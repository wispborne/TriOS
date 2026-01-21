import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

/// Reads and parses a mod_info.json file from a mod folder.
///
/// Looks for both enabled (`mod_info.json`) and disabled (`mod_info.json.disabled`)
/// variants. Returns null if the file doesn't exist or can't be parsed.
Future<ModInfo?> getModInfo(
  Directory modFolder,
  StringBuffer progressText,
) async {
  try {
    final possibleModInfos = [
      Constants.modInfoFileName,
      ...Constants.modInfoFileDisabledNames,
    ].map((it) => modFolder.resolve(it).toFile()).toList();

    return possibleModInfos.firstWhereOrNull((file) => file.existsSync())?.let((
      modInfoFile,
    ) async {
      var rawString = await withFileHandleLimit(
        () => modInfoFile.readAsString(),
      );
      var jsonEncodedYaml = (rawString).replaceAll("\t", "  ").fixJson();

      final model = ModInfo.fromJsonModel(
        ModInfoJsonMapper.fromJson(jsonEncodedYaml),
        modFolder,
      );

      return model;
    });
  } catch (e, st) {
    Fimber.v(
      () =>
          "Unable to find or read 'mod_info.json' in ${modFolder.absolute}. ($e)\n$st",
    );
    return null;
  }
}

/// Finds a mod_info.json file in the mod folder.
///
/// Returns a disabled one if no enabled one is found.
/// Returns null if no mod_info.json file exists in any form.
File? getModInfoFile(Directory modFolder) {
  final regularModInfoFile = modFolder
      .resolve(Constants.modInfoFileName)
      .toFile();
  if (regularModInfoFile.existsSync()) {
    return regularModInfoFile;
  }

  for (var disabledModInfoFileName in Constants.modInfoFileDisabledNames) {
    final disabledModInfoFile = modFolder
        .resolve(disabledModInfoFileName)
        .toFile();
    if (disabledModInfoFile.existsSync()) {
      return disabledModInfoFile;
    }
  }

  return null;
}

/// Reads the version checker CSV file and returns the path to the version JSON file.
///
/// Returns null if the CSV doesn't exist or can't be read.
File? getVersionFile(Directory modFolder) {
  final csv = File(p.join(modFolder.path, Constants.versionCheckerCsvPath));
  if (!csv.existsSync()) return null;
  try {
    return modFolder
        .resolve(
          (const CsvToListConverter(
                eol: "\n",
              ).convert(csv.readAsStringSync().replaceAll("\r\n", "\n"))[1][0]
              as String),
        )
        .toFile();
  } catch (e, st) {
    Fimber.e(
      "Unable to read version checker csv file in ${modFolder.absolute}. ($e)\n$st",
    );
    return null;
  }
}

/// Reads and parses a version checker JSON file.
///
/// Cleans up the mod thread ID by removing non-numeric characters
/// and handling empty IDs. Returns null if the file doesn't exist or can't be parsed.
VersionCheckerInfo? getVersionCheckerInfo(File versionFile) {
  if (!versionFile.existsSync()) return null;
  try {
    var info = VersionCheckerInfoMapper.fromJson(
      versionFile.readAsStringSync().fixJson(),
    );

    if (info.modThreadId != null) {
      info = info.copyWith(
        modThreadId: info.modThreadId?.replaceAll(RegExp(r'[^0-9.]'), ''),
      );

      if (info.modThreadId!.trimStart("0").isEmpty) {
        info = info.copyWith(modThreadId: null);
      }
    }

    return info;
  } catch (e, st) {
    Fimber.e(
      "Unable to read version checker json file in ${versionFile.absolute}. ($e)\n$st",
    );
    return null;
  }
}

/// NOT THREAD SAFE.
/// Watches the mods folder for changes and calls [onUpdated] when a mod_info.json
/// file is added, removed, or modified.
///
/// This is a polling-based watcher that checks periodically.
/// Use [addModsFolderFileWatcher] for event-based watching.
///
/// [cancelController] is used to cancel the stream.
/// [onUpdated] is called with a list of all mod_info.json files found in the mods folder.
void watchModsFolder(
  Directory modsFolder,
  Ref ref,
  Function(List<File> modInfoFilesFound) onUpdated,
  StreamController cancelController,
) async {
  // Only run the mod folder check if the window is focused.
  // Checks every second to see if it's still in the background.
  while (!cancelController.isClosed) {
    var delaySeconds = ref.read(AppState.isWindowFocused)
        ? ref.read(
            appSettings.select((value) => value.secondsBetweenModFolderChecks),
          )
        : 1;
    await Future.delayed(Duration(seconds: delaySeconds));
    // TODO: re-add full manual scan, minus time-based diffing.
    // if (ref.read(AppState.isWindowFocused)) {
    //   checkModsFolderForUpdates(modsFolder, onUpdated);
    // }
  }
}

/// Sets up a file system watcher for the mods folder.
///
/// Calls [onUpdated] whenever a file is created, deleted, or modified
/// in the mods folder. This is event-based and more efficient than polling.
void addModsFolderFileWatcher(
  Directory modsFolder,
  Function(List<File> modInfoFilesFound) onUpdated,
) {
  modsFolder.watch()
    ..listen((event) {
      if (event.type == FileSystemEvent.create ||
          event.type == FileSystemEvent.delete ||
          event.type == FileSystemEvent.modify) {
        onUpdated([event.path.toFile()]);
      }
    })
    ..handleError((error) {
      Fimber.w("Error watching mods folder: $error");
    });
}

/// Finds a mod variant that matches the given mod info.
///
/// Matches by smolId (mod ID + version).
/// Returns null if no matching variant is found.
ModVariant? getModVariantForModInfo(
  ModInfo modInfo,
  List<ModVariant> modVariants,
) {
  return modVariants.firstWhereOrNull(
    (it) => it.modInfo.smolId == modInfo.smolId,
  );
}
