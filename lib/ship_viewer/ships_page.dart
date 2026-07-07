import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:trios/widgets/snackbar.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/ship_manager.dart';
import 'package:trios/ship_viewer/ships_page_controller.dart';
import 'package:trios/ship_viewer/widgets/ship_codex_card.dart';
import 'package:trios/ship_viewer/widgets/ship_details_dialog.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/collapsed_filter_button.dart';
import 'package:trios/widgets/description_with_substitutions.dart';
import 'package:trios/widgets/export_to_csv_dialog.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/overflow_menu_button.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/smart_search/smart_search_bar.dart';
import 'package:trios/widgets/viewer_split_pane.dart';
import 'package:trios/widgets/viewer_toolbar.dart';

import '../trios/navigation.dart';
import '../widgets/multi_split_mixin_view.dart';
import 'widgets/ship_blueprint_view.dart';

final _nonAlphanumeric = RegExp(r'[^0-9a-zA-Z]');

class ShipsPage extends ConsumerStatefulWidget {
  const ShipsPage({super.key});

  @override
  ConsumerState<ShipsPage> createState() => _ShipsPageState();
}

class _ShipsPageState extends ConsumerState<ShipsPage>
    with AutomaticKeepAliveClientMixin<ShipsPage>, MultiSplitViewMixin {
  @override
  bool get wantKeepAlive => true;

  WispGridController<Ship>? _gridController;
  Widget? _cachedBuild;

  @override
  List<Area> get areas {
    final controllerState = ref.read(shipsPageControllerProvider);
    return controllerState.splitPane
        ? [Area(id: 'top'), Area(id: 'bottom')]
        : [Area(id: 'top')];
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
        ref.read(shipsPageControllerProvider.notifier).setChipSelections(
          'mod',
          {filterRequest.modName: true},
        );
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
      searchBox: SmartSearchBar(
        fields: controller.searchFieldsMeta,
        recentHistory: ref.watch(
          appSettings.select((s) => s.shipsSearchHistory),
        ),
        initialValue: controllerState.currentSearchQuery,
        onChanged: (query) => ref
            .read(shipsPageControllerProvider.notifier)
            .updateSearchQuery(query),
        onSubmitted: () =>
            ref.read(shipsPageControllerProvider.notifier).submitSearchQuery(),
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
      child: buildFilterPanel(
        theme,
        shipsBeforeFilter,
        controllerState,
        controller,
      ),
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
      showClearAll: controller.filterGroups.any((g) => g.isActive),
      onClearAll: controller.clearAllFilters,
      filterWidgets: [
        for (final g in controller.filterGroups)
          FilterGroupRenderer<Ship>(
            group: g,
            scope: controller.scope,
            items: displayedShips,
            onChanged: () => controller.onGroupChanged(g.id),
          ),
      ],
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

    return DefaultTextStyle.merge(
      style: theme.textTheme.labelLarge!.copyWith(fontSize: 14),
      child: WispGrid<Ship>(
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
                  onTap: () => showShipDetailsDialog(context, ref, item),
                  child: Container(
                    color: Colors.transparent,
                    child: buildRowContextMenu(item, child),
                  ),
                ),
              ),
            ),
        groups: [UngroupedShipGridGroup(), ModShipGridGroup()],
      ),
    );
  }

  Widget buildRowContextMenu(Ship ship, Widget child) {
    final controller = ref.read(shipsPageControllerProvider.notifier);
    final gameCoreDir = controller.getGameCoreDir();

    return ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: <ContextMenuEntry>[
          MenuItem(
            label: 'Copy ID',
            icon: Icons.copy,
            onSelected: () => Clipboard.setData(ClipboardData(text: ship.id)),
          ),
          if (ship.dataFile != null)
            MenuItem(
              label: 'Open ${ship.isSkin ? '.skin' : '.ship'} file',
              icon: Icons.edit_note,
              onSelected: () {
                ship.dataFile!.absolute.showInExplorer();
              },
            ),
          if (ship.csvFile != null)
            MenuItem(
              label: 'Open ship_data.csv',
              icon: Icons.edit_note,
              onSelected: () {
                ship.csvFile!.absolute.showInExplorer();
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
        itemCellBuilder: (item, modifiers) => ShipImageCell(
          imagePath: _getPathForSpriteName(item, gameCoreDir).path,
          ship: item,
          fit: controllerState.useContainFit
              ? BoxFit.contain
              : BoxFit.scaleDown,
          rowHovered: modifiers.isHovering,
        ),
        csvValue: (ship) => _getPathForSpriteName(ship, gameCoreDir).path,
        defaultState: WispGridColumnState(position: position++, width: 50),
      ),
      WispGridColumn<Ship>(
        key: 'hullName',
        isSortable: true,
        name: 'Name',
        getSortValue: (ship) =>
            ship.hullNameForDisplay().replaceAll(_nonAlphanumeric, ''),
        itemCellBuilder: (item, _) => Row(
          children: [
            Flexible(
              child: ShipCodexCard.tooltip(
                ship: item,
                shipSystemsMap: controllerState.shipSystemsMap,
                weaponsMap: controllerState.weaponsMap,
                hullmodsMap: controllerState.hullmodsMap,
                child: MouseRegion(
                  cursor: SystemMouseCursors.none,
                  child: Text(
                    item.hullNameForDisplay(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (item.isSkin)
              Padding(
                padding: const .only(left: 8, top: 3),
                child: Container(
                  padding: const .symmetric(horizontal: 4, vertical: 1),
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
      col('id', 'ID', (s) => s.id),
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
      WispGridColumn(
        key: 'builtInWeaponCount',
        name: 'Built-in Wpns',
        isSortable: true,
        getSortValue: (ship) => ship.builtInWeapons?.length ?? 0,
        itemCellBuilder: (item, _) =>
            Text('${item.builtInWeapons?.length ?? 0}'),
        csvValue: (ship) => (ship.builtInWeapons?.length ?? 0).toString(),
        defaultState: WispGridColumnState(position: position++, width: 120),
      ),
      WispGridColumn(
        key: 'builtInModCount',
        name: 'Built-in Mods',
        isSortable: true,
        getSortValue: (ship) => ship.builtInMods?.length ?? 0,
        itemCellBuilder: (item, _) => Text('${item.builtInMods?.length ?? 0}'),
        csvValue: (ship) => (ship.builtInMods?.length ?? 0).toString(),
        defaultState: WispGridColumnState(position: position++, width: 120),
      ),
      WispGridColumn(
        key: 'builtInWingCount',
        name: 'Built-in Wings',
        isSortable: true,
        getSortValue: (ship) => ship.builtInWings?.length ?? 0,
        itemCellBuilder: (item, _) => Text('${item.builtInWings?.length ?? 0}'),
        csvValue: (ship) => (ship.builtInWings?.length ?? 0).toString(),
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
        col('deploymentPoints', 'DP', (s) => s.deploymentPoints),
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
        col('sensorProfile', 'Sensor Profile', (s) => s.sensorProfile),
        col('sensorStrength', 'Sensor Strength', (s) => s.sensorStrength),
        col('baseValue', 'Credits (base)', (s) => s.baseValue.asCredits()),
        col('crPercentPerDay', 'CR%/Day', (s) => s.crPercentPerDay),
        col('crToDeploy', 'CR to Deploy', (s) => s.crToDeploy),
        col('peakCrSec', 'PPT', (s) => s.peakCrSec),
        col('crLossPerSec', 'CR Loss/Sec', (s) => s.crLossPerSec),
        col('supplyCostPerMonth', 'Supplies/Mon', (s) => s.suppliesMo),
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
        OverflowMenuCheckItem(
          title: 'Always show engine glow',
          icon: Icons.local_fire_department,
          checked: controllerState.alwaysShowEngineGlow,
          onTap: () => controller.toggleAlwaysShowEngineGlow(),
        ).toEntry(2),
      ],
    );
  }

}

// Ship image loader with basic caching
class ShipImageCell extends StatefulWidget {
  final String? imagePath;
  final Ship? ship;
  final BoxFit fit;

  /// Whether the grid row is hovered; reveals the engine glow on the icon.
  final bool rowHovered;

  const ShipImageCell({
    super.key,
    required this.imagePath,
    this.ship,
    this.fit = BoxFit.scaleDown,
    this.rowHovered = false,
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
    const size = 40.0;

    if (_extantPath == null) {
      return const SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.image_not_supported),
      );
    }
    final shipW = (widget.ship?.width ?? 80).toDouble();
    final shipH = (widget.ship?.height ?? 80).toDouble();
    final longest = (shipW > shipH ? shipW : shipH).clamp(1.0, double.infinity);
    final previewLong = longest;
    final previewScale = previewLong / longest;

    final tooltipWidget = Card(
      color: kDarkTooltipBackground,
      child: Padding(
        padding: .all(16),
        child: widget.ship != null
            ? SizedBox(
                width: shipW * previewScale,
                height: shipH * previewScale,
                child: ShipBlueprintView.minimal(
                  ship: widget.ship!,
                  fit: BoxFit.contain,
                ),
              )
            : Image.file(_extantPath!.toFile(), fit: BoxFit.contain),
      ),
    );

    return MovingTooltipWidget(
      tooltipWidget: tooltipWidget,
      child: ContextMenuRegion(
        contextMenu: ContextMenu(
          entries: <ContextMenuEntry>[
            MenuItem(
              label: 'Copy sprite to clipboard',
              icon: Icons.copy,
              onSelected: _copySpriteToClipboard,
            ),
            MenuItem(
              label: 'Open sprite folder',
              icon: Icons.folder_open,
              onSelected: () => _extantPath?.toFile().showInExplorer(),
            ),
          ],
          padding: const EdgeInsets.all(8.0),
        ),
        child: InkWell(
          onTap: () {
            _extantPath?.toFile().showInExplorer();
          },
          child: widget.ship != null
              ? SizedBox(
                  width: size,
                  height: size,
                  child: ShipBlueprintView.minimal(
                    ship: widget.ship!,
                    cacheWidth: size.toInt(),
                    fit: widget.fit,
                    clipContent: false,
                    forceEngineGlow: widget.rowHovered,
                  ),
                )
              : Image.file(
                  File(_extantPath!),
                  width: size,
                  height: size,
                  cacheWidth: size.toInt(),
                  fit: widget.fit,
                ),
        ),
      ),
    );
  }

  /// Copies the ship's hull sprite (a PNG file) to the clipboard.
  Future<void> _copySpriteToClipboard() async {
    final path = _extantPath;
    if (path == null) return;

    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      if (!mounted) return;
      showSnackBar(
        context: context,
        type: SnackBarType.warn,
        content: const Text('Copying images is not supported on this platform.'),
      );
      return;
    }

    try {
      final bytes = await File(path).readAsBytes();
      final item = DataWriterItem()..add(Formats.png(bytes));
      await clipboard.write([item]);
      if (!mounted) return;
      showSnackBar(
        context: context,
        type: SnackBarType.info,
        content: const Text('Copied sprite to clipboard.'),
      );
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        context: context,
        type: SnackBarType.error,
        content: Text('Failed to copy sprite: $e'),
      );
    }
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
