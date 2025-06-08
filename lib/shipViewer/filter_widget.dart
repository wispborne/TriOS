import 'package:flutter/material.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/widgets/text_trios.dart';

class ShipFilterWidget extends StatefulWidget {
  final String columnName;
  final String Function(Ship) getValue;
  final List<Ship> ships;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>> onSelectionChanged;

  const ShipFilterWidget({
    super.key,
    required this.columnName,
    required this.getValue,
    required this.ships,
    required this.selectedValues,
    required this.onSelectionChanged,
  });

  @override
  State<ShipFilterWidget> createState() => _ShipFilterWidgetState();
}

class _ShipFilterWidgetState extends State<ShipFilterWidget> {
  List<String> _uniqueValues = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _updateUniqueValues();
  }

  @override
  void didUpdateWidget(ShipFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ships != widget.ships) {
      _updateUniqueValues();
    }
  }

  void _updateUniqueValues() {
    final values = widget.ships
        .map(widget.getValue)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    _uniqueValues = values;
  }

  void _toggleValue(String value) {
    final newSelection = Set<String>.from(widget.selectedValues);
    if (newSelection.contains(value)) {
      newSelection.remove(value);
    } else {
      newSelection.add(value);
    }
    widget.onSelectionChanged(newSelection);
  }

  void _selectAll() {
    widget.onSelectionChanged(_uniqueValues.toSet());
  }

  void _clearAll() {
    widget.onSelectionChanged(<String>{});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = widget.selectedValues.isNotEmpty;
    final selectedCount = widget.selectedValues.length;
    final totalCount = _uniqueValues.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextTriOS(
                      widget.columnName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasSelection
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (hasSelection)
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
                        '$selectedCount/$totalCount',
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
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Select/Clear buttons
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _selectAll,
                      icon: const Icon(Icons.check_box, size: 16),
                      label: const Text('Select All'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.check_box_outline_blank, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _uniqueValues.map((value) {
                        final isSelected = widget.selectedValues.contains(
                          value,
                        );
                        return FilterChip(
                          label: Text(
                            value,
                            style: theme.textTheme.labelMedium,
                          ),
                          selected: isSelected,
                          onSelected: (_) => _toggleValue(value),
                          selectedColor: theme.colorScheme.primary.withOpacity(
                            0.15,
                          ),
                          checkmarkColor: theme.colorScheme.primary,
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.25),
                          ),
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
