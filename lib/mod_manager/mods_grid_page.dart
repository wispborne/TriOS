import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/chipper/utils.dart';
import 'package:trios/dashboard/changelogs.dart';
import 'package:trios/dashboard/mod_list_basic.dart';
import 'package:trios/dashboard/mod_list_basic_entry.dart';
import 'package:trios/dashboard/version_check_icon.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/mod_context_menu.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/mod_manager/mod_summary_panel.dart';
import 'package:trios/mod_manager/mod_version_selection_dropdown.dart';
import 'package:trios/mod_tag_manager/mod_tag_manager.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/mod_metadata.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/graphics_lib_config_provider.dart';
import 'package:trios/vram_estimator/vram_estimator_page.dart';
import 'package:trios/widgets/add_new_mods_button.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/export_to_csv_dialog.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/mod_type_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/refresh_mods_button.dart';
import 'package:trios/widgets/svg_image_icon.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/text_with_icon.dart';
import 'package:trios/widgets/tooltip_frame.dart';
import 'package:url_launcher/url_launcher.dart';

import '../mod_profiles/mod_profiles_manager.dart';
import '../mod_profiles/models/mod_profile.dart';
import '../thirdparty/flutter_tags/item_tags.dart';
import '../thirdparty/flutter_tags/tags.dart' show Tags;
import '../utils/search.dart';
import 'filter_mods_search_view.dart';
import 'homebrew_grid/wispgrid_group.dart';
import 'homebrew_grid/wispgrid_header_row_view.dart';
import 'vram_checker_explanation.dart';

