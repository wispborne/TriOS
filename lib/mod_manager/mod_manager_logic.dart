import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/models/enabled_mods.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/map_diff.dart';
import 'package:trios/utils/util.dart';

import '../chipper/utils.dart';
import '../models/mod.dart';
import '../models/mod_info.dart';
import '../models/version.dart';
import '../themes/theme_manager.dart';
import '../trios/settings/settings.dart';

final modManager =
    AsyncNotifierProvider<ModManagerNotifier, void>(ModManagerNotifier.new);

class ModManagerNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<List<InstallModResult>> installModFromArchiveWithDefaultUI(
    File archiveFile,
    BuildContext context,
  ) async {
    try {
      final installModsResult = await installModFromArchive(
          archiveFile,
          generateModFolderPath(ref.read(appSettings).gameDir!)!,
          ref.read(AppState.mods),
          (modsBeingInstalled) => showDialog<List<String>>(
              context: context,
              builder: (context) {
                // Start by selecting to install variants that are not already installed.
                final smolIdsToInstall = modsBeingInstalled
                    .where((it) => it.alreadyExistingVariant == null)
                    .map((it) => it.modInfo.modInfo.smolId)
                    .toList();
                return StatefulBuilder(builder: (context, setState) {
                  return AlertDialog(
                    title: const Text("Install mods"),
                    content: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: modsBeingInstalled
                            .map((it) => Builder(builder: (context) {
                                  final isSelected = smolIdsToInstall
                                      .contains(it.modInfo.modInfo.smolId);
                                  return CheckboxListTile(
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            "${it.modInfo.modInfo.name} ${it.modInfo.modInfo.version}"),
                                        Text(
                                            it.modInfo.modInfo.description
                                                    ?.takeWhile(
                                                        (it) => it != "\n")
                                                    .take(50) ??
                                                "",
                                            style:
                                                const TextStyle(fontSize: 12)),
                                        it.alreadyExistingVariant != null
                                            ? Text(
                                                isSelected
                                                    ? "(existing mod will be replaced)"
                                                    : "(already exists)",
                                                style: TextStyle(
                                                    color: ThemeManager
                                                        .vanillaWarningColor,
                                                    fontSize: 12),
                                              )
                                            : const SizedBox(),
                                      ],
                                    ),
                                    value: isSelected,
                                    onChanged: (value) {
                                      if (value == false) {
                                        setState(() {
                                          smolIdsToInstall.remove(
                                              it.modInfo.modInfo.smolId);
                                        });
                                      } else {
                                        setState(() {
                                          smolIdsToInstall
                                              .add(it.modInfo.modInfo.smolId);
                                        });
                                      }
                                    },
                                  );
                                }))
                            .toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(<String>[]);
                        },
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(smolIdsToInstall);
                        },
                        child: const Text("Install"),
                      ),
                    ],
                  );
                });
              }));

      if (installModsResult.isEmpty) {
        return [];
      }
      ref.invalidate(AppState.modVariants);
      // We have toasts now.
      // showSnackBar(
      //     context: context,
      //     content: Text(installModsResult.length == 1
      //         ? "Installed: ${installModsResult.first.modInfo.name} ${installModsResult.first.modInfo.version}"
      //         : "Installed ${installModsResult.length} mods (${installModsResult.map((it) => "${it.modInfo.name} ${it.modInfo.version}").join(", ")})"));

      final errors = installModsResult.where((it) => it.err != null).toList();
      if (errors.isNotEmpty) {
        showAlertDialog(
          context,
          title: "Error",
          content:
              "One or more mods could not be extracted. Check the logs for more information.\n${errors.map((it) => "${it.modInfo.name} ${it.modInfo.version}\n${it.err}").toList()}",
        );
      }

      return installModsResult;
    } catch (e, st) {
      Fimber.w("Error installing mod from archive: $e", ex: e, stacktrace: st);
      if (!context.mounted) return [];
      showAlertDialog(
        context,
        title: "Error installing mod",
        content: "$e",
      );
      return [];
    }
  }
}

