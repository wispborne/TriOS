import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/shipViewer/shipManager.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';

import '../widgets/MultiSplitViewMixin.dart';

class ShipPage extends ConsumerStatefulWidget {
  const ShipPage({super.key});

  @override
  ConsumerState<ShipPage> createState() => _ShipPageState();
}

class _ShipPageState extends ConsumerState<ShipPage>
    with AutomaticKeepAliveClientMixin<ShipPage>, MultiSplitViewMixin {
  @override
  bool get wantKeepAlive => true;

  final SearchController _searchController = SearchController();
  WispGridController<Ship>? _gridTop;
  WispGridController<Ship>? _gridBottom;
  bool showSpoilers = false;
  bool splitPane = false;

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

    List<Ship> ships = shipsAsync.valueOrNull ?? [];
    final spoilerTags = ["threat", "dweller"];

    if (!showSpoilers) {
      ships =
          ships.where((ship) {
            final hints = ship.hints.orEmpty().map((h) => h.toLowerCase());
            final tags = ship.tags.orEmpty().map((t) => t.toLowerCase());

            final hidden = hints.contains('hide_in_codex');
            final isSpoiler = tags.any(spoilerTags.contains);

            return !hidden && !isSpoiler;
          }).toList();
    }

    final query = _searchController.value.text;
    if (query.isNotEmpty) {
      ships =
          ships.where((ship) {
            return ship.toMap().values.any((value) {
              return value.toString().toLowerCase().contains(
                query.toLowerCase(),
              );
            });
          }).toList();
    }

    final columns = buildCols(theme);

    final total = shipsAsync.valueOrNull?.length;
    final visible = ships.length ?? 0;

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
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed:
                                () => ref.invalidate(shipListNotifierProvider),
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
                      return buildGrid(columns, ships, true, theme);
                    case 'bottom':
                      return buildGrid(columns, ships, false, theme);
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
      alwaysShowScrollbar: true,
      rowBuilder:
          ({required item, required modifiers, required child}) =>
              SizedBox(height: 50, child: child),
      onLoaded: (controller) {
        if (isTop) {
          _gridTop = controller;
        } else {
          _gridBottom = controller;
        }
      },
      groups: [ModShipGridGroup()],
    );
  }

  List<WispGridColumn<Ship>> buildCols(ThemeData theme) {
    final vanillaBasePath = File(
      ref.watch(appSettings.select((s) => s.gameCoreDir))?.path ?? '',
    );
    return [
      WispGridColumn(
        key: 'modVariant',
        isSortable: true,
        name: 'Mod',
        getSortValue: (ship) => ship.modVariant?.modInfo.nameOrId,
        itemCellBuilder:
            (item, _) => Tooltip(
              message: item.modVariant?.modInfo.nameOrId ?? "Vanilla",
              child: Text(
                item.modVariant?.modInfo.nameOrId ?? "Vanilla",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
        defaultState: const WispGridColumnState(position: 0, width: 120),
      ),
      WispGridColumn(
        key: 'sprite',
        name: '',
        isSortable: false,
        itemCellBuilder:
            (item, _) => ShipImageCell(
              imagePath:
                  (item.modVariant == null
                          ? vanillaBasePath
                          : item.modVariant!.modFolder)
                      .resolve(item.spriteName ?? "")
                      .path,
            ),
        defaultState: const WispGridColumnState(position: 1, width: 50),
      ),
      WispGridColumn(
        key: 'hullName',
        isSortable: true,
        name: 'Name',
        getSortValue: (ship) => ship.hullName,
        itemCellBuilder: (item, _) => Text(item.hullName ?? "(unknown)"),
        defaultState: const WispGridColumnState(position: 2, width: 200),
      ),
      WispGridColumn(
        key: 'hullSize',
        isSortable: true,
        name: 'Size',
        getSortValue: (ship) => ship.hullSize,
        itemCellBuilder: (item, _) => Text(item.hullSizeForDisplay()),
        defaultState: const WispGridColumnState(position: 3, width: 80),
      ),
      WispGridColumn(
        key: 'weaponSlotCount',
        name: 'Wpns',
        isSortable: true,
        getSortValue: (ship) => ship.weaponSlots?.length ?? 0,
        itemCellBuilder: (item, _) => Text('${item.weaponSlots?.length ?? 0}'),
        defaultState: const WispGridColumnState(position: 4, width: 120),
      ),
      WispGridColumn(
        key: 'techManufacturer',
        isSortable: true,
        name: 'Tech',
        getSortValue: (ship) => ship.techManufacturer,
        itemCellBuilder: (item, _) => Text(item.techManufacturer ?? ''),
        defaultState: const WispGridColumnState(position: 5, width: 220),
      ),
    ];
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
  String? _found;

  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() async {
    final path = widget.imagePath;
    if (path == null || path.isEmpty) return;

    if (_cache[path] == true) {
      _found = path;
    } else {
      final exists = await File(path).exists();
      _cache[path] = exists;
      if (exists) _found = path;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_found == null) {
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
          child: Image.file(File(_found!), fit: BoxFit.contain),
        ),
      ),
      child: Image.file(
        File(_found!),
        width: 40,
        height: 40,
        fit: BoxFit.contain,
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
