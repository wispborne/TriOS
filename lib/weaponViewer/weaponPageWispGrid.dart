import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/weaponViewer/models/weapon.dart';
import 'package:trios/weaponViewer/weaponsManager.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/moving_tooltip.dart';

import '../widgets/MultiSplitViewMixin.dart';

class WeaponPage extends ConsumerStatefulWidget {
  const WeaponPage({super.key});

  @override
  ConsumerState<WeaponPage> createState() => _WeaponPageState();
}

class _WeaponPageState extends ConsumerState<WeaponPage>
    with AutomaticKeepAliveClientMixin<WeaponPage>, MultiSplitViewMixin {
  @override
  bool get wantKeepAlive => true;
  final SearchController _searchController = SearchController();
  WispGridController<Weapon>? _gridStateManagerTop;
  WispGridController<Weapon>? _gridStateManagerBottom;
  bool showHiddenWeapons = false;
  bool splitPane = false;
  String gameCorePath = "";

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
    final gridState = ref.watch(appSettings.select((s) => s.weaponsGridState));
    final weaponListAsyncValue = ref.watch(weaponListNotifierProvider);
    final theme = Theme.of(context);
    gameCorePath =
        ref.watch(appSettings.select((s) => s.gameCoreDir))?.path ?? '';
    List<Weapon> items = weaponListAsyncValue.valueOrNull ?? [];

    if (!showHiddenWeapons) {
      items = items
          .where((weapon) => weapon.weaponType?.toLowerCase() != "decorative")
          .toList();
    }

    final query = _searchController.value.text;
    if (query.isNotEmpty) {
      items = items.where((weapon) {
        return weapon.toMap().values.any((value) {
          return value.toString().toLowerCase().contains(query.toLowerCase());
        });
      }).toList();
    }

    final columns = buildCols(theme);

    final weaponCount = weaponListAsyncValue.valueOrNull?.length;
    final filteredWeaponCount =
        _gridStateManagerTop?.lastDisplayedItemsReadonly.distinctBy((row) {
              final weapon = row;
              return weapon.id;
            }).length ??
            0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 50,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Stack(
                  children: [
                    const SizedBox(width: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            '${weaponCount ?? "..."} Weapons${weaponCount != filteredWeaponCount ? " ($filteredWeaponCount shown)" : ""}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontSize: 20),
                          ),
                          if (ref.watch(isLoadingWeaponsList))
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Center(
                      child: buildSearchBox(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          MovingTooltipWidget.text(
                            message: "Show hidden weapons",
                            child: buildToolbarButton(
                                theme, "Show Hidden", showHiddenWeapons,
                                (value) {
                              setState(() {
                                showHiddenWeapons = value ?? false;
                              });
                            }),
                          ),
                          buildToolbarButton(theme, "Compare", splitPane,
                              (value) {
                            splitPane = value ?? false;
                            multiSplitController.areas = areas;
                            setState(() {});
                          }),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              ref.invalidate(weaponListNotifierProvider);
                            },
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
            padding: const EdgeInsets.all(8.0),
            child: MultiSplitViewTheme(
              data: MultiSplitViewThemeData(
                  dividerThickness: 16,
                  dividerPainter: DividerPainters.dashed(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    highlightedColor: theme.colorScheme.onSurface,
                    highlightedThickness: 2,
                    gap: 1,
                    animationDuration: const Duration(milliseconds: 100),
                  )),
              child: MultiSplitView(
                  controller: multiSplitController,
                  axis: Axis.vertical,
                  builder: (context, area) {
                    switch (area.id) {
                      case 'top':
                        return buildGrid(
                            columns, items, theme, true, gridState);
                      case 'bottom':
                        return buildGrid(
                            columns, items, theme, false, gridState);
                      default:
                        return Container();
                    }
                  }),
            ),
          ),
        ),
      ],
    );
    // },
    // loading: () => const Center(child: CircularProgressIndicator()),
    // error: (error, stack) => Center(
    //   child: SelectableText('Error loading weapons: $error'),
    // ),
    // );
  }

  SizedBox buildToolbarButton(
      ThemeData theme, String text, bool value, ValueChanged<bool?> onChanged) {
    return SizedBox(
      height: 30,
      child: Card.outlined(
        margin: const EdgeInsets.symmetric(),
        child: CheckboxWithLabel(
          labelWidget: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(text,
                style: theme.textTheme.labelLarge!.copyWith(fontSize: 14)),
          ),
          textPadding: const EdgeInsets.only(left: 4),
          checkWrapper: (child) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: child,
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget buildGrid(List<WispGridColumn<Weapon>> columns, List<Weapon> items,
      ThemeData theme, bool isTop, WispGridState gridState) {
    return DefaultTextStyle.merge(
      style: theme.textTheme.labelLarge!.copyWith(fontSize: 14),
      child: WispGrid<Weapon>(
        gridState: gridState,
        updateGridState: (updateFunction) {
          ref.read(appSettings.notifier).update((state) {
            return state.copyWith(
                weaponsGridState: updateFunction(state.weaponsGridState));
          });
        },
        columns: columns,
        items: items,
        itemExtent: 50,
        rowBuilder: (item, modifiers, child) =>
            SizedBox(height: 50, child: child),
        onLoaded: (WispGridController<Weapon> controller) {
          if (isTop) {
            _gridStateManagerTop = controller;
          } else {
            _gridStateManagerBottom = controller;
          }
        },
      ),
    );
  }

  List<WispGridColumn<Weapon>> buildCols(ThemeData theme) {
    return [
      WispGridColumn(
        key: 'modVariant',
        isSortable: true,
        name: 'Mod',
        getSortValue: (weapon) => weapon.modVariant?.modInfo.nameOrId,
        itemCellBuilder: (item, modifiers) => Builder(builder: (context) {
          final modName = item.modVariant?.modInfo.nameOrId ?? "(vanilla)";
          return Tooltip(
            message: modName,
            child: Text(
              modName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall!.copyWith(fontSize: 14),
            ),
          );
        }),
        defaultState: WispGridColumnState(position: 0, width: 100),
      ),
      WispGridColumn(
        key: 'spritePaths',
        isSortable: false,
        name: '',
        itemCellBuilder: (item, modifiers) => WeaponImageCell(
          imagePaths: [
            item.hardpointGunSprite,
            item.hardpointSprite,
            item.turretGunSprite,
            item.turretSprite
          ].whereType<String>().toList(),
        ),
        defaultState: WispGridColumnState(position: 1, width: 40),
      ),
      WispGridColumn(
        key: 'name',
        isSortable: true,
        name: 'Name',
        getSortValue: (weapon) => weapon.name ?? weapon.id,
        itemCellBuilder: (item, modifiers) => Tooltip(
          message: item.id,
          child: Text(
            item.name ?? item.id,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall!.copyWith(fontSize: 14),
          ),
        ),
        defaultState: WispGridColumnState(position: 2, width: 150),
      ),
      WispGridColumn(
        key: 'weaponType',
        isSortable: true,
        name: 'Weapon Type',
        getSortValue: (weapon) => weapon.weaponType,
        itemCellBuilder: (item, modifiers) => Text(item.weaponType ?? ""),
        defaultState: WispGridColumnState(position: 3, width: 100),
      ),
      WispGridColumn(
        key: 'size',
        isSortable: true,
        name: 'Size',
        getSortValue: (weapon) => weapon.size,
        itemCellBuilder: (item, modifiers) => Text(item.size ?? ""),
        defaultState: WispGridColumnState(position: 4, width: 80),
      ),
      WispGridColumn(
        key: 'techManufacturer',
        isSortable: true,
        name: 'Tech/Manufacturer',
        getSortValue: (weapon) => weapon.techManufacturer,
        itemCellBuilder: (item, modifiers) => Text(item.techManufacturer ?? ""),
        defaultState: WispGridColumnState(position: 5, width: 150),
      ),
      WispGridColumn(
        key: 'damagePerShot',
        isSortable: true,
        name: 'Dmg/Shot',
        getSortValue: (weapon) => weapon.damagePerShot,
        itemCellBuilder: (item, modifiers) =>
            Text(item.damagePerShot?.toString() ?? ""),
        defaultState: WispGridColumnState(position: 6, width: 110),
      ),
      WispGridColumn(
        key: 'range',
        isSortable: true,
        name: 'Range',
        getSortValue: (weapon) => weapon.range,
        itemCellBuilder: (item, modifiers) =>
            Text(item.range?.toString() ?? ""),
        defaultState: WispGridColumnState(position: 7, width: 80),
      ),
      WispGridColumn(
        key: 'damagePerSecond',
        isSortable: true,
        name: 'Dmg/Sec',
        getSortValue: (weapon) => weapon.damagePerSecond,
        itemCellBuilder: (item, modifiers) =>
            Text(item.damagePerSecond?.toString() ?? ""),
        defaultState: WispGridColumnState(position: 8, width: 90),
      ),
      WispGridColumn(
        key: 'ammo',
        isSortable: true,
        name: 'Ammo',
        getSortValue: (weapon) => weapon.ammo,
        itemCellBuilder: (item, modifiers) => Text(item.ammo?.toString() ?? ""),
        defaultState: WispGridColumnState(position: 9, width: 80),
      ),
      WispGridColumn(
        key: 'emp',
        isSortable: true,
        name: 'EMP',
        getSortValue: (weapon) => weapon.emp,
        itemCellBuilder: (item, modifiers) => Text(item.emp?.toString() ?? ""),
        defaultState: WispGridColumnState(position: 10, width: 80),
      ),
      WispGridColumn(
        key: 'turnRate',
        isSortable: true,
        name: 'Turn Rate',
        getSortValue: (weapon) => weapon.turnRate,
        itemCellBuilder: (item, modifiers) =>
            Text(item.turnRate?.toString() ?? ""),
        defaultState: WispGridColumnState(position: 11, width: 90),
      ),
      WispGridColumn(
        key: 'tier',
        isSortable: true,
        name: 'Tier',
        getSortValue: (weapon) => weapon.tier,
        itemCellBuilder: (item, modifiers) => Text(item.tier?.toString() ?? ""),
        defaultState: WispGridColumnState(position: 12, width: 60),
      ),
    ];
  }

  SizedBox buildSearchBox() {
    return SizedBox(
      height: 30,
      width: 300,
      child: SearchAnchor(
        searchController: _searchController,
        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            controller: controller,
            leading: const Icon(Icons.search),
            hintText: "Filter...",
            trailing: [
              controller.value.text.isEmpty
                  ? Container()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                      },
                    )
            ],
            backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainer,
            ),
            onChanged: (value) {
              setState(() {});
            },
          );
        },
        suggestionsBuilder:
            (BuildContext context, SearchController controller) {
          return [];
        },
      ),
    );
  }
}

// Custom widget for asynchronously checking file existence and displaying the image
class WeaponImageCell extends StatefulWidget {
  final List<String> imagePaths;

  const WeaponImageCell({super.key, required this.imagePaths});

  @override
  State<WeaponImageCell> createState() => _WeaponImageCellState();
}

class _WeaponImageCellState extends State<WeaponImageCell> {
  static final Map<String, bool> _fileExistsCache = {};

  String? _existingImagePath;

  @override
  void initState() {
    super.initState();
    _findExistingImagePath();
  }

  void _findExistingImagePath() async {
    for (String path in widget.imagePaths) {
      if (_fileExistsCache.containsKey(path)) {
        if (_fileExistsCache[path] == true) {
          _existingImagePath = path;
          break;
        }
      } else {
        bool exists = await File(path).exists();
        _fileExistsCache[path] = exists;
        if (exists) {
          _existingImagePath = path;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        // Trigger a rebuild with the found image path
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_existingImagePath == null) {
      // While checking or if no image is found, show a placeholder
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: Icon(Icons.image_not_supported)),
      );
    } else {
      return Image.file(
        File(_existingImagePath!),
        width: 40,
        height: 40,
        fit: BoxFit.contain,
      );
    }
  }
}
