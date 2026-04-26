import 'dart:core';
import 'dart:io';

import 'package:async_task/async_task.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/vram_estimator/image_reader/image_reader_async.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/references/graphicslib_references.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';
import 'package:trios/vram_estimator/vram_check_scan_params.dart';

const String _backgroundFolderName = "backgrounds";
const int _vanillaBackgroundWidth = 2048;

/// Channel message sent from the worker to the main isolate carrying a
/// `(processed, total, recentAssetPath)` per-file progress tick. Plain
/// `Map` so async_task's default codec round-trips it without registration.
Map<String, Object?> fileProgressMsg(
  int processed,
  int total,
  String? recentAssetPath,
) => <String, Object?>{
  'kind': 'fileProgress',
  'processed': processed,
  'total': total,
  'recentAssetPath': recentAssetPath,
};

/// Channel message sent from the worker to the main isolate signaling that
/// scanning of a particular mod is starting. Used to drive `onModStart`.
Map<String, Object?> modStartMsg() => <String, Object?>{'kind': 'modStart'};

/// Cancellation marker the dispatcher sends *into* the worker. The worker
/// polls for this between phase boundaries and aborts.
const String cancelChannelMarker = '__cancel__';

/// Marker the worker sends as its very last channel message so the
/// dispatcher's pump loop can stop awaiting `waitMessage` (which would
/// otherwise hang once the task completes — the channel doesn't surface
/// closure as a `null` from `waitMessage`).
const String scanDoneChannelMarker = '__scan_done__';

/// Per-call file-handle limiter. The pre-extraction code kept a single
/// counter on `VramChecker`; per-mod scopes are isolate-safe and avoid
/// sharing state across worker isolates.
class _FileHandleLimiter {
  final int max;
  int current = 0;
  final void Function(String)? onWaiting;

  _FileHandleLimiter(this.max, {this.onWaiting});

  Future<T> run<T>(Future<T> Function() function) async {
    while (current + 1 > max) {
      onWaiting?.call(
        "Waiting for file handles to free up. Current file handles: $current",
      );
      await Future.delayed(const Duration(milliseconds: 100));
    }
    current++;
    try {
      return await function();
    } finally {
      current--;
    }
  }
}

