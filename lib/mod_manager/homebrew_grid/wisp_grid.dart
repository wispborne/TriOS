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
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

abstract class WispGridItem {
  String get key;
}

class WispGrid<T extends WispGridItem> extends ConsumerStatefulWidget {
  static const gridRowSpacing = 8.0;
  static const lightTextOpacity = 0.8;
  final List<T?> items;
  final Function(dynamic mod) onRowSelected;
  final T? selectedMod;
  final List<WispGridColumn<T>> columns;
  final List<WispGridGroup<T>> groups;
  final int? Function(T left, T right)? preSortComparator;
  final Widget Function(T item, RowBuilderModifiers modifiers, Widget child)
      rowBuilder;
  final WispGridGroup<T>? defaultGrouping;
  final void Function(WispGridController<T> controller)? onLoaded;

  const WispGrid({
    super.key,
    required this.items,
    required this.onRowSelected,
    required this.columns,
    required this.groups,
    required this.rowBuilder,
    this.preSortComparator,
    this.selectedMod,
    this.defaultGrouping,
    this.onLoaded,
  });

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
    final gridState = ref.watch(appSettings.select((s) => s.modsGridState));
    final groupingSetting = gridState.groupingSetting;

    final grouping = widget.groups.firstWhereOrNull(
            (grp) => grp.key == groupingSetting?.currentGroupedByKey) ??
        widget.defaultGrouping;
    final activeSortField = gridState.sortedColumnKey ?? columns.first.key;

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

            final sortResult =
                _getSortValueForItem(left, activeSortField, columns)?.compareTo(
                        _getSortValueForItem(
                            right, activeSortField, columns)) ??
                    0;
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
          SizedBox(
              height: 30,
              child: WispGridHeaderRowView(
                gridState: gridState,
                groups: widget.groups,
                updateGridState: (updateFunction) {
                  ref.read(appSettings.notifier).update((state) {
                    return state.copyWith(
                        modsGridState: updateFunction(state.modsGridState));
                  });
                },
                columns: columns,
              )) as Widget
        ] +
        items
            .flatMap((entry) {
              final groupSortValue = entry.key;
              final itemsInGroup = entry.value;
              final isCollapsed = collapseStates[groupSortValue] == true;

              final widgets = <Widget>[];

              if (grouping != null) {
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
                                if (widget.selectedMod != null) {
                                  widget.onRowSelected(item);
                                }
                                _onRowCheck(
                                  modId: item.key,
                                  shiftPressed: false,
                                  ctrlPressed: false,
                                );
                              }
                            },
                            onDoubleTapped: () {
                              widget.onRowSelected(item);
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
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: displayedMods.length,
                  controller: _gridScrollControllerVertical,
                  itemBuilder: (context, index) {
                    final item = displayedMods[index];

                    if (item is WispGridGroupRowView) {
                      return Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: SizedBox(width: totalRowWidth, child: item),
                          ),
                          Spacer(),
                        ],
                      );
                    }

                    try {
                      return item;
                    } catch (e) {
                      Fimber.v(() => 'Error in WispGrid: $e');
                      return Text("Incoherent screaming");
                    }
                  }),
            ),
          ),
        ),
      ),
    );
  }

  // ContextMenuRegion buildWrappedRow(T item, BuildContext context) {
  //   // Disabling the click for mods panel functionality because
  //   // having the double-click introduces a delay on all single-clicks in the row,
  //   // and single-clicking for the side panel is too annoying.
  //   // TODO see if there's a way to stop the onDoubleTap from delaying single-clicks
  //   // on the version dropdown popup.
  //   final doubleClickForModsPanel = true;
  //   // ref.watch(appSettings.select((s) => s.doubleClickForModsPanel));
  //   final mod = item;
  //
  //   return ContextMenuRegion(
  //     contextMenu: _checkedItemIds.length > 1
  //         ? buildModBulkActionContextMenu(
  //             (_lastDisplayedItems as List<Mod>)
  //                 .where((mod) => _checkedItemIds.contains(mod.id))
  //                 .toList(),
  //             ref,
  //             context)
  //         : buildModContextMenu(mod, ref, context, showSwapToVersion: true),
  //     child: WispGridRowView<T>(
  //       mod: item,
  //       columns: widget.columns,
  //       rowBuilder: widget.rowBuilder,
  //       onTapped: () {
  //         if (HardwareKeyboard.instance.isShiftPressed) {
  //           _onRowCheck(
  //             modId: mod.id,
  //             shiftPressed: true,
  //             ctrlPressed: false,
  //           );
  //         } else if (HardwareKeyboard.instance.isControlPressed) {
  //           _onRowCheck(
  //             modId: mod.id,
  //             shiftPressed: false,
  //             ctrlPressed: true,
  //           );
  //         } else {
  //           if (!doubleClickForModsPanel || widget.selectedMod != null) {
  //             widget.onRowSelected(mod);
  //           }
  //           _onRowCheck(
  //             modId: mod.id,
  //             shiftPressed: false,
  //             ctrlPressed: false,
  //           );
  //         }
  //       },
  //       onDoubleTapped: () {
  //         if (doubleClickForModsPanel) {
  //           widget.onRowSelected(mod);
  //         }
  //       },
  //       // onModRowSelected: widget.onModRowSelected,
  //       isRowChecked: _checkedItemIds.contains(mod.id),
  //     ),
  //   );
  // }

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

// Comparable? _getSortValueForMod(
//     Mod mod,
//     ModMetadata? metadata,
//     ModGridSortField sortField,
//     AsyncValue<VramEstimatorState> vramEstimatorStateProvider) {
//   return switch (sortField) {
//     ModGridSortField.icons =>
//       mod.findFirstEnabledOrHighestVersion?.modInfo.isUtility == true
//           ? "utility"
//           : mod.findFirstEnabledOrHighestVersion?.modInfo.isTotalConversion ==
//                   true
//               ? "total conversion"
//               : "other",
//     ModGridSortField.name =>
//       mod.findFirstEnabledOrHighestVersion?.modInfo.nameOrId,
//     ModGridSortField.enabledState => mod.isEnabledOnUi.toComparable(),
//     ModGridSortField.author =>
//       mod.findFirstEnabledOrHighestVersion?.modInfo.author?.toLowerCase() ?? "",
//     ModGridSortField.version =>
//       mod.findFirstEnabledOrHighestVersion?.modInfo.version,
//     ModGridSortField.vramImpact => vramEstimatorStateProvider
//             .valueOrNull
//             ?.modVramInfo[mod.findHighestEnabledVersion?.smolId]
//             ?.maxPossibleBytesForMod ??
//         0,
//     ModGridSortField.gameVersion =>
//       mod.findFirstEnabledOrHighestVersion?.modInfo.gameVersion,
//     ModGridSortField.firstSeen => metadata?.firstSeen ?? 0,
//     ModGridSortField.lastEnabled => metadata?.lastEnabled ?? 0,
//   };
// }