Future<List<ModVariant>> getModsVariantsInFolder(Directory modsFolder) async {
  var mods = <ModVariant?>[];

  for (var modFolder in modsFolder.listSync().whereType<Directory>()) {
    try {
      var progressText = StringBuffer();
      var modInfo = await getModInfo(modFolder, progressText);
      if (modInfo == null) {
        continue;
      }

      final modVariant = ModVariant(
        modInfo: modInfo,
        modFolder: modFolder,
        versionCheckerInfo:
            getVersionFile(modFolder)?.let((it) => getVersionCheckerInfo(it)),
        hasNonBrickedModInfo: await modFolder
            .resolve(Constants.unbrickedModInfoFileName)
            .exists(),
      );

      // Screenshot mode
      // if (modVariant.modInfo.isCompatibleWithGame("0.97a-RC10") == GameCompatibility.compatible || (Random().nextBool() && Random().nextBool())) {
      mods.add(modVariant);
      // }
    } catch (e, st) {
      Fimber.w("Unable to read mod in ${modFolder.absolute}. ($e)\n$st");
    }
  }

  return mods.whereType<ModVariant>().toList();
}

VersionCheckerInfo? getVersionCheckerInfo(File versionFile) {
  if (!versionFile.existsSync()) return null;
  try {
    var info = VersionCheckerInfo.fromJson(
        versionFile.readAsStringSync().fixJsonToMap());

    if (info.modThreadId != null) {
      info = info.copyWith(
          modThreadId: info.modThreadId?.replaceAll(RegExp(r'[^0-9]'), ''));

      if (info.modThreadId!.trimStart("0").isEmpty) {
        info = info.copyWith(modThreadId: null);
      }
    }

    return info;
  } catch (e, st) {
    Fimber.e(
        "Unable to read version checker json file in ${versionFile.absolute}. ($e)\n$st");
    return null;
  }
}

File? getVersionFile(Directory modFolder) {
  final csv = File(p.join(modFolder.path, Constants.versionCheckerCsvPath));
  if (!csv.existsSync()) return null;
  try {
    return modFolder
        .resolve((const CsvToListConverter(eol: "\n")
                .convert(csv.readAsStringSync().replaceAll("\r\n", "\n"))[1][0]
            as String))
        .toFile();
  } catch (e, st) {
    Fimber.e(
        "Unable to read version checker csv file in ${modFolder.absolute}. ($e)\n$st");
    return null;
  }
}

Future<ModInfo?> getModInfo(
    Directory modFolder, StringBuffer progressText) async {
  try {
    return modFolder
        .listSync()
        .whereType<File>()
        .firstWhereOrNull((file) => file.nameWithExtension.equalsAnyIgnoreCase(
            [Constants.modInfoFileName, ...Constants.modInfoFileDisabledNames]))
        ?.let((modInfoFile) async {
      var rawString =
          await withFileHandleLimit(() => modInfoFile.readAsString());
      var jsonEncodedYaml = (rawString).replaceAll("\t", "  ").fixJsonToMap();

      // try {
      final model = ModInfo.fromJsonModel(
          ModInfoJson.fromJson(jsonEncodedYaml), modFolder);

      // Fimber.v("Using 0.9.5a mod_info.json format for ${modInfoFile.absolute}");

      return model;
      // } catch (e) {
      //   final model = ModInfoModel_091a.fromJson(jsonEncodedYaml);
      //
      //   Fimber.v("Using 0.9.1a mod_info.json format for ${modInfoFile.absolute}");
      //
      //   return ModInfo(model.id, modFolder, model.name, model.version.toString(), model.gameVersion);
      // }
    });
  } catch (e, st) {
    Fimber.v(
        "Unable to find or read 'mod_info.json' in ${modFolder.absolute}. ($e)\n$st");
    return null;
  }
}

File getEnabledModsFile(Directory modsFolder) {
  return File(p.join(modsFolder.path, "enabled_mods.json"));
}

