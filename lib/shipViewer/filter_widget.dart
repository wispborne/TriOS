import 'package:flutter/material.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/widgets/text_trios.dart';

class GridFilter {
  final String name;
  final String Function(Ship) valueGetter;
  final String Function(String)? displayNameGetter;

  // Map of values to filter states:
  // true = include, false = exclude, null = no filter
  final Map<String, bool?> filterStates = {};

  GridFilter({
    required this.name,
    required this.valueGetter,
    this.displayNameGetter,
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

class GridFilterWidget extends StatefulWidget {
  final GridFilter filter;
  final List<Ship> ships;
  final Map<String, bool?> filterStates;
  final Function(Map<String, bool?>) onSelectionChanged;

  const GridFilterWidget({
    super.key,
    required this.filter,
    required this.ships,
    required this.filterStates,
    required this.onSelectionChanged,
  });

  @override
  State<GridFilterWidget> createState() => _GridFilterWidgetState();
}

class _GridFilterWidgetState extends State<GridFilterWidget> {
  List<String> _uniqueValues = [];
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _updateUniqueValues();
  }

  @override
  void didUpdateWidget(GridFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ships != widget.ships) {
      _updateUniqueValues();
    }
  }

  void _updateUniqueValues() {
    final values = widget.ships
        .map(widget.filter.valueGetter)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
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

  int get totalCount => _uniqueValues.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilters = widget.filterStates.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
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
                  Spacer(),
                  if (hasFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: TextTriOS(
                        '${includedCount}+ ${excludedCount}-',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 200,
                    child: SingleChildScrollView(
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
                              side = BorderSide(
                                color: theme.colorScheme.primary,
                              );
                              break;
                            case false: // Exclude
                              chipColor = theme.colorScheme.secondaryContainer;
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

                          return FilterChip(
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
                            backgroundColor: Colors.transparent,
                            side: side,
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
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
