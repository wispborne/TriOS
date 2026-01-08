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
import 'package:trios/widgets/expanding_constrained_aligned_widget.dart';
import 'package:trios/widgets/export_to_csv_dialog.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';
import 'package:trios/widgets/trios_dropdown_menu.dart';

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

  final SearchController _searchController = SearchController();
  final ScrollController _filterScrollController = ScrollController();
  WispGridController<Weapon>? _gridController;

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
            child: Row(
              children: [
                const SizedBox(width: 4),
                Text(
                  '$total Weapons${total != visible ? " ($visible shown)" : ""}',
                  style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),
                ),
                const SizedBox(width: 4),
                if (controllerState.isLoading)
                  Padding(
                    padding: const .only(left: 8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (!controllerState.isLoading)
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
                const SizedBox(width: 8),
                ExpandingConstrainedAlignedWidget(
                  alignment: Alignment.centerRight,
                  child: buildSearchBox(),
                ),
                const SizedBox(width: 8),
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
                  message:
                      "Show hidden weapons (deco weapons, system weapons without SHOW_IN_CODEX tag).",
                  child: TriOSToolbarCheckboxButton(
                    text: "Show Hidden",
                    value: controllerState.showHidden,
                    onChanged: (value) => controller.toggleShowHidden(),
                  ),
                ),
                const SizedBox(width: 8),
                TriOSDropdownMenu<WeaponSpoilerLevel>(
                  initialSelection: controllerState.weaponSpoilerLevel,
                  onSelected: (level) {
                    if (level == null) return;
                    controller.setWeaponSpoilerLevel(level);
                  },
                  dropdownMenuEntries: [
                    DropdownMenuEntry(
                      value: WeaponSpoilerLevel.noSpoilers,
                      label: "No spoilers",
                      labelWidget: MovingTooltipWidget.text(
                        message: "Hides weapons tagged CODEX_UNLOCKABLE.",
                        child: Text("No spoilers"),
                      ),
                    ),
                    DropdownMenuEntry(
                      value: WeaponSpoilerLevel.showAllSpoilers,
                      label: "Show all spoilers",
                      labelWidget: MovingTooltipWidget.text(
                        warningLevel: TooltipWarningLevel.warning,
                        message: "Shows weapons tagged CODEX_UNLOCKABLE.",
                        child: Text("Show all spoilers"),
                      ),
                    ),
                  ],
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
                _buildOverflowButton(
                  context: context,
                  theme: theme,
                  controllerState: controllerState,
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
                            spacing: 4,
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
        onLoaded: (controller) {
          _gridController = controller;
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
    final imagePaths = spritesForWeapon(w);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                w.name ?? w.id ?? 'Weapon',
                style: theme.textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
                w.customPrimary!.replaceSubstitutionsRich(
                  w.customPrimaryHL,
                  highlightColor: theme.colorScheme.secondary,
                  baseStyle: theme.textTheme.bodySmall,
                ),
              if ((w.customAncillary ?? '').isNotEmpty)
                w.customAncillary!.replaceSubstitutionsRich(
                  w.customAncillaryHL,
                  highlightColor: theme.colorScheme.secondary,
                  baseStyle: theme.textTheme.bodySmall,
                ),
            ],
          ),
        Divider(color: Theme.of(context).colorScheme.outline),
        _kv(
          w.modVariant != null ? 'Mod' : null,
          w.modVariant?.modInfo.nameOrId ?? 'Vanilla',
          theme,
        ),
        _kv('Type', w.weaponType?.toTitleCase(), theme),
        _kv('Size', w.size?.toTitleCase(), theme),
        _kv('Tech/Manufacturer', w.techManufacturer, theme),
        const SizedBox(height: 12),
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
            _chip('Ammo', _fmtNum(w.ammo)),
            _chip('Ammo/Sec', _fmtNum(w.ammoPerSec)),
            _chip('Reload Size', _fmtNum(w.reloadSize)),
            _chip('Energy/Shot', _fmtNum(w.energyPerShot)),
            _chip('Energy/Sec', _fmtNum(w.energyPerSecond)),
            _chip('Chargeup', _fmtNum(w.chargeup)),
            _chip('Chargedown', _fmtNum(w.chargedown)),
            _chip('Burst Size', _fmtNum(w.burstSize)),
            _chip('Burst Delay', _fmtNum(w.burstDelay)),
            _chip('Min Spread', _fmtNum(w.minSpread)),
            _chip('Max Spread', _fmtNum(w.maxSpread)),
            _chip('Spread/Shot', _fmtNum(w.spreadPerShot)),
            _chip('Spread Decay/Sec', _fmtNum(w.spreadDecayPerSec)),
            _chip('Beam Speed', _fmtNum(w.beamSpeed)),
            _chip('Proj Speed', _fmtNum(w.projSpeed)),
            _chip('Launch Speed', _fmtNum(w.launchSpeed)),
            _chip('Flight Time', _fmtNum(w.flightTime)),
            _chip('Proj HP', _fmtNum(w.projHitpoints)),
            _chip('Autofire Acc Bonus', _fmtNum(w.autofireAccBonus)),
            if ((w.extraArcForAI ?? '').isNotEmpty)
              _chip('Extra Arc (AI)', w.extraArcForAI!),
            if ((w.hints ?? '').isNotEmpty) _chip('Hints', w.hints!),
            if ((w.tags ?? '').isNotEmpty) _chip('Tags', w.tags!),
            if ((w.groupTag ?? '').isNotEmpty) _chip('Group Tag', w.groupTag!),
            if ((w.forWeaponTooltip ?? '').isNotEmpty)
              _chip('Tooltip', w.forWeaponTooltip!),
            if ((w.primaryRoleStr ?? '').isNotEmpty)
              _chip('Primary Role', w.primaryRoleStr!),
            if ((w.speedStr ?? '').isNotEmpty) _chip('Speed', w.speedStr!),
            if ((w.trackingStr ?? '').isNotEmpty)
              _chip('Tracking', w.trackingStr!),
            if ((w.turnRateStr ?? '').isNotEmpty)
              _chip('Turn Rate (txt)', w.turnRateStr!),
            if ((w.accuracyStr ?? '').isNotEmpty)
              _chip('Accuracy', w.accuracyStr!),
            if (w.noDPSInTooltip == true) _chip('No DPS In Tooltip', 'Yes'),
            if (w.number != null) _chip('Number', _fmtNum(w.number)),
            if ((w.specClass ?? '').isNotEmpty)
              _chip('Spec Class', w.specClass!),
            if ((w.type ?? '').isNotEmpty) _chip('Type', w.type!),
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
      child: RichText(
        text: TextSpan(
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
        defaultState: WispGridColumnState(position: position++, width: width),
      );
    }

    return [
      WispGridColumn(
        key: 'info',
        isSortable: false,
        name: '',
        itemCellBuilder: (item, _) => MovingTooltipWidget.framed(
          tooltipWidget: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: _buildInfoPane(item, theme, context),
              ),
            ),
          ),
          child: Icon(
            Icons.info,
            size: 24,
            color: theme.iconTheme.color?.withAlpha(200),
          ),
        ),
        csvValue: (weapon) => null,
        defaultState: WispGridColumnState(position: position++, width: 32),
      ),
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
        itemCellBuilder: (item, modifiers) =>
            WeaponImageCell(imagePaths: spritesForWeapon(item)),
        csvValue: (weapon) => spritesForWeapon(weapon).join(","),
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
      col('op', 'OP', (w) => w.ops, width: 110),
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

  Widget _buildOverflowButton({
    required BuildContext context,
    required ThemeData theme,
    required WeaponsPageState controllerState,
  }) {
    return PopupMenuButton(
      tooltip: "More actions",
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        PopupMenuItem(
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
          child: ListTile(
            dense: true,
            leading: Icon(Icons.table_view),
            title: Text("Export to CSV"),
          ),
        ),
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
            fit: BoxFit.contain,
          ),
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
