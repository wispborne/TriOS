import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/platform_specific.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mod.dart';
import '../trios/app_state.dart';
import '../utils/logging.dart';
import '../widgets/debug_info.dart';

ContextMenu buildModContextMenu(Mod mod, WidgetRef ref, BuildContext context,
    {bool showSwapToVersion = true}) {
  final currentStarsectorVersion =
      ref.read(appSettings.select((s) => s.lastStarsectorVersion));
  final modVariant = mod.findFirstEnabledOrHighestVersion!;
  final isGameRunning = ref.watch(AppState.isGameRunning).value == true;

  return ContextMenu(
    entries: <ContextMenuEntry>[
      if (!isGameRunning && showSwapToVersion && mod.modVariants.length > 1)
        menuItemChangeVersion(mod, ref),
      menuItemOpenFolder(mod),
      menuItemOpenModInfoFile(mod),
      MenuItem(
        label:
            'Open Forum Page${modVariant.versionCheckerInfo?.modThreadId == null ? ' (not set)' : ''}',
        icon: Icons.open_in_browser,
        onSelected: () {
          if (modVariant.versionCheckerInfo?.modThreadId == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  "Mod has not set up Version Checker, or it does not contain a forum thread id."),
            ));
            return;
          }
          launchUrl(Uri.parse(
              "${Constants.forumModPageUrl}${modVariant.versionCheckerInfo?.modThreadId}"));
        },
      ),
      menuItemCheckVram(mod, ref),
      if (!isGameRunning) menuItemDeleteFolder(mod, context, ref),
      if (currentStarsectorVersion != null &&
          !isGameRunning &&
          Version.parse(modVariant.modInfo.gameVersion ?? "0.0.0",
                  sanitizeInput: true) !=
              Version.parse(currentStarsectorVersion, sanitizeInput: true))
        MenuItem(
            label: 'Force to $currentStarsectorVersion',
            icon: Icons.electric_bolt,
            onSelected: () {
              ref.read(modManager.notifier).forceChangeModGameVersion(
                  modVariant, currentStarsectorVersion);
              ref.invalidate(AppState.modVariants);
            }),
      menuItemDebugging(context, mod, ref, isGameRunning),
    ],
    padding: const EdgeInsets.all(8.0),
  );
}

MenuItem menuItemOpenFolder(Mod mod) {
  if (mod.modVariants.length == 1) {
    return MenuItem(
        label: 'Open Folder',
        icon: Icons.folder,
        onSelected: () {
          launchUrl(Uri.parse(
              "file:${mod.modVariants.first.modFolder.absolute.path}"));
        });
  } else {
    return MenuItem.submenu(
        label: "Open Folder...",
        icon: Icons.folder,
        onSelected: () {
          launchUrl(Uri.parse(
              "file:${mod.findFirstEnabledOrHighestVersion?.modFolder.absolute.path}"));
        },
        items: [
          for (var variant in mod.modVariants.sortedDescending())
            MenuItem(
                label: variant.modInfo.version.toString(),
                onSelected: () {
                  launchUrl(
                      Uri.parse("file:${variant.modFolder.absolute.path}"));
                }),
        ]);
  }
}

MenuItem menuItemChangeVersion(Mod mod, WidgetRef ref) {
  final enabledSmolId = mod.findFirstEnabled?.smolId;

  return MenuItem.submenu(
      label: "Enable Mod...",
      icon: Icons.toggle_on,
      onSelected: () {
        ref
            .watch(AppState.modVariants.notifier)
            .changeActiveModVariant(mod, mod.findHighestVersion);
      },
      items: [
        for (var variant in mod.modVariants.sortedDescending())
          MenuItem(
            icon: variant.smolId == enabledSmolId
                ? Icons.power_settings_new
                : null,
            label: variant.modInfo.version.toString() +
                (variant.smolId == enabledSmolId ? " (enabled)" : ""),
            onSelected: () {
              ref
                  .watch(AppState.modVariants.notifier)
                  .changeActiveModVariant(mod, variant);
            },
          ),
        if (enabledSmolId != null)
          MenuItem(
            label: "Disable",
            icon: Icons.close,
            onSelected: () {
              ref
                  .watch(AppState.modVariants.notifier)
                  .changeActiveModVariant(mod, null);
            },
          ),
      ]);
}

MenuItem menuItemOpenModInfoFile(Mod mod) {
  final modVariant = mod.findFirstEnabledOrHighestVersion!;
  return MenuItem(
    label: 'Open mod_info.json',
    icon: Icons.edit_note,
    onSelected: () {
      launchUrl(Uri.parse(
          "file:${getModInfoFile(modVariant.modFolder)?.absolute.path}"));
    },
  );
}

MenuItem menuItemDeleteFolder(Mod mod, BuildContext context, WidgetRef ref) {
  Future<void> deleteFolder(String folderPath) async {
    final directory = Directory(folderPath);
    if (await directory.exists()) {
      directory.moveToTrash(deleteIfFailed: true);
    }
    ref.read(AppState.modVariants.notifier).reloadModVariants();
  }

  Future<void> showDeleteConfirmationDialog(List<String> folderPaths) async {
    runZonedGuarded(() async {
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
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
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
    }, (e, s) {
      Fimber.w("Error deleting mod folder", ex: e, stacktrace: s);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("An error occurred while deleting the mod folder(s)."),
      ));
    });
  }

  if (mod.modVariants.length == 1) {
    return MenuItem(
      label: 'Delete Folder',
      icon: Icons.delete,
      onSelected: () {
        showDeleteConfirmationDialog(
            [mod.modVariants.first.modFolder.absolute.path]);
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
              showDeleteConfirmationDialog(modVariantsSorted
                  .skip(1)
                  .map((v) => v.modFolder.absolute.path)
                  .toList());
            }),
      ],
    );
  }
}

MenuItem menuItemDebugging(
    BuildContext context, Mod mod, WidgetRef ref, bool isGameRunning) {
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
              label: (redownloadEnabled)
                  ? "Redownload & Reinstall"
                  : "Redownload unavailable",
              icon: redownloadEnabled ? Icons.downloading : null,
              onSelected: () {
                if (redownloadEnabled) {
                  ref.read(downloadManager.notifier).downloadAndInstallMod(
                      latestVersionWithDirectDownload.modInfo.nameOrId,
                      latestVersionWithDirectDownload
                          .versionCheckerInfo!.directDownloadURL!,
                      activateVariantOnComplete: false,
                      modInfo: latestVersionWithDirectDownload.modInfo);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        "This mod does not support direct download. Please manually redownload/reinstall."),
                  ));
                }
              }),
      ]);
}

MenuItem menuItemCheckVram(Mod mod, WidgetRef ref) {
  return MenuItem(
    label: 'Estimate VRAM Usage',
    icon: Icons.memory,
    onSelected: () {
      ref.read(AppState.vramEstimatorProvider.notifier).startEstimating(
          smolIdsToCheck: [mod.findFirstEnabledOrHighestVersion!.smolId]);
    },
  );
}
