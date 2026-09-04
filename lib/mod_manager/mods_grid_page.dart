import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:trios/catalog/download_confirm.dart';
import 'package:trios/catalog/catalog_manager.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/mod_manager/homebrew_grid/mod_grid_columns.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/mod_context_menu.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/mod_summary_panel.dart';
import 'package:trios/mod_manager/widgets/category_management_popup.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/mod_tag_manager/category_manager.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/trios/download_manager/download_target.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/add_new_mods_button.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/export_to_csv_dialog.dart';
import 'package:trios/widgets/mod_download/mod_download_button.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/palette_generator_mixin.dart';
import 'package:trios/widgets/popup_style_menu_anchor.dart';
import 'package:trios/widgets/refresh_mods_button.dart';
import 'package:trios/widgets/smart_search/smart_search_bar.dart';
import 'package:trios/widgets/snackbar.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/text_with_icon.dart';
import 'package:trios/widgets/trios_dropdown_button.dart';
import 'package:url_launcher/url_launcher.dart';

import '../mod_profiles/mod_profiles_manager.dart';
import '../mod_profiles/models/mod_profile.dart';
import 'homebrew_grid/wispgrid_group.dart';
import 'mods_grid_page_controller.dart';

final vramColumnHovered = StateProvider.autoDispose<bool>((ref) => false);

class ModsGridPage extends ConsumerStatefulWidget {
  const ModsGridPage({super.key});

  @override
  ConsumerState createState() => _ModsGridState();
}

