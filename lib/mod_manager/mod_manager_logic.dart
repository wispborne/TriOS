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
import 'package:trios/compression/archive.dart';
import 'package:trios/mod_manager/audit_log.dart';
import 'package:trios/mod_manager/mod_context_menu.dart';
import 'package:trios/mod_manager/mod_install_source.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/mod_profiles/models/mod_profile.dart';
import 'package:trios/mod_profiles/models/shared_mod_list.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/platform_specific.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/widgets/force_game_version_warning_dialog.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_with_icon.dart';

import '../chipper/utils.dart';
import '../models/mod.dart';
import '../models/mod_info.dart';
import '../models/version.dart';
import '../themes/theme_manager.dart';
import '../trios/settings/settings.dart';

final modManager = AsyncNotifierProvider<ModManagerNotifier, void>(
  ModManagerNotifier.new,
);

class ModManagerNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  Future<List<InstallModResult>> installModFromSourceWithDefaultUI(
    ModInstallSource modInstallSource, {
    bool forceDontEnableModUpdates = false,
  }) async {
    final context = ref.read(AppState.appContext);
    if (context == null) {
      return Future.value([]);
    }

    try {
      final installModsResult = await installModFromDisk(
        modInstallSource,
        ref.read(appSettings.select((s) => s.modsDir))!,
        ref.read(AppState.mods),
        (modsBeingInstalled) {
          return showDialog<List<ExtractedModInfo>>(
            context: context,
            builder: (context) {
              // Start by selecting to install variants that are not already installed.
              final List<ExtractedModInfo> extractedFilesToInstall =
                  modsBeingInstalled
                      .where((it) => it.alreadyExistingVariant == null)
                      .map((it) => it.modInfo)
                      .distinctBy((it) => it.modInfo.smolId)
                      .toList();

              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text("Install mods"),
                    content: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 400),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...modsBeingInstalled.map(
                              (it) => Builder(
                                builder: (context) {
                                  final isSelected = extractedFilesToInstall
                                      .contains(it.modInfo);
                                  final gameVersion = ref.watch(
                                    appSettings.select(
                                      (s) => s.lastStarsectorVersion,
                                    ),
                                  );

                                  final themeData = Theme.of(context);
                                  final iconColor = themeData.iconTheme.color
                                      ?.withOpacity(0.7);
                                  const iconSize = 20.0;
                                  const subtitleSize = 14.0;
                                  return MovingTooltipWidget.framed(
                                    tooltipWidget: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 500,
                                      ),
                                      child: Text(
                                        it.modInfo.modInfo
                                            .toMap()
                                            .prettyPrintJson(),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    child: CheckboxListTile(
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Mod name
                                          Text(
                                            "${it.modInfo.modInfo.name}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                          // Version and game version
                                          TextWithIcon(
                                            leading: Icon(
                                              Icons.info,
                                              size: iconSize,
                                              color: iconColor,
                                            ),
                                            widget: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        "v${it.modInfo.modInfo.version}",
                                                    style: const TextStyle(
                                                      fontSize: subtitleSize,
                                                    ),
                                                  ),
                                                  // bullet separator
                                                  TextSpan(
                                                    text: " • ",
                                                    style: TextStyle(
                                                      fontSize: subtitleSize,
                                                      color: iconColor,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: it
                                                        .modInfo
                                                        .modInfo
                                                        .gameVersion,
                                                    style: TextStyle(
                                                      fontSize: subtitleSize,
                                                      color:
                                                          (it.modInfo.modInfo
                                                                      .isCompatibleWithGame(
                                                                        gameVersion,
                                                                      )
                                                                      .getGameCompatibilityColor() ??
                                                                  themeData
                                                                      .colorScheme
                                                                      .onSurface)
                                                              .withOpacity(0.9),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // File path
                                          TextWithIcon(
                                            leading: Icon(
                                              Icons.folder,
                                              size: iconSize,
                                              color: iconColor,
                                            ),
                                            text: it
                                                .modInfo
                                                .extractedFile
                                                .relativePath,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: subtitleSize,
                                            ),
                                          ),

                                          // Description
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                              left: iconSize + 9,
                                            ),
                                            child: TextWithIcon(
                                              // leading: SvgImageIcon(
                                              //   "assets/images/icon-text.svg",
                                              //   width: iconSize,
                                              //   color: iconColor,
                                              // ),
                                              text:
                                                  it.modInfo.modInfo.description
                                                      ?.takeWhile(
                                                        (it) =>
                                                            it != "\n" &&
                                                            it != ".",
                                                      ) ??
                                                  "",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: themeData
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.9),
                                              ),
                                            ),
                                          ),
                                          it.alreadyExistingVariant != null
                                              ? Text(
                                                  isSelected
                                                      ? "(existing mod will be replaced)"
                                                      : "(already exists)",
                                                  style: TextStyle(
                                                    color: ThemeManager
                                                        .vanillaWarningColor,
                                                    fontSize: 12,
                                                  ),
                                                )
                                              : const SizedBox(),
                                        ],
                                      ),
                                      value: isSelected,
                                      onChanged: (value) {
                                        if (value == false) {
                                          setState(() {
                                            extractedFilesToInstall.remove(
                                              it.modInfo,
                                            );
                                          });
                                        } else {
                                          setState(() {
                                            // Only allow user to select one mod with the same id and version.
                                            extractedFilesToInstall.removeWhere(
                                              (existing) =>
                                                  existing.modInfo.smolId ==
                                                  it.modInfo.modInfo.smolId,
                                            );
                                            extractedFilesToInstall.add(
                                              it.modInfo,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (modsBeingInstalled
                                    .distinctBy(
                                      (it) => it.modInfo.modInfo.smolId,
                                    )
                                    .length !=
                                modsBeingInstalled.length)
                              Text(
                                "Multiple mods have the same id and version. Only one of those may be selected.",
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: ThemeManager.vanillaWarningColor,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(<ExtractedModInfo>[]);
                        },
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(extractedFilesToInstall);
                        },
                        child: const Text("Install"),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );

      if (installModsResult.isEmpty) {
        return [];
      }

      await ref.read(AppState.modVariants.notifier).reloadModVariants();
      final refreshedVariants = ref.read(AppState.modVariants).value ?? [];

      if (!forceDontEnableModUpdates &&
          ref.read(appSettings.select((s) => s.modUpdateBehavior)) ==
              ModUpdateBehavior.switchToNewVersionIfWasEnabled) {
        final mods = ref.read(AppState.mods);
        final successfulUpdates = installModsResult.where(
          (it) => it.err == null,
        );
        final enabledVariants = <ModVariant>[];

        for (final installed in successfulUpdates) {
          // Find the variant post-install so we can activate it.
          final actualVariant = refreshedVariants.firstWhereOrNull(
            (variant) => variant.smolId == installed.modInfo.smolId,
          );
          try {
            // If the mod existed and was enabled, switch to the newly downloaded version.

            if (actualVariant != null &&
                actualVariant.mod(mods)?.isEnabledInGame == true) {
              enabledVariants.add(actualVariant);
              // Should check for wrong game version here, but it requires a `ref` that we don't have.
              await changeActiveModVariant(
                actualVariant.mod(mods)!,
                actualVariant,
              );
            }
          } catch (ex) {
            Fimber.w(
              "Failed to activate mod ${installed.modInfo.smolId} after updating: $ex",
            );
            // }
          }
        }

        // Refresh all variants of touched mods.
        // final modifiedVariants = enabledVariants
        //     .map((it) => it.mod(mods))
        //     .nonNulls
        //     .toSet()
        //     .flatMap((it) => it.modVariants)
        //     .toList();
        await ref.read(AppState.modVariants.notifier).reloadModVariants();
      }

      final List<InstallModResult> errors = installModsResult
          .where((it) => it.err != null)
          .toList();
      if (errors.isNotEmpty) {
        showAlertDialog(
          context,
          title: "Error",
          widget: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: errors.length == 1
                              ? "There was an error while installing.\nPlease install the mod manually."
                              : "There were errors while installing.\nPlease install the mods manually.\n",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Check the ${Constants.appName} logs for more information.\n\n",
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
                            const Icon(Icons.error_outline),
                            const SizedBox(width: 8),
                            Text(
                              "${failedMod.modInfo.name} ${failedMod.modInfo.version}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  OpenFilex.open(
                                    failedMod.sourceFileEntity.parent.path,
                                  );
                                },
                                child: const Text("Show mod file"),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {
                                  OpenFilex.open(
                                    failedMod.destinationFolder.path,
                                  );
                                },
                                child: const Text(
                                  "Open Starsector mods folder",
                                ),
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
            },
          ),
        );
      }

      return installModsResult;
    } catch (e, st) {
      Fimber.w("Error installing mod from archive: $e", ex: e, stacktrace: st);
      if (!context.mounted) return [];
      showAlertDialog(context, title: "Error installing mod", content: "$e");
      return [];
    }
  }

  /// Given an [InstallModResult], attempts to install the mod(s) contained within it.
  /// If there are multiple mods in the source, or one or more mods are already installed, the user will be asked which mods to install/delete.
  /// Returns a list of ModInfos and any errors that occurred when installing each.
  /// userInputNeededHandler should return the list of SmolIds to install.
  /// [modInstallSource] should be an archive file or a folder.
  /// [destinationFolder] is the game's mods folder.
  /// [currentMods] is a list of all installed mods.
  Future<List<InstallModResult>> installModFromDisk(
    ModInstallSource modInstallSource,
    Directory destinationFolder,
    List<Mod> currentMods,
    Future<List<ExtractedModInfo>?> Function(
      List<({ExtractedModInfo modInfo, ModVariant? alreadyExistingVariant})>
      modInfosFound,
    )
    userInputNeededHandler, {
    bool dryRun = false,
  }) async {
    Fimber.i(
      "Installing mod from ${modInstallSource.runtimeType}: ${modInstallSource.entity.path} to ${destinationFolder.path}",
    );

    if (!modInstallSource.entity.existsSync()) {
      throw Exception("File does not exist: ${modInstallSource.entity.path}");
    }
    final results = <InstallModResult>[];
    final archive = ref.read(archiveProvider).requireValue;

    final archiveFileList = await modInstallSource.listFilePaths(archive);
    final modInfoFiles = archiveFileList
        .filter(
          (it) =>
              it.containsIgnoreCase(Constants.modInfoFileName) &&
              !it.toFile().nameWithExtension
              // avoid doing toFile() twice for each file
              .let((name) => name.startsWith(".") || name.startsWith("_")),
        )
        .toList();

    if (modInfoFiles.isEmpty) {
      throw Exception(
        "No mod_info.json file found in source:\n${modInstallSource.entity.path}",
      );
    }

    Fimber.i(
      "Found mod_info.json(s) file in source: ${modInfoFiles.map((it) => it).toList()}",
    );

    final extractedModInfos = await modInstallSource.getActualFiles(
      modInfoFiles,
      archive,
    );

    final List<ExtractedModInfo> modInfos = await Future.wait(
      extractedModInfos.nonNulls.map((modInfoFile) async {
        try {
          ExtractedModInfo modInfo = (
            extractedFile: modInfoFile,
            modInfo: ModInfoMapper.fromJson(
              modInfoFile.extractedFile
                  .readAsStringSyncAllowingMalformed()
                  .fixJson(),
            ),
          );
          return modInfo;
        } catch (e, st) {
          Fimber.e(
            "Error reading mod_info.json files: $e",
            ex: e,
            stacktrace: st,
          );
          return Future.error(
            Exception("Error parsing '${modInfoFile.extractedFile.path}':\n$e"),
            st,
          );
        }
      }),
    );

    // Check for mods that are already installed.
    var allModVariants = currentMods.variants;
    final alreadyPresentModVariants = modInfos
        .map((it) => getModVariantForModInfo(it.modInfo, allModVariants))
        .nonNulls
        .toList();

    if (alreadyPresentModVariants.isNotEmpty) {
      Fimber.i(
        "Mod already exists: ${alreadyPresentModVariants.map((it) => "${it.modInfo.id} ${it.modInfo.version}").toList()}",
      );
    }

    // User can choose to install only some of the mods (if multiple were found).
    var modInfosToInstall = modInfos;

    // If there are multiple mod_info.json files or one or more mods were already installed, ask user for input.
    if (alreadyPresentModVariants.isNotEmpty || modInfos.length > 1) {
      final userInput = await userInputNeededHandler(
        modInfos
            .map(
              (modInfo) => (
                modInfo: modInfo,
                alreadyExistingVariant: getModVariantForModInfo(
                  modInfo.modInfo,
                  alreadyPresentModVariants,
                ),
              ),
            )
            .toList(),
      );
      Fimber.i("User has chosen to install mods: $userInput");
      if (userInput == null) {
        return [];
      }
      // Grab just the modInfos that the user wants to install.
      modInfosToInstall = userInput
          .map(
            (selectedModInfoToInstall) => modInfos.firstWhere(
              (modInfo) => modInfo == selectedModInfoToInstall,
            ),
          )
          .toList();

      // Find any mods that are already installed.
      final existingVariantsMatchingOneBeingInstalled = modInfosToInstall
          .map((it) => getModVariantForModInfo(it.modInfo, allModVariants))
          .nonNulls
          .toList();

      // If the same mod variant is already installed, delete it first.
      for (var modToDelete in existingVariantsMatchingOneBeingInstalled) {
        if (dryRun) {
          Fimber.i(
            "Dry run: Would delete mod folder ${modToDelete.modFolder} before reinstalling same variant.",
          );
          continue;
        }

        try {
          modToDelete.modFolder.moveToTrash(deleteIfFailed: true);
          Fimber.i(
            "Deleted mod folder before reinstalling same variant: ${modToDelete.modFolder}",
          );
        } on Exception catch (e, st) {
          Fimber.e(
            "Error deleting mod folder: ${modToDelete.modFolder}",
            ex: e,
            stacktrace: st,
          );
          results.add((
            sourceFileEntity: modInstallSource.entity.toFile(),
            destinationFolder: destinationFolder,
            modInfo: modToDelete.modInfo,
            err: e,
            st: st,
          ));

          // If there was an error deleting the mod folder, don't install the new version.
          modInfosToInstall.removeWhere(
            (it) => it.modInfo.smolId == modToDelete.modInfo.smolId,
          );
        }
      }
    }

    final shouldPersistHighestVersionFolderName = ref.read(
      appSettings.select((s) => s.folderNamingSetting),
    );

    // Start installing the mods one by one.
    for (final modInfoToInstall in modInfosToInstall) {
      final fallbackFolderName =
          modInfoToInstall.extractedFile.originalFile.parent.path != "."
          ? modInfoToInstall.extractedFile.originalFile.parent.name
          : modInfoToInstall.modInfo.nameOrId.fixFilenameForFileSystem();

      try {
        String targetModFolderName = await setUpNewHighestModVersionFolder(
          modInfoToInstall.modInfo,
          fallbackFolderName,
          shouldPersistHighestVersionFolderName,
          currentMods,
          destinationFolder,
          dryRun: dryRun,
        );
        results.add(
          await installMod(
            modInfoToInstall,
            currentMods,
            archiveFileList,
            modInstallSource,
            destinationFolder,
            targetModFolderName,
            dryRun: dryRun,
          ),
        );
      } catch (e, st) {
        Fimber.w("Error installing mod: $e", ex: e, stacktrace: st);
        continue;
      }
    }

    return results;
  }

  /// Sets up the folder for the highest version of a mod.
  ///
  /// This function determines the appropriate folder name for the highest version of a mod.
  /// If the `shouldPersistHighestVersionFolderName` flag is true, it ensures that the highest version folder name is persisted.
  /// It also moves the contents of the highest version folder to a new versioned folder if necessary.
  ///
  /// @param modInfo The `ModInfo` object containing information about the mod.
  /// @param fallbackFolderName The fallback folder name to use if there wasn't a previously existing highest version.
  /// @param shouldPersistHighestVersionFolderName A boolean flag indicating whether to persist the highest version folder name.
  /// @param currentMods A list of currently installed mods.
  /// @param destinationFolder The destination folder where the mod should be installed.
  /// @param dryRun A boolean flag indicating whether this is a dry run (no actual file operations).
  /// @returns The name of the target mod folder.
  Future<String> setUpNewHighestModVersionFolder(
    ModInfo modInfo,
    String fallbackFolderName,
    FolderNamingSetting folderSetting,
    List<Mod> currentMods,
    Directory destinationFolder, {
    bool dryRun = false,
  }) async {
    var targetModFolderName = ModVariant.generateUniqueVariantFolderName(
      modInfo,
    );

    // If we persist the highest version folder name, do some extra logic.
    if (folderSetting == FolderNamingSetting.doNotChangeNameForHighestVersion) {
      final otherVariants = currentMods
          .where((mod) => mod.id == modInfo.id)
          .flatMap((mod) => mod.modVariants)
          .toList();
      if (otherVariants.isNotEmpty) {
        Fimber.i(
          "Found other versions of ${modInfo.id}: ${otherVariants.map((it) => it.modInfo.version).toList()}",
        );
        // Check if the new version is higher than any other installed version.
        var isHigherVersionThanAllExisting = !otherVariants.any(
          (existingVersion) =>
              (existingVersion.modInfo.version?.compareTo(modInfo.version) ??
                  0) >=
              0,
        );
        if (isHigherVersionThanAllExisting) {
          Fimber.i("New version is higher than all existing versions.");
          final highestVersion = otherVariants.maxByOrNull(
            (it) => it.modInfo.version ?? Version.zero(),
          )!;
          final highestVersionFolder = highestVersion.modFolder;
          final versionedNameForHighestVersion =
              ModVariant.generateUniqueVariantFolderName(
                highestVersion.modInfo,
              );

          if (versionedNameForHighestVersion == highestVersionFolder.name) {
            Fimber.w(
              "Wanted to avoid renaming highest version folder per user settings, but existing folder name contains mod version number, which is what we wanted to rename it to."
              "\nExisting: ${highestVersionFolder.name}. Would rename to: $versionedNameForHighestVersion"
              "\nUsing fallback name instead for new version ($fallbackFolderName) and leaving existing folder alone.",
            );
            return fallbackFolderName;
          }

          // Move the contents of the highest version folder to the new, versioned folder.
          try {
            Fimber.i(
              "Moving files from highest version folder ($highestVersionFolder) to new versioned folder ($versionedNameForHighestVersion).",
            );
            for (final folderItem in highestVersionFolder.listSync(
              recursive: true,
            )) {
              if (folderItem.isDirectory()) {
                continue; // Directories will be created as needed.
              }

              final file = folderItem.toFile();

              final relativePath = file.relativeTo(highestVersionFolder);
              final newFilePath = destinationFolder
                  .resolve(versionedNameForHighestVersion)
                  .resolve(relativePath)
                  .toFile();

              Fimber.d("Moving file: ${file.path} to $newFilePath");
              if (!dryRun) {
                newFilePath.toFile().parent.createSync(recursive: true);
                await file.renameSafely(newFilePath.path);
              }
            }
          } catch (e, st) {
            final msg =
                "Error moving files from highest version folder ($highestVersionFolder) to new versioned folder ($versionedNameForHighestVersion). Skipping mod ${modInfo.smolId}\n$e";
            Fimber.w(msg, ex: e, stacktrace: st);
            rethrow;
          }

          // Put the new mod into the folder of the previous highest version,
          // now that it's empty (we moved it into its own versioned folder).
          targetModFolderName = highestVersionFolder.name;
        }
      } else {
        final originalFolderInSource = fallbackFolderName;
        Fimber.i(
          "No other versions of ${modInfo.id} found. Using original folder name: $originalFolderInSource.",
        );
        targetModFolderName = originalFolderInSource;
      }
    } else if (folderSetting == FolderNamingSetting.doNotChangeNamesEver) {
      Fimber.i(
        "Not changing folder names for highest version. Using original folder name: $fallbackFolderName.",
      );
      targetModFolderName = fallbackFolderName;
    }

    return targetModFolderName;
  }

  Future<InstallModResult> installMod(
    ExtractedModInfo modInfoToInstall,
    List<Mod> currentMods,
    List<String> sourceFileList,
    ModInstallSource modInstallSource,
    Directory destinationFolder,
    String targetModFolderName, {
    bool dryRun = true,
  }) async {
    final modInfo = modInfoToInstall.modInfo;
    var existingMod = currentMods.firstWhereOrNull((it) => it.id == modInfo.id);

    try {
      // STEP 1: Find the mod_info.json file to determine the mod root folder.
      // This handles zips where there is no top-level folder, or multiple nested ones.
      // e.g. `/mod_info.json` or `/mod-name/mod_info.json` or `/mod/mod/mod/mod_info.json`.
      final modInfoParentFolder =
          modInfoToInstall.extractedFile.originalFile.parent;
      // TODO this is always empty because `sourceFileList` uses relative paths and `modInfoParentFolder` is an absolute path.
      final modInfoSiblings = sourceFileList
          .where((it) => it.toFile().parent.path == modInfoParentFolder.path)
          .toList();
      Fimber.d(
        "Mod info (${modInfoToInstall.extractedFile.originalFile.path}) siblings: ${modInfoSiblings.map((it) => it).toList()}",
      );

      // STEP 2: Extract the mod, transforming the extracted paths go to targetModFolderName.
      if (dryRun) {
        Fimber.i(
          "Dry run: Would extract mod ${modInfo.id} ${modInfo.version} to '$targetModFolderName'",
        );
        return (
          sourceFileEntity: modInstallSource.entity.toFile(),
          destinationFolder: destinationFolder,
          modInfo: modInfo,
          err: null,
          st: null,
        );
      }

      final errors = <(Object err, StackTrace? st)>[];
      final archive = ref.read(archiveProvider).requireValue;

      final extractedMod = await modInstallSource.createFilesAtDestination(
        destinationFolder.path,
        archive,
        fileFilter: (entry) => p.isWithin(modInfoParentFolder.path, entry),
        pathTransform: (entry) => p.join(
          targetModFolderName,
          p.relative(entry, from: modInfoParentFolder.path),
        ),
        onError: (e, st) {
          errors.add((e, st));
          Fimber.e(
            "Error extracting file: ${modInstallSource.entity.path}",
            ex: e,
            stacktrace: st,
          );
          return false;
        },
      );

      final newModFolder = destinationFolder
          .resolve(targetModFolderName)
          .toDirectory();
      Fimber.i(
        "Extracted ${extractedMod.length} files in mod ${modInfo.id} ${modInfo.version} to '$newModFolder'",
      );

      // Ensure we don't end up with two enabled variants.
      if (existingMod != null && existingMod.hasEnabledVariant) {
        Fimber.i(
          "There is already an enabled variant for ${modInfo.id}. Disabling newly installed variant ${modInfo.smolId} so both aren't enabled.",
        );
        disableModInfoFile(newModFolder, modInfo.smolId);
      }

      await cleanUpModVariantsBasedOnRetainSetting(modInfo.id, [
        modInfo.smolId,
      ], dryRun: dryRun);

      final missingFilesError = errors
          .map((record) => record.$1)
          .whereType<ModInstallValidationException>()
          .toList();
      if (missingFilesError.isNotEmpty) {
        throw missingFilesError.first;
      }

      return (
        sourceFileEntity: modInstallSource.entity.toFile(),
        destinationFolder: destinationFolder,
        modInfo: modInfo,
        err: null,
        st: null,
      );
    } on Exception catch (e, st) {
      Fimber.e("Error installing mod: $e", ex: e, stacktrace: st);
      return (
        sourceFileEntity: modInstallSource.entity.toFile(),
        destinationFolder: destinationFolder,
        modInfo: modInfo,
        err: e,
        st: st,
      );
    }
  }

  Future<List<ModInfo>> cleanUpAllModVariantsBasedOnRetainSetting({
    bool dryRun = false,
  }) {
    final mods = ref.read(AppState.mods);
    return Future.wait(
      mods.map(
        (mod) =>
            cleanUpModVariantsBasedOnRetainSetting(mod.id, [], dryRun: dryRun),
      ),
    ).then((it) => it.flattened.toList());
  }

  Future<List<ModInfo>> cleanUpModVariantsBasedOnRetainSetting(
    String modId,
    List<String> smolIdsToKeep, {
    bool dryRun = false,
  }) async {
    final lastNVersionsSetting = ref.read(
      appSettings.select((s) => s.keepLastNVersions),
    );
    if (lastNVersionsSetting == null) {
      Fimber.i(
        "keepLastNVersions setting is null (infinite). Not removing old mod variants.",
      );
      return [];
    }

    final mod = ref
        .read(AppState.mods)
        .firstWhereOrNull((it) => it.id == modId);
    if (mod == null) {
      Fimber.e("Mod not found: $modId");
      return [];
    }

    final variantsSpecificallyKept = mod.modVariants
        .where((it) => smolIdsToKeep.contains(it.modInfo.smolId))
        .toList();
    final theOtherVariants = mod.modVariants
        .where((it) => !smolIdsToKeep.contains(it.modInfo.smolId))
        .toList();

    final variantsToKeep = variantsSpecificallyKept
      ..addAll(
        theOtherVariants.sortedDescending().take(
          lastNVersionsSetting - variantsSpecificallyKept.length,
        ),
      );
    final variantsToDelete = mod.modVariants
        .where((it) => !variantsToKeep.contains(it))
        .toList();

    if (variantsToDelete.isEmpty) {
      Fimber.i("All variants of $modId are being retained.");
      return [];
    }

    Fimber.i(
      "Removing ${variantsToDelete.length} old mod variants for $modId. Keeping ${variantsToKeep.length} variants.",
    );
    for (final variant in variantsToDelete) {
      if (dryRun) {
        Fimber.i("Dry run: Would delete mod folder ${variant.modFolder}");
        continue;
      }
      try {
        variant.modFolder.moveToTrash(deleteIfFailed: true);
        Fimber.i("Deleted mod folder: ${variant.modFolder}");
      } catch (e, st) {
        Fimber.e(
          "Error deleting mod folder: ${variant.modFolder}",
          ex: e,
          stacktrace: st,
        );
      }
    }

    return variantsToDelete.map((it) => it.modInfo).toList();
  }

  /// You probably want to use `changeActiveModVariantWithForceModGameVersionDialogIfNeeded` instead, which shows a warning if the mod is for a different game version.
  Future<void> changeActiveModVariant(
    Mod mod,
    ModVariant? modVariant, {
    bool validateDependencies = true,
  }) async {
    final isDisablingMod = modVariant == null;
    Fimber.i(
      isDisablingMod
          ? "Disabling ${mod.id}."
          : "Changing active variant of ${mod.id} to ${modVariant.smolId}. (current: ${mod.findFirstEnabled?.smolId}).",
    );

    final modVariantParentModId = modVariant?.modInfo;
    if (modVariantParentModId != null && mod.id != modVariantParentModId.id) {
      final errMsg =
          "Mod variant ${modVariant?.smolId} does not belong to mod ${mod.id}.";
      Fimber.e(errMsg);
      throw Exception(errMsg);
    }

    // Optimization: If the mod variant is already enabled, don't do anything.
    if (modVariant != null && mod.isEnabled(modVariant)) {
      // Ensure that this is the only active variant.
      // If there are somehow more than one active variant for the mod, don't return here,
      // run the rest of the method to clean that up.
      if (mod.modVariants.countWhere((it) => mod.isEnabled(it)) <= 1) {
        Fimber.i("Variant ${modVariant.smolId} is already enabled.");
        return;
      }
    }

    // Variants that have `mod_info.json` instead of `mod_info.json.disabled`.
    // We'll want to change those to disabled when we're enabling a specific version.
    final modInfoEnabledVariants = mod.modVariants
        .where((it) => it.isModInfoEnabled)
        .toList();
    if (modVariant == null && modInfoEnabledVariants.isEmpty) {
      Fimber.i(
        "Went to disable the mod but no variants were active, nothing to do! $mod",
      );
      return;
    }

    // We're going to make a batch of changes, wait until they're done to refresh modVariants.
    // ref
    //     .read(AppState.modVariants.notifier)
    //     .shouldAutomaticallyReloadOnFilesChanged = false;

    // If enabling a variant, disable all other non-bricked mod variants
    // (except for the variant we want to actually enable, if that's already active).
    for (var variant in modInfoEnabledVariants) {
      if (variant.smolId != modVariant?.smolId) {
        try {
          await _disableModVariant(
            variant,
            // If disabling mod, disable in vanilla launcher.
            disableModInVanillaLauncher: isDisablingMod,
            // Only need to brick `mod_info.json` files if enabling one variant among many.
            // If disabling the mod, all `mod_info.json` files should be unbricked (happens later in this method).
            // If there's only one variant, it's fine to leave the `mod_info.json` file unbricked.
            brickModInfo: !isDisablingMod && mod.modVariants.length > 1,
            reason: isDisablingMod
                ? "You disabled ${mod.id} (${variant.modInfo.version} was enabled before)."
                : "Changed ${mod.id} to ${modVariant.modInfo.version}, so ${variant.bestVersion} has to be disabled.",
          );
        } catch (e, st) {
          Fimber.e("Error disabling mod variant: $e", ex: e, stacktrace: st);
        }
      }
    }

    if (!isDisablingMod) {
      await _enableModVariant(
        modVariant,
        mod,
        enableInVanillaLauncher: true,
        reason:
            "You changed ${mod.id} to version ${modVariant.bestVersion} from ${mod.findFirstEnabled == null ? "disabled" : mod.findFirstEnabled?.bestVersion}.",
      );
    } else {
      // If mod is disabled in `enabled_mods.json`, set all the `mod_info.json` files to non-bricked.
      // That makes things easier on the user & MOSS by mimicking vanilla behavior whenever possible.
      final disabledModVariants = mod.modVariants
          .where((v) => !v.isModInfoEnabled)
          .toList();
      for (final disabledVariant in disabledModVariants) {
        try {
          await _enableModInfoFile(disabledVariant);
        } catch (e, st) {
          Fimber.e(
            "Error enabling mod_info.json file: $e",
            ex: e,
            stacktrace: st,
          );
        }
      }
    }

    // ref
    //     .read(AppState.modVariants.notifier)
    //     .shouldAutomaticallyReloadOnFilesChanged = true;

    // TODO update ONLY the mod that changed and any dependents/dependencies.
    await ref
        .read(AppState.modVariants.notifier)
        .reloadModVariants(
          onlyVariants: {
            ...modInfoEnabledVariants,
            modVariant,
          }.nonNulls.toList(),
        );

    if (validateDependencies) {
      await validateModDependencies(modsToFreeze: [mod.id]);
    }
  }

  /// Check for multiple enabled variants for the same mod.
  /// If an enabled mod has a disabled dependency, enable the dependency.
  /// If an enabled mod's dependencies are not met, disable the mod.
  /// `modsToFreeze` is a list of mod ids that are being modified already and things should change around them.
  Future<void> validateModDependencies({List<String>? modsToFreeze}) async {
    if (ref.watch(
          appSettings.select((value) => value.autoEnableAndDisableDependencies),
        ) ==
        false) {
      Fimber.d("Auto dependency validation is disabled.");
      return;
    }
    final modifiedModIds = modsToFreeze?.toSet() ?? {};
    var numModsChangedLastLoop = 0;
    final gameVersion = ref.read(AppState.starsectorVersion).valueOrNull;

    do {
      numModsChangedLastLoop = 0;
      final enabledMods = ref
          .read(AppState.enabledModsFile)
          .valueOrNull
          ?.enabledMods
          .toList();
      if (enabledMods == null) return;

      final allVariants = ref.read(AppState.modVariants).valueOrNull ?? [];
      final allMods = AppState.getModsFromVariants(
        allVariants,
        enabledMods,
      ).toList();
      // final dependencyCheck = ref.read(AppState.modCompatibility);
      for (final mod in allMods) {
        if (!mod.isEnabledInGameSync(enabledMods)) continue;

        // Check for multiple enabled variants for the same mod.
        if (mod.enabledVariants.length > 1) {
          final highestEnabledVersion = mod.findHighestEnabledVersion;
          for (var value in mod.enabledVariants.where((variant) {
            return variant.smolId != highestEnabledVersion?.smolId;
          })) {
            Fimber.i(
              "Found multiple enabled versions for mod ${mod.id}. Disabling ${value.smolId}",
            );
            try {
              _disableModVariant(
                value,
                brickModInfo: true,
                disableModInVanillaLauncher: false,
                reason:
                    "When validating ${mod.id}, found multiple enabled versions. Only keeping ${highestEnabledVersion?.modInfo.version} enabled.",
              );
            } catch (e, st) {
              Fimber.e(
                "Error disabling mod variant: $e",
                ex: e,
                stacktrace: st,
              );
            }
          }
        }

        final enabledVariant = mod.findFirstEnabled;
        if (enabledVariant == null) continue;

        final dependenciesFound = enabledVariant.checkDependencies(
          allVariants,
          enabledMods,
          gameVersion,
        );
        Fimber.d(
          "Dependencies found for ${enabledVariant.smolId}: $dependenciesFound.",
        );

        for (final dependencyCheck in dependenciesFound) {
          final wasAlreadyModified =
              modifiedModIds.contains(dependencyCheck.dependency.id) == true;
          Fimber.d(
            "Dependency ${dependencyCheck.dependency.id} check for ${enabledVariant.smolId}: frozen? $wasAlreadyModified, ${dependencyCheck.satisfiedAmount}.",
          );

          // If an enabled mod has a disabled dependency, enable the dependency.
          if (dependencyCheck.dependency.id == null) continue;

          if (!modifiedModIds.contains(dependencyCheck.dependency.id) &&
              dependencyCheck.satisfiedAmount is Disabled) {
            final dependency = dependencyCheck.satisfiedAmount.modVariant!;
            Fimber.i(
              "Enabling dependency ${dependency.smolId} for ${enabledVariant.smolId}.",
            );
            modifiedModIds.add(mod.id);
            await changeActiveModVariant(
              dependency.mod(allMods)!,
              dependency,
              validateDependencies: false,
            );
            numModsChangedLastLoop++;
          } else if (!modifiedModIds.contains(mod.id) &&
                  dependencyCheck.satisfiedAmount is VersionInvalid ||
              dependencyCheck.satisfiedAmount is Missing ||
              dependencyCheck.satisfiedAmount is Disabled) {
            // If an enabled mod's dependencies are not met, disable the mod.
            Fimber.i(
              "Disabling ${mod.id} because ${dependencyCheck.dependency.formattedNameVersionId} was ${dependencyCheck.satisfiedAmount}.",
            );
            modifiedModIds.add(mod.id);
            await changeActiveModVariant(
              mod,
              null,
              validateDependencies: false,
            );
            numModsChangedLastLoop++;
          }
        }
      }

      if (numModsChangedLastLoop > 0) {
        Fimber.i(
          "Doing another validation pass. Modified so far: ${modifiedModIds.join(", ")}.",
        );
      }
    } while (numModsChangedLastLoop > 0);
  }

  Future<void> _enableModVariant(
    ModVariant modVariant,
    Mod mod, {
    bool enableInVanillaLauncher = true,
    required String reason,
  }) async {
    // final mods = ref.read(AppState.mods);
    // final mod = mods.firstWhereOrNull((mod) => mod.id == modVariant.modInfo.id);
    final enabledMods = ref.read(AppState.enabledModsFile).valueOrNull;
    Fimber.i("Enabling variant ${modVariant.smolId}");
    final modsFolderPath = ref.read(appSettings).modsDir;

    if (modsFolderPath == null || !modsFolderPath.existsSync()) {
      throw Exception("Mods folder does not exist: $modsFolderPath");
    }

    if (enabledMods == null) {
      throw Exception(
        "Enabled mods is null, can't enable mod ${modVariant.smolId}.",
      );
    }

    if (mod.isEnabled(modVariant)) {
      Fimber.i("Variant ${modVariant.smolId} is already enabled.");
      return;
    }

    // Look for any disabled mod_info files in the folder.
    await _enableModInfoFile(modVariant);

    if (enableInVanillaLauncher && !mod.isEnabledInGame) {
      await _enableModInEnabledMods(modVariant.modInfo.id);
    }

    ref
        .read(AppState.modAudit.notifier)
        .addAuditEntry(modVariant.smolId, ModAction.enable, reason: reason);
    ref.read(AppState.modsMetadata.notifier).updateModBaseMetadata(mod.id, (
      oldMetadata,
    ) {
      return oldMetadata.copyWith(
        lastEnabled: DateTime.now().millisecondsSinceEpoch,
      );
    });
    Fimber.i("Enabling ${modVariant.smolId}: success.");
  }

  Future<void> _enableModInfoFile(ModVariant modVariant) async {
    // Look for any disabled mod_info files in the folder.
    final disabledModInfoFiles =
        (await Constants.modInfoFileDisabledNames
                .map((it) => modVariant.modFolder.resolve(it).toFile())
                .whereAsync((it) async => await it.isWritable()))
            .toList();

    // And re-enable one.
    if (!modVariant.isModInfoEnabled) {
      disabledModInfoFiles.firstOrNull?.let((disabledModInfoFile) async {
        disabledModInfoFile.renameSync(
          modVariant.modFolder.resolve(Constants.modInfoFileName).path,
        );
        Fimber.i(
          "Re-enabled ${modVariant.smolId}: renamed ${disabledModInfoFile.nameWithExtension} to ${Constants.modInfoFileName}.",
        );
      });
    }
  }

  /// Use with caution. Prefer to use [changeActiveModVariant] instead.
  Future<void> _disableModVariant(
    ModVariant modVariant, {
    bool brickModInfo = false,
    bool disableModInVanillaLauncher = true,
    required String reason,
  }) async {
    final enabledMods = ref.read(AppState.enabledModIds).valueOrNull;
    final variants = ref.read(AppState.modVariants).valueOrNull ?? [];
    final mods = AppState.getModsFromVariants(
      variants,
      enabledMods.orEmpty().toList(),
    );
    Fimber.i(
      "Disabling variant '${modVariant.smolId}' (Set mod_info.json to disabled? $brickModInfo. Set enabled_mods to disabled? $disableModInVanillaLauncher.",
    );

    if (brickModInfo) {
      disableModInfoFile(modVariant.modFolder, modVariant.smolId);
    }

    if (disableModInVanillaLauncher) {
      final mod = modVariant.mod(mods)!;
      if (mod.isEnabledInGame) {
        Fimber.i(
          "Disabling mod '${modVariant.modInfo.id}' as part of disabling variant '${modVariant.smolId}'.",
        );
        _disableModInEnabledMods(modVariant.modInfo.id);
      } else {
        Fimber.i(
          "Mod '${modVariant.modInfo.id}' was already disabled in enabled_mods.json and won't be disabled as part of disabling variant ${modVariant.smolId}.",
        );
      }
    }

    // if (disableInVanillaLauncher) {
    //   val mod = modVariant.mod(modsCache) ?: return Result.failure(NullPointerException())
    //   if (mod.isEnabledInGame) {
    //     Timber.i { "Disabling mod ${modVariant.modInfo.id} as part of disabling variant ${modVariant.smolId}." }
    //     gameEnabledMods.disable(modVariant.modInfo.id)
    //   } else {
    //     Timber.i { "Mod ${modVariant.modInfo.id} was already disabled in enabled_mods.json and won't be disabled as part of disabling variant ${modVariant.smolId}." }
    //   }
    // }

    ref
        .read(AppState.modAudit.notifier)
        .addAuditEntry(modVariant.smolId, ModAction.disable, reason: reason);
    Fimber.i("Disabling '${modVariant.smolId}': success.");
  }

  void disableModInfoFile(Directory modFolder, String smolId) {
    final modInfoFile = modFolder.resolve(Constants.unbrickedModInfoFileName);

    if (!modInfoFile.existsSync()) {
      throw Exception("mod_info.json not found in ${modFolder.absolute}");
    }

    modInfoFile.renameSync(
      modInfoFile.parent.resolve(Constants.modInfoFileDisabledNames.first).path,
    );
    Fimber.i(
      "Disabled '$smolId': renamed to '${Constants.modInfoFileDisabledNames.first}'.",
    );
  }

  Future<void> _disableModInEnabledMods(String modId) async {
    ref.read(AppState.enabledModsFile.notifier).disableMod(modId);
  }

  Future<void> _enableModInEnabledMods(String modId) async {
    ref.read(AppState.enabledModsFile.notifier).enableMod(modId);
  }

  Future<void> forceChangeModGameVersion(
    ModVariant modVariant,
    String newGameVersion, {
    bool refreshModlistAfter = true,
  }) async {
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

    if (refreshModlistAfter) {
      await ref
          .read(AppState.modVariants.notifier)
          .reloadModVariants(onlyVariants: [modVariant]);
    }
  }

  /// Enables the highest version of each disabled mod passed in.
  /// Does not change already-enabled mods.
  Future<void> enableMultiple(List<Mod> mods) async {
    final disabledMods = mods.where((mod) => !mod.hasEnabledVariant).toList();

    if (disabledMods.isEmpty) {
      return;
    }

    Fimber.d("Enabling ${disabledMods.length} mods...");
    final modManagerNotifier = ref.read(modManager.notifier);

    for (final mod in disabledMods.sublist(0, disabledMods.length - 1)) {
      await modManagerNotifier
          .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
            mod,
            mod.findHighestVersion,
            validateDependencies: false,
          );
    }
    // Validate dependencies at the end only.
    await modManagerNotifier
        .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
          disabledMods.last,
          disabledMods.last.findHighestVersion,
          validateDependencies: true,
        );
  }

  /// Disables all mods passed in.
  Future<void> disableMultiple(List<Mod> mods) async {
    final enabledMods = mods.where((mod) => mod.hasEnabledVariant).toList();
    if (enabledMods.isEmpty) {
      return;
    }

    Fimber.d("Disabling ${enabledMods.length} mods...");
    var modManagerNotifier = ref.read(modManager.notifier);

    for (final mod in enabledMods) {
      await modManagerNotifier.changeActiveModVariant(
        mod,
        null,
        validateDependencies: false,
      );
    }
  }

  Future<void> changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
    Mod mod,
    ModVariant? modVariant, {
    bool validateDependencies = true,
    bool refreshModlistAfter = true,
  }) async {
    try {
      final currentStarsectorVersion = ref.read(
        appSettings.select((s) => s.lastStarsectorVersion),
      );
      final isGameRunning = ref.read(AppState.isGameRunning).value == true;

      if (modVariant != null &&
          isModGameVersionIncorrect(
            currentStarsectorVersion,
            isGameRunning,
            modVariant,
          )) {
        await showDialog(
          context: ref.read(AppState.appContext)!,
          builder: (context) {
            return ForceGameVersionWarningDialog(
              modVariant: modVariant,
              onForced: () {
                changeActiveModVariant(mod, modVariant);
              },
              refreshModlistAfter: refreshModlistAfter,
            );
          },
        );
      } else {
        await changeActiveModVariant(
          mod,
          modVariant,
          validateDependencies: validateDependencies,
        );
      }
    } catch (e, st) {
      Fimber.e("Error while changing mod variant", ex: e, stacktrace: st);
      rethrow;
    }
  }
}

bool isModGameVersionIncorrect(
  String? currentStarsectorVersion,
  bool isGameRunning,
  ModVariant modVariant,
) {
  return currentStarsectorVersion != null &&
      !isGameRunning &&
      !Version.parse(
        modVariant.modInfo.gameVersion ?? "0.0.0",
        sanitizeInput: true,
      ).equalsSymbolic(
        Version.parse(currentStarsectorVersion, sanitizeInput: true),
      );
}

typedef ExtractedModInfo = ({SourcedFile extractedFile, ModInfo modInfo});

typedef InstallModResult = ({
  File sourceFileEntity,
  Directory destinationFolder,
  ModInfo modInfo,
  Exception? err,
  StackTrace? st,
});

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

      // try {
      final model = ModInfo.fromJsonModel(
        ModInfoJsonMapper.fromJson(jsonEncodedYaml),
        modFolder,
      );

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
    Fimber.v(
      () =>
          "Unable to find or read 'mod_info.json' in ${modFolder.absolute}. ($e)\n$st",
    );
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

addModsFolderFileWatcher(
  Directory modsFolder,
  Function(List<File> modInfoFilesFound) onUpdated,
) {
  modsFolder.watch()
    ..listen((event) {
      if (event.type == FileSystemEvent.create ||
          event.type == FileSystemEvent.delete ||
          event.type == FileSystemEvent.modify) {
        // checkModsFolderForUpdates(modsFolder, (_) {});
        onUpdated([event.path.toFile()]);
      }
    })
    ..handleError((error) {
      Fimber.w("Error watching mods folder: $error");
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
//       .nonNulls
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
  Set<String>? modIds,
  List<Mod> allMods,
  BuildContext context,
) {
  final enabledModsList = modIds
      .orEmpty()
      .map((id) => allMods.firstWhereOrNull((mod) => mod.id == id))
      .nonNulls
      .toList()
      .sortedByName;
  copyModListToClipboardFromMods(enabledModsList, context);
}

void copyModListToClipboard({
  String? id,
  String? name,
  String? description,
  required List<ShallowModVariant> variants,
  DateTime? dateCreated,
  DateTime? dateModified,
  required BuildContext context,
}) {
  final sharedList = createSharedModListFromVariants(
    id,
    name,
    description,
    dateCreated,
    dateModified,
    variants,
  );
  copySharedModListToClipboard(sharedList, context);
}

void copyModListToClipboardFromMods(List<Mod> mods, BuildContext context) {
  Clipboard.setData(
    ClipboardData(
      text:
          "Mods (${mods.length})\n${mods.map((mod) {
            final variant = mod.findFirstEnabledOrHighestVersion;
            return "${variant?.modInfo.name}  v${variant?.modInfo.version}  [${mod.id}]";
          }).join('\n')}",
    ),
  );
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Copied mod list to clipboard.")),
  );
}

