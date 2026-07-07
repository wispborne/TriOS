import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/flutter_context_menu/components/menu_item.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/models/context_menu.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/models/context_menu_entry.dart';
import 'package:trios/thirdparty/flutter_context_menu/widgets/context_menu_region.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/weapons_manager.dart';
import 'package:trios/weapon_viewer/weapons_page_controller.dart';
import 'package:trios/weapon_viewer/widgets/weapon_codex_card.dart';
import 'package:trios/weapon_viewer/widgets/weapon_details_dialog.dart';
import 'package:trios/weapon_viewer/widgets/weapon_image_cell.dart';
import 'package:trios/widgets/collapsed_filter_button.dart';
import 'package:trios/widgets/export_to_csv_dialog.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_widget.dart';
import 'package:trios/widgets/overflow_menu_button.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/smart_search/smart_search_bar.dart';
import 'package:trios/widgets/viewer_split_pane.dart';
import 'package:trios/widgets/viewer_toolbar.dart';

import '../trios/navigation.dart';
import '../widgets/multi_split_mixin_view.dart';

final _nonAlphanumeric = RegExp(r'[^0-9a-zA-Z]');

class WeaponsPage extends ConsumerStatefulWidget {
  const WeaponsPage({super.key});

  @override
  ConsumerState<WeaponsPage> createState() => _WeaponsPageState();
}

