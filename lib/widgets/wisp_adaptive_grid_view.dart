import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A reusable widget that lays out [items] in a responsive, adaptive grid:
/// - Figures out how many columns fit based on [minItemWidth].
/// - Places [horizontalSpacing] between columns.
/// - Each row only takes as much vertical space as its tallest child.
/// - You can provide optional [padding].
/// - Provide [itemBuilder] to build each cell from an item.
class WispAdaptiveGridView<T> extends StatelessWidget {
  /// The items to display in the grid.
  final List<T> items;

  /// Minimum width of each grid item. The widget will use as many columns
  /// as can fit items of at least this width (plus [horizontalSpacing]).
  final double minItemWidth;

  /// The horizontal spacing between items in a row.
  final double? horizontalSpacing;
  final double? verticalSpacing;

  /// Padding around the entire scrollable area.
  final EdgeInsets padding;

  /// Called to build each item in the grid.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  const WispAdaptiveGridView({
    super.key,
    required this.items,
    required this.minItemWidth,
    this.horizontalSpacing,
    this.verticalSpacing,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth =
            constraints.maxWidth - (padding.left + padding.right);
        // In case the user gave large horizontal padding, avoid negative containerWidth.
        final availableWidth = math.max(containerWidth, 0.0);

        final layout = _calculateGridLayout(
          containerWidth: availableWidth,
          minItemWidth: minItemWidth,
          horizontalMargin: horizontalSpacing ?? 0.0,
        );

        final rows = <Widget>[];
        for (int i = 0; i < items.length; i += layout.columns) {
          final rowItems =
              items.sublist(i, math.min(i + layout.columns, items.length));

          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int r = 0; r < rowItems.length; r++) ...[
                  SizedBox(
                    width: layout.itemWidth,
                    child: itemBuilder(context, rowItems[r], i + r),
                  ),
                  if (r < rowItems.length - 1)
                    SizedBox(width: horizontalSpacing),
                ],
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: padding,
          child: Column(
            spacing: verticalSpacing ?? 0,
            children: rows,
          ),
        );
      },
    );
  }
}

/// Simple data class to hold the grid layout parameters.
class _WispAdaptiveGridLayout {
  final int columns;
  final double itemWidth;

  const _WispAdaptiveGridLayout(this.columns, this.itemWidth);
}

/// Computes how many columns fit and how wide each item should be
/// so that the grid fills [containerWidth] exactly (except for
/// small rounding) with at least [minItemWidth] per item.
///
/// [horizontalMargin] is the gap between items in a row.
_WispAdaptiveGridLayout _calculateGridLayout({
  required double containerWidth,
  required double minItemWidth,
  required double horizontalMargin,
}) {
  int columns =
      ((containerWidth + horizontalMargin) / (minItemWidth + horizontalMargin))
          .floor();

  while (columns > 0) {
    final itemWidth =
        (containerWidth - (columns - 1) * horizontalMargin) / columns;
    if (itemWidth >= minItemWidth) {
      return _WispAdaptiveGridLayout(columns, itemWidth);
    }
    columns--;
  }

  // fallback: 1 column
  return _WispAdaptiveGridLayout(1, containerWidth);
}
