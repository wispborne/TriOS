import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mod.dart';
import '../trios/app_state.dart';
import '../widgets/debug_info.dart';

ContextMenu buildModContextMenu(Mod mod, WidgetRef ref, BuildContext context) {
  final currentStarsectorVersion =
      ref.read(appSettings.select((s) => s.lastStarsectorVersion));
  final modVariant = mod.findFirstEnabledOrHighestVersion!;

  return ContextMenu(
    entries: <ContextMenuEntry>[
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
      menuItemDeleteFolder(mod, context, ref),
      if (currentStarsectorVersion != null &&
          Version.parse(modVariant.modInfo.gameVersion ?? "0.0.0",
                  sanitizeInput: true) !=
              Version.parse(currentStarsectorVersion, sanitizeInput: true))
        MenuItem(
            label: 'Force to $currentStarsectorVersion',
            icon: Icons.electric_bolt,
            onSelected: () {
              forceChangeModGameVersion(modVariant, currentStarsectorVersion);
              ref.invalidate(AppState.modVariants);
            }),
      MenuItem(
          label: "Show Raw Info",
          icon: Icons.info,
          onSelected: () {
            showDebugViewDialog(context, mod);
          }),
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
          for (var variant in mod.modVariants.sortedModVariants)
            MenuItem(
                label: variant.modInfo.version.toString(),
                onSelected: () {
                  launchUrl(
                      Uri.parse("file:${variant.modFolder.absolute.path}"));
                }),
        ]);
  }
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
  final theme = Theme.of(context);
  Future<void> deleteFolder(String folderPath) async {
    final directory = Directory(folderPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    ref.read(AppState.modVariants.notifier).reloadModVariants();
  }

  Future<void> showDeleteConfirmationDialog(String folderPath) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Mod'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  "Are you sure you want to delete '${folderPath.toDirectory().name}'?\nThis action cannot be undone."),
            ],
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
      await deleteFolder(folderPath);
    }
  }

  if (mod.modVariants.length == 1) {
    return MenuItem(
      label: 'Delete Folder',
      icon: Icons.delete,
      onSelected: () {
        showDeleteConfirmationDialog(
            mod.modVariants.first.modFolder.absolute.path);
      },
    );
  } else {
    return MenuItem.submenu(
      label: "Delete Folder...",
      icon: Icons.delete,
      items: [
        for (var variant in mod.modVariants.sortedModVariants)
          MenuItem(
            label: variant.modInfo.version.toString(),
            onSelected: () {
              showDeleteConfirmationDialog(variant.modFolder.absolute.path);
            },
          ),
      ],
    );
  }
}
