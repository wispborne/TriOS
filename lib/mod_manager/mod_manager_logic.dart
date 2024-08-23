import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/tooltip_frame.dart';

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
          generateModsFolderPath(ref.read(appSettings).gameDir!)!,
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
                                  var gameVersion = ref.watch(appSettings
                                      .select((s) => s.lastStarsectorVersion));
                                  return MovingTooltipWidget(
                                    tooltipWidget: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 500),
                                      child: TooltipFrame(
                                          child: Column(
                                        children: [
                                          Text(
                                              const JsonEncoder.withIndent("  ")
                                                  .convert(it.modInfo.modInfo),
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        ],
                                      )),
                                    ),
                                    child: CheckboxListTile(
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("${it.modInfo.modInfo.name}"),
                                          Text.rich(TextSpan(children: [
                                            TextSpan(
                                                text:
                                                    "v${it.modInfo.modInfo.version}",
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                            // bullet separator
                                            const TextSpan(
                                                text: " • ",
                                                style: TextStyle(fontSize: 13)),
                                            TextSpan(
                                                text: it.modInfo.modInfo
                                                    .gameVersion,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: it.modInfo.modInfo
                                                        .isCompatibleWithGame(
                                                            gameVersion)
                                                        .getGameCompatibilityColor())),
                                          ])),
                                          Text(
                                              it.modInfo.modInfo.description
                                                      ?.takeWhile((it) =>
                                                          it != "\n" &&
                                                          it != ".") ??
                                                  "",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12)),
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
                                    ),
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

      final List<InstallModResult> errors =
          installModsResult.where((it) => it.err != null).toList();
      if (errors.isNotEmpty) {
        showAlertDialog(context, title: "Error",
            widget: Builder(builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text:
                          "One or more mods could not be extracted. Please install them manually.\n",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: "Check the logs for more information.\n\n",
                    ),
                  ],
                ),
              ),
              ...errors.map((failedMod) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${failedMod.modInfo.name} ${failedMod.modInfo.version}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              OpenFilex.open(failedMod.archiveFile.parent.path);
                            },
                            child: const Text("Open folder"),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              OpenFilex.open(failedMod.destinationFolder.path);
                            },
                            child: const Text("Open mods folder"),
                          ),
                        ],
                      ),
                    ),
                    SelectableText(
                      "${failedMod.err}\n",
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              }),
            ],
          );
        }));
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
            List<
                    ({
                      ExtractedModInfo modInfo,
                      ModVariant? alreadyExistingVariant
                    })>
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
          .map((smolId) => modInfos
              .firstWhere((modInfo) => modInfo.modInfo.smolId == smolId))
          .toList();

      // Find any mods that are already installed.
      final modsToDeleteFirst = modInfosToInstall
          .map((it) => getModVariantForModInfo(it.modInfo, allModVariants))
          .whereNotNull();
      // If user has selected to, delete the existing mod folders
      for (var modToDelete in modsToDeleteFirst) {
        try {
          modToDelete.modFolder.deleteSync(recursive: true);
          Fimber.i(
              "Deleted mod folder before reinstalling same variant: ${modToDelete.modFolder}");
        } catch (e, st) {
          Fimber.e("Error deleting mod folder: ${modToDelete.modFolder}",
              ex: e, stacktrace: st);
          results.add((
            archiveFile: archiveFile,
            destinationFolder: destinationFolder,
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

    // Start installing the mods one by one.
    for (final modInfoToInstall in modInfosToInstall) {
      final modInfo = modInfoToInstall.modInfo;
      var existingMod =
          currentMods.firstWhereOrNull((it) => it.id == modInfo.id);

      try {
        // We need to handle both when mod_info.json is at / and when at /mod/mod/mod/mod_info.json.
        final generatedDestFolderName =
            ModVariant.generateUniqueVariantFolderName(modInfo);
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
            return false;
          },
        );
        final newModFolder =
            destinationFolder.resolve(generatedDestFolderName).toDirectory();
        Fimber.i(
            "Extracted ${extractedMod.length} files in mod ${modInfo.id} ${modInfo.version} to '$newModFolder'");

        // Ensure we don't end up with two enabled variants.
        if (existingMod != null && existingMod.hasEnabledVariant) {
          Fimber.i(
              "There is already an enabled variant for ${modInfo.id}. Disabling newly installed variant ${modInfo.smolId} so both aren't enabled.");
          ref
              .read(AppState.modVariants.notifier)
              .disableModInfoFile(newModFolder, modInfo.smolId);
        }

        results.add((
          archiveFile: archiveFile,
          destinationFolder: destinationFolder,
          modInfo: modInfo,
          err: null,
          st: null,
        ));
      } catch (e, st) {
        Fimber.e("Error installing mod: $e", ex: e, stacktrace: st);
        results.add((
          archiveFile: archiveFile,
          destinationFolder: destinationFolder,
          modInfo: modInfo,
          err: e,
          st: st,
        ));
      }
    }

    return results;
  }
}

