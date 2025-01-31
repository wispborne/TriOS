import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktx/collections.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group_row.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_header_row_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_row_view.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

// TODO use a keyfinder function instead of requiring implementing WispGridItem
abstract class WispGridItem {
  String get key;
}

class WispGrid<T extends WispGridItem> extends ConsumerStatefulWidget {
  static const gridRowSpacing = 8.0;
  static const lightTextOpacity = 0.8;
  final List<T?> items;
  final Function(T item)? onRowSelected;
  final T? selectedItem;
  final List<WispGridColumn<T>> columns;
  final List<WispGridGroup<T>> groups;
  final int? Function(T left, T right)? preSortComparator;
  final Widget Function(T item, RowBuilderModifiers modifiers, Widget child)
      rowBuilder;
  final WispGridGroup<T>? defaultGrouping;
  final String? defaultSortField;
  final void Function(WispGridController<T> controller)? onLoaded;
  final WispGridState gridState;
  final Function(WispGridState Function(WispGridState)) updateGridState;
  final double? itemExtent;
  final bool alwaysShowScrollbar;

  const WispGrid({
    super.key,
    required this.items,
    required this.columns,
    this.onRowSelected,
    this.groups = const [],
    this.rowBuilder = defaultRowBuilder,
    this.preSortComparator,
    this.selectedItem,
    this.defaultGrouping,
    this.defaultSortField,
    this.onLoaded,
    required this.gridState,
    required this.updateGridState,
    this.itemExtent,
    this.alwaysShowScrollbar = false,
  });

  static Widget defaultRowBuilder(
    WispGridItem item,
    RowBuilderModifiers modifiers,
    Widget child,
  ) =>
      child;

  @override
  ConsumerState<WispGrid<T>> createState() => _WispGridState<T>();
}

/// Provides readonly access to the grid's internal state.
class WispGridController<T extends WispGridItem> {
  final _WispGridState<T> _wispGridState;

  /// The currently checked item ids. Modifying this will do nothing.
  Set<String> get checkedItemIdsReadonly =>
      _wispGridState._checkedItemIds.toSet();

  /// The last displayed items. Modifying this will do nothing, though modifying the items themselves will work (please don't).
  List<T> get lastDisplayedItemsReadonly =>
      _wispGridState._lastDisplayedItems.toList();

  WispGridController(ConsumerState<WispGrid<T>> wispGridState)
      : _wispGridState = wispGridState as _WispGridState<T>;
}

