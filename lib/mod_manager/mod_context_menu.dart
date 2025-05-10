import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/platform_specific.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mod.dart';
import '../trios/app_state.dart';
import '../utils/logging.dart';
import '../widgets/debug_info.dart';

ContextMenu buildModContextMenu(
  Mod mod,
  WidgetRef ref,
  BuildContext context, {
  bool showSwapToVersion = true,
}) {
  final currentStarsectorVersion = ref.read(
    appSettings.select((s) => s.lastStarsectorVersion),
  );
  final modVariant = mod.findFirstEnabledOrHighestVersion!;
  final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

  return ContextMenu(
    entries: <ContextMenuEntry>[
      if (!isGameRunning && showSwapToVersion)
        buildMenuItemChangeVersion(mod, ref),
      buildMenuItemOpenFolder(mod),
      buildMenuItemOpenModInfoFile(mod),
      buildMenuItemOpenForumPage(modVariant, context),
      if (ref.watch(AppState.vramEstimatorProvider).valueOrNull?.isScanning !=
          true)
        buildMenuItemCheckVram(mod, ref),
      buildMenuItemToggleMuteUpdates(mod, ref),
      if (!isGameRunning) menuItemDeleteFolder(mod, context, ref),
      if (isModGameVersionIncorrect(
        currentStarsectorVersion,
        isGameRunning,
        modVariant,
      ))
        buildMenuItemForceChangeModGameVersion(
          currentStarsectorVersion!,
          ref,
          modVariant,
        ),
      buildMenuItemDebugging(context, mod, ref, isGameRunning),
    ],
    padding: const EdgeInsets.all(8.0),
  );
}

ContextMenu buildModBulkActionContextMenu(
  List<Mod> selectedMods,
  WidgetRef ref,
  BuildContext context,
) {
  final currentStarsectorVersion = ref.read(
    appSettings.select((s) => s.lastStarsectorVersion),
  );
  final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

  return ContextMenu(
    entries: <ContextMenuEntry>[
      MenuHeader(text: "${selectedMods.length} mods selected"),
      if (!isGameRunning && selectedMods.any((mod) => !mod.hasEnabledVariant))
        MenuItem(
          label: 'Enable',
          icon: Icons.toggle_on,
          onSelected: () async {
            for (final mod in selectedMods.sublist(
              0,
              selectedMods.length - 1,
            )) {
              await ref
                  .read(modManager.notifier)
                  .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                    mod,
                    mod.findHighestVersion,
                    validateDependencies: false,
                  );
            }
            // Validate dependencies only at the end.
            await ref
                .read(modManager.notifier)
                .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                  selectedMods.last,
                  selectedMods.last.findHighestVersion,
                  validateDependencies: true,
                );
            ref.invalidate(AppState.modVariants);
          },
        ),
      if (!isGameRunning && selectedMods.any((mod) => mod.hasEnabledVariant))
        MenuItem(
          label: 'Disable',
          icon: Icons.toggle_off,
          onSelected: () async {
            // Validate dependencies only at the end.
            for (final mod in selectedMods.sublist(
              0,
              selectedMods.length - 1,
            )) {
              // Don't need to use changeActiveModVariantWithForceModGameVersionDialogIfNeeded because we're disabling the mod.
              await ref
                  .read(modManager.notifier)
                  .changeActiveModVariant(
                    mod,
                    null,
                    validateDependencies: false,
                  );
            }
            // Validate dependencies only at the end.
            await ref
                .read(modManager.notifier)
                .changeActiveModVariant(
                  selectedMods.last,
                  null,
                  validateDependencies: true,
                );
            ref.invalidate(AppState.modVariants);
          },
        ),
      // check vram of selected
      MenuItem(
        label: 'Check VRAM of selected',
        icon: Icons.memory,
        onSelected: () {
          ref
              .read(AppState.vramEstimatorProvider.notifier)
              .startEstimating(
                variantsToCheck:
                    selectedMods
                        .map((mod) => mod.findFirstEnabledOrHighestVersion!)
                        .toList(),
              );
        },
      ),
      MenuItem(
        label: 'Check for updates',
        icon: Icons.refresh,
        onSelected: () {
          ref
              .read(AppState.versionCheckResults.notifier)
              .refresh(
                skipCache: true,
                specificVariantsToCheck:
                    selectedMods
                        .map((mod) => mod.findFirstEnabledOrHighestVersion!)
                        .toList(),
              );
        },
      ),

      if (selectedMods.any(
        (mod) => isModGameVersionIncorrect(
          currentStarsectorVersion,
          isGameRunning,
          mod.findFirstEnabledOrHighestVersion!,
        ),
      ))
        MenuItem(
          label: 'Force to $currentStarsectorVersion',
          icon: Icons.electric_bolt,
          onSelected: () {
            showDialog(
              context: ref.context,
              builder: (context) {
                return ForceGameVersionWarningDialog(mods: selectedMods);
              },
            );
          },
        ),
    ],
    padding: const EdgeInsets.all(8.0),
  );
}