typedef ExtractedModInfo = ({
  LibArchiveExtractedFile extractedFile,
  ModInfo modInfo
});

typedef InstallModResult = ({
  File archiveFile,
  Directory destinationFolder,
  ModInfo modInfo,
  Object? err,
  StackTrace? st
});

Future<List<ModVariant>> getModsVariantsInFolder(Directory modsFolder) async {
  final mods = <ModVariant?>[];
  final folders =
      [modsFolder] + [...modsFolder.listSync().whereType<Directory>()];

  for (final modFolder in folders) {
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
    final possibleModInfos = [
      Constants.modInfoFileName,
      ...Constants.modInfoFileDisabledNames
    ].map((it) => modFolder.resolve(it).toFile()).toList();

    return possibleModInfos
        .firstWhereOrNull((file) => file.existsSync())
        ?.let((modInfoFile) async {
      var rawString =
          await withFileHandleLimit(() => modInfoFile.readAsString());
      var jsonEncodedYaml = (rawString).replaceAll("\t", "  ").fixJsonToMap();

      // try {
      final model = ModInfo.fromJsonModel(
          ModInfoJson.fromJson(jsonEncodedYaml), modFolder);

      // Fimber.v(() =>"Using 0.9.5a mod_info.json format for ${modInfoFile.absolute}");

      return model;
      // } catch (e) {
      //   final model = ModInfoModel_091a.fromJson(jsonEncodedYaml);
      //
      //   Fimber.v(() =>"Using 0.9.1a mod_info.json format for ${modInfoFile.absolute}");
      //
      //   return ModInfo(model.id, modFolder, model.name, model.version.toString(), model.gameVersion);
      // }
    });
  } catch (e, st) {
    Fimber.v(() =>
        "Unable to find or read 'mod_info.json' in ${modFolder.absolute}. ($e)\n$st");
    return null;
  }
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
    // TODO: re-add full manual scan, minus time-based diffing.
    // if (ref.read(AppState.isWindowFocused)) {
    //   checkModsFolderForUpdates(modsFolder, onUpdated);
    // }
  }
}

addModsFolderFileWatcher(
  Directory modsFolder,
  Function(List<File> modInfoFilesFound) onUpdated,
) {
  final watcher = modsFolder.watch();
  watcher.listen((event) {
    if (event.type == FileSystemEvent.create ||
        event.type == FileSystemEvent.delete ||
        event.type == FileSystemEvent.modify) {
      // checkModsFolderForUpdates(modsFolder, (_) {});
      onUpdated([event.path.toFile()]);
    }
  });
}

// final _lastPathsAndLastModified = <String, DateTime>{};