/// Pure, isolate-safe per-mod scan body. Both the single-isolate path
/// inside `VramChecker.check()` and (in the multithreaded path)
/// `VramScanTask.run()` call into this function so the actual scan logic
/// lives in exactly one place.
///
/// When [channel] is non-null, per-file progress and per-mod-start events
/// are emitted as channel messages; cancellation is observed by polling
/// for [cancelChannelMarker] on the same channel. When [channel] is null,
/// [onModStart] / [onFileProgress] are invoked directly on the calling
/// isolate, and [isCancelledLocal] is polled for cooperative cancellation.
///
/// Verbose / debug log lines are always captured into a per-mod
/// `StringBuffer` and returned in [VramScanOutcome.logBuffer] — the
/// dispatcher replays them into the user-visible log streams after the
/// task settles, preserving per-mod-atomic ordering.
Future<VramScanOutcome> scanOneMod(
  VramCheckScanParams params, {
  AsyncTaskChannel? channel,
  ReadImageHeaders? imageReaderPool,
  void Function(VramCheckerMod modInfo)? onModStart,
  void Function(int processed, int total, String? recentAssetPath)?
  onFileProgress,
  bool Function()? isCancelledLocal,
}) async {
  final logBuffer = StringBuffer();

  // All non-progress log writes go through this pair so worker and main
  // isolate paths stay identical.
  void verboseOut(String line) {
    logBuffer.writeln(line);
  }

  void debugOut(String line) {
    logBuffer.writeln(line);
  }

  // Cancellation in the worker path is delivered via a channel message; the
  // dispatcher in `VramChecker.check()` is responsible for sending the
  // marker on the same channel when the scan is cancelled mid-flight. Phase
  // boundaries call [checkCancelled] which both polls the channel (worker)
  // and the local predicate (main isolate).
  bool channelCancelObserved = false;
  void drainCancelMessages() {
    if (channel == null) return;
    while (true) {
      final msg = channel.readMessage<Object?>();
      if (msg == null) return;
      if (msg == cancelChannelMarker) {
        channelCancelObserved = true;
        return;
      }
    }
  }

  bool isCancelled() {
    if (channelCancelObserved) return true;
    if (isCancelledLocal != null && isCancelledLocal()) return true;
    return false;
  }

  void checkCancelled() {
    drainCancelMessages();
    if (isCancelled()) {
      throw const _CancelledException();
    }
  }

  final modInfo = params.modInfo;
  VramScanOutcome buildOutcome(VramScanOutcome o) {
    // Send a "done" sentinel so the dispatcher's pump loop exits.
    // Worker-only — the main-isolate path doesn't open a channel.
    if (channel != null) {
      try {
        channel.send(scanDoneChannelMarker);
      } catch (_) {
        // Channel may have been closed by executor teardown; ignore.
      }
    }
    return o;
  }

  try {
    logBuffer.writeln("\nFolder: ${modInfo.name}");
    if (channel != null) {
      channel.send(modStartMsg());
    } else {
      onModStart?.call(modInfo);
    }

    checkCancelled();
    final startTimeForMod = DateTime.timestamp().millisecondsSinceEpoch;

    int? maxImages;
    // Special handling for Illustrated Entities, which dynamically unloads
    // images. Very rough estimate.
    if (modInfo.modInfo.id == Constants.illustratedEntitiesId) {
      maxImages = 20;
    }

    // Enumerate every file in the mod folder once. Selectors consume this
    // pre-enumerated list so listing only happens per mod, not per
    // selector. Async listing so the calling isolate isn't blocked on
    // large mods.
    final modFolderDir = modInfo.modFolder.toDirectory();
    final maxLimit = maxImages ?? intMaxValue;
    final filesInMod = <VramModFile>[];
    await for (final entity in modFolderDir.list(recursive: true)) {
      if (entity is! File) continue;
      filesInMod.add(
        VramModFile(
          file: entity,
          relativePath: entity.relativePath(modFolderDir),
        ),
      );
      if (filesInMod.length >= maxLimit) break;
    }

    checkCancelled();

    // Parse the mod's GraphicsLib CSV once per mod; shared with every
    // selector.
    final graphicsLibEntries = await GraphicsLibReferences.parse(
      modInfo,
      filesInMod,
      onError: verboseOut,
    );

    final timeFinishedGettingGraphicsLibData =
        DateTime.timestamp().millisecondsSinceEpoch;
    if (params.showPerformance) {
      verboseOut(
        "Finished getting GraphicsLib images for ${modInfo.name} in ${(timeFinishedGettingGraphicsLibData - startTimeForMod)} ms",
      );
    }

    checkCancelled();

    // Reconstruct the selector inside this isolate from the serializable
    // (id, config) pair. On the main isolate this is the same logical
    // result as `resolveSelector` since both code paths register through
    // `VramAssetSelector.fromId`.
    final selector = VramAssetSelector.fromId(
      params.selectorId,
      params.selectorConfig,
    );

    final selectorCtx = VramSelectorContext(
      verboseOut: verboseOut,
      debugOut: debugOut,
      isCancelled: isCancelled,
      showPerformance: params.showPerformance,
      graphicsLibEntries: graphicsLibEntries,
    );
    final selectedAssets = await selector.select(
      modInfo,
      filesInMod,
      selectorCtx,
    );

    final timeFinishedSelector = DateTime.timestamp().millisecondsSinceEpoch;
    if (params.showPerformance) {
      final selectorMs =
          timeFinishedSelector - timeFinishedGettingGraphicsLibData;
      verboseOut(
        "Selector '${selector.id.wireValue}' returned ${selectedAssets.length} assets for ${modInfo.name} in $selectorMs ms",
      );
      final refCount = selectedAssets
          .where((a) => a.provenance == AssetProvenance.referenced)
          .length;
      final unrefCount = selectedAssets.length - refCount;
      Fimber.d(
        "[VramChecker] selector=${selector.id.wireValue} mod=${modInfo.modId} "
        "time=${selectorMs}ms referenced=$refCount unreferenced=$unrefCount "
        "total=${selectedAssets.length}",
      );
    }

    checkCancelled();

    final totalFiles = selectedAssets.length;
    if (channel != null) {
      channel.send(fileProgressMsg(0, totalFiles, null));
    } else {
      onFileProgress?.call(0, totalFiles, null);
    }
    var processedFiles = 0;
    void onAssetDone(String relativePath) {
      processedFiles++;
      if (channel != null) {
        channel.send(fileProgressMsg(processedFiles, totalFiles, relativePath));
      } else {
        onFileProgress?.call(processedFiles, totalFiles, relativePath);
      }
    }

    final imagePool = imageReaderPool ?? ReadImageHeaders();
    final fileHandleLimiter = _FileHandleLimiter(
      params.maxFileHandles,
      onWaiting: verboseOut,
    );

    final referencedFutures = _processAssets(
      selectedAssets
          .where((a) => a.provenance == AssetProvenance.referenced)
          .toList(),
      imagePool,
      fileHandleLimiter,
      isCancelled: isCancelled,
      showSkippedFiles: params.showSkippedFiles,
      verboseOut: verboseOut,
      onAssetDone: onAssetDone,
    );
    final unreferencedFutures = _processAssets(
      selectedAssets
          .where((a) => a.provenance == AssetProvenance.unreferenced)
          .toList(),
      imagePool,
      fileHandleLimiter,
      isCancelled: isCancelled,
      showSkippedFiles: params.showSkippedFiles,
      verboseOut: verboseOut,
      onAssetDone: onAssetDone,
    );

    final results = await Future.wait([
      Future.wait(referencedFutures),
      Future.wait(unreferencedFutures),
    ]);
    final referencedRows = results[0].nonNulls.toList();
    final unreferencedRows = results[1].nonNulls.toList();

    final timeFinishedGettingFileData =
        DateTime.timestamp().millisecondsSinceEpoch;
    if (params.showPerformance) {
      final headerMs = timeFinishedGettingFileData - timeFinishedSelector;
      verboseOut(
        "Finished getting file data for ${modInfo.formattedName} in $headerMs ms",
      );
      Fimber.d(
        "[VramChecker] headerRead mod=${modInfo.modId} "
        "refRows=${referencedRows.length} unrefRows=${unreferencedRows.length} "
        "time=${headerMs}ms",
      );
    }

    checkCancelled();

    final referencedTable = ModImageTable.fromRows(referencedRows);
    final unreferencedTable = unreferencedRows.isEmpty
        ? null
        : ModImageTable.fromRows(unreferencedRows);

    List<ModImageView> referencedViews = List.generate(
      referencedTable.length,
      (i) => ModImageView(i, referencedTable),
    );

    referencedViews = _filterBackgroundsAgainstVanilla(
      referencedViews,
      modInfo.modFolder,
      verboseOut: verboseOut,
    );

    if (params.showCountedFiles) {
      for (var view in referencedViews) {
        verboseOut(
          "${p.relative(view.file.path, from: modInfo.modFolder)} - TexHeight: ${view.textureHeight}, TexWidth: ${view.textureWidth}, ChannelBits: ${view.bitsInAllChannelsSum}, Mult: ${view.multiplier}\n   --> ${view.textureHeight} * ${view.textureWidth} * ${view.bitsInAllChannelsSum} * ${view.multiplier} = ${view.bytesUsed} bytes added over vanilla",
        );
      }
    }

    final filteredReferencedTable = ModImageTable.fromRows(
      referencedViews
          .map(
            (view) => {
              'filePath': view.filePath,
              'textureHeight': view.textureHeight,
              'textureWidth': view.textureWidth,
              'bitsInAllChannelsSum': view.bitsInAllChannelsSum,
              'imageType': view.imageType.name,
              'graphicsLibType': view.graphicsLibType?.name,
              if (view.referencedBy != null && view.referencedBy!.isNotEmpty)
                'referencedBy': view.referencedBy,
            },
          )
          .toList(),
    );

    final mod = VramMod(
      modInfo,
      params.enabledModIds.contains(modInfo.modId),
      filteredReferencedTable,
      graphicsLibEntries,
      unreferencedImages: unreferencedTable,
      scannedAt: DateTime.now(),
    );

    if (params.showPerformance) {
      verboseOut(
        "Finished calculating ${filteredReferencedTable.length} file sizes for ${mod.info.formattedName} in ${(DateTime.timestamp().millisecondsSinceEpoch - timeFinishedGettingFileData)} ms",
      );
    }
    verboseOut(mod.bytesNotIncludingGraphicsLib().bytesAsReadableMB());

    return buildOutcome(
      VramScanOutcome.success(mod: mod, logBuffer: logBuffer.toString()),
    );
  } on _CancelledException {
    return buildOutcome(
      VramScanOutcome.cancelled(logBuffer: logBuffer.toString()),
    );
  } catch (e, st) {
    return buildOutcome(
      VramScanOutcome.failed(
        message: e.toString(),
        stack: st.toString(),
        logBuffer: logBuffer.toString(),
      ),
    );
  }
}

