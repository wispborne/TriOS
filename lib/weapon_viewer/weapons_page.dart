import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:super_clipboard/super_clipboard.dart';
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
import 'package:trios/widgets/snackbar.dart';
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
                            if (w.allSpriteFiles.isNotEmpty)
                              IconButton(
                                tooltip: 'Open weapon data folder(s)',
                                icon: const Icon(Icons.folder),
                                onPressed: () {
                                  w.csvFile?.parent.path.openAsUriInBrowser();
                                  final wpnParent = w.wpnFile?.parent;
                                  if (wpnParent != null &&
                                      wpnParent.path !=
                                          w.csvFile?.parent.path) {
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
    final imagePaths = w.allSpriteFiles;

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

// Decoded-image cache for the layered weapon composite, keyed by file path.
final Map<String, Future<ui.Image?>> _weaponDecodedImageCache = {};

Future<ui.Image?> _loadWeaponImage(String path) {
  return _weaponDecodedImageCache.putIfAbsent(path, () async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  });
}

/// One composited sprite layer, positioned in weapon-pixel space where the
/// origin is the weapon's mount center.
class _WeaponLayer {
  final ui.Image image;

  /// Where this layer's [pivot] lands, relative to the mount center.
  final Offset center;

  /// The point within the image (image pixel coords) mapped onto [center].
  final Offset pivot;

  /// Rotation about [center], in radians.
  final double rotation;

  final Paint paint;

  /// For glow layers: the additive tint (from `glowColor`, or white). The
  /// painter builds the per-frame additive paint from this scaled by the
  /// current fade opacity, so glow intensity can animate.
  final Color? glowTint;

  _WeaponLayer({
    required this.image,
    required this.center,
    required this.pivot,
    required this.rotation,
    required this.paint,
    this.glowTint,
  });

  /// Axis-aligned bounds of this layer in weapon space.
  Rect get bounds {
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    final corners = [
      Offset(-pivot.dx, -pivot.dy),
      Offset(w - pivot.dx, -pivot.dy),
      Offset(w - pivot.dx, h - pivot.dy),
      Offset(-pivot.dx, h - pivot.dy),
    ];
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final c in corners) {
      final x = c.dx * cos - c.dy * sin + center.dx;
      final y = c.dx * sin + c.dy * cos + center.dy;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

/// Renders a weapon as the game does at rest: a single mount's sprite layers
/// (under → barrel/main, ordered by [Weapon.renderBarrelBelow]) plus any loaded
/// missiles, with the glow sprite drawn additively on top.
class WeaponImageCell extends ConsumerStatefulWidget {
  final Weapon weapon;
  final BoxFit fit;
  final double size;

  const WeaponImageCell({
    super.key,
    required this.weapon,
    this.fit = BoxFit.scaleDown,
    this.size = 40,
  });

  @override
  ConsumerState<WeaponImageCell> createState() => _WeaponImageCellState();
}

class _WeaponImageCellState extends ConsumerState<WeaponImageCell>
    with SingleTickerProviderStateMixin {
  List<_WeaponLayer> _layers = const [];

  // Glow layers, faded in/out by [_glowController] on hover (or pinned on when
  // "Always show weapon glow" is enabled).
  List<_WeaponLayer> _glowLayers = const [];
  Size _canvasSize = Size.zero;
  bool _loaded = false;
  bool _hovering = false;
  bool _alwaysShowGlow = false;

  late final AnimationController _glowController;

  static const double _deg2rad = math.pi / 180.0;

  /// Animate the glow toward fully shown when hovered or always-on, else hidden.
  void _updateGlow() {
    _glowController.animateTo((_alwaysShowGlow || _hovering) ? 1.0 : 0.0);
  }

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _build();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WeaponImageCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weapon.id != widget.weapon.id) {
      _loaded = false;
      _build();
    }
  }

  /// Renders the composite at native pixel resolution to PNG bytes,
  /// optionally including the glow layers.
  Future<Uint8List?> _renderCompositePng({required bool withGlow}) async {
    if (_layers.isEmpty || _canvasSize.isEmpty) return null;
    final w = _canvasSize.width.round();
    final h = _canvasSize.height.round();
    if (w <= 0 || h <= 0) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final l in _layers) {
      _drawWeaponLayer(canvas, l, l.paint);
    }
    if (withGlow) {
      for (final l in _glowLayers) {
        _drawWeaponLayer(
          canvas,
          l,
          _glowLayerPaint(l.glowTint ?? const Color(0xFFFFFFFF), 1.0),
        );
      }
    }

    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(w, h);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }

  Future<void> _copySpriteToClipboard({required bool withGlow}) async {
    final bytes = await _renderCompositePng(withGlow: withGlow);
    if (!mounted) return;
    if (bytes == null) return;

    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      showSnackBar(
        context: context,
        type: SnackBarType.warn,
        content: const Text(
          'Copying images is not supported on this platform.',
        ),
      );
      return;
    }

    final item = DataWriterItem()..add(Formats.png(bytes));
    await clipboard.write([item]);
    if (!mounted) return;
    showSnackBar(
      context: context,
      type: SnackBarType.info,
      content: Text(
        withGlow
            ? 'Copied sprite (with glow) to clipboard.'
            : 'Copied sprite to clipboard.',
      ),
    );
  }

  /// The composite painted at 1:1 (native pixel) scale, statically.
  Widget _composite1to1({required bool withGlow}) {
    return SizedBox(
      width: _canvasSize.width,
      height: _canvasSize.height,
      child: CustomPaint(
        painter: _WeaponSpritePainter(
          layers: _layers,
          glowLayers: withGlow ? _glowLayers : const [],
          glowOpacity: const AlwaysStoppedAnimation(1.0),
        ),
      ),
    );
  }

  /// Hover tooltip: the 1:1 composite, shown both without and with glow.
  Widget _buildTooltipPreview(BuildContext context) {
    final theme = Theme.of(context);
    final hasGlow = _glowLayers.isNotEmpty;

    Widget tile(bool withGlow) => Container(
      color: kDarkTooltipBackground,
      padding: const EdgeInsets.all(8),
      child: _composite1to1(withGlow: withGlow),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.weapon.name ?? widget.weapon.id,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasGlow) ...[
              tile(false),
              const SizedBox(width: 8),
              tile(true),
            ] else
              tile(false),
          ],
        ),
      ],
    );
  }

  Future<void> _build() async {
    final weapon = widget.weapon;
    final layers = <_WeaponLayer>[];
    final glowLayers = <_WeaponLayer>[];

    // Full-frame layers (under, gun/main in at-rest draw order), centered.
    for (final path in weapon.spriteLayers) {
      final img = await _loadWeaponImage(path);
      if (img == null) continue;
      layers.add(
        _WeaponLayer(
          image: img,
          center: Offset.zero,
          pivot: Offset(img.width / 2, img.height / 2),
          rotation: 0,
          paint: Paint()..filterQuality = FilterQuality.high,
        ),
      );
    }

    // Loaded missiles: one per tube, at its fire offset, oriented up.
    final offsets = weapon.mountOffsets;
    if (weapon.renderLoadedMissiles &&
        weapon.loadedMissileSprite != null &&
        offsets != null &&
        offsets.length >= 2) {
      final missileImg = await _loadWeaponImage(weapon.loadedMissileSprite!);
      if (missileImg != null) {
        final c = weapon.loadedMissileCenter;
        final pivot = (c != null && c.length >= 2)
            ? Offset(c[0], c[1])
            : Offset(missileImg.width / 2, missileImg.height / 2);
        final angles = weapon.mountAngleOffsets;
        final tubes = offsets.length ~/ 2;
        for (var i = 0; i < tubes; i++) {
          final x = offsets[i * 2]; // forward (along barrel)
          final y = offsets[i * 2 + 1]; // lateral
          final angle = (angles != null && angles.length > i) ? angles[i] : 0.0;
          layers.add(
            _WeaponLayer(
              image: missileImg,
              // weapon-forward = up = -y on screen; lateral = +x on screen.
              center: Offset(y, -x),
              pivot: pivot,
              rotation: angle * _deg2rad,
              paint: Paint()..filterQuality = FilterQuality.high,
            ),
          );
        }
      }
    }

    // Glow sprite on top, drawn additively and tinted by glowColor. Painted
    // only on hover, faded in/out by [_glowController].
    final glowPath = weapon.glowSprite;
    if (glowPath != null) {
      final glowImg = await _loadWeaponImage(glowPath);
      if (glowImg != null) {
        final gc = weapon.glowColor;
        final tint = (gc != null && gc.length >= 3)
            ? Color.fromARGB(
                gc.length >= 4 ? gc[3].round().clamp(0, 255) : 255,
                gc[0].round().clamp(0, 255),
                gc[1].round().clamp(0, 255),
                gc[2].round().clamp(0, 255),
              )
            : const Color(0xFFFFFFFF);
        glowLayers.add(
          _WeaponLayer(
            image: glowImg,
            center: Offset.zero,
            pivot: Offset(glowImg.width / 2, glowImg.height / 2),
            rotation: 0,
            paint: Paint(),
            glowTint: tint,
          ),
        );
      }
    }

    final all = [...layers, ...glowLayers];
    if (all.isEmpty) {
      if (mounted) setState(() => _loaded = true);
      return;
    }

    // Union bounding box over all layers (incl. glow) so the canvas size — and
    // thus the rendered scale — stays stable whether or not glow is shown.
    var bbox = all.first.bounds;
    for (final l in all.skip(1)) {
      bbox = bbox.expandToInclude(l.bounds);
    }
    _WeaponLayer shift(_WeaponLayer l) => _WeaponLayer(
      image: l.image,
      center: l.center - bbox.topLeft,
      pivot: l.pivot,
      rotation: l.rotation,
      paint: l.paint,
      glowTint: l.glowTint,
    );

    if (mounted) {
      setState(() {
        _layers = layers.map(shift).toList();
        _glowLayers = glowLayers.map(shift).toList();
        _canvasSize = bbox.size;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return SizedBox(width: widget.size, height: widget.size);
    }
    if ((_layers.isEmpty && _glowLayers.isEmpty) || _canvasSize.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: Icon(Icons.image_not_supported)),
      );
    }

    final tooltipPath =
        widget.weapon.mainSprite ?? widget.weapon.allSpriteFiles.firstOrNull;

    // Pin the glow on (or release back to hover behavior) when the setting flips.
    final alwaysShowGlow = ref.watch(
      weaponsPageControllerProvider.select((s) => s.alwaysShowGlow),
    );
    if (alwaysShowGlow != _alwaysShowGlow) {
      _alwaysShowGlow = alwaysShowGlow;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateGlow();
      });
    }

    Widget composite = FittedBox(
      fit: widget.fit,
      child: SizedBox(
        width: _canvasSize.width,
        height: _canvasSize.height,
        child: CustomPaint(
          painter: _WeaponSpritePainter(
            layers: _layers,
            glowLayers: _glowLayers,
            glowOpacity: _glowController,
          ),
        ),
      ),
    );

    // Right-click: open the sprite's folder, copy the composite to clipboard.
    // (No tap handler — taps fall through to the row's default handler.)
    composite = ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: <ContextMenuEntry>[
          if (tooltipPath != null)
            MenuItem(
              label: 'Open sprite folder',
              icon: Icons.folder_open,
              onSelected: () => tooltipPath.toFile().showInExplorer(),
            ),
          MenuItem(
            label: _glowLayers.isEmpty
                ? 'Copy sprite to clipboard'
                : 'Copy sprite (no glow)',
            icon: Icons.copy,
            onSelected: () => _copySpriteToClipboard(withGlow: false),
          ),
          if (_glowLayers.isNotEmpty)
            MenuItem(
              label: 'Copy sprite (with glow)',
              icon: Icons.auto_awesome,
              onSelected: () => _copySpriteToClipboard(withGlow: true),
            ),
        ],
        padding: const EdgeInsets.all(8.0),
      ),
      child: composite,
    );

    // Glow fades in on hover and out on exit (unless pinned on by the setting).
    if (_glowLayers.isNotEmpty) {
      composite = MouseRegion(
        onEnter: (_) {
          _hovering = true;
          _updateGlow();
        },
        onExit: (_) {
          _hovering = false;
          _updateGlow();
        },
        child: composite,
      );
    }

    if (_layers.isNotEmpty) {
      composite = MovingTooltipWidget.framed(
        backgroundColor: kDarkTooltipBackground,
        tooltipWidgetBuilder: (context) => _buildTooltipPreview(context),
        child: composite,
      );
    }

    return SizedBox(width: widget.size, height: widget.size, child: composite);
  }
}

