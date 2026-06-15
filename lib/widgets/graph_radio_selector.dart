import 'package:flutter/material.dart';

enum GraphType { pie, bar }

class GraphTypeSelector extends StatefulWidget {
  final ValueChanged<GraphType> onGraphTypeChanged;

  const GraphTypeSelector({super.key, required this.onGraphTypeChanged});

  @override
  GraphTypeSelectorState createState() => GraphTypeSelectorState();
}

class GraphTypeSelectorState extends State<GraphTypeSelector> {
  GraphType _selectedType = GraphType.bar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SegmentedButton<GraphType>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return null;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimaryContainer;
          }
          return null;
        }),
      ),
      segments: [
        ButtonSegment<GraphType>(
          value: GraphType.bar,
          icon: const Icon(Icons.bar_chart, size: 20),
          tooltip: 'Bar Chart',
        ),
        ButtonSegment<GraphType>(
          value: GraphType.pie,
          icon: const Icon(Icons.pie_chart, size: 20),
          tooltip: 'Pie Chart',
        ),
      ],
      selected: {_selectedType},
      onSelectionChanged: (Set<GraphType> selected) {
        setState(() {
          _selectedType = selected.first;
          widget.onGraphTypeChanged(selected.first);
        });
      },
    );
  }
}
