import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/version.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/conditional_wrap.dart';
import 'package:trios/widgets/disable_if_cannot_write_mods.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

import '../mod_manager/version_checker.dart';
import '../models/mod.dart';
import '../trios/app_state.dart';
import '../trios/download_manager/download_manager.dart';
import '../widgets/add_new_mods_button.dart';
import '../widgets/debug_info.dart';
import 'mod_list_basic_entry.dart';

class ModListMini extends ConsumerStatefulWidget {
  const ModListMini({super.key});

  @override
  ConsumerState createState() => _ModListMiniState();

  static ContextMenu buildContextMenu(
      Mod mod, WidgetRef ref, BuildContext context) {
    final currentStarsectorVersion =
        ref.read(appSettings.select((s) => s.lastStarsectorVersion));
    final modVariant = mod.findFirstEnabledOrHighestVersion!;

    return ContextMenu(
      entries: <ContextMenuEntry>[
        MenuItem(
            label: 'Open Folder',
            icon: Icons.folder,
            onSelected: () {
              launchUrl(
                  Uri.parse("file:${modVariant.modsFolder.absolute.path}"));
            }),
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
}

class _ModListMiniState extends ConsumerState<ModListMini>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final enabledModIds = ref.watch(AppState.enabledModIds).valueOrNull;
    final modListAsync = ref.watch(AppState.mods);
    final modVariants = ref.watch(AppState.modVariants);
    final modList = modListAsync;
    final versionCheck = ref.watch(AppState.versionCheckResults).valueOrNull;
    final isRefreshing = (modVariants.isLoading ||
        ref.watch(AppState.versionCheckResults).isLoading);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Text("Mods",
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 20)),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                                message: "Refresh mods and recheck versions",
                                child: IconButton(
                                  icon: ConditionalWrap(
                                      condition: isRefreshing,
                                      wrapper: (child) => Animate(
                                          onComplete: (c) => c.repeat(),
                                          effects: [
                                            RotateEffect(duration: 2000.ms)
                                          ],
                                          child: child),
                                      child: const Icon(Icons.refresh)),
                                  padding: const EdgeInsets.only(right: 8.0),
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    AppState.skipCacheOnNextVersionCheck = true;
                                    ref.invalidate(AppState.modVariants);
                                  },
                                )),
                            Tooltip(
                              message: "Copy mod info",
                              child: IconButton(
                                icon: const Icon(Icons.copy),
                                padding: EdgeInsets.zero,
                                iconSize: 20,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text:
                                          "Mods (${modList.length})\n${modList.map((mod) {
                                    final variant =
                                        mod.findFirstEnabledOrHighestVersion;
                                    return false
                                        ? "${mod.id} ${variant?.modInfo.version}"
                                        : "${variant?.modInfo.name}  v${variant?.modInfo.version}  [${mod.id}]";
                                  }).join('\n')}"));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content:
                                        Text("Copied mod info to clipboard."),
                                  ));
                                },
                              ),
                            ),
                            const AddNewModsButton()
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: modVariants.when(
              data: (_) {
                final isUpdatesFieldShown =
                    ref.watch(appSettings.select((s) => s.isUpdatesFieldShown));
                var modsWithUpdates = <Mod?>[null] +
                    modList
                        .map((e) => e as Mod?)
                        .filter((mod) {
                          final variant = mod?.findHighestVersion;
                          if (variant?.versionCheckerInfo == null) return false;

                          final localVersionCheck = variant!.versionCheckerInfo;
                          final remoteVersionCheck =
                              versionCheck?[variant.smolId];
                          return compareLocalAndRemoteVersions(
                                      localVersionCheck, remoteVersionCheck) ==
                                  -1 &&
                              remoteVersionCheck?.error == null;
                        })
                        .sortedBy((info) =>
                            info?.findFirstEnabledOrHighestVersion?.modInfo
                                .name ??
                            "")
                        .toList();
                final updatesToDisplay =
                    (isUpdatesFieldShown ? modsWithUpdates : <Mod?>[null]);
                final listItems = updatesToDisplay +
                    (modsWithUpdates.isEmpty ? [] : [null]) + // Divider
                    (modList
                        // .filter((mod) => mod.versionCheckerInfo == null)
                        .sortedBy((info) =>
                            info.findFirstEnabledOrHighestVersion?.modInfo
                                .name ??
                            "")
                        .toList());

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "${enabledModIds?.length ?? 0} of ${modList.length} enabled",
                        style: Theme.of(context).textTheme.labelMedium),
                    Expanded(
                      child: VsScrollbar(
                        controller: _scrollController,
                        isAlwaysShown: true,
                        showTrackOnHover: true,
                        child: DisableIfCannotWriteMods(
                          child: ListView.builder(
                              shrinkWrap: true,
                              controller: _scrollController,
                              itemCount: listItems.length, // UPDATES title
                              itemBuilder: (context, index) {
                                if (index == 0 && modsWithUpdates.isNotEmpty) {
                                  return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Divider(),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 0, right: 8),
                                          child: Row(
                                            children: [
                                              Text(
                                                  "UPDATES (${modsWithUpdates.whereNotNull().length}${isUpdatesFieldShown ? "" : " hidden"})",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium),
                                              IconButton(
                                                onPressed: () => ref
                                                    .read(appSettings.notifier)
                                                    .update((s) => s.copyWith(
                                                        isUpdatesFieldShown: !s
                                                            .isUpdatesFieldShown)),
                                                icon: Icon(
                                                    isUpdatesFieldShown
                                                        ? Icons.visibility
                                                        : Icons.visibility_off,
                                                    size: 15,
                                                    color: theme
                                                        .colorScheme.onSurface),
                                              ),
                                              const Spacer(),
                                              Tooltip(
                                                  message:
                                                      "Download all ${modsWithUpdates.whereNotNull().length} updates",
                                                  child: IconButton(
                                                      onPressed: () {
                                                        _onClickedDownloadModUpdatesDialog(
                                                            modsWithUpdates,
                                                            versionCheck,
                                                            context);
                                                      },
                                                      icon: Icon(Icons.update,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary))),
                                            ],
                                          ),
                                        ),
                                      ]);
                                }
                                final mod = listItems[index];
                                if (mod == null) {
                                  return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Divider(),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4.0),
                                          child: Text("ALL MODS",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium),
                                        ),
                                      ]);
                                }

                                return ContextMenuRegion(
                                  contextMenu: ModListMini.buildContextMenu(
                                      mod, ref, context),
                                  child: ModListBasicEntry(
                                      mod: mod,
                                      isEnabled:
                                          enabledModIds?.contains(mod.id) ??
                                              false),
                                );
                              }),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                  child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator())),
              error: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        ].animate(interval: 400.ms).fade(duration: 300.ms),
      ),
    );
  }

  void _onClickedDownloadModUpdatesDialog(List<Mod?> modsWithUpdates,
      Map<String, VersionCheckResult>? versionCheck, BuildContext context) {
    downloadUpdates() {
      for (var mod in modsWithUpdates) {
        if (mod == null) continue;
        final variant = mod.findHighestVersion!;
        final remoteVersionCheck = versionCheck?[variant.smolId];
        if (remoteVersionCheck?.remoteVersion != null) {
          downloadUpdateViaBrowser(
            remoteVersionCheck!.remoteVersion!,
            ref,
            context,
            activateVariantOnComplete: true,
            modInfo: variant.modInfo,
          );
        }
      }
    }

    // Confirm if # updates is more than 5
    if (modsWithUpdates.length <= 5) {
      downloadUpdates();
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Are you sure?"),
              content: Text(
                  "Download updates for ${modsWithUpdates.whereType<Mod>().length} mods?"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      downloadUpdates();
                    },
                    child: const Text("Download")),
              ],
            );
          });
    }
  }
}
