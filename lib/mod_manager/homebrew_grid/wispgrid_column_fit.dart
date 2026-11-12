import 'dart:math';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/utils/extensions.dart';

/// Space kept between a cell's text and the next column.
const double _textPadding = 8;

/// Room for the arrow a sorted column shows next to its name.
const double _sortArrowWidth = 24;

/// Only the longest strings by character count get measured. Measuring every
/// cell is too slow on the larger grids.
const int _longestTextsToMeasure = 5;

/// Tracks how wide each column needs to be to show all of its text.
///
/// A width only ever grows while the grid is open, so searching or filtering
/// doesn't make columns jump around.
class WispGridColumnFit<T extends WispGridItem> {
  /// Column key to needed width. Columns with no text yet aren't included.
  final Map<String, double> contentWidths = {};

  final Map<String, Set<String>> _measuredItemKeys = {};

  /// Measures [items] that haven't been measured yet. An item with no text
  /// yet is tried again next time, since its data may still be loading.
  void measure({
    required List<WispGridColumn<T>> columns,
    required Iterable<T> items,
    required TextStyle? cellStyle,
    required TextStyle? headerStyle,
    required TextScaler textScaler,
  }) {
    for (final column in columns) {
      final autoFitText = column.autoFitText;
      if (autoFitText == null) continue;

      final measuredKeys = _measuredItemKeys.putIfAbsent(column.key, () => {});
      final newTexts = <String>{};
      for (final item in items) {
        if (measuredKeys.contains(item.key)) continue;
        final text = autoFitText(item);
        if (text == null || text.isEmpty) continue;
        measuredKeys.add(item.key);
        newTexts.add(text);
      }
      if (newTexts.isEmpty) continue;

      final longestTexts = newTexts
          .sortedBy<num>((text) => -text.length)
          .take(_longestTextsToMeasure);
      final cellWidth =
          longestTexts
              .map((text) => _textWidth(text, cellStyle, textScaler))
              .max +
          column.autoFitExtraWidth;
      final headerWidth =
          _textWidth(column.name, headerStyle, textScaler) +
          (column.isSortable ? _sortArrowWidth : 0);

      contentWidths[column.key] = max(
        contentWidths[column.key] ?? 0,
        max(cellWidth, headerWidth) + _textPadding,
      );
    }
  }

  double _textWidth(String text, TextStyle? style, TextScaler textScaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: .ltr,
      textScaler: textScaler,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

/// Returns [state] with automatic widths applied, for drawing only. Never
/// save the result, or the automatic widths become permanent.
///
/// A column's default width is its limit. Columns the user has resized are
/// left alone, including ones resized before automatic sizing existed, which
/// can be recognized by a width that differs from the default.
WispGridState withAutoFitWidths(
  WispGridState state,
  List<WispGridColumn> columns,
  Map<String, double> contentWidths,
) {
  final columnStates = state.sortedColumns(columns).toMap();
  for (final column in columns) {
    final contentWidth = contentWidths[column.key];
    if (contentWidth == null) continue;

    final columnState = columnStates[column.key]!;
    if (columnState.isWidthSetByUser ||
        columnState.width != column.defaultState.width) {
      continue;
    }
    columnStates[column.key] = columnState.copyWith(
      width: min(contentWidth, column.defaultState.width),
    );
  }
  return state.copyWith(columnsState: columnStates);
}

/// Returns [state] with the given columns back to automatic sizing.
WispGridState resetColumnWidths(
  WispGridState state,
  List<WispGridColumn> columns,
  Iterable<String> columnKeys,
) {
  final columnStates = state.sortedColumns(columns).toMap();
  for (final columnKey in columnKeys) {
    final defaultWidth = columns
        .firstWhere((column) => column.key == columnKey)
        .defaultState
        .width;
    columnStates[columnKey] = columnStates[columnKey]!.copyWith(
      width: defaultWidth,
      isWidthSetByUser: false,
    );
  }
  return state.copyWith(columnsState: columnStates);
}

/// Returns [state] with the given column widths saved as the user's choice.
WispGridState setColumnWidths(
  WispGridState state,
  List<WispGridColumn> columns,
  Map<String, double> widths,
) {
  final columnStates = state.sortedColumns(columns).toMap();
  widths.forEach((columnKey, width) {
    columnStates[columnKey] = columnStates[columnKey]!.copyWith(
      width: width,
      isWidthSetByUser: true,
    );
  });
  return state.copyWith(columnsState: columnStates);
}
