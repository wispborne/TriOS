import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:stringr/stringr.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/shipSystemsManager/ship_systems_manager.dart';
import 'package:trios/shipViewer/filter_widget.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/shipViewer/shipManager.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
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

class ShipPage extends ConsumerStatefulWidget {
  const ShipPage({super.key});

  @override
  ConsumerState<ShipPage> createState() => _ShipPageState();
}

class _ShipPageState extends ConsumerState<ShipPage>
    with AutomaticKeepAliveClientMixin<ShipPage>, MultiSplitViewMixin {
  final spoilerTags = ["threat", "dweller"];

  @override
  bool get wantKeepAlive => true;

  final SearchController _searchController = SearchController();
  late File gameCoreDir;
  bool showEnabled = false;
  bool showSpoilers = false;
  bool splitPane = false;
  bool showFilters = true;

  // Filter states
  Set<String> selectedHullSizes = <String>{};
  Set<String> selectedDesignations = <String>{};
  Set<String> selectedTechManufacturers = <String>{};

  @override
  List<Area> get areas =>
      splitPane ? [Area(id: 'top'), Area(id: 'bottom')] : [Area(id: 'top')];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final shipsAsync = ref.watch(shipListNotifierProvider);
    final theme = Theme.of(context);
    final mods = ref.watch(AppState.mods);
    gameCoreDir = File(
      ref.watch(appSettings.select((s) => s.gameCoreDir))?.path ?? '',
    );

    List<Ship> ships = shipsAsync.valueOrNull ?? [];

    if (showEnabled) {
      ships = ships.where((ship) {
        return ship.modVariant == null ||
            ship.modVariant?.mod(mods)?.hasEnabledVariant == true;
      }).toList();
    }

    if (!showSpoilers) {
      ships = ships.where((ship) {
        final hints = ship.hints.orEmpty().map((h) => h.toLowerCase());
        final tags = ship.tags.orEmpty().map((t) => t.toLowerCase());

        final hidden = hints.contains('hide_in_codex');
        final isSpoiler = tags.any(spoilerTags.contains);

        return !hidden && !isSpoiler;
      }).toList();
    }

    // Apply column filters
    if (selectedHullSizes.isNotEmpty) {
      ships = ships.where((ship) {
        return selectedHullSizes.contains(ship.hullSizeForDisplay());
      }).toList();
    }

    if (selectedDesignations.isNotEmpty) {
      ships = ships.where((ship) {
        final designation = ship.designation ?? '';
        return selectedDesignations.contains(designation);
      }).toList();
    }

    if (selectedTechManufacturers.isNotEmpty) {
      ships = ships.where((ship) {
        final tech = ship.techManufacturer ?? '';
        return selectedTechManufacturers.contains(tech);
      }).toList();
    }

    final query = _searchController.value.text;
    if (query.isNotEmpty) {
      ships = ships.where((ship) {
        return ship.toMap().values.any((value) {
          return value.toString().toLowerCase().contains(query.toLowerCase());
        });
      }).toList();
    }

    final columns = buildCols(theme);

    final total = shipsAsync.valueOrNull?.length;
    final visible = ships.length ?? 0;
    final allShips = shipsAsync.valueOrNull ?? [];

    return Column(
      children: [
        Padding(
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
                            '${total ?? "..."} Ships${total != visible ? " ($visible shown)" : ""}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 20,
                            ),
                          ),
                          if (ref.watch(isLoadingShipsList))
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                            message: "Show/hide column filters",
                            child: TriOSToolbarCheckboxButton(
                              text: "Filters",
                              value: showFilters,
                              onChanged: (value) {
                                setState(() {
                                  showFilters = value ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          MovingTooltipWidget.text(
                            message: "Only ships from enabled mods.",
                            child: TriOSToolbarCheckboxButton(
                              text: "Only Enabled",
                              value: showEnabled,
                              onChanged: (value) {
                                setState(() {
                                  showEnabled = value ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          MovingTooltipWidget.text(
                            message:
                                "Show ships with 'HIDE_IN_CODEX' or certain ultra-redacted vanilla tags.",
                            warningLevel: TooltipWarningLevel.error,
                            child: TriOSToolbarCheckboxButton(
                              text: "Show Spoilers",
                              value: showSpoilers,
                              onChanged: (value) {
                                setState(() {
                                  showSpoilers = value ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          TriOSToolbarCheckboxButton(
                            text: "Compare",
                            value: splitPane,
                            onChanged: (value) {
                              splitPane = value ?? false;
                              multiSplitController.areas = areas;
                              setState(() {});
                            },
                          ),
                          MovingTooltipWidget.text(
                            message: "Refresh",
                            child: Disable(
                              isEnabled: !ref.watch(isLoadingShipsList),
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
        ),
        // Filter section
        if (showFilters)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ship Filters',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (selectedHullSizes.isNotEmpty ||
                              selectedDesignations.isNotEmpty ||
                              selectedTechManufacturers.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  selectedHullSizes.clear();
                                  selectedDesignations.clear();
                                  selectedTechManufacturers.clear();
                                });
                              },
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Clear All Filters'),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 400,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            SizedBox(
                              width: 250,
                              child: ShipFilterWidget(
                                columnName: 'Hull Size',
                                getValue: (ship) => ship.hullSizeForDisplay(),
                                ships: allShips,
                                selectedValues: selectedHullSizes,
                                onSelectionChanged: (values) {
                                  setState(() {
                                    selectedHullSizes = values;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 250,
                              child: ShipFilterWidget(
                                columnName: 'Designation',
                                getValue: (ship) => ship.designation ?? '',
                                ships: allShips,
                                selectedValues: selectedDesignations,
                                onSelectionChanged: (values) {
                                  setState(() {
                                    selectedDesignations = values;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 300,
                              child: ShipFilterWidget(
                                columnName: 'Tech/Manufacturer',
                                getValue: (ship) => ship.techManufacturer ?? '',
                                ships: allShips,
                                selectedValues: selectedTechManufacturers,
                                onSelectionChanged: (values) {
                                  setState(() {
                                    selectedTechManufacturers = values;
                                  });
                                },
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
          ),
        Expanded(
          child: Padding(
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
          ),
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
    return ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: <ContextMenuEntry>[
          buildOpenSingleFolderMenuItem(_getPathForSpriteName(ship).parent),
        ],
        padding: const EdgeInsets.all(8.0),
      ),
      // Container needed to add hit detection to the non-Text parts of the row.
      child: Container(color: Colors.transparent, child: child),
    );
  }

  List<WispGridColumn<Ship>> buildCols(ThemeData theme) {
    final shipSystems = ref.read(shipSystemsStreamProvider).valueOrNull ?? [];
    final shipSystemsMap = shipSystems.associateBy((e) => e.id);
    int position = 0;

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
        itemCellBuilder: (item, _) =>
            ShipImageCell(imagePath: _getPathForSpriteName(item).path),
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
          (s) => shipSystemsMap[s.systemId ?? ""]?.name ?? s.systemId,
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
        col('maxTurnRate', 'Turn Rate', (s) => s.maxTurnRate),
        col('turnAcceleration', 'Turn Accel', (s) => s.turnAcceleration),
        col('mass', 'Mass', (s) => s.mass),
        col(
          'shieldType',
          'Shield Type',
          (s) => s.shieldType?.lowerCase().capitalize(),
        ),
        col(
          'defenseId',
          'Defense ID',
          (s) => shipSystemsMap[s.defenseId ?? ""]?.name ?? s.defenseId,
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
        col('baseValue', 'Base \$', (s) => s.baseValue),
        col('crPercentPerDay', 'CR%/Day', (s) => s.crPercentPerDay),
        col('crToDeploy', 'CR to Deploy', (s) => s.crToDeploy),
        col('peakCrSec', 'Peak CR (s)', (s) => s.peakCrSec),
      ],
    ];
  }

  Directory _getPathForSpriteName(Ship item) {
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
                    setState(() {});
                  },
                ),
            ],
            onChanged: (_) => setState(() {}),
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
