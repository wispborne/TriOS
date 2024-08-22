import 'package:flutter/material.dart';
import 'package:trios/thirdparty/pluto_grid_plus/lib/pluto_grid_plus.dart';

import 'text_cell.dart';

class PlutoTextCell extends StatefulWidget implements TextCell {
  @override
  final PlutoGridStateManager stateManager;

  @override
  final PlutoCell cell;

  @override
  final PlutoColumn column;

  @override
  final PlutoRow row;

  const PlutoTextCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    super.key,
  });

  @override
  PlutoTextCellState createState() => PlutoTextCellState();
}

class PlutoTextCellState extends State<PlutoTextCell>
    with TextCellState<PlutoTextCell> {}
