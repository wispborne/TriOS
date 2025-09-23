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
  final Widget Function({
    required T item,
    required RowBuilderModifiers modifiers,
    required Widget child,
  })
  rowBuilder;
  final WispGridGroup<T>? defaultGrouping;
  final String? defaultSortField;
  final void Function(WispGridController<T> controller)? onLoaded;
  final WispGridState gridState;
  final Function(WispGridState? Function(WispGridState)) updateGridState;
  final double? itemExtent;
  final double topPadding;
  final double bottomPadding;

  /// Controls which scrollbars are visible in the grid
  final ScrollbarConfig scrollbarConfig;

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
    this.topPadding = 0,
    this.bottomPadding = 8,
    this.scrollbarConfig = const ScrollbarConfig(),
  });

  static Widget defaultRowBuilder({
    required WispGridItem item,
    required RowBuilderModifiers modifiers,
    required Widget child,
  }) => child;

  @override
  ConsumerState<WispGrid<T>> createState() => _WispGridState<T>();
}

/// Configuration for scrollbars in WispGrid
class ScrollbarConfig {
  final ScrollbarVisibility showLeftScrollbar;

  final ScrollbarVisibility showRightScrollbar;

  final ScrollbarVisibility showBottomScrollbar;

  const ScrollbarConfig({
    this.showLeftScrollbar = ScrollbarVisibility.always,
    this.showRightScrollbar = ScrollbarVisibility.never,
    this.showBottomScrollbar = ScrollbarVisibility.auto,
  });
}

enum ScrollbarVisibility { auto, always, never }

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

extension WispGridColumnsExtension on WispGridState {
  double getWidthUpToColumn(String columnKey, List<WispGridColumn> columns) =>
      sortedVisibleColumns(columns)
          .takeWhile((element) => element.key != columnKey)
          .map((e) => e.value.width + WispGrid.gridRowSpacing)
          .sum;
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

  // Exposed to public, and used for selecting/checking rows.
  List<T> _lastDisplayedItems = [];
  List<MapEntry<WispGridGroup<T>?, List<T>>> _lastDisplayedItemsInGroups = [];