void copySharedModListToClipboard(
  SharedModList sharedModList,
  BuildContext context,
) {
  Clipboard.setData(ClipboardData(text: sharedModList.toShareString()));
  // Clipboard.setData(ClipboardData(text: sharedModList.toMap().prettyPrintJson()));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Copied mod list to clipboard. Import via Mod Profiles page.",
      ),
    ),
  );
}

SharedModList createSharedModListFromVariants(
  String? id,
  String? name,
  String? description,
  DateTime? dateCreated,
  DateTime? dateModified,
  List<ShallowModVariant> variants,
) {
  final enabledModVariants = variants.map((variant) {
    return SharedModVariant(
      modId: variant.modId,
      modName: variant.modName,
      smolVariantId: variant.smolVariantId,
      versionName: variant.version,
    );
  }).toList();

  return SharedModList.create(
    id: id,
    name: name ?? "Current Mod List",
    description: description ?? "Generated mod list from TriOS",
    mods: enabledModVariants,
    dateCreated: dateCreated,
    dateModified: dateModified,
  );
}

GameCompatibility compareGameVersions(
  String? modGameVersion,
  String? gameVersion,
) {
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
      ? [Satisfied, Disabled, VersionWarning, VersionInvalid, Missing]
      : [Missing, VersionInvalid, VersionWarning, Disabled, Satisfied];

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
          (it) => it is Satisfied || it is Disabled || it is VersionWarning,
        )
        .prefer(
          (it) =>
              gameVersion != null &&
              it.modVariant?.isCompatibleWithGameVersion(
                    gameVersion.toString(),
                  ) !=
                  GameCompatibility.incompatible,
        )
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
  ModInfo modInfo,
  List<ModVariant> modVariants,
) {
  return modVariants.firstWhereOrNull(
    (it) => it.modInfo.smolId == modInfo.smolId,
  );
}