/// `allMods` will filter out mods that have been removed from the mods folder since the last time the enabled mods file was written.
Future<EnabledMods> getEnabledMods(Directory modsFolder,
    {List<Mod>? allMods}) async {
  return EnabledMods.fromJson(
      (await getEnabledModsFile(modsFolder).readAsString()).fixJsonToMap());
}

// Future<void> disableMod(
//     String modInfoId, Directory modsFolder, WidgetRef ref) async {
//   var enabledMods = await getEnabledMods(modsFolder);
//   enabledMods = enabledMods.copyWith(
//       enabledMods:
//           enabledMods.enabledMods.filter((id) => id != modInfoId).toSet());
//
//   final enabledModsFile = getEnabledModsFile(modsFolder);
//   await enabledModsFile.writeAsString(jsonEncode(enabledMods.toJson()));
//   ref.invalidate(AppState.enabledMods);
// }

// Enable the new variant
//   val result = if (modVariant != null) {
//     // Enable the one we want.
//     // Slower: Reload, since we just disabled it
// //                val freshModVariant =
//     modLoader.reload(listOf(mod.id))?.mods?.flatMap { it.variants }
//       ?.first { it.smolId == modVariant.smolId }
//   ?: kotlin.run {
//   val error = "After disabling, couldn't find mod variant ${modVariant.smolId}."
//   Timber.w { error }
//   return Result.failure(RuntimeException(error))
//   }
//   // Faster: Assume we disabled it and change the mod to be disabled.
// //                modVariant.mod = modVariant.mod.copy(isEnabledInGame = false)
//   modModificationStateHolder.state.update {
//   it.toMutableMap().apply {
//   this[mod.id] =
//   ModModificationState.EnablingVariant
//   }
//   }
//   staging.enableModVariant(modVariant, modLoader)
//   } else {
//   Result.success(Unit)
//   }

/// NOT THREAD SAFE.
/// Watches the mods folder for changes and calls [onUpdated] when a mod_info.json file is added, removed, or modified.
/// [cancelController] is used to cancel the stream.
/// [onUpdated] is called with a list of all mod_info.json files found in the mods folder.
/// Uses a static variable to keep track of the last paths and last modified times of the mod_info.json files.
watchModsFolder(
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
            appSettings.select((value) => value.secondsBetweenModFolderChecks))
        : 1;
    await Future.delayed(Duration(seconds: delaySeconds));
    if (ref.read(AppState.isWindowFocused)) {
      checkModsFolderForUpdates(modsFolder, onUpdated);
    }
  }
}

final _lastPathsAndLastModified = <String, DateTime>{};

/// NOT THREAD SAFE.
/// Watches the mods folder for changes and calls [onUpdated] when a mod_info.json file is added, removed, or modified.
/// [cancelController] is used to cancel the stream.
/// [onUpdated] is called with a list of all mod_info.json files found in the mods folder.
/// Uses a static variable to keep track of the last paths and last modified times of the mod_info.json files.
void checkModsFolderForUpdates(
    Directory modsFolder, Function(List<File> modInfoFilesFound) onUpdated) {
  Fimber.d("Checking mod_info.json files in ${modsFolder.absolute}.");
  final modInfoFiles = modsFolder
      .listSync()
      .whereType<Directory>()
      .map((it) => getModInfoFile(it))
      .whereNotNull()
      .toList();

  final newPathsAndLastModified = modInfoFiles
      .map((it) => MapEntry(it.path, it.lastModifiedSync()))
      .toMap();

  // if (lastPathsAndLastModified.isNotEmpty) {
  final diff = _lastPathsAndLastModified.compareWith(newPathsAndLastModified);
  if (diff.hasChanged) {
    // TODO use diff for more efficient UI updates
    _lastPathsAndLastModified.clear();
    _lastPathsAndLastModified.addAll(newPathsAndLastModified);
    onUpdated(modInfoFiles);
  }
}