final modsGridSearchQuery = StateProvider.autoDispose<String>((ref) => "");

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
  final _searchController = SearchController();
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

    final query = _searchController.value.text;
    final modsMatchingSearch = searchMods(allMods, query) ?? [];
    final modsMetadata = ref.watch(AppState.modsMetadata).value;
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
                              const SizedBox(width: 8),
                              // Removing Est. VRAM button because it's on the mod groups now.
                              // Maybe should add it to an overflow menu, though.
                              if (false) buildEstimateVramButton(theme),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 30,
                                width: 300,
                                child: FilterModsSearchBar(
                                  searchController: _searchController,
                                  query: ref.watch(modsGridSearchQuery),
                                  ref: ref,
                                ),
                              ),
                              const Spacer(),
                              // Builder(builder: (context) {
                              //   final isDoubleClick = ref.watch(
                              //       appSettings.select(
                              //           (s) => s.doubleClickForModsPanel));
                              //
                              //   return AnimatedPopupMenuButton(
                              //       icon: Icon(Icons.more_vert),
                              //       showArrow: false,
                              //       onSelected: (value) {
                              //         ref.read(appSettings.notifier).update(
                              //             (s) => s.copyWith(
                              //                 doubleClickForModsPanel:
                              //                     !value));
                              //       },
                              //       menuItems: [
                              //         PopupMenuItem(
                              //             value: isDoubleClick,
                              //             child: Row(
                              //               children: [
                              //                 AbsorbPointer(
                              //                   child: Checkbox(
                              //                       value: isDoubleClick,
                              //                       onChanged: (_) {}),
                              //                 ),
                              //                 SizedBox(width: 8),
                              //                 // Space between icon and text
                              //                 Text(
                              //                     "Double-click to view side panel"),
                              //               ],
                              //             )),
                              //       ]);
                              // }),
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
                  scrollbarConfig: ScrollbarConfig(),
                  selectedItem: selectedMod,
                  defaultGrouping: EnabledStateModGridGroup(),
                  defaultSortField: ModGridSortField.name.name,
                  groups: [
                    UngroupedModGridGroup(),
                    EnabledStateModGridGroup(),
                    AuthorModGridGroup(),
                    ModTypeModGridGroup(),
                    GameVersionModGridGroup(),
                  ],
                  preSortComparator: (left, right) {
                    final leftMetadata = modsMetadata?.getMergedModMetadata(
                      left.id,
                    );
                    final rightMetadata = modsMetadata?.getMergedModMetadata(
                      right.id,
                    );

                    if (ref.watch(appSettings.select((s) => s.pinFavorites))) {
                      final leftFavorited = leftMetadata?.isFavorited == true;
                      final rightFavorited = rightMetadata?.isFavorited == true;

                      if (leftFavorited != rightFavorited) {
                        return leftFavorited ? -1 : 1;
                      }
                    }

                    return null;
                  },
                  rowBuilder: ({required item, required modifiers, required child}) {
                    final isHovering = modifiers.isHovering ?? false;
                    final modMetadata = ref
                        .watch(AppState.modsMetadata)
                        .value
                        ?.userMetadata[item.id];
                    final isFavorited = modMetadata?.isFavorited ?? false;

                    final backgroundBaseColor = isFavorited
                        ? theme.colorScheme.primary.withOpacity(0.3)
                        : Colors.transparent;

                    // Mix in any hover/checked overlay color
                    final backgroundColor = backgroundBaseColor.mix(
                      modifiers.isRowChecked
                          ? theme.colorScheme.onSurface.withOpacity(0.4)
                          : isHovering
                          ? theme.colorScheme.onInverseSurface.withOpacity(0.2)
                          : Colors.transparent,
                      0.5,
                    );

                    return Container(
                      decoration: BoxDecoration(color: backgroundColor),
                      child: Builder(
                        builder: (context) {
                          if (controller == null) return child;
                          return ContextMenuRegion(
                            contextMenu:
                                (controller!.checkedItemIdsReadonly.length) > 1
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
                              // This container is so that the context menu gets hit detection.
                              // Without it, right-clicking empty space doesn't show the context menu.
                              color: Colors.transparent,
                              child: Column(
                                children: [
                                  child,
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left:
                                          12 +
                                          gridState.getWidthUpToColumn(
                                            ModGridHeader.name.name,
                                            modifiers.columns,
                                          ),
                                    ),
                                    child: buildMissingDependencyButtons(
                                      (item).findFirstEnabled,
                                      allMods,
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
                  columns: [
                    WispGridColumn<Mod>(
                      key: ModGridHeader.favorites.name,
                      name: "Favorite",
                      isSortable: false,
                      headerCellBuilder: (modifiers) => buildColumnHeader(
                        ModGridHeader.favorites,
                        modifiers,
                      ).child,
                      itemCellBuilder: (mod, modifiers) => Builder(
                        builder: (context) {
                          final modMetadata =
                              modsMetadata?.userMetadata[mod.id];
                          final isFavorited = modMetadata?.isFavorited ?? false;
                          return FavoriteButton(
                            mod: mod,
                            isRowHighlighted: modifiers.isHovering,
                            isFavorited: isFavorited,
                          );
                        },
                      ),
                      csvValue: (mod) =>
                          modsMetadata?.userMetadata[mod.id]?.isFavorited
                              .toString() ??
                          "false",
                      defaultState: WispGridColumnState(position: 0, width: 50),
                    ),
                    WispGridColumn<Mod>(
                      key: ModGridHeader.changeVariantButton.name,
                      name: "Version Select",
                      isSortable: false,
                      headerCellBuilder: (modifiers) => Container(),
                      itemCellBuilder: (mod, modifiers) => Disable(
                        isEnabled: !isGameRunning,
                        child: ModVersionSelectionDropdown(
                          mod: mod,
                          width: modifiers.columnState.width,
                          showTooltip: true,
                        ),
                      ),
                      csvValue: (mod) => mod.modVariants
                          .map((v) => v.modInfo.version.toString())
                          .join(","),
                      defaultState: WispGridColumnState(
                        position: 1,
                        width: 130,
                      ),
                    ),
                    WispGridColumn<Mod>(
                      key: ModGridHeader.icons.name,
                      name: "Mod Icon",
                      isSortable: true,
                      getSortValue: (mod) => mod.getSortValueForModIcon(),
                      headerCellBuilder: (modifiers) => Container(),
                      itemCellBuilder: (mod, modifiers) => Builder(
                        builder: (context) {
                          String? iconPath = mod
                              .findFirstEnabledOrHighestVersion
                              ?.iconFilePath;
                          return iconPath != null
                              ? ModIcon(iconPath, size: 32)
                              : const SizedBox(width: 32, height: 32);
                        },
                      ),
                      csvValue: (mod) =>
                          mod.findFirstEnabledOrHighestVersion?.iconFilePath,
                      defaultState: WispGridColumnState(position: 2, width: 32),
                    ),
                    WispGridColumn<Mod>(
                      key: ModGridHeader.modIcon.name,
                      name: "Mod Type Icon",
                      isSortable: true,
                      getSortValue: (mod) => mod.getSortValueForType(),
                      headerCellBuilder: (modifiers) => Container(),
                      itemCellBuilder: (mod, modifiers) => ModTypeIcon(
                        modVariant: mod.findFirstEnabledOrHighestVersion!,
                      ),
                      csvValue: (mod) => mod
                          .findFirstEnabledOrHighestVersion
                          ?.modInfo
                          .modTypes
                          .joinToString(transform: (type) => type.name),
                      defaultState: WispGridColumnState(position: 3, width: 32),
                    ),
                    WispGridColumn<Mod>(
                      key: ModGridHeader.loadOrder.name,
                      name: "Load #",
                      isSortable: true,
                      getSortValue: (mod) => mod.getSortValueForLoadOrder(),
                      headerCellBuilder: (modifiers) => buildColumnHeader(
                        ModGridHeader.loadOrder,
                        modifiers,
                      ).child,
                      itemCellBuilder: (mod, modifiers) => TextTriOS(
                        loadOrderNumberLookupByModId[mod.id]?.toString() ?? "—",
                        style: GoogleFonts.roboto(
                          textStyle: theme.textTheme.labelLarge,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      csvValue: (mod) =>
                          loadOrderNumberLookupByModId[mod.id]?.toString() ??
                          "—",
                      defaultState: WispGridColumnState(
                        position: 4,
                        width: 70,
                        isVisible: false,
                      ),
                    ),
                    WispGridColumn<Mod>(
                      key: ModGridHeader.name.name,
                      name: "Name",
                      isSortable: true,
                      getSortValue: (mod) => mod.getSortValueForName(),
                      headerCellBuilder: (modifiers) => buildColumnHeader(
                        ModGridHeader.name,
                        modifiers,
                      ).child,
                      itemCellBuilder: (mod, modifiers) => buildNameCell(
                        mod,
                        mod.findFirstEnabledOrHighestVersion!,
                        allMods,
                        modifiers.columnState,
                      ),
                      csvValue: (mod) => mod
                          .findFirstEnabledOrHighestVersion
                          ?.modInfo
                          .nameOrId,
                      defaultState: WispGridColumnState(
                        position: 4,
                        width: 200,
                      ),
                    ),
                    WispGridColumn<Mod>(
                      key: ModGridHeader.author.name,
                      name: "Author",
                      isSortable: true,
                      getSortValue: (mod) => mod.getSortValueForAuthor(),
                      headerCellBuilder: (modifiers) => buildColumnHeader(
                        ModGridHeader.author,
                        modifiers,
                      ).child,
                      itemCellBuilder: (mod, modifiers) => Builder(
                        builder: (context) {
                          final theme = Theme.of(context);
                          final lightTextColor = theme.colorScheme.onSurface
                              .withValues(alpha: WispGrid.lightTextOpacity);
                          final bestVersion =
                              mod.findFirstEnabledOrHighestVersion!;
                          return TextTriOS(
                            bestVersion.modInfo.author?.toString().replaceAll(
                                  "\n",
                                  "   ",
                                ) ??
                                "(no author)",
                            maxLines: 1,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: lightTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                      csvValue: (mod) =>
                          mod.findFirstEnabledOrHighestVersion?.modInfo.author,
                      defaultState: WispGridColumnState(
                        position: 5,
                        width: 200,
                      ),
                    ),
                    WispGridColumn<Mod>(
                      key: ModGridHeader.updateStatus.name,
                      name: "Update",
                      isSortable: true,
                      getSortValue: (mod) =>
                          mod.getSortValueForUpdateStatus(ref, modsMetadata),
                      itemCellBuilder: (mod, modifiers) => Builder(
                        builder: (context) {
                          final bestVersion =
                              mod.findFirstEnabledOrHighestVersion!;
                          return _buildUpdateCell(
                            WispGrid.lightTextOpacity,
                            mod,
                            isGameRunning,
                            bestVersion,
                            modifiers.columnState,
                            modsMetadata?.getMergedModMetadata(mod.id),
                          );
                        },
                      ),
                      csvValue: (mod) => null,
                      defaultState: WispGridColumnState(position: 6, width: 65),
                    ),
                    WispGridColumn<Mod>(
                      key: ModGridHeader.version.name,
                      name: "Version",
                      isSortable: true,
                      getSortValue: (mod) => mod.getSortValueForVersion(),
                      itemCellBuilder: (mod, modifiers) => Builder(
                        builder: (context) {
                          final bestVersion =
                              mod.findFirstEnabledOrHighestVersion!;
                          return _buildVersionCell(
                            WispGrid.lightTextOpacity,
                            mod,
                            isGameRunning,
                            bestVersion,
                            modifiers.columnState,
                            modsMetadata?.getMergedModMetadata(mod.id),
                          );
                        },
                      ),
                      csvValue: (mod) => mod
                          .findFirstEnabledOrHighestVersion
                          ?.modInfo
                          .version
                          .toString(),
                      defaultState: WispGridColumnState(position: 7, width: 75),
                    ),
                    WispGridColumn<Mod>(
                      key: ModGridHeader.vramImpact.name,
                      name: "VRAM Est.",
                      isSortable: true,
                      getSortValue: (mod) =>
                          mod.getSortValueForVram(vramEstState.value),
                      headerCellBuilder: (modifiers) => buildColumnHeader(
                        ModGridHeader.vramImpact,
                        modifiers,
                      ).child,
                      itemCellBuilder: (mod, modifiers) => buildVramCell(
                        WispGrid.lightTextOpacity,
                        mod,
                        modifiers.columnState,
                      ),
                      csvValue: (mod) => ref
                          .read(AppState.vramEstimatorProvider)
                          .value
                          ?.modVramInfo[mod
                              .findFirstEnabledOrHighestVersion!
                              .smolId]
                          ?.bytesNotIncludingGraphicsLib()
                          .toString(),
                      defaultState: WispGridColumnState(
                        position: 8,
                        width: 128,
                      ),
                    ),
                    if (false)
                      WispGridColumn<Mod>(
                        key: ModGridHeader.tags.name,
                        name: "Tags",
                        isSortable: false,
                        headerCellBuilder: (modifiers) => buildColumnHeader(
                          ModGridHeader.tags,
                          modifiers,
                        ).child,
                        itemCellBuilder: (mod, modifiers) => Opacity(
                          opacity: WispGrid.lightTextOpacity,
                          child: ContextMenuRegion(
                            contextMenu: ContextMenu(
                              entries: [
                                MenuItem(
                                  label: "Add Default Tags",
                                  onSelected: () {
                                    ref
                                        .read(modTagManagerProvider.notifier)
                                        .addDefaultModTags([
                                          mod.findFirstEnabledOrHighestVersion!,
                                        ]);
                                  },
                                ),
                              ],
                            ),
                            child: Container(
                              // For hit testing, same as the Row below
                              color: Colors.transparent,
                              child: Builder(
                                builder: (context) {
                                  final tagsForMod = ref
                                      .watch(modTagManagerProvider.notifier)
                                      .getTagsForMod(mod.id)
                                      .toList();
                                  return Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        child: tagsForMod.isEmpty
                                            ? Text("")
                                            : Tags(
                                                itemCount: tagsForMod.length,
                                                itemBuilder: (index) {
                                                  return ItemTags(
                                                    index: index,
                                                    title:
                                                        tagsForMod[index].name,
                                                    singleItem: true,
                                                    active: true,
                                                    textActiveColor: theme
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                    activeColor: theme
                                                        .colorScheme
                                                        .primaryContainer,
                                                    splashColor:
                                                        Colors.transparent,
                                                    removeButton: ItemTagsRemoveButton(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      onRemoved: () {
                                                        ref
                                                            .read(
                                                              modTagManagerProvider
                                                                  .notifier,
                                                            )
                                                            .removeTagIdsFromMod(
                                                              mod.id,
                                                              [
                                                                tagsForMod[index]
                                                                    .id,
                                                              ],
                                                            );
                                                        return true;
                                                      },
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        csvValue: (mod) => ref
                            .watch(modTagManagerProvider.notifier)
                            .getTagsForMod(mod.id)
                            .toList()
                            .join(", "),
                        defaultState: WispGridColumnState(
                          position: 9,
                          width: 150,
                        ),
                      ),
                    WispGridColumn<Mod>(
                      key: ModGridHeader.gameVersion.name,
                      name: "Game Version",
                      isSortable: true,
                      getSortValue: (mod) => mod.getSortValueForGameVersion(),
                      headerCellBuilder: (modifiers) => buildColumnHeader(
                        ModGridHeader.gameVersion,
                        modifiers,
                      ).child,
                      itemCellBuilder: (mod, modifiers) => Builder(
                        builder: (context) {
                          final bestVersion =
                              mod.findFirstEnabledOrHighestVersion!;
                          final originalGameVersion =
                              bestVersion.modInfo.originalGameVersion;

                          return MovingTooltipWidget.text(
                            message: originalGameVersion != null
                                ? "Original game version: $originalGameVersion"
                                : null,
                            child: Opacity(
                              opacity: WispGrid.lightTextOpacity,
                              child: Text(
                                "${bestVersion.modInfo.gameVersion ?? "(no game version)"}"
                                "${originalGameVersion != null ? "**" : ""}",
                                style:
                                    compareGameVersions(
                                          bestVersion.modInfo.gameVersion,
                                          ref
                                              .watch(appSettings)
                                              .lastStarsectorVersion,
                                        ) ==
                                        GameCompatibility.perfectMatch
                                    ? theme.textTheme.labelLarge
                                    : theme.textTheme.labelLarge?.copyWith(
                                        color: ThemeManager.vanillaErrorColor,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                      csvValue: (mod) => mod
                          .findFirstEnabledOrHighestVersion
                          ?.modInfo
                          .gameVersion,
                      defaultState: WispGridColumnState(
                        position: 10,
                        width: 100,
                      ),
                    ),
                    WispGridColumn<Mod>(
                      key: ModGridHeader.firstSeen.name,
                      name: "First Seen",
                      isSortable: true,
                      getSortValue: (mod) =>
                          mod.getSortValueForFirstSeen(modsMetadata),
                      headerCellBuilder: (modifiers) => buildColumnHeader(
                        ModGridHeader.firstSeen,
                        modifiers,
                      ).child,
                      itemCellBuilder: (mod, modifiers) => Opacity(
                        opacity: WispGrid.lightTextOpacity,
                        child: Text(
                          modsMetadata
                                  ?.getMergedModMetadata(mod.id)
                                  ?.let(
                                    (m) => Constants.dateTimeFormat.format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                        m.firstSeen,
                                      ),
                                    ),
                                  ) ??
                              "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      csvValue: (mod) =>
                          modsMetadata
                              ?.getMergedModMetadata(mod.id)
                              ?.let(
                                (m) => DateTime.fromMillisecondsSinceEpoch(
                                  m.firstSeen,
                                ).toIso8601String(),
                              ) ??
                          "",
                      defaultState: WispGridColumnState(
                        position: 11,
                        width: 150,
                      ),
                    ),
                    WispGridColumn<Mod>(
                      key: ModGridHeader.lastEnabled.name,
                      name: "Last Enabled",
                      isSortable: true,
                      getSortValue: (mod) =>
                          mod.getSortValueForLastEnabled(modsMetadata),
                      headerCellBuilder: (modifiers) => buildColumnHeader(
                        ModGridHeader.lastEnabled,
                        modifiers,
                      ).child,
                      itemCellBuilder: (mod, modifiers) => Opacity(
                        opacity: WispGrid.lightTextOpacity,
                        child: Text(
                          modsMetadata
                                  ?.getMergedModMetadata(mod.id)
                                  ?.lastEnabled
                                  ?.let(
                                    (lastEnabled) =>
                                        Constants.dateTimeFormat.format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                            lastEnabled,
                                          ),
                                        ),
                                  ) ??
                              "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      csvValue: (mod) =>
                          modsMetadata
                              ?.getMergedModMetadata(mod.id)
                              ?.lastEnabled
                              ?.let(
                                (lastEnabled) =>
                                    DateTime.fromMillisecondsSinceEpoch(
                                      lastEnabled,
                                    ).toIso8601String(),
                              ) ??
                          "",
                      defaultState: WispGridColumnState(
                        position: 12,
                        width: 150,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (selectedMod != null)
          Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              width: 400,
              child: ModSummaryPanel(selectedMod, () {
                setState(() {
                  selectedMod = null;
                });
              }),
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
              foregroundColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.8),
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

  Widget buildProfileSelector(bool isGameRunning) {
    return Builder(
      builder: (context) {
        final profiles = ref.watch(modProfilesProvider).value;
        final activeProfileId = ref.watch(
          appSettings.select((s) => s.activeModProfileId),
        );
        final activeProfile = ref
            .read(modProfilesProvider.notifier)
            .getCurrentModProfile();

        return SizedBox(
          height: 36,
          child: MovingTooltipWidget.text(
            message:
                "Swap between mod loadouts. Manage them in the Profiles tab.",
            child: PopupMenuButton(
              onSelected: (profile) {
                if (profile is ModProfile) {
                  ref
                      .read(modProfilesProvider.notifier)
                      .showActivateDialog(profile, context);
                }
              },
              tooltip: "",
              borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
              initialValue: activeProfile,
              itemBuilder: (BuildContext context) {
                return profiles?.modProfiles
                        .map(
                          (p) => PopupMenuItem(
                            value: p,
                            child: Text(
                              "${p.name} (${p.enabledModVariants.length} mods)",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList() ??
                    [];
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Mod Profile",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      activeProfile?.name.truncate(20) ?? "(none)",
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(fontSize: 8),
                    ),
                  ],
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
                      return DropdownButton(
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

  Widget buildOverflowButton(List<Mod> allMods) {
    final theme = Theme.of(context);

    return MovingTooltipWidget.text(
      message: "More options",
      child: PopupMenuButton(
        tooltip: "",
        icon: const Icon(Icons.more_vert),
        itemBuilder: (context) => <PopupMenuEntry>[
          PopupMenuItem(
            onTap: () {
              ref
                  .read(appSettings.notifier)
                  .update((s) => s.copyWith(pinFavorites: !s.pinFavorites));
            },
            child: Builder(
              builder: (context) {
                final pinFavorites = ref.watch(
                  appSettings.select((s) => s.pinFavorites),
                );
                return ListTile(
                  dense: true,
                  leading: Icon(
                    pinFavorites
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  title: Text("Pin Favorited Mods to Top"),
                );
              },
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem(
            onTap: () {
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
            child: ListTile(
              dense: true,
              leading: Icon(Icons.local_fire_department),
              title: Text("Enable All Mods"),
            ),
          ),
          PopupMenuItem(
            onTap: () {
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
            child: ListTile(
              dense: true,
              leading: Icon(Icons.fire_truck),
              title: Text("Disable All Mods"),
            ),
          ),
          PopupMenuItem(
            onTap: () {
              copyModListToClipboardFromMods(
                allMods.where((mod) => mod.hasEnabledVariant).toList(),
                context,
              );
            },
            child: ListTile(
              dense: true,
              leading: Icon(Icons.copy),
              title: Text("Copy Enabled Mods to Clipboard"),
            ),
          ),
          PopupMenuItem(
            onTap: () {
              copyModListToClipboardFromMods(allMods, context);
            },
            child: ListTile(
              dense: true,
              leading: Icon(Icons.copy_all),
              title: Text("Copy All Mods to Clipboard"),
            ),
          ),
          PopupMenuItem(
            onTap: () {
              if (controller == null) return;
              showExportOrCopyDialog(
                context,
                  () => WispGridCsvExporter.toCsv(controller!, includeHeaders: true),
                null
              );
            },
            child: ListTile(
              dense: true,
              leading: Icon(Icons.table_view),
              title: Text("Export to CSV"),
            ),
          ),
        ],
      ),
    );
  }

  WispGridHeader buildColumnHeader(
    ModGridHeader header,
    HeaderBuilderModifiers modifiers,
  ) {
    // final state =
    //     ref
    //         .watch(appSettings.select((s) => s.modsGridState))
    //         .columnsState[header.name] ??
    //     WispGridColumnState(position: 0, width: 100);

    final sortField = switch (header) {
      ModGridHeader.favorites => null,
      ModGridHeader.changeVariantButton => null,
      ModGridHeader.icons => ModGridSortField.icons,
      ModGridHeader.modIcon => ModGridSortField.icons,
      ModGridHeader.loadOrder => ModGridSortField.loadOrder,
      ModGridHeader.name => ModGridSortField.name,
      ModGridHeader.author => ModGridSortField.author,
      ModGridHeader.version => ModGridSortField.version,
      ModGridHeader.updateStatus => ModGridSortField.updateStatus,
      ModGridHeader.vramImpact => ModGridSortField.vramImpact,
      ModGridHeader.tags => null,
      ModGridHeader.gameVersion => ModGridSortField.gameVersion,
      ModGridHeader.firstSeen => ModGridSortField.firstSeen,
      ModGridHeader.lastEnabled => ModGridSortField.lastEnabled,
    };

    final builder = Builder(
      builder: (context) {
        final headerTextStyle = Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold);

        return switch (header) {
          ModGridHeader.favorites => Container(),
          ModGridHeader.changeVariantButton => Container(),
          ModGridHeader.icons => Container(),
          ModGridHeader.modIcon => Container(),
          ModGridHeader.loadOrder => MovingTooltipWidget.text(
            message: ModListMini.modLoadOrderSettingExplanation,
            child: Text('Load #', style: headerTextStyle),
          ),
          ModGridHeader.name => Text('Name', style: headerTextStyle),
          ModGridHeader.author => Text('Author', style: headerTextStyle),
          ModGridHeader.updateStatus => Text('Update', style: headerTextStyle),
          ModGridHeader.version => Text('Version', style: headerTextStyle),
          ModGridHeader.vramImpact => MovingTooltipWidget.text(
            message:
                'An *estimate* of how much VRAM is used based on the images in the mod folder.'
                '\nThis may be inaccurate.',
            child: Row(
              children: [
                Text('VRAM Est.', style: headerTextStyle),
                const SizedBox(width: 4),
                MovingTooltipWidget.text(
                  message: "About VRAM & VRAM Estimator",
                  child: IconButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => VramCheckerExplanationDialog(),
                    ),
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.info_outline, size: 20),
                  ),
                ),
              ],
            ),
          ),
          ModGridHeader.gameVersion => Text(
            'Game Version',
            style: headerTextStyle,
          ),
          ModGridHeader.firstSeen => Text('First Seen', style: headerTextStyle),
          ModGridHeader.lastEnabled => Text(
            'Last Enabled',
            style: headerTextStyle,
          ),
          ModGridHeader.tags => Text('Tags', style: headerTextStyle),
        };
      },
    );

    return WispGridHeader(sortField: sortField?.name, child: builder);
  }

  Builder buildVramCell(
    double lightTextOpacity,
    Mod mod,
    WispGridColumnState state,
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final lightTextColor = theme.colorScheme.onSurface.withOpacity(
          lightTextOpacity,
        );
        final bestVersion = mod.findFirstEnabledOrHighestVersion;
        final graphicsLibConfig = ref.watch(graphicsLibConfigProvider);
        if (bestVersion == null) return const SizedBox();

        return Expanded(
          child: Builder(
            builder: (context) {
              final vramEstimatorState = ref.watch(
                AppState.vramEstimatorProvider,
              );
              final vramProvider = ref.watch(AppState.vramEstimatorProvider);
              final vramMap = vramProvider.value?.modVramInfo ?? {};
              final vramEstimate = vramMap[bestVersion.smolId];
              final biggestFish = vramMap
                  .maxBy((e) => e.value.imagesNotIncludingGraphicsLib().sum())
                  ?.value
                  .imagesNotIncludingGraphicsLib()
                  .sum();
              final ratio = biggestFish == null
                  ? 0.00
                  : (vramMap[bestVersion.smolId]
                                ?.imagesNotIncludingGraphicsLib()
                                .sum()
                                .toDouble() ??
                            0) /
                        biggestFish.toDouble();
              final withoutGraphicsLib = vramEstimate
                  ?.imagesNotIncludingGraphicsLib();

              final isIllustratedEntities =
                  mod.findFirstEnabledOrHighestVersion?.modInfo.id ==
                  Constants.illustratedEntitiesId;

              return MovingTooltipWidget.framed(
                tooltipWidget: vramEstimate == null
                    ? null
                    : IntrinsicWidth(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "VRAM Estimate",
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "${mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId} v${vramEstimate.info.version}"
                              "\n\n${withoutGraphicsLib?.sum().bytesAsReadableMB()} from mod (${withoutGraphicsLib?.length} images)"
                              "\n---"
                              "\n${withoutGraphicsLib?.sum().bytesAsReadableMB()} total"
                              "${isIllustratedEntities ? ""
                                        ""
                                        "\n\nNOTE"
                                        "\nIllustrated Entities dynamically loads and unloads images from VRAM." : ""}",
                              style: theme.textTheme.labelLarge,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Divider(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: .5,
                                ),
                              ),
                            ),
                            VramEstimatorPage.buildVramTopFilesTableWidget(
                              theme,
                              vramEstimate,
                              graphicsLibConfig,
                            ),
                          ],
                        ),
                      ),
                warningLevel: isIllustratedEntities
                    ? TooltipWarningLevel.warning
                    : null,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child:
                            vramEstimate?.imagesNotIncludingGraphicsLib() !=
                                null
                            ? Text(
                                vramEstimate!
                                    .imagesNotIncludingGraphicsLib()
                                    .sum()
                                    .bytesAsReadableMB(),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: lightTextColor,
                                ),
                              )
                            : Align(
                                alignment: Alignment.centerRight,
                                child: Opacity(
                                  opacity: 0.5,
                                  child: Disable(
                                    isEnabled:
                                        vramEstimatorState
                                            .value
                                            ?.isScanning !=
                                        true,
                                    child: MovingTooltipWidget.text(
                                      message: "Estimate VRAM usage",
                                      child: IconButton(
                                        icon: const Icon(Icons.memory),
                                        iconSize: 24,
                                        onPressed: () {
                                          ref
                                              .read(
                                                AppState
                                                    .vramEstimatorProvider
                                                    .notifier,
                                              )
                                              .startEstimating(
                                                variantsToCheck: [
                                                  mod.findFirstEnabledOrHighestVersion!,
                                                ],
                                              );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (vramEstimate != null)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: LinearProgressIndicator(
                            value: ratio.isNaN || ratio.isInfinite ? 0 : ratio,
                            backgroundColor: theme.colorScheme.surfaceContainer,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Builder _buildUpdateCell(
    double lightTextOpacity,
    Mod mod,
    bool isGameRunning,
    ModVariant bestVersion,
    WispGridColumnState state,
    ModMetadata? metadata,
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final lightTextColor = theme.colorScheme.onSurface.withOpacity(
          lightTextOpacity,
        );
        final versionCheckResultsNew = ref
            .watch(AppState.versionCheckResults)
            .value;
        //
        final versionCheckComparison = mod.updateCheck(versionCheckResultsNew);
        final localVersionCheck =
            versionCheckComparison?.variant.versionCheckerInfo;
        final remoteVersionCheck = versionCheckComparison?.remoteVersionCheck;
        final changelogUrl = ref
            .read(AppState.changelogsProvider.notifier)
            .getChangelogUrl(
              versionCheckComparison?.variant.versionCheckerInfo,
              versionCheckComparison?.remoteVersionCheck,
            );
        final areUpdatesMuted = metadata != null && metadata.areUpdatesMuted;

        return mod.modVariants.isEmpty
            ? const Text("")
            : ContextMenuRegion(
                contextMenu: ContextMenu(
                  entries: [
                    if (!areUpdatesMuted)
                      MenuItem(
                        label: 'Recheck',
                        icon: Icons.refresh,
                        onSelected: () {
                          ref
                              .read(AppState.versionCheckResults.notifier)
                              .refresh(
                                skipCache: true,
                                specificVariantsToCheck: [
                                  mod.findFirstEnabledOrHighestVersion!,
                                ],
                              );
                        },
                      ),
                    buildMenuItemToggleMuteUpdates(mod, ref),
                  ],
                ),
                child: Row(
                  children: [
                    if (changelogUrl.isNotNullOrEmpty())
                      MovingTooltipWidget(
                        tooltipWidget: SizedBox(
                          width: 400,
                          height: 400,
                          child: TooltipFrame(
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 4,
                                      top: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          child: SvgImageIcon(
                                            "assets/images/icon-bullhorn-variant.svg",
                                            color: theme.colorScheme.primary,
                                            width: 20,
                                            height: 20,
                                          ),
                                        ),
                                        Text(
                                          "Click horn to see full changelog",
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Changelogs(
                                    mod,
                                    localVersionCheck,
                                    remoteVersionCheck,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                content: Changelogs(
                                  mod,
                                  localVersionCheck,
                                  remoteVersionCheck,
                                ),
                              ),
                            );
                          },
                          child: SvgImageIcon(
                            "assets/images/icon-bullhorn-variant.svg",
                            color: theme.iconTheme.color?.withValues(
                              alpha: 0.7,
                            ),
                            width: 20,
                            height: 20,
                          ),
                        ),
                      )
                    else
                      SizedBox(width: 20),
                    (areUpdatesMuted)
                        ? MovingTooltipWidget.text(
                            message: "Updates muted",
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 4.0,
                                right: 8,
                              ),
                              child: Icon(
                                Icons.notifications_off,
                                size: 20.0,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          )
                        : MovingTooltipWidget(
                            tooltipWidget:
                                ModListBasicEntry.buildVersionCheckTextReadoutForTooltip(
                                  mod,
                                  null,
                                  versionCheckComparison?.comparisonInt,
                                  localVersionCheck,
                                  remoteVersionCheck,
                                ),
                            child: Disable(
                              isEnabled: !isGameRunning,
                              child: InkWell(
                                onTap: () {
                                  if (remoteVersionCheck?.remoteVersion !=
                                          null &&
                                      versionCheckComparison?.comparisonInt ==
                                          -1) {
                                    ref
                                        .read(downloadManager.notifier)
                                        .downloadUpdateViaBrowser(
                                          remoteVersionCheck!.remoteVersion!,
                                          activateVariantOnComplete: false,
                                          modInfo: bestVersion.modInfo,
                                        );
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        content:
                                            ModListBasicEntry.changeAndVersionCheckAlertDialogContent(
                                              mod,
                                              changelogUrl,
                                              localVersionCheck,
                                              remoteVersionCheck,
                                              versionCheckComparison
                                                  ?.comparisonInt,
                                            ),
                                      ),
                                    );
                                  }
                                },
                                onSecondaryTap: () => showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    content:
                                        ModListBasicEntry.changeAndVersionCheckAlertDialogContent(
                                          mod,
                                          changelogUrl,
                                          localVersionCheck,
                                          remoteVersionCheck,
                                          versionCheckComparison?.comparisonInt,
                                        ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                  ),
                                  child: VersionCheckIcon.fromComparison(
                                    comparison: versionCheckComparison,
                                    modId: mod.id,
                                    theme: theme,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                  // ),
                ),
              );
      },
    );
  }

  Builder _buildVersionCell(
    double lightTextOpacity,
    Mod mod,
    bool isGameRunning,
    ModVariant bestVersion,
    WispGridColumnState state,
    ModMetadata? metadata,
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final lightTextColor = theme.colorScheme.onSurface.withOpacity(
          lightTextOpacity,
        );
        final disabledVersionTextColor = lightTextColor.withOpacity(0.5);
        final enabledVersion = mod.findFirstEnabled;

        return mod.modVariants.isEmpty
            ? const Text("")
            : Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final variantsWithEnabledFirst = mod.modVariants.sorted(
                          (a, b) => a.isModInfoEnabled != b.isModInfoEnabled
                              ? (a.isModInfoEnabled ? -1 : 1)
                              : a.compareTo(b),
                        );

                        final text = RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              for (
                                var i = 0;
                                i < variantsWithEnabledFirst.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  TextSpan(
                                    text: ', ',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: disabledVersionTextColor,
                                    ),
                                  ),
                                TextSpan(
                                  text: variantsWithEnabledFirst[i]
                                      .modInfo
                                      .version
                                      .toString(),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color:
                                        enabledVersion ==
                                            variantsWithEnabledFirst[i]
                                        ? null
                                        : disabledVersionTextColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );

                        return MovingTooltipWidget.framed(
                          tooltipWidget: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: mod.modVariants
                                .sortedByDescending(
                                  (v) => v.bestVersion ?? Version.zero(),
                                )
                                .map(
                                  (v) => Text(
                                    v.bestVersion?.toString() ?? "",

                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: enabledVersion == v
                                          ? null
                                          : disabledVersionTextColor,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          child: text,
                        );
                      },
                    ),
                  ),
                ],
                // ),
              );
      },
    );
  }

  Builder buildNameCell(
    Mod mod,
    ModVariant bestVersion,
    List<Mod> allMods,
    WispGridColumnState state,
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        return TextTriOS(
          bestVersion.modInfo.name ?? "(no name)",
          style: GoogleFonts.roboto(
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  Widget buildMissingDependencyButtons(
    ModVariant? enabledVersion,
    List<Mod> allMods,
  ) {
    final modCompatibility = ref.watch(
      AppState.modCompatibility,
    )[enabledVersion?.smolId];
    final unmetDependencies =
        modCompatibility?.dependencyChecks
            .where((e) => !e.isCurrentlySatisfied)
            .toList() ??
        [];

    if (unmetDependencies.isEmpty) return Container();

    final gridState = ref.watch(appSettings.select((s) => s.modsGridState));
    final cellWidthBeforeNameColumn = gridState.columnsState.entries
        .sortedBy<num>((entry) => entry.value.position)
        .takeWhile((element) => element.key != ModGridHeader.name.name)
        .map((e) => e.value.width + WispGrid.gridRowSpacing)
        .sum;

    return Padding(
      padding: EdgeInsets.only(left: cellWidthBeforeNameColumn, bottom: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...unmetDependencies.map((checkResult) {
            return MissingDependencyButton(
              enabledVersion: enabledVersion,
              checkResult: checkResult,
              allMods: allMods,
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
  });

  final ModVariant? enabledVersion;
  final ModDependencyCheckResult checkResult;
  final List<Mod> allMods;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: const Size(60, 34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ThemeManager.cornerRadius,
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

                    return OutlinedButton(
                      onPressed: () async {
                        final modName =
                            missingDependency.formattedNameVersionId;
                        // Advanced search
                        final url = Uri.parse(
                          'https://www.google.com/search?q=starsector+$modName+download',
                        );

                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          showSnackBar(
                            context: context,
                            content: const Text(
                              "Couldn't open browser. Google recommends Chrome for a faster experience!",
                            ),
                          );
                        }
                      },
                      style: buttonStyle,
                      child: TextWithIcon(
                        text:
                            "Search ${missingDependency.formattedNameVersionId}",
                        leading: const SvgImageIcon(
                          "assets/images/icon-search.svg",
                          width: 20,
                          height: 20,
                        ),
                        leadingPadding: const EdgeInsets.only(right: 4),
                      ),
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