class VersionCheckComparison {
  final ModVariant variant;
  late final RemoteVersionCheckResult? remoteVersionCheck;
  late final int? comparisonInt;

  VersionCheckComparison(
    this.variant,
    Map<String, RemoteVersionCheckResult> versionChecks,
  ) {
    remoteVersionCheck = versionChecks[variant.smolId];
    comparisonInt = compareLocalAndRemoteVersions(
      variant.versionCheckerInfo,
      remoteVersionCheck,
    );
  }

  VersionCheckComparison.specific(this.variant, this.remoteVersionCheck) {
    comparisonInt = compareLocalAndRemoteVersions(
      variant.versionCheckerInfo,
      remoteVersionCheck,
    );
  }

  bool get hasUpdate => comparisonInt != null && comparisonInt! < 0;

  /// The actual comparison of the local and remote versions.
  /// Returns 0 if the versions are the same, -1 if the remote version is newer, and 1 if the local version is newer.
  /// Usually, you should use [VersionCheckComparison] instead.
  static int? compareLocalAndRemoteVersions(
    VersionCheckerInfo? local,
    RemoteVersionCheckResult? remote,
  ) {
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
      getTopDependencySeverity(
        dependencyStates,
        gameVersion,
        sortLeastSevere: false,
      ).let(
        (it) => dependencyChecks.firstWhereOrNull(
          (dep) => dep.satisfiedAmount == it,
        ),
      );

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

  bool get canBeSatisfiedWithInstalledModsButIsnt =>
      !isCurrentlySatisfied && canBeSatisfiedWithInstalledMods;

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
