import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/descriptions/description_entry.dart';
import 'package:trios/descriptions/descriptions_manager.dart';
import 'package:trios/hullmod_viewer/hullmods_manager.dart';
import 'package:trios/hullmod_viewer/hullmods_page_controller.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
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
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/collapsed_filter_button.dart';
import 'package:trios/widgets/description_with_substitutions.dart';
import 'package:trios/widgets/export_to_csv_dialog.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';
import 'package:trios/widgets/filter_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/multi_split_mixin_view.dart';
import 'package:trios/widgets/overflow_menu_button.dart';
import 'package:trios/widgets/text_trios.dart';
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

    // Apply pending mod filter from context menu navigation.
    final filterRequest = ref.watch(AppState.viewerFilterRequest);
    if (filterRequest != null &&
        filterRequest.destination == TriOSTools.hullmods) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(hullmodsPageControllerProvider.notifier).setChipSelections(
          'mod',
          {filterRequest.modName: true},
        );
        ref.read(AppState.viewerFilterRequest.notifier).state = null;
      });
    }

    final columns = _buildCols(theme, controllerState);
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
      child: _buildFilterPanel(
        theme,
        hullmodsBeforeFilter,
        controllerState,
        controller,
      ),
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
      showClearAll: controller.filterGroups.any((g) => g.isActive),
      onClearAll: controller.clearAllFilters,
      filterWidgets: [
        for (final g in controller.filterGroups)
          FilterGroupRenderer<Hullmod>(
            group: g,
            scope: controller.scope,
            items: displayedHullmods,
            onChanged: () => controller.onGroupChanged(g.id),
          ),
      ],
    );
  }

  Widget _buildGrid(
    List<WispGridColumn<Hullmod>> columns,
    List<Hullmod> items,
    List<Mod> mods,
    bool isTop,
    ThemeData theme,
  ) {
    final gridState = ref.watch(appSettings.select((s) => s.hullmodsGridState));

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
                    _buildInfoPane(
                      h,
                      theme,
                      context,
                      useContainFit: ref
                          .read(hullmodsPageControllerProvider)
                          .useContainFit,
                    ),
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

  Column _buildInfoPane(
    Hullmod h,
    ThemeData theme,
    BuildContext context, {
    bool useContainFit = false,
  }) {
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

    final fancyColor = theme.colorScheme.onSurface.mix(
      theme.colorScheme.primary,
      0.5,
    );
    final variableColor = theme.colorScheme.onSurface.mix(
      theme.colorScheme.secondary,
      0.3,
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
                  size: 32,
                  fit: useContainFit ? BoxFit.contain : BoxFit.scaleDown,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    h.name ?? h.id,
                    style: theme.textTheme.titleLarge?.copyWith(
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SelectableText(h.id, style: theme.textTheme.labelSmall),
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
          DescriptionWithSubstitutions(
            description: h.desc!,
            baseStyle: theme.textTheme.bodySmall,
            highlightColor: fancyColor,
            showPlaceholderHintText: (h.sModDesc ?? '')
                .isEmpty, // Show if it won't be shown on Smod text.
          ),
        ],
        if ((h.sModDesc ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          DescriptionWithSubstitutions(
            description: 'S-Mod: ${h.sModDesc!}',
            baseStyle: theme.textTheme.bodySmall?.copyWith(color: fancyColor),
            highlightColor: variableColor,
          ),
        ],
        Builder(
          builder: (context) {
            final desc = ref.watch(
              descriptionProvider((h.id, DescriptionEntry.typeHullMod)),
            );
            if (desc?.text1 == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: DescriptionWithSubstitutions(
                description: desc!.text1!,
                baseStyle: theme.textTheme.bodySmall,
              ),
            );
          },
        ),
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
          MenuItem(
            label: 'Copy ID',
            icon: Icons.copy,
            onSelected: () =>
                Clipboard.setData(ClipboardData(text: hullmod.id)),
          ),
          if (hullmod.csvFile != null)
            buildOpenSingleFolderMenuItem(
              hullmod.csvFile!.parent,
              label: 'Open hullmod data folder',
            ),
          if (hullmod.modVariant != null)
            buildOpenSingleFolderMenuItem(
              hullmod.modVariant!.modFolder.absolute,
              label: 'Open Mod Folder',
            ),
          if (hullmod.modVariant != null)
            buildMenuItemOpenForumPage(hullmod.modVariant!, context),
        ],
        padding: const EdgeInsets.all(8.0),
      ),
      child: Container(color: Colors.transparent, child: child),
    );
  }

  List<WispGridColumn<Hullmod>> _buildCols(
    ThemeData theme,
    HullmodsPageState controllerState,
  ) {
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
                child: _buildInfoPane(
                  item,
                  theme,
                  context,
                  useContainFit: controllerState.useContainFit,
                ),
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
            ? _HullmodSpriteWidget(
                spritePath: item.sprite!,
                size: 40,
                fit: controllerState.useContainFit
                    ? BoxFit.contain
                    : BoxFit.scaleDown,
              )
            : const SizedBox(
                width: 40,
                height: 40,
                child: Center(child: Icon(Icons.image_not_supported, size: 16)),
              ),
        csvValue: (hullmod) => hullmod.sprite,
        defaultState: WispGridColumnState(position: position++, width: 48),
      ),
      col('name', 'Name', (h) => h.name ?? h.id, width: 180),
      col('id', 'ID', (h) => h.id),
      col(
        'techManufacturer',
        'Tech/Manufacturer',
        (h) => h.techManufacturer,
        width: 150,
      ),
      col('costFrigate', 'OP (Frig)', (h) => h.costFrigate, width: 80),
      col('costDest', 'OP (Dest)', (h) => h.costDest, width: 80),
      col('costCruiser', 'OP (Cru)', (h) => h.costCruiser, width: 80),
      col('costCapital', 'OP (Cap)', (h) => h.costCapital, width: 80),
      col('tier', 'Tier', (h) => h.tier, width: 60),
      col('uiTags', 'Tags', (h) => h.uiTags, width: 120),
      col('short', 'Short Desc.', (h) => h.shortDescription, width: 200),
    ];
  }

  Widget _buildOverflowButton({
    required BuildContext context,
    required ThemeData theme,
    required HullmodsPageState controllerState,
  }) {
    final controller = ref.read(hullmodsPageControllerProvider.notifier);
    return OverflowMenuButton(
      menuItems: [
        OverflowMenuItem(
          title: 'Export to CSV',
          icon: Icons.table_view,
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

final Map<String, bool> _hullmodSpritePathCache = {};

class _HullmodSpriteWidget extends StatefulWidget {
  final String spritePath;
  final double size;
  final BoxFit fit;

  const _HullmodSpriteWidget({
    required this.spritePath,
    this.size = 32,
    this.fit = BoxFit.scaleDown,
  });

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
        fit: widget.fit,
      ),
    );
  }
}

class UngroupedHullmodGridGroup extends WispGridGroup<Hullmod> {
  UngroupedHullmodGridGroup() : super('none', 'None');

  @override
  String getGroupName(Hullmod mod, {Comparable? groupSortValue}) =>
      'All Hullmods';

  @override
  Comparable getGroupSortValue(Hullmod mod) => 1;

  @override
  bool get isGroupVisible => false;
}

class ModNameHullmodGridGroup extends WispGridGroup<Hullmod> {
  ModNameHullmodGridGroup() : super('modVariant', 'Mod');

  @override
  String getGroupName(Hullmod mod, {Comparable? groupSortValue}) =>
      mod.modVariant?.modInfo.nameOrId ?? 'Vanilla';

  @override
  Comparable getGroupSortValue(Hullmod mod) =>
      mod.modVariant?.modInfo.nameOrId.toLowerCase() ?? '        ';
}