void _drawWeaponLayer(Canvas canvas, _WeaponLayer l, Paint paint) {
  canvas.save();
  canvas.translate(l.center.dx, l.center.dy);
  if (l.rotation != 0) canvas.rotate(l.rotation);
  canvas.drawImage(l.image, Offset(-l.pivot.dx, -l.pivot.dy), paint);
  canvas.restore();
}

/// Additive glow paint, scaled by [op] (0–1) so the glow can fade in/out.
Paint _glowLayerPaint(Color tint, double op) => Paint()
  ..blendMode = BlendMode.plus
  ..filterQuality = FilterQuality.high
  ..colorFilter = ColorFilter.mode(
    Color.from(
      alpha: tint.a * op,
      red: tint.r * op,
      green: tint.g * op,
      blue: tint.b * op,
    ),
    BlendMode.modulate,
  );

class _WeaponSpritePainter extends CustomPainter {
  final List<_WeaponLayer> layers;
  final List<_WeaponLayer> glowLayers;

  /// Current glow fade, 0 (hidden) to 1 (full). Drives repaint while animating.
  final Animation<double> glowOpacity;

  _WeaponSpritePainter({
    required this.layers,
    required this.glowLayers,
    required this.glowOpacity,
  }) : super(repaint: glowOpacity);

  @override
  void paint(Canvas canvas, Size size) {
    for (final l in layers) {
      _drawWeaponLayer(canvas, l, l.paint);
    }

    final op = glowOpacity.value;
    if (op <= 0) return;
    for (final l in glowLayers) {
      _drawWeaponLayer(
        canvas,
        l,
        _glowLayerPaint(l.glowTint ?? const Color(0xFFFFFFFF), op),
      );
    }
  }

  @override
  bool shouldRepaint(_WeaponSpritePainter oldDelegate) =>
      !identical(oldDelegate.layers, layers) ||
      !identical(oldDelegate.glowLayers, glowLayers);
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