/// Looks for a mod_info.json file in the mod folder. Returns a disabled one if no enabled one is found.
File? getModInfoFile(Directory modFolder) {
  final regularModInfoFile =
      modFolder.resolve(Constants.modInfoFileName).toFile();
  if (regularModInfoFile.existsSync()) {
    return regularModInfoFile;
  }

  for (var disabledModInfoFileName in Constants.modInfoFileDisabledNames) {
    final disabledModInfoFile =
        modFolder.resolve(disabledModInfoFileName).toFile();
    if (disabledModInfoFile.existsSync()) {
      return disabledModInfoFile;
    }
  }

  return null;
}

// /// SmolId, StreamController.
// final Map<String, StreamController<File?>> _modFoldersBeingWatched = {};
//
// watchSingleModFolder(ModVariant variant,
//     Function(ModVariant variant, File? modInfoFile) onUpdated) async {
//   if (_modFoldersBeingWatched[variant.smolId]?.isClosed != true &&
//       _modFoldersBeingWatched[variant.smolId]?.hasListener == true) {
//     Fimber.i(
//         "Watcher for ${variant.smolId} is open and has a listener, not rewatching.");
//     return;
//   }
//
//   var controller =
//       _modFoldersBeingWatched[variant.smolId] ?? StreamController<File?>();
//
//   // If the watcher is closed somehow, we need to recreate it.
//   if (controller.isClosed) {
//     controller = StreamController<File?>();
//     _modFoldersBeingWatched[variant.smolId] = controller;
//   }
//
//   // Watch the enabled_mods.json file for changes.
//   final modInfoFile =
//       variant.modsFolder.resolve(Constants.modInfoFileName).toFile();
//   Fimber.i("Watching for changes: ${modInfoFile.absolute}");
//   pollFileForModification(modInfoFile, controller);
//   controller.stream.listen((event) {
//     onUpdated(variant, event);
//   });
// }

Future<void> forceChangeModGameVersion(
    ModVariant modVariant, String newGameVersion) async {
  final modInfoFile = modVariant.modInfoFile;
  if (modInfoFile == null || !modInfoFile.existsSync()) {
    Fimber.e("Mod info file not found for ${modVariant.smolId}");
    return;
  }

  // Replace the game version in the mod_info.json file.
  // Don't use the code model, we want to keep any extra fields that might not be in the model.
  final modInfoJson = modInfoFile.readAsStringSync().fixJsonToMap();
  modInfoJson["gameVersion"] = newGameVersion;
  modInfoJson["originalGameVersion"] = modVariant.modInfo.gameVersion;
  await modInfoFile.writeAsString(jsonEncodePrettily(modInfoJson));
}

GameCompatibility compareGameVersions(
    String? modGameVersion, String? gameVersion) {
  // game is versioned like 0.95.1a-RC5 and 0.95.0a-RC5
  // they are fully compatible if the first three numbers are the same
  // they are partially compatible if the first two numbers are the same
  // they are incompatible if the first or second number is different
  if (modGameVersion == null || gameVersion == null) {
    return GameCompatibility.perfectMatch;
  }

  final modVersion = Version.parse(modGameVersion, sanitizeInput: true);
  final gameVersionParsed = Version.parse(gameVersion, sanitizeInput: true);
  if (modVersion.major == gameVersionParsed.major &&
      modVersion.minor == gameVersionParsed.minor &&
      modVersion.patch == gameVersionParsed.patch) {
    return GameCompatibility.perfectMatch;
  } else if (modVersion.major == gameVersionParsed.major &&
      modVersion.minor == gameVersionParsed.minor) {
    return GameCompatibility.warning;
  } else {
    return GameCompatibility.incompatible;
  }
}

extension DependencyExt on Dependency {
  ModDependencySatisfiedState isSatisfiedBy(
      ModVariant variant, EnabledMods enabledMods) {
    if (id != variant.modInfo.id) {
      return Missing();
    }

    if (version != null) {
      if (variant.modInfo.version?.major != version!.major) {
        return VersionInvalid(variant);
      } else if (variant.modInfo.version?.minor != version!.minor) {
        return VersionWarning(variant);
      }
    }

    if (!variant.modInfo.isEnabled(enabledMods)) {
      return Disabled(variant);
    }

    return Satisfied(variant);
  }