MenuItem<dynamic> buildMenuItemForceChangeModGameVersion(
  String currentStarsectorVersion,
  WidgetRef ref,
  ModVariant modVariant,
) {
  return MenuItem(
    label: 'Force to $currentStarsectorVersion',
    icon: Icons.electric_bolt,
    onSelected: () {
      showDialog(
        context: ref.context,
        builder:
            (context) => ForceGameVersionWarningDialog(modVariant: modVariant),
      );
    },
  );
}

class ForceGameVersionWarningDialog extends ConsumerWidget {
  final ModVariant? modVariant;
  final List<Mod>? mods;
  final Function()? onForced;
  final bool refreshModlistAfter;

  ForceGameVersionWarningDialog({
    super.key,
    this.modVariant,
    this.mods,
    this.onForced,
    this.refreshModlistAfter = true,
  }) {
    assert(
      modVariant != null || mods?.isNotEmpty == true,
      "At least one of 'mods' or 'modVariant' must be provided",
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;
    final currentStarsectorVersion = ref.read(
      appSettings.select((s) => s.lastStarsectorVersion),
    );

    if (currentStarsectorVersion == null) {
      return AlertDialog(
        title: const Text("Error"),
        content: const Text("Could not determine current Starsector version."),
      );
    }

    final modsToForce =
        (mods
                    ?.where(
                      (mod) => isModGameVersionIncorrect(
                        currentStarsectorVersion,
                        isGameRunning,
                        mod.findFirstEnabledOrHighestVersion!,
                      ),
                    )
                    .map((mod) => mod.findFirstEnabledOrHighestVersion!) ??
                [modVariant!])
            .toList();
    final hasMultiple = modsToForce.length > 1;

    final singleModIntro =
        hasMultiple
            ? ""
            : "'${modsToForce.single.modInfo.nameOrId}' was made for Starsector ${modsToForce.single.modInfo.gameVersion}, but you can try running it in $currentStarsectorVersion.\n";

    // Split the singleModIntro into parts to apply bold formatting to the mod name
    final singleModIntroParts =
        hasMultiple
            ? <TextSpan>[]
            : [
              TextSpan(
                text: modsToForce.single.modInfo.nameOrId,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text:
                    " was made for Starsector ${modsToForce.single.modInfo.gameVersion}, but you can try running it in $currentStarsectorVersion.\n",
              ),
            ];

    return AlertDialog(
      title: Text(
        "Force ${hasMultiple ? "${modsToForce.length} mods " : ""}to $currentStarsectorVersion?",
      ),
      content: RichText(
        text: TextSpan(
          children: [
            ...singleModIntroParts, // Use the split parts here
            TextSpan(
              text:
                  "${hasMultiple ? singleModIntro : ""}Simple mods like portrait packs should be fine. Game updates usually don't break mods, but it depends on the mod and the game version.\n\n",
            ),
            if (hasMultiple)
              TextSpan(
                text:
                    "${modsToForce.joinToString(separator: '\n', transform: (mod) => "- ${mod.modInfo.nameOrId} (${mod.modInfo.version}) is meant for Starsector '${mod.modInfo.gameVersion}'.")}"
                    "\n\n",
              ),
            TextSpan(
              text:
                  hasMultiple
                      ? "Are you sure you want to modify ${modsToForce.length} mod_info.json files "
                          "to run on $currentStarsectorVersion?"
                      : "Are you sure you want to modify the '${modsToForce.single.modInfo.nameOrId}' mod_info.json file "
                          "to run on $currentStarsectorVersion?",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            for (final variant in modsToForce) {
              ref
                  .read(modManager.notifier)
                  .forceChangeModGameVersion(
                    variant,
                    currentStarsectorVersion,
                    refreshModlistAfter: refreshModlistAfter,
                  );
            }
            ref.invalidate(AppState.modVariants);
            onForced?.call();
          },
          child: const Text("Force"),
        ),
      ],
    );
  }
}

MenuItem<dynamic> buildMenuItemOpenForumPage(
  ModVariant modVariant,
  BuildContext context,
) {
  return MenuItem(
    label:
        'Open Forum Page${modVariant.versionCheckerInfo?.modThreadId == null ? ' (not set)' : ''}',
    icon: Icons.open_in_browser,
    onSelected: () {
      if (modVariant.versionCheckerInfo?.modThreadId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Mod has not set up Version Checker, or it does not contain a forum thread id.",
            ),
          ),
        );
        return;
      }
      launchUrl(
        Uri.parse(
          "${Constants.forumModPageUrl}${modVariant.versionCheckerInfo?.modThreadId}",
        ),
      );
    },
  );
}