class _WispGridState<T extends WispGridItem>
    extends ConsumerState<WispGrid<T>> {
  final ScrollController _gridScrollControllerVertical = ScrollController();
  final ScrollController _gridScrollControllerHorizontal = ScrollController();
  final Map<Object?, bool> collapseStates = {};
  final Set<String> _checkedItemIds = {};

  List<WispGridColumn<T>> get columns => widget.columns;

  WispGridState get gridState => widget.gridState;

  /// Used for shift-clicking to select a range.
  String? _lastCheckedItemId;
  List<T> _lastDisplayedItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.onLoaded == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLoaded!(WispGridController(this));
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupingSetting = gridState.groupingSetting;

    final grouping = widget.groups.firstWhereOrNull(
            (grp) => grp.key == groupingSetting?.currentGroupedByKey);
    final activeSortField = gridState.sortedColumnKey ??
        widget.defaultSortField ??
        columns.first.key;

    final items = widget.items
        .whereType<T>()
        // Sort by favorites first, then by the active sort field
        .sorted(
          (left, right) {
            final preSortResult =
                widget.preSortComparator?.call(left, right) ?? 0;
            if (preSortResult != 0) {
              return preSortResult;
            }

            final leftValue =
                _getSortValueForItem(left, activeSortField, columns);
            final rightValue =
                _getSortValueForItem(right, activeSortField, columns);

            final sortResult = (leftValue != null && rightValue != null)
                ? leftValue.compareTo(rightValue)
                : (leftValue == null && rightValue == null)
                    ? 0
                    : (leftValue == null ? -1 : 1);

            return gridState.isSortDescending ? sortResult * -1 : sortResult;
          },
        )
        .groupBy((item) => grouping?.getGroupSortValue(item))
        .entries
        .let((entries) => groupingSetting?.isSortDescending ?? false
            ? entries.sortedByDescending((entry) => entry.key)
            : entries.sortedByDescending((entry) => entry.key).reversed)
        .toList();
    _lastDisplayedItems = items.flatMap((entry) => entry.value).toList();

    int index = 0;

    final displayedMods = [
          // SizedBox(
          //     height: 30,
          //     child: WispGridHeaderRowView(
          //       gridState: gridState,
          //       groups: widget.groups,
          //       updateGridState: widget.updateGridState,
          //       columns: columns,
          //     )) as Widget
        ] +
        items
            .flatMap((entry) {
              final groupSortValue = entry.key;
              final itemsInGroup = entry.value;
              final isCollapsed = collapseStates[groupSortValue] == true;

              final widgets = <Widget>[];

              if (grouping != null && grouping.isGroupVisible) {
                final header = WispGridGroupRowView(
                  grouping: grouping,
                  itemsInGroup: itemsInGroup,
                  isCollapsed: isCollapsed,
                  setCollapsed: (isCollapsed) {
                    setState(() {
                      collapseStates[groupSortValue] = isCollapsed;
                    });
                  },
                  shownIndex: index++,
                  columns: widget.columns,
                );
                widgets.add(header);
              }
              final items = !isCollapsed
                  ? itemsInGroup
                      .map((item) => WispGridRowView<T>(
                            key: ValueKey(item.key),
                            item: item,
                            gridState: gridState,
                            columns: widget.columns,
                            rowBuilder: widget.rowBuilder,
                            onTapped: () {
                              if (HardwareKeyboard.instance.isShiftPressed) {
                                _onRowCheck(
                                  modId: item.key,
                                  shiftPressed: true,
                                  ctrlPressed: false,
                                );
                              } else if (HardwareKeyboard
                                  .instance.isControlPressed) {
                                _onRowCheck(
                                  modId: item.key,
                                  shiftPressed: false,
                                  ctrlPressed: true,
                                );
                              } else {
                                if (widget.selectedItem != null) {
                                  widget.onRowSelected?.call(item);
                                }
                                _onRowCheck(
                                  modId: item.key,
                                  shiftPressed: false,
                                  ctrlPressed: false,
                                );
                              }
                            },
                            onDoubleTapped: () {
                              widget.onRowSelected?.call(item);
                            },
                            isRowChecked: _checkedItemIds.contains(item.key),
                          ))
                      .toList()
                  : <Widget>[];
              widgets.addAll(items);

              return widgets;
            })
            .nonNulls
            .toList();
    final totalRowWidth = gridState
        .sortedVisibleColumns(widget.columns)
        .map((e) => e.value.width + WispGrid.gridRowSpacing)
        .sum;

    // TODO smooth scrolling: https://github.com/dridino/smooth_list_view/blob/main/lib/smooth_list_view.dart
    return Scrollbar(
        controller: _gridScrollControllerHorizontal,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _gridScrollControllerHorizontal,
          child: SizedBox(
            width: gridState
                .sortedVisibleColumns(widget.columns)
                .map((e) => e.value.width + WispGrid.gridRowSpacing + 10)
                .sum
                .coerceAtMost(MediaQuery.of(context).size.width * 1.3),
            child: Scrollbar(
              controller: _gridScrollControllerVertical,
              scrollbarOrientation: ScrollbarOrientation.left,
              thumbVisibility: widget.alwaysShowScrollbar,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: Builder(builder: (context) {
                  final itemSliverDelegate = SliverChildBuilderDelegate(
                    (context, index) {
                      final item = displayedMods[index];
                      // TODO for better perf, would could add an optional height param to rows passed in.
                      // TODO Then, chunk the grid into SliverFixedExtentLists.

                      // Handle group-row widgets vs normal row widgets
                      if (item is WispGridGroupRowView) {
                        return Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: SizedBox(
                                width: totalRowWidth,
                                child: item,
                              ),
                            ),
                            const Spacer(),
                          ],
                        );
                      }

                      // Otherwise it’s a normal row widget (WispGridRowView, etc.)
                      try {
                        return item; // Already built widget
                      } catch (e) {
                        Fimber.v(() => 'Error in WispGrid: $e');
                        return const Text("Incoherent screaming");
                      }
                    },
                    childCount: displayedMods.length,
                  );

                  return CustomScrollView(
                      controller: _gridScrollControllerVertical,
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _PinnedHeaderDelegate(
                            minHeight: 30,
                            maxHeight: 30,
                            child: Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: WispGridHeaderRowView(
                                gridState: gridState,
                                groups: widget.groups,
                                updateGridState: widget.updateGridState,
                                columns: columns,
                                defaultGridSort: widget.defaultSortField,
                              ),
                            ),
                          ),
                        ),
                        widget.itemExtent == null
                            ? SliverList(delegate: itemSliverDelegate)
                            : SliverFixedExtentList(
                                itemExtent: widget.itemExtent!,
                                delegate: itemSliverDelegate,
                              ),
                      ]);
                }),
              ),
            ),
          ),
        ));
  }

  /// Handles multi-check logic for shift/control-clicking a row.
  /// Updates the set of checked mod IDs and the last checked mod ID.
  /// - `modId` The unique identifier of the row that was clicked.
  /// - `shiftPressed` True if the Shift key was held during the click.
  /// - `ctrlPressed` True if the Control (or Command on macOS) key was held during the click.
  void _onRowCheck({
    required String modId,
    required bool shiftPressed,
    required bool ctrlPressed,
  }) {
    final orderedModIds = _lastDisplayedItems.map((mod) => mod.key).toList();

    setState(() {
      if (!shiftPressed && !ctrlPressed) {
        _checkedItemIds.clear();
        _lastCheckedItemId = modId;
        return;
      }

      if (shiftPressed && _lastCheckedItemId != null) {
        final lastIndex = orderedModIds.indexOf(_lastCheckedItemId!);
        final currentIndex = orderedModIds.indexOf(modId);

        if (lastIndex == -1 || currentIndex == -1) {
          _checkedItemIds
            ..clear()
            ..add(modId);
          _lastCheckedItemId = modId;
          return;
        }

        final start = lastIndex < currentIndex ? lastIndex : currentIndex;
        final end = lastIndex < currentIndex ? currentIndex : lastIndex;
        final selectedRange = orderedModIds.sublist(start, end + 1);
        final allSelected = selectedRange.every(_checkedItemIds.contains);

        allSelected
            ? _checkedItemIds.removeAll(selectedRange)
            : _checkedItemIds.addAll(selectedRange);

        _lastCheckedItemId = modId;
      } else if (ctrlPressed) {
        _checkedItemIds.contains(modId)
            ? _checkedItemIds.remove(modId)
            : _checkedItemIds.add(modId);

        _lastCheckedItemId = modId;
      }
    });
  }

  Comparable? _getSortValueForItem(
      T mod, String sortField, List<WispGridColumn<T>> columns) {
    final column =
        columns.firstWhereOrNull((column) => column.key == sortField);
    if (column == null || !column.isSortable || column.getSortValue == null) {
      return null;
    }
    return column.getSortValue!(mod);
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _PinnedHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_PinnedHeaderDelegate oldDelegate) {
    // Rebuild if the config changes.
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
