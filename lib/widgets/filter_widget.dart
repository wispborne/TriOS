import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/checkbox_with_label.dart';
import 'package:trios/widgets/filter_engine/filter_group.dart';
import 'package:trios/widgets/filter_engine/filter_scope.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persist_button.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';

/// Panel-wide settings that individual filter groups read: the panel's search
/// box and whether advanced mode is on.
///
/// [FiltersPanel] supplies this. Groups are built by the page, above the
/// panel, so they can't be given these as constructor arguments.
class FilterPanelOptions extends InheritedWidget {
  /// What the user typed in the panel's search box. Empty means "show all".
  final String searchTerm;

  /// Whether the panel is in advanced mode.
  final bool isAdvanced;

  const FilterPanelOptions({
    super.key,
    required this.searchTerm,
    required this.isAdvanced,
    required super.child,
  });

  static const FilterPanelOptions _defaults = FilterPanelOptions(
    searchTerm: '',
    isAdvanced: false,
    child: SizedBox.shrink(),
  );

  /// Returns the enclosing panel's options, or plain defaults when a filter
  /// group is rendered outside a [FiltersPanel].
  static FilterPanelOptions of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FilterPanelOptions>() ??
      _defaults;

  @override
  bool updateShouldNotify(FilterPanelOptions oldWidget) =>
      searchTerm != oldWidget.searchTerm || isAdvanced != oldWidget.isAdvanced;
}

/// Widget rendering a single [ChipFilterGroup] with lock-button, tri-state
/// chips, include/exclude counts and a collapsible header.
class GridFilterWidget<T> extends ConsumerStatefulWidget {
  final ChipFilterGroup<T> filter;
  final List<T> items;
  final Map<String, bool?> filterStates;
  final Function(Map<String, bool?>) onSelectionChanged;
  final FilterScope scope;

  /// When true, each chip shows how many [items] have that value. Opt-in so the
  /// existing viewer pages render exactly as before. Counts are of [items] (not
  /// the chip-filtered subset), so they don't change as chips are toggled.
  final bool showCounts;

  const GridFilterWidget({
    super.key,
    required this.filter,
    required this.items,
    required this.filterStates,
    required this.onSelectionChanged,
    required this.scope,
    this.showCounts = false,
  });

  @override
  ConsumerState<GridFilterWidget<T>> createState() =>
      _GridFilterWidgetState<T>();
}

class _GridFilterWidgetState<T> extends ConsumerState<GridFilterWidget<T>> {
  List<String> _uniqueValues = [];
  Map<String, int> _valueCounts = const {};
  late bool _isExpanded = !widget.filter.collapsedByDefault;

  /// The panel's search term, read in `build` so the button callbacks can use
  /// it without another context lookup.
  String _searchTerm = '';

  /// Chips left after the panel's search box is applied.
  List<String> _searchedValues = const [];

  @override
  void initState() {
    super.initState();
    _updateUniqueValues();
  }