MenuItem buildMenuItemOpenFolder(Mod mod) {
  if (mod.modVariants.length == 1) {
    return MenuItem(
      label: 'Open Folder',
      icon: Icons.folder,
      onSelected: () {
        launchUrl(
          Uri.parse("file:${mod.modVariants.first.modFolder.absolute.path}"),
        );
      },
    );
  } else {
    return MenuItem.submenu(
      label: "Open Folder...",
      icon: Icons.folder,
      onSelected: () {
        launchUrl(
          Uri.parse(
            "file:${mod.findFirstEnabledOrHighestVersion?.modFolder.absolute.path}",
          ),
        );
      },
      items: [
        for (var variant in mod.modVariants.sortedDescending())
          MenuItem(
            label: variant.modInfo.version.toString(),
            onSelected: () {
              variant.modFolder.absolute.path.openAsUriInBrowser();
            },
          ),
      ],
    );
  }
}

MenuItem buildMenuItemChangeVersion(Mod mod, WidgetRef ref) {
  final enabledSmolId = mod.findFirstEnabled?.smolId;
  final isEnabled = enabledSmolId != null;

  return MenuItem.submenu(
    label: "Change to...",
    icon: Icons.toggle_on,
    onSelected: () {
      if (isEnabled) {
        // Don't need changeActiveModVariantWithForceModGameVersionDialogIfNeeded because we're disabling the mod.
        ref.watch(modManager.notifier).changeActiveModVariant(mod, null);
      } else {
        ref
            .watch(modManager.notifier)
            .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
              mod,
              mod.findHighestVersion,
            );
      }
    },
    items: [
      if (isEnabled)
        MenuItem(
          label: "Disable",
          icon: Icons.close,
          onSelected: () {
            ref.watch(modManager.notifier).changeActiveModVariant(mod, null);
          },
        ),
      for (var variant in mod.modVariants.sortedDescending())
        MenuItem(
          icon:
              variant.smolId == enabledSmolId ? Icons.power_settings_new : null,
          label:
              variant.modInfo.version.toString() +
              (variant.smolId == enabledSmolId ? " (enabled)" : ""),
          onSelected: () {
            ref
                .watch(modManager.notifier)
                .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                  mod,
                  variant,
                );
          },
        ),
    ],
  );
}

MenuItem buildMenuItemOpenModInfoFile(Mod mod) {
  final modVariant = mod.findFirstEnabledOrHighestVersion!;
  return MenuItem(
    label: 'Open mod_info.json',
    icon: Icons.edit_note,
    onSelected: () {
      launchUrl(
        Uri.parse(
          "file:${getModInfoFile(modVariant.modFolder)?.absolute.path}",
        ),
      );
    },
  );
}