  /// Searches [allMods] for the best possible match for this dependency.
  ModDependencySatisfiedState isSatisfiedByAny(
    List<ModVariant> allMods,
    EnabledMods enabledMods,
    String? gameVersion,
  ) {
    var foundDependencies = allMods.filter((mod) => mod.modInfo.id == id);
    if (foundDependencies.isEmpty) {
      return Missing();
    }

    final satisfyResults = foundDependencies
        .map((variant) => isSatisfiedBy(variant, enabledMods))
        .toList();

    // Return the least severe state.
    return getTopDependencySeverity(satisfyResults, gameVersion,
        sortLeastSevere: true);
    // if (satisfyResults.contains(DependencyStateType.Satisfied)) {
    //   return DependencyStateType.Satisfied;
    // } else if (satisfyResults.contains(DependencyStateType.Disabled)) {
    //   return DependencyStateType.Disabled;
    // } else if (satisfyResults.contains(DependencyStateType.VersionWarning)) {
    //   return DependencyStateType.VersionWarning;
    // } else if (satisfyResults.contains(DependencyStateType.VersionInvalid)) {
    //   return DependencyStateType.VersionInvalid;
    // } else {
    //   return DependencyStateType.Missing;
    // }
  }
}

/// Determines the most or least severe dependency state from a list of dependency states.
///
/// @param sortLeastSevere A boolean flag indicating whether to sort the states in ascending order of severity.
///                        If `true`, the method returns the least severe state. If `false`, it returns the most severe state.
ModDependencySatisfiedState getTopDependencySeverity(
  List<ModDependencySatisfiedState> satisfyResults,
  String? gameVersion, {
  required bool sortLeastSevere,
}) {
  final statePriority = sortLeastSevere
      ? [
          Satisfied,
          Disabled,
          VersionWarning,
          VersionInvalid,
          Missing,
        ]
      : [
          Missing,
          VersionInvalid,
          VersionWarning,
          Disabled,
          Satisfied,
        ];

  // Add the most (or least) severe state(s) to a list.
  final mostOrLeastSevere = <ModDependencySatisfiedState>[];
  for (var state in statePriority) {
    if (satisfyResults.any((it) => it.runtimeType == state)) {
      for (var result in satisfyResults) {
        if (result.runtimeType == state) {
          mostOrLeastSevere.add(result);
        }
      }

      break;
    }
  }

  // These three states (Satisfied, Disabled, VersionWarning) are all roughly the same severity.
  // They should all work, and even if we get an exact version match that's enabled,
  // we should still prefer the highest version even if it's disabled.
  if (mostOrLeastSevere.firstOrNull is Satisfied ||
      mostOrLeastSevere.firstOrNull is Disabled ||
      mostOrLeastSevere.firstOrNull is VersionWarning) {
    // Find the highest version that's compatible.
    final possibilities = satisfyResults
        .where(
            (it) => it is Satisfied || it is Disabled || it is VersionWarning)
        .prefer((it) =>
            gameVersion != null &&
            it.modVariant
                    ?.isCompatibleWithGameVersion(gameVersion.toString()) !=
                GameCompatibility.incompatible)
        .toList();

    if (possibilities.isNotEmpty) {
      // Find the highest version.
      return possibilities
              .where((it) => it.modVariant != null)
              .maxByOrNull<ModVariant>((state) => state.modVariant!) ??
          possibilities.first;
    }
  }

  return mostOrLeastSevere.firstOrNull ?? Missing();
}

typedef ExtractedModInfo = ({
  LibArchiveExtractedFile extractedFile,
  ModInfo modInfo
});

typedef InstallModResult = ({ModInfo modInfo, Object? err, StackTrace? st});

