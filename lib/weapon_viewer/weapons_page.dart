import 'dart:io';

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
        ref
            .read(weaponsPageControllerProvider.notifier)
            .setChipSelections('mod', {filterRequest.modName: true});
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
        onChanged: (query) =>
            ref.read(weaponsPageControllerProvider.notifier).updateSearchQuery(query),
        onSubmitted: () =>
            ref.read(weaponsPageControllerProvider.notifier).submitSearchQuery(),
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
                onTap: () => _showWeaponDetailsDialog(context, item),
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

  void _showWeaponDetailsDialog(BuildContext context, Weapon w) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInfoPane(w, theme, context),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Wrap(
                          spacing: 4,
                          children: [
                            if (w.wpnFile != null)
                              IconButton(
                                tooltip: 'Open .wpn file',
                                icon: const Icon(Icons.edit_note),
                                onPressed: () =>
                                    w.wpnFile!.absolute.showInExplorer(),
                              ),
                            IconButton(
                              tooltip: 'Open weapon_data.csv',
                              icon: const Icon(Icons.edit_note),
                              onPressed: () =>
                                  w.csvFile?.absolute.showInExplorer(),
                            ),
                            if (w.spritesForWeapon.isNotEmpty)
                              IconButton(
                                tooltip: 'Open weapon data folder(s)',
                                icon: const Icon(Icons.folder),
                                onPressed: () {
                                  w.csvFile?.parent.path.openAsUriInBrowser();
                                  final wpnParent = w.wpnFile?.parent;
                                  if (wpnParent != null &&
                                      wpnParent.path != w.csvFile?.parent.path) {
                                    wpnParent.path.openAsUriInBrowser();
                                  }
                                },
                              ),
                          ],
                        ),
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

  Column _buildInfoPane(Weapon w, ThemeData theme, BuildContext context) {
    final imagePaths = w.spritesForWeapon;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    w.name ?? w.id,
                    style: theme.textTheme.titleLarge?.copyWith(
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SelectableText(w.id, style: theme.textTheme.labelSmall),
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: imagePaths
              .map(
                (p) => FutureBuilder<String?>(
                  future: _getWeaponImagePath([p]),
                  builder: (context, snap) {
                    final path = snap.data;
                    if (path == null) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: () => path.toFile().showInExplorer(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MovingTooltipWidget.image(
                            path: path,
                            child: Image.file(
                              File(path),
                              width: 56,
                              height: 56,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 56,
                            child: TextTriOS(
                              path.split(Platform.pathSeparator).last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
        if (w.customPrimary != null || w.customAncillary != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              if ((w.customPrimary ?? '').isNotEmpty)
                DescriptionWithSubstitutions(
                  description: w.customPrimary!,
                  highlightValues: w.customPrimaryHL,
                  highlightColor: theme.colorScheme.secondary,
                  baseStyle: theme.textTheme.bodySmall,
                ),
              if ((w.customAncillary ?? '').isNotEmpty)
                DescriptionWithSubstitutions(
                  description: w.customAncillary!,
                  highlightValues: w.customAncillaryHL,
                  highlightColor: theme.colorScheme.secondary,
                  baseStyle: theme.textTheme.bodySmall,
                ),
            ],
          ),
        const SizedBox(height: 8),
        WeaponCodexCard.create(
          weapon: w,
          showTitle: false,
          useAbbreviations: false,
        ),
        // Builder(
        //   builder: (context) {
        //     final desc = ref.watch(
        //       descriptionProvider((w.id, DescriptionEntry.typeWeapon)),
        //     );
        //     if (desc?.text1 == null) return const SizedBox.shrink();
        //     return Padding(
        //       padding: const EdgeInsets.only(top: 8),
        //       child: DescriptionWithSubstitutions(
        //         description: desc!.text1!,
        //         baseStyle: theme.textTheme.bodyMedium,
        //       ),
        //     );
        //   },
        // ),
        Divider(color: Theme.of(context).colorScheme.outline),
        _kv(
          w.modVariant != null ? 'Mod' : null,
          w.modVariant?.modInfo.nameOrId ?? 'Vanilla',
          theme,
        ),
        _kv('Type', w.weaponType?.toTitleCase(), theme),
        _kv('Size', w.size?.toTitleCase(), theme),
        _kv('Tech/Manufacturer', w.techManufacturer, theme),
        _kv('Spec Class', w.specClass, theme),
        _kv('Raw Type', w.type, theme),
        // Combat
        section('Combat'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Dmg/Shot', _fmtNum(w.damagePerShot)),
            _chip('Dmg/Sec', _fmtNum(w.damagePerSecond)),
            _chip('EMP', _fmtNum(w.emp)),
            _chip('Impact', _fmtNum(w.impact)),
            _chip('Range', _fmtNum(w.range)),
            _chip('Turn Rate', _fmtNum(w.turnRate)),
            _chip('OP', _fmtNum(w.ops)),
          ],
        ),
        // Fire Mechanics
        section('Fire Mechanics'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Ammo', _fmtNum(w.ammo)),
            _chip('Ammo/Sec', _fmtNum(w.ammoPerSec)),
            _chip('Reload Size', _fmtNum(w.reloadSize)),
            _chip('Energy/Shot', _fmtNum(w.energyPerShot)),
            _chip('Energy/Sec', _fmtNum(w.energyPerSecond)),
            _chip('Chargeup', _fmtNum(w.chargeup)),
            _chip('Chargedown', _fmtNum(w.chargedown)),
            _chip('Burst Size', _fmtNum(w.burstSize)),
            _chip('Burst Delay', _fmtNum(w.burstDelay)),
          ],
        ),
        // Accuracy & Spread
        section('Accuracy & Spread'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Min Spread', _fmtNum(w.minSpread)),
            _chip('Max Spread', _fmtNum(w.maxSpread)),
            _chip('Spread/Shot', _fmtNum(w.spreadPerShot)),
            _chip('Spread Decay/Sec', _fmtNum(w.spreadDecayPerSec)),
            _chip('Autofire Acc Bonus', _fmtNum(w.autofireAccBonus)),
            if ((w.extraArcForAI ?? '').isNotEmpty)
              _chip('Extra Arc (AI)', w.extraArcForAI!),
          ],
        ),
        // Projectile
        section('Projectile'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Beam Speed', _fmtNum(w.beamSpeed)),
            _chip('Proj Speed', _fmtNum(w.projSpeed)),
            _chip('Launch Speed', _fmtNum(w.launchSpeed)),
            _chip('Flight Time', _fmtNum(w.flightTime)),
            _chip('Proj HP', _fmtNum(w.projHitpoints)),
          ],
        ),
        // Misc
        section('Misc'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Tier', _fmtNum(w.tier)),
            _chip('Rarity', _fmtNum(w.rarity)),
            _chip('Base Value', w.baseValue.asCredits()),
            if (w.number != null) _chip('Number', _fmtNum(w.number)),
            if (w.noDPSInTooltip == true) _chip('No DPS In Tooltip', 'Yes'),
            if ((w.hints ?? '').isNotEmpty) _chip('Hints', w.hints!),
            if ((w.tags ?? '').isNotEmpty) _chip('Tags', w.tags!),
            if ((w.groupTag ?? '').isNotEmpty) _chip('Group Tag', w.groupTag!),
            if ((w.forWeaponTooltip ?? '').isNotEmpty)
              _chip('For Weapon Tooltip', w.forWeaponTooltip!),
            if ((w.primaryRoleStr ?? '').isNotEmpty)
              _chip('Primary Role', w.primaryRoleStr!),
            if ((w.speedStr ?? '').isNotEmpty) _chip('Speed', w.speedStr!),
            if ((w.trackingStr ?? '').isNotEmpty)
              _chip('Tracking', w.trackingStr!),
            if ((w.turnRateStr ?? '').isNotEmpty)
              _chip('Turn Rate (txt)', w.turnRateStr!),
            if ((w.accuracyStr ?? '').isNotEmpty)
              _chip('Accuracy', w.accuracyStr!),
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
      child: SelectableText.rich(
        TextSpan(
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

  Widget buildRowContextMenu(Weapon weapon, Widget child) {
    final weaponSpritePath = weapon.spritesForWeapon.firstOrNull;
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
          imagePaths: item.spritesForWeapon,
          fit: controllerState.useContainFit
              ? BoxFit.contain
              : BoxFit.scaleDown,
        ),
        csvValue: (weapon) => weapon.spritesForWeapon.join(","),
        defaultState: WispGridColumnState(position: position++, width: 40),
      ),
      WispGridColumn(
        key: 'name',
        isSortable: true,
        name: 'Name',
        getSortValue: (w) => w.name ?? w.id,
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
      col(
        'speedStr',
        'Speed',
        (w) => w.speedStr,
        width: 90,
        isVisible: false,
      ),
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
      col(
        'energyPerShot',
        'Flux/Shot',
        (w) => w.energyPerShot,
        width: 90,
      ),
      col(
        'energyPerSecond',
        'Flux/Sec',
        (w) => w.energyPerSecond,
        width: 90,
      ),
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
      ],
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
  final BoxFit fit;

  const WeaponImageCell({
    super.key,
    required this.imagePaths,
    this.fit = BoxFit.scaleDown,
  });

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
      return MovingTooltipWidget.image(
        path: _existingImagePath!,
        child: InkWell(
          onTap: () {
            _existingImagePath?.toFile().showInExplorer();
          },
          child: Image.file(
            File(_existingImagePath!),
            width: 40,
            height: 40,
            fit: widget.fit,
          ),
        ),
      );
    }
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
