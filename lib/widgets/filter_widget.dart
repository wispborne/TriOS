import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/filter_engine/filter_group.dart';
import 'package:trios/widgets/filter_engine/filter_scope.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persist_button.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persistence_provider.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';

/// Widget rendering a single [ChipFilterGroup] with lock-button, tri-state
/// chips, include/exclude counts and a collapsible header.
class GridFilterWidget<T> extends ConsumerStatefulWidget {
  final ChipFilterGroup<T> filter;
  final List<T> items;
  final Map<String, bool?> filterStates;
  final Function(Map<String, bool?>) onSelectionChanged;
  final FilterScope scope;

  const GridFilterWidget({
    super.key,
    required this.filter,
    required this.items,
    required this.filterStates,
    required this.onSelectionChanged,
    required this.scope,
  });

  @override
  ConsumerState<GridFilterWidget<T>> createState() =>
      _GridFilterWidgetState<T>();
}

class _GridFilterWidgetState<T> extends ConsumerState<GridFilterWidget<T>> {
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
        values.sort((a, b) => displayName(a).compareTo(displayName(b)));
      } else {
        values.sort();
      }
    }
    _uniqueValues = values;
  }

  /// If the group is currently locked, mirror the new selections to
  /// persistence so settings reflect the latest state.
  void _maybePersist(Map<String, bool?> newFilterStates) {
    final key = FilterGroupPersistence.keyFor(widget.scope, widget.filter.id);
    final isLocked = ref
        .read(appSettings)
        .persistedFilterGroups
        .containsKey(key);
    if (!isLocked) return;
    ref
        .read(filterGroupPersistenceProvider)
        .write(widget.scope, widget.filter.id, newFilterStates);
  }

  void _emit(Map<String, bool?> newFilterStates) {
    widget.onSelectionChanged(newFilterStates);
    _maybePersist(newFilterStates);
  }

  void _toggleValue(String value) {
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

  void _selectAll() {
    final newFilterStates = Map<String, bool?>.from(widget.filterStates);
    for (final value in _uniqueValues) {
      newFilterStates[value] = true;
    }
    _emit(newFilterStates);
  }

  void _clearAll() {
    _emit({});
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
                  const SizedBox(width: 4),
                  const Spacer(),
                  if (hasFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
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
                    currentSelections: () =>
                        Map<String, Object?>.from(widget.filterStates),
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
                              TriOSThemeConstants.cornerRadius,
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