// Things to handle:
// - One or more mods already installed.
// - One or more mods in the archive.
// - Ask user which they want to install and optionally delete previous.
/// Given an archive file, attempts to install the mod(s) contained within it.
/// If there are multiple mods in the archive, or one or more mods are already installed, the user will be asked which mods to install/delete.
/// Returns a list of ModInfos and any errors that occurred when installing each.
/// userInputNeededHandler should return the list of SmolIds to install.
Future<List<InstallModResult>> installModFromArchive(
  File archiveFile,
  Directory destinationFolder,
  List<Mod> currentMods,
  Future<List<String>?> Function(
          List<({ExtractedModInfo modInfo, ModVariant? alreadyExistingVariant})>
              modInfosFound)
      userInputNeededHandler,
) async {
  if (!archiveFile.existsSync()) {
    throw Exception("File does not exist: ${archiveFile.path}");
  }
  final results = <InstallModResult>[];

  final libArchive = LibArchive();
  final archiveFileList = libArchive.listEntriesInArchive(archiveFile);
  var modInfoFiles = archiveFileList.filter(
      (it) => it.pathName.containsIgnoreCase(Constants.modInfoFileName));

  if (modInfoFiles.isEmpty) {
    throw Exception(
        "No mod_info.json file found in archive:\n${archiveFile.path}");
  }

  Fimber.i(
      "Found mod_info.json(s) file in archive: ${modInfoFiles.map((it) => it.pathName).toList()}");

  // Extract just mod_info.json files to a temp folder.
  var modInfosTempFolder = Directory.systemTemp.createTempSync();
  final extractedModInfos = await libArchive.extractEntriesInArchive(
    archiveFile,
    modInfosTempFolder.path,
    fileFilter: (entry) =>
        entry.file.toFile().nameWithExtension == Constants.modInfoFileName,
  );
  final modInfos = await Future.wait(
      extractedModInfos.whereNotNull().map((modInfoFile) async {
    ExtractedModInfo modInfo = (
      extractedFile: modInfoFile,
      modInfo: ModInfo.fromJson(modInfoFile.extractedFile
          .readAsStringSyncAllowingMalformed()
          .fixJsonToMap())
    );
    return modInfo;
  }).toList());

  // Check for mods that are already installed.
  var allModVariants = currentMods.variants;
  final alreadyPresentModVariants = modInfos
      .map((it) => getModVariantForModInfo(it.modInfo, allModVariants))
      .whereNotNull()
      .toList();

  if (alreadyPresentModVariants.isNotEmpty) {
    Fimber.i(
        "Mod already exists: ${alreadyPresentModVariants.map((it) => "${it.modInfo.id} ${it.modInfo.version}").toList()}");
  }

  // User can choose to install only some of the mods (if multiple were found).
  var modInfosToInstall = modInfos;

  // If there are multiple mod_info.json files or one or more mods were already installed, ask user for input.
  if (alreadyPresentModVariants.isNotEmpty || modInfos.length > 1) {
    final userInput = await userInputNeededHandler(
      modInfos
          .map((modInfo) => (
                modInfo: modInfo,
                alreadyExistingVariant: getModVariantForModInfo(
                    modInfo.modInfo, alreadyPresentModVariants),
              ))
          .toList(),
    );
    Fimber.i("User has chosen to install mods: $userInput");
    if (userInput == null) {
      return [];
    }
    // Grab just the modInfos that the user wants to install.
    modInfosToInstall = userInput
        .map((smolId) =>
            modInfos.firstWhere((modInfo) => modInfo.modInfo.smolId == smolId))
        .toList();

    // Find any mods that are already installed.
    final modsToDeleteFirst = modInfosToInstall
        .map((it) => getModVariantForModInfo(it.modInfo, allModVariants))
        .whereNotNull();
    // Delete the existing mod folders first.
    for (var modToDelete in modsToDeleteFirst) {
      try {
        modToDelete.modFolder.deleteSync(recursive: true);
        Fimber.i(
            "Deleted mod folder before reinstalling same variant: ${modToDelete.modFolder}");
      } catch (e, st) {
        Fimber.e("Error deleting mod folder: ${modToDelete.modFolder}",
            ex: e, stacktrace: st);
        results.add((
          modInfo: modToDelete.modInfo,
          err: e,
          st: st,
        ));
        // If there was an error deleting the mod folder, don't install the new version.
        modInfosToInstall.removeWhere(
            (it) => it.modInfo.smolId == modToDelete.modInfo.smolId);
      }
    }
  }

  for (final modInfoToInstall in modInfosToInstall) {
    final modInfo = modInfoToInstall.modInfo;
    try {
      // We need to handle both when mod_info.json is at / and when at /mod/mod/mod/mod_info.json.
      final generatedDestFolderName =
          ModVariant.generateVariantFolderName(modInfo);
      final modInfoParentFolder =
          modInfoToInstall.extractedFile.archiveFile.file.parent;
      final modInfoSiblings = archiveFileList
          .filter((it) => it.file.parent.path == modInfoParentFolder.path)
          .toList();
      Fimber.d(
          "Mod info (${modInfoToInstall.extractedFile.archiveFile.file.path}) siblings: ${modInfoSiblings.map((it) => it.pathName).toList()}");
      final errors = <(Object err, StackTrace st)>[];

      final extractedMod = await libArchive.extractEntriesInArchive(
        archiveFile,
        destinationFolder.path,
        fileFilter: (entry) => entry.file.isFile()
            ? modInfoSiblings.contains(entry)
            : p.isWithin(modInfoParentFolder.path, entry.file.path),
        pathTransform: (entry) => p.join(
          generatedDestFolderName,
          p.relative(entry.file.path, from: modInfoParentFolder.path),
        ),
        onError: (e, st) {
          errors.add((e, st));
          Fimber.e("Error extracting file: $e", ex: e, stacktrace: st);
          return true;
        },
      );
      Fimber.i(
          "Extracted ${extractedMod.length} files in mod ${modInfo.id} ${modInfo.version} to '${destinationFolder.resolve(generatedDestFolderName)}'");
      results.add((
        modInfo: modInfo,
        err: null,
        st: null,
      ));
    } catch (e, st) {
      Fimber.e("Error installing mod: $e", ex: e, stacktrace: st);
      results.add((
        modInfo: modInfo,
        err: e,
        st: st,
      ));
    }
  }

  return results;
}

