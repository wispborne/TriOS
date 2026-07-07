import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trios/codex/codex_facets.dart';
import 'package:trios/codex/codex_grouping.dart';
import 'package:trios/codex/codex_index.dart';
import 'package:trios/codex/codex_labels.dart';
import 'package:trios/codex/codex_links.dart';
import 'package:trios/codex/codex_page_controller.dart';
import 'package:trios/codex/codex_search.dart';
import 'package:trios/codex/models/codex_entry.dart';
import 'package:trios/codex/widgets/codex_detail_panel.dart';
import 'package:trios/codex/widgets/codex_entry_tooltip.dart';
import 'package:trios/codex/widgets/codex_list_row.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/ships_page_controller.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/filter_engine/filter_group.dart';
import 'package:trios/widgets/filter_engine/filter_group_renderer.dart';
import 'package:trios/widgets/filter_engine/filter_scope.dart';
import 'package:trios/widgets/filter_engine/filter_scope_controller.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';
import 'package:trios/widgets/highlightable.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';
import 'package:trios/widgets/trios_dropdown_button.dart';

/// The unified Codex: a single searchable, cross-linked view over ships,
/// weapons, hullmods, ship systems, fighters, and factions. Copies the in-game
/// Codex layout (toolbar, drill-down list, detail panel, related panel, filter
/// bar) with a TriOS skin.
class CodexPage extends ConsumerStatefulWidget {
  const CodexPage({super.key});

  @override
  ConsumerState<CodexPage> createState() => _CodexPageState();
}

