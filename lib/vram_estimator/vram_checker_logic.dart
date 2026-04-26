import 'dart:collection';
import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:async_task/async_task.dart';
import 'package:trios/utils/extensions.dart';

import '../models/mod_variant.dart';
import '../utils/logging.dart';
import '../utils/util.dart';
import 'image_reader/image_reader_async.dart';
import 'models/gpu_info.dart';
import 'models/graphics_lib_config.dart';
import 'models/vram_checker_models.dart';
import 'selectors/folder_scan_selector.dart';
import 'selectors/vram_asset_selector.dart';
import 'vram_check_scan_params.dart';
import 'vram_scan_one_mod.dart';
import 'vram_scan_task.dart';

class VramChecker {
  List<String>? enabledModIds;
  List<ModVariant> variantsToCheck;
  bool showGfxLibDebugOutput;
  bool showPerformance;
  bool showSkippedFiles;
  bool showCountedFiles;
  GraphicsLibConfig graphicsLibConfig;
  Function(VramMod) modProgressOut = (it) => (it);
  Function(VramCheckerMod) onModStart = (it) => (it);
  /// Fires exactly once per mod whose scan reached its terminal state —
  /// success, failure, cancel, or executor-level error. Pairs with
  /// [onModStart] so callers can maintain "in-flight" UI state without
  /// leaking entries when a task ends abnormally.
  Function(VramCheckerMod) onModEnd = (it) => (it);
  Function(String) verboseOut = (it) => (it);
  Function(String) debugOut = (it) => (it);
  bool Function() isCancelled;

  /// Called with file-level progress for a mod that is currently being
  /// scanned. [modInfo] identifies the mod (essential in multithreaded
  /// mode where several mods scan in parallel). [processed] is the number
  /// of selected assets whose header has been read so far; [total] is the
  /// selector's full asset count for that mod; [recentAssetPath] is the
  /// mod-relative path of the asset whose completion just incremented
  /// [processed], or null on the initial (0, total, null) fire-once call
  /// at the start of a mod.
  ///
  /// Note: reads run concurrently, so [recentAssetPath] isn't "the" file
  /// being scanned — it's whichever happened to finish most recently. Good
  /// enough for live activity feedback.
  Function(
    VramCheckerMod modInfo,
    int processed,
    int total,
    String? recentAssetPath,
  )?
  onFileProgress;

  /// Selector that decides which image files a mod contributes. Defaults
  /// to [FolderScanSelector] (the behavior this class had before
  /// selectors existed) so existing callers need no changes.
  VramAssetSelector selector;

  int maxFileHandles;

  /// When true, run the per-mod scan loop across an `async_task`
  /// `AsyncExecutor` isolate pool. When false (default), keep the legacy
  /// single-isolate sequential pipeline. See `Settings.vramEstimatorMultithreaded`.
  bool multithreaded;

  /// [modProgressOut] is called with each mod as it is processed.
  VramChecker({
    this.enabledModIds,
    required this.variantsToCheck,
    required this.showGfxLibDebugOutput,
    required this.showPerformance,
    required this.showSkippedFiles,
    required this.showCountedFiles,
    required this.graphicsLibConfig,
    this.maxFileHandles = 2000,
    VramAssetSelector? selector,
    Function(VramMod)? modProgressOut,
    Function(VramCheckerMod)? onModStart,
    Function(VramCheckerMod)? onModEnd,
    Function(String)? verboseOut,
    Function(String)? debugOut,
    this.onFileProgress,
    required this.isCancelled,
    this.multithreaded = false,
  }) : selector = selector ?? FolderScanSelector() {
    if (verboseOut != null) {
      this.verboseOut = verboseOut;
    }
    if (debugOut != null) {
      this.debugOut = debugOut;
    }
    if (modProgressOut != null) {
      this.modProgressOut = modProgressOut;
    }
    if (onModStart != null) {
      this.onModStart = onModStart;
    }
    if (onModEnd != null) {
      this.onModEnd = onModEnd;
    }
  }

