import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/shipViewer/ship_manager.dart';
import 'package:trios/shipViewer/ships_page_controller.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/collapsed_filter_button.dart';
import 'package:trios/widgets/export_to_csv_dialog.dart';
import 'package:trios/widgets/filter_widget.dart';
import 'package:trios/widgets/ingame_ship_tooltip.dart';
import 'package:trios/widgets/ingame_weapon_tooltip.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/overflow_menu_button.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/trios_dropdown_menu.dart';
import 'package:trios/widgets/viewer_search_box.dart';
import 'package:trios/widgets/viewer_split_pane.dart';
import 'package:trios/widgets/viewer_toolbar.dart';

import '../trios/navigation.dart';
import '../widgets/multi_split_mixin_view.dart';
import 'ship_module_resolver.dart';
import 'widgets/ship_sprite_composite.dart';
import 'widgets/ship_weapon_slot_overlay.dart';

class ShipsPage extends ConsumerStatefulWidget {
  const ShipsPage({super.key});

  @override
  ConsumerState<ShipsPage> createState() => _ShipsPageState();
}

class _ShipsPageState extends ConsumerState<ShipsPage>
    with AutomaticKeepAliveClientMixin<ShipsPage>, MultiSplitViewMixin {
  @override
  bool get wantKeepAlive => true;

  final SearchController _searchController = SearchController();

  WispGridController<Ship>? _gridController;
  Widget? _cachedBuild;

  /// Cache resolved modules per ship ID to avoid recomputing on every build.
  final _resolvedModulesCache = <String, List<ResolvedModule>>{};

  @override
  List<Area> get areas {
    final controllerState = ref.read(shipsPageControllerProvider);
    return controllerState.splitPane
        ? [Area(id: 'top'), Area(id: 'bottom')]
        : [Area(id: 'top')];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isActive =
        ref.watch(appSettings.select((s) => s.defaultTool)) == TriOSTools.ships;
    if (!isActive && _cachedBuild != null) return _cachedBuild!;

    final controller = ref.watch(shipsPageControllerProvider.notifier);
    final controllerState = ref.watch(shipsPageControllerProvider);
    final theme = Theme.of(context);
    final mods = ref.watch(AppState.mods);

    // Apply pending mod filter from context menu navigation.
    final filterRequest = ref.watch(AppState.viewerFilterRequest);
    if (filterRequest != null &&
        filterRequest.destination == TriOSTools.ships) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final modFilter = ref
            .read(shipsPageControllerProvider)
            .filterCategories
            .firstWhereOrNull((f) => f.name == 'Mod');
        if (modFilter != null) {
          ref.read(shipsPageControllerProvider.notifier).updateFilterStates(
            modFilter,
            {filterRequest.modName: true},
          );
        }
        ref.read(AppState.viewerFilterRequest.notifier).state = null;
      });
    }

    final columns = buildCols(theme, controllerState);
    final total = controllerState.allShips.length;
    final visible = controllerState.filteredShips.length;

    final result = Column(
      children: [
        _buildToolbar(
          context,
          theme,
          total,
          visible,
          controller,
          controllerState,
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFiltersSection(
                theme,
                controllerState,
                controller,
                controllerState.shipsBeforeGridFilter,
              ),
              Expanded(
                child: _buildGridSection(
                  theme,
                  controllerState,
                  columns,
                  controllerState.filteredShips,
                  mods,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    _cachedBuild = result;
    return result;
  }

  Widget _buildToolbar(
    BuildContext context,
    ThemeData theme,
    int total,
    int visible,
    ShipsPageController controller,
    ShipsPageState controllerState,
  ) {
    return ViewerToolbar(
      entityName: "Ships",
      total: total,
      visible: visible,
      isLoading: controllerState.isLoading,
      onRefresh: () => ref.invalidate(shipListNotifierProvider),
      searchBox: ViewerSearchBox(
        searchController: _searchController,
        hintText: "Filter ships...",
        onChanged: (query) => ref
            .read(shipsPageControllerProvider.notifier)
            .updateSearchQuery(query),
        onClear: () => ref
            .read(shipsPageControllerProvider.notifier)
            .updateSearchQuery(''),
      ),
      splitPane: controllerState.splitPane,
      onToggleSplitPane: () {
        controller.toggleSplitPane();
        multiSplitController.areas = areas;
        setState(() {});
      },
      trailingActions: [
        _buildOverflowButton(
          context: context,
          theme: theme,
          controllerState: controllerState,
        ),
      ],
    );
  }

  Widget _buildFiltersSection(
    ThemeData theme,
    ShipsPageState controllerState,
    ShipsPageController controller,
    List<Ship> shipsBeforeFilter,
  ) {
    if (!controllerState.showFilters) {
      return CollapsedFilterButton(
        onTap: controller.toggleShowFilters,
        activeFilterCount: controller.activeFilterCount,
      );
    }

    return buildFilterPanel(
      theme,
      shipsBeforeFilter,
      controllerState,
      controller,
    );
  }

  Widget _buildGridSection(
    ThemeData theme,
    ShipsPageState controllerState,
    List<WispGridColumn<Ship>> columns,
    List<Ship> ships,
    List<Mod> mods,
  ) {
    return ViewerSplitPane(
      controller: multiSplitController,
      gridBuilder: (areaId) {
        switch (areaId) {
          case 'top':
            return buildGrid(columns, ships, mods, true, theme);
          case 'bottom':
            return buildGrid(columns, ships, mods, false, theme);
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  FiltersPanel buildFilterPanel(
    ThemeData theme,
    List<Ship> displayedShips,
    ShipsPageState controllerState,
    ShipsPageController controller,
  ) {
    return FiltersPanel(
      onHide: controller.toggleShowFilters,
      activeFilterCount: controller.activeFilterCount,
      showClearAll: controllerState.filterCategories.any(
        (f) => f.hasActiveFilters,
      ),
      onClearAll: controller.clearAllFilters,
      filterWidgets: [
        _buildCheckboxFilters(theme, controllerState, controller),
        const SizedBox(height: 8),
        ...controllerState.filterCategories.map((filter) {
          return GridFilterWidget(
            filter: filter,
            items: displayedShips,
            filterStates: filter.filterStates,
            onSelectionChanged: (states) {
              controller.updateFilterStates(filter, states);
            },
          );
        }),
      ],
    );
  }

  Widget _buildCheckboxFilters(
    ThemeData theme,
    ShipsPageState controllerState,
    ShipsPageController controller,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const .all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MovingTooltipWidget.text(
              message: "Only show ships from enabled mods.",
              child: CheckboxListTile(
                title: const Text('Only Enabled Mods'),
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: .only(left: 8),
                value: controllerState.showEnabled,
                onChanged: (value) => controller.toggleShowEnabled(),
              ),
            ),
            const SizedBox(height: 8),
            TriOSDropdownMenu<SpoilerLevel>(
              initialSelection: controllerState.spoilerLevelToShow,
              onSelected: (level) {
                if (level == null) return;
                controller.setShowSpoilers(level);
              },
              highlightOutlineColor:
                  controllerState.spoilerLevelToShow !=
                      SpoilerLevel.showAllSpoilers
                  ? theme.colorScheme.primary
                  : null,
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  value: SpoilerLevel.showNone,
                  label: "No Spoilers",
                  labelWidget: MovingTooltipWidget.text(
                    message: "No spoilers shown at all.",
                    child: Text("No Spoilers"),
                  ),
                  leadingIcon: const Icon(Icons.visibility_off, size: 20),
                ),
                DropdownMenuEntry(
                  value: SpoilerLevel.showSlightSpoilers,
                  label: "Show slight spoilers",
                  labelWidget: MovingTooltipWidget.text(
                    warningLevel: TooltipWarningLevel.warning,
                    message: "Shows CODEX_UNLOCKABLE ships.",
                    child: Text("Show slight spoilers"),
                  ),
                  leadingIcon: const Icon(Icons.visibility, size: 20),
                ),
                DropdownMenuEntry(
                  value: SpoilerLevel.showAllSpoilers,
                  label: "Show all spoilers",
                  labelWidget: MovingTooltipWidget.text(
                    warningLevel: TooltipWarningLevel.error,
                    message:
                        "Show all spoilers, including HIDE_IN_CODEX and certain ultra-redacted vanilla tagged ships",
                    child: Text("Show all spoilers"),
                  ),
                  leadingIcon: const Icon(Icons.visibility_outlined, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildGrid(
    List<WispGridColumn<Ship>> columns,
    List<Ship> items,
    List<Mod> mods,
    bool isTop,
    ThemeData theme,
  ) {
    final gridState = ref.watch(appSettings.select((s) => s.shipsGridState));

    return WispGrid<Ship>(
      gridState: gridState,
      updateGridState: (updateFn) {
        ref.read(appSettings.notifier).update((state) {
          // I'm not a hack you're a hack
          return state.copyWith(
            shipsGridState:
                updateFn(state.shipsGridState) ?? Settings().shipsGridState,
          );
        });
      },
      onLoaded: (controller) {
        _gridController = controller;
      },
      columns: columns,
      items: items,
      itemExtent: 48,
      scrollbarConfig: ScrollbarConfig(
        showLeftScrollbar: ScrollbarVisibility.always,
        showRightScrollbar: ScrollbarVisibility.always,
        showBottomScrollbar: ScrollbarVisibility.always,
      ),
      rowBuilder: ({required item, required modifiers, required child}) =>
          Padding(
            padding: const .only(top: 4),
            child: SizedBox(
              height: 40,
              child: InkWell(
                onTap: () => _showShipDetailsDialog(context, item),
                child: Container(
                  color: Colors.transparent,
                  child: buildRowContextMenu(item, child),
                ),
              ),
            ),
          ),
      groups: [UngroupedShipGridGroup(), ModShipGridGroup()],
    );
  }

  Widget buildRowContextMenu(Ship ship, Widget child) {
    final controller = ref.read(shipsPageControllerProvider.notifier);
    final gameCoreDir = controller.getGameCoreDir();

    return ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: <ContextMenuEntry>[
          if (ship.dataFile != null)
            MenuItem(
              label: 'Open ${ship.isSkin ? '.skin' : '.ship'} file',
              icon: Icons.edit_note,
              onSelected: () {
                ship.dataFile!.absolute.showInExplorer();
              },
            ),
          MenuItem(
            label: 'Open ship_data.csv',
            icon: Icons.edit_note,
            onSelected: () {
              ship.csvFile.absolute.showInExplorer();
            },
          ),
          buildOpenSingleFolderMenuItem(
            _getPathForSpriteName(ship, gameCoreDir).parent,
          ),
          if (ship.modVariant != null)
            buildOpenSingleFolderMenuItem(
              ship.modVariant!.modFolder.absolute,
              label: 'Open Mod Folder',
            ),
          if (ship.modVariant != null)
            buildMenuItemOpenForumPage(ship.modVariant!, context),
        ],
        padding: const EdgeInsets.all(8.0),
      ),
      // Container needed to add hit detection to the non-Text parts of the row.
      child: Container(color: Colors.transparent, child: child),
    );
  }

  List<WispGridColumn<Ship>> buildCols(
    ThemeData theme,
    ShipsPageState controllerState,
  ) {
    int position = 0;
    final controller = ref.read(shipsPageControllerProvider.notifier);
    final gameCoreDir = controller.getGameCoreDir();

    String shipValueToString(
      Comparable<dynamic>? Function(Ship) getValue,
      Ship item,
    ) {
      final value = getValue(item);
      final str = switch (value) {
        double dbl => dbl.toStringMinimizingDigits(2),
        null => "",
        _ => value.toString(),
      };
      return str;
    }

    // Reusable helper
    WispGridColumn<Ship> col(
      String key,
      String name,
      Comparable<dynamic>? Function(Ship) getValue, {
      double width = 100,
    }) {
      return WispGridColumn<Ship>(
        key: key,
        isSortable: true,
        name: name,
        getSortValue: getValue,
        itemCellBuilder: (item, _) {
          String str = shipValueToString(getValue, item);
          return TextTriOS(str, maxLines: 1, overflow: TextOverflow.ellipsis);
        },
        csvValue: (item) => shipValueToString(getValue, item),
        defaultState: WispGridColumnState(position: position++, width: width),
      );
    }

    return [
      WispGridColumn(
        key: 'info',
        name: '',
        isSortable: false,
        itemCellBuilder: (item, _) => MovingTooltipWidget.framed(
          tooltipWidget: CtrlSwappedTooltip(
            ctrlBuilder: (ctx) => ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  child: _buildShipInfoPane(item, theme, controllerState),
                ),
              ),
            ),
            defaultBuilder: (ctx) => ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IngameShipTooltip.buildShipContent(
                  item,
                  controllerState.shipSystemsMap,
                  controllerState.weaponsMap,
                  ctx,
                ),
              ),
            ),
          ),
          child: Icon(
            Icons.info,
            size: 24,
            color: theme.iconTheme.color?.withAlpha(200),
          ),
        ),
        csvValue: (ship) => null,
        defaultState: WispGridColumnState(position: position++, width: 32),
      ),
      WispGridColumn(
        key: 'modVariant',
        isSortable: true,
        name: 'Mod',
        getSortValue: (ship) => ship.modVariant?.modInfo.nameOrId,
        itemCellBuilder: (item, _) => TextTriOS(
          item.modVariant?.modInfo.nameOrId ?? "Vanilla",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        csvValue: (ship) => ship.modVariant?.modInfo.nameOrId,
        defaultState: WispGridColumnState(position: position++, width: 120),
      ),
      WispGridColumn(
        key: 'sprite',
        name: '',
        isSortable: false,
        itemCellBuilder: (item, _) => ShipImageCell(
          imagePath: _getPathForSpriteName(item, gameCoreDir).path,
          fit: controllerState.useContainFit
              ? BoxFit.contain
              : BoxFit.scaleDown,
        ),
        csvValue: (ship) => _getPathForSpriteName(ship, gameCoreDir).path,
        defaultState: WispGridColumnState(position: position++, width: 50),
      ),
      WispGridColumn<Ship>(
        key: 'hullName',
        isSortable: true,
        name: 'Name',
        getSortValue: (ship) => ship.hullNameForDisplay(),
        itemCellBuilder: (item, _) => Row(
          children: [
            TextTriOS(
              item.hullNameForDisplay(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.isSkin)
              Padding(
                padding: const .only(left: 8, top: 3),
                child: Container(
                  padding: const .symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: MovingTooltipWidget.text(
                    message:
                        "This ship comes from a .skin file."
                        "\nSkins are variations of standard hulls. For example, the Falcon (P) is a skin of the Falcon.",
                    child: Text(
                      'Skin',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        csvValue: (item) => item.hullNameForDisplay(),
        defaultState: WispGridColumnState(position: position++, width: 200),
      ),
      col('hullSize', 'Hull', (s) => s.hullSizeForDisplay(), width: 80),
      WispGridColumn(
        key: 'weaponSlotCount',
        name: 'Wpns',
        isSortable: true,
        getSortValue: (ship) => ship.mountableWeaponSlotCount,
        itemCellBuilder: (item, _) => Text('${item.mountableWeaponSlotCount}'),
        csvValue: (ship) => ship.mountableWeaponSlotCount.toString(),
        defaultState: WispGridColumnState(position: position++, width: 120),
      ),
      col('techManufacturer', 'Tech', (s) => s.techManufacturer, width: 220),
      ...[
        col('designation', 'Designation', (s) => s.designation),
        col(
          'systemId',
          'System',
          (s) =>
              controllerState.shipSystemsMap[s.systemId ?? ""]?.name ??
              s.systemId,
        ),
        col('fleetPts', 'Fleet Pts', (s) => s.fleetPts),
        col('hitpoints', 'Hitpoints', (s) => s.hitpoints),
        col('armorRating', 'Armor', (s) => s.armorRating),
        col('maxFlux', 'Max Flux', (s) => s.maxFlux),
        col('fluxDissipation', 'Flux Diss', (s) => s.fluxDissipation),
        col('ordnancePoints', 'Ordnance', (s) => s.ordnancePoints),
        col('fighterBays', 'Fighter Bays', (s) => s.fighterBays),
        col('maxSpeed', 'Max Speed', (s) => s.maxSpeed),
        col('acceleration', 'Accel', (s) => s.acceleration),
        col('deceleration', 'Decel', (s) => s.deceleration),
        col('maxTurnRate', 'Turn Rate', (s) => s.maxTurnRate),
        col('turnAcceleration', 'Turn Accel', (s) => s.turnAcceleration),
        col('mass', 'Mass', (s) => s.mass),
        col('shieldType', 'Shield', (s) => s.shieldType?.toTitleCase()),
        col(
          'defenseId',
          'Defense ID',
          (s) =>
              controllerState.shipSystemsMap[s.defenseId ?? ""]?.name ??
              s.defenseId,
        ),
        col('shieldArc', 'Shield Arc', (s) => s.shieldArc),
        col('shieldUpkeep', 'Shield Upkeep', (s) => s.shieldUpkeep),
        col('shieldEfficiency', 'Shield Eff.', (s) => s.shieldEfficiency),
        col('phaseCost', 'Phase Cost', (s) => s.phaseCost),
        col('phaseUpkeep', 'Phase Upkeep', (s) => s.phaseUpkeep),
        col('minCrew', 'Min Crew', (s) => s.minCrew),
        col('maxCrew', 'Max Crew', (s) => s.maxCrew),
        col('cargo', 'Cargo', (s) => s.cargo),
        col('fuel', 'Fuel', (s) => s.fuel),
        col('fuelPerLY', 'Fuel/LY', (s) => s.fuelPerLY),
        col('range', 'Range', (s) => s.range),
        col('maxBurn', 'Max Burn', (s) => s.maxBurn),
        col('baseValue', 'Credits (base)', (s) => s.baseValue.asCredits()),
        col('crPercentPerDay', 'CR%/Day', (s) => s.crPercentPerDay),
        col('crToDeploy', 'CR to Deploy', (s) => s.crToDeploy),
        col('peakCrSec', 'PPT', (s) => s.peakCrSec),
        col('crLossPerSec', 'CR Loss/Sec', (s) => s.crLossPerSec),
        col('supplyCostPerMonth', 'Supplies/Mon', (s) => s.suppliesMo),
        col('suppliesRec', 'Supplies/Rec', (s) => s.suppliesRec),
        col('rarity', 'Rarity', (s) => s.rarity),
        col('breakProb', 'Break Prob', (s) => s.breakProb),
        col('minPieces', 'Min Pieces', (s) => s.minPieces),
        col('maxPieces', 'Max Pieces', (s) => s.maxPieces),
        col('travelDrive', 'Travel Drive', (s) => s.travelDrive),
        col('number', 'Number', (s) => s.number),
        col('style', 'Style', (s) => s.style?.toTitleCase()),
      ],
    ];
  }

  Directory _getPathForSpriteName(Ship item, Directory gameCoreDir) {
    return (item.modVariant == null ? gameCoreDir : item.modVariant!.modFolder)
        .resolve(item.spriteName ?? "")
        .toDirectory();
  }

  Widget _buildOverflowButton({
    required BuildContext context,
    required ThemeData theme,
    required ShipsPageState controllerState,
  }) {
    final controller = ref.read(shipsPageControllerProvider.notifier);
    return OverflowMenuButton(
      menuItems: [
        OverflowMenuItem(
          title: 'Export to CSV',
          icon: Icons.table_view,
          onTap: () {
            if (_gridController == null) return;

            showExportOrCopyDialog(
              context,
              "ship",
              () => WispGridCsvExporter.toCsv(
                _gridController!,
                includeHeaders: true,
              ),
              () => ref.read(shipListNotifierProvider.notifier).allShipsAsCsv(),
            );
          },
        ).toEntry(0),
        OverflowMenuCheckItem(
          title: 'Stretch icons to fit',
          icon: Icons.fit_screen,
          checked: controllerState.useContainFit,
          onTap: () => controller.toggleUseContainFit(),
        ).toEntry(1),
      ],
    );
  }

  void _showShipDetailsDialog(BuildContext context, Ship s) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildShipInfoPane(
                      s,
                      theme,
                      ref.read(shipsPageControllerProvider),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShipInfoPane(
    Ship s,
    ThemeData theme,
    ShipsPageState controllerState,
  ) {
    final controller = ref.read(shipsPageControllerProvider.notifier);
    final gameCoreDir = controller.getGameCoreDir();
    final spriteDir = _getPathForSpriteName(s, gameCoreDir);

    // Resolve station modules for this ship (cached per ship ID).
    final modules = _resolvedModulesCache.putIfAbsent(s.id, () {
      final allShips = ref.read(shipListNotifierProvider).valueOrNull ?? [];
      final variants = ref.read(moduleVariantsProvider);
      final variantHullIds = ref.read(variantHullIdMapProvider);
      return resolveModules(s, allShips, variants, variantHullIds);
    });

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    s.hullNameForDisplay(),
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(s.id, style: theme.textTheme.labelSmall),
                  if (s.isSkin && s.baseHullId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        spacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Skin',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          Text(
                            'of ${controllerState.hullNameById(s.baseHullId!)}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if ((spriteDir.path).isNotEmpty)
              GestureDetector(
                onTap: () => spriteDir.toFile().showInExplorer(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MovingTooltipWidget.image(
                      path: spriteDir.path,
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: modules.isEmpty
                            ? Image.file(
                                File(spriteDir.path),
                                fit: BoxFit.contain,
                              )
                            : ShipSpriteComposite(
                                ship: s,
                                modules: modules,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 80,
                      child: TextTriOS(
                        spriteDir.path.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (s.weaponSlots != null &&
            s.weaponSlots!.isNotEmpty &&
            s.spriteFile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ShipWeaponSlotOverlay(ship: s, modules: modules),
          ),
        Divider(color: Theme.of(context).colorScheme.outline),
        _kv(
          s.modVariant != null ? 'Mod' : null,
          s.modVariant?.modInfo.nameOrId ?? 'Vanilla',
          theme,
        ),
        _kv('Hull Size', s.hullSizeForDisplay(), theme),
        _kv('Designation', s.designation, theme),
        _kv('Style', s.style?.toTitleCase(), theme),
        _kv(
          'System',
          controllerState.shipSystemsMap[s.systemId ?? ""]?.name ?? s.systemId,
          theme,
        ),
        _kv(
          'Defense',
          controllerState.shipSystemsMap[s.defenseId ?? ""]?.name ??
              s.defenseId,
          theme,
        ),
        _kv('Tech/Manufacturer', s.techManufacturer, theme),
        // Combat
        section('Combat'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Fleet Pts', _fmtNum(s.fleetPts)),
            _chip('Hitpoints', _fmtNum(s.hitpoints)),
            _chip('Armor', _fmtNum(s.armorRating)),
            _chip('Max Flux', _fmtNum(s.maxFlux)),
            _chip('Flux Diss', _fmtNum(s.fluxDissipation)),
            _chip('Ordnance Pts', _fmtNum(s.ordnancePoints)),
            _chip('Fighter Bays', _fmtNum(s.fighterBays)),
            _chip('Weapons', _fmtNum(s.mountableWeaponSlotCount)),
          ],
        ),
        // Shields / Phase
        if (s.shieldType != null) ...[
          section('Shield / Phase'),
          Wrap(
            runSpacing: 6,
            children: [
              _chip('Shield', s.shieldType!.toTitleCase()),
              _chip('Shield Arc', _fmtNum(s.shieldArc)),
              _chip('Shield Upkeep', _fmtNum(s.shieldUpkeep)),
              _chip('Shield Efficiency', _fmtNum(s.shieldEfficiency)),
              _chip('Phase Cost', _fmtNum(s.phaseCost)),
              _chip('Phase Upkeep', _fmtNum(s.phaseUpkeep)),
            ],
          ),
        ],
        // Mobility
        section('Mobility'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Max Speed', _fmtNum(s.maxSpeed)),
            _chip('Acceleration', _fmtNum(s.acceleration)),
            _chip('Deceleration', _fmtNum(s.deceleration)),
            _chip('Turn Rate', _fmtNum(s.maxTurnRate)),
            _chip('Turn Accel', _fmtNum(s.turnAcceleration)),
            _chip('Mass', _fmtNum(s.mass)),
          ],
        ),
        // Crew & Logistics
        section('Crew & Logistics'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Min Crew', _fmtNum(s.minCrew)),
            _chip('Max Crew', _fmtNum(s.maxCrew)),
            _chip('Cargo', _fmtNum(s.cargo)),
            _chip('Fuel', _fmtNum(s.fuel)),
            _chip('Fuel/LY', _fmtNum(s.fuelPerLY)),
            _chip('Range', _fmtNum(s.range)),
            _chip('Max Burn', _fmtNum(s.maxBurn)),
          ],
        ),
        // Economics & CR
        section('Economics & CR'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Base Value', s.baseValue.asCredits()),
            _chip('CR%/Day', _fmtNum(s.crPercentPerDay)),
            _chip('CR to Deploy', _fmtNum(s.crToDeploy)),
            _chip('PPT (s)', _fmtNum(s.peakCrSec)),
            _chip('CR Loss/Sec', _fmtNum(s.crLossPerSec)),
            _chip('Supplies/Mo', _fmtNum(s.suppliesMo)),
            _chip('Supplies/Rec', _fmtNum(s.suppliesRec)),
          ],
        ),
        // Misc
        section('Misc'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Rarity', s.rarity ?? '-'),
            _chip('Break Prob', s.breakProb ?? '-'),
            _chip('Min Pieces', _fmtNum(s.minPieces)),
            _chip('Max Pieces', _fmtNum(s.maxPieces)),
            _chip('Travel Drive', s.travelDrive ?? '-'),
            _chip('Collision Radius', _fmtNum(s.collisionRadius)),
            if ((s.hints ?? []).isNotEmpty) _chip('Hints', s.hints!.join(', ')),
            if ((s.tags ?? []).isNotEmpty) _chip('Tags', s.tags!.join(', ')),
            if ((s.builtInMods ?? []).isNotEmpty)
              _chip('Built-in Mods', s.builtInMods!.join(', ')),
            if ((s.builtInWings ?? []).isNotEmpty)
              _chip('Built-in Wings', s.builtInWings!.join(', ')),
            if ((s.builtInWeapons ?? {}).isNotEmpty)
              _chip('Built-in Weapons', s.builtInWeapons!.values.join(', ')),
          ],
        ),
      ],
    );
  }

  String _fmtNum(num? n) => switch (n) {
    null => '-',
    double d => d.toStringAsFixed(d % 1 == 0 ? 0 : 2),
    _ => n.toString(),
  };

  Widget _kv(String? k, String? v, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: [
            if (k != null) TextSpan(text: '$k: '),
            TextSpan(
              text: (v == null || v.isEmpty) ? '-' : v,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SelectableText.rich(
        TextSpan(
          style: const TextStyle(fontSize: 11, color: Colors.white70),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

// Ship image loader with basic caching
class ShipImageCell extends StatefulWidget {
  final String? imagePath;
  final BoxFit fit;

  const ShipImageCell({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.scaleDown,
  });

  @override
  State<ShipImageCell> createState() => _ShipImageCellState();
}

class _ShipImageCellState extends State<ShipImageCell> {
  static final _cache = <String, bool>{};
  String? _extantPath;

  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() async {
    final path = widget.imagePath;
    if (path == null || path.isEmpty) return;

    if (_cache[path] == true) {
      _extantPath = path;
    } else {
      final exists = await File(path).exists();
      _cache[path] = exists;
      if (exists) _extantPath = path;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_extantPath == null) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Icon(Icons.image_not_supported),
      );
    }
    return MovingTooltipWidget.image(
      path: _extantPath!,
      child: InkWell(
        onTap: () {
          _extantPath?.toFile().showInExplorer();
        },
        child: Image.file(
          File(_extantPath!),
          width: 40,
          height: 40,
          cacheWidth: 40,
          fit: widget.fit,
        ),
      ),
    );
  }
}

class UngroupedShipGridGroup extends WispGridGroup<Ship> {
  UngroupedShipGridGroup() : super('none', 'None');

  @override
  String getGroupName(Ship item, {Comparable? groupSortValue}) => 'All Ships';

  @override
  Comparable getGroupSortValue(Ship item) => 1;

  @override
  bool get isGroupVisible => false;
}

class ModShipGridGroup extends WispGridGroup<Ship> {
  ModShipGridGroup() : super('mod', 'Mod');

  @override
  String getGroupName(Ship item, {Comparable? groupSortValue}) =>
      item.modVariant?.modInfo.nameOrId ?? "Vanilla";

  @override
  Comparable getGroupSortValue(Ship item) =>
      item.modVariant?.modInfo.nameOrId.toLowerCase() ?? '';
}