class _CodexPageState extends ConsumerState<CodexPage>
    with AutomaticKeepAliveClientMixin {
  static const double _sideWidth = 288;

  /// Approximate list-row heights, used to estimate a scroll offset when jumping
  /// to a row that the virtualized list hasn't built yet. They only need to be
  /// close: the jump centers the target, then [Highlightable] fine-tunes.
  static const double _entryRowHeight = 48;
  static const double _groupHeaderHeight = 34;

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _listScrollController = ScrollController();
  final _relatedScrollController = ScrollController();

  /// One facet controller per category (built once; selections persist across
  /// rebuilds). Factions have no facets, so its groups list is empty.
  late final Map<CodexEntryType, FilterScopeController<CodexEntry>>
  _facetControllers;

  /// The current spoiler+mod-filtered entries of the active category. The count
  /// basis for the facet chips and the source for the tech/manufacturer label.
  final Map<CodexEntryType, List<CodexEntry>> _facetItems = {};

  /// Ship-by-hull-id lookup for the fighters' tech facet and wing row images.
  Map<String, Ship> _shipsByHull = const {};

  /// Lookup maps over the visible index, rebuilt each frame. Shared by the row
  /// hover tooltips (list, search, related) so they show the same nested cards.
  Map<String, ShipSystem> _shipSystemsMap = const {};
  Map<String, Weapon> _weaponsMap = const {};
  Map<String, Hullmod> _hullmodsMap = const {};
  Directory? _gameCoreDir;

  /// The selected grouping id per category. Unset defaults to grouping by mod.
  final Map<CodexEntryType, String> _groupingIds = {};

  /// Collapsed group keys per category. A key in the set hides that group's
  /// entries (the header stays, showing the count). Ephemeral — not restored by
  /// history, like scroll positions.
  final Map<CodexEntryType, Set<String>> _collapsedGroups = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _facetControllers = {
      for (final type in codexCategoryOrder)
        type: FilterScopeController<CodexEntry>(
          scope: FilterScope('codex', scopeId: type.name),
          groups: buildCodexFacetGroups(
            type,
            itemsFor: () => _facetItems[type] ?? const [],
            shipForHull: (hullId) => _shipsByHull[hullId],
          ),
        ),
    };
    // Let the controller capture/restore/reset facets for history & category
    // switches without knowing about the filter engine.
    ref.read(codexPageControllerProvider.notifier).facets = CodexFacetBridge(
      capture: _captureFacets,
      restore: _restoreFacets,
      reset: _resetFacets,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _listScrollController.dispose();
    _relatedScrollController.dispose();
    super.dispose();
  }

  Map<String, Map<String, Object?>> _captureFacets(CodexEntryType category) {
    final ctrl = _facetControllers[category];
    if (ctrl == null) return const {};
    return {for (final g in ctrl.groups) g.id: g.serialize()};
  }

  void _restoreFacets(
    CodexEntryType category,
    Map<String, Map<String, Object?>> selections,
  ) {
    final ctrl = _facetControllers[category];
    if (ctrl == null) return;
    for (final entry in selections.entries) {
      ctrl.findGroup(entry.key)?.restore(entry.value);
    }
    if (mounted) setState(() {});
  }

  void _resetFacets(CodexEntryType category) {
    _facetControllers[category]?.clearAll();
    if (mounted) setState(() {});
  }

  CodexPageController get _controller =>
      ref.read(codexPageControllerProvider.notifier);

  void _syncSearchField(String query) {
    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  void _randomEntry() {
    final pool = ref.read(codexListedIndexProvider);
    final state = ref.read(codexPageControllerProvider);
    final candidates = pool.where((e) => e.key != state.selected).toList();
    if (candidates.isEmpty) return;
    final pick = candidates[Random().nextInt(candidates.length)];
    _controller.select(pick.key);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(codexPageControllerProvider);
    _syncSearchField(state.searchQuery);

    // Ship lookup for wing rows and the fighters' tech facet.
    final visible = ref.watch(codexVisibleIndexProvider);
    _shipsByHull = {
      for (final e in visible)
        if (e is ShipCodexEntry) e.ship.id: e.ship,
    };
    // Lookup maps for the row hover tooltips (same nested cards the detail
    // panel and related panel use).
    _shipSystemsMap = {
      for (final e in visible)
        if (e is ShipSystemCodexEntry) e.system.id: e.system,
    };
    _weaponsMap = {
      for (final e in visible)
        if (e is WeaponCodexEntry) e.weapon.id: e.weapon,
    };
    _hullmodsMap = {
      for (final e in visible)
        if (e is HullmodCodexEntry) e.hullmod.id: e.hullmod,
    };
    _gameCoreDir = ref.watch(AppState.gameCoreFolder).valueOrNull;

    // Count basis for the active category's facets (pre-chip-filter).
    final category = state.category;
    if (category != null && !state.isSearching) {
      final listed = ref.watch(codexListedIndexProvider);
      final items = listed.where((e) => e.type == category).toList()
        ..sort(
          (a, b) =>
              a.sortName.toLowerCase().compareTo(b.sortName.toLowerCase()),
        );
      _facetItems[category] = items;
      // Load locked facet state and merge staged selections whose values exist
      // in the current data — before the list below applies the chip filters.
      final ctrl = _facetControllers[category]!;
      ctrl.loadPersisted(ref.read(filterGroupPersistenceProvider));
      ctrl.applyPendingChipMerge(items);
    }
    final showFacets =
        category != null &&
        !state.isSearching &&
        (_facetControllers[category]?.groups.isNotEmpty ?? false);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        spacing: 8,
        children: [
          _panelCard(child: _buildToolbar(context, state)),
          Expanded(
            child: Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Categories on the left (full height).
                SizedBox(
                  width: _sideWidth,
                  child: _panelCard(child: _buildList(context, state)),
                ),
                // The codex view (detail) with the Related panel directly
                // below it — between the categories and the filters.
                Expanded(
                  child: Column(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: _panelCard(
                          child: CodexDetailPanel(selected: state.selected),
                        ),
                      ),
                      SizedBox(
                        height: 150,
                        child: _panelCard(
                          child: _buildRelatedPanel(context, state),
                        ),
                      ),
                    ],
                  ),
                ),
                // Filters on the right (full height).
                SizedBox(
                  width: _sideWidth,
                  child: _panelCard(
                    child: _buildFiltersPanel(context, category, showFacets),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A card container for a top-level region, so groups read as cards + spacing
  /// rather than divider lines.
  Widget _panelCard({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  /// Consistent section header used across the page's panels.
  Widget _panelHeader(BuildContext context, IconData? icon, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        spacing: 8,
        children: [
          if (icon != null) Icon(icon, size: 16),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Filters panel (right side, vertical) ─────────────────────────────────
  Widget _buildFiltersPanel(
    BuildContext context,
    CodexEntryType? category,
    bool showFacets,
  ) {
    final groups = showFacets ? _facetControllers[category]!.groups : const [];
    final items = category != null
        ? (_facetItems[category] ?? const <CodexEntry>[])
        : const <CodexEntry>[];
    final scope = category != null
        ? FilterScope('codex', scopeId: category.name)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panelHeader(context, Icons.filter_list, 'Filters'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStandingControls(context),
                for (final group in groups)
                  FilterGroupRenderer<CodexEntry>(
                    group: group,
                    scope: scope!,
                    items: items,
                    showCounts: true,
                    onChanged: () => setState(() {}),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Toolbar ────────────────────────────────────────────────────────────
  Widget _buildToolbar(BuildContext context, CodexPageState state) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        spacing: 4,
        children: [
          MovingTooltipWidget.text(
            message: 'Back',
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: state.canGoBack ? _controller.back : null,
            ),
          ),
          MovingTooltipWidget.text(
            message: 'Forward',
            child: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: state.canGoForward ? _controller.forward : null,
            ),
          ),
          MovingTooltipWidget.text(
            message: 'Up a level',
            child: IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: (state.category != null || state.isSearching)
                  ? _controller.goUp
                  : null,
            ),
          ),
          MovingTooltipWidget.text(
            message: 'Random entry',
            child: IconButton(icon: Icon(Symbols.ifl), onPressed: _randomEntry),
          ),
          const Spacer(),
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                hintText: 'Search the Codex…',
                border: const OutlineInputBorder(),
                suffixIcon: state.isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _controller.setSearch(''),
                      )
                    : null,
              ),
              onChanged: _controller.setSearch,
            ),
          ),
        ],
      ),
    );
  }

  // ── Left list ──────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context, CodexPageState state) {
    if (state.isSearching) {
      return _buildSearchResults(context, state);
    }
    if (state.category == null) {
      return _buildRootCategories(context);
    }
    return _buildCategoryList(context, state);
  }

  Widget _buildRootCategories(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        for (final type in codexCategoryOrder)
          ListTile(
            leading: codexCategoryIcon(type, size: 24),
            title: Text(codexCategoryLabel(type)),
            trailing: ref.watch(codexCategoryLoadingProvider(type))
                ? MovingTooltipWidget.text(
                    message: 'Loading ${codexCategoryLabel(type)}…',
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: ThemedCircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.chevron_right, size: 18),
            onTap: () => _controller.openCategory(type),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Pick a category, or search across everything.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(BuildContext context, CodexPageState state) {
    final category = state.category!;
    // `_facetItems[category]` was computed (sorted) in build(); apply the
    // category's facet chip selections to get the shown list.
    final base = _facetItems[category] ?? const <CodexEntry>[];
    final entries = _facetControllers[category]!.applyChipFilters(base);

    final groupings = _groupingsFor(category);
    // Default to grouping by mod; groupings always include a 'mod' option.
    final grouping = groupings.firstWhere(
      (g) => g.id == (_groupingIds[category] ?? 'mod'),
      orElse: () => groupings.first,
    );
    final collapsed = _collapsedGroups[category] ?? const <String>{};
    // Entries, with a section header record before each group when grouped.
    final rows = _listRows(entries, grouping, collapsed);

    // Landing here from a search result / related click / random: scroll the
    // target row into view. A virtualized list won't build (so can't self-scroll
    // to) an off-screen row, so jump to its estimated offset first.
    final target = state.highlightTarget;
    if (target != null && target.$1 == category) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _landOnTarget(category, target, entries, grouping),
      );
    }

    return Column(
      children: [
        _buildCategoryHeader(context, category, groupings, grouping),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            controller: _listScrollController,
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final row = rows[i];
              if (row is ({String key, String label, int count})) {
                return _buildGroupHeaderRow(
                  context,
                  category,
                  row.key,
                  row.label,
                  row.count,
                  collapsed.contains(row.key),
                );
              }
              final entry = row as CodexEntry;
              // Highlightable wraps its child in an UnconstrainedBox, which
              // strips the width constraint; re-impose the list width so the
              // row's Expanded has a bounded width to fill.
              return LayoutBuilder(
                builder: (context, constraints) => Highlightable(
                  highlightKey: codexHighlightKey(entry.key),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: _withRowTooltip(
                      entry,
                      CodexListRow(
                        entry: entry,
                        selected: entry.key == state.selected,
                        wingShip: entry is WingCodexEntry
                            ? _shipsByHull[entry.wing.hullId]
                            : null,
                        onTap: () => _controller.select(entry.key),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader(
    BuildContext context,
    CodexEntryType category,
    List<CodexGrouping> groupings,
    CodexGrouping grouping,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            spacing: 8,
            children: [
              MovingTooltipWidget.text(
                message: 'Up a level',
                child: TextButton.icon(
                  onPressed: _controller.goUp,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('All categories'),
                ),
              ),
              Expanded(
                child: TriOSDropdownButton<CodexEntryType>(
                  value: category,
                  isExpanded: true,
                  items: [
                    for (final type in codexCategoryOrder)
                      DropdownMenuItem(
                        value: type,
                        child: Row(
                          spacing: 8,
                          children: [
                            codexCategoryIcon(type, size: 18),
                            Text(codexCategoryLabel(type)),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (type) {
                    if (type != null) _controller.openCategory(type);
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            spacing: 8,
            children: [
              Text(
                'Group by',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Expanded(
                child: TriOSDropdownButton<String>(
                  value: grouping.id,
                  isExpanded: true,
                  isDense: true,
                  items: [
                    for (final g in groupings)
                      DropdownMenuItem(value: g.id, child: Text(g.label)),
                  ],
                  onChanged: (id) {
                    if (id != null) {
                      setState(() => _groupingIds[category] = id);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The grouping options for [category]: None, Mod, and one per facet group.
  List<CodexGrouping> _groupingsFor(CodexEntryType category) {
    final facets = _facetControllers[category]!.groups
        .whereType<ChipFilterGroup<CodexEntry>>()
        .toList();
    final mods = ref.watch(AppState.mods);
    final modNames = <String, String>{
      for (final mod in mods)
        mod.id:
            mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ?? mod.id,
    };
    return buildCodexGroupings(
      facets: facets,
      modNameOf: (id) => modNames[id] ?? id,
    );
  }

  /// Flattens [entries] into list rows. With an active grouping, each section
  /// gets a `(label, count)` header record followed by its entries; an entry
  /// with several group values (hullmod tags, multi-mod factions) appears
  /// under each.
  List<Object> _listRows(
    List<CodexEntry> entries,
    CodexGrouping grouping,
    Set<String> collapsedKeys,
  ) {
    if (grouping.isNone) return entries;
    final byKey = <String, List<CodexEntry>>{};
    for (final entry in entries) {
      final keys = grouping.keysOf(entry);
      if (keys.isEmpty) {
        byKey.putIfAbsent('', () => []).add(entry);
      } else {
        for (final key in keys) {
          byKey.putIfAbsent(key, () => []).add(entry);
        }
      }
    }
    final keys = byKey.keys.toList()
      ..sort((a, b) {
        // "Other" (empty key) always sorts last.
        if (a.isEmpty || b.isEmpty) return a.isEmpty ? 1 : -1;
        final cmp = grouping.sortComparator;
        if (cmp != null) return cmp(a, b);
        return grouping
            .labelOf(a)
            .toLowerCase()
            .compareTo(grouping.labelOf(b).toLowerCase());
      });
    return [
      for (final key in keys) ...[
        (key: key, label: grouping.labelOf(key), count: byKey[key]!.length),
        if (!collapsedKeys.contains(key)) ...byKey[key]!,
      ],
    ];
  }

  Widget _buildGroupHeaderRow(
    BuildContext context,
    CodexEntryType category,
    String key,
    String label,
    int count,
    bool collapsed,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _toggleGroupCollapsed(category, key),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 2),
        child: Row(
          spacing: 6,
          children: [
            Icon(
              collapsed ? Icons.chevron_right : Icons.expand_more,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Collapse or expand the [key] group under [category].
  void _toggleGroupCollapsed(CodexEntryType category, String key) {
    setState(() {
      final set = _collapsedGroups.putIfAbsent(category, () => <String>{});
      if (!set.remove(key)) set.add(key);
    });
  }

  /// Wraps a list [row] for [entry] in the same hover card the related panel
  /// shows, so hovering an entry in the list or search results previews its
  /// full codex card.
  Widget _withRowTooltip(CodexEntry entry, Widget row) {
    return codexEntryTooltip(
      entry: entry,
      shipSystemsMap: _shipSystemsMap,
      weaponsMap: _weaponsMap,
      hullmodsMap: _hullmodsMap,
      gameCoreDir: _gameCoreDir,
      child: row,
    );
  }

  /// Brings the just-selected [target] row into view after landing in
  /// [category]. Expands the target's group if it was collapsed, then jumps the
  /// list near the row so the virtualized list builds it; [Highlightable] then
  /// scrolls it exactly into view and plays its glow.
  void _landOnTarget(
    CodexEntryType category,
    (CodexEntryType, String) target,
    List<CodexEntry> entries,
    CodexGrouping grouping,
  ) {
    if (!mounted) return;

    // Expand the target's group so its row exists in the list.
    final collapsed = _collapsedGroups[category];
    if (collapsed != null && collapsed.isNotEmpty && !grouping.isNone) {
      for (final e in entries) {
        if (e.key == target) {
          for (final key in grouping.keysOf(e)) {
            collapsed.remove(key);
          }
          break;
        }
      }
    }

    // Stop this from re-firing on every rebuild; the glow runs off the separate
    // active-highlight key, so it still plays.
    _controller.consumeHighlight();
    setState(() {});

    // After the list rebuilds (group expanded), jump near the row.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_listScrollController.hasClients) return;
      final rows = _listRows(
        entries,
        grouping,
        _collapsedGroups[category] ?? const {},
      );
      var index = -1;
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        if (r is CodexEntry && r.key == target) {
          index = i;
          break;
        }
      }
      if (index < 0) return;

      var offset = 0.0;
      for (var i = 0; i < index; i++) {
        offset += rows[i] is CodexEntry ? _entryRowHeight : _groupHeaderHeight;
      }
      final position = _listScrollController.position;
      // Center the target so an imperfect estimate still lands it on-screen.
      final centered =
          offset - position.viewportDimension / 2 + _entryRowHeight / 2;
      _listScrollController.jumpTo(
        centered.clamp(0.0, position.maxScrollExtent),
      );
    });
  }

  Widget _buildSearchResults(BuildContext context, CodexPageState state) {
    final listed = ref.watch(codexListedIndexProvider);
    final pool = state.category == null
        ? listed
        : listed.where((e) => e.type == state.category).toList();
    final results = codexSearch(state.searchQuery, pool);

    return Column(
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.search, size: 18),
          title: Text('Search results (${results.length})'),
          trailing: IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () => _controller.setSearch(''),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, i) {
              final entry = results[i];
              return _withRowTooltip(
                entry,
                CodexListRow(
                  entry: entry,
                  showTypeHint: true,
                  selected: entry.key == state.selected,
                  wingShip: entry is WingCodexEntry
                      ? _shipsByHull[entry.wing.hullId]
                      : null,
                  onTap: () => _controller.select(entry.key),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Related panel (below the detail, between categories and filters) ─────
  Widget _buildRelatedPanel(BuildContext context, CodexPageState state) {
    final theme = Theme.of(context);
    final selected = state.selected;
    final visible = ref.watch(codexVisibleIndexProvider);
    final links = ref.watch(codexLinksProvider);

    final related =
        (selected == null
                ? const <CodexEntry>[]
                : resolveCodexLinks(selected, links, {
                    for (final e in visible) e.key: e,
                  }))
            // Decorative weapons (running lights, glows, etc.) aren't useful here.
            .where((e) => !_isDecorativeWeapon(e))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panelHeader(context, null, 'Related entries'),
        Expanded(
          child: related.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nothing related',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                )
              : Scrollbar(
                  controller: _relatedScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _relatedScrollController,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final entry in related)
                          SizedBox(
                            width: 232,
                            child: _withRowTooltip(
                              entry,
                              CodexListRow(
                                entry: entry,
                                showTypeHint: true,
                                compact: true,
                                wingShip: entry is WingCodexEntry
                                    ? _shipsByHull[entry.wing.hullId]
                                    : null,
                                onTap: () => _controller.select(entry.key),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// Whether [entry] is a decorative weapon (running lights, engine glows) —
  /// hidden from the Related bar.
  bool _isDecorativeWeapon(CodexEntry entry) =>
      entry is WeaponCodexEntry &&
      entry.weapon.weaponType?.toLowerCase() == 'decorative';

  // ── Standing controls (top of the filters panel, vertical) ───────────────
  Widget _buildStandingControls(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(codexStandingFiltersProvider);
    final notifier = ref.read(codexStandingFiltersProvider.notifier);
    final mods = ref.watch(AppState.mods);

    // Distinct mod ids present in the index, with display names.
    final modNames = <String, String>{
      for (final mod in mods)
        mod.id:
            mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId ?? mod.id,
    };

    Widget labeled(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        child,
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          labeled(
            'Spoilers',
            TriOSDropdownButton<SpoilerLevel>(
              value: filters.spoilerLevel,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: SpoilerLevel.showNone,
                  child: Text('None'),
                ),
                DropdownMenuItem(
                  value: SpoilerLevel.showSlightSpoilers,
                  child: Text('Slight'),
                ),
                DropdownMenuItem(
                  value: SpoilerLevel.showAllSpoilers,
                  child: Text('All'),
                ),
              ],
              onChanged: (v) {
                if (v != null) notifier.setSpoilerLevel(v);
              },
            ),
          ),
          labeled(
            'Mod',
            TriOSDropdownButton<String?>(
              value: filters.modId,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                const DropdownMenuItem(
                  value: codexVanillaModId,
                  child: Text('Vanilla only'),
                ),
                for (final entry in modNames.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: notifier.setModId,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: CheckboxWithLabel(
              label: 'Show hidden weapons',
              value: filters.showHidden,
              onChanged: (v) => notifier.setShowHidden(v ?? false),
            ),
          ),
        ],
      ),
    );
  }
}