  static const VANILLA_BACKGROUND_WIDTH = 2048;
  static const VANILLA_BACKGROUND_TEXTURE_SIZE_IN_BYTES = 12582912.0;
  static const VANILLA_GAME_VRAM_USAGE_IN_BYTES =
      433586176.0; // 0.9.1a, per https://fractalsoftworks.com/forum/index.php?topic=8726.0
  static const OUTPUT_LABEL_WIDTH = 38;

  static const BACKGROUND_FOLDER_NAME = "backgrounds";

  var progressText = StringBuffer();
  var modTotals = StringBuffer();
  var summaryText = StringBuffer();
  var startTime = DateTime.timestamp().millisecondsSinceEpoch;

  /// Build the serializable per-mod parameter object the [scanOneMod]
  /// top-level function consumes. The selector is passed by id + config
  /// instead of by instance so the same params survive an isolate hop in
  /// the multithreaded path.
  VramCheckScanParams _buildParams(VramCheckerMod modInfo) {
    // The current selector instance carries its own config (e.g.
    // `ReferencedAssetsSelector.config`). We can't introspect it
    // generically, so we rely on the selector exposing a `.toMap()`-able
    // config when needed — for now, both registered selectors are
    // reconstructable from id alone or via a `Map`-shaped config that
    // gets passed in by the notifier when the multithreaded path lands.
    // For the single-threaded path the worker reconstructs a fresh
    // selector via `VramAssetSelector.fromId` to keep both code paths
    // identical; behaviorally this is a no-op (selectors are stateless
    // beyond their config).
    Object? selectorConfig;
    final s = selector;
    // ignore: avoid_dynamic_calls
    final dynamic dynSelector = s;
    try {
      selectorConfig = dynSelector.config;
    } catch (_) {
      selectorConfig = null;
    }

    return VramCheckScanParams(
      modInfo: modInfo,
      enabledModIds: enabledModIds ?? const [],
      selectorId: selector.id,
      selectorConfig: selectorConfig,
      graphicsLibConfig: graphicsLibConfig,
      showGfxLibDebugOutput: showGfxLibDebugOutput,
      showPerformance: showPerformance,
      showSkippedFiles: showSkippedFiles,
      showCountedFiles: showCountedFiles,
      maxFileHandles: maxFileHandles,
    );
  }

  /// Drive the in-process scan one mod at a time, reusing the shared
  /// [scanOneMod] body. Replays the per-mod log buffer into
  /// [verboseOut]/[debugOut] after each mod completes so log ordering is
  /// per-mod-atomic — matching the multithreaded path.
  Future<List<VramMod>> _checkSingleIsolate() async {
    final imageHeaderReaderPool = ReadImageHeaders();
    final mods = <VramMod>[];

    for (final variant in variantsToCheck) {
      final modInfo = VramCheckerMod(variant.modInfo, variant.modFolder.path);
      if (isCancelled()) {
        throw Exception("Cancelled");
      }
      final outcome = await scanOneMod(
        _buildParams(modInfo),
        imageReaderPool: imageHeaderReaderPool,
        onModStart: onModStart,
        onFileProgress: (processed, total, path) {
          onFileProgress?.call(modInfo, processed, total, path);
        },
        isCancelledLocal: isCancelled,
      );

      // Replay captured per-mod log into verboseOut. Single-threaded
      // mode used to stream lines live; per-mod batching is acceptable
      // (mod names are in every line, ordering across mods is not part
      // of the parity guarantee).
      final captured = outcome.logBuffer;
      if (captured.isNotEmpty) {
        verboseOut(captured);
      }

      // Fire onModEnd for every terminal state — callers rely on this
      // to clean up "in-flight" UI tracking even when a scan fails.
      onModEnd(modInfo);

      if (outcome.cancelled) {
        throw Exception("Cancelled");
      }
      if (outcome.isFailure) {
        Fimber.w(
          "VRAM scan failed for mod ${modInfo.modId}: ${outcome.errorMessage}\n${outcome.errorStack}",
        );
        continue;
      }
      final mod = outcome.mod!;
      modProgressOut(mod);
      mods.add(mod);
      // Yield between mods so the calling isolate gets a frame.
      await Future<void>.microtask(() {});
    }
    return mods;
  }