class _ModsGridState extends ConsumerState<ModsGridPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;
  Mod? selectedMod;
  AnimationController? animationController;
  List<Mod> filteredMods = [];
  WispGridController<Mod>? controller;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final allMods = ref.watch(AppState.mods);
    final isGameRunning = ref.watch(AppState.isGameRunning).value == true;
    final theme = Theme.of(context);
    final gridState = ref.watch(appSettings.select((s) => s.modsGridState));
    // Watch category state so the grid rebuilds immediately on category changes
    // (e.g. drag-and-drop between category groups, context menu reassignment).
    ref.watch(categoryManagerProvider);

    final searchState = ref.watch(modsGridSearchControllerProvider);
    final modsMatchingSearch = searchState.filteredMods;
    final modsMetadata = ref.watch(AppState.modsMetadata).value;
    // Read once here, not inside the sort comparator below. A comparator runs
    // n*log(n) times per sort, and every ref.watch re-subscribes to the provider.
    final pinFavorites = ref.watch(appSettings.select((s) => s.pinFavorites));
    final versionCheck = ref.watch(AppState.versionCheckResults).value;
    final modsGridUpdateVisibility = ref.watch(
      appSettings.select((s) => s.modsGridUpdateVisibility),
    );
    final modsGridUpdatesShowDisabledMods = ref.watch(
      appSettings.select((s) => s.modsGridUpdatesShowDisabledMods),
    );
    final modsWithUpdates = modsMatchingSearch
        .where((mod) => mod.updateCheck(versionCheck)?.hasUpdate == true)
        .where(
          (mod) => modsGridUpdatesShowDisabledMods || mod.hasEnabledVariant,
        )
        .toList();
    final mutedUpdates = modsWithUpdates.where((mod) {
      final metadata = modsMetadata?.getMergedModMetadata(mod.id);
      return metadata != null &&
          metadata.isUpdateHidden(
            mod.updateCheck(versionCheck)?.remoteVersionString,
          );
    }).toList();
    final pinnedUpdateMods = switch (modsGridUpdateVisibility) {
      ModsGridUpdateVisibility.showAll => modsWithUpdates,
      ModsGridUpdateVisibility.showUnmuted =>
        modsWithUpdates.where((mod) => !mutedUpdates.contains(mod)).toList(),
      ModsGridUpdateVisibility.hide => <Mod>[],
    };
    final vramEstState = ref.watch(AppState.vramEstimatorProvider);
    final loadOrderNumberLookupByModId = allMods
        .where((mod) => mod.hasEnabledVariant)
        .sortedByButBetter((mod) => mod.getSortValueForLoadOrder())
        .let((list) {
          final lookupMap = <String, int>{};
          for (int i = 0; i < list.length; i++) {
            lookupMap[list[i].id] = i + 1; // Don't use 0-based index for UI
          }
          return lookupMap;
        });

    return Stack(
      children: [
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4, right: 4),
                    child: SizedBox(
                      height: 50,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 2, right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const SizedBox(width: 4),
                              const AddNewModsButton(
                                labelWidget: Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Text("Add Mod(s)"),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(width: 8),
                              RefreshModsButton(
                                iconOnly: true,
                                outlined: false,
                                isDense: true,
                                isRefreshing: isChangingModProfileProvider,
                              ),
                              const SizedBox(width: 8),
                              buildProfileSelector(isGameRunning),
                              Padding(
                                padding: const .symmetric(vertical: 8),
                                child: VerticalDivider(
                                  color: theme.dividerColor.withAlpha(150),
                                ),
                              ),
                              buildGroupBySelector(gridState),
                              const SizedBox(width: 8),
                              buildThenBySelector(gridState),
                              const SizedBox(width: 8),
                              // Removing Est. VRAM button because it's on the mod groups now.
                              // Maybe should add it to an overflow menu, though.
                              if (false) buildEstimateVramButton(theme),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 300,
                                      maxHeight: 30,
                                    ),
                                    child: SmartSearchBar(
                                      fields: ref
                                          .watch(
                                            modsGridSearchControllerProvider
                                                .notifier,
                                          )
                                          .searchFieldsMeta,
                                      recentHistory: ref.watch(
                                        appSettings.select(
                                          (s) => s.modsSearchHistory,
                                        ),
                                      ),
                                      initialValue:
                                          searchState.currentSearchQuery,
                                      onChanged: (query) => ref
                                          .read(
                                            modsGridSearchControllerProvider
                                                .notifier,
                                          )
                                          .updateSearchQuery(query),
                                      onSubmitted: () => ref
                                          .read(
                                            modsGridSearchControllerProvider
                                                .notifier,
                                          )
                                          .submitSearchQuery(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              MovingTooltipWidget.text(
                                message: "Open side panel",
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedMod = modsMatchingSearch.isEmpty
                                          ? null
                                          : modsMatchingSearch.firstOrNull;
                                    });
                                  },
                                  icon: Icon(Icons.view_sidebar),
                                ),
                              ),
                              const SizedBox(width: 8),
                              buildOverflowButton(allMods),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: WispGrid<Mod>(
                  gridState: gridState,
                  updateGridState: (updateFunction) {
                    ref.read(appSettings.notifier).update((state) {
                      final newState = updateFunction(state.modsGridState);
                      return state.copyWith(
                        modsGridState: newState ?? Settings().modsGridState,
                      );
                    });
                  },
                  onLoaded: (controller) {
                    setState(() {
                      this.controller = controller;
                    });
                  },
                  items: modsMatchingSearch,
                  onRowSelected: (mod) {
                    setState(() {
                      if (selectedMod == mod) {
                        // Don't close mod panel if open, that's annoying.
                        // It made since when single-click toggled it.
                        // selectedMod = null;
                      } else {
                        selectedMod = mod;
                      }
                    });
                  },
                  perColumnContextMenuEntries: {
                    ModGridHeader.categories.name: [
                      MenuItem(
                        label: 'Manage Categories...',
                        icon: Icons.settings,
                        onSelected: () {
                          showCategoryManagementPopup(
                            context: context,
                            ref: ref,
                          );
                        },
                      ),
                    ],
                  },
                  pinnedItems: pinnedUpdateMods,
                  pinnedGroupInfo: PinnedGroupInfo(
                    name: "Updates Available",
                    icon: SvgCategoryIcon(
                      "assets/images/icon-update-badge.svg",
                    ),
                  ),
                  pinnedGroupContextMenuEntries: [
                    MenuItem.submenu(
                      label: 'Updates Visibility',
                      leading: Center(
                        child: SvgImageIcon(
                          "assets/images/icon-update-badge.svg",
                          height: 16,
                          width: 16,
                          color: theme.iconTheme.color,
                        ),
                      ),
                      items: [
                        MenuItem(
                          label: 'Show unmuted updates',
                          icon:
                              modsGridUpdateVisibility ==
                                  ModsGridUpdateVisibility.showUnmuted
                              ? Icons.check
                              : null,
                          onSelected: () {
                            ref
                                .read(appSettings.notifier)
                                .update(
                                  (s) => s.copyWith(
                                    modsGridUpdateVisibility:
                                        ModsGridUpdateVisibility.showUnmuted,
                                  ),
                                );
                          },
                        ),
                        MenuItem(
                          label: 'Show all updates',
                          icon:
                              modsGridUpdateVisibility ==
                                  ModsGridUpdateVisibility.showAll
                              ? Icons.check
                              : null,
                          onSelected: () {
                            ref
                                .read(appSettings.notifier)
                                .update(
                                  (s) => s.copyWith(
                                    modsGridUpdateVisibility:
                                        ModsGridUpdateVisibility.showAll,
                                  ),
                                );
                          },
                        ),
                        MenuItem(
                          label: "Don't show updates",
                          icon:
                              modsGridUpdateVisibility ==
                                  ModsGridUpdateVisibility.hide
                              ? Icons.check
                              : null,
                          onSelected: () {
                            ref
                                .read(appSettings.notifier)
                                .update(
                                  (s) => s.copyWith(
                                    modsGridUpdateVisibility:
                                        ModsGridUpdateVisibility.hide,
                                  ),
                                );
                          },
                        ),
                      ],
                    ),
                    MenuItem(
                      label: 'Only show enabled mods',
                      icon: modsGridUpdatesShowDisabledMods
                          ? null
                          : Icons.check,
                      onSelected: () {
                        ref
                            .read(appSettings.notifier)
                            .update(
                              (s) => s.copyWith(
                                modsGridUpdatesShowDisabledMods:
                                    !s.modsGridUpdatesShowDisabledMods,
                              ),
                            );
                      },
                    ),
                    MenuDivider(),
                  ],
                  scrollbarConfig: ScrollbarConfig(
                    showLeftScrollbar: .never,
                    showRightScrollbar: .always,
                  ),
                  selectedItem: selectedMod,
                  defaultGrouping: EnabledStateModGridGroup(),
                  defaultSortField: ModGridSortField.name.name,
                  groups: _allGroupOptions,
                  preSortComparator: (left, right) {
                    if (!pinFavorites) return null;

                    final leftFavorited =
                        modsMetadata
                            ?.getMergedModMetadata(left.id)
                            ?.isFavorited ==
                        true;
                    final rightFavorited =
                        modsMetadata
                            ?.getMergedModMetadata(right.id)
                            ?.isFavorited ==
                        true;

                    if (leftFavorited != rightFavorited) {
                      return leftFavorited ? -1 : 1;
                    }

                    return null;
                  },
                  rowBuilder:
                      ({required item, required modifiers, required child}) {
                        final isHovering = modifiers.isHovering ?? false;
                        final modMetadata = ref
                            .watch(AppState.modsMetadata)
                            .value
                            ?.userMetadata[item.id];
                        final isFavorited = modMetadata?.isFavorited ?? false;

                        return _ModGridRow(
                          mod: item,
                          isFavorited: isFavorited,
                          isHovering: isHovering,
                          isRowChecked: modifiers.isRowChecked,
                          child: Builder(
                            builder: (context) {
                              if (controller == null) return child;
                              return ContextMenuRegion(
                                contextMenuBuilder: () =>
                                    (controller!
                                            .checkedItemIdsReadonly
                                            .length) >
                                        1
                                    ? buildModBulkActionContextMenu(
                                        (controller!.lastDisplayedItemsReadonly)
                                            .where(
                                              (mod) => controller!
                                                  .checkedItemIdsReadonly
                                                  .contains(mod.id),
                                            )
                                            .toList(),
                                        ref,
                                        context,
                                      )
                                    : buildModContextMenu(
                                        item,
                                        ref,
                                        context,
                                        showSwapToVersion: true,
                                        openSidebar: (mod) {
                                          setState(() {
                                            selectedMod = mod;
                                          });
                                        },
                                      ),
                                child: Container(
                                  // Receive right-clicks on empty space.
                                  color: Colors.transparent,
                                  child: Column(
                                    children: [
                                      child,
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: _dependencyButtonLeftInset(
                                            gridState,
                                            modifiers.columns,
                                          ),
                                        ),
                                        child: buildMissingDependencyButtons(
                                          (item)
                                              .findFirstEnabledOrHighestVersion,
                                          allMods,
                                          isParentEnabled:
                                              item.hasEnabledVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                  columns: ModGridColumns(
                    ref: ref,
                    theme: theme,
                    modsMetadata: modsMetadata,
                    isGameRunning: isGameRunning,
                    allMods: allMods,
                    vramEstState: vramEstState,
                    loadOrderNumberLookupByModId: loadOrderNumberLookupByModId,
                    checkedModIds: () =>
                        controller?.checkedItemIdsReadonly ?? {},
                  ).build(),
                ),
              ),
            ),
          ],
        ),
        if (selectedMod != null)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const .only(top: 56.0),
              child: SizedBox(
                width: 400,
                child: ModSummaryPanel(selectedMod, () {
                  setState(() {
                    selectedMod = null;
                  });
                }),
              ),
            ),
          ),
      ],
    );
  }

  Builder buildEstimateVramButton(ThemeData theme) {
    return Builder(
      builder: (context) {
        final vramEst = ref.watch(AppState.vramEstimatorProvider);
        final isScanningVram = vramEst.value?.isScanning == true;
        return Animate(
          controller: animationController,
          effects: [
            if (isScanningVram)
              ShimmerEffect(
                colors: [
                  theme.colorScheme.onSurface,
                  theme.colorScheme.secondary,
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                duration: const Duration(milliseconds: 1500),
              ),
          ],
          child: OutlinedButton.icon(
            onPressed: () => isScanningVram
                ? ref
                      .read(AppState.vramEstimatorProvider.notifier)
                      .cancelEstimation()
                : showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      icon: const Icon(Icons.memory),
                      title: const Text("Estimate VRAM"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "This will scan all enabled mods and estimate the total VRAM usage.",
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "This may take a few minutes and cause your computer to lag!",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
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
                            ref
                                .read(AppState.vramEstimatorProvider.notifier)
                                .startEstimating();
                            Navigator.of(context).pop();
                          },
                          child: const Text("Estimate"),
                        ),
                      ],
                    ),
                  ),
            label: Text(isScanningVram ? "Cancel Scan" : "Est. VRAM"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface
                  .withOpacity(0.8),
              side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            icon: const Icon(Icons.memory),
          ),
        );
      },
    );
  }

  /// Marks the "Stop using profile" entry in the profile picker menu.
  static const _stopUsingProfileMenuValue = "trios.stopUsingProfile";

  Widget buildProfileSelector(bool isGameRunning) {
    return Builder(
      builder: (context) {
        final profiles = ref.watch(modProfilesProvider).value;
        final activeProfileId = ref.watch(
          appSettings.select((s) => s.activeModProfileId),
        );
        final trackedStatus = ref.watch(trackedProfileStatusProvider);
        final trackedProfile = trackedStatus.profile;
        final theme = Theme.of(context);

        final subtitle = trackedStatus.isLoading
            ? "Loading…"
            : trackedProfile == null
            ? "(none)"
            : trackedStatus.isModified
            ? "${trackedProfile.name.truncate(14)} (Modified)"
            : trackedProfile.name.truncate(20);

        return SizedBox(
          height: 36,
          child: MovingTooltipWidget.text(
            message: trackedStatus.isModified
                ? "Your enabled mods no longer match '${trackedProfile!.name}'."
                      "\nSave or revert on the Profiles tab."
                : "Swap between mod loadouts. Manage them in the Profiles tab.",
            child: Disable(
              isEnabled: !trackedStatus.isLoading,
              child: PopupMenuButton<Object>(
                onSelected: (selected) {
                  if (selected == _stopUsingProfileMenuValue) {
                    ref
                        .read(modProfilesProvider.notifier)
                        .showStopUsingProfileDialog(context);
                  } else if (selected is ModProfile) {
                    ref
                        .read(modProfilesProvider.notifier)
                        .showActivateDialog(selected, context);
                  }
                },
                tooltip: "",
                borderRadius: BorderRadius.circular(
                  TriOSThemeConstants.cornerRadius,
                ),
                initialValue: trackedProfile,
                itemBuilder: (BuildContext context) {
                  final items = <PopupMenuEntry<Object>>[
                    for (final p
                        in profiles?.modProfiles ?? const <ModProfile>[])
                      PopupMenuItem<Object>(
                        value: p,
                        enabled: !isGameRunning && p.id != trackedProfile?.id,
                        child: Text(
                          "${p.name} (${p.enabledModVariants.length} mods)",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                  ];
                  if (trackedProfile != null) {
                    items.add(const PopupMenuDivider());
                    items.add(
                      PopupMenuItem<Object>(
                        value: _stopUsingProfileMenuValue,
                        child: Text(
                          "Deactivate '${trackedProfile.name.truncate(20)}'",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    );
                  }
                  return items;
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Mod Profile", style: theme.textTheme.labelMedium),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 8,
                          color: trackedStatus.isModified
                              ? theme.colorScheme.secondary
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        return Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text("Profile:"),
            ),
            MovingTooltipWidget.text(
              message: isGameRunning ? "Game is running" : "",
              child: Disable(
                isEnabled: !isGameRunning,
                child: SizedBox(
                  width: 175,
                  child: Builder(
                    builder: (context) {
                      return TriOSDropdownButton(
                        value: profiles?.modProfiles.firstWhereOrNull(
                          (p) => p.id == activeProfileId,
                        ),
                        isDense: true,
                        isExpanded: true,
                        hint: const Text("(none active)"),
                        padding: const EdgeInsets.all(4),
                        focusColor: Colors.transparent,
                        items:
                            profiles?.modProfiles
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      "${p.name} (${p.enabledModVariants.length} mods)",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList() ??
                            [],
                        onChanged: (value) {
                          if (value is ModProfile) {
                            ref
                                .read(modProfilesProvider.notifier)
                                .showActivateDialog(value, context);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static final List<WispGridGroup<Mod>> _groupOptions = [
    UngroupedModGridGroup(),
    EnabledStateModGridGroup(),
    AuthorModGridGroup(),
  ];

  List<WispGridGroup<Mod>> get _allGroupOptions => [
    ..._groupOptions,
    CategoryModGridGroup(ref),
    ModTypeModGridGroup(),
    GameVersionModGridGroup(),
  ];

  Widget buildGroupBySelector(WispGridState gridState) {
    final groups = _allGroupOptions;
    final currentKey =
        gridState.groupingSetting?.currentGroupedByKey ??
        EnabledStateModGridGroup().key;
    final currentGroup =
        groups.firstWhereOrNull((g) => g.key == currentKey) ?? groups[1];

    return SizedBox(
      height: 36,
      child: MovingTooltipWidget.text(
        message: "Change how mods are grouped in the grid.",
        child: PopupMenuButton<WispGridGroup<Mod>>(
          onSelected: (group) {
            ref.read(appSettings.notifier).update((state) {
              final existing =
                  state.modsGridState.groupingSetting ??
                  const GroupingSetting(currentGroupedByKey: 'enabledState');
              return state.copyWith(
                modsGridState: state.modsGridState.copyWith(
                  groupingSetting: existing.copyWith(
                    currentGroupedByKey: group.key,
                  ),
                ),
              );
            });
          },
          tooltip: "",
          borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
          itemBuilder: (BuildContext context) => groups
              .map(
                (g) => PopupMenuItem<WispGridGroup<Mod>>(
                  value: g,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: g.key == currentKey
                            ? const Icon(Icons.check, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 4),
                      Text(g.displayName, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              )
              .toList(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Group By",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  currentGroup.displayName,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildThenBySelector(WispGridState gridState) {
    final groups = _allGroupOptions;
    final currentPrimaryKey =
        gridState.groupingSetting?.currentGroupedByKey ??
        EnabledStateModGridGroup().key;
    final currentSecondaryKey =
        gridState.groupingSetting?.secondaryGroupedByKey;
    // The "no grouping" entry is itself a group named "None", so leave it out
    // here — the menu already has its own "None" to clear the second level.
    final candidates = groups
        .where((g) => g.key != currentPrimaryKey && g.isGroupVisible)
        .toList();

    // Hide the selector entirely when "Then By" would be meaningless.
    if (groups.length <= 1 || candidates.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentSecondary = candidates.firstWhereOrNull(
      (g) => g.key == currentSecondaryKey,
    );

    void updateSecondary(String? newKey) {
      ref.read(appSettings.notifier).update((state) {
        final existing = state.modsGridState.groupingSetting;
        if (existing == null) return state;
        return state.copyWith(
          modsGridState: state.modsGridState.copyWith(
            groupingSetting: existing.copyWith(secondaryGroupedByKey: newKey),
          ),
        );
      });
    }

    return SizedBox(
      height: 36,
      child: MovingTooltipWidget.text(
        message: "Add a second level of grouping under the primary group.",
        child: PopupMenuButton<Object>(
          onSelected: (value) {
            if (value is WispGridGroup<Mod>) {
              updateSecondary(value.key);
            } else {
              updateSecondary(null);
            }
          },
          tooltip: "",
          borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<Object>(
              value: 'none',
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: currentSecondaryKey == null
                        ? const Icon(Icons.check, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 4),
                  const Text('None', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            ...candidates.map(
              (g) => PopupMenuItem<Object>(
                value: g,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: g.key == currentSecondaryKey
                          ? const Icon(Icons.check, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 4),
                    Text(g.displayName, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Then By", style: Theme.of(context).textTheme.labelMedium),
                Text(
                  currentSecondary?.displayName ?? 'None',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildOverflowButton(List<Mod> allMods) {
    final theme = Theme.of(context);
    final modsGridUpdateVisibility = ref.watch(
      appSettings.select((s) => s.modsGridUpdateVisibility),
    );

    return MovingTooltipWidget.text(
      message: "More options",
      child: PopupStyleMenuAnchor(
        builder: (context, menuController, child) {
          return IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: "",
            onPressed: () {
              if (menuController.isOpen) {
                menuController.close();
              } else {
                menuController.open();
              }
            },
          );
        },
        menuChildren: [
          PopupStyleMenuAnchor.checkboxItem(
            value: ref.watch(appSettings.select((s) => s.pinFavorites)),
            onPressed: () {
              final current = ref.read(appSettings).pinFavorites;
              ref
                  .read(appSettings.notifier)
                  .update((s) => s.copyWith(pinFavorites: !current));
            },
            child: const Text("Pin Favorited Mods to Top"),
          ),
          PopupStyleMenuAnchor.checkboxItem(
            value: ref.watch(appSettings.select((s) => s.modsGridColorful)),
            onPressed: () {
              final current = ref.read(appSettings).modsGridColorful;
              ref
                  .read(appSettings.notifier)
                  .update((s) => s.copyWith(modsGridColorful: !current));
            },
            child: MovingTooltipWidget.text(
              message:
                  "If a mod has an icon, use its colors to style the mod row.",
              child: const Text("Colorful"),
            ),
          ),
          PopupStyleMenuAnchor.checkboxItem(
            value: ref.watch(
              appSettings.select((s) => s.modsGridHighContrastEnableButton),
            ),
            onPressed: () {
              final current = ref
                  .read(appSettings)
                  .modsGridHighContrastEnableButton;
              ref
                  .read(appSettings.notifier)
                  .update(
                    (s) =>
                        s.copyWith(modsGridHighContrastEnableButton: !current),
                  );
            },
            child: MovingTooltipWidget.text(
              message: "It doesn't mean you're old.",
              child: const Text("Mod Buttons: High Contrast"),
            ),
          ),
          PopupStyleMenuAnchor.checkboxItem(
            value: ref.watch(
              appSettings.select((s) => s.modsGridShowDataWarnings),
            ),
            onPressed: () {
              final current = ref.read(appSettings).modsGridShowDataWarnings;
              ref
                  .read(appSettings.notifier)
                  .update(
                    (s) => s.copyWith(modsGridShowDataWarnings: !current),
                  );
            },
            child: MovingTooltipWidget.text(
              message: "Show a warning icon next to mods whose data has a problem, like a mod whose .version file and mod_info.json don't agree on the version.",
              child: const Text("Show Mod Data Warnings"),
            ),
          ),
          if (ref.watch(
            appSettings.select(
              (s) =>
                  s.modsGridState.groupingSetting?.currentGroupedByKey ==
                  'category',
            ),
          ))
            PopupStyleMenuAnchor.checkboxItem(
              value: ref.watch(
                appSettings.select((s) => s.modsGridShowModInAllCategories),
              ),
              onPressed: () => toggleShowModInAllCategories(ref),
              child: MovingTooltipWidget.text(
                message: "If a mod is in multiple categories, show the mod in each category rather than only in its primary category.",
                child: const Text("Repeat Mods In Each Category"),
              ),
            ),
          Divider(),
          SubmenuButton(
            leadingIcon: PopupStyleMenuAnchor.paddedIcon(
              SvgImageIcon("assets/images/icon-update-badge.svg"),
            ),
            menuChildren: [
              MenuItemButton(
                leadingIcon: PopupStyleMenuAnchor.paddedIcon(
                  Icon(
                    modsGridUpdateVisibility ==
                            ModsGridUpdateVisibility.showUnmuted
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                ),
                onPressed: () {
                  ref
                      .read(appSettings.notifier)
                      .update(
                        (s) => s.copyWith(
                          modsGridUpdateVisibility:
                              ModsGridUpdateVisibility.showUnmuted,
                        ),
                      );
                },
                child: const Text("Show unmuted updates"),
              ),
              MenuItemButton(
                leadingIcon: PopupStyleMenuAnchor.paddedIcon(
                  Icon(
                    modsGridUpdateVisibility == ModsGridUpdateVisibility.showAll
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                ),
                onPressed: () {
                  ref
                      .read(appSettings.notifier)
                      .update(
                        (s) => s.copyWith(
                          modsGridUpdateVisibility:
                              ModsGridUpdateVisibility.showAll,
                        ),
                      );
                },
                child: const Text("Show all updates"),
              ),
              MenuItemButton(
                leadingIcon: PopupStyleMenuAnchor.paddedIcon(
                  Icon(
                    modsGridUpdateVisibility == ModsGridUpdateVisibility.hide
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                ),
                onPressed: () {
                  ref
                      .read(appSettings.notifier)
                      .update(
                        (s) => s.copyWith(
                          modsGridUpdateVisibility:
                              ModsGridUpdateVisibility.hide,
                        ),
                      );
                },
                child: const Text("Don't show updates"),
              ),
            ],
            child: MovingTooltipWidget.text(
              message: "Whether to show a section at the top of the page containing only mods with updates.",
              child: Text(switch (modsGridUpdateVisibility) {
                ModsGridUpdateVisibility.showUnmuted =>
                  "Showing Updates section",
                ModsGridUpdateVisibility.showAll =>
                  "Showing Updates section (incl. muted)",
                ModsGridUpdateVisibility.hide => "Not showing Update section",
              }),
            ),
          ),
          Divider(),
          MenuItemButton(
            leadingIcon: PopupStyleMenuAnchor.paddedIcon(
              Icon(Icons.local_fire_department),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Enable All Mods"),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Are you sure you want to enable all ${allMods.length} mods?",
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "This will enable the latest version of all disabled mods."
                          "\nMods that are already enabled won't be changed.",
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(modManager.notifier).enableMultiple(allMods);
                        },
                        child: const Text("Enable All"),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text("Enable All Mods"),
          ),
          MenuItemButton(
            leadingIcon: PopupStyleMenuAnchor.paddedIcon(
              Icon(Icons.fire_truck),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Disable All Mods"),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Are you sure you want to disable all ${allMods.length} mods?",
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref
                              .read(modManager.notifier)
                              .disableMultiple(allMods);
                        },
                        child: const Text("Disable All"),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text("Disable All Mods"),
          ),
          MenuItemButton(
            leadingIcon: PopupStyleMenuAnchor.paddedIcon(Icon(Icons.copy)),
            onPressed: () {
              copyModListToClipboardFromMods(
                allMods.where((mod) => mod.hasEnabledVariant).toList(),
                context,
              );
            },
            child: Text("Copy Enabled Mods to Clipboard"),
          ),
          MenuItemButton(
            leadingIcon: PopupStyleMenuAnchor.paddedIcon(Icon(Icons.copy_all)),
            onPressed: () {
              copyModListToClipboardFromMods(allMods, context);
            },
            child: Text("Copy All Mods to Clipboard"),
          ),
          MenuItemButton(
            leadingIcon: PopupStyleMenuAnchor.paddedIcon(
              Icon(Icons.table_view),
            ),
            onPressed: () {
              if (controller == null) return;
              showExportOrCopyDialog(
                context,
                "mod",
                () => WispGridCsvExporter.toCsv(
                  controller!,
                  includeHeaders: true,
                ),
                () => ref.read(modManager.notifier).allModsAsCsv(),
              );
            },
            child: Text("Export to CSV"),
          ),
          Divider(),
          MenuItemButton(
            leadingIcon: PopupStyleMenuAnchor.paddedIcon(Icon(Icons.settings)),
            onPressed: () {
              showCategoryManagementPopup(context: context, ref: ref);
            },
            child: Text("Manage Categories..."),
          ),
        ],
      ),
    );
  }

  /// Left inset that lines the dependency buttons up under the Enable/Disable
  /// (version) column. The row lays out cells as [8px gap, col0, col1, ...]
  /// with 8px between each, so a column's left edge sits at 16 plus the total
  /// width of the columns before it (each plus one 8px gap). Recomputed from
  /// live grid state so it follows the column when it's moved or resized.
  /// Falls back to the first column's position if that column is hidden.
  double _dependencyButtonLeftInset(
    WispGridState gridState,
    List<WispGridColumn> columns,
  ) {
    const leadingInset = WispGrid.gridRowSpacing * 2; // 8px gap + 8px spacing
    var inset = leadingInset;
    for (final entry in gridState.sortedVisibleColumns(columns)) {
      if (entry.key == ModGridHeader.changeVariantButton.name) {
        return inset;
      }
      inset += entry.value.width + WispGrid.gridRowSpacing;
    }
    // Enable/Disable column not visible — keep the original indent.
    return leadingInset;
  }

  Widget buildMissingDependencyButtons(
    ModVariant? enabledVersion,
    List<Mod> allMods, {
    required bool isParentEnabled,
  }) {
    final modCompatibility = ref.watch(
      AppState.modCompatibility,
    )[enabledVersion?.smolId];
    final unmetDependencies =
        modCompatibility?.dependencyChecks
            .where((e) => !e.isCurrentlySatisfied)
            .toList() ??
        [];

    if (unmetDependencies.isEmpty) return Container();

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4, left: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          ...unmetDependencies.map((checkResult) {
            return MissingDependencyButton(
              enabledVersion: enabledVersion,
              checkResult: checkResult,
              allMods: allMods,
              isParentEnabled: isParentEnabled,
            );
          }),
        ],
      ),
    );
  }
}

class MissingDependencyButton extends ConsumerWidget {
  const MissingDependencyButton({
    super.key,
    required this.enabledVersion,
    required this.checkResult,
    required this.allMods,
    required this.isParentEnabled,
  });

  final ModVariant? enabledVersion;
  final ModDependencyCheckResult checkResult;
  final List<Mod> allMods;
  final bool isParentEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A present-but-off dependency only matters once the parent mod is on:
    // enabling it alone does nothing while the parent is still off.
    if (checkResult.satisfiedAmount is Disabled && !isParentEnabled) {
      return const SizedBox.shrink();
    }

    final buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: const Size(60, 34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          TriOSThemeConstants.cornerRadius,
        ), // Rounded corners
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: MovingTooltipWidget.text(
        message:
            "${enabledVersion?.modInfo.nameOrId} requires ${checkResult.dependency.formattedNameVersion}",
        child: Row(
          children: [
            // if (checkResult.satisfiedAmount is Disabled)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Builder(
                builder: (context) {
                  if (checkResult.satisfiedAmount is Disabled) {
                    final disabledVariant =
                        (checkResult.satisfiedAmount as Disabled).modVariant;
                    return OutlinedButton(
                      onPressed: () {
                        ref
                            .read(modManager.notifier)
                            .changeActiveModVariantWithForceModGameVersionDialogIfNeeded(
                              disabledVariant!.mod(allMods)!,
                              disabledVariant,
                            );
                      },
                      style: buttonStyle,
                      child: TextWithIcon(
                        text:
                            "Enable ${disabledVariant?.modInfo.formattedNameVersion}",
                        leading: disabledVariant?.iconFilePath == null
                            ? null
                            : Image.file(
                                (disabledVariant?.iconFilePath ?? "").toFile(),
                                height: 20,
                                isAntiAlias: true,
                              ),
                        leadingPadding: const EdgeInsets.only(right: 4),
                      ),
                    );
                  } else {
                    final missingDependency = checkResult.dependency;

                    // The catalog has no mod IDs, so match the missing mod to
                    // a catalog entry by name (ignoring case and punctuation),
                    // the same way mod records match installed mods.
                    final catalog = ref
                        .watch(browseModsNotifierProvider)
                        .value
                        ?.items;
                    final candidates = <String>{
                      if (missingDependency.name != null)
                        missingDependency.name!.alphanumericLower(),
                      if (missingDependency.id != null)
                        missingDependency.id!.alphanumericLower(),
                    };
                    final catalogMatch = (catalog == null || candidates.isEmpty)
                        ? null
                        : catalog.firstWhereOrNull(
                            (m) =>
                                candidates.contains(m.name.alphanumericLower()),
                          );
                    final directDownloadUrl = catalogMatch
                        ?.getUrls()[ModUrlType.DirectDownload];
                    final hasDirectDownload =
                        directDownloadUrl != null &&
                        directDownloadUrl.isNotEmpty;
                    // Page to open when there's no one-click download link.
                    final websiteUrl = catalogMatch?.getBestWebsiteUrl();

                    // Is the dependency installed, just an older version than
                    // what the mod needs? (modVariant is only set when present.)
                    final installedVariant =
                        checkResult.satisfiedAmount.modVariant;
                    final installedVersion = installedVariant?.modInfo.version;
                    final requiredVersion = missingDependency.version;
                    final isOutdated =
                        installedVariant != null &&
                        installedVersion != null &&
                        requiredVersion != null &&
                        installedVersion < requiredVersion;

                    Future<void> openUrl(String url) async {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else if (context.mounted) {
                        showSnackBar(
                          context: context,
                          content: const Text(
                            "Couldn't open browser. Google recommends Chrome for a faster experience!",
                          ),
                        );
                      }
                    }

                    void searchOnline() => openUrl(
                      'https://www.google.com/search?q=starsector+'
                      '${missingDependency.formattedNameVersionId}+download',
                    );

                    final String text;
                    final String? tooltipMessage;
                    final Widget leading;
                    final VoidCallback onPressed;

                    const downloadIcon = Icon(Icons.download, size: 20);
                    const openPageIcon = Icon(Icons.open_in_browser, size: 20);
                    const searchIcon = SvgImageIcon(
                      "assets/images/icon-search.svg",
                      width: 20,
                      height: 20,
                    );

                    // Only the one-click branches start a download, so only
                    // they show progress.
                    final downloadTarget = hasDirectDownload
                        ? DownloadTarget(
                            modId: missingDependency.id,
                            url: directDownloadUrl,
                            catalogName: catalogMatch?.name,
                            displayName: missingDependency.nameOrId,
                          )
                        : null;

                    // Asks first, and only starts spinning once the user says
                    // yes — backing out of the dialog leaves the button alone.
                    Future<void> confirmAndDownload() async {
                      final started = await confirmAndDownloadModViaManager(
                        context,
                        ref,
                        modName: missingDependency.nameOrId,
                        downloadUrl: directDownloadUrl!,
                        activateVariantOnComplete: false,
                      );
                      if (started) {
                        ref
                            .read(pendingDownloadClicks.notifier)
                            .markClicked(downloadTarget!);
                      }
                    }

                    if (isOutdated) {
                      final outdatedTooltip =
                          "You have $installedVersion. This mod needs "
                          "$requiredVersion or newer.";
                      final updateText =
                          "Update ${missingDependency.nameOrId} "
                          "($requiredVersion required)";
                      if (hasDirectDownload) {
                        text = updateText;
                        tooltipMessage =
                            "$outdatedTooltip Click to download the latest version.";
                        leading = downloadIcon;
                        onPressed = confirmAndDownload;
                      } else if (websiteUrl != null) {
                        text = updateText;
                        tooltipMessage =
                            "$outdatedTooltip Click to open the download page.";
                        leading = openPageIcon;
                        onPressed = () => openUrl(websiteUrl);
                      } else {
                        text = "Search for newer ${missingDependency.nameOrId}";
                        tooltipMessage = outdatedTooltip;
                        leading = searchIcon;
                        onPressed = searchOnline;
                      }
                    } else if (hasDirectDownload) {
                      text =
                          "Install ${missingDependency.formattedNameVersion}";
                      tooltipMessage =
                          "Download and install ${missingDependency.nameOrId} "
                          "with ${Constants.appName}";
                      leading = downloadIcon;
                      onPressed = confirmAndDownload;
                    } else {
                      text =
                          "Search ${missingDependency.formattedNameVersionId}";
                      tooltipMessage = null;
                      leading = searchIcon;
                      onPressed = searchOnline;
                    }

                    if (downloadTarget != null) {
                      return ModDownloadButton(
                        target: downloadTarget,
                        variant: ModDownloadButtonVariant.outlined,
                        style: buttonStyle,
                        icon: leading,
                        label: Text(text),
                        tooltip: tooltipMessage,
                        onPressed: onPressed,
                        spinnerSize: 20,
                        // confirmAndDownload marks it once the user says yes,
                        // so the click itself mustn't.
                        markPendingOnPress: false,
                      );
                    }

                    final button = OutlinedButton(
                      onPressed: onPressed,
                      style: buttonStyle,
                      child: TextWithIcon(
                        text: text,
                        leading: leading,
                        leadingPadding: const EdgeInsets.only(right: 4),
                      ),
                    );

                    return tooltipMessage == null
                        ? button
                        : MovingTooltipWidget.text(
                            message: tooltipMessage,
                            child: button,
                          );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.mod,
    required this.isRowHighlighted,
    required this.isFavorited,
  });

  final Mod mod;
  final bool isRowHighlighted;
  final bool isFavorited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isFavorited || isRowHighlighted)
          Padding(
            padding: const EdgeInsets.only(right: 0.0),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  ref
                      .read(AppState.modsMetadata.notifier)
                      .updateModUserMetadata(
                        mod.id,
                        (oldMetadata) => oldMetadata.copyWith(
                          isFavorited: !(oldMetadata.isFavorited ?? false),
                        ),
                      );
                },
                child: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited
                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.6)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ModGridRow extends ConsumerStatefulWidget {
  final Mod mod;
  final bool isFavorited;
  final bool isHovering;
  final bool isRowChecked;
  final Widget child;

  const _ModGridRow({
    required this.mod,
    required this.isFavorited,
    required this.isHovering,
    required this.isRowChecked,
    required this.child,
  });

  @override
  ConsumerState<_ModGridRow> createState() => _ModGridRowState();
}

class _ModGridRowState extends ConsumerState<_ModGridRow>
    with PaletteGeneratorMixin<_ModGridRow> {
  @override
  String? getIconPath() =>
      widget.mod.findFirstEnabledOrHighestVersion?.iconFilePath ??
      widget.mod.modVariants.firstOrNull?.iconFilePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isColorfulModeOn = ref.watch(
      appSettings.select((s) => s.modsGridColorful),
    );
    final paletteTriosTheme = isColorfulModeOn
        ? paletteGenerator?.toTriOSTheme(context)
        : null;
    final paletteTheme = paletteTriosTheme != null
        ? ThemeManager.convertToThemeData(paletteTriosTheme)
        : null;
    final paletteBg = paletteTheme?.colorScheme.surfaceDim;
    final paletteAccent = paletteTheme?.colorScheme.onSurface;

    final backgroundBaseColor = isColorfulModeOn
        ? (paletteBg?.withValues(alpha: 0.3) ?? Colors.transparent)
        : widget.isFavorited
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : Colors.transparent;

    // Mix in any hover/checked overlay color, but only when there is one.
    final overlayColor = widget.isRowChecked
        ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
        : widget.isHovering
        ? theme.colorScheme.onInverseSurface.withValues(alpha: 0.2)
        : null;
    final backgroundColor = overlayColor != null
        ? backgroundBaseColor.mix(overlayColor, 0.5)
        : backgroundBaseColor;

    // Recolor text and icons via the theme so that cells using Theme.of(context)
    // pick up the palette accent. TextTheme.apply() recolors every text style
    // while preserving fontFamily, fontWeight, fontSize, etc.
    Widget child = widget.child;
    if (paletteAccent != null) {
      child = Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.apply(
            bodyColor: paletteAccent,
            displayColor: paletteAccent,
          ),
          iconTheme: theme.iconTheme.copyWith(color: paletteAccent),
          colorScheme: theme.colorScheme.copyWith(onSurface: paletteAccent),
          progressIndicatorTheme: paletteTheme?.progressIndicatorTheme,
        ),
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(color: backgroundColor),
      child: child,
    );
  }
}
