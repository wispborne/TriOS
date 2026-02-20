import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/shipViewer/filter_widget.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/shipViewer/ship_manager.dart';
import 'package:trios/shipViewer/ships_page_controller.dart';
import 'package:trios/themes/theme_manager.dart' show ThemeManager;
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/expanding_constrained_aligned_widget.dart';
import 'package:trios/widgets/export_to_csv_dialog.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';
import 'package:trios/widgets/trios_dropdown_menu.dart';

import '../widgets/multi_split_mixin_view.dart';

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

    final controller = ref.watch(shipsPageControllerProvider.notifier);
    final controllerState = ref.watch(shipsPageControllerProvider);
    final theme = Theme.of(context);
    final mods = ref.watch(AppState.mods);

    final columns = buildCols(theme, controllerState);
    final total = controllerState.allShips.length;
    final visible = controllerState.filteredShips.length;

    return Column(
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
  }

  Widget _buildToolbar(
    BuildContext context,
    ThemeData theme,
    int total,
    int visible,
    ShipsPageController controller,
    ShipsPageState controllerState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: 50,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Text(
                  '$total Ships${total != visible ? " ($visible shown)" : ""}',
                  style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),
                ),
                const SizedBox(width: 4),
                if (controllerState.isLoading)
                  Padding(
                    padding: const .only(left: 8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (!controllerState.isLoading)
                  MovingTooltipWidget.text(
                    message: "Refresh",
                    child: Disable(
                      isEnabled: !controllerState.isLoading,
                      child: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () =>
                            ref.invalidate(shipListNotifierProvider),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                ExpandingConstrainedAlignedWidget(
                  alignment: Alignment.centerRight,
                  child: buildSearchBox(),
                ),
                const SizedBox(width: 8),
                MovingTooltipWidget.text(
                  message: "Only ships from enabled mods.",
                  child: TriOSToolbarCheckboxButton(
                    text: "Only Enabled",
                    value: controllerState.showEnabled,
                    onChanged: (value) => controller.toggleShowEnabled(),
                  ),
                ),
                const SizedBox(width: 8),
                TriOSDropdownMenu<SpoilerLevel>(
                  initialSelection: controllerState.spoilerLevelToShow,
                  onSelected: (level) {
                    if (level == null) return;
                    controller.setShowSpoilers(level);
                  },
                  dropdownMenuEntries: [
                    DropdownMenuEntry(
                      value: SpoilerLevel.showNone,
                      label: "No Spoilers",
                      labelWidget: MovingTooltipWidget.text(
                        message: "No spoilers shown at all.",
                        child: Text("No Spoilers"),
                      ),
                    ),
                    DropdownMenuEntry(
                      value: SpoilerLevel.showSlightSpoilers,
                      label: "Slight spoilers",
                      labelWidget: MovingTooltipWidget.text(
                        warningLevel: TooltipWarningLevel.warning,
                        message: "Shows CODEX_UNLOCKABLE ships.",
                        child: Text("Slight spoilers"),
                      ),
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
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                TriOSToolbarCheckboxButton(
                  text: "Compare",
                  value: controllerState.splitPane,
                  onChanged: (value) {
                    controller.toggleSplitPane();
                    multiSplitController.areas = areas;
                    setState(() {});
                  },
                ),
                _buildOverflowButton(
                  context: context,
                  theme: theme,
                  controllerState: controllerState,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection(
    ThemeData theme,
    ShipsPageState controllerState,
    ShipsPageController controller,
    List<Ship> shipsBeforeFilter,
  ) {
    if (!controllerState.showFilters) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Card(
          child: InkWell(
            onTap: controller.toggleShowFilters,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: MovingTooltipWidget.text(
                message: "Show filters",
                child: const Icon(Icons.filter_list, size: 16),
              ),
            ),
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: MultiSplitViewTheme(
        data: MultiSplitViewThemeData(
          dividerThickness: 16,
          dividerPainter: DividerPainters.dashed(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            highlightedColor: theme.colorScheme.onSurface,
            highlightedThickness: 2,
            gap: 1,
          ),
        ),
        child: MultiSplitView(
          controller: multiSplitController,
          axis: Axis.vertical,
          builder: (context, area) {
            switch (area.id) {
              case 'top':
                return buildGrid(columns, ships, mods, true, theme);
              case 'bottom':
                return buildGrid(columns, ships, mods, false, theme);
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  AnimatedContainer buildFilterPanel(
    ThemeData theme,
    List<Ship> displayedShips,
    ShipsPageState controllerState,
    ShipsPageController controller,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          child: Scrollbar(
            thumbVisibility: true,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              child: SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        MovingTooltipWidget.text(
                          message: "Hide filters",
                          child: InkWell(
                            onTap: controller.toggleShowFilters,
                            borderRadius: BorderRadius.circular(
                              ThemeManager.cornerRadius,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  const Icon(Icons.filter_list, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Filters',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (controllerState.filterCategories.any(
                          (f) => f.hasActiveFilters,
                        ))
                          TriOSToolbarItem(
                            elevation: 0,
                            child: TextButton.icon(
                              onPressed: controller.clearAllFilters,
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Clear All'),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ScrollConfiguration(
                        // Hide inner scrollbar, shown above instead.
                        behavior: ScrollConfiguration.of(
                          context,
                        ).copyWith(scrollbars: false),
                        child: SingleChildScrollView(
                          primary: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: controllerState.filterCategories.map((
                              filter,
                            ) {
                              return GridFilterWidget(
                                filter: filter,
                                items: displayedShips,
                                filterStates: filter.filterStates,
                                onSelectionChanged: (states) {
                                  controller.updateFilterStates(filter, states);
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
      itemExtent: 50,
      scrollbarConfig: ScrollbarConfig(
        showLeftScrollbar: ScrollbarVisibility.always,
        showRightScrollbar: ScrollbarVisibility.always,
        showBottomScrollbar: ScrollbarVisibility.always,
      ),
      rowBuilder: ({required item, required modifiers, required child}) =>
          SizedBox(
            height: 50,
            child: InkWell(
              onTap: () => _showShipDetailsDialog(context, item),
              child: Container(
                color: Colors.transparent,
                child: buildRowContextMenu(item, child),
              ),
            ),
          ),
      groups: [ModShipGridGroup()],
    );
  }

  Widget buildRowContextMenu(Ship ship, Widget child) {
    final controller = ref.read(shipsPageControllerProvider.notifier);
    final gameCoreDir = controller.getGameCoreDir();

    return ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: <ContextMenuEntry>[
          buildOpenSingleFolderMenuItem(
            _getPathForSpriteName(ship, gameCoreDir).parent,
          ),
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
          tooltipWidget: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: _buildShipInfoPane(item, theme, controllerState),
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
        ),
        csvValue: (ship) => _getPathForSpriteName(ship, gameCoreDir).path,
        defaultState: WispGridColumnState(position: position++, width: 50),
      ),
      col('hullName', 'Name', (s) => s.hullNameForDisplay(), width: 200),
      col('hullSize', 'Hull', (s) => s.hullSizeForDisplay(), width: 80),
      WispGridColumn(
        key: 'weaponSlotCount',
        name: 'Wpns',
        isSortable: true,
        getSortValue: (ship) => ship.mountableWeaponSlotCount,
        itemCellBuilder: (item, _) =>
            Text('${item.mountableWeaponSlotCount}'),
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
        col('baseValue', 'Credits (base)', (s) => s.baseValue),
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

  SizedBox buildSearchBox() {
    return SizedBox(
      height: 30,
      width: 300,
      child: SearchAnchor(
        searchController: _searchController,
        builder: (context, controller) {
          return SearchBar(
            controller: controller,
            leading: const Icon(Icons.search),
            hintText: "Filter ships...",
            trailing: [
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    ref
                        .read(shipsPageControllerProvider.notifier)
                        .updateSearchQuery('');
                  },
                ),
            ],
            onChanged: (query) {
              ref
                  .read(shipsPageControllerProvider.notifier)
                  .updateSearchQuery(query);
            },
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainer,
            ),
          );
        },
        suggestionsBuilder: (_, __) => [],
      ),
    );
  }

  Widget _buildOverflowButton({
    required BuildContext context,
    required ThemeData theme,
    required ShipsPageState controllerState,
  }) {
    return PopupMenuButton(
      tooltip: "More actions",
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        PopupMenuItem(
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
          child: const Row(
            children: [
              Icon(Icons.table_view, size: 18),
              SizedBox(width: 8),
              Text('Export to CSV'),
            ],
          ),
        ),
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

  Column _buildShipInfoPane(
    Ship s,
    ThemeData theme,
    ShipsPageState controllerState,
  ) {
    final controller = ref.read(shipsPageControllerProvider.notifier);
    final gameCoreDir = controller.getGameCoreDir();
    final spriteDir = _getPathForSpriteName(s, gameCoreDir);

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
                      child: Image.file(
                        File(spriteDir.path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
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
        Divider(color: Theme.of(context).colorScheme.outline),
        _kv(
          s.modVariant != null ? 'Mod' : null,
          s.modVariant?.modInfo.nameOrId ?? 'Vanilla',
          theme,
        ),
        _kv('Hull Size', s.hullSizeForDisplay(), theme),
        _kv(
          'System',
          controllerState.shipSystemsMap[s.systemId ?? ""]?.name ?? s.systemId,
          theme,
        ),
        _kv('Tech/Manufacturer', s.techManufacturer, theme),
        const SizedBox(height: 12),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Fleet Pts', _fmtNum(s.fleetPts)),
            _chip('Hitpoints', _fmtNum(s.hitpoints)),
            _chip('Armor', _fmtNum(s.armorRating)),
            _chip('Max Flux', _fmtNum(s.maxFlux)),
            _chip('Flux Diss', _fmtNum(s.fluxDissipation)),
            _chip('Shield', s.shieldType?.toTitleCase() ?? '-'),
            _chip('Weapons', _fmtNum(s.mountableWeaponSlotCount)),
            if ((s.designation ?? '').isNotEmpty)
              _chip('Designation', s.designation!),
            if ((s.tags ?? []).isNotEmpty) _chip('Tags', s.tags!.join(", ")),
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
      child: RichText(
        text: TextSpan(
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

  const ShipImageCell({super.key, required this.imagePath});

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
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class ModShipGridGroup extends WispGridGroup<Ship> {
  ModShipGridGroup() : super('mod', 'Mod');

  @override
  String getGroupName(Ship item) =>
      item.modVariant?.modInfo.nameOrId ?? "Vanilla";

  @override
  Comparable getGroupSortValue(Ship item) =>
      item.modVariant?.modInfo.nameOrId.toLowerCase() ?? '';
}