/// NOT THREAD SAFE.
/// Watches the mods folder for changes and calls [onUpdated] when a mod_info.json file is added, removed, or modified.
/// [cancelController] is used to cancel the stream.
/// [onUpdated] is called with a list of all mod_info.json files found in the mods folder.
/// Uses a static variable to keep track of the last paths and last modified times of the mod_info.json files.
// void checkModsFolderForUpdates(
//     Directory modsFolder, Function(List<File> modInfoFilesFound) onUpdated) {
//   Fimber.d("Checking mod_info.json files in ${modsFolder.absolute}.");
//   final modInfoFiles = modsFolder
//       .listSync()
//       .whereType<Directory>()
//       .map((it) => getModInfoFile(it))
//       .whereNotNull()
//       .toList();
//
//   final newPathsAndLastModified = modInfoFiles
//       .map((it) => MapEntry(it.path, it.lastModifiedSync()))
//       .toMap();
//
//   // if (lastPathsAndLastModified.isNotEmpty) {
//   final diff = _lastPathsAndLastModified.compareWith(newPathsAndLastModified);
//   if (diff.hasChanged) {
//     // TODO use diff for more efficient UI updates
//     _lastPathsAndLastModified.clear();
//     _lastPathsAndLastModified.addAll(newPathsAndLastModified);
//     onUpdated(modInfoFiles);
//   }
// }

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

void copyModListToClipboardFromIds(
    Set<String>? modIds, List<Mod> allMods, BuildContext context) {
  final enabledModsList = modIds
      .orEmpty()
      .map((id) => allMods.firstWhereOrNull((mod) => mod.id == id))
      .whereNotNull()
      .toList()
      .sortedByName;
  copyModListToClipboardFromMods(enabledModsList, context);
}

void copyModListToClipboardFromMods(List<Mod> mods, BuildContext context) {
  Clipboard.setData(ClipboardData(
      text: "Mods (${mods.length})\n${mods.map((mod) {
    final variant = mod.findFirstEnabledOrHighestVersion;
    return false
        ? "${mod.id} ${variant?.modInfo.version}"
        : "${variant?.modInfo.name}  v${variant?.modInfo.version}  [${mod.id}]";
  }).join('\n')}"));
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text("Copied mod list to clipboard."),
  ));
}

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

ModVariant? getModVariantForModInfo(
    ModInfo modInfo, List<ModVariant> modVariants) {
  return modVariants
      .firstWhereOrNull((it) => it.modInfo.smolId == modInfo.smolId);
}

class VersionCheckComparison {
  final ModVariant variant;
  late final RemoteVersionCheckResult? remoteVersionCheck;
  late final int? comparisonInt;

  VersionCheckComparison(
      this.variant, Map<String, RemoteVersionCheckResult> versionChecks) {
    remoteVersionCheck = versionChecks[variant.smolId];
    comparisonInt = compareLocalAndRemoteVersions(
        variant.versionCheckerInfo, remoteVersionCheck);
  }

  VersionCheckComparison.specific(this.variant, this.remoteVersionCheck) {
    comparisonInt = compareLocalAndRemoteVersions(
        variant.versionCheckerInfo, remoteVersionCheck);
  }

  bool get hasUpdate => comparisonInt != null && comparisonInt! < 0;

  /// The actual comparison of the local and remote versions.
  /// Returns 0 if the versions are the same, -1 if the remote version is newer, and 1 if the local version is newer.
  /// Usually, you should use [VersionCheckComparison] instead.
  static int? compareLocalAndRemoteVersions(
      VersionCheckerInfo? local, RemoteVersionCheckResult? remote) {
    if (local == null || remote == null) return null;
    return local.modVersion?.compareTo(remote.remoteVersion?.modVersion);
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

  @override
  String toString() =>
      "{gameCompatibility: $gameCompatibility, dependencyChecks: $dependencyChecks}";
}

/// How much a given mod variant's dependency is satisfied.
class ModDependencyCheckResult {
  final Dependency dependency;
  final ModDependencySatisfiedState satisfiedAmount;

  ModDependencyCheckResult(this.dependency, this.satisfiedAmount);

  bool get isCurrentlySatisfied => satisfiedAmount is Satisfied;

  bool get canBeSatisfiedWithInstalledMods =>
      satisfiedAmount is Satisfied ||
      satisfiedAmount is Disabled ||
      satisfiedAmount is VersionWarning;

  @override
  String toString() =>
      "{dependency: $dependency, satisfiedAmount: $satisfiedAmount}";
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
