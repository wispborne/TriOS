import 'dart:core';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';

import '../models/mod_variant.dart';
import '../utils/util.dart';
import 'image_reader/image_reader_async.dart';
import 'image_reader/png_chatgpt.dart';
import 'models/gpu_info.dart';
import 'models/graphics_lib_config.dart';
import 'models/graphics_lib_info.dart';
import 'models/vram_checker_models.dart';

class VramChecker {
  List<String>? enabledModIds;
  List<ModVariant> variantsToCheck;
  bool showGfxLibDebugOutput;
  bool showPerformance;
  bool showSkippedFiles;
  bool showCountedFiles;
  GraphicsLibConfig graphicsLibConfig;
  Function(VramMod) modProgressOut = (it) => (it);
  Function(String) verboseOut = (it) => (it);
  Function(String) debugOut = (it) => (it);
  bool Function() isCancelled;

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
    Function(VramMod)? modProgressOut,
    Function(String)? verboseOut,
    Function(String)? debugOut,
    required this.isCancelled,
  }) {
    if (verboseOut != null) {
      this.verboseOut = verboseOut;
    }
    if (debugOut != null) {
      this.debugOut = debugOut;
    }
    if (modProgressOut != null) {
      this.modProgressOut = modProgressOut;
    }
  }

  static const VANILLA_BACKGROUND_WIDTH = 2048;
  static const VANILLA_BACKGROUND_TEXTURE_SIZE_IN_BYTES = 12582912.0;
  static const VANILLA_GAME_VRAM_USAGE_IN_BYTES =
      433586176.0; // 0.9.1a, per https://fractalsoftworks.com/forum/index.php?topic=8726.0
  static const OUTPUT_LABEL_WIDTH = 38;

  /// If one of these strings is in the filename, the file is skipped *
  static const UNUSED_INDICATOR = ["CURRENTLY_UNUSED", "DO_NOT_USE"];
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

    const csvReader = CsvToListConverter(
      allowInvalid: true,
      convertEmptyTo: null,
    );

    progressText.appendAndPrint(
      "GraphicsLib Config: $graphicsLibConfig",
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
    final mods =
        (await Stream.fromIterable(
              variantsToCheck.map(
                (it) => VramCheckerMod(it.modInfo, it.modFolder.path),
              ),
            ).asyncMap((modInfo) async {
              progressText.appendAndPrint(
                "\nFolder: ${modInfo.name}",
                verboseOut,
              );
              if (isCancelled()) {
                throw Exception("Cancelled");
              }
              final startTimeForMod =
                  DateTime.timestamp().millisecondsSinceEpoch;
              final baseFolderPath = modInfo.modFolder;

              // Gather all file data for this mod.
              final filesInMod = modInfo.modFolder
                  .toDirectory()
                  .listSync(recursive: true)
                  .whereType<File>()
                  .map((file) {
                    final relPath = p.relative(file.path, from: baseFolderPath);
                    return _FileData(
                      file: file,
                      relativePath: file.relativePath(
                        modInfo.modFolder.toDirectory(),
                      ),
                    );
                  })
                  .toList();

              // Get GraphicsLib settings from CSV files.
              final List<GraphicsLibInfo> graphicsLibEntries =
                  _getGraphicsLibSettingsForMod(
                    filesInMod,
                    csvReader,
                    progressText,
                  ) ??
                  [];

              final timeFinishedGettingGraphicsLibData =
                  DateTime.timestamp().millisecondsSinceEpoch;
              if (showPerformance) {
                progressText.appendAndPrint(
                  "Finished getting GraphicsLib images for ${modInfo.name} in ${(timeFinishedGettingGraphicsLibData - startTimeForMod)} ms",
                  verboseOut,
                );
              }

              // Process image files (png, jpg, etc.).
              final imageRowFutures = filesInMod
                  .where((it) => it.file.isImage)
                  .map((file) async {
                    if (isCancelled()) {
                      throw Exception("Cancelled");
                    }
                    ImageType imageType;
                    if (file.relativePath.contains(BACKGROUND_FOLDER_NAME)) {
                      imageType = ImageType.background;
                    } else if (UNUSED_INDICATOR.any(
                      (suffix) => file.relativePath.contains(suffix),
                    )) {
                      imageType = ImageType.unused;
                    } else {
                      imageType = ImageType.texture;
                    }

                    MapType? graphicsLibType;

                    // Hardcode logic that the cache folder of GraphicsLib
                    // always contains normal maps.
                    if (modInfo.modId == Constants.graphicsLibId &&
                        file.file.path.contains("cache")) {
                      graphicsLibType = MapType.Normal;
                    } else {
                      graphicsLibType = graphicsLibEntries
                          .firstWhereOrNull(
                            (it) => it.relativeFilePath == file.relativePath,
                          )
                          ?.mapType;
                    }
                    final ext = file.file.nameWithExtension.toLowerCase();
                    if (ext.endsWith(".png")) {
                      return await _getModImagePng(
                        imageHeaderReaderPool,
                        file,
                        imageType,
                        modInfo,
                        graphicsLibType,
                      );
                    } else {
                      return await _getModImageGeneric(
                        imageHeaderReaderPool,
                        file,
                        modInfo,
                        imageType,
                        graphicsLibType,
                      );
                    }
                  });

              // Gather non-null image rows.
              final modImageRows = (await Future.wait(
                imageRowFutures,
              )).nonNulls.toList();

              final timeFinishedGettingFileData =
                  DateTime.timestamp().millisecondsSinceEpoch;
              if (showPerformance) {
                progressText.appendAndPrint(
                  "Finished getting file data for ${modInfo.formattedName} in ${(timeFinishedGettingFileData - timeFinishedGettingGraphicsLibData)} ms",
                  verboseOut,
                );
              }

              // Build a columnar table from the row maps.
              final fullTable = ModImageTable.fromRows(modImageRows);
              // Create views for each row.
              List<ModImageView> imageViews = List.generate(
                fullTable.length,
                (i) => ModImageView(i, fullTable),
              );

              // Filter out unused images.
              final unusedViews = imageViews
                  .where((view) => view.imageType == ImageType.unused)
                  .toList();
              if (unusedViews.isNotEmpty && showSkippedFiles) {
                progressText.appendAndPrint(
                  "Skipping unused files",
                  verboseOut,
                );
                for (var view in unusedViews) {
                  progressText.appendAndPrint(
                    "  ${p.relative(view.file.path, from: modInfo.modFolder)}",
                    verboseOut,
                  );
                }
              }
              imageViews.removeWhere(
                (view) => view.imageType == ImageType.unused,
              );

              // The game only loads one background at a time and vanilla always has one loaded.
              // Therefore, a mod only increases the VRAM use by the size difference of the largest background over vanilla.
              final backgroundViews = imageViews
                  .where((view) => view.imageType == ImageType.background)
                  .toList();
              final largestBackground = backgroundViews
                  .where((view) => view.textureWidth > VANILLA_BACKGROUND_WIDTH)
                  .maxByOrNull<num>((view) => view.bytesUsed);
              final modBackgroundsSmallerThanLargestVanilla = backgroundViews
                  .where(
                    (view) =>
                        largestBackground != null && view != largestBackground,
                  )
                  .toList();
              if (modBackgroundsSmallerThanLargestVanilla.isNotEmpty) {
                progressText.appendAndPrint(
                  "Skipping backgrounds that are not larger than vanilla and/or not the mod's largest background.",
                  verboseOut,
                );
                for (var view in modBackgroundsSmallerThanLargestVanilla) {
                  progressText.appendAndPrint(
                    "   ${p.relative(view.file.path, from: modInfo.modFolder)}",
                    verboseOut,
                  );
                }
              }
              imageViews.removeWhere(
                (view) =>
                    modBackgroundsSmallerThanLargestVanilla.contains(view),
              );

              // Optionally log each image’s details.
              for (var view in imageViews) {
                if (showCountedFiles) {
                  progressText.appendAndPrint(
                    "${p.relative(view.file.path, from: modInfo.modFolder)} - TexHeight: ${view.textureHeight}, TexWidth: ${view.textureWidth}, ChannelBits: ${view.bitsInAllChannelsSum}, Mult: ${view.multiplier}\n   --> ${view.textureHeight} * ${view.textureWidth} * ${view.bitsInAllChannelsSum} * ${view.multiplier} = ${view.bytesUsed} bytes added over vanilla",
                    verboseOut,
                  );
                }
              }

              // Reassemble the final table from the remaining image views.
              final filteredRows = imageViews
                  .map(
                    (view) => {
                      'filePath': view.filePath,
                      'textureHeight': view.textureHeight,
                      'textureWidth': view.textureWidth,
                      'bitsInAllChannelsSum': view.bitsInAllChannelsSum,
                      'imageType': view.imageType.name,
                      'graphicsLibType': view.graphicsLibType?.name,
                    },
                  )
                  .toList();
              final finalTable = ModImageTable.fromRows(filteredRows);

              final mod = VramMod(
                modInfo,
                (enabledModIds ?? []).contains(modInfo.modId),
                finalTable,
                graphicsLibEntries,
              );

              if (showPerformance) {
                progressText.appendAndPrint(
                  "Finished calculating ${finalTable.length} file sizes for ${mod.info.formattedName} in ${(DateTime.timestamp().millisecondsSinceEpoch - timeFinishedGettingFileData)} ms",
                  verboseOut,
                );
              }
              progressText.appendAndPrint(
                mod
                    .bytesNotIncludingGraphicsLib()
                    .bytesAsReadableMB(),
                verboseOut,
              );
              modProgressOut(mod);
              return mod;
            }).toList())
            .sortedByDescending<num>(
              (it) => it.bytesNotIncludingGraphicsLib(),
            )
            .toList();

    for (var mod in mods) {
      modTotals.writeln();
      modTotals.writeln(
        "${mod.info.formattedName} - ${mod.images.length} images - ${(mod.isEnabled) ? "Enabled" : "Disabled"}",
      );
      modTotals.writeln(
        mod
            .bytesNotIncludingGraphicsLib()
            .bytesAsReadableMB(),
      );
    }

    final enabledMods = mods.where((mod) => mod.isEnabled);
    final totalBytes = mods.getBytesUsedByDedupedImages();
    final totalBytesOfEnabledMods = enabledMods.getBytesUsedByDedupedImages();

    if (showPerformance) {
      progressText.appendAndPrint(
        "Finished run in ${(DateTime.timestamp().millisecondsSinceEpoch - startTime)} ms",
        verboseOut,
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
    summaryText.writeln(
      "** Unused images in mods are counted unless they contain one of ${UNUSED_INDICATOR.joinToString(transform: (it) => "\"$it\"")} in the file name.",
    );

    // var currentFolder = currentDirectory.path;
    // var outputFile = File("$currentFolder/VRAM_usage_of_mods.txt");
    // outputFile.writeAsStringSync("$progressText\n$modTotals\n$summaryText",
    //     flush: true);
    //
    // summaryText.writeln(
    //     "\nFile written to ${outputFile.absolute.path}.\nSummary copied to clipboard, ready to paste.");

    verboseOut(modTotals.toString());
    debugOut(summaryText.toString());

    return mods;
  }

  // Update helper functions to return a row-map instead of a ModImage

  Future<Map<String, dynamic>?> _getModImagePng(
    ReadImageHeaders imageHeaderReaderPool,
    _FileData file,
    ImageType imageType,
    VramCheckerMod modInfo,
    MapType? graphicsLibType,
  ) async {
    ImageHeader? image;
    try {
      image = await withFileHandleLimit(
        () => imageHeaderReaderPool.readPng(file.file.path),
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
        'graphicsLibType': graphicsLibType?.name,
      };
    } catch (e) {
      if (showSkippedFiles) {
        progressText.appendAndPrint(
          "Skipped non-image ${file.relativePath} ($e)",
          verboseOut,
        );
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getModImageGeneric(
    ReadImageHeaders imageHeaderReaderPool,
    _FileData file,
    VramCheckerMod modInfo,
    ImageType imageType,
    MapType? graphicsLibType,
  ) async {
    ImageHeader? image;
    try {
      image = await withFileHandleLimit(
        () => imageHeaderReaderPool.readGeneric(file.file.path),
      );
      if (image == null) {
        throw Exception("Image is null");
      }
    } catch (e) {
      if (showSkippedFiles) {
        progressText.appendAndPrint(
          "Skipped non-image ${file.relativePath} ($e)",
          verboseOut,
        );
      }
      return null;
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
      'graphicsLibType': graphicsLibType?.name,
    };
  }

  List<GraphicsLibInfo>? _getGraphicsLibSettingsForMod(
    List<_FileData> filesInMod,
    CsvToListConverter csvReader,
    StringBuffer progressText,
  ) {
    final modGraphicsLibSettingsFile = filesInMod
        .filter((it) => it.file.nameWithExtension.endsWith(".csv"))
        .map((file) {
          try {
            return csvReader.convert(file.file.readAsStringSync().replaceAll("\r\n", "\n"), eol: "\n");
          } catch (e) {
            progressText.appendAndPrint(
              "Unable to read ${file.file.path}: $e",
              verboseOut,
            );
          }

          return [null];
        })
        .nonNulls
        .filter((csvRows) => csvRows.isNotEmpty)
        .firstWhereOrNull(
          (csvRows) =>
              csvRows.first?.containsAll(["id", "type", "map", "path"]) == true,
        );

    if (modGraphicsLibSettingsFile == null) {
      return null;
    }

    final idColumn = modGraphicsLibSettingsFile.first!.indexOf("id");
    final mapColumn = modGraphicsLibSettingsFile.first!.indexOf("map");
    final pathColumn = modGraphicsLibSettingsFile.first!.indexOf("path");

    return modGraphicsLibSettingsFile
        .map((List<dynamic>? row) {
          try {
            final mapType = switch (row![mapColumn]) {
              "normal" => MapType.Normal,
              "material" => MapType.Material,
              "surface" => MapType.Surface,
              _ => null,
            };

            if (mapType == null) {
              return null;
            }

            final path = row[pathColumn].trim();
            return GraphicsLibInfo(row[idColumn], mapType, p.normalize(path));
          } catch (e) {
            progressText.appendAndPrint("$row - $e", verboseOut);
          }

          return null;
        })
        .nonNulls
        .toList();
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
    // Use a set keyed by (modFolder, filePath)
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

extension _FileExtensions on File {
  bool get isImage {
    final ext = p.extension(path).toLowerCase();
    return ext.endsWith(".png") ||
        ext.endsWith(".jpg") ||
        ext.endsWith(".jpeg") ||
        ext.endsWith(".gif") ||
        ext.endsWith(".webp");
  }
}

class _FileData {
  final File file;
  final String relativePath;

  _FileData({required this.file, required this.relativePath});
}
