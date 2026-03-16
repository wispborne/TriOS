import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/hullmodViewer/hullmods_manager.dart';
import 'package:trios/hullmodViewer/hullmods_page_controller.dart';
import 'package:trios/hullmodViewer/models/hullmod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/models/context_menu.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/models/context_menu_entry.dart';
import 'package:trios/thirdparty/flutter_context_menu/widgets/context_menu_region.dart';
import 'package:trios/trios/context_menu_items.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/collapsed_filter_button.dart';
import 'package:trios/widgets/export_to_csv_dialog.dart';
import 'package:trios/widgets/filter_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/multi_split_mixin_view.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/trios_dropdown_menu.dart';
import 'package:trios/widgets/viewer_search_box.dart';
import 'package:trios/widgets/viewer_split_pane.dart';
import 'package:trios/widgets/viewer_toolbar.dart';

class HullmodsPage extends ConsumerStatefulWidget {
  const HullmodsPage({super.key});

  @override
  ConsumerState<HullmodsPage> createState() => _HullmodsPageState();
}

class _HullmodsPageState extends ConsumerState<HullmodsPage>
    with AutomaticKeepAliveClientMixin<HullmodsPage>, MultiSplitViewMixin {
  @override
  bool get wantKeepAlive => true;

  final SearchController _searchController = SearchController();
  final ScrollController _filterScrollController = ScrollController();
  WispGridController<Hullmod>? _gridController;
  Widget? _cachedBuild;

  @override
  List<Area> get areas {
    final controllerState = ref.read(hullmodsPageControllerProvider);
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

    final isActive =
        ref.watch(appSettings.select((s) => s.defaultTool)) ==
        TriOSTools.hullmods;
    if (!isActive && _cachedBuild != null) return _cachedBuild!;

    final controller = ref.watch(hullmodsPageControllerProvider.notifier);
    final controllerState = ref.watch(hullmodsPageControllerProvider);
    final theme = Theme.of(context);
    final mods = ref.watch(AppState.mods);

    final columns = _buildCols(theme);
    final total = controllerState.allHullmods.length;
    final visible = controllerState.filteredHullmods.length;

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
                controllerState.hullmodsBeforeGridFilter,
              ),
              Expanded(
                child: _buildGridSection(
                  theme,
                  controllerState,
                  columns,
                  controllerState.filteredHullmods,
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
    HullmodsPageController controller,
    HullmodsPageState controllerState,
  ) {
    return ViewerToolbar(
      entityName: "Hullmods",
      total: total,
      visible: visible,
      isLoading: controllerState.isLoading,
      onRefresh: () => ref.invalidate(hullmodListNotifierProvider),
      searchBox: ViewerSearchBox(
        searchController: _searchController,
        hintText: "Filter hullmods...",
        onChanged: (query) => ref
            .read(hullmodsPageControllerProvider.notifier)
            .updateSearchQuery(query),
        onClear: () => ref
            .read(hullmodsPageControllerProvider.notifier)
            .updateSearchQuery(''),
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
    HullmodsPageState controllerState,
    HullmodsPageController controller,
    List<Hullmod> hullmodsBeforeFilter,
  ) {
    if (!controllerState.showFilters) {
      return CollapsedFilterButton(
        onTap: controller.toggleShowFilters,
        activeFilterCount: controller.activeFilterCount,
      );
    }

    return _buildFilterPanel(
      theme,
      hullmodsBeforeFilter,
      controllerState,
      controller,
    );
  }

  Widget _buildGridSection(
    ThemeData theme,
    HullmodsPageState controllerState,
    List<WispGridColumn<Hullmod>> columns,
    List<Hullmod> hullmods,
    List<Mod> mods,
  ) {
    return ViewerSplitPane(
      controller: multiSplitController,
      gridBuilder: (areaId) {
        switch (areaId) {
          case 'top':
            return _buildGrid(columns, hullmods, mods, true, theme);
          case 'bottom':
            return _buildGrid(columns, hullmods, mods, false, theme);
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  FiltersPanel _buildFilterPanel(
    ThemeData theme,
    List<Hullmod> displayedHullmods,
    HullmodsPageState controllerState,
    HullmodsPageController controller,
  ) {
    return FiltersPanel(
      onHide: controller.toggleShowFilters,
      scrollController: _filterScrollController,
      activeFilterCount: controller.activeFilterCount,
      showClearAll: controllerState.filterCategories.any(
        (f) => f.hasActiveFilters,
      ),
      onClearAll: controller.clearAllFilters,
      filterWidgets: [
        _buildCheckboxFilters(theme, controllerState, controller),
        const SizedBox(height: 8),
        ...controllerState.filterCategories.map((filter) {
          return GridFilterWidget<Hullmod>(
            filter: filter,
            items: displayedHullmods,
            filterStates: filter.filterStates,
            onSelectionChanged: (states) {
              controller.updateFilterStates(filter, states);
            },
          );
        }),
      ],
    );
  }

  Widget _buildCheckboxFilters(
    ThemeData theme,
    HullmodsPageState controllerState,
    HullmodsPageController controller,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MovingTooltipWidget.text(
              message: "Only hullmods from enabled mods.",
              child: CheckboxListTile(
                title: const Text('Only Enabled Mods'),
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: .only(left: 8),
                value: controllerState.showEnabled,
                onChanged: (value) => controller.toggleShowEnabled(),
              ),
            ),
            MovingTooltipWidget.text(
              message:
                  "Show hidden hullmods (built-in hullmods, internal hullmods).",
              child: CheckboxListTile(
                title: const Text('Show Hidden Hullmods'),
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: .only(left: 8),
                value: controllerState.showHidden,
                onChanged: (value) => controller.toggleShowHidden(),
              ),
            ),
            const SizedBox(height: 8),
            TriOSDropdownMenu<HullmodSpoilerLevel>(
              initialSelection: controllerState.hullmodSpoilerLevel,
              onSelected: (level) {
                if (level == null) return;
                controller.setHullmodSpoilerLevel(level);
              },
              highlightOutlineColor:
                  controllerState.hullmodSpoilerLevel !=
                      HullmodSpoilerLevel.showAllSpoilers
                  ? theme.colorScheme.primary
                  : null,
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  value: HullmodSpoilerLevel.noSpoilers,
                  label: "No spoilers",
                  labelWidget: MovingTooltipWidget.text(
                    message:
                        "Hides hullmods tagged CODEX_UNLOCKABLE or CODEX_REQUIRE_RELATED.",
                    child: Text("No spoilers"),
                  ),
                  leadingIcon: const Icon(Icons.visibility_off, size: 20),
                ),
                DropdownMenuEntry(
                  value: HullmodSpoilerLevel.showAllSpoilers,
                  label: "Show all spoilers",
                  labelWidget: MovingTooltipWidget.text(
                    warningLevel: TooltipWarningLevel.warning,
                    message:
                        "Shows hullmods tagged CODEX_UNLOCKABLE or CODEX_REQUIRE_RELATED.",
                    child: Text("Show all spoilers"),
                  ),
                  leadingIcon: const Icon(Icons.visibility_outlined, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    List<WispGridColumn<Hullmod>> columns,
    List<Hullmod> items,
    List<Mod> mods,
    bool isTop,
    ThemeData theme,
  ) {
    final gridState =
        ref.watch(appSettings.select((s) => s.hullmodsGridState));

    return DefaultTextStyle.merge(
      style: theme.textTheme.labelLarge!.copyWith(fontSize: 14),
      child: WispGrid<Hullmod>(
        gridState: gridState,
        updateGridState: (updateFunction) {
          ref.read(appSettings.notifier).update((state) {
            return state.copyWith(
              hullmodsGridState:
                  updateFunction(state.hullmodsGridState) ??
                  Settings().hullmodsGridState,
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
                onTap: () => _showHullmodDetailsDialog(context, item),
                child: Container(
                  color: Colors.transparent,
                  child: _buildRowContextMenu(item, child),
                ),
              ),
            ),
        groups: [UngroupedHullmodGridGroup(), ModNameHullmodGridGroup()],
      ),
    );
  }

  void _showHullmodDetailsDialog(BuildContext context, Hullmod h) {
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
                    _buildInfoPane(h, theme, context),
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

  Column _buildInfoPane(Hullmod h, ThemeData theme, BuildContext context) {
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
            if (h.sprite != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _HullmodSpriteWidget(
                  spritePath: h.sprite!,
                  size: 48,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name ?? h.id,
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(h.id, style: theme.textTheme.labelSmall),
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
        if ((h.shortDescription ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            h.shortDescription!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if ((h.desc ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          SelectableText(h.desc!, style: theme.textTheme.bodySmall),
        ],
        if ((h.sModDesc ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          SelectableText(
            'S-Mod: ${h.sModDesc!}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
        Divider(color: theme.colorScheme.outline),
        _kv(
          h.modVariant != null ? 'Mod' : null,
          h.modVariant?.modInfo.nameOrId ?? 'Vanilla',
          theme,
        ),
        _kv('Tech/Manufacturer', h.techManufacturer, theme),
        _kv('Script', h.script, theme),
        // Costs
        section('OP Costs'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Frigate', _fmtNum(h.costFrigate)),
            _chip('Destroyer', _fmtNum(h.costDest)),
            _chip('Cruiser', _fmtNum(h.costCruiser)),
            _chip('Capital', _fmtNum(h.costCapital)),
          ],
        ),
        // Misc
        section('Misc'),
        Wrap(
          runSpacing: 6,
          children: [
            _chip('Tier', _fmtNum(h.tier)),
            _chip('Rarity', _fmtNum(h.rarity)),
            _chip('Base Value', h.baseValue.asCredits()),
            if (h.unlocked == true) _chip('Unlocked', 'Yes'),
            if (h.hidden == true) _chip('Hidden', 'Yes'),
            if (h.hiddenEverywhere == true) _chip('Hidden Everywhere', 'Yes'),
            if ((h.tags ?? '').isNotEmpty) _chip('Tags', h.tags!),
            if ((h.uiTags ?? '').isNotEmpty) _chip('UI Tags', h.uiTags!),
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

  Widget _buildRowContextMenu(Hullmod hullmod, Widget child) {
    return ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: <ContextMenuEntry>[
          buildOpenSingleFolderMenuItem(
            hullmod.csvFile.parent,
            label: 'Open hullmod data folder',
          ),
        ],
        padding: const EdgeInsets.all(8.0),
      ),
      child: Container(color: Colors.transparent, child: child),
    );
  }

  List<WispGridColumn<Hullmod>> _buildCols(ThemeData theme) {
    int position = 0;

    String hullmodValueToString(
      Comparable<dynamic>? Function(Hullmod) getValue,
      Hullmod item,
    ) {
      final value = getValue(item);
      final str = switch (value) {
        double dbl => dbl.toStringMinimizingDigits(2),
        null => "",
        _ => value.toString(),
      };
      return str;
    }

    WispGridColumn<Hullmod> col(
      String key,
      String name,
      Comparable<dynamic>? Function(Hullmod) getValue, {
      double width = 100,
    }) {
      return WispGridColumn<Hullmod>(
        key: key,
        isSortable: true,
        name: name,
        getSortValue: getValue,
        itemCellBuilder: (item, _) {
          return TextTriOS(
            hullmodValueToString(getValue, item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
        csvValue: (item) => hullmodValueToString(getValue, item),
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
              padding: const EdgeInsets.all(8),
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
        csvValue: (hullmod) => null,
        defaultState: WispGridColumnState(position: position++, width: 32),
      ),
      WispGridColumn(
        key: 'modVariant',
        isSortable: true,
        name: 'Mod',
        getSortValue: (hullmod) => hullmod.modVariant?.modInfo.nameOrId,
        itemCellBuilder: (item, _) => TextTriOS(
          item.modVariant?.modInfo.nameOrId ?? "Vanilla",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge,
        ),
        csvValue: (hullmod) =>
            hullmod.modVariant?.modInfo.nameOrId ?? "Vanilla",
        defaultState: WispGridColumnState(position: position++, width: 120),
      ),
      WispGridColumn(
        key: 'sprite',
        isSortable: false,
        name: '',
        itemCellBuilder: (item, _) => item.sprite != null
            ? _HullmodSpriteWidget(spritePath: item.sprite!, size: 40)
            : const SizedBox(
                width: 40,
                height: 40,
                child: Center(child: Icon(Icons.image_not_supported, size: 16)),
              ),
        csvValue: (hullmod) => hullmod.sprite,
        defaultState: WispGridColumnState(position: position++, width: 48),
      ),
      col('name', 'Name', (h) => h.name ?? h.id, width: 180),
      col('tier', 'Tier', (h) => h.tier, width: 60),
      col('costFrigate', 'OP (Frig)', (h) => h.costFrigate, width: 80),
      col('costDest', 'OP (Dest)', (h) => h.costDest, width: 80),
      col('costCruiser', 'OP (Cru)', (h) => h.costCruiser, width: 80),
      col('costCapital', 'OP (Cap)', (h) => h.costCapital, width: 80),
      col(
        'techManufacturer',
        'Tech/Manufacturer',
        (h) => h.techManufacturer,
        width: 150,
      ),
      col('uiTags', 'UI Tags', (h) => h.uiTags, width: 120),
      col('short', 'Description', (h) => h.shortDescription, width: 200),
    ];
  }

  Widget _buildOverflowButton({
    required BuildContext context,
    required ThemeData theme,
    required HullmodsPageState controllerState,
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
              "hullmod",
              () => WispGridCsvExporter.toCsv(
                _gridController!,
                includeHeaders: true,
              ),
              () => ref
                  .read(hullmodListNotifierProvider.notifier)
                  .allHullmodsAsCsv(),
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

final Map<String, bool> _hullmodSpritePathCache = {};

class _HullmodSpriteWidget extends StatefulWidget {
  final String spritePath;
  final double size;

  const _HullmodSpriteWidget({required this.spritePath, this.size = 40});

  @override
  State<_HullmodSpriteWidget> createState() => _HullmodSpriteWidgetState();
}

class _HullmodSpriteWidgetState extends State<_HullmodSpriteWidget> {
  bool? _exists;

  @override
  void initState() {
    super.initState();
    _checkExists();
  }

  void _checkExists() async {
    if (_hullmodSpritePathCache.containsKey(widget.spritePath)) {
      _exists = _hullmodSpritePathCache[widget.spritePath];
    } else {
      final exists = await File(widget.spritePath).exists();
      _hullmodSpritePathCache[widget.spritePath] = exists;
      _exists = exists;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_exists != true) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: Icon(Icons.image_not_supported, size: 16)),
      );
    }

    return MovingTooltipWidget.image(
      path: widget.spritePath,
      child: Image.file(
        File(widget.spritePath),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class UngroupedHullmodGridGroup extends WispGridGroup<Hullmod> {
  UngroupedHullmodGridGroup() : super('none', 'None');

  @override
  String getGroupName(Hullmod mod) => 'All Hullmods';

  @override
  Comparable getGroupSortValue(Hullmod mod) => 1;

  @override
  bool get isGroupVisible => false;
}

class ModNameHullmodGridGroup extends WispGridGroup<Hullmod> {
  ModNameHullmodGridGroup() : super('modId', 'Mod');

  @override
  String getGroupName(Hullmod mod) =>
      mod.modVariant?.modInfo.nameOrId ?? 'Vanilla';

  @override
  Comparable getGroupSortValue(Hullmod mod) =>
      mod.modVariant?.modInfo.nameOrId.toLowerCase() ?? '        ';
}
