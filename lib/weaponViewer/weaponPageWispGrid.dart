import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/models/context_menu.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/models/context_menu_entry.dart';
import 'package:trios/thirdparty/flutter_context_menu/widgets/context_menu_region.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weaponViewer/models/weapon.dart';
import 'package:trios/weaponViewer/weaponsManager.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';

import '../trios/context_menu_items.dart';
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
  bool showEnabledOnly = false;
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
    final mods = ref.watch(AppState.mods);
    gameCorePath =
        ref.watch(appSettings.select((s) => s.gameCoreDir))?.path ?? '';
    List<Weapon> items = weaponListAsyncValue.valueOrNull ?? [];
    final allItemsCount = items.length;

    if (showEnabledOnly) {
      items = items.where((items) {
        return items.modVariant == null ||
            items.modVariant?.mod(mods)?.hasEnabledVariant == true;
      }).toList();
    }

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

    final filteredWeaponCount = items.length;

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
                            '${allItemsCount ?? "..."} Weapons${allItemsCount != filteredWeaponCount ? " ($filteredWeaponCount shown)" : ""}',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(fontSize: 20),
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
                    Center(child: buildSearchBox()),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          MovingTooltipWidget.text(
                            message: "Only weapons from enabled mods.",
                            child: TriOSToolbarCheckboxButton(
                              text: "Only Enabled",
                              value: showEnabledOnly,
                              onChanged: (value) {
                                setState(() {
                                  showEnabledOnly = value ?? false;
                                });
                              },
                            ),
                          ),
                          MovingTooltipWidget.text(
                            message: "Show hidden weapons",
                            child: TriOSToolbarCheckboxButton(
                              text: "Show Hidden",
                              value: showHiddenWeapons,
                              onChanged: (value) {
                                setState(() {
                                  showHiddenWeapons = value ?? false;
                                });
                              },
                            ),
                          ),
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
                ),
              ),
              child: MultiSplitView(
                controller: multiSplitController,
                axis: Axis.vertical,
                builder: (context, area) {
                  switch (area.id) {
                    case 'top':
                      return buildGrid(columns, items, theme, true, gridState);
                    case 'bottom':
                      return buildGrid(columns, items, theme, false, gridState);
                    default:
                      return Container();
                  }
                },
              ),
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

  Widget buildRowContextMenu(Weapon weapon, Widget child) {
    final weaponSpritePath = spritesForWeapon(weapon).firstOrNull;
    return ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: <ContextMenuEntry>[
          if (weaponSpritePath != null)
            buildOpenSingleFolderMenuItem(
              weapon.csvFile.parent,
              secondFolder: weapon.wpnFile?.parent,
              label: 'Open weapon data folder(s)',
            ),
        ],
        padding: const EdgeInsets.all(8.0),
      ),
      // Container needed to add hit detection to the non-Text parts of the row.
      child: Container(color: Colors.transparent, child: child),
    );
  }

  Widget buildGrid(
    List<WispGridColumn<Weapon>> columns,
    List<Weapon> items,
    ThemeData theme,
    bool isTop,
    WispGridState gridState,
  ) {
    return DefaultTextStyle.merge(
      style: theme.textTheme.labelLarge!.copyWith(fontSize: 14),
      child: WispGrid<Weapon>(
        gridState: gridState,
        updateGridState: (updateFunction) {
          ref.read(appSettings.notifier).update((state) {
            return state.copyWith(
              weaponsGridState:
                  updateFunction(state.weaponsGridState) ??
                  Settings().weaponsGridState,
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
            SizedBox(
              height: 50,
              child: Container(
                color: Colors.transparent,
                child: buildRowContextMenu(item, child),
              ),
            ),
        onLoaded: (WispGridController<Weapon> controller) {
          if (isTop) {
            _gridStateManagerTop = controller;
          } else {
            _gridStateManagerBottom = controller;
          }
        },
        groups: [UngroupedWeaponGridGroup(), ModNameWeaponGridGroup()],
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
        itemCellBuilder: (item, modifiers) => Builder(
          builder: (context) {
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
          },
        ),
        defaultState: WispGridColumnState(position: 0, width: 100),
      ),
      WispGridColumn(
        key: 'spritePaths',
        isSortable: false,
        name: '',
        itemCellBuilder: (item, modifiers) =>
            WeaponImageCell(imagePaths: spritesForWeapon(item)),
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

  List<String> spritesForWeapon(Weapon item) {
    return [
      item.hardpointGunSprite,
      item.hardpointSprite,
      item.turretGunSprite,
      item.turretSprite,
    ].whereType<String>().toList();
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
                    ),
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

final Map<String, bool> _weaponImagePathCache = {};

/// Returns the first existing image path from the list
Future<String?> _getWeaponImagePath(List<String> imagePaths) async {
  for (String path in imagePaths) {
    if (_weaponImagePathCache.containsKey(path)) {
      if (_weaponImagePathCache[path] == true) {
        return path;
      }
    } else {
      bool exists = await File(path).exists();
      _weaponImagePathCache[path] = exists;
      if (exists) {
        return path;
      }
    }
  }
  return null;
}

// Custom widget for asynchronously checking file existence and displaying the image
class WeaponImageCell extends StatefulWidget {
  final List<String> imagePaths;

  const WeaponImageCell({super.key, required this.imagePaths});

  @override
  State<WeaponImageCell> createState() => _WeaponImageCellState();
}

class _WeaponImageCellState extends State<WeaponImageCell> {
  String? _existingImagePath;

  @override
  void initState() {
    super.initState();
    _findExistingImagePath();
  }

  void _findExistingImagePath() async {
    _existingImagePath = await _getWeaponImagePath(widget.imagePaths);

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
      return InkWell(
        onTap: () {
          _existingImagePath?.toFile().showInExplorer();
        },
        child: Image.file(
          File(_existingImagePath!),
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
      );
    }
  }
}

class UngroupedWeaponGridGroup extends WispGridGroup<Weapon> {
  UngroupedWeaponGridGroup() : super('none', 'None');

  @override
  String getGroupName(Weapon mod) => 'All Weapons';

  @override
  Comparable getGroupSortValue(Weapon mod) => 1;

  @override
  bool get isGroupVisible => false;
}

class ModNameWeaponGridGroup extends WispGridGroup<Weapon> {
  ModNameWeaponGridGroup() : super('modId', 'Mod');

  @override
  String getGroupName(Weapon mod) =>
      mod.modVariant?.modInfo.nameOrId ?? 'Vanilla';

  @override
  Comparable getGroupSortValue(Weapon mod) =>
      mod.modVariant?.modInfo.nameOrId.toLowerCase() ?? '        ';
}
