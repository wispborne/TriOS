import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:path/path.dart' as p;
import 'package:squadron/squadron.dart';
import 'package:vram_estimator_flutter/extensions.dart';
import 'package:vram_estimator_flutter/image_reader/png_chatgpt.dart';
import 'package:yaml/yaml.dart';

import 'image_reader.dart';
import 'models/gpu_info.dart';
import 'models/graphics_lib_config.dart';
import 'models/graphics_lib_info.dart';
import 'models/mod_image.dart';
import 'models/mod_info.dart';
import 'models/mod_info_json.dart';
import 'models/mod_result.dart';

class VramChecker {
  List<String>? enabledModIds;
  List<String>? modIdsToCheck;
  List<Directory> foldersToCheck;
  bool showGfxLibDebugOutput;
  bool showPerformance;
  bool showSkippedFiles;
  bool showCountedFiles;
  GraphicsLibConfig graphicsLibConfig;
  Function(String) verboseOut = (it) => (it);
  Function(String) debugOut = (it) => (it);
  int maxFileHandles;

  VramChecker({
    this.enabledModIds,
    this.modIdsToCheck,
    required this.foldersToCheck,
    required this.showGfxLibDebugOutput,
    required this.showPerformance,
    required this.showSkippedFiles,
    required this.showCountedFiles,
    required this.graphicsLibConfig,
    this.maxFileHandles = 2000,
    Function(String)? verboseOut,
    Function(String)? debugOut,
  }) {
    if (verboseOut != null) {
      this.verboseOut = verboseOut;
    }
    if (debugOut != null) {
      this.debugOut = debugOut;
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

  Future<List<Mod>> check() async {
    progressText = StringBuffer();
    modTotals = StringBuffer();
    summaryText = StringBuffer();
    startTime = DateTime.timestamp().millisecondsSinceEpoch;

    const csvReader =
        CsvToListConverter(allowInvalid: true, convertEmptyTo: null);
    // .skipEmptyRows(true)
    // .errorOnDifferentFieldCount(false);

    final jsonMapper = JsonMapper();
//     .defaultLeniency(true)
//     .enable(
// JsonReadFeature.ALLOW_JAVA_COMMENTS, JsonReadFeature.ALLOW_SINGLE_QUOTES,
// JsonReadFeature.ALLOW_YAML_COMMENTS, JsonReadFeature.ALLOW_MISSING_VALUES,
// JsonReadFeature.ALLOW_TRAILING_COMMA, JsonReadFeature.ALLOW_UNQUOTED_FIELD_NAMES,
// JsonReadFeature.ALLOW_UNESCAPED_CONTROL_CHARS,
// JsonReadFeature.ALLOW_BACKSLASH_ESCAPING_ANY_CHARACTER,
// JsonReadFeature.ALLOW_LEADING_DECIMAL_POINT_FOR_NUMBERS
// )
//     .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
//     .build()

    if (foldersToCheck.none((it) => it.existsSync())) {
      throw Exception(
          "This doesn't exist! ${foldersToCheck.joinToString(transform: (it) => it.absolute.toString())}");
    }

    progressText.appendAndPrint(
        "GraphicsLib Config: $graphicsLibConfig", debugOut);

    if (enabledModIds != null) {
      progressText.appendAndPrint(
          "\nEnabled Mods:\n${enabledModIds?.join("\n")}", verboseOut);
    }

    progressText.appendAndPrint(
        "Mods folders: ${foldersToCheck.joinToString(transform: (it) => it.absolute.toString())}",
        verboseOut);

    Squadron.setId('VRAM_CHECKER');
    // Squadron.logLevel = SquadronLogLevel.config;
    // Squadron.setLogger(ConsoleSquadronLogger());
    const settings =
        ConcurrencySettings(minWorkers: 1, maxWorkers: 4, maxParallel: 4);
    final imageHeaderReaderPool =
        ReadImageHeadersWorkerPool(concurrencySettings: settings);

    final mods = (await Stream.fromIterable(foldersToCheck)
            .where((it) => it.existsSync())
            .expand((it) => it.listSync())
            .where((it) => FileSystemEntity.isDirectorySync(it.path))
            .asyncMap((it) =>
                getModInfo(jsonMapper, Directory(it.path), progressText))
            .where((it) => it != null)
            .map((modInfo) => modInfo!)
            .where((it) => (modIdsToCheck == null)
                ? true
                : modIdsToCheck?.contains(it.id) == true)
            .asyncMap((modInfo) async {
      progressText.appendAndPrint("\nFolder: ${modInfo.name}", verboseOut);
      final startTimeForMod = DateTime.timestamp().millisecondsSinceEpoch;

      final filesInMod = modInfo.modFolder
          .listSync(recursive: true)
          .filter((it) => it is File)
          .map((it) => it as File)
          .toList();

      final myGraphicsLibFilesToExcludeForMod = graphicsLibFilesToExcludeForMod(
          filesInMod,
          csvReader,
          progressText,
          showGfxLibDebugOutput,
          graphicsLibConfig);

      final timeFinishedGettingGraphicsLibData =
          DateTime.timestamp().millisecondsSinceEpoch;
      if (showPerformance) {
        progressText.appendAndPrint(
            "Finished getting GraphicsLib images for ${modInfo.name} in ${(timeFinishedGettingGraphicsLibData - startTimeForMod)} ms",
            verboseOut);
      }

      final modImages = (await Future.wait(filesInMod.filter((it) {
        final ext = p.extension(it.path).toLowerCase();
        return ext.endsWith(".png") ||
            ext.endsWith(".jpg") ||
            ext.endsWith(".jpeg") ||
            ext.endsWith(".gif");
      }).map((file) async {
        ImageType imageType;
        if (file
            .relativePath(modInfo.modFolder)
            .contains(BACKGROUND_FOLDER_NAME)) {
          imageType = ImageType.Background;
        } else if (UNUSED_INDICATOR.any((suffix) =>
            file.relativePath(modInfo.modFolder).contains(suffix))) {
          imageType = ImageType.Unused;
        } else {
          imageType = ImageType.Texture;
        }

        if (file.name.endsWith(".png")) {
          return await getModImagePng(
                  imageHeaderReaderPool, file, imageType, modInfo) ??
              await getModImageGeneric(
                  imageHeaderReaderPool, file, modInfo, imageType);
        } else {
          return await getModImageGeneric(
              imageHeaderReaderPool, file, modInfo, imageType);
        }
      })))
          .whereNotNull();

      final timeFinishedGettingFileData =
          DateTime.timestamp().millisecondsSinceEpoch;
      if (showPerformance) {
        progressText.appendAndPrint(
            "Finished getting file data for ${modInfo.formattedName} in ${(timeFinishedGettingFileData - timeFinishedGettingGraphicsLibData)} ms",
            verboseOut);
      }

      final imagesToSumUp = modImages.toList();

      final unusedImages = imagesToSumUp.where((it) {
        return it.imageType == ImageType.Unused;
      });

      if (unusedImages.isNotEmpty && showSkippedFiles) {
        progressText.appendAndPrint("Skipping unused files", verboseOut);
      }

      for (var it in unusedImages) {
        progressText.appendAndPrint(
            "  ${it.file.relativePath(modInfo.modFolder)}", verboseOut);
      }

      imagesToSumUp.removeAll(unusedImages);

// The game only loads one background at a time and vanilla always has one loaded.
// Therefore, a mod only increases the VRAM use by the size difference of the largest background over vanilla.
      final largestBackgroundBiggerThanVanilla = modImages
          .filter((it) =>
              it.imageType == ImageType.Background &&
              it.textureWidth > VANILLA_BACKGROUND_WIDTH)
          .maxByOrNull<num>((it) => it.bytesUsed);

      final modBackgroundsSmallerThanLargestVanilla = modImages.filter((it) =>
          it.imageType == ImageType.Background &&
          it != largestBackgroundBiggerThanVanilla);

      if (modBackgroundsSmallerThanLargestVanilla.isNotEmpty) {
        progressText.appendAndPrint(
            "Skipping backgrounds that are not larger than vanilla and/or not the mod's largest background.",
            verboseOut);
      }
      for (var it in modBackgroundsSmallerThanLargestVanilla) {
        progressText.appendAndPrint(
            "   ${it.file.relativePath(modInfo.modFolder)}", verboseOut);
      }

      imagesToSumUp.removeAll(modBackgroundsSmallerThanLargestVanilla);

      for (var image in imagesToSumUp) {
        if (showCountedFiles) {
          progressText.appendAndPrint(
              "${image.file.relativePath(modInfo.modFolder)} - TexHeight: ${image.textureHeight}, TexWidth: ${image.textureWidth}, ChannelBits: ${image.bitsInAllChannelsSum}, Mult: ${image.multiplier}\n   --> ${image.textureHeight} * ${image.textureWidth} * ${image.bitsInAllChannelsSum} * ${image.multiplier} = ${image.bytesUsed} bytes added over vanilla",
              verboseOut);
        }
      }

      final List<ModImage> imagesWithoutExcludedGfxLibMaps;
      if ((myGraphicsLibFilesToExcludeForMod != null)) {
        final glibPaths =
            myGraphicsLibFilesToExcludeForMod.map((it) => it.relativeFilePath);
        imagesWithoutExcludedGfxLibMaps = imagesToSumUp
            .whereNot((image) =>
                glibPaths.contains(image.file.relativeTo(modInfo.modFolder)))
            .toList();
      } else {
        imagesWithoutExcludedGfxLibMaps = imagesToSumUp;
      }

      final mod = Mod(modInfo, (enabledModIds ?? []).contains(modInfo.id),
          imagesWithoutExcludedGfxLibMaps);

      if (showPerformance) {
        progressText.appendAndPrint(
            "Finished calculating ${mod.images.length} file sizes for ${mod.info.formattedName} in ${(DateTime.timestamp().millisecondsSinceEpoch - timeFinishedGettingFileData)} ms",
            verboseOut);
      }
      progressText.appendAndPrint(
          mod.totalBytesForMod.bytesAsReadableMB(), verboseOut);

      return mod;
    }).toList())
        .sortedByDescending<num>((it) => it.totalBytesForMod)
        .toList();

    for (var mod in mods) {
      modTotals.writeln();
      modTotals.writeln(
          "${mod.info.formattedName} - ${mod.images.length} images - ${(mod.isEnabled) ? "Enabled" : "Disabled"}");
      modTotals.writeln(mod.totalBytesForMod.bytesAsReadableMB());
    }

    final enabledMods = mods.filter((mod) => mod.isEnabled);
    final totalBytes = mods.getBytesUsedByDedupedImages();

    final totalBytesOfEnabledMods = enabledMods.getBytesUsedByDedupedImages();

    if (showPerformance) {
      progressText.appendAndPrint(
          "Finished run in ${(DateTime.timestamp().millisecondsSinceEpoch - startTime)} ms",
          verboseOut);
    }

    final enabledModsString = enabledMods
        .joinToString(
            separator: "\n    ", transform: (it) => it.info.formattedName)
        .ifBlank("(none)");

    progressText.appendAndPrint("\n", verboseOut);
    summaryText.writeln();
    summaryText.writeln("-------------");
    summaryText.writeln("VRAM Use Estimates");
    summaryText.writeln();
    summaryText.writeln("Configuration");
    summaryText.writeln("  Enabled Mods");
    summaryText.writeln("    $enabledModsString");
    summaryText.writeln("  GraphicsLib");
    summaryText.writeln(
        "    Normal Maps Enabled: ${graphicsLibConfig.areGfxLibNormalMapsEnabled}");
    summaryText.writeln(
        "    Material Maps Enabled: ${graphicsLibConfig.areGfxLibMaterialMapsEnabled}");
    summaryText.writeln(
        "    Surface Maps Enabled: ${graphicsLibConfig.areGfxLibSurfaceMapsEnabled}");
    summaryText.writeln(
        "    Edit 'config.properties' to choose your GraphicsLib settings.");
    try {
      getGPUInfo()?.also((info) {
        summaryText.writeln("  System");
        summaryText.writeln(info.gpuString
            ?.joinToString(separator: "\n", transform: (it) => "    $it"));

// If expected VRAM after loading game and mods is less than 300 MB, show warning
        if (info.freeVRAM -
                (totalBytesOfEnabledMods + VANILLA_GAME_VRAM_USAGE_IN_BYTES) <
            300000) {
          summaryText.writeln();
          summaryText.writeln(
              "WARNING: You may not have enough free VRAM to run your current modlist.");
        }
      });
    } catch (it, st) {
      summaryText.writeln();
      summaryText
          .writeln("Unable to get GPU information due to the follow error:");
      summaryText.writeln(st.toString());
    }
    summaryText.writeln();

    summaryText.writeln(
        "Enabled + Disabled Mods w/o Vanilla".padRight(OUTPUT_LABEL_WIDTH) +
            totalBytes.bytesAsReadableMB());
    summaryText.writeln("Enabled + Disabled Mods w/ Vanilla"
            .padRight(OUTPUT_LABEL_WIDTH) +
        (totalBytes + VANILLA_GAME_VRAM_USAGE_IN_BYTES).bytesAsReadableMB());
    summaryText.writeln();
    summaryText.writeln(
        "Enabled Mods w/o Vanilla".padRight(OUTPUT_LABEL_WIDTH) +
            totalBytesOfEnabledMods.bytesAsReadableMB());
    summaryText.writeln("Enabled Mods w/ Vanilla".padRight(OUTPUT_LABEL_WIDTH) +
        (totalBytesOfEnabledMods + VANILLA_GAME_VRAM_USAGE_IN_BYTES)
            .bytesAsReadableMB());

    summaryText.writeln();
    summaryText.writeln(
        "** This is only an estimate of VRAM use and actual use may be higher or lower.");
    summaryText.writeln(
        "** Unused images in mods are counted unless they contain one of ${UNUSED_INDICATOR.joinToString(transform: (it) => "\"$it\"")} in the file name.");

    var currentFolder = Directory.current.path;
    var outputFile = File("$currentFolder/VRAM_usage_of_mods.txt");
    if (outputFile.existsSync()) outputFile.delete();
    outputFile.create();
    outputFile.writeAsStringSync("$progressText\n$modTotals\n$summaryText");

    summaryText.writeln(
        "\nFile written to ${outputFile.absolute.path}.\nSummary copied to clipboard, ready to paste.");

    verboseOut(modTotals.toString());
    debugOut(summaryText.toString());

    imageHeaderReaderPool.stop();

    return mods;
  }

  Future<ModImage?> getModImagePng(
      ReadImageHeadersWorkerPool imageHeaderReaderPool,
      File file,
      ImageType imageType,
      ModInfo modInfo) async {
    ImageHeader? image;
    try {
      image =
          // await withFileHandleLimit(() => readPngFileHeaders(file.path));
          await withFileHandleLimit(
              () => imageHeaderReaderPool.readPng(file.path));

      if (image == null) {
        throw Exception("Image is null");
      }

      return ModImage(
          file,
          (image.width == 1) ? 1 : (image.width - 1).highestOneBit() * 2,
          (image.height == 1) ? 1 : (image.height - 1).highestOneBit() * 2,
          // image!.colorModel.componentSize.toList(),
          image.bitDepth * image.numChannels,
          imageType);
    } catch (e) {
      if (showSkippedFiles) {
        progressText.appendAndPrint(
            "Skipped non-image ${file.relativePath(modInfo.modFolder)} ($e)",
            verboseOut);
      }

      return null;
    }
  }

  Future<ModImage?> getModImageGeneric(
      ReadImageHeadersWorkerPool imageHeaderReaderPool,
      File file,
      ModInfo modInfo,
      ImageType imageType) async {
    ImageHeader? image;
    try {
      image =
          // await withFileHandleLimit(() => readPngFileHeaders(file.path));
          await withFileHandleLimit(
              () => imageHeaderReaderPool.readGeneric(file.path));

      if (image == null) {
        throw Exception("Image is null");
      }
      // }
    } catch (e) {
      if (showSkippedFiles) {
        progressText.appendAndPrint(
            "Skipped non-image ${file.relativePath(modInfo.modFolder)} ($e)",
            verboseOut);
      }

      return null;
    }

    return ModImage(
        file,
        (image.width == 1) ? 1 : (image.width - 1).highestOneBit() * 2,
        (image.height == 1) ? 1 : (image.height - 1).highestOneBit() * 2,
        // image!.colorModel.componentSize.toList(),
        image.bitDepth * image.numChannels,
        imageType);
  }

  // Future<ModInfo?> loadModInfo(File file) async {
  Future<ModInfo?> getModInfo(JsonMapper jsonMapper, Directory modFolder,
      StringBuffer progressText) async {
    try {
      return modFolder
          .listSync()
          .whereType<File>()
          .firstWhereOrNull((file) => file.name == "mod_info.json")
          ?.let((modInfoFile) async {
        var rawString =
            await withFileHandleLimit(() => modInfoFile.readAsString());
        var jsonEncodedYaml =
            json.encode(loadYaml((rawString).replaceAll("\t", "  ")));
        // final jsonAsMap = jsonDecode(jsonEncodedYaml) as Map<String, dynamic>;

        try {
          final model =
              JsonMapper.deserialize<ModInfoJsonModel_095a>(jsonEncodedYaml)!;

          progressText.appendAndPrint(
              "Using 0.9.5a mod_info.json format for ${modInfoFile.absolute}",
              verboseOut);

          return ModInfo(model.id, modFolder, model.name,
              "${model.version.major}.${model.version.minor}.${model.version.patch}");
        } catch (e) {
          final model =
              JsonMapper.deserialize<ModInfoJsonModel_091a>(jsonEncodedYaml)!;

          progressText.appendAndPrint(
              "Using 0.9.1a mod_info.json format for ${modInfoFile.absolute}",
              verboseOut);

          return ModInfo(model.id, modFolder, model.name, model.version);
        }
      });
    } catch (e, st) {
      progressText.appendAndPrint(
          "Unable to find or read 'mod_info.json' in ${modFolder.absolute}. ($e)\n$st",
          verboseOut);
      return null;
    }
  }

  List<GraphicsLibInfo>? graphicsLibFilesToExcludeForMod(
      List<File> filesInMod,
      CsvToListConverter csvReader,
      StringBuffer progressText,
      bool showGfxLibDebugOutput,
      GraphicsLibConfig graphicsLibConfig) {
    return filesInMod
        .filter((it) => it.name.endsWith(".csv"))
        .map((file) {
          try {
            return csvReader.convert(file.readAsStringSync());
          } catch (e) {
            progressText.appendAndPrint(
                "Unable to read ${file.path}: ${e}", verboseOut);
          }

          return [null];
        })
        .whereNotNull()
        .filter((it) => it.isNotEmpty)
// Look for a CSV with a header row containing certain column names
        .firstWhereOrNull((it) =>
            it.first?.containsAll(["id", "type", "map", "path"]) == true)
        ?.let((it) {
          final mapColumn = it.first?.indexOf("map");
          final pathColumn = it.first?.indexOf("path");

          if (mapColumn == null || pathColumn == null) {
            progressText.appendAndPrint(
                "Unable to find 'map' or 'path' column", verboseOut);
            return null;
          }

          return it
              .map((List<dynamic>? row) {
                try {
                  final mapType = switch (row![mapColumn]) {
                    "normal" => MapType.Normal,
                    "material" => MapType.Material,
                    "surface" => MapType.Surface,
                    _ => null
                  };

                  if (mapType == null) {
                    return null;
                  }

                  final path = row[pathColumn].trim();
                  return GraphicsLibInfo(mapType, p.normalize(path));
                } catch (e) {
                  progressText.appendAndPrint("$row - ${e}", verboseOut);
                }

                return null;
              })
              .whereNotNull()
              .filter((it) => switch (it.mapType) {
                    MapType.Normal =>
                      !graphicsLibConfig.areGfxLibNormalMapsEnabled,
                    MapType.Material =>
                      !graphicsLibConfig.areGfxLibMaterialMapsEnabled,
                    MapType.Surface =>
                      !graphicsLibConfig.areGfxLibSurfaceMapsEnabled,
                    _ => false
                  })
              .also((it) {
                if (showGfxLibDebugOutput) {
                  for (var info in it) {
                    progressText.appendAndPrint(info.toString(), verboseOut);
                  }
                }
              })
              .toList();
        });
  }

  Future<T> withFileHandleLimit<T>(Future<T> Function() function) async {
    while (currentFileHandles + 1 > maxFileHandles) {
      verboseOut(
          "Waiting for file handles to free up. Current file handles: $currentFileHandles");
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