  /// Drive the scan across an `async_task` worker pool. Per-mod progress
  /// and cancellation flow over each task's [AsyncTaskChannel]. Replays
  /// each mod's captured log buffer once its task settles, preserving
  /// per-mod-atomic ordering even when several mods run in parallel.
  Future<List<VramMod>> _checkMultithreaded() async {
    final parallelism = max(
      1,
      min(Platform.numberOfProcessors - 1, 4),
    );
    final executor = AsyncExecutor(
      sequential: false,
      parallelism: parallelism,
      taskTypeRegister: vramScanTaskRegister,
    );

    final mods = <VramMod>[];

    try {
      // Build all the params + tasks up front, then drain through a
      // bounded worker pool. The pool size matches executor parallelism
      // so the dispatcher never has more pump loops in flight than the
      // executor can actually run — without this, hundreds of polling
      // loops would jam the main isolate (Windows shows "Not Responding"
      // and progress UI freezes).
      final variants = variantsToCheck
          .map((v) => VramCheckerMod(v.modInfo, v.modFolder.path))
          .toList();
      final taskQueue = Queue<({VramScanTask task, VramCheckerMod modInfo})>();
      for (final modInfo in variants) {
        final params = _buildParams(modInfo);
        taskQueue.add((
          task: VramScanTask(params.toTransfer()),
          modInfo: modInfo,
        ));
      }

      final workers = <Future<void>>[];
      for (var i = 0; i < parallelism; i++) {
        workers.add(() async {
          while (taskQueue.isNotEmpty) {
            if (isCancelled()) return;
            final entry = taskQueue.removeFirst();
            final exec = executor.execute(entry.task);
            await _pumpTask(entry.task, exec, entry.modInfo, mods);
          }
        }());
      }

      await Future.wait(workers);
    } finally {
      try {
        await executor.close();
      } catch (e, st) {
        Fimber.w(
          'Failed to close VRAM AsyncExecutor cleanly: $e',
          ex: e,
          stacktrace: st,
        );
      }
    }
    return mods;
  }

