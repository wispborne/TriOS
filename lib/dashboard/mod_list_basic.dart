import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:pasteboard/pasteboard.dart';
// import 'package:screenshot/screenshot.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/smol4.dart';
import 'package:trios/models/enabled_mods.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/disable_if_cannot_write_mods.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

import '../mod_manager/mod_context_menu.dart';
import '../mod_manager/version_checker.dart';
import '../models/mod.dart';
import '../trios/app_state.dart';
import '../trios/download_manager/download_manager.dart';
import '../utils/search.dart';
import '../widgets/add_new_mods_button.dart';
import '../widgets/refresh_mods_button.dart';
import 'mod_list_basic_entry.dart';

class ModListMini extends ConsumerStatefulWidget {
  const ModListMini({super.key});

  @override
  ConsumerState createState() => _ModListMiniState();
}

class _ModListMiniState extends ConsumerState<ModListMini>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final searchController = SearchController();

  // final screenshotController = ScreenshotController();
  bool hideDisabled = false;

  @override
  Widget build(BuildContext context) {
    final fullModList = ref.watch(AppState.mods);
    final enabledModIds = ref
        .watch(AppState.enabledModsFile)
        .valueOrNull
        ?.filterOutMissingMods(fullModList)
        .enabledMods;
    final modVariants = ref.watch(AppState.modVariants);
    final query = ref.watch(searchQuery);

    List<Mod> filteredModList = fullModList
        .let((mods) => hideDisabled
            ? mods
                .where((mod) => !hideDisabled || mod.hasEnabledVariant)
                .toList()
            : mods)
        .let((mods) => query.isEmpty ? mods : searchMods(mods, query) ?? [])
        .sortedByName;

    final versionCheck = ref.watch(AppState.versionCheckResults).valueOrNull;
    searchController.value = TextEditingValue(text: query);
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
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Mods",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontSize: 20)),
                            Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: Text(
                                  "${enabledModIds?.length ?? 0} of ${fullModList.length} enabled",
                                  style:
                                      Theme.of(context).textTheme.labelMedium),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const RefreshModsButton(
                                    iconOnly: true,
                                    isRefreshing: false,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                  MovingTooltipWidget.text(
                                    message:
                                        "Copy mod list to clipboard\n\nRight-click for ALL mods",
                                    child: GestureDetector(
                                      onSecondaryTap: () {
                                        copyModListToClipboardFromMods(
                                            fullModList, context);
                                      },
                                      child: IconButton(
                                        icon: const Icon(Icons.copy),
                                        iconSize: 20,
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        onPressed: () {
                                          copyModListToClipboardFromIds(
                                              enabledModIds,
                                              filteredModList,
                                              context);
                                        },
                                      ),
                                    ),
                                  ),
                                  const AddNewModsButton(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 4)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 8, bottom: 4, right: 4),
                      child: SizedBox(
                        height: 30,
                        child: ModListBasicSearch(query),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            child: CheckboxWithLabel(
                              value: hideDisabled,
                              onChanged: (newValue) {
                                setState(() {
                                  hideDisabled = newValue ?? false;
                                });
                              },
                              checkboxScale: 0.8,
                              textPadding: const EdgeInsets.all(0),
                              labelWidget: Text("Hide Disabled",
                                  style: theme.textTheme.labelMedium),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                            child: MovingTooltipWidget.text(
                              message:
                                  "When checked, updating an enabled mod switches to the new version.",
                              child: CheckboxWithLabel(
                                value: ref.watch(appSettings
                                        .select((s) => s.modUpdateBehavior)) ==
                                    ModUpdateBehavior
                                        .switchToNewVersionIfWasEnabled,
                                onChanged: (newValue) {
                                  setState(() {
                                    ref.read(appSettings.notifier).update((s) =>
                                        s.copyWith(
                                            modUpdateBehavior: newValue == true
                                                ? ModUpdateBehavior
                                                    .switchToNewVersionIfWasEnabled
                                                : ModUpdateBehavior
                                                    .doNotChange));
                                  });
                                },
                                checkboxScale: 0.8,
                                textPadding: const EdgeInsets.all(0),
                                labelWidget: Text("Swap on Update",
                                    style: theme.textTheme.labelMedium),
                              ),
                            ),
                          ),
                        ],
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
                    filteredModList
                        .map((e) => e as Mod?)
                        .filter((mod) {
                          return mod?.updateCheck(versionCheck)?.hasUpdate ==
                              true;
                          // final variant = mod?.findHighestVersion;
                          // if (variant?.versionCheckerInfo == null) return false;
                          //
                          // final localVersionCheck = variant!.versionCheckerInfo;
                          // final remoteVersionCheck =
                          //     versionCheck?[variant.smolId];
                          // return compareLocalAndRemoteVersions(
                          //             localVersionCheck, remoteVersionCheck) ==
                          //         -1 &&
                          //     remoteVersionCheck?.error == null;
                        })
                        .toList()
                        .sortedByName;
                final updatesToDisplay =
                    (isUpdatesFieldShown ? modsWithUpdates : <Mod?>[null]);
                final listItems = updatesToDisplay +
                    (modsWithUpdates.isEmpty ? [] : [null]) +
                    (filteredModList.sortedByName.toList());
                final isGameRunning =
                    ref.watch(AppState.isGameRunning).value ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                if (index == 0 &&
                                    modsWithUpdates.nonNulls.isNotEmpty) {
                                  return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Divider(),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: Row(
                                            children: [
                                              Text(
                                                  isUpdatesFieldShown
                                                      ? "UPDATES (${modsWithUpdates.nonNulls.length})"
                                                      : "${modsWithUpdates.nonNulls.length} hidden updates",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium),
                                              IconButton(
                                                onPressed: () => ref
                                                    .read(appSettings.notifier)
                                                    .update((s) => s.copyWith(
                                                        isUpdatesFieldShown: !s
                                                            .isUpdatesFieldShown)),
                                                constraints:
                                                    const BoxConstraints(),
                                                icon: Icon(
                                                    isUpdatesFieldShown
                                                        ? Icons.visibility
                                                        : Icons.visibility_off,
                                                    size: 15,
                                                    color: theme
                                                        .colorScheme.onSurface),
                                              ),
                                              const Spacer(),
                                              MovingTooltipWidget.text(
                                                  message: isGameRunning
                                                      ? "Game is running"
                                                      : "Download all ${modsWithUpdates.nonNulls.length} updates",
                                                  child: Disable(
                                                    isEnabled: !isGameRunning,
                                                    child: SizedBox(
                                                      child: TextButton.icon(
                                                          label: const Text(
                                                              "Update All"),
                                                          onPressed: () {
                                                            _onClickedDownloadModUpdatesDialog(
                                                                modsWithUpdates,
                                                                versionCheck,
                                                                context);
                                                          },
                                                          icon: Icon(
                                                              Icons.update,
                                                              size: 24,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary)),
                                                    ),
                                                  )),
                                            ],
                                          ),
                                        ),
                                      ]);
                                }
                                final mod = listItems[index];

                                // Hide the second "ALL MODS" title if there are no updates.
                                // Definitely a hack. Proper fix would be to change `listItems`
                                // to a container/viewmodel instead of mods.
                                if (updatesToDisplay.nonNulls.isEmpty &&
                                    mod == null &&
                                    index == 1) {
                                  return Container();
                                }

                                if (mod == null) {
                                  return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Divider(),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4.0),
                                          child: Row(
                                            children: [
                                              Text("ALL MODS",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium),
                                              // Screenshot doesn't work because it creates a child outside of
                                              // the provider scope (of riverpod), and can't render.
                                              // MovingTooltipWidget.text(
                                              //   message:
                                              //       "Copy screenshot to clipboard",
                                              //   child: IconButton(
                                              //     onPressed: () {
                                              //       screenshotController
                                              //           .captureFromLongWidget(
                                              //               InheritedTheme
                                              //                   .captureAll(
                                              //         context,
                                              //         Material(
                                              //           child: Column(
                                              //             children: filteredModList
                                              //                 .map((mod) =>
                                              //                     ModListBasicEntry(
                                              //                         mod: mod))
                                              //                 .toList(),
                                              //           ),
                                              //         ),
                                              //       ))
                                              //           .then((value) {
                                              //         Pasteboard.writeImage(
                                              //             value);
                                              //       });
                                              //     },
                                              //     constraints:
                                              //         const BoxConstraints(),
                                              //     icon: Icon(Icons.photo_camera,
                                              //         size: 15,
                                              //         color: theme.colorScheme
                                              //             .onSurface),
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ),
                                      ]);
                                }

                                return ContextMenuRegion(
                                  contextMenu:
                                      buildModContextMenu(mod, ref, context),
                                  child: ModListBasicEntry(
                                    mod: mod,
                                    isDisabled: isGameRunning,
                                  ),
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

  SearchAnchor ModListBasicSearch(String query) {
    return SearchAnchor(
      searchController: searchController,
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
            controller: controller,
            leading: const Icon(Icons.search),
            hintText: "Filter...",
            trailing: [
              query.isEmpty
                  ? Container()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        controller.clear();
                        ref.read(searchQuery.notifier).state = "";
                      },
                    )
            ],
            backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainer),
            onChanged: (value) {
              ref.read(searchQuery.notifier).state = value;
            });
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        return [];
      },
    );
  }

  void _onClickedDownloadModUpdatesDialog(List<Mod?> modsWithUpdates,
      VersionCheckerState? versionCheck, BuildContext context) {
    downloadUpdates() {
      for (var mod in modsWithUpdates) {
        if (mod == null) continue;
        final variant = mod.findHighestVersion!;
        final remoteVersionCheck =
            versionCheck?.versionCheckResultsBySmolId[variant.smolId];
        if (remoteVersionCheck?.remoteVersion != null) {
          ref.read(downloadManager.notifier).downloadUpdateViaBrowser(
                remoteVersionCheck!.remoteVersion!,
                activateVariantOnComplete: false,
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
