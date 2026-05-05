import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group_row.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_header_row_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_row_view.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';

// TODO use a keyfinder function instead of requiring implementing WispGridItem
abstract class WispGridItem {
  String get key;
}

/// Describes the pinned group shown at the top of the grid, regardless of
/// the active grouping.
class PinnedGroupInfo {
  final String name;
  final CategoryIcon? icon;
  final Color? color;

  const PinnedGroupInfo({required this.name, this.icon, this.color});
}

/// Data carried during a drag-and-drop operation between groups.
class _WispGridDragData {
  final List<String> itemKeys;
  final String dragDataType;

  _WispGridDragData({required this.itemKeys, required this.dragDataType});
}

/// Key for tracking collapse state across primary + secondary group levels.
/// [secondary] is null when the key refers to a primary group header.
class _CollapseKey {
  final Comparable? primary;
  final Comparable? secondary;

  const _CollapseKey(this.primary, [this.secondary]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _CollapseKey &&
          other.primary == primary &&
          other.secondary == secondary);

  @override
  int get hashCode => Object.hash(primary, secondary);
}

/// A rendered primary group containing one or more secondary subgroups.
/// When secondary grouping is inactive, [subgroups] has one synthetic entry.
class _RenderedGroup<T extends WispGridItem> {
  final WispGridGroup<T>? grouping;
  final Comparable? sortValue;
  final List<_RenderedSubgroup<T>> subgroups;
  final bool isPinned;

  const _RenderedGroup({
    required this.grouping,
    required this.sortValue,
    required this.subgroups,
    this.isPinned = false,
  });

  List<T> get allItems =>
      subgroups.expand((s) => s.items).toList(growable: false);
}

class _RenderedSubgroup<T extends WispGridItem> {
  final WispGridGroup<T>? grouping;
  final Comparable? sortValue;
  final List<T> items;

  const _RenderedSubgroup({
    required this.grouping,
    required this.sortValue,
    required this.items,
  });
}