ModVariant? getModVariantForModInfo(
    ModInfo modInfo, List<ModVariant> modVariants) {
  return modVariants
      .firstWhereOrNull((it) => it.modInfo.smolId == modInfo.smolId);
}

extension ModInfoExt on ModInfo {
  GameCompatibility isCompatibleWithGame(String? gameVersion) {
    return compareGameVersions(gameVersion, this.gameVersion);
  }

  bool isEnabled(EnabledMods enabledMods) {
    return enabledMods.enabledMods.contains(id);
  }

  /// Searches [modVariants] for the best possible match for this dependency.
  List<ModDependencyCheckResult> checkDependencies(
    List<ModVariant> modVariants,
    EnabledMods enabledMods,
    String? gameVersion,
  ) {
    return dependencies.map((dep) {
      return ModDependencyCheckResult(
          dep, dep.isSatisfiedByAny(modVariants, enabledMods, gameVersion));
    }).toList();
  }
}

extension ModDependencySatisfiedStateExt on ModDependencySatisfiedState {
  String getDependencyStateText() {
    return switch (this) {
      Satisfied _ => "(found ${modVariant?.modInfo.version})",
      Missing _ => "(missing)",
      Disabled _ => "(disabled: ${modVariant?.modInfo.version})",
      VersionInvalid _ => "(wrong version: ${modVariant?.modInfo.version})",
      VersionWarning _ => "(found: ${modVariant?.modInfo.version})",
    };
  }
}

extension ModListExtensions on List<Mod> {
  List<ModVariant> get variants {
    return expand((mod) => mod.modVariants).toList();
  }

  List<Mod> get sortedMods {
    return sortedBy((mod) =>
        mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ??
        "(no variant)");
  }
}