  @override
  void initState() {
    super.initState();
    if (widget.onLoaded == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLoaded!(WispGridController(this));
    });
  }

  @override
  void dispose() {
    _gridScrollControllerVertical.dispose();
    _gridScrollControllerHorizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupingSetting = gridState.groupingSetting;

    final grouping = widget.groups.firstWhereOrNull(
      (grp) => grp.key == groupingSetting?.currentGroupedByKey,
    );
    final defaultSortField = widget.defaultSortField ?? columns.first.key;
    final activeSortField = gridState.sortedColumnKey ?? defaultSortField;

    final items = widget.items
        .whereType<T>()
        // Sort by favorites first, then by the active sort field
        .sorted((left, right) {
          final preSortResult =
              widget.preSortComparator?.call(left, right) ?? 0;
          if (preSortResult != 0) {
            return preSortResult;
          }

          final leftValue = _getSortValueForItem(
            left,
            activeSortField,
            columns,
          );
          final rightValue = _getSortValueForItem(
            right,
            activeSortField,
            columns,
          );

          int sortResult = _compareItems(leftValue, rightValue);
          bool usedSecondarySort = false;

          if (sortResult == 0) {
            usedSecondarySort = true;
            // Use default for tiebreaker (secondary sort)
            final leftSecondary = _getSortValueForItem(
              left,
              defaultSortField,
              columns,
            );
            final rightSecondary = _getSortValueForItem(
              right,
              defaultSortField,
              columns,
            );
            sortResult = _compareItems(leftSecondary, rightSecondary);
          }

          // Flip sorting for the main sort, but always sort secondary sort in the same direction
          // i.e. sort by Update in either direction, but always secondary sort by Name ascending
          return gridState.isSortDescending && !usedSecondarySort
              ? sortResult * -1
              : sortResult;
        })
        .groupBy((item) => grouping?.getGroupSortValue(item))
        .entries
        .let(
          (entries) => groupingSetting?.isSortDescending ?? false
              ? entries.sortedByDescending((entry) => entry.key)
              : entries.sortedByDescending((entry) => entry.key).reversed,
        )
        .toList();
    _lastDisplayedItems = items.flatMap((entry) => entry.value).toList();
    _lastDisplayedItemsInGroups = items
        .map(
          (entry) => MapEntry(
            entry.key == null ? null : widget.groups[entry.key as int],
            entry.value,
          ),
        )
        .toList();

    int index = 0;

    final displayedMods = items
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
                    .map(
                      (item) => WispGridRowView<T>(
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
                              .instance
                              .isControlPressed) {
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
                      ),
                    )
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

    // Start with the content area
    Widget content = _buildVerticalScrollView(displayedMods, totalRowWidth);

    // Apply scrollbars based on configuration
    if (widget.scrollbarConfig.showLeftScrollbar != ScrollbarVisibility.never) {
      content = Scrollbar(
        controller: _gridScrollControllerVertical,
        scrollbarOrientation: ScrollbarOrientation.left,
        thumbVisibility:
            widget.scrollbarConfig.showLeftScrollbar ==
            ScrollbarVisibility.always,
        child: content,
      );
    }

    if (widget.scrollbarConfig.showRightScrollbar !=
        ScrollbarVisibility.never) {
      content = Scrollbar(
        controller: _gridScrollControllerVertical, // Same controller for sync
        scrollbarOrientation: ScrollbarOrientation.right,
        thumbVisibility:
            widget.scrollbarConfig.showRightScrollbar ==
            ScrollbarVisibility.always,
        child: content,
      );
    }

    // Apply horizontal scrollbar if needed
    if (widget.scrollbarConfig.showBottomScrollbar !=
        ScrollbarVisibility.never) {
      content = Scrollbar(
        controller: _gridScrollControllerHorizontal,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        thumbVisibility:
            widget.scrollbarConfig.showBottomScrollbar ==
            ScrollbarVisibility.always,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _gridScrollControllerHorizontal,
          child: SizedBox(
            width: gridState
                .sortedVisibleColumns(widget.columns)
                .map((e) => e.value.width + WispGrid.gridRowSpacing + 10)
                .sum,
            child: content,
          ),
        ),
      );
    } else {
      // Even without scrollbar, we still need the horizontal scroll view
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _gridScrollControllerHorizontal,
        child: SizedBox(
          width: gridState
              .sortedVisibleColumns(widget.columns)
              .map((e) => e.value.width + WispGrid.gridRowSpacing + 10)
              .sum,
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildVerticalScrollView(
    List<Widget> displayedMods,
    double totalRowWidth,
  ) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Builder(
        builder: (context) {
          final itemSliverDelegate = SliverChildBuilderDelegate((
            context,
            index,
          ) {
            final item = displayedMods[index];

            // Handle group-row widgets vs normal row widgets
            if (item is WispGridGroupRowView) {
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: SizedBox(width: totalRowWidth, child: item),
                  ),
                  const Spacer(),
                ],
              );
            }

            // Otherwise it's a normal row widget (WispGridRowView, etc.)
            try {
              return item; // Already built widget
            } catch (e) {
              Fimber.v(() => 'Error in WispGrid: $e');
              return const Text("Incoherent screaming");
            }
          }, childCount: displayedMods.length);

          return CustomScrollView(
            controller: _gridScrollControllerVertical,
            slivers: [
              SliverPadding(padding: EdgeInsets.only(top: widget.topPadding)),
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
              SliverPadding(
                padding: EdgeInsets.only(bottom: widget.bottomPadding),
              ),
            ],
          );
        },
      ),
    );
  }

  int _compareItems(
    Comparable<dynamic>? leftValue,
    Comparable<dynamic>? rightValue,
  ) {
    int sortResult;
    if (leftValue != null && rightValue != null) {
      sortResult = leftValue.compareTo(rightValue);
    } else if (leftValue == null && rightValue == null) {
      sortResult = 0;
    } else if (leftValue == null) {
      sortResult = -1;
    } else {
      sortResult = 1;
    }

    return sortResult;
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
    T mod,
    String sortField,
    List<WispGridColumn<T>> columns,
  ) {
    final column = columns.firstWhereOrNull(
      (column) => column.key == sortField,
    );
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
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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

extension WispGridCsvExport<T extends WispGridItem> on _WispGridState<T> {
  /// Converts the currently visible grid data to CSV format.
  /// Returns a CSV string with headers and data formatted as displayed in the grid.
  String toCsv({bool includeHeaders = true}) {
    final visibleColumns = gridState.sortedVisibleColumns(widget.columns);
    final csvRows = <List<String>>[];

    WispGridColumn<T> columnForColumnKey(String columnKey) =>
        widget.columns.firstWhere((c) => c.key == columnKey);

    // Add headers if requested
    if (includeHeaders) {
      final headers = visibleColumns
          .map((entry) => columnForColumnKey(entry.key).name)
          .toList();
      csvRows.add(headers);
    }

    // Process each item from the last displayed items
    for (final item in _lastDisplayedItemsInGroups) {
      if (item.key != null) {
        csvRows.add(["# Group: ${item.key?.displayName}"]);
      }

      final itemsInGroup = item.value;

      for (final item in itemsInGroup) {
        final row = <String>[];
        for (final columnEntry in visibleColumns) {
          final column = columnForColumnKey(columnEntry.key);
          row.add(column.csvValue?.call(item) ?? "");
        }
        csvRows.add(row);
      }
    }

    return _convertRowsToCsv(csvRows);
  }

  /// Converts rows of data to properly escaped CSV format
  String _convertRowsToCsv(List<List<String>> rows) {
    return rows
        .map((row) => row.map((cell) => _escapeCsvValue(cell)).join(','))
        .join('\n');
  }

  /// Properly escapes a CSV value by wrapping in quotes if necessary
  String _escapeCsvValue(String value) {
    if (value.contains(',') ||
        value.contains('\n') ||
        value.contains('\r') ||
        value.contains('"')) {
      final escapedValue = value.replaceAll('"', '""');
      return '"$escapedValue"';
    }
    return value;
  }
}

/// Utility methods to add CSV export functionality to WispGrid
class WispGridCsvExporter {
  /// Converts the grid's visible data to CSV using the provided controller
  static String toCsv<T extends WispGridItem>(
    WispGridController<T> controller, {
    bool includeHeaders = true,
  }) => controller._wispGridState.toCsv(includeHeaders: includeHeaders);
}
