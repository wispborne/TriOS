import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_records/mod_record_sources_dialog.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/navigation_request.dart';
import 'package:trios/utils/dialogs.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/debug_info.dart';
import 'package:trios/widgets/force_game_version_warning_dialog.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:url_launcher/url_launcher.dart';

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
        builder: (context) =>
            ForceGameVersionWarningDialog(modVariant: modVariant),
      );
    },
  );
}

MenuItem<dynamic> buildMenuItemOpenForumPage(
  ModVariant modVariant,
  BuildContext context,
) {
  final hasThread = modVariant.versionCheckerInfo?.modThreadId != null;
  final hasNexusPage = modVariant.versionCheckerInfo?.modNexusId != null;
  final hasPage = hasThread || hasNexusPage;
  return MenuItem(
    label: hasThread
        ? 'Open Forum Page'
        : hasNexusPage
        ? 'Open Nexus Page'
        : 'Open Forum Page (unavailable)',
    icon: Icons.open_in_browser,
    iconOpacity: hasPage ? 1 : 0.5,
    onSelected: () {
      if (hasThread) {
        launchUrl(
          Uri.parse(
            "${Constants.forumModPageUrl}${modVariant.versionCheckerInfo?.modThreadId}",
          ),
        );
      } else if (hasNexusPage) {
        launchUrl(
          Uri.parse(
            "${Constants.nexusModsPageUrl}${modVariant.versionCheckerInfo?.modNexusId}",
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Mod has not set up Version Checker, or it does not contain a forum thread id.",
            ),
          ),
        );
      }
    },
  );
}

MenuItem buildMenuItemOpenFolder(Mod mod) {
  if (mod.modVariants.length == 1) {
    return buildOpenSingleFolderMenuItem(
      mod.modVariants.first.modFolder.absolute,
    );
  } else {
    return MenuItem.submenu(
      label: "Open Folder...",
      icon: Icons.folder,
      onSelected: () {
        mod.findFirstEnabledOrHighestVersion?.modFolder.absolute.path
            .openAsUriInBrowser();
      },
      items: [
        for (var variant in mod.modVariants.sortedDescending())
          buildOpenSingleFolderMenuItem(
            variant.modFolder.absolute,
            label: variant.modInfo.version.toString(),
          ),
      ],
    );
  }
}

MenuItem<dynamic> buildOpenSingleFolderMenuItem(
  Directory folder, {
  Directory? secondFolder,
  String label = 'Open Folder',
}) {
  return MenuItem(
    label: label,
    icon: Icons.folder,
    onSelected: () {
      folder.path.openAsUriInBrowser();

      if (secondFolder != null && secondFolder.path != folder.path) {
        secondFolder.path.openAsUriInBrowser();
      }
    },
  );
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
          icon: variant.smolId == enabledSmolId
              ? Icons.power_settings_new
              : null,
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
  if (mod.modVariants.length == 1) {
    return MenuItem(
      label: 'Delete Mod...',
      icon: Icons.delete,
      onSelected: () {
        showDeleteModFoldersConfirmationDialog(
          [mod.modVariants.first],
          context,
          ref,
        );
      },
    );
  } else {
    final modVariantsSorted = mod.modVariants.sortedDescending();
    return MenuItem.submenu(
      label: "Delete Mod...",
      icon: Icons.delete,
      items: [
        for (var variant in modVariantsSorted)
          MenuItem(
            label: variant.modInfo.version.toString(),
            onSelected: () {
              showDeleteModFoldersConfirmationDialog([variant], context, ref);
            },
          ),
        MenuItem(
          label: "All but ${modVariantsSorted.firstOrNull?.modInfo.version}",
          onSelected: () {
            showDeleteModFoldersConfirmationDialog(
              modVariantsSorted.skip(1).map((v) => v).toList(),
              context,
              ref,
            );
          },
        ),
        MenuItem(
          label: "All versions",
          onSelected: () {
            showDeleteModFoldersConfirmationDialog(
              modVariantsSorted.map((v) => v).toList(),
              context,
              ref,
            );
          },
        ),
      ],
    );
  }
}

MenuItem menuItemDeleteMultipleMods(
  List<Mod> mods,
  BuildContext context,
  WidgetRef ref,
) {
  if (mods.length == 1) {
    return menuItemDeleteFolder(mods.first, context, ref);
  }

  return MenuItem.submenu(
    label: "Delete Mods...",
    icon: Icons.delete,
    items: [
      MenuItem(
        label: "All but enabled/highest version of each",
        onSelected: () {
          showDeleteModFoldersConfirmationDialog(
            mods
                .flatMap(
                  (mod) =>
                      mod.modVariants
                          .toList() // Copy the list to avoid modifying the original
                        ..remove(mod.findFirstEnabledOrHighestVersion!),
                )
                .map((v) => v)
                .toList(),
            context,
            ref,
          );
        },
      ),
      MenuItem(
        label: "All selected mods",
        onSelected: () {
          showDeleteModFoldersConfirmationDialog(
            mods.flatMap((mod) => mod.modVariants).map((v) => v).toList(),
            context,
            ref,
          );
        },
      ),
    ],
  );
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
      MenuItem(
        label: "Mod Sources",
        icon: Icons.source,
        onSelected: () => showModRecordSourcesDialog(
          context,
          mod.id,
          mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ?? mod.id,
        ),
      ),
      if (!isGameRunning)
        MenuItem(
          label: (redownloadEnabled)
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

MenuItem buildMenuItemOpenInSidebar(
  Mod mod,
  WidgetRef ref,
  Function(Mod? mod) openSidebar,
) {
  return MenuItem(
    label: 'Open in side panel',
    icon: Icons.view_sidebar,
    onSelected: () {
      openSidebar(mod);
    },
  );
}

MenuItem buildMenuItemToggleMuteUpdates(Mod mod, WidgetRef ref) {
  final modsMetadata = ref.watch(AppState.modsMetadata).value;
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

MenuItem buildMenuItemViewInViewer(Mod mod, WidgetRef ref) {
  final modName =
      mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ?? mod.id;

  void navigate(TriOSTools tool) {
    ref.read(AppState.viewerFilterRequest.notifier).state = ViewerFilterRequest(
      destination: tool,
      modName: modName,
    );
    ref.read(AppState.navigationRequest.notifier).state = NavigationRequest(
      destination: tool,
    );
  }

  return MenuItem.submenu(
    label: 'View...',
    icon: Icons.search,
    items: [
      MenuItem(
        label: 'Ships',
        leading: SvgImageIcon("assets/images/icon-onslaught.svg"),
        onSelected: () => navigate(TriOSTools.ships),
      ),
      MenuItem(
        label: 'Weapons',
        leading: SvgImageIcon("assets/images/icon-target.svg"),
        onSelected: () => navigate(TriOSTools.weapons),
      ),
      MenuItem(
        label: 'Hullmods',
        leading: SvgImageIcon("assets/images/icon-hullmod.svg"),
        onSelected: () => navigate(TriOSTools.hullmods),
      ),
      MenuItem(
        label: 'Portraits',
        leading: SvgImageIcon("assets/images/icon-account-box-outline.svg"),
        onSelected: () => navigate(TriOSTools.portraits),
      ),
    ],
  );
}
