import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A widget that lays out [items] in a responsive, adaptive grid.
///
/// Unlike a traditional [GridView], each row automatically adjusts its height
/// to fit the tallest item in that row. This widget uses [ListView.builder] to
/// build rows lazily, improving performance when [items] is large.
///
/// ### Features
/// - Determines how many columns fit based on [minItemWidth].
/// - Inserts [horizontalSpacing] between items in a row and [verticalSpacing]
///   between rows.
/// - [padding] provides outer space around the grid.
/// - [itemBuilder] is called to build each item; you get the item and its index.
///
/// ### Example
/// ```dart
/// WispAdaptiveGridView<String>(
///   items: List.generate(1000, (i) => 'Item $i'),
///   minItemWidth: 200,
///   horizontalSpacing: 8,
///   verticalSpacing: 8,
///   itemBuilder: (context, item, index) {
///     return Container(
///       color: Colors.blueGrey,
///       child: Text(item, style: TextStyle(color: Colors.white)),
///     );
///   },
/// );
/// ```
class WispAdaptiveGridView<T> extends StatelessWidget {
  /// The items to display in the grid.
  final List<T> items;

  /// Minimum width of each grid item. The widget will use as many columns
  /// as can fit items of at least this width (plus [horizontalSpacing]).
  final double minItemWidth;

  /// The horizontal spacing between items in a row.
  final double horizontalSpacing;

  /// The vertical spacing between rows.
  final double verticalSpacing;

  /// Padding around the entire scrollable area.
  final EdgeInsets padding;

  final bool shrinkWrap;

  /// Builds each item in the grid. You receive the [BuildContext], the item
  /// itself, and the absolute index of the item in [items].
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  const WispAdaptiveGridView({
    super.key,
    required this.items,
    required this.minItemWidth,
    this.horizontalSpacing = 0.0,
    this.verticalSpacing = 0.0,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust for horizontal padding to find actual available width.
        final containerWidth =
            math.max(0.0, constraints.maxWidth - padding.left - padding.right);

        // Compute how many columns we can fit and the item width for each column.
        final layout = _calculateAdaptiveLayout(
          containerWidth: containerWidth,
          minItemWidth: minItemWidth,
          horizontalSpacing: horizontalSpacing,
        );

        // Determine the total number of rows needed.
        final totalRows = (items.length + layout.columns - 1) ~/ layout.columns;

        return ListView.builder(
          padding: padding,
          itemCount: totalRows,
          shrinkWrap: shrinkWrap,
          itemBuilder: (context, rowIndex) {
            // The chunk of items for this particular row.
            final startIndex = rowIndex * layout.columns;
            final endIndex =
                math.min(startIndex + layout.columns, items.length);
            final rowItems = items.sublist(startIndex, endIndex);

            return Container(
              // Optional vertical spacing after each row (except the last).
              margin: EdgeInsets.only(
                  bottom: rowIndex < totalRows - 1 ? verticalSpacing : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < rowItems.length; i++) ...[
                    SizedBox(
                      width: layout.itemWidth,
                      child: itemBuilder(context, rowItems[i], startIndex + i),
                    ),
                    if (i < rowItems.length - 1)
                      SizedBox(width: horizontalSpacing),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// A private helper for storing the computed number of columns and item width.
class _AdaptiveLayout {
  final int columns;
  final double itemWidth;

  const _AdaptiveLayout(this.columns, this.itemWidth);
}

/// Determines how many columns can fit into [containerWidth] while ensuring
/// each item has at least [minItemWidth] width. [horizontalSpacing] is inserted
/// between columns, so each row's total width is fully utilized.
_AdaptiveLayout _calculateAdaptiveLayout({
  required double containerWidth,
  required double minItemWidth,
  required double horizontalSpacing,
}) {
  // Initial guess: maximum columns
  int columns = ((containerWidth + horizontalSpacing) /
          (minItemWidth + horizontalSpacing))
      .floor();

  while (columns > 0) {
    // Compute the final item width if we place [columns] items plus (columns - 1) spaces.
    final itemWidth =
        (containerWidth - (columns - 1) * horizontalSpacing) / columns;
    if (itemWidth >= minItemWidth) {
      return _AdaptiveLayout(columns, itemWidth);
    }
    columns--;
  }

  // Fallback if even 1 column won't fit minItemWidth => single column anyway
  return _AdaptiveLayout(1, containerWidth);
}