extension ModListExtensionsNullable on List<Mod?> {
  List<Mod?> get sortedMods {
    return sortedBy((mod) =>
        mod?.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ??
        "(no variant)");
  }
}

extension ModVariantListExtensionsNullable on List<ModVariant?> {
  List<ModVariant?> get sortedMods {
    return sortedBy((variant) => variant?.modInfo.nameOrId ?? "");
  }
}

extension ModVariantListExtensions on List<ModVariant> {
  List<ModVariant> get sortedModVariants {
    return sortedBy((variant) => variant.modInfo.nameOrId);
  }
}

extension ModVariantExt on ModVariant {
  /// Searches [modVariants] for the best possible match for this dependency.
  List<ModDependencyCheckResult> checkDependencies(
    List<ModVariant> modVariants,
    EnabledMods enabledMods,
    String? gameVersion,
  ) =>
      modInfo.checkDependencies(modVariants, enabledMods, gameVersion);

  GameCompatibility isCompatibleWithGameVersion(String gameVersion) {
    return modInfo.isCompatibleWithGame(gameVersion);
  }
}

extension ModVariantsExt on List<ModVariant> {
  ModVariant? highestVersionForGameVersion(String gameVersion) {
    return where((it) =>
        it.isCompatibleWithGameVersion(gameVersion) !=
        GameCompatibility.incompatible).toList().findHighestVersion;
  }

  ModVariant? preferHighestVersionForGameVersion(String? gameVersion) {
    if (gameVersion == null) {
      return findHighestVersion;
    }
    return highestVersionForGameVersion(gameVersion) ?? findHighestVersion;
  }

  ModVariant? get findHighestVersion {
    return maxByOrNull((variant) => variant);
  }
}

class DependencyCheck {
  final GameCompatibility gameCompatibility;
  final List<ModDependencyCheckResult> dependencyChecks;

  DependencyCheck(this.gameCompatibility, this.dependencyChecks);

  List<ModDependencySatisfiedState> get dependencyStates =>
      dependencyChecks.map((it) => it.satisfiedAmount).toList();

  bool get isGameCompatible =>
      gameCompatibility != GameCompatibility.incompatible;

  ModDependencyCheckResult? mostSevereDependency(String? gameVersion) =>
      getTopDependencySeverity(dependencyStates, gameVersion,
              sortLeastSevere: false)
          .let((it) => dependencyChecks
              .firstWhereOrNull((dep) => dep.satisfiedAmount == it));
}

/// How much a given mod variant's dependency is satisfied.
class ModDependencyCheckResult {
  final Dependency dependency;
  final ModDependencySatisfiedState satisfiedAmount;

  ModDependencyCheckResult(this.dependency, this.satisfiedAmount);

  @override
  String toString() =>
      "DependencyCheckResult{dependency: $dependency, satisfiedAmount: $satisfiedAmount}";
}

enum GameCompatibility { perfectMatch, warning, incompatible }

class DependencyState {
  final Dependency dependency;

  DependencyState(this.dependency);
}

/// mod: The mod that was checked as a possible dependency.
sealed class ModDependencySatisfiedState {
  final ModVariant? modVariant;

  ModDependencySatisfiedState({this.modVariant});

  @override
  String toString() => "${modVariant?.smolId} $runtimeType";
}

class Missing extends ModDependencySatisfiedState {
  Missing() : super();
}

class Disabled extends ModDependencySatisfiedState {
  Disabled(ModVariant modVariant) : super(modVariant: modVariant);
}

class VersionInvalid extends ModDependencySatisfiedState {
  VersionInvalid(ModVariant modVariant) : super(modVariant: modVariant);
}

/// Minor version mismatch.
class VersionWarning extends ModDependencySatisfiedState {
  VersionWarning(ModVariant modVariant) : super(modVariant: modVariant);
}

class Satisfied extends ModDependencySatisfiedState {
  Satisfied(ModVariant modVariant) : super(modVariant: modVariant);
}
