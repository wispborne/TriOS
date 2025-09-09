import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/shipViewer/filter_widget.dart';
import 'package:trios/themes/theme_manager.dart' show ThemeManager;
import 'package:trios/thirdparty/flutter_context_menu/core/models/context_menu.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/models/context_menu_entry.dart';
import 'package:trios/thirdparty/flutter_context_menu/widgets/context_menu_region.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weaponViewer/models/weapon.dart';
import 'package:trios/weaponViewer/weapons_manager.dart';
import 'package:trios/weaponViewer/weapons_page_controller.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';

import '../widgets/MultiSplitViewMixin.dart';

class WeaponsPage extends ConsumerStatefulWidget {
  const WeaponsPage({super.key});

  @override
  ConsumerState<WeaponsPage> createState() => _WeaponsPageState();
}

class _WeaponsPageState extends ConsumerState<WeaponsPage>
    with AutomaticKeepAliveClientMixin<WeaponsPage>, MultiSplitViewMixin {
  @override
  bool get wantKeepAlive => true;

  final SearchController _searchController = SearchController();
  final ScrollController _filterScrollController = ScrollController();

  @override
  List<Area> get areas {
    final controllerState = ref.read(weaponsPageControllerProvider);
    return controllerState.splitPane
        ? [Area(id: 'top'), Area(id: 'bottom')]
        : [Area(id: 'top')];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final controller = ref.watch(weaponsPageControllerProvider.notifier);
    final controllerState = ref.watch(weaponsPageControllerProvider);
    final theme = Theme.of(context);
    final mods = ref.watch(AppState.mods);

    final columns = buildCols(theme);
    final total = controllerState.allWeapons.length;
    final visible = controllerState.filteredWeapons.length;

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
                controllerState.weaponsBeforeGridFilter,
              ),
              Expanded(
                child: _buildGridSection(
                  theme,
                  controllerState,
                  columns,
                  controllerState.filteredWeapons,
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
    WeaponsPageController controller,
    WeaponsPageState controllerState,
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
                        '$total Weapons${total != visible ? " ($visible shown)" : ""}',
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
                        message: "Only weapons from enabled mods.",
                        child: TriOSToolbarCheckboxButton(
                          text: "Only Enabled",
                          value: controllerState.showEnabled,
                          onChanged: (value) => controller.toggleShowEnabled(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MovingTooltipWidget.text(
                        message: "Show hidden weapons.",
                        child: TriOSToolbarCheckboxButton(
                          text: "Show Hidden",
                          value: controllerState.showHidden,
                          onChanged: (value) => controller.toggleShowHidden(),
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
                                ref.invalidate(weaponListNotifierProvider),
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
    WeaponsPageState controllerState,
    WeaponsPageController controller,
    List<Weapon> weaponsBeforeFilter,
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
      weaponsBeforeFilter,
      controllerState,
      controller,
    );
  }

  Widget _buildGridSection(
    ThemeData theme,
    WeaponsPageState controllerState,
    List<WispGridColumn<Weapon>> columns,
    List<Weapon> weapons,
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
                return buildGrid(columns, weapons, mods, true, theme);
              case 'bottom':
                return buildGrid(columns, weapons, mods, false, theme);
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
    List<Weapon> displayedWeapons,
    WeaponsPageState controllerState,
    WeaponsPageController controller,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          child: Scrollbar(
            thumbVisibility: true,
            controller: _filterScrollController,
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
                          controller: _filterScrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: controllerState.filterCategories.map((
                              filter,
                            ) {
                              return GridFilterWidget<Weapon>(
                                filter: filter,
                                items: displayedWeapons,
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
    List<WispGridColumn<Weapon>> columns,
    List<Weapon> items,
    List<Mod> mods,
    bool isTop,
    ThemeData theme,
  ) {
    final gridState = ref.watch(appSettings.select((s) => s.weaponsGridState));

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
        groups: [UngroupedWeaponGridGroup(), ModNameWeaponGridGroup()],
      ),
    );
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

  List<WispGridColumn<Weapon>> buildCols(ThemeData theme) {
    int position = 0;

    // Reusable helper
    WispGridColumn<Weapon> col(
      String key,
      String name,
      Comparable<dynamic>? Function(Weapon) getValue, {
      double width = 100,
    }) {
      return WispGridColumn<Weapon>(
        key: key,
        isSortable: true,
        name: name,
        getSortValue: getValue,
        itemCellBuilder: (item, _) {
          final value = getValue(item);
          final str = switch (value) {
            double dbl => dbl.toStringAsFixed(2),
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
        getSortValue: (weapon) => weapon.modVariant?.modInfo.nameOrId,
        itemCellBuilder: (item, _) => TextTriOS(
          item.modVariant?.modInfo.nameOrId ?? "Vanilla",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        defaultState: WispGridColumnState(position: position++, width: 120),
      ),
      WispGridColumn(
        key: 'spritePaths',
        isSortable: false,
        name: '',
        itemCellBuilder: (item, modifiers) =>
            WeaponImageCell(imagePaths: spritesForWeapon(item)),
        defaultState: WispGridColumnState(position: position++, width: 40),
      ),
      col('name', 'Name', (w) => w.name ?? w.id, width: 150),
      col(
        'weaponType',
        'Weapon Type',
        (w) => w.weaponType?.toTitleCase(),
        width: 100,
      ),
      col('size', 'Size', (w) => w.size?.toTitleCase(), width: 80),
      col(
        'techManufacturer',
        'Tech/Manufacturer',
        (w) => w.techManufacturer,
        width: 150,
      ),
      col('damagePerShot', 'Dmg/Shot', (w) => w.damagePerShot, width: 110),
      col('range', 'Range', (w) => w.range, width: 80),
      col('damagePerSecond', 'Dmg/Sec', (w) => w.damagePerSecond, width: 90),
      col('ammo', 'Ammo', (w) => w.ammo, width: 80),
      col('emp', 'EMP', (w) => w.emp, width: 80),
      col('turnRate', 'Turn Rate', (w) => w.turnRate, width: 90),
      col('tier', 'Tier', (w) => w.tier, width: 60),
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
        builder: (context, controller) {
          return SearchBar(
            controller: controller,
            leading: const Icon(Icons.search),
            hintText: "Filter weapons...",
            trailing: [
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    ref
                        .read(weaponsPageControllerProvider.notifier)
                        .updateSearchQuery('');
                  },
                ),
            ],
            onChanged: (query) {
              ref
                  .read(weaponsPageControllerProvider.notifier)
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