class _WeaponsPageState extends ConsumerState<WeaponsPage>
    with AutomaticKeepAliveClientMixin<WeaponsPage>, MultiSplitViewMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _filterScrollController = ScrollController();
  WispGridController<Weapon>? _gridController;
  Widget? _cachedBuild;

  @override
  List<Area> get areas {
    final controllerState = ref.read(weaponsPageControllerProvider);
    return controllerState.splitPane
        ? [Area(id: 'top'), Area(id: 'bottom')]
        : [Area(id: 'top')];
  }

  @override
  void dispose() {
    _filterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isActive =
        ref.watch(appSettings.select((s) => s.defaultTool)) ==
        TriOSTools.weapons;
    if (!isActive && _cachedBuild != null) return _cachedBuild!;

    final controller = ref.watch(weaponsPageControllerProvider.notifier);
    final controllerState = ref.watch(weaponsPageControllerProvider);
    final theme = Theme.of(context);
    final mods = ref.watch(AppState.mods);

    // Apply pending mod filter from context menu navigation.
    final filterRequest = ref.watch(AppState.viewerFilterRequest);
    if (filterRequest != null &&
        filterRequest.destination == TriOSTools.weapons) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(weaponsPageControllerProvider.notifier).setChipSelections(
          'mod',
          {filterRequest.modName: true},
        );
        ref.read(AppState.viewerFilterRequest.notifier).state = null;
      });
    }

    final columns = buildCols(theme, controllerState);
    final total = controllerState.allWeapons.length;
    final visible = controllerState.filteredWeapons.length;

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

    _cachedBuild = result;
    return result;
  }

  Widget _buildToolbar(
    BuildContext context,
    ThemeData theme,
    int total,
    int visible,
    WeaponsPageController controller,
    WeaponsPageState controllerState,
  ) {
    return ViewerToolbar(
      entityName: "Weapons",
      total: total,
      visible: visible,
      isLoading: controllerState.isLoading,
      onRefresh: () => ref.invalidate(weaponListNotifierProvider),
      searchBox: SmartSearchBar(
        fields: controller.searchFieldsMeta,
        recentHistory: ref.watch(
          appSettings.select((s) => s.weaponsSearchHistory),
        ),
        initialValue: controllerState.currentSearchQuery,
        onChanged: (query) => ref
            .read(weaponsPageControllerProvider.notifier)
            .updateSearchQuery(query),
        onSubmitted: () => ref
            .read(weaponsPageControllerProvider.notifier)
            .submitSearchQuery(),
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
    WeaponsPageState controllerState,
    WeaponsPageController controller,
    List<Weapon> weaponsBeforeFilter,
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
        weaponsBeforeFilter,
        controllerState,
        controller,
      ),
    );
  }

  Widget _buildGridSection(
    ThemeData theme,
    WeaponsPageState controllerState,
    List<WispGridColumn<Weapon>> columns,
    List<Weapon> weapons,
    List<Mod> mods,
  ) {
    return ViewerSplitPane(
      controller: multiSplitController,
      gridBuilder: (areaId) {
        switch (areaId) {
          case 'top':
            return buildGrid(columns, weapons, mods, true, theme);
          case 'bottom':
            return buildGrid(columns, weapons, mods, false, theme);
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  FiltersPanel buildFilterPanel(
    ThemeData theme,
    List<Weapon> displayedWeapons,
    WeaponsPageState controllerState,
    WeaponsPageController controller,
  ) {
    return FiltersPanel(
      onHide: controller.toggleShowFilters,
      scrollController: _filterScrollController,
      activeFilterCount: controller.activeFilterCount,
      showClearAll: controller.filterGroups.any((g) => g.isActive),
      onClearAll: controller.clearAllFilters,
      filterWidgets: [
        for (final g in controller.filterGroups)
          FilterGroupRenderer<Weapon>(
            group: g,
            scope: controller.scope,
            items: displayedWeapons,
            onChanged: () => controller.onGroupChanged(g.id),
          ),
      ],
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
        onLoaded: (controller) {
          _gridController = controller;
        },
        columns: columns,
        items: items,
        itemExtent: 40,
        scrollbarConfig: ScrollbarConfig(
          showLeftScrollbar: ScrollbarVisibility.always,
          showRightScrollbar: ScrollbarVisibility.always,
          showBottomScrollbar: ScrollbarVisibility.always,
        ),
        rowBuilder: ({required item, required modifiers, required child}) =>
            SizedBox(
              height: 40,
              child: InkWell(
                onTap: () => showWeaponDetailsDialog(context, item),
                child: Container(
                  // Needed to add hit detection for right-clicking.
                  color: Colors.transparent,
                  child: buildRowContextMenu(item, child),
                ),
              ),
            ),
        groups: [UngroupedWeaponGridGroup(), ModNameWeaponGridGroup()],
      ),
    );
  }

  Widget buildRowContextMenu(Weapon weapon, Widget child) {
    final weaponSpritePath = weapon.allSpriteFiles.firstOrNull;
    return ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: <ContextMenuEntry>[
          MenuItem(
            label: 'Copy ID',
            icon: Icons.copy,
            onSelected: () => Clipboard.setData(ClipboardData(text: weapon.id)),
          ),
          if (weapon.wpnFile != null)
            MenuItem(
              label: 'Open .wpn file',
              icon: Icons.edit_note,
              onSelected: () {
                weapon.wpnFile!.absolute.showInExplorer();
              },
            ),
          if (weapon.csvFile != null)
            MenuItem(
              label: 'Open weapon_data.csv',
              icon: Icons.edit_note,
              onSelected: () {
                weapon.csvFile!.absolute.showInExplorer();
              },
            ),
          if (weaponSpritePath != null && weapon.csvFile != null)
            buildOpenSingleFolderMenuItem(
              weapon.csvFile!.parent,
              secondFolder: weapon.wpnFile?.parent,
              label: 'Open weapon data folder(s)',
            ),
          if (weapon.modVariant != null)
            buildOpenSingleFolderMenuItem(
              weapon.modVariant!.modFolder.absolute,
              label: 'Open Mod Folder',
            ),
          if (weapon.modVariant != null)
            buildMenuItemOpenForumPage(weapon.modVariant!, context),
        ],
        padding: const EdgeInsets.all(8.0),
      ),
      // Container needed to add hit detection to the non-Text parts of the row.
      child: Container(color: Colors.transparent, child: child),
    );
  }

  List<WispGridColumn<Weapon>> buildCols(
    ThemeData theme,
    WeaponsPageState controllerState,
  ) {
    int position = 0;

    String wepValueToString(
      Comparable<dynamic>? Function(Weapon) getValue,
      Weapon item,
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
    WispGridColumn<Weapon> col(
      String key,
      String name,
      Comparable<dynamic>? Function(Weapon) getValue, {
      double width = 100,
      bool isVisible = true,
    }) {
      return WispGridColumn<Weapon>(
        key: key,
        isSortable: true,
        name: name,
        getSortValue: getValue,
        itemCellBuilder: (item, _) {
          return TextTriOS(
            wepValueToString(getValue, item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
        csvValue: (item) => wepValueToString(getValue, item),
        defaultState: WispGridColumnState(
          position: position++,
          width: width,
          isVisible: isVisible,
        ),
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
          style: theme.textTheme.labelLarge,
        ),
        csvValue: (weapon) => weapon.modVariant?.modInfo.nameOrId ?? "Vanilla",
        defaultState: WispGridColumnState(position: position++, width: 120),
      ),
      WispGridColumn(
        key: 'spritePaths',
        isSortable: false,
        name: '',
        itemCellBuilder: (item, modifiers) => WeaponImageCell(
          weapon: item,
          fit: controllerState.useContainFit
              ? BoxFit.contain
              : BoxFit.scaleDown,
          rowHovered: modifiers.isHovering,
        ),
        csvValue: (weapon) => weapon.allSpriteFiles.join(","),
        defaultState: WispGridColumnState(position: position++, width: 40),
      ),
      WispGridColumn(
        key: 'name',
        isSortable: true,
        name: 'Name',
        getSortValue: (w) => (w.name ?? w.id).replaceAll(_nonAlphanumeric, ''),
        itemCellBuilder: (w, _) => WeaponCodexCard.tooltip(
          weapon: w,
          child: MouseRegion(
            cursor: SystemMouseCursors.none,
            child: Text(
              w.name ?? w.id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge,
            ),
          ),
        ),
        csvValue: (weapon) => weapon.modVariant?.modInfo.nameOrId ?? "Vanilla",
        defaultState: WispGridColumnState(position: position++, width: 150),
      ),
      col('id', 'ID', (w) => w.id),
      col(
        'weaponType',
        'Weapon Type',
        (w) => w.weaponType?.toTitleCase(),
        width: 100,
      ),
      col('size', 'Size', (w) => w.size?.toTitleCase(), width: 80),
      col(
        'damageType',
        'Dmg Type',
        (w) => w.damageType?.toTitleCase(),
        width: 90,
      ),
      col(
        'techManufacturer',
        'Tech/Manufacturer',
        (w) => w.techManufacturer,
        width: 150,
      ),
      col(
        'specClass',
        'Spec Class',
        (w) => w.specClass,
        width: 100,
        isVisible: false,
      ),
      col(
        'primaryRoleStr',
        'Role',
        (w) => w.primaryRoleStr,
        width: 110,
        isVisible: false,
      ),
      col(
        'accuracyStr',
        'Accuracy',
        (w) => w.accuracyStr,
        width: 100,
        isVisible: false,
      ),
      col(
        'trackingStr',
        'Tracking',
        (w) => w.trackingStr,
        width: 100,
        isVisible: false,
      ),
      col('speedStr', 'Speed', (w) => w.speedStr, width: 90, isVisible: false),
      col(
        'turnRateStr',
        'Turn Rate (text)',
        (w) => w.turnRateStr,
        width: 110,
        isVisible: false,
      ),
      col('damagePerShot', 'Dmg/Shot', (w) => w.damagePerShot, width: 110),
      col('impact', 'Impact', (w) => w.impact, width: 80, isVisible: false),
      col('op', 'OP', (w) => w.ops, width: 110),
      col('baseValue', 'Cost', (w) => w.baseValue, width: 80),
      col('energyPerShot', 'Flux/Shot', (w) => w.energyPerShot, width: 90),
      col('energyPerSecond', 'Flux/Sec', (w) => w.energyPerSecond, width: 90),
      col('range', 'Range', (w) => w.range, width: 80),
      col('damagePerSecond', 'Dmg/Sec', (w) => w.damagePerSecond, width: 90),
      col('ammo', 'Ammo', (w) => w.ammo, width: 80),
      col(
        'ammoPerSec',
        'Ammo/Sec',
        (w) => w.ammoPerSec,
        width: 90,
        isVisible: false,
      ),
      col(
        'reloadSize',
        'Reload Size',
        (w) => w.reloadSize,
        width: 100,
        isVisible: false,
      ),
      col('emp', 'EMP', (w) => w.emp, width: 80),
      col(
        'chargeup',
        'Chargeup',
        (w) => w.chargeup,
        width: 90,
        isVisible: false,
      ),
      col(
        'chargedown',
        'Chargedown',
        (w) => w.chargedown,
        width: 100,
        isVisible: false,
      ),
      col(
        'burstSize',
        'Burst Size',
        (w) => w.burstSize,
        width: 90,
        isVisible: false,
      ),
      col(
        'burstDelay',
        'Burst Delay',
        (w) => w.burstDelay,
        width: 100,
        isVisible: false,
      ),
      col(
        'minSpread',
        'Min Spread',
        (w) => w.minSpread,
        width: 100,
        isVisible: false,
      ),
      col(
        'maxSpread',
        'Max Spread',
        (w) => w.maxSpread,
        width: 100,
        isVisible: false,
      ),
      col(
        'spreadPerShot',
        'Spread/Shot',
        (w) => w.spreadPerShot,
        width: 110,
        isVisible: false,
      ),
      col(
        'spreadDecayPerSec',
        'Spread Decay',
        (w) => w.spreadDecayPerSec,
        width: 110,
        isVisible: false,
      ),
      col(
        'autofireAccBonus',
        'AF Acc Bonus',
        (w) => w.autofireAccBonus,
        width: 110,
        isVisible: false,
      ),
      col(
        'projSpeed',
        'Proj Speed',
        (w) => w.projSpeed,
        width: 100,
        isVisible: false,
      ),
      col(
        'beamSpeed',
        'Beam Speed',
        (w) => w.beamSpeed,
        width: 100,
        isVisible: false,
      ),
      col(
        'launchSpeed',
        'Launch Speed',
        (w) => w.launchSpeed,
        width: 110,
        isVisible: false,
      ),
      col(
        'flightTime',
        'Flight Time',
        (w) => w.flightTime,
        width: 100,
        isVisible: false,
      ),
      col(
        'projHitpoints',
        'Proj HP',
        (w) => w.projHitpoints,
        width: 90,
        isVisible: false,
      ),
      col('turnRate', 'Turn Rate', (w) => w.turnRate, width: 90),
      col('tier', 'Tier', (w) => w.tier, width: 60),
      col('rarity', 'Rarity', (w) => w.rarity, width: 80, isVisible: false),
      col('hints', 'Hints', (w) => w.hints, width: 150, isVisible: false),
      col('tags', 'Tags', (w) => w.tags, width: 150, isVisible: false),
      col(
        'groupTag',
        'Group Tag',
        (w) => w.groupTag,
        width: 120,
        isVisible: false,
      ),
    ];
  }

  Widget _buildOverflowButton({
    required BuildContext context,
    required ThemeData theme,
    required WeaponsPageState controllerState,
  }) {
    final controller = ref.read(weaponsPageControllerProvider.notifier);
    return OverflowMenuButton(
      menuItems: [
        OverflowMenuItem(
          title: 'Export to CSV',
          icon: Icons.table_view,
          onTap: () {
            if (_gridController == null) return;

            showExportOrCopyDialog(
              context,
              "weapon",
              () => WispGridCsvExporter.toCsv(
                _gridController!,
                includeHeaders: true,
              ),
              () => ref
                  .read(weaponListNotifierProvider.notifier)
                  .allWeaponsAsCsv(),
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
          title: 'Always show weapon glow',
          icon: Icons.auto_awesome,
          checked: controllerState.alwaysShowGlow,
          onTap: () => controller.toggleAlwaysShowGlow(),
        ).toEntry(2),
      ],
    );
  }
}

class UngroupedWeaponGridGroup extends WispGridGroup<Weapon> {
  UngroupedWeaponGridGroup() : super('none', 'None');

  @override
  String getGroupName(Weapon mod, {Comparable? groupSortValue}) =>
      'All Weapons';

  @override
  Comparable getGroupSortValue(Weapon mod) => 1;

  @override
  bool get isGroupVisible => false;
}

class ModNameWeaponGridGroup extends WispGridGroup<Weapon> {
  ModNameWeaponGridGroup() : super('modId', 'Mod');

  @override
  String getGroupName(Weapon mod, {Comparable? groupSortValue}) =>
      mod.modVariant?.modInfo.nameOrId ?? 'Vanilla';

  @override
  Comparable getGroupSortValue(Weapon mod) =>
      mod.modVariant?.modInfo.nameOrId.toLowerCase() ?? '        ';
}
