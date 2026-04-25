import 'dart:core';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';

import '../models/mod_variant.dart';
import '../utils/logging.dart';
import '../utils/util.dart';
import 'image_reader/image_reader_async.dart';
import 'models/gpu_info.dart';
import 'models/graphics_lib_config.dart';
import 'models/vram_checker_models.dart';
import 'selectors/folder_scan_selector.dart';
import 'selectors/references/graphicslib_references.dart';
import 'selectors/vram_asset_selector.dart';

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
  Function(String) verboseOut = (it) => (it);
  Function(String) debugOut = (it) => (it);
  bool Function() isCancelled;

  /// Called with file-level progress for the mod currently being scanned.
  /// [processed] is the number of selected assets whose header has been
  /// read so far; [total] is the selector's full asset count for that mod;
  /// [recentAssetPath] is the mod-relative path of the asset whose
  /// completion just incremented [processed], or null on the initial
  /// (0, total, null) fire-once call at the start of a mod.
  ///
  /// Note: reads run concurrently, so [recentAssetPath] isn't "the" file
  /// being scanned — it's whichever happened to finish most recently. Good
  /// enough for live activity feedback.
  Function(int processed, int total, String? recentAssetPath)? onFileProgress;

  /// Selector that decides which image files a mod contributes. Defaults to
  /// [FolderScanSelector] (the behavior this class had before selectors
  /// existed) so existing callers need no changes.
  VramAssetSelector selector;

  int maxFileHandles;

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
    Function(String)? verboseOut,
    Function(String)? debugOut,
    this.onFileProgress,
    required this.isCancelled,
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
  }

  static const VANILLA_BACKGROUND_WIDTH = 2048;
  static const VANILLA_BACKGROUND_TEXTURE_SIZE_IN_BYTES = 12582912.0;
  static const VANILLA_GAME_VRAM_USAGE_IN_BYTES =
      433586176.0; // 0.9.1a, per https://fractalsoftworks.com/forum/index.php?topic=8726.0
  static const OUTPUT_LABEL_WIDTH = 38;

  static const BACKGROUND_FOLDER_NAME = "backgrounds";
  var currentFileHandles = 0;

  var progressText = StringBuffer();
  var modTotals = StringBuffer();
  var summaryText = StringBuffer();
  var startTime = DateTime.timestamp().millisecondsSinceEpoch;

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

    final imageHeaderReaderPool = ReadImageHeaders();

    // Process each mod variant asynchronously.
    final mods = (await Stream.fromIterable(variantsToCheck.map((it) => VramCheckerMod(it.modInfo, it.modFolder.path))).asyncMap((
      modInfo,
    ) async {
      progressText.appendAndPrint("\nFolder: ${modInfo.name}", verboseOut);
      onModStart(modInfo);
      if (isCancelled()) {
        throw Exception("Cancelled");
      }
      final startTimeForMod = DateTime.timestamp().millisecondsSinceEpoch;

      int? maxImages;

      // Special handling for Illustrated Entities, which dynamically unloads images.
      // Very rough estimate.
      if (modInfo.modInfo.id == Constants.illustratedEntitiesId) {
        maxImages = 20;
      }

      // Enumerate every file in the mod folder once. Selectors consume this
      // pre-enumerated list so listing only happens per mod, not per selector.
      // Async listing so the UI thread isn't blocked on large mods.
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

      // Parse the mod's GraphicsLib CSV once per mod; shared with every selector.
      final graphicsLibEntries = await GraphicsLibReferences.parse(
        modInfo,
        filesInMod,
        onError: (msg) => progressText.appendAndPrint(msg, verboseOut),
      );

      final timeFinishedGettingGraphicsLibData =
          DateTime.timestamp().millisecondsSinceEpoch;
      if (showPerformance) {
        progressText.appendAndPrint(
          "Finished getting GraphicsLib images for ${modInfo.name} in ${(timeFinishedGettingGraphicsLibData - startTimeForMod)} ms",
          verboseOut,
        );
      }

      // Ask the selector which files to count.
      final selectorCtx = VramSelectorContext(
        verboseOut: verboseOut,
        debugOut: debugOut,
        isCancelled: isCancelled,
        showPerformance: showPerformance,
        graphicsLibEntries: graphicsLibEntries,
      );
      final selectedAssets = await selector.select(
        modInfo,
        filesInMod,
        selectorCtx,
      );

      final timeFinishedSelector = DateTime.timestamp().millisecondsSinceEpoch;
      if (showPerformance) {
        final selectorMs =
            timeFinishedSelector - timeFinishedGettingGraphicsLibData;
        progressText.appendAndPrint(
          "Selector '${selector.id}' returned ${selectedAssets.length} assets for ${modInfo.name} in $selectorMs ms",
          verboseOut,
        );
        final refCount = selectedAssets
            .where((a) => a.provenance == AssetProvenance.referenced)
            .length;
        final unrefCount = selectedAssets.length - refCount;
        Fimber.d(
          "[VramChecker] selector=${selector.id} mod=${modInfo.modId} "
          "time=${selectorMs}ms referenced=$refCount unreferenced=$unrefCount "
          "total=${selectedAssets.length}",
        );
      }

      final totalFiles = selectedAssets.length;
      onFileProgress?.call(0, totalFiles, null);
      var processedFiles = 0;
      void onAssetDone(String relativePath) {
        processedFiles++;
        onFileProgress?.call(processedFiles, totalFiles, relativePath);
      }

      final referencedFutures = _processAssets(
        selectedAssets
            .where((a) => a.provenance == AssetProvenance.referenced)
            .toList(),
        imageHeaderReaderPool,
        onAssetDone: onAssetDone,
      );
      final unreferencedFutures = _processAssets(
        selectedAssets
            .where((a) => a.provenance == AssetProvenance.unreferenced)
            .toList(),
        imageHeaderReaderPool,
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
      if (showPerformance) {
        final headerMs = timeFinishedGettingFileData - timeFinishedSelector;
        progressText.appendAndPrint(
          "Finished getting file data for ${modInfo.formattedName} in $headerMs ms",
          verboseOut,
        );
        Fimber.d(
          "[VramChecker] headerRead mod=${modInfo.modId} "
          "refRows=${referencedRows.length} unrefRows=${unreferencedRows.length} "
          "time=${headerMs}ms",
        );
      }

      // Build columnar tables and views.
      final referencedTable = ModImageTable.fromRows(referencedRows);
      final unreferencedTable = unreferencedRows.isEmpty
          ? null
          : ModImageTable.fromRows(unreferencedRows);

      List<ModImageView> referencedViews = List.generate(
        referencedTable.length,
        (i) => ModImageView(i, referencedTable),
      );

      // The game only loads one background at a time and vanilla always has one loaded.
      // Therefore, a mod only increases the VRAM use by the size difference of the largest background over vanilla.
      referencedViews = _filterBackgroundsAgainstVanilla(
        referencedViews,
        modInfo.modFolder,
      );

      // Optionally log each image's details.
      for (var view in referencedViews) {
        if (showCountedFiles) {
          progressText.appendAndPrint(
            "${p.relative(view.file.path, from: modInfo.modFolder)} - TexHeight: ${view.textureHeight}, TexWidth: ${view.textureWidth}, ChannelBits: ${view.bitsInAllChannelsSum}, Mult: ${view.multiplier}\n   --> ${view.textureHeight} * ${view.textureWidth} * ${view.bitsInAllChannelsSum} * ${view.multiplier} = ${view.bytesUsed} bytes added over vanilla",
            verboseOut,
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
                if (view.referencedBy != null &&
                    view.referencedBy!.isNotEmpty)
                  'referencedBy': view.referencedBy,
              },
            )
            .toList(),
      );

      final mod = VramMod(
        modInfo,
        (enabledModIds ?? []).contains(modInfo.modId),
        filteredReferencedTable,
        graphicsLibEntries,
        unreferencedImages: unreferencedTable,
        scannedAt: DateTime.now(),
      );

      if (showPerformance) {
        progressText.appendAndPrint(
          "Finished calculating ${filteredReferencedTable.length} file sizes for ${mod.info.formattedName} in ${(DateTime.timestamp().millisecondsSinceEpoch - timeFinishedGettingFileData)} ms",
          verboseOut,
        );
      }
      progressText.appendAndPrint(
        mod.bytesNotIncludingGraphicsLib().bytesAsReadableMB(),
        verboseOut,
      );
      modProgressOut(mod);
      // Yield between mods so the UI thread gets a frame.
      await Future<void>.microtask(() {});
      return mod;
    }).toList()).sortedByDescending<num>((it) => it.bytesNotIncludingGraphicsLib()).toList();

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

  Iterable<Future<Map<String, dynamic>?>> _processAssets(
    Iterable<SelectedAsset> assets,
    ReadImageHeaders imageHeaderReaderPool, {
    void Function(String relativePath)? onAssetDone,
  }) {
    return assets.map((asset) async {
      if (isCancelled()) {
        throw Exception("Cancelled");
      }
      final file = asset.file;
      final imageType = file.relativePath.contains(BACKGROUND_FOLDER_NAME)
          ? ImageType.background
          : ImageType.texture;

      try {
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
      } catch (e) {
        if (showSkippedFiles) {
          progressText.appendAndPrint(
            "Skipped non-image ${file.relativePath} ($e)",
            verboseOut,
          );
        }
        return null;
      } finally {
        onAssetDone?.call(file.relativePath);
      }
    });
  }

  /// Backgrounds at or below vanilla size contribute nothing; among oversized
  /// backgrounds only the largest counts. Mirrors the previous behavior
  /// exactly — applied to referenced assets only.
  List<ModImageView> _filterBackgroundsAgainstVanilla(
    List<ModImageView> views,
    String modFolder,
  ) {
    final backgrounds = views
        .where((view) => view.imageType == ImageType.background)
        .toList();
    final largestBackground = backgrounds
        .where((view) => view.textureWidth > VANILLA_BACKGROUND_WIDTH)
        .maxByOrNull<num>((view) => view.bytesUsed);
    final backgroundsToDrop = {
      for (final view in backgrounds)
        if (largestBackground != null && view != largestBackground) view,
    };
    if (backgroundsToDrop.isNotEmpty) {
      progressText.appendAndPrint(
        "Skipping backgrounds that are not larger than vanilla and/or not the mod's largest background.",
        verboseOut,
      );
      for (var view in backgroundsToDrop) {
        progressText.appendAndPrint(
          "   ${p.relative(view.file.path, from: modFolder)}",
          verboseOut,
        );
      }
    }
    return views.where((v) => !backgroundsToDrop.contains(v)).toList();
  }

  Future<T> withFileHandleLimit<T>(Future<T> Function() function) async {
    while (currentFileHandles + 1 > maxFileHandles) {
      verboseOut(
        "Waiting for file handles to free up. Current file handles: $currentFileHandles",
      );
      await Future.delayed(const Duration(milliseconds: 100));
    }
    currentFileHandles++;
    try {
      return await function();
    } finally {
      currentFileHandles--;
    }
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
