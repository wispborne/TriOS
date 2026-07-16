import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/faction_viewer/faction_manager.dart';
import 'package:trios/faction_viewer/faction_viewer_controller.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/faction_viewer/spawn_weights/spawn_weight_calculator.dart';
import 'package:trios/faction_viewer/spawn_weights/spawn_weights_view.dart';
import 'package:trios/faction_viewer/spawn_weights/vanilla_share_bar.dart';
import 'package:trios/faction_viewer/widgets/faction_card.dart';
import 'package:trios/faction_viewer/widgets/faction_profile_dialog.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/collapsed_filter_button.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_widget.dart';
import 'package:trios/widgets/mode_switcher.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/smart_search/smart_search_bar.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/viewer_toolbar.dart';
import 'package:trios/widgets/trios_dropdown_menu.dart';
import 'package:trios/widgets/wisp_adaptive_grid_view.dart';

class FactionViewerPage extends ConsumerStatefulWidget {
  const FactionViewerPage({super.key});

  @override
  ConsumerState<FactionViewerPage> createState() => _FactionViewerPageState();
}

class _FactionViewerPageState extends ConsumerState<FactionViewerPage>
    with AutomaticKeepAliveClientMixin<FactionViewerPage> {
  @override
  bool get wantKeepAlive => true;

  final _filterScrollController = ScrollController();
  WispGridController<Faction>? _gridController;

  @override
  void dispose() {
    _filterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controllerState = ref.watch(factionViewerControllerProvider);
    final controller = ref.watch(factionViewerControllerProvider.notifier);
    final isLoading = ref.watch(isLoadingFactionsList);
    final gameCoreDir = ref.watch(AppState.gameCoreFolder).value;

    final filterRequest = ref.watch(AppState.viewerFilterRequest);
    if (filterRequest != null &&
        filterRequest.destination == TriOSTools.factions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(factionViewerControllerProvider.notifier).setChipSelections(
          'source',
          {filterRequest.modName: true},
        );
        ref.read(AppState.viewerFilterRequest.notifier).state = null;
      });
    }

    return Column(
      children: [
        ViewerToolbar(
          entityName: 'factions',
          total: controllerState.allFactions.length,
          visible: controllerState.filteredFactions.length,
          isLoading: isLoading,
          onRefresh: () => ref.invalidate(factionListNotifierProvider),
          searchBox: SmartSearchBar(
            fields: controller.searchFieldsMeta,
            recentHistory: ref.watch(
              appSettings.select((s) => s.factionSearchHistory),
            ),
            initialValue: controllerState.searchQuery,
            hintText:
                controllerState.viewMode == FactionViewMode.spawnWeights
                ? 'Search ships...'
                : 'Search factions...',
            onChanged: (query) => ref
                .read(factionViewerControllerProvider.notifier)
                .updateSearchQuery(query),
            onSubmitted: () => ref
                .read(factionViewerControllerProvider.notifier)
                .submitSearchQuery(),
          ),
          leadingActions: [
            if (controllerState.viewMode == FactionViewMode.gallery)
              _buildGallerySortDropdown(controller, controllerState),
          ],
          trailingActions: [_buildViewModeToggle(controller, controllerState)],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFiltersSection(controllerState, controller),
              Expanded(
                child: controllerState.filteredFactions.isEmpty && !isLoading
                    ? const Center(child: Text('No factions found.'))
                    : switch (controllerState.viewMode) {
                        FactionViewMode.grid => _buildGrid(
                          controllerState,
                          gameCoreDir,
                          Theme.of(context),
                        ),
                        FactionViewMode.spawnWeights => SpawnWeightsView(
                          factions: controllerState.filteredFactions,
                          searchQuery: controllerState.searchQuery,
                        ),
                        FactionViewMode.gallery => _buildGallery(
                          controllerState,
                          gameCoreDir,
                        ),
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySortDropdown(
    FactionViewerController controller,
    FactionViewerState state,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: TriOSDropdownMenu<FactionGallerySortField>(
            initialSelection: state.gallerySortField,
            onSelected: (value) {
              controller.setGallerySortField(
                value ?? FactionGallerySortField.ships,
              );
            },
            dropdownMenuEntries: FactionGallerySortField.values
                .map(
                  (field) =>
                      DropdownMenuEntry(value: field, label: field.label),
                )
                .toList(),
          ),
        ),
        MovingTooltipWidget.text(
          message: state.gallerySortAscending ? 'Ascending' : 'Descending',
          child: IconButton(
            icon: Icon(
              state.gallerySortAscending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 20,
            ),
            onPressed: controller.toggleGallerySortDirection,
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeToggle(
    FactionViewerController controller,
    FactionViewerState state,
  ) {
    return ModeSwitcher<FactionViewMode>(
      selected: state.viewMode,
      onChanged: controller.setViewMode,
      modes: const {
        FactionViewMode.gallery: 'Cards',
        FactionViewMode.grid: 'Grid',
        FactionViewMode.spawnWeights: 'Spawn weights',
      },
      modeIcons: const {
        FactionViewMode.gallery: Icon(Icons.grid_view, size: 18),
        FactionViewMode.grid: Icon(Icons.view_list, size: 18),
        FactionViewMode.spawnWeights: Icon(Icons.balance, size: 18),
      },
    );
  }

  Widget _buildFiltersSection(
    FactionViewerState controllerState,
    FactionViewerController controller,
  ) {
    if (!controllerState.showFilters) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, top: 4),
        child: CollapsedFilterButton(
          onTap: controller.toggleShowFilters,
          activeFilterCount: controller.activeFilterCount,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8),
      child: FiltersPanel(
        onHide: controller.toggleShowFilters,
        scrollController: _filterScrollController,
        activeFilterCount: controller.activeFilterCount,
        showClearAll: controller.filterGroups.any((g) => g.isActive),
        onClearAll: controller.clearAllFilters,
        filterWidgets: [
          for (final g in controller.filterGroups)
            FilterGroupRenderer<Faction>(
              group: g,
              scope: controller.scope,
              items: controllerState.allFactions,
              onChanged: () => controller.onGroupChanged(g.id),
            ),
        ],
      ),
    );
  }

  Widget _buildGallery(FactionViewerState state, Directory? gameCoreDir) {
    final sortedFactions = FactionViewerController.sortForGallery(
      state.filteredFactions,
      state.gallerySortField,
      state.gallerySortAscending,
    );
    return WispAdaptiveGridView<Faction>(
      items: sortedFactions,
      minItemWidth: 280,
      horizontalSpacing: 8,
      verticalSpacing: 8,
      padding: .all(8),
      itemBuilder: (context, faction, index) {
        return SizedBox(
          height: 168,
          child: _buildRowContextMenu(
            faction,
            gameCoreDir,
            FactionCard(
              faction: faction,
              gameCoreDir: gameCoreDir,
              onTap: () => _showProfile(context, faction, gameCoreDir),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(
    FactionViewerState state,
    Directory? gameCoreDir,
    ThemeData theme,
  ) {
    final gridState = ref.watch(appSettings.select((s) => s.factionsGridState));
    final summaries = ref.watch(factionSpawnSummariesProvider);
    final columns = _buildColumns(theme, gameCoreDir, summaries);

    return DefaultTextStyle.merge(
      style: theme.textTheme.labelLarge!.copyWith(fontSize: 14),
      child: WispGrid<Faction>(
        gridState: gridState,
        updateGridState: (updateFn) {
          ref.read(appSettings.notifier).update((s) {
            return s.copyWith(
              factionsGridState:
                  updateFn(s.factionsGridState) ?? Settings().factionsGridState,
            );
          });
        },
        onLoaded: (controller) {
          _gridController = controller;
        },
        columns: columns,
        items: state.filteredFactions,
        itemExtent: 40,
        scrollbarConfig: ScrollbarConfig(
          showLeftScrollbar: ScrollbarVisibility.always,
          showRightScrollbar: ScrollbarVisibility.always,
          showBottomScrollbar: ScrollbarVisibility.always,
        ),
        rowBuilder: ({required item, required modifiers, required child}) =>
            SizedBox(
              height: 40,
              child: InkWell(
                onTap: () => _showProfile(context, item, gameCoreDir),
                child: Container(
                  color: Colors.transparent,
                  child: _buildRowContextMenu(item, gameCoreDir, child),
                ),
              ),
            ),
        groups: [UngroupedFactionGridGroup(), SourceFactionGridGroup()],
      ),
    );
  }

  List<WispGridColumn<Faction>> _buildColumns(
    ThemeData theme,
    Directory? gameCoreDir,
    Map<String, FactionSpawnSummary> summaries,
  ) {
    int position = 0;

    WispGridColumn<Faction> col(
      String key,
      String name,
      Comparable<dynamic>? Function(Faction) getValue, {
      double width = 100,
    }) {
      return WispGridColumn<Faction>(
        key: key,
        isSortable: true,
        name: name,
        getSortValue: getValue,
        itemCellBuilder: (item, _) {
          final value = getValue(item);
          final str = value?.toString() ?? '';
          return TextTriOS(str, maxLines: 1, overflow: TextOverflow.ellipsis);
        },
        csvValue: (item) => getValue(item)?.toString(),
        defaultState: WispGridColumnState(position: position++, width: width),
      );
    }

    return [
      WispGridColumn<Faction>(
        key: 'logo',
        isSortable: false,
        name: '',
        itemCellBuilder: (item, _) {
          final logoPath = _resolveImagePath(item, item.logo, gameCoreDir);
          if (logoPath == null) {
            return const SizedBox(
              width: 32,
              height: 32,
              child: Center(child: Icon(Icons.flag, size: 16)),
            );
          }
          return Image.file(
            File(logoPath),
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox(
              width: 32,
              height: 32,
              child: Center(child: Icon(Icons.flag, size: 16)),
            ),
          );
        },
        csvValue: (item) => item.logo,
        defaultState: WispGridColumnState(position: position++, width: 48),
      ),
      WispGridColumn<Faction>(
        key: 'name',
        isSortable: true,
        name: 'Name',
        getSortValue: (f) => f.displayName.toLowerCase(),
        itemCellBuilder: (item, _) => TextTriOS(
          item.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        csvValue: (item) => item.displayName,
        defaultState: WispGridColumnState(position: position++, width: 150),
      ),
      WispGridColumn<Faction>(
        key: 'color',
        isSortable: true,
        name: 'Color',
        getSortValue: (f) {
          final c = f.color;
          // Sort by RGB value so similar colors group together.
          return c[0] * 65536 + c[1] * 256 + (c.length > 2 ? c[2] : 0);
        },
        itemCellBuilder: (item, _) {
          final color = item.factionColor;
          return Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        },
        csvValue: (item) => item.color.join(','),
        defaultState: WispGridColumnState(position: position++, width: 60),
      ),
      col('warships', 'Warships', (f) => f.doctrine?.warships, width: 80),
      col('carriers', 'Carriers', (f) => f.doctrine?.carriers, width: 80),
      col('phase', 'Phase', (f) => f.doctrine?.phaseShips, width: 70),
      col('aggression', 'Aggression', (f) => f.doctrine?.aggression, width: 90),
      col(
        'shipQuality',
        'Ship Quality',
        (f) => f.doctrine?.shipQuality,
        width: 100,
      ),
      col(
        'officerQuality',
        'Officer Quality',
        (f) => f.doctrine?.officerQuality,
        width: 110,
      ),
      col('knownShips', 'Ships', (f) => f.knownShipIds.length, width: 70),
      col('knownWeapons', 'Weapons', (f) => f.knownWeaponIds.length, width: 80),
      WispGridColumn<Faction>(
        key: 'vanillaSpawn',
        isSortable: true,
        name: 'Vanilla %',
        // Factions with no warships sort below the ones that have them.
        getSortValue: (f) => summaries[f.mergeKey]?.vanillaShare ?? -1,
        itemCellBuilder: (item, _) {
          final summary =
              summaries[item.mergeKey] ?? FactionSpawnSummary.empty;
          final share = summary.vanillaShare;
          return MovingTooltipWidget.text(
            message: vanillaShareTooltip(summary),
            child: TextTriOS(
              share == null ? '—' : formatShare(share),
              maxLines: 1,
            ),
          );
        },
        csvValue: (item) {
          final share = summaries[item.mergeKey]?.vanillaShare;
          return share == null ? '' : formatShare(share);
        },
        defaultState: WispGridColumnState(position: position++, width: 90),
      ),
      WispGridColumn<Faction>(
        key: 'source',
        isSortable: true,
        name: 'Added by',
        getSortValue: (f) => (f.addedBy?.name ?? '').toLowerCase(),
        itemCellBuilder: (item, _) => MovingTooltipWidget.text(
          message: item.attributionTooltip,
          child: TextTriOS(
            item.addedBy?.name ??
                (item.sources.isEmpty ? '' : 'Patch only'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        csvValue: (item) => item.addedBy?.name ?? '',
        defaultState: WispGridColumnState(position: position++, width: 120),
      ),
    ];
  }

  Widget _buildRowContextMenu(
    Faction faction,
    Directory? gameCoreDir,
    Widget child,
  ) {
    final primarySource = faction.addedBy ?? faction.sources.firstOrNull;
    final folder = primarySource?.modVariant is ModVariant
        ? (primarySource!.modVariant as ModVariant).modFolder
        : gameCoreDir;
    final factionFile = folder != null
        ? File(
            p.join(
              folder.path,
              'data',
              'world',
              'factions',
              '${faction.mergeKey}.faction',
            ),
          )
        : null;

    return ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: <ContextMenuEntry>[
          MenuItem(
            label: 'Copy ID',
            icon: Icons.copy,
            onSelected: () =>
                Clipboard.setData(ClipboardData(text: faction.id)),
          ),
          if (factionFile != null && factionFile.existsSync())
            MenuItem(
              label: 'Open .faction file',
              icon: Icons.edit_note,
              onSelected: () => factionFile.absolute.showInExplorer(),
            ),
          if (factionFile != null && factionFile.existsSync())
            buildOpenSingleFolderMenuItem(
              factionFile.parent,
              label: 'Open faction folder',
            ),
          if (primarySource?.modVariant is ModVariant)
            buildOpenSingleFolderMenuItem(
              (primarySource!.modVariant as ModVariant).modFolder.absolute,
              label: 'Open Mod Folder',
            ),
        ],
        padding: const EdgeInsets.all(8.0),
      ),
      child: Container(color: Colors.transparent, child: child),
    );
  }

  String? _resolveImagePath(
    Faction faction,
    String? relativePath,
    Directory? gameCoreDir,
  ) {
    if (relativePath == null) return null;
    for (final source in faction.sources.reversed) {
      final baseDir = source.modVariant is ModVariant
          ? (source.modVariant as ModVariant).modFolder
          : gameCoreDir;
      if (baseDir == null) continue;
      final fullPath = p.join(baseDir.path, relativePath);
      if (File(fullPath).existsSync()) return fullPath;
    }
    return null;
  }

  void _showProfile(
    BuildContext context,
    Faction faction,
    Directory? gameCoreDir,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          FactionProfileDialog(faction: faction, gameCoreDir: gameCoreDir),
    );
  }
}

class UngroupedFactionGridGroup extends WispGridGroup<Faction> {
  UngroupedFactionGridGroup() : super('none', 'None');

  @override
  String getGroupName(Faction item, {Comparable? groupSortValue}) =>
      'All Factions';

  @override
  Comparable getGroupSortValue(Faction item) => 1;

  @override
  bool get isGroupVisible => false;
}

class SourceFactionGridGroup extends WispGridGroup<Faction> {
  SourceFactionGridGroup() : super('source', 'Added by');

  @override
  String getGroupName(Faction item, {Comparable? groupSortValue}) =>
      item.addedBy?.name ??
      (item.sources.isEmpty ? 'Unknown' : 'Patch only');

  @override
  Comparable getGroupSortValue(Faction item) =>
      item.addedBy?.name.toLowerCase() ?? '';
}
