import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TriOSDataGrid extends ConsumerStatefulWidget {
  const TriOSDataGrid({super.key});

  @override
  ConsumerState createState() => _TriOSDataGridState();
}

class _TriOSDataGridState extends ConsumerState<TriOSDataGrid> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("TriOS Data Grid"),
      ],
    );
  }
}

class TriosGridHeaderRow extends ConsumerStatefulWidget {
  final List<TriOSColumn> columns;
  final TextStyle? headerStyle;

  TriosGridHeaderRow({super.key, required this.columns, this.headerStyle});

  @override
  ConsumerState createState() => _TriosGridHeaderRowState();
}

class _TriosGridHeaderRowState extends ConsumerState<TriosGridHeaderRow> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: widget.columns.map((column) {
        return SizedBox(
          width: column.width,
          child: Text(column.label ?? "",
              style: widget.headerStyle ??
                  const TextStyle(fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }
}

class TriOSColumn {
  final double width;
  final String? label;

  TriOSColumn({required this.width, this.label});
}

class TriosGridRow extends ConsumerStatefulWidget {
  final List<TriOSColumn> columns;
  final TextStyle? rowStyle;

  TriosGridRow({super.key, required this.columns, this.rowStyle});

  @override
  ConsumerState createState() => _TriosGridRowState();
}

class _TriosGridRowState extends ConsumerState<TriosGridRow> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: widget.columns.map((column) {
        return SizedBox(
          width: column.width,
          child: Text(column.label ?? "",
              style: widget.rowStyle ?? const TextStyle()),
        );
      }).toList(),
    );
  }
}