MenuItem menuItemDeleteFolder(Mod mod, BuildContext context, WidgetRef ref) {
  Future<void> deleteFolder(String folderPath) async {
    final directory = Directory(folderPath);
    final modsDir = ref.read(appSettings.select((s) => s.modsDir))!.path;

    if (p.equals(folderPath, modsDir)) {
      Fimber.e("Refusing to delete the mods root folder");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Did you just try to delete your mods folder? No!"),
        ),
      );
      return;
    }

    if (await directory.exists()) {
      directory.moveToTrash(deleteIfFailed: true);
    }
    ref.read(AppState.modVariants.notifier).reloadModVariants();
  }

  Future<void> showDeleteConfirmationDialog(List<String> folderPaths) async {
    runZonedGuarded(
      () async {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Delete Mod${folderPaths.length > 1 ? "s" : ""}'),
              content: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Are you sure you want to delete:\n'),
                    for (var folderPath in folderPaths)
                      Text("• ${folderPath.toDirectory().name}"),
                    const Text("\nThis action cannot be undone."),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  label: const Text('Delete'),
                  icon: const Icon(Icons.delete),
                ),
              ],
            );
          },
        );

        if (shouldDelete == true) {
          for (var folderPath in folderPaths) {
            deleteFolder(folderPath);
          }
        }
      },
      (e, s) {
        Fimber.w("Error deleting mod folder", ex: e, stacktrace: s);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "An error occurred while deleting the mod folder(s).",
            ),
          ),
        );
      },
    );
  }

  if (mod.modVariants.length == 1) {
    return MenuItem(
      label: 'Delete Folder',
      icon: Icons.delete,
      onSelected: () {
        showDeleteConfirmationDialog([
          mod.modVariants.first.modFolder.absolute.path,
        ]);
      },
    );
  } else {
    final modVariantsSorted = mod.modVariants.sortedDescending();
    return MenuItem.submenu(
      label: "Delete Folder...",
      icon: Icons.delete,
      items: [
        for (var variant in modVariantsSorted)
          MenuItem(
            label: variant.modInfo.version.toString(),
            onSelected: () {
              showDeleteConfirmationDialog([variant.modFolder.absolute.path]);
            },
          ),
        MenuItem(
          label: "All but ${modVariantsSorted.firstOrNull?.modInfo.version}",
          onSelected: () {
            showDeleteConfirmationDialog(
              modVariantsSorted
                  .skip(1)
                  .map((v) => v.modFolder.absolute.path)
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

MenuItem buildMenuItemDebugging(
  BuildContext context,
  Mod mod,
  WidgetRef ref,
  bool isGameRunning,
) {
  final latestVersionWithDirectDownload = mod.modVariants
      .sortedDescending()
      .firstWhereOrNull((v) => v.versionCheckerInfo?.hasDirectDownload == true);

  var redownloadEnabled = latestVersionWithDirectDownload != null;
  return MenuItem.submenu(
    label: "Troubleshoot...",
    icon: Icons.bug_report,
    onSelected: () => showDebugViewDialog(context, mod),
    items: [
      MenuItem(
        label: "Show Raw Info",
        icon: Icons.info_outline,
        onSelected: () => showDebugViewDialog(context, mod),
      ),
      if (!isGameRunning)
        MenuItem(
          label:
              (redownloadEnabled)
                  ? "Redownload & Reinstall"
                  : "Redownload unavailable",
          icon: redownloadEnabled ? Icons.downloading : null,
          onSelected: () {
            if (redownloadEnabled) {
              ref
                  .read(downloadManager.notifier)
                  .downloadAndInstallMod(
                    latestVersionWithDirectDownload.modInfo.nameOrId,
                    latestVersionWithDirectDownload
                        .versionCheckerInfo!
                        .directDownloadURL!,
                    activateVariantOnComplete: false,
                    modInfo: latestVersionWithDirectDownload.modInfo,
                  );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "This mod does not support direct download. Please manually redownload/reinstall.",
                  ),
                ),
              );
            }
          },
        ),
    ],
  );
}

MenuItem buildMenuItemCheckVram(Mod mod, WidgetRef ref) {
  return MenuItem(
    label: 'Estimate VRAM Usage',
    icon: Icons.memory,
    onSelected: () {
      ref
          .read(AppState.vramEstimatorProvider.notifier)
          .startEstimating(
            variantsToCheck: [mod.findFirstEnabledOrHighestVersion!],
          );
    },
  );
}

MenuItem buildMenuItemToggleMuteUpdates(Mod mod, WidgetRef ref) {
  final modsMetadata = ref.watch(AppState.modsMetadata).valueOrNull;
  final isMuted =
      modsMetadata?.getMergedModMetadata(mod.id)?.areUpdatesMuted == true;

  return MenuItem(
    label: isMuted ? 'Unmute Updates' : 'Mute Updates',
    icon: isMuted ? Icons.notifications : Icons.notifications_off,
    onSelected: () {
      ref
          .read(AppState.modsMetadata.notifier)
          .updateModUserMetadata(
            mod.id,
            (oldMetadata) => oldMetadata.copyWith(areUpdatesMuted: !isMuted),
          );
      if (isMuted) {
        // Fire version check for the mod.
        ref
            .read(AppState.versionCheckResults.notifier)
            .refresh(
              skipCache: true,
              specificVariantsToCheck: [mod.findFirstEnabledOrHighestVersion!],
              evenIfMuted: true,
            );
      }
    },
  );
}