/// Sentinel sort value used to identify the synthetic pinned group at the top
/// of the grid in collapse-state keys.
const String _pinnedSortValue = '__pinned__';

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

  /// Per-column additional context menu entries for column headers, keyed by column key.
  final Map<String, List<ContextMenuEntry>> perColumnContextMenuEntries;

  /// Items shown in a pinned group at the top of the grid, regardless of
  /// the active grouping.  Pass an empty list to hide the pinned group.
  final List<T> pinnedItems;

  /// Info for the pinned group header (name, icon, color).
  /// Falls back to a default "Pinned" label when null.
  final PinnedGroupInfo? pinnedGroupInfo;

  /// Additional context menu entries shown when right-clicking the pinned
  /// group header.
  final List<ContextMenuEntry> pinnedGroupContextMenuEntries;

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
    this.perColumnContextMenuEntries = const {},
    this.pinnedItems = const [],
    this.pinnedGroupInfo,
    this.pinnedGroupContextMenuEntries = const [],
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
  final Map<_CollapseKey, bool> collapseStates = {};
  final Set<String> _checkedItemIds = {};

  List<WispGridColumn<T>> get columns => widget.columns;

  WispGridState get gridState => widget.gridState;

  /// Used for shift-clicking to select a range.
  String? _lastCheckedItemId;

  // Exposed to public, and used for selecting/checking rows.
  List<T> _lastDisplayedItems = [];
  List<_RenderedGroup<T>> _lastRenderedGroups = const [];

  /// Updated by DragTargets to change drag feedback text.
  final ValueNotifier<String?> _dragTargetGroupName = ValueNotifier(null);

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
    _dragTargetGroupName.dispose();
    _gridScrollControllerVertical.dispose();
    _gridScrollControllerHorizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupingSetting = gridState.groupingSetting;

    final primaryGrouping = widget.groups.firstWhereOrNull(
      (grp) => grp.key == groupingSetting?.currentGroupedByKey,
    );
    final secondaryKey = groupingSetting?.secondaryGroupedByKey;
    final WispGridGroup<T>? secondaryGrouping = (primaryGrouping == null ||
            secondaryKey == null ||
            secondaryKey == primaryGrouping.key)
        ? null
        : widget.groups.firstWhereOrNull((g) => g.key == secondaryKey);

    final defaultSortField = widget.defaultSortField ?? columns.first.key;
    final activeSortField = gridState.sortedColumnKey ?? defaultSortField;

    final sortedItems = widget.items
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
        .toList();

    // Primary-level grouping.
    final Map<Comparable?, List<T>> primaryGrouped = {};
    for (final item in sortedItems) {
      final sortValues = primaryGrouping?.getAllGroupSortValues(item) ??
          [primaryGrouping?.getGroupSortValue(item)];
      for (final sv in sortValues) {
        (primaryGrouped[sv] ??= []).add(item);
      }
    }
    final primaryEntries = (groupingSetting?.isSortDescending ?? false)
        ? primaryGrouped.entries.sortedByDescending((e) => e.key).toList()
        : primaryGrouped.entries
            .sortedByDescending((e) => e.key)
            .reversed
            .toList();

    final renderedGroups = <_RenderedGroup<T>>[];

    // Pinned group at the top, rendered single-level regardless of secondary.
    if (widget.pinnedItems.isNotEmpty) {
      renderedGroups.add(
        _RenderedGroup<T>(
          grouping: null,
          sortValue: _pinnedSortValue,
          subgroups: [
            _RenderedSubgroup<T>(
              grouping: null,
              sortValue: null,
              items: widget.pinnedItems,
            ),
          ],
          isPinned: true,
        ),
      );
    }

    for (final entry in primaryEntries) {
      final primaryBucket = entry.value;
      List<_RenderedSubgroup<T>> subgroups;

      if (secondaryGrouping != null) {
        final Map<Comparable?, List<T>> secondaryGrouped = {};
        for (final item in primaryBucket) {
          final svs = secondaryGrouping.getAllGroupSortValues(item);
          for (final sv in svs) {
            (secondaryGrouped[sv] ??= []).add(item);
          }
        }
        // Secondary always sorts ascending (design: no secondary sort toggle).
        subgroups = secondaryGrouped.entries
            .sortedByDescending((e) => e.key)
            .reversed
            .map(
              (sEntry) => _RenderedSubgroup<T>(
                grouping: secondaryGrouping,
                sortValue: sEntry.key,
                items: sEntry.value,
              ),
            )
            .toList();
      } else {
        subgroups = [
          _RenderedSubgroup<T>(
            grouping: null,
            sortValue: null,
            items: primaryBucket,
          ),
        ];
      }

      renderedGroups.add(
        _RenderedGroup<T>(
          grouping: primaryGrouping,
          sortValue: entry.key,
          subgroups: subgroups,
        ),
      );
    }

    _lastRenderedGroups = renderedGroups;
    _lastDisplayedItems = renderedGroups
        .expand((g) => g.subgroups.expand((s) => s.items))
        .toList();

    int index = 0;
    final displayedMods = <Widget>[];

    for (final group in renderedGroups) {
      if (group.isPinned) {
        final info =
            widget.pinnedGroupInfo ?? const PinnedGroupInfo(name: 'Pinned');
        final pinnedCollapseKey = const _CollapseKey(_pinnedSortValue);
        final isPinnedCollapsed = collapseStates[pinnedCollapseKey] == true;
        final pinnedItems = group.subgroups.first.items;
        displayedMods.add(
          WispGridGroupRowView<T>(
            grouping: _PinnedWispGridGroup<T>(info),
            itemsInGroup: pinnedItems,
            isCollapsed: isPinnedCollapsed,
            setCollapsed: (c) {
              setState(() {
                collapseStates[pinnedCollapseKey] = c;
              });
            },
            shownIndex: index++,
            columns: widget.columns,
            groups: const [],
            gridState: gridState,
            updateGridState: widget.updateGridState,
            additionalContextMenuEntries: widget.pinnedGroupContextMenuEntries,
          ),
        );
        if (!isPinnedCollapsed) {
          for (final item in pinnedItems) {
            displayedMods.add(
              WispGridRowView<T>(
                key: ValueKey('pinned_${item.key}'),
                item: item,
                gridState: gridState,
                columns: widget.columns,
                rowBuilder: widget.rowBuilder,
                onTapped: () {
                  widget.onRowSelected?.call(item);
                },
                onDoubleTapped: () {
                  widget.onRowSelected?.call(item);
                },
                isRowChecked: _checkedItemIds.contains(item.key),
              ),
            );
          }
        }
        continue;
      }

      final primaryGroupingLocal = group.grouping;
      final hasPrimaryHeader =
          primaryGroupingLocal != null && primaryGroupingLocal.isGroupVisible;
      final primaryCollapseKey = _CollapseKey(group.sortValue);
      final isPrimaryCollapsed =
          hasPrimaryHeader && collapseStates[primaryCollapseKey] == true;

      if (hasPrimaryHeader) {
        final primaryBucketItems = group.allItems;
        Widget primaryHeader = WispGridGroupRowView<T>(
          grouping: primaryGroupingLocal,
          itemsInGroup: primaryBucketItems,
          isCollapsed: isPrimaryCollapsed,
          setCollapsed: (c) {
            setState(() {
              collapseStates[primaryCollapseKey] = c;
            });
          },
          shownIndex: index++,
          columns: widget.columns,
          groups: widget.groups,
          gridState: gridState,
          updateGridState: widget.updateGridState,
          groupSortValue:
              group.sortValue is Comparable ? group.sortValue : null,
        );
        if (primaryGroupingLocal.supportsDragAndDrop) {
          primaryHeader = _DragTargetGroupHeader<T>(
            grouping: primaryGroupingLocal,
            itemsInGroup: primaryBucketItems,
            hoverGroupName: _dragTargetGroupName,
            child: primaryHeader,
          );
        }
        displayedMods.add(primaryHeader);
      }

      if (isPrimaryCollapsed) continue;

      // Per-row DragTarget is wired to the primary grouping only.
      final rowDragGrouping = primaryGroupingLocal;
      final isRowDragEnabled = rowDragGrouping?.supportsDragAndDrop == true;
      final rowDragBucketItems = group.allItems;

      for (final sub in group.subgroups) {
        final hasSecondaryHeader =
            secondaryGrouping != null && sub.grouping != null;
        bool isSecondaryCollapsed = false;

        if (hasSecondaryHeader) {
          final secondaryCollapseKey =
              _CollapseKey(group.sortValue, sub.sortValue);
          isSecondaryCollapsed = collapseStates[secondaryCollapseKey] == true;

          Widget secondaryHeader = WispGridGroupRowView<T>(
            grouping: sub.grouping!,
            itemsInGroup: sub.items,
            isCollapsed: isSecondaryCollapsed,
            setCollapsed: (c) {
              setState(() {
                collapseStates[secondaryCollapseKey] = c;
              });
            },
            shownIndex: index++,
            columns: widget.columns,
            groups: widget.groups,
            gridState: gridState,
            updateGridState: widget.updateGridState,
            groupSortValue:
                sub.sortValue is Comparable ? sub.sortValue : null,
            headerStyleOverride: GroupHeaderStyle.small,
          );
          if (sub.grouping!.supportsDragAndDrop) {
            secondaryHeader = _DragTargetGroupHeader<T>(
              grouping: sub.grouping!,
              itemsInGroup: sub.items,
              hoverGroupName: _dragTargetGroupName,
              child: secondaryHeader,
            );
          }
          displayedMods.add(secondaryHeader);
          if (isSecondaryCollapsed) continue;
        }

        for (final item in sub.items) {
          Widget rowWidget = WispGridRowView<T>(
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
              } else if (HardwareKeyboard.instance.isControlPressed) {
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
          );

          if (isRowDragEnabled) {
            final draggedKeys = _checkedItemIds.contains(item.key) &&
                    _checkedItemIds.length > 1
                ? _checkedItemIds.toList()
                : [item.key];

            final baseRowWidget = rowWidget;
            rowWidget = DragTarget<_WispGridDragData>(
              onWillAcceptWithDetails: (details) =>
                  details.data.dragDataType ==
                      rowDragGrouping!.dragDataType &&
                  !details.data.itemKeys.contains(item.key),
              onAcceptWithDetails: (details) {
                _dragTargetGroupName.value = null;
                rowDragGrouping!.onItemsDropped(
                  details.data.itemKeys,
                  rowDragBucketItems,
                  ref,
                );
              },
              onMove: (details) {
                final targetName = rowDragGrouping!.getGroupName(
                  rowDragBucketItems.first,
                );
                _dragTargetGroupName.value = targetName == null
                    ? null
                    : rowDragGrouping.dragHoverLabel(
                        targetName,
                        details.data.itemKeys,
                      );
              },
              onLeave: (_) {
                _dragTargetGroupName.value = null;
              },
              builder: (context, candidateData, rejectedData) {
                return LongPressDraggable<_WispGridDragData>(
                  delay: const Duration(milliseconds: 200),
                  data: _WispGridDragData(
                    itemKeys: draggedKeys,
                    dragDataType: rowDragGrouping!.dragDataType,
                  ),
                  onDragEnd: (_) {
                    _dragTargetGroupName.value = null;
                  },
                  dragAnchorStrategy: (draggable, context, position) =>
                      const Offset(16, 16),
                  feedback: _DragFeedbackBadge(
                    label: rowDragGrouping.dragFeedbackLabel(
                      draggedKeys,
                      widget.items.nonNulls.toList(),
                    ),
                    hoverGroupName: _dragTargetGroupName,
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.4,
                    child: baseRowWidget,
                  ),
                  child: baseRowWidget,
                );
              },
            );
          }

          displayedMods.add(rowWidget);
        }
      }
    }

    final visibleColumnsForWidth =
        gridState.sortedVisibleColumns(widget.columns);
    // Width must satisfy two layouts that share this SizedBox:
    //   Row body (WispGridRowView): 2 wrapping boxes + N columns +
    //     (N+1) inter-child gaps = sum(w) + (N+3)*spacing
    //   Header (WispGridHeaderRowView): horizontal padding of 2*spacing on
    //     each side + N dividers between (N+1) MultiSplitView areas
    //     = sum(w) + (N+4)*spacing (endspace flex floors at 0)
    // The header is the larger of the two; under-allocating squeezes the
    // header columns, and onMultiSplitViewChanged persists the squeezed
    // widths back to state — a feedback loop that shrinks columns to zero.
    final totalRowWidth = visibleColumnsForWidth
            .map((e) => e.value.width)
            .sum +
        (visibleColumnsForWidth.length + 4) * WispGrid.gridRowSpacing;

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
            width: totalRowWidth,
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
          width: totalRowWidth,
          child: content,
        ),
      );
    }

    // Apply RIGHT scrollbar OUTSIDE horizontal scroll so it stays
    // pinned to the visible viewport edge, not the content edge.
    if (widget.scrollbarConfig.showRightScrollbar !=
        ScrollbarVisibility.never) {
      content = Scrollbar(
        controller: _gridScrollControllerVertical,
        scrollbarOrientation: ScrollbarOrientation.right,
        thumbVisibility:
            widget.scrollbarConfig.showRightScrollbar ==
            ScrollbarVisibility.always,
        // Allow vertical scroll notifications through regardless of depth,
        // since the horizontal SingleChildScrollView sits between this
        // Scrollbar and the vertical CustomScrollView.
        notificationPredicate: (notification) =>
            notification.metrics.axis == Axis.vertical,
        child: content,
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
            if (_isGroupHeader(item)) {
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
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
                      perColumnContextMenuEntries:
                          widget.perColumnContextMenuEntries,
                    ),
                  ),
                ),
              ),
              _buildItemSliver(displayedMods, itemSliverDelegate),
              SliverPadding(
                padding: EdgeInsets.only(bottom: widget.bottomPadding),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isGroupHeader(Widget w) =>
      w is WispGridGroupRowView || w is _DragTargetGroupHeader;

  /// Resolves the effective [GroupHeaderStyle] for a group-header widget,
  /// unwrapping any [_DragTargetGroupHeader] wrapper to read the underlying
  /// [WispGridGroupRowView.headerStyleOverride] when present.
  GroupHeaderStyle _headerStyleFor(Widget w) {
    if (w is WispGridGroupRowView) {
      return w.headerStyleOverride ??
          gridState.groupingSetting?.headerStyle ??
          GroupHeaderStyle.small;
    }
    if (w is _DragTargetGroupHeader) {
      return _headerStyleFor(w.child);
    }
    return gridState.groupingSetting?.headerStyle ?? GroupHeaderStyle.small;
  }

  double _headerHeightFor(Widget w) => switch (_headerStyleFor(w)) {
        GroupHeaderStyle.small => 28.0,
        GroupHeaderStyle.medium => 32.0,
        GroupHeaderStyle.large => 44.0,
      };

  Widget _buildItemSliver(
    List<Widget> displayedMods,
    SliverChildBuilderDelegate delegate,
  ) {
    if (widget.itemExtent == null) {
      return SliverList(delegate: delegate);
    }

    final hasGroupHeaders = displayedMods.any(_isGroupHeader);
    if (!hasGroupHeaders) {
      return SliverFixedExtentList(
        itemExtent: widget.itemExtent!,
        delegate: delegate,
      );
    }

    return SliverVariedExtentList(
      delegate: delegate,
      itemExtentBuilder: (i, _) => _isGroupHeader(displayedMods[i])
          ? _headerHeightFor(displayedMods[i])
          : widget.itemExtent!,
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
  /// Returns a CSV string with headers and data formatted as displayed in the
  /// grid. When secondary grouping is active, emits a `## Subgroup: <name>`
  /// line before each secondary bucket's rows; otherwise only `# Group:`
  /// lines appear.
  String toCsv({bool includeHeaders = true}) {
    final visibleColumns = gridState.sortedVisibleColumns(widget.columns);
    final csvRows = <List<String>>[];

    WispGridColumn<T> columnForColumnKey(String columnKey) =>
        widget.columns.firstWhere((c) => c.key == columnKey);

    if (includeHeaders) {
      final headers = visibleColumns
          .map((entry) => columnForColumnKey(entry.key).name)
          .toList();
      csvRows.add(headers);
    }

    void appendItems(List<T> items) {
      for (final item in items) {
        final row = <String>[];
        for (final columnEntry in visibleColumns) {
          final column = columnForColumnKey(columnEntry.key);
          row.add(column.csvValue?.call(item) ?? "");
        }
        csvRows.add(row);
      }
    }

    for (final group in _lastRenderedGroups) {
      String? primaryName;
      if (group.isPinned) {
        primaryName = widget.pinnedGroupInfo?.name ?? 'Pinned';
      } else if (group.grouping != null && group.grouping!.isGroupVisible) {
        final firstItem = group.allItems.firstOrNull;
        if (firstItem != null) {
          primaryName = group.grouping!.getGroupName(
                firstItem,
                groupSortValue: group.sortValue,
              ) ??
              group.grouping!.displayName;
        }
      }
      if (primaryName != null) {
        csvRows.add(["# Group: $primaryName"]);
      }

      // Pinned groups and single-level groupings render as one flat list.
      final emitSubgroupMarkers =
          !group.isPinned && group.subgroups.any((s) => s.grouping != null);

      for (final sub in group.subgroups) {
        if (emitSubgroupMarkers && sub.grouping != null) {
          final firstItem = sub.items.firstOrNull;
          final subName = firstItem == null
              ? sub.grouping!.displayName
              : (sub.grouping!.getGroupName(
                    firstItem,
                    groupSortValue: sub.sortValue,
                  ) ??
                  sub.grouping!.displayName);
          csvRows.add(["## Subgroup: $subName"]);
        }
        appendItems(sub.items);
      }
    }

    return convertRowsToCsv(csvRows);
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

/// Wraps a group header in a [DragTarget] to accept drops from dragged rows.
/// Drag feedback badge that reactively shows "Move to <group>" when hovering
/// over a valid drop target.
class _DragFeedbackBadge extends StatelessWidget {
  final String label;
  final ValueNotifier<String?> hoverGroupName;

  const _DragFeedbackBadge({required this.label, required this.hoverGroupName});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: hoverGroupName,
      builder: (context, groupName, _) {
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              groupName ?? label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        );
      },
    );
  }
}

class _DragTargetGroupHeader<T extends WispGridItem> extends ConsumerWidget {
  final WispGridGroup<T> grouping;
  final List<T> itemsInGroup;
  final ValueNotifier<String?> hoverGroupName;
  final Widget child;

  const _DragTargetGroupHeader({
    super.key,
    required this.grouping,
    required this.itemsInGroup,
    required this.hoverGroupName,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<_WispGridDragData>(
      onWillAcceptWithDetails: (details) {
        return details.data.dragDataType == grouping.dragDataType;
      },
      onAcceptWithDetails: (details) {
        hoverGroupName.value = null;
        grouping.onItemsDropped(details.data.itemKeys, itemsInGroup, ref);
      },
      onMove: (details) {
        final targetName = grouping.getGroupName(itemsInGroup.first);
        hoverGroupName.value = targetName == null
            ? null
            : grouping.dragHoverLabel(targetName, details.data.itemKeys);
      },
      onLeave: (_) {
        hoverGroupName.value = null;
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        if (!isHovered) return child;

        final brightness = Theme.of(context).brightness;
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
            BlendMode.srcATop,
          ),
          child: child,
        );
      },
    );
  }
}

/// A lightweight [WispGridGroup] that returns fixed values from
/// [PinnedGroupInfo], used so the pinned group can reuse
/// [WispGridGroupRowView] without duplicating header rendering logic.
class _PinnedWispGridGroup<T extends WispGridItem> extends WispGridGroup<T> {
  final PinnedGroupInfo info;

  _PinnedWispGridGroup(this.info) : super('__pinned__', info.name);

  @override
  String? getGroupName(T mod, {Comparable? groupSortValue}) => info.name;

  @override
  Comparable? getGroupSortValue(T mod) => null;

  @override
  Color? getGroupColor(T mod, {Comparable? groupSortValue}) => info.color;

  @override
  CategoryIcon? getGroupIcon(T mod, {Comparable? groupSortValue}) => info.icon;
}
