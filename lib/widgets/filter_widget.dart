import 'package:flutter/material.dart';
import 'package:trios/themes/theme_manager.dart' show ThemeManager;
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';

class GridFilter<T> {
  final String name;
  final String Function(T) valueGetter;

  /// Optional getter that returns multiple values per item.
  /// When provided, the filter panel shows each individual value as a separate
  /// chip and matching checks whether *any* of the item's values match.
  /// [valueGetter] is still required but may return an empty string when
  /// [valuesGetter] is used.
  final List<String> Function(T)? valuesGetter;

  final String Function(String)? displayNameGetter;

  /// Custom comparator for sorting filter chip values (raw IDs).
  /// When set, takes precedence over [displayNameGetter]-based sorting.
  final Comparator<String>? sortComparator;

  /// If true, doesn't sort by display name or custom sort.
  final bool useDefaultSort;

  /// If true, the filter section starts collapsed in the UI.
  final bool collapsedByDefault;

  // Map of values to filter states:
  // true = include, false = exclude, null = no filter
  final Map<String, bool?> filterStates = {};

  GridFilter({
    required this.name,
    required this.valueGetter,
    this.valuesGetter,
    this.displayNameGetter,
    this.sortComparator,
    this.useDefaultSort = false,
    this.collapsedByDefault = false,
  });

  Set<String> get includedValues => filterStates.entries
      .where((e) => e.value == true)
      .map((e) => e.key)
      .toSet();

  Set<String> get excludedValues => filterStates.entries
      .where((e) => e.value == false)
      .map((e) => e.key)
      .toSet();

  bool get hasActiveFilters => filterStates.isNotEmpty;
}

class GridFilterWidget<T> extends StatefulWidget {
  final GridFilter<T> filter;
  final List<T> items;
  final Map<String, bool?> filterStates;
  final Function(Map<String, bool?>) onSelectionChanged;

  const GridFilterWidget({
    super.key,
    required this.filter,
    required this.items,
    required this.filterStates,
    required this.onSelectionChanged,
  });

  @override
  State<GridFilterWidget<T>> createState() => _GridFilterWidgetState<T>();
}

class _GridFilterWidgetState<T> extends State<GridFilterWidget<T>> {
  List<String> _uniqueValues = [];
  late bool _isExpanded = !widget.filter.collapsedByDefault;

  @override
  void initState() {
    super.initState();
    _updateUniqueValues();
  }

  @override
  void didUpdateWidget(GridFilterWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _updateUniqueValues();
    }
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
        values.sort((a, b) => displayName(a).compareTo(displayName(b)));
      } else {
        values.sort();
      }
    }
    _uniqueValues = values;
  }

  void _toggleValue(String value) {
    // Create a copy of the current filter states
    final newFilterStates = Map<String, bool?>.from(widget.filterStates);

    // Cycle through states: null -> true -> false -> null
    bool? currentState = widget.filterStates[value];
    bool? newState;

    if (currentState == null) {
      newState = true; // Include
    } else if (currentState == true) {
      newState = false; // Exclude
    } else {
      newState = null; // No filter
    }

    if (newState == null) {
      newFilterStates.remove(value);
    } else {
      newFilterStates[value] = newState;
    }

    widget.onSelectionChanged(newFilterStates);
  }

  void _selectAll() {
    final newFilterStates = Map<String, bool?>.from(widget.filterStates);
    for (final value in _uniqueValues) {
      newFilterStates[value] = true;
    }
    widget.onSelectionChanged(newFilterStates);
  }

  void _clearAll() {
    widget.onSelectionChanged({});
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilters = widget.filterStates.isNotEmpty;

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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: TextTriOS(
                      widget.filter.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _selectAll,
                    icon: const Icon(Icons.check_box, size: 16),
                    tooltip: 'Include all',
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _clearAll,
                    icon: const Icon(Icons.check_box_outline_blank, size: 16),
                    tooltip: 'Clear all filters',
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (hasFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      // decoration: BoxDecoration(
                      //   // color: theme.colorScheme.primary.withOpacity(0.1),
                      //   borderRadius: BorderRadius.circular(12),
                      //   border: Border.all(
                      //     color: theme.colorScheme.outline.withOpacity(0.3),
                      //   ),
                      // ),
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
                          // TextTriOS(
                          //   '${includedCount}+ ${excludedCount}–',
                          //   style: theme.textTheme.bodySmall?.copyWith(
                          //     color: theme.colorScheme.primary,
                          //     fontWeight: FontWeight.w500,
                          //   ),
                          // ),
                        ],
                      ),
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
                      children: _uniqueValues.map((value) {
                        final state = widget.filterStates[value];

                        // Determine the visual style based on state
                        Color? chipColor;
                        Icon? leadingIcon;
                        BorderSide? side;

                        switch (state) {
                          case true: // Include
                            chipColor = theme.colorScheme.primaryContainer;
                            leadingIcon = Icon(
                              Icons.check,
                              size: 16,
                              color: theme.colorScheme.primary,
                            );
                            side = BorderSide(color: theme.colorScheme.primary);
                            break;
                          case false: // Exclude
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
                          case null: // No filter
                            chipColor = null;
                            leadingIcon = null;
                            side = BorderSide(
                              color: theme.colorScheme.outline.withOpacity(
                                0.25,
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
                            label: Text(
                              widget.filter.displayNameGetter != null
                                  ? widget.filter.displayNameGetter!(value)
                                  : value,
                              style: theme.textTheme.labelMedium,
                            ),
                            selected: state != null,
                            avatar: leadingIcon,
                            onSelected: (_) => _toggleValue(value),
                            selectedColor: chipColor,
                            checkmarkColor: Colors.transparent,
                            // Hide the default checkmark
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
  /// Called when the user taps the "Filters" header to collapse the panel.
  final VoidCallback onHide;

  /// Total number of active filters across all filter types (grid, checkbox,
  /// dropdown, etc.). Passed in by the caller so the widget stays generic.
  final int activeFilterCount;

  /// Whether to show the "Clear All" button (typically true when any
  /// [GridFilter] has active states).
  final bool showClearAll;

  /// Called when the user taps "Clear All".
  final VoidCallback? onClearAll;

  /// Filter content widgets rendered in the scrollable body (e.g.
  /// a checkbox-filters card, then one [GridFilterWidget] per category).
  final List<Widget> filterWidgets;

  final ScrollController? scrollController;

  /// Width of the panel. Defaults to 300.
  final double width;

  const FiltersPanel({
    super.key,
    required this.onHide,
    required this.activeFilterCount,
    required this.filterWidgets,
    this.showClearAll = false,
    this.onClearAll,
    this.scrollController,
    this.width = 300,
  });

  @override
  State<FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  late final ScrollController _ownedController;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _ownedController = ScrollController();
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _ownedController.dispose();
    }
    super.dispose();
  }

  ScrollController get _controller =>
      widget.scrollController ?? _ownedController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Card(
          child: Scrollbar(
            thumbVisibility: true,
            controller: _controller,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 16,
                top: 8,
                bottom: 8,
              ),
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
                              ThemeManager.cornerRadius,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                spacing: 8,
                                children: [
                                  const Icon(Icons.filter_list, size: 16),
                                  Text(
                                    'Filters',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
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
                        if (widget.showClearAll)
                          TriOSToolbarItem(
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(
                          context,
                        ).copyWith(scrollbars: false),
                        child: SingleChildScrollView(
                          controller: _controller,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: widget.filterWidgets,
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