  /// Forward channel messages (progress, mod-start) from a single
  /// running task to the main-isolate callbacks while awaiting its
  /// completion. On task completion, replay the captured log buffer
  /// and (on success) record the mod and emit `modProgressOut`.
  Future<void> _pumpTask(
    VramScanTask task,
    Future<Map<String, dynamic>> exec,
    VramCheckerMod modInfo,
    List<VramMod> mods,
  ) async {
    final channel = await task.channel();
    bool pumpDone = false;
    bool taskCancelInjected = false;

    // Listen for progress/start messages until the worker emits its
    // `scanDoneChannelMarker` sentinel, or until the task settles
    // (whichever comes first — a worker that crashed before sending the
    // sentinel must not park the pump forever). Polling via the
    // non-blocking [readMessage] keeps the dispatcher in control of the
    // loop's lifetime.
    final pump = () async {
      if (channel == null) return;
      while (!pumpDone) {
        final msg = channel.readMessage<Object?>();
        if (msg == null) {
          // 50ms is fast enough for live progress (20Hz) and 3x lighter
          // on the event loop than the 16ms / 60Hz default.
          await Future.delayed(const Duration(milliseconds: 50));
          continue;
        }
        if (msg == scanDoneChannelMarker) {
          pumpDone = true;
          return;
        }
        if (msg is Map) {
          final kind = msg['kind'];
          if (kind == 'fileProgress') {
            onFileProgress?.call(
              modInfo,
              msg['processed'] as int,
              msg['total'] as int,
              msg['recentAssetPath'] as String?,
            );
          } else if (kind == 'modStart') {
            onModStart(modInfo);
          }
        }
      }
    }();

    // Watch for cancellation while the task is in flight; inject a
    // cancel marker into the channel exactly once. Polled at 200ms —
    // perceived cancellation latency under 0.25s is fine and this is
    // cheaper on the event loop than tighter polling.
    final cancelWatcher = () async {
      while (!pumpDone) {
        if (isCancelled() && !taskCancelInjected && channel != null) {
          channel.send(cancelChannelMarker);
          taskCancelInjected = true;
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }();

    Map<String, dynamic>? resultMap;
    Object? execError;
    StackTrace? execStack;
    try {
      resultMap = await exec;
    } catch (e, st) {
      execError = e;
      execStack = st;
    } finally {
      // The worker normally sends the `scanDoneChannelMarker` itself; if
      // the executor surfaced an error before the worker got there, force
      // the pump to break out on its next non-blocking poll.
      pumpDone = true;
    }

    // Drain the pump and watcher.
    await pump;
    await cancelWatcher;

    // Fire onModEnd for every terminal state regardless of whether the
    // worker succeeded, was cancelled, or threw. This is what keeps the
    // notifier's `activeScans` from leaking entries: without this, mods
    // whose scan failed would remain in the in-flight UI map until the
    // overall scan ends.
    try {
      onModEnd(modInfo);
    } catch (e, st) {
      Fimber.w(
        'onModEnd threw for ${modInfo.modId}: $e',
        ex: e,
        stacktrace: st,
      );
    }

    if (execError != null) {
      Fimber.w(
        'VRAM scan task threw for mod ${modInfo.modId}: $execError\n$execStack',
      );
      return;
    }

    final outcome = VramScanOutcome.fromTransfer(resultMap!);
    if (outcome.logBuffer.isNotEmpty) {
      verboseOut(outcome.logBuffer);
    }
    if (outcome.cancelled) return;
    if (outcome.isFailure) {
      Fimber.w(
        'VRAM scan failed for mod ${modInfo.modId}: ${outcome.errorMessage}\n${outcome.errorStack}',
      );
      return;
    }
    final mod = outcome.mod!;
    modProgressOut(mod);
    mods.add(mod);
  }

  Future<List<VramMod>> check() async {
    progressText = StringBuffer();
    modTotals = StringBuffer();
    summaryText = StringBuffer();
    startTime = DateTime.timestamp().millisecondsSinceEpoch;

    progressText.appendAndPrint(
      "GraphicsLib Config: $graphicsLibConfig",
      debugOut,
    );
    progressText.appendAndPrint(
      "Selector: ${selector.id} (${selector.displayName})",
      debugOut,
    );

    if (enabledModIds != null) {
      progressText.appendAndPrint(
        "\nEnabled Mods:\n${enabledModIds?.join("\n")}",
        verboseOut,
      );
    }

    // Isolate spawn cost dominates for tiny lists; fall back to the
    // single-isolate path when there's nothing to parallelize.
    final useMultithreaded = multithreaded && variantsToCheck.length >= 2;
    final scanned = useMultithreaded
        ? await _checkMultithreaded()
        : await _checkSingleIsolate();

    final mods = scanned
        .sortedByDescending<num>((it) => it.bytesNotIncludingGraphicsLib())
        .toList();

    for (var mod in mods) {
      modTotals.writeln();
      modTotals.writeln(
        "${mod.info.formattedName} - ${mod.images.length} images - ${(mod.isEnabled) ? "Enabled" : "Disabled"}",
      );
      modTotals.writeln(mod.bytesNotIncludingGraphicsLib().bytesAsReadableMB());
    }

    final enabledMods = mods.where((mod) => mod.isEnabled);
    final totalBytes = mods.getBytesUsedByDedupedImages();
    final totalBytesOfEnabledMods = enabledMods.getBytesUsedByDedupedImages();

    if (showPerformance) {
      final totalMs = DateTime.timestamp().millisecondsSinceEpoch - startTime;
      progressText.appendAndPrint("Finished run in $totalMs ms", verboseOut);
      Fimber.d(
        "[VramChecker] runComplete selector=${selector.id} "
        "mods=${mods.length} time=${totalMs}ms",
      );
    }

    final enabledModsString = enabledMods
        .joinToString(
          separator: "\n    ",
          transform: (it) => it.info.formattedName,
        )
        .ifBlank("(none)");

    progressText.appendAndPrint("\n", verboseOut);
    summaryText.writeln();
    summaryText.writeln("-------------");
    summaryText.writeln("VRAM Use Estimates");
    summaryText.writeln(
      "Time taken: ${(DateTime.now().millisecondsSinceEpoch - startTime)} ms",
    );
    summaryText.writeln();
    summaryText.writeln("Configuration");
    summaryText.writeln("  Enabled Mods");
    summaryText.writeln("    $enabledModsString");
    summaryText.writeln("  GraphicsLib");
    summaryText.writeln(
      "    Normal Maps Enabled: ${graphicsLibConfig.areGfxLibNormalMapsEnabled}",
    );
    summaryText.writeln(
      "    Material Maps Enabled: ${graphicsLibConfig.areGfxLibMaterialMapsEnabled}",
    );
    summaryText.writeln(
      "    Surface Maps Enabled: ${graphicsLibConfig.areGfxLibSurfaceMapsEnabled}",
    );
    summaryText.writeln(
      "    Edit 'config.properties' to choose your GraphicsLib settings.",
    );
    try {
      getGPUInfo()?.also((info) {
        summaryText.writeln("  System");
        summaryText.writeln(
          info.gpuString?.joinToString(
            separator: "\n",
            transform: (it) => "    $it",
          ),
        );

        // If expected VRAM after loading game and mods is less than 300 MB, show warning
        if (info.freeVRAM -
                (totalBytesOfEnabledMods + VANILLA_GAME_VRAM_USAGE_IN_BYTES) <
            300000) {
          summaryText.writeln();
          summaryText.writeln(
            "WARNING: You may not have enough free VRAM to run your current modlist.",
          );
        }
      });
    } catch (it, st) {
      summaryText.writeln();
      summaryText.writeln(
        "Unable to get GPU information due to the following error:",
      );
      summaryText.writeln(st.toString());
    }
    summaryText.writeln();

    summaryText.writeln(
      "Enabled + Disabled Mods w/o Vanilla".padRight(OUTPUT_LABEL_WIDTH) +
          totalBytes.bytesAsReadableMB(),
    );
    summaryText.writeln(
      "Enabled + Disabled Mods w/ Vanilla".padRight(OUTPUT_LABEL_WIDTH) +
          (totalBytes + VANILLA_GAME_VRAM_USAGE_IN_BYTES).bytesAsReadableMB(),
    );
    summaryText.writeln();
    summaryText.writeln(
      "Enabled Mods w/o Vanilla".padRight(OUTPUT_LABEL_WIDTH) +
          totalBytesOfEnabledMods.bytesAsReadableMB(),
    );
    summaryText.writeln(
      "Enabled Mods w/ Vanilla".padRight(OUTPUT_LABEL_WIDTH) +
          (totalBytesOfEnabledMods + VANILLA_GAME_VRAM_USAGE_IN_BYTES)
              .bytesAsReadableMB(),
    );

    summaryText.writeln();
    summaryText.writeln(
      "** This is only an estimate of VRAM use and actual use may be higher or lower.",
    );
    summaryText.writeln("** Selector: ${selector.id}. ${selector.description}");

    verboseOut(modTotals.toString());
    debugOut(summaryText.toString());

    return mods;
  }
}

extension ModListExt on Iterable<VramMod> {
  int getBytesUsedByDedupedImages() {
    // Use a set keyed by (modFolder, filePath). Only sums the referenced
    // bucket; [VramMod.unreferencedImages] is advisory and never included
    // in aggregate totals.
    final seen = <Tuple2<String, String>>{};
    int sum = 0;
    for (var mod in this) {
      final table = mod.images;
      for (int i = 0; i < table.length; i++) {
        final view = ModImageView(i, table);
        final key = Tuple2(mod.info.modFolder, view.filePath);
        if (!seen.contains(key)) {
          seen.add(key);
          sum += view.bytesUsed;
        }
      }
    }
    return sum;
  }
}
