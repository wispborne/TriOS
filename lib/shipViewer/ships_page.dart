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
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';

import '../widgets/MultiSplitViewMixin.dart';

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
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        '$total Ships${total != visible ? " ($visible shown)" : ""}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      if (controllerState.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  ),
                ),
                Center(child: buildSearchBox()),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MovingTooltipWidget.text(
                        message: "Only ships from enabled mods.",
                        child: TriOSToolbarCheckboxButton(
                          text: "Only Enabled",
                          value: controllerState.showEnabled,
                          onChanged: (value) => controller.toggleShowEnabled(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MovingTooltipWidget.text(
                        message:
                            "Show ships with 'HIDE_IN_CODEX' or certain ultra-redacted vanilla tags.",
                        warningLevel: TooltipWarningLevel.error,
                        child: TriOSToolbarCheckboxButton(
                          text: "Show Spoilers",
                          value: controllerState.showSpoilers,
                          onChanged: (value) => controller.toggleShowSpoilers(),
                        ),
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
                    ],
                  ),
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
      columns: columns,
      items: items,
      itemExtent: 50,
      scrollbarConfig: ScrollbarConfig(
        showLeftScrollbar: ScrollbarVisibility.always,
        showRightScrollbar: ScrollbarVisibility.always,
        showBottomScrollbar: ScrollbarVisibility.always,
      ),
      rowBuilder: ({required item, required modifiers, required child}) =>
          SizedBox(height: 50, child: buildRowContextMenu(item, child)),
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
          final value = getValue(item);
          final str = switch (value) {
            double dbl => dbl.toStringMinimizingDigits(2),
            null => "",
            _ => value.toString(),
          };
          return TextTriOS(str, maxLines: 1, overflow: TextOverflow.ellipsis);
        },
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
        defaultState: WispGridColumnState(position: position++, width: 120),
      ),
      WispGridColumn(
        key: 'sprite',
        name: '',
        isSortable: false,
        itemCellBuilder: (item, _) => ShipImageCell(
          imagePath: _getPathForSpriteName(item, gameCoreDir).path,
        ),
        defaultState: WispGridColumnState(position: position++, width: 50),
      ),
      col('hullName', 'Name', (s) => s.hullName, width: 200),
      col('hullSize', 'Hull', (s) => s.hullSizeForDisplay(), width: 80),
      WispGridColumn(
        key: 'weaponSlotCount',
        name: 'Wpns',
        isSortable: true,
        getSortValue: (ship) => ship.weaponSlots?.length ?? 0,
        itemCellBuilder: (item, _) => Text('${item.weaponSlots?.length ?? 0}'),
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
        col('shield', 'Shield', (s) => s.shieldType?.toTitleCase()),
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
    return MovingTooltipWidget(
      tooltipWidget: Card(
        color: Color.from(red: 0.05, green: 0.05, blue: 0.05, alpha: 1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Image.file(File(_extantPath!), fit: BoxFit.contain),
        ),
      ),
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
