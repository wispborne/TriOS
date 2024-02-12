import 'package:flutter/material.dart';

enum GraphType { pie, bar }

class GraphTypeSelector extends StatefulWidget {
  final ValueChanged<GraphType> onGraphTypeChanged;

  const GraphTypeSelector({super.key, required this.onGraphTypeChanged});

  @override
  GraphTypeSelectorState createState() => GraphTypeSelectorState();
}

class GraphTypeSelectorState extends State<GraphTypeSelector> {
  GraphType _selectedType = GraphType.pie;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: RadioListTile<GraphType>(
            title: const Text('Pie Chart'),
            value: GraphType.pie,
            groupValue: _selectedType,
            dense: true,
            onChanged: (GraphType? value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                  widget.onGraphTypeChanged(value);
                });
              }
            },
          ),
        ),
        Expanded(
          child: RadioListTile<GraphType>(
            title: const Text('Bar Chart'),
            value: GraphType.bar,
            dense: true,
            groupValue: _selectedType,
            onChanged: (GraphType? value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                  widget.onGraphTypeChanged(value);
                });
              }
            },
          ),
        ),
      ],
    );
  }
}