class _CancelledException implements Exception {
  const _CancelledException();
  @override
  String toString() => 'Cancelled';
}

Iterable<Future<Map<String, dynamic>?>> _processAssets(
  Iterable<SelectedAsset> assets,
  ReadImageHeaders imageHeaderReaderPool,
  _FileHandleLimiter limiter, {
  required bool Function() isCancelled,
  required bool showSkippedFiles,
  required void Function(String) verboseOut,
  void Function(String relativePath)? onAssetDone,
}) {
  return assets.map((asset) async {
    if (isCancelled()) {
      throw const _CancelledException();
    }
    final file = asset.file;
    final imageType = file.relativePath.contains(_backgroundFolderName)
        ? ImageType.background
        : ImageType.texture;

    try {
      return await limiter.run(() async {
        final image = await imageHeaderReaderPool.readImageDeterminingBest(
          file.file.path,
        );
        if (image == null) {
          throw Exception("Image is null");
        }
        return {
          'filePath': file.file.path,
          'textureHeight': (image.width == 1)
              ? 1
              : (image.width - 1).highestOneBit() * 2,
          'textureWidth': (image.height == 1)
              ? 1
              : (image.height - 1).highestOneBit() * 2,
          'bitsInAllChannelsSum': image.bitDepth * image.numChannels,
          'imageType': imageType.name,
          'graphicsLibType': asset.graphicsLibType?.name,
          if (asset.referencedBy != null && asset.referencedBy!.isNotEmpty)
            'referencedBy': asset.referencedBy,
        };
      });
    } catch (e) {
      if (showSkippedFiles) {
        verboseOut("Skipped non-image ${file.relativePath} ($e)");
      }
      return null;
    } finally {
      onAssetDone?.call(file.relativePath);
    }
  });
}

/// Backgrounds at or below vanilla size contribute nothing; among
/// oversized backgrounds only the largest counts. Mirrors the previous
/// behavior exactly — applied to referenced assets only.
List<ModImageView> _filterBackgroundsAgainstVanilla(
  List<ModImageView> views,
  String modFolder, {
  required void Function(String) verboseOut,
}) {
  final backgrounds = views
      .where((view) => view.imageType == ImageType.background)
      .toList();
  final largestBackground = backgrounds
      .where((view) => view.textureWidth > _vanillaBackgroundWidth)
      .maxByOrNull<num>((view) => view.bytesUsed);
  final backgroundsToDrop = {
    for (final view in backgrounds)
      if (largestBackground != null && view != largestBackground) view,
  };
  if (backgroundsToDrop.isNotEmpty) {
    verboseOut(
      "Skipping backgrounds that are not larger than vanilla and/or not the mod's largest background.",
    );
    for (var view in backgroundsToDrop) {
      verboseOut("   ${p.relative(view.file.path, from: modFolder)}");
    }
  }
  return views.where((v) => !backgroundsToDrop.contains(v)).toList();
}
