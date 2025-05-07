import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/version.dart';
import 'package:trios/thirdparty/dartx/comparable.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
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

final _searchQuery = StateProvider.autoDispose<String>((ref) => "");

class ModListMini extends ConsumerStatefulWidget {
  const ModListMini({super.key});

  @override
  ConsumerState createState() => _ModListMiniState();
}

class _ModListMiniState extends ConsumerState<ModListMini>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final _searchController = SearchController();

  bool hideDisabled = false;

  @override
  Widget build(BuildContext context) {
    final fullModList = ref.watch(AppState.mods);
    final enabledModIds =
        fullModList
            .where((it) => it.isEnabledInGame)
            .map((it) => it.id)
            .toSet();
    // ref
    //     .watch(AppState.enabledModsFile)
    //     .valueOrNull
    //     ?.filterOutMissingMods(fullModList)
    //     .enabledMods;

    final modVariants = ref.watch(AppState.modVariants);
    final query = ref.watch(_searchQuery);
    final versionCheck = ref.watch(AppState.versionCheckResults).valueOrNull;
    final theme = Theme.of(context);

    List<Mod> filteredModList =
        fullModList
            .let(
              (mods) =>
                  hideDisabled
                      ? mods
                          .where(
                            (mod) => !hideDisabled || mod.hasEnabledVariant,
                          )
                          .toList()
                      : mods,
            )
            .let((mods) => query.isEmpty ? mods : searchMods(mods, query) ?? [])
            .sortedByName;

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
                            Text(
                              "Mods",
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(fontSize: 20),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: Text(
                                "${enabledModIds?.length ?? 0} of ${fullModList.length} enabled",
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                  MovingTooltipWidget.text(
                                    message:
                                        "Copy mod list to clipboard\n\nRight-click for ALL mods",
                                    child: GestureDetector(
                                      onSecondaryTap: () {
                                        copyModListToClipboardFromMods(
                                          fullModList,
                                          context,
                                        );
                                      },
                                      child: IconButton(
                                        icon: const Icon(Icons.copy),
                                        iconSize: 20,
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        onPressed: () {
                                          copyModListToClipboardFromIds(
                                            enabledModIds,
                                            filteredModList,
                                            context,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const AddNewModsButton(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                        bottom: 4,
                        right: 4,
                      ),
                      child: SizedBox(
                        height: 30,
                        child: ModListBasicSearch(
                          searchController: _searchController,
                          query: query,
                        ),
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
                              labelWidget: Text(
                                "Hide Disabled",
                                style: theme.textTheme.labelMedium,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          if (Constants.currentVersion >=
                              Version.parse("1.2.0"))
                            MovingTooltipWidget.text(
                              message: "Sort By",
                              child: PopupMenuButton<String>(
                                icon: Icon(Icons.sort, size: 20),
                                tooltip: "",
                                itemBuilder:
                                    (context) => [
                                      PopupMenuItem(
                                        value: "name",
                                        onTap: () {
                                          // todo
                                          ref.watch(
                                            appSettings.select(
                                              (s) => s.dashboardModListSort,
                                            ),
                                          );
                                        },
                                        child: Text("Sort by Name (todo)"),
                                      ),
                                    ],
                              ),
                            ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.settings, size: 20),
                            tooltip: "",
                            itemBuilder:
                                (context) => [
                                  PopupMenuItem(
                                    child: SizedBox(
                                      height: 20,
                                      child: MovingTooltipWidget.text(
                                        message:
                                            "When checked, updating an enabled mod switches to the new version.",
                                        child: CheckboxWithLabel(
                                          value:
                                              ref.watch(
                                                appSettings.select(
                                                  (s) => s.modUpdateBehavior,
                                                ),
                                              ) ==
                                              ModUpdateBehavior
                                                  .switchToNewVersionIfWasEnabled,
                                          onChanged: (newValue) {
                                            setState(() {
                                              ref
                                                  .read(appSettings.notifier)
                                                  .update(
                                                    (s) => s.copyWith(
                                                      modUpdateBehavior:
                                                          newValue == true
                                                              ? ModUpdateBehavior
                                                                  .switchToNewVersionIfWasEnabled
                                                              : ModUpdateBehavior
                                                                  .doNotChange,
                                                    ),
                                                  );
                                            });
                                          },
                                          checkboxScale: 0.8,
                                          textPadding: const EdgeInsets.all(0),
                                          labelWidget: Text(
                                            "Swap on Update",
                                            style: theme.textTheme.labelMedium,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                final dashboardGridModUpdateVisibility = ref.watch(
                  appSettings.select((s) => s.dashboardGridModUpdateVisibility),
                );
                final isUpdatesFieldShown =
                    dashboardGridModUpdateVisibility !=
                    DashboardGridModUpdateVisibility.hideAll;
                final modsMetadata =
                    ref.watch(AppState.modsMetadata).valueOrNull;
                final modsWithUpdates =
                    <Mod?>[null] +
                    filteredModList
                        .map((e) => e as Mod?)
                        .where((mod) {
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
                final mutedModsWithUpdates =
                    modsMetadata == null
                        ? <Mod?>[]
                        : modsWithUpdates
                            .where(
                              (mod) =>
                                  mod != null &&
                                  modsMetadata
                                          .getMergedModMetadata(mod.id)
                                          ?.areUpdatesMuted ==
                                      true,
                            )
                            .toList();

                final updatesToDisplay =
                    switch (dashboardGridModUpdateVisibility) {
                      DashboardGridModUpdateVisibility.allVisible =>
                        modsWithUpdates,
                      DashboardGridModUpdateVisibility.hideMuted =>
                        modsWithUpdates - mutedModsWithUpdates,
                      DashboardGridModUpdateVisibility.hideAll => <Mod?>[null],
                    };
                final listItems =
                    updatesToDisplay +
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
                            controller: _scrollController,
                            itemCount: listItems.length, // UPDATES title
                            itemBuilder: (context, index) {
                              if (index == 0 &&
                                  modsWithUpdates.nonNulls.isNotEmpty) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Row(
                                        children: [
                                          UpdatesHeader(
                                            dashboardGridModUpdateVisibility:
                                                dashboardGridModUpdateVisibility,
                                            updatesToDisplay: updatesToDisplay,
                                            mutedModsWithUpdates:
                                                mutedModsWithUpdates,
                                            modsWithUpdates: modsWithUpdates,
                                          ),
                                          ChangeUpdateVisibilityEyeView(
                                            dashboardGridModUpdateVisibility:
                                                dashboardGridModUpdateVisibility,
                                            theme: theme,
                                          ),
                                          const Spacer(),
                                          MovingTooltipWidget.text(
                                            message:
                                                isGameRunning
                                                    ? "Game is running"
                                                    : "Download all ${modsWithUpdates.nonNulls.length} updates",
                                            child: Disable(
                                              isEnabled: !isGameRunning,
                                              child: SizedBox(
                                                child: TextButton.icon(
                                                  label: const Text(
                                                    "Update All",
                                                  ),
                                                  onPressed: () {
                                                    _onClickedDownloadModUpdatesDialog(
                                                      modsWithUpdates,
                                                      versionCheck,
                                                      context,
                                                    );
                                                  },
                                                  icon: Icon(
                                                    Icons.update,
                                                    size: 24,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 4.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            "ALL MODS",
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.labelMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return ContextMenuRegion(
                                contextMenu: buildModContextMenu(
                                  mod,
                                  ref,
                                  context,
                                ),
                                child: ModListBasicEntry(
                                  mod: mod,
                                  isDisabled: isGameRunning,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading:
                  () => const Center(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error: (error, stackTrace) => Text('Error: $error'),
            ),
          ),
        ].animate(interval: 400.ms).fade(duration: 300.ms),
      ),
    );
  }

  void _onClickedDownloadModUpdatesDialog(
    List<Mod?> modsWithUpdates,
    VersionCheckerState? versionCheck,
    BuildContext context,
  ) {
    downloadUpdates() {
      for (var mod in modsWithUpdates) {
        if (mod == null) continue;
        final variant = mod.findHighestVersion!;
        final remoteVersionCheck =
            versionCheck?.versionCheckResultsBySmolId[variant.smolId];
        if (remoteVersionCheck?.remoteVersion != null) {
          ref
              .read(downloadManager.notifier)
              .downloadUpdateViaBrowser(
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
              "Download updates for ${modsWithUpdates.whereType<Mod>().length} mods?",
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
                  downloadUpdates();
                },
                child: const Text("Download"),
              ),
            ],
          );
        },
      );
    }
  }
}

class ModListBasicSearch extends ConsumerWidget {
  const ModListBasicSearch({
    super.key,
    required this.searchController,
    required this.query,
  });

  final SearchController searchController;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    ref.read(_searchQuery.notifier).state = "";
                  },
                ),
          ],
          backgroundColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainer,
          ),
          onChanged: (value) {
            ref.read(_searchQuery.notifier).state = value;
          },
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        return [];
      },
    );
  }
}

class ChangeUpdateVisibilityEyeView extends ConsumerWidget {
  const ChangeUpdateVisibilityEyeView({
    super.key,
    required this.dashboardGridModUpdateVisibility,
    required this.theme,
  });

  final DashboardGridModUpdateVisibility dashboardGridModUpdateVisibility;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed:
          () => ref
              .read(appSettings.notifier)
              .update(
                (s) => s.copyWith(
                  dashboardGridModUpdateVisibility: switch (s
                      .dashboardGridModUpdateVisibility) {
                    DashboardGridModUpdateVisibility.allVisible =>
                      DashboardGridModUpdateVisibility.hideMuted,
                    DashboardGridModUpdateVisibility.hideMuted =>
                      DashboardGridModUpdateVisibility.hideAll,
                    DashboardGridModUpdateVisibility.hideAll =>
                      DashboardGridModUpdateVisibility.allVisible,
                  },
                ),
              ),
      constraints: const BoxConstraints(),
      icon: MovingTooltipWidget.text(
        message: switch (dashboardGridModUpdateVisibility) {
          DashboardGridModUpdateVisibility.allVisible => "Showing all updates",
          DashboardGridModUpdateVisibility.hideMuted =>
            "Showing unmuted updates",
          DashboardGridModUpdateVisibility.hideAll => "Updates hidden",
        },
        child: Icon(
          switch (dashboardGridModUpdateVisibility) {
            DashboardGridModUpdateVisibility.allVisible =>
              Icons.visibility_outlined,
            DashboardGridModUpdateVisibility.hideMuted => Icons.visibility,
            DashboardGridModUpdateVisibility.hideAll => Icons.visibility_off,
          },
          size: 15,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class UpdatesHeader extends ConsumerWidget {
  const UpdatesHeader({
    super.key,
    required this.dashboardGridModUpdateVisibility,
    required this.updatesToDisplay,
    required this.mutedModsWithUpdates,
    required this.modsWithUpdates,
  });

  final DashboardGridModUpdateVisibility dashboardGridModUpdateVisibility;
  final List<Mod?> updatesToDisplay;
  final List<Mod?> mutedModsWithUpdates;
  final List<Mod?> modsWithUpdates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (dashboardGridModUpdateVisibility) {
      DashboardGridModUpdateVisibility.allVisible => Text(
        "ALL UPDATES (${updatesToDisplay.nonNulls.length})",
        style: Theme.of(context).textTheme.labelMedium,
      ),
      DashboardGridModUpdateVisibility.hideMuted => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "UPDATES (${updatesToDisplay.nonNulls.length}",
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (mutedModsWithUpdates.isNotEmpty) ...[
            Text(
              " + ${mutedModsWithUpdates.nonNulls.length} ",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            MovingTooltipWidget.text(
              message: "Muted updates",
              child: Icon(
                Icons.notifications_off,
                size: 14,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ],
          Text(")", style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
      DashboardGridModUpdateVisibility.hideAll => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${(modsWithUpdates - mutedModsWithUpdates).nonNulls.length} hidden updates",
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (mutedModsWithUpdates.isNotEmpty) ...[
            Text(
              " (+ ${mutedModsWithUpdates.nonNulls.length} ",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            MovingTooltipWidget.text(
              message: "Muted updates",
              child: Icon(
                Icons.notifications_off,
                size: 14,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            Text(")", style: Theme.of(context).textTheme.labelMedium),
          ],
        ],
      ),
    };
  }
}
