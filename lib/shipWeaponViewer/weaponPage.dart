import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/shipWeaponViewer/weaponsManager.dart';
import 'package:trios/thirdparty/pluto_grid_plus/lib/pluto_grid_plus.dart';

class WeaponPage extends ConsumerStatefulWidget {
  const WeaponPage({Key? key}) : super(key: key);

  @override
  _WeaponPageState createState() => _WeaponPageState();
}

class _WeaponPageState extends ConsumerState<WeaponPage> {
  final SearchController _searchController = SearchController();
  PlutoGridStateManager? _stateManager;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterGrid(String query) {
    if (_stateManager == null) return;

    _stateManager!.setFilter(
      (PlutoRow row) {
        return row.cells.values.any((cell) {
          final value = cell.value.toString().toLowerCase();
          return value.contains(query.toLowerCase());
        });
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Watch the weapons provider
    final weaponListAsyncValue = ref.watch(weaponListNotifierProvider);
    final theme = Theme.of(context);

    // Configure columns for the PlutoGrid
    List<PlutoColumn> columns = [
      PlutoColumn(
        title: 'Mod',
        field: 'modVariant',
        type: PlutoColumnType.text(),
      ),
      PlutoColumn(
        title: 'Name',
        field: 'name',
        type: PlutoColumnType.text(),
      ),
      PlutoColumn(
        title: 'ID',
        field: 'id',
        type: PlutoColumnType.text(),
      ),
      PlutoColumn(
        title: 'Tier',
        field: 'tier',
        type: PlutoColumnType.number(),
      ),
      PlutoColumn(
        title: 'Rarity',
        field: 'rarity',
        type: PlutoColumnType.number(),
      ),
      PlutoColumn(
        title: 'Damage/Shot',
        field: 'damagePerShot',
        type: PlutoColumnType.number(),
      ),
      PlutoColumn(
        title: 'Type',
        field: 'type',
        type: PlutoColumnType.text(),
      ),
      // Add additional columns as necessary
    ];

    return weaponListAsyncValue.when(
      data: (weapons) {
        // Map weapons to rows for PlutoGrid
        List<PlutoRow> rows = weapons.map((weapon) {
          return PlutoRow(
            cells: {
              'modVariant': PlutoCell(
                  value: weapon.modVariant?.modInfo.nameOrId ?? "Vanilla"),
              'name': PlutoCell(value: weapon.name ?? ""),
              'id': PlutoCell(value: weapon.id),
              'tier': PlutoCell(value: weapon.tier ?? ""),
              'rarity': PlutoCell(value: weapon.rarity ?? ""),
              'damagePerShot': PlutoCell(value: weapon.damagePerShot ?? ""),
              'type': PlutoCell(value: weapon.type ?? ""),
              // Add other fields if needed
            },
          );
        }).toList();

        return Column(
          children: [
            SizedBox(
              height: 50,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Stack(
                    children: [
                      const SizedBox(width: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${weaponListAsyncValue.valueOrNull?.length ?? "..."} Weapons',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontSize: 20),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                            height: 30,
                            width: 300,
                            child: SearchAnchor(
                              searchController: _searchController,
                              builder: (BuildContext context,
                                  SearchController controller) {
                                return SearchBar(
                                    controller: controller,
                                    leading: const Icon(Icons.search),
                                    hintText: "Filter...",
                                    trailing: [
                                      controller.value.text.isEmpty
                                          ? Container()
                                          : IconButton(
                                              icon: const Icon(Icons.clear),
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                              onPressed: () {
                                                controller.clear();
                                                _filterGrid("");
                                                // filteredMods =
                                                //     filterMods(query);
                                              },
                                            )
                                    ],
                                    backgroundColor: WidgetStateProperty.all(
                                        Theme.of(context)
                                            .colorScheme
                                            .surfaceContainer),
                                    onChanged: (value) {
                                      _filterGrid(value);
                                      // setState(() {
                                      //   query = value;
                                      //   filteredMods = filterMods(value);
                                      // });
                                    });
                              },
                              suggestionsBuilder: (BuildContext context,
                                  SearchController controller) {
                                return [];
                              },
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: PlutoGrid(
                  columns: columns,
                  rows: rows,
                  onLoaded: (PlutoGridOnLoadedEvent event) {
                    _stateManager = event.stateManager;
                    // Enable column filtering if needed
                    _stateManager!.setShowColumnFilter(false);
                  },
                  configuration: PlutoGridConfiguration(
                    columnSize: const PlutoGridColumnSizeConfig(
                        // autoSizeMode: PlutoAutoSizeMode.,
                        ),
                    scrollbar: const PlutoGridScrollbarConfig(
                      isAlwaysShown: true,
                      hoverWidth: 10,
                      scrollbarThickness: 8,
                      scrollbarRadius: Radius.circular(5),
                      dragDevices: {
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.touch,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.invertedStylus,
                      },
                    ),
                    style: PlutoGridStyleConfig.dark(
                      enableCellBorderHorizontal: false,
                      enableCellBorderVertical: false,
                      activatedBorderColor: Colors.transparent,
                      inactivatedBorderColor: Colors.transparent,
                      menuBackgroundColor: theme.colorScheme.surface,
                      gridBackgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      rowColor: Colors.transparent,
                      borderColor: Colors.transparent,
                      cellColorInEditState: Colors.transparent,
                      cellColorInReadOnlyState: Colors.transparent,
                      gridBorderColor: Colors.transparent,
                      activatedColor:
                          theme.colorScheme.onSurface.withOpacity(0.1),
                      evenRowColor: theme.colorScheme.surface.withOpacity(0.4),
                      defaultCellPadding: EdgeInsets.zero,
                      defaultColumnFilterPadding: EdgeInsets.zero,
                      defaultColumnTitlePadding: EdgeInsets.zero,
                      enableRowColorAnimation: true,
                      iconSize: 12,
                      columnTextStyle: theme.textTheme.headlineSmall!
                          .copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                      dragTargetColumnColor:
                          theme.colorScheme.surface.darker(20),
                      iconColor: theme.colorScheme.onSurface.withAlpha(150),
                      cellTextStyle:
                          theme.textTheme.labelLarge!.copyWith(fontSize: 14),
                    ),
                  ),
                  onChanged: (PlutoGridOnChangedEvent event) {
                    print(
                        'Value changed from ${event.oldValue} to ${event.value}');
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: SelectableText('Error loading weapons: $error'),
      ),
    );
  }
}
