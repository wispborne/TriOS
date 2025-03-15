import 'package:flutter/material.dart';
import 'package:trios/widgets/trios_radio_tile.dart';

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: TriOSRadioTile<GraphType>(
            title: const Text('Bar Chart'),
            value: GraphType.bar,
            dense: true,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
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
        Expanded(
          child: TriOSRadioTile<GraphType>(
            title: const Text('Pie Chart'),
            value: GraphType.pie,
            groupValue: _selectedType,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
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
      ],
    );
  }
}