  @override
  void didUpdateWidget(GridFilterWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always recompute: `valuesGetter` may depend on external state (e.g.
    // Catalog's Attributes group reads the controller's status map, which
    // populates after modRecords load without changing `items`' identity).
    _updateUniqueValues();
  }

  void _updateUniqueValues() {
    final List<String> values;
    if (widget.filter.valuesGetter != null) {
      values = widget.items
          .expand(widget.filter.valuesGetter!)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
    } else {
      values = widget.items
          .map(widget.filter.valueGetter)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
    }

    if (!widget.filter.useDefaultSort) {
      final comparator = widget.filter.sortComparator;
      final displayName = widget.filter.displayNameGetter;
      if (comparator != null) {
        values.sort(comparator);
      } else if (displayName != null) {
        // Look up each name once; getters can be expensive (e.g. codex tech
        // labels scan the whole entry list).
        final names = {for (final v in values) v: displayName(v)};
        values.sort((a, b) => names[a]!.compareTo(names[b]!));
      } else {
        values.sort();
      }
    }
    _uniqueValues = values;

    if (widget.showCounts) {
      final counts = <String, int>{};
      for (final item in widget.items) {
        if (widget.filter.valuesGetter != null) {
          for (final v in widget.filter.valuesGetter!(item)) {
            if (v.isNotEmpty) counts[v] = (counts[v] ?? 0) + 1;
          }
        } else {
          final v = widget.filter.valueGetter(item);
          if (v.isNotEmpty) counts[v] = (counts[v] ?? 0) + 1;
        }
      }
      _valueCounts = counts;
    }
  }

  /// If the group is currently locked, mirror the group's state to
  /// persistence so settings reflect the latest state.
  void _maybePersist() {
    final key = FilterGroupPersistence.keyFor(widget.scope, widget.filter.id);
    final isLocked = ref
        .read(appSettings)
        .persistedFilterGroups
        .containsKey(key);
    if (!isLocked) return;
    ref
        .read(filterGroupPersistenceProvider)
        .write(widget.scope, widget.filter.id, widget.filter.serialize());
  }

  void _emit(Map<String, bool?> newFilterStates) {
    widget.onSelectionChanged(newFilterStates);
    _maybePersist();
  }

  /// Values the All / Clear / Exclude buttons act on. They stick to what the
  /// search box is showing; holding shift acts on the whole group instead.
  List<String> get _valuesToActOn =>
      HardwareKeyboard.instance.isShiftPressed || _searchTerm.isEmpty
      ? _uniqueValues
      : _searchedValues;

  void _toggleValue(String value) {
    // Shift-click solos: everything else in the group is cleared.
    if (HardwareKeyboard.instance.isShiftPressed) {
      _emit({value: true});
      return;
    }

    final newFilterStates = Map<String, bool?>.from(widget.filterStates);

    bool? currentState = widget.filterStates[value];
    bool? newState;

    if (currentState == null) {
      newState = true;
    } else if (currentState == true) {
      newState = false;
    } else {
      newState = null;
    }

    if (newState == null) {
      newFilterStates.remove(value);
    } else {
      newFilterStates[value] = newState;
    }

    _emit(newFilterStates);
  }

  void _setAll(bool state) {
    final newFilterStates = Map<String, bool?>.from(widget.filterStates);
    for (final value in _valuesToActOn) {
      newFilterStates[value] = state;
    }
    _emit(newFilterStates);
  }

  void _clearAll() {
    // With no search on, wipe the lot — including any values that aren't in
    // the current data (loaded from settings for mods that aren't on).
    if (_searchTerm.isEmpty || HardwareKeyboard.instance.isShiftPressed) {
      _emit({});
      return;
    }
    final newFilterStates = Map<String, bool?>.from(widget.filterStates);
    for (final value in _searchedValues) {
      newFilterStates.remove(value);
    }
    _emit(newFilterStates);
  }

  void _toggleLogicMode() {
    widget.filter.logicMode = widget.filter.logicMode == ChipLogicMode.any
        ? ChipLogicMode.all
        : ChipLogicMode.any;
    setState(() {});
    // Re-runs filtering with the new mode and saves it if the group is locked.
    _emit(Map<String, bool?>.from(widget.filterStates));
  }

  /// Chips left after the panel's search box is applied. A group whose own
  /// name matches keeps all of its chips.
  List<String> _applySearch(String term) {
    if (term.isEmpty) return _uniqueValues;
    final needle = term.toLowerCase();
    if (widget.filter.name.toLowerCase().contains(needle)) return _uniqueValues;
    return _uniqueValues.where((value) {
      if (value.toLowerCase().contains(needle)) return true;
      final display = widget.filter.displayNameGetter?.call(value);
      return display != null && display.toLowerCase().contains(needle);
    }).toList();
  }

  int get includedCount =>
      widget.filterStates.values.where((v) => v == true).length;

  int get excludedCount =>
      widget.filterStates.values.where((v) => v == false).length;

  List<String> get includedValues => widget.filterStates.entries
      .where((e) => e.value == true)
      .map((e) => widget.filter.displayNameGetter?.call(e.key) ?? e.key)
      .toList();

  List<String> get excludedValues => widget.filterStates.entries
      .where((e) => e.value == false)
      .map((e) => widget.filter.displayNameGetter?.call(e.key) ?? e.key)
      .toList();

  int get totalCount => _uniqueValues.length;

  /// The chip's label, optionally with a dim per-value count suffix.
  Widget _chipLabel(ThemeData theme, String value) {
    final text = widget.filter.displayNameGetter != null
        ? widget.filter.displayNameGetter!(value)
        : value;
    if (!widget.showCounts) {
      return Text(text, style: theme.textTheme.labelMedium);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: theme.textTheme.labelMedium),
        const SizedBox(width: 4),
        Text(
          '${_valueCounts[value] ?? 0}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  /// Header buttons are kept small on purpose: the panel is only 300 wide and
  /// the group's name needs the room more than the buttons do.
  ButtonStyle _headerButtonStyle(ThemeData theme) => TextButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: const Size(24, 28),
    maximumSize: const Size(24, 28),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    foregroundColor: theme.colorScheme.onSurface,
  );

  /// The "any" / "all" button. "any" is the old behaviour: one of the
  /// included values is enough. "all" demands every one of them.
  Widget _buildLogicButton(ThemeData theme) {
    final isAll = widget.filter.logicMode == ChipLogicMode.all;
    return MovingTooltipWidget.text(
      message: isAll
          ? 'All: only shows items that have every value you include.\n'
                'Click for "any".'
          : 'Any: shows items with at least one of the values you include.\n'
                'Click for "all".',
      child: TextButton(
        onPressed: _toggleLogicMode,
        style: TextButton.styleFrom(
          padding: const .symmetric(horizontal: 4),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: isAll
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
        child: Text(
          isAll ? 'all' : 'any',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: isAll ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  /// Tooltip for the include-all / exclude-all / clear-all buttons, with a
  /// note about the search box when one is in use.
  String _allButtonsTooltip(String label) => _searchTerm.isEmpty
      ? label
      : '$label\nOnly the values the search is showing.\n'
            'Hold shift to do the whole group.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilters = widget.filterStates.isNotEmpty;
    final options = FilterPanelOptions.of(context);
    _searchTerm = options.searchTerm;
    _searchedValues = _applySearch(_searchTerm);

    // Nothing in this group matches the search — hide it entirely.
    if (_searchTerm.isNotEmpty && _searchedValues.isEmpty) {
      return const SizedBox.shrink();
    }

    // The logic button hides in simple mode, unless it's set to something
    // other than the default — a group must never filter differently with no
    // visible reason why.
    final showLogicButton =
        options.isAdvanced || widget.filter.logicMode != ChipLogicMode.any;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: theme.colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: .only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: !_isExpanded ? .circular(12) : .zero,
              bottomRight: !_isExpanded ? .circular(12) : .zero,
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  // Expanded, with no Spacer after it: the name takes all the
                  // room the buttons don't need, and everything else sits on
                  // the right.
                  Expanded(
                    child: Padding(
                      padding: const .only(
                        left: 8,
                        right: 4,
                        top: 2,
                        bottom: 2,
                      ),
                      child: TextTriOS(
                        widget.filter.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  if (showLogicButton) _buildLogicButton(theme),
                  // The all/exclude/clear buttons act on the chips below, so
                  // they're only here while those chips are on screen. A shut
                  // group shows its counts instead.
                  if (_isExpanded) ...[
                    MovingTooltipWidget.text(
                      message: _allButtonsTooltip('Include all'),
                      child: IconButton(
                        onPressed: () => _setAll(true),
                        icon: const Icon(Icons.check_box, size: 16),
                        style: _headerButtonStyle(theme),
                      ),
                    ),
                    MovingTooltipWidget.text(
                      message: _allButtonsTooltip('Exclude all'),
                      child: IconButton(
                        onPressed: () => _setAll(false),
                        icon: const Icon(
                          Icons.indeterminate_check_box,
                          size: 16,
                        ),
                        style: _headerButtonStyle(theme),
                      ),
                    ),
                    MovingTooltipWidget.text(
                      message: _allButtonsTooltip('Clear all filters'),
                      child: IconButton(
                        onPressed: _clearAll,
                        icon: const Icon(
                          Icons.check_box_outline_blank,
                          size: 16,
                        ),
                        style: _headerButtonStyle(theme),
                      ),
                    ),
                  ],
                  // Counts stand in for the chips while the group is shut.
                  if (hasFilters && !_isExpanded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          if (includedCount > 0)
                            MovingTooltipWidget.text(
                              message:
                                  'Included:\n${includedValues.join('\n')}',
                              child: Row(
                                children: [
                                  Text(
                                    includedCount.toString(),
                                    style: theme.textTheme.labelMedium,
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.check, size: 16),
                                ],
                              ),
                            ),
                          if (includedCount > 0 && excludedCount > 0)
                            const SizedBox(width: 8),
                          if (excludedCount > 0)
                            MovingTooltipWidget.text(
                              message:
                                  'Excluded:\n${excludedValues.join('\n')}',
                              child: Row(
                                children: [
                                  Text(
                                    excludedCount.toString(),
                                    style: theme.textTheme.labelMedium,
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.remove, size: 16),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  FilterGridPersistButton(
                    scope: widget.scope,
                    filterGroupId: widget.filter.id,
                    currentSelections: () => widget.filter.serialize(),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) const Divider(height: 1),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _searchedValues.map((value) {
                        final state = widget.filterStates[value];

                        Color? chipColor;
                        Icon? leadingIcon;
                        BorderSide? side;

                        switch (state) {
                          case true:
                            chipColor = theme.colorScheme.primaryContainer;
                            leadingIcon = Icon(
                              Icons.check,
                              size: 16,
                              color: theme.colorScheme.primary,
                            );
                            side = BorderSide(color: theme.colorScheme.primary);
                            break;
                          case false:
                            chipColor =
                                theme.colorScheme.surfaceContainerLowest;
                            leadingIcon = Icon(
                              Icons.remove,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            );
                            side = BorderSide(
                              color: theme.colorScheme.secondary,
                            );
                            break;
                          case null:
                            chipColor = null;
                            leadingIcon = null;
                            side = BorderSide(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.25,
                              ),
                            );
                            break;
                        }

                        return MovingTooltipWidget.text(
                          message: switch (state) {
                            true => "Included",
                            false => "Excluded",
                            null => "",
                          },
                          child: FilterChip(
                            label: _chipLabel(theme, value),
                            selected: state != null,
                            avatar: leadingIcon,
                            onSelected: (_) => _toggleValue(value),
                            selectedColor: chipColor,
                            checkmarkColor: Colors.transparent,
                            backgroundColor: theme.colorScheme.surfaceContainer,
                            side: side,
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A reusable filter panel shell used by Ships, Weapons, and Portraits pages.
///
/// Renders the "Filters" header row (icon + label + active-count pill +
/// optional "Clear All" button) above a scrollable column of [filterWidgets].
class FiltersPanel extends StatefulWidget {
  final VoidCallback onHide;
  final int activeFilterCount;
  final bool showClearAll;
  final VoidCallback? onClearAll;
  final List<Widget> filterWidgets;
  final ScrollController? scrollController;
  final double width;

  /// Shows a search box that narrows the filters down to matching chips.
  /// Off by default so panels that don't need it look unchanged.
  final bool showSearch;

  /// Whether advanced mode is on. Advanced mode shows the per-group
  /// "any" / "all" buttons and the number-range sliders.
  final bool isAdvanced;

  /// When set, the panel shows an "Advanced" checkbox.
  final ValueChanged<bool>? onAdvancedChanged;

  /// When set, the panel shows a button that opens it in a bigger dialog.
  final VoidCallback? onExpand;

  const FiltersPanel({
    super.key,
    required this.onHide,
    required this.activeFilterCount,
    required this.filterWidgets,
    this.showClearAll = false,
    this.onClearAll,
    this.scrollController,
    this.width = 300,
    this.showSearch = false,
    this.isAdvanced = false,
    this.onAdvancedChanged,
    this.onExpand,
  });

  @override
  State<FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  late final ScrollController _ownedController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _ownedController = ScrollController();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    if (widget.scrollController == null) {
      _ownedController.dispose();
    }
    super.dispose();
  }

  ScrollController get _controller =>
      widget.scrollController ?? _ownedController;

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _searchTerm = value.trim());
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _searchTerm = '');
  }

  /// Search box plus the "Advanced" checkbox, shown above the filter groups.
  Widget _buildSearchRow(ThemeData theme) {
    return Padding(
      padding: const .only(bottom: 8),
      child: Row(
        spacing: 8,
        children: [
          if (widget.showSearch)
            Expanded(
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: theme.textTheme.labelLarge,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Filter filters',
                    contentPadding: const .symmetric(horizontal: 8),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : MovingTooltipWidget.text(
                            message: 'Clear search',
                            child: IconButton(
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
          if (widget.onAdvancedChanged != null)
            MovingTooltipWidget.text(
              message:
                  'Advanced filters: adds an "any" / "all" choice to each '
                  'group, for asking that items have every value you pick '
                  'rather than just one of them.',
              child: CheckboxWithLabel(
                label: 'Advanced',
                labelStyle: theme.textTheme.labelLarge,
                value: widget.isAdvanced,
                onChanged: (value) => widget.onAdvancedChanged!(value ?? false),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Scrollbar(
        thumbVisibility: true,
        controller: _controller,
        child: Padding(
          padding: const .only(left: 8, right: 16, top: 8, bottom: 8),
          child: SizedBox(
            width: widget.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MovingTooltipWidget.text(
                      message: "Hide filters",
                      child: InkWell(
                        onTap: widget.onHide,
                        borderRadius: BorderRadius.circular(
                          TriOSThemeConstants.cornerRadius,
                        ),
                        child: Padding(
                          padding: const .all(8),
                          child: Row(
                            spacing: 8,
                            children: [
                              const Icon(Icons.filter_list, size: 16),
                              Text(
                                'Filters',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ActiveFilterCountPill(
                                count: widget.activeFilterCount,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Disable button for now, not sure if I want to support the dialog.
                    // if (widget.onExpand != null)
                    //   MovingTooltipWidget.text(
                    //     message: 'Open the filters in a bigger window',
                    //     child: IconButton(
                    //       onPressed: widget.onExpand,
                    //       icon: const Icon(Icons.open_in_full, size: 16),
                    //       style: TextButton.styleFrom(
                    //         foregroundColor: theme.colorScheme.onSurface,
                    //       ),
                    //     ),
                    //   ),
                    if (widget.showClearAll)
                      MovingTooltipWidget.text(
                        message:
                            "Resets filters back to default."
                            "\nSome filters are applied by default, such as spoiler warnings.",
                        child: TriOSToolbarItem(
                          elevation: 0,
                          child: TextButton.icon(
                            onPressed: widget.onClearAll,
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Clear All'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.showSearch || widget.onAdvancedChanged != null)
                  _buildSearchRow(theme),
                Expanded(
                  // Groups read the search term and advanced flag from
                  // here; the page builds them before this panel exists,
                  // so they can't be passed in directly.
                  child: FilterPanelOptions(
                    searchTerm: _searchTerm,
                    isAdvanced: widget.isAdvanced,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        controller: _controller,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          // No spacing here: groups hidden by the search
                          // box would still leave a gap. Each group card
                          // brings its own margin.
                          children: widget.filterWidgets,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the filter panel in a bigger window. Changes apply as you make them,
/// same as in the sidebar — there's no Save or Cancel.
///
/// [panelBuilder] must build the panel from live state (wrap it in a
/// `Consumer`), otherwise the dialog won't keep up with the changes made in
/// it.
Future<void> showFilterPanelDialog(
  BuildContext context,
  WidgetBuilder panelBuilder,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 800),
        child: Padding(
          padding: const .symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(child: panelBuilder(context)),
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: TextButton(
              //     onPressed: () => Navigator.of(context).pop(),
              //     child: const Text('Done'),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A small pill showing the number of active filter values across all categories.
/// Returns an empty widget when [count] is 0.
class ActiveFilterCountPill extends StatelessWidget {
  final int count;

  const ActiveFilterCountPill({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
