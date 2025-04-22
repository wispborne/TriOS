import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
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

  const WispGridRowView({
    super.key,
    required this.item,
    required this.onTapped,
    required this.onDoubleTapped,
    required this.isRowChecked,
    required this.columns,
    required this.rowBuilder,
    required this.gridState,
  });

  @override
  ConsumerState createState() => _WispGridRowViewState<T>();
}

class _WispGridRowViewState<T extends WispGridItem>
    extends ConsumerState<WispGridRowView<T>> {
  static const _standardRowHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final height = _standardRowHeight;

    return HoverableWidget(
      onTapDown: () => widget.onTapped(),
      child: Builder(
        builder: (context) {
          final isHovering = HoverData.of(context)?.isHovering ?? false;

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
                      ...(widget.gridState
                          .sortedVisibleColumns(widget.columns)
                          .map((columnSetting) {
                            return Builder(
                              builder: (context) {
                                final header = columnSetting.key;
                                final state = columnSetting.value;
                                final gridColumn = widget.columns
                                    .firstWhereOrNull(
                                      (column) => column.key == header,
                                    );

                                if (gridColumn == null) {
                                  return Container();
                                }
                                return _RowItemContainer(
                                  height: height,
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
                          })
                          .toList()),
                      SizedBox(width: WispGrid.gridRowSpacing),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [child],
          ),
        ),
      ],
    );
  }
}
