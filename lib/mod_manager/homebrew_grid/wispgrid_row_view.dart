import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_frozen_overlay.dart';
import 'package:trios/widgets/hoverable_widget.dart';

class WispGridRowView<T extends WispGridItem> extends ConsumerStatefulWidget {
  final T item;

  final bool isRowChecked;
  final void Function() onTapped;
  final void Function() onDoubleTapped;
  final List<WispGridColumn<T>> columns;
  final Widget Function({
    required T item,
    required RowBuilderModifiers modifiers,
    required Widget child,
  })
  rowBuilder;
  final WispGridState gridState;

  /// The grid's horizontal scroll controller, used to hold the frozen columns
  /// at the left edge. Null means no frozen copy is drawn.
  final ScrollController? horizontalScrollController;

  const WispGridRowView({
    super.key,
    required this.item,
    required this.onTapped,
    required this.onDoubleTapped,
    required this.isRowChecked,
    required this.columns,
    required this.rowBuilder,
    required this.gridState,
    this.horizontalScrollController,
  });

  @override
  ConsumerState createState() => _WispGridRowViewState<T>();
}

class _WispGridRowViewState<T extends WispGridItem>
    extends ConsumerState<WispGridRowView<T>> {
  static const _standardRowHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final columnsToShow = widget.gridState.sortedVisibleColumns(widget.columns);
    final frozenColumns = columnsToShow
        .where((entry) => entry.value.isFrozen)
        .toList();
    final scrollController = widget.horizontalScrollController;

    return HoverableWidget(
      onTap: () => widget.onTapped(),
      child: Builder(
        builder: (context) {
          final isHovering = HoverData.of(context)?.isHovering ?? false;

          final row = _buildRow(
            columnsToShow,
            isHovering: isHovering,
            hasTrailingSpacer: true,
          );

          if (frozenColumns.isEmpty || scrollController == null) return row;

          return Stack(
            // The real row must lay out exactly as it would without the
            // overlay, so hand it the constraints the grid gave us.
            fit: StackFit.passthrough,
            children: [
              row,
              WispGridFrozenOverlay(
                horizontalScrollController: scrollController,
                width: widget.gridState.frozenBlockWidth(widget.columns),
                child: _buildRow(
                  frozenColumns,
                  isHovering: isHovering,
                  hasTrailingSpacer: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the row through the page's own `rowBuilder`, so the frozen copy
  /// gets the same background, hover tint and click handling as the real row.
  Widget _buildRow(
    List<MapEntry<String, WispGridColumnState>> columnsToShow, {
    required bool isHovering,
    required bool hasTrailingSpacer,
  }) {
    final item = widget.item;

    return widget.rowBuilder(
      item: item,
      modifiers: RowBuilderModifiers(
        isHovering: isHovering,
        isRowChecked: widget.isRowChecked,
        columns: widget.columns,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: WispGrid.gridRowSpacing,
              children: [
                SizedBox(width: WispGrid.gridRowSpacing),
                ...columnsToShow.map((columnSetting) {
                  return Builder(
                    builder: (context) {
                      final header = columnSetting.key;
                      final state = columnSetting.value;
                      final gridColumn = widget.columns.firstWhereOrNull(
                        (column) => column.key == header,
                      );

                      if (gridColumn == null) {
                        return Container();
                      }
                      return _RowItemContainer(
                        height: _standardRowHeight,
                        width: state.width,
                        child:
                            gridColumn.itemCellBuilder?.call(
                              item,
                              CellBuilderModifiers(
                                isHovering: isHovering,
                                isRowChecked: widget.isRowChecked,
                                columnState: state,
                              ),
                            ) ??
                            Text(item.toString()),
                      );
                    },
                  );
                }),
                if (hasTrailingSpacer) SizedBox(width: WispGrid.gridRowSpacing),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowItemContainer extends StatelessWidget {
  final Widget child;
  final double height;
  final double width;

  const _RowItemContainer({
    required this.child,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          width: width,
          // Same placement as before (left, vertically centered), but a cell
          // that asks for the full width or height now gets it.
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ],
    );
  }
}
