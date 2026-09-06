import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/thirdparty/dartx/function.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/hoverable_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/multi_split_mixin_view.dart';

import 'wisp_grid.dart';

class WispGridHeader {
  final String? sortField;
  final Builder child;

  const WispGridHeader({this.sortField, required this.child});
}

typedef WispGridHeaderBuilder = WispGridHeader Function(
  MapEntry<ModGridHeader, WispGridColumnState> columnSetting,
  bool isHovering,
);

class WispGridHeaderRowView extends ConsumerStatefulWidget {
  final WispGridState gridState;
  final Function(WispGridState? Function(WispGridState)) updateGridState;
  final List<WispGridColumn> columns;
  final List<WispGridGroup> groups;
  final String? defaultGridSort;
  final double leadingItemWidth;

  /// Per-column additional context menu entries, keyed by column key.
  final Map<String, List<ContextMenuEntry>> perColumnContextMenuEntries;

  const WispGridHeaderRowView({
    super.key,
    required this.gridState,
    required this.updateGridState,
    required this.columns,
    required this.groups,
    this.defaultGridSort,
    this.leadingItemWidth = 0,
    this.perColumnContextMenuEntries = const {},
  });

  @override
  ConsumerState createState() => _WispGridHeaderRowViewState();
}

const _opacity = 0.5;

class _WispGridHeaderRowViewState extends ConsumerState<WispGridHeaderRowView>
    with MultiSplitViewMixin {
  bool _isResizing = false;

  List<WispGridColumn> get columns => widget.columns;

  Function(WispGridState? Function(WispGridState)) get updateGridState =>
      widget.updateGridState;

  WispGridState get gridState => widget.gridState;

  @override
  List<Area> get areas =>
      gridState
          .sortedVisibleColumns(columns)
          .map(
            (entry) => Area(id: entry.key.toString(), size: entry.value.width),
          )
          .toList()
        ..add(Area(id: 'endspace'));

  @override
  void initState() {
    super.initState();
    multiSplitController = MultiSplitViewController(areas: areas);
    multiSplitController.addListener(onMultiSplitViewChanged);
  }

  @override
  void didUpdateWidget(covariant WispGridHeaderRowView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update areas if the configuration has changed
    final updatedAreas = areas;
    final lengthChanged =
        multiSplitController.areas.length != updatedAreas.length;
    final sizesChanged = !listEquals(
      multiSplitController.areas.map((a) => a.size).toList(),
      updatedAreas.map((a) => a.size).toList(),
    );

    if (lengthChanged) {
      // Visible-column count changed — sync immediately so build doesn't
      // run with stale areas and overflow / mis-render the header row.
      multiSplitController.areas = updatedAreas;
    } else if (sizesChanged) {
      // Just resizing — defer to avoid fighting the user's active drag.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        multiSplitController.areas = updatedAreas;
      });
    }
  }

  @override
  void onMultiSplitViewChanged() {
    super.onMultiSplitViewChanged();

    if (!_isResizing) {
      _isResizing = true;
      return;
    }

    // Defer state update until resizing finishes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isResizing = false;
      updateGridState((WispGridState state) {
        var sortedColumns = state.sortedColumns(columns);
        final columnSettings = Map.fromEntries(sortedColumns);
        for (final area in multiSplitController.areas) {
          final header = columns.firstWhereOrNull(
            (header) => header.key.toString() == area.id,
          );
          if (header == null) continue;
          columnSettings[header.key] = columnSettings[header.key]!.copyWith(
            width: area.size,
          );
        }

        return state.copyWith(columnsState: columnSettings);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContextMenuRegion(
      contextMenu: buildHeaderContextMenu(gridState),
      child: HoverableWidget(
        child: Builder(
          builder: (context) {
            final isHovering = HoverData.of(context)?.isHovering ?? false;
            return MovingTooltipWidget.text(
              message:
                  'Click to sort. Drag the edges to resize.\n'
                  'Right-click for grouping and column options.',
              child: MultiSplitViewTheme(
                data: MultiSplitViewThemeData(
                  dividerThickness: WispGrid.gridRowSpacing,
                  dividerPainter: DividerPainters.grooved1(
                    color: isHovering
                        ? theme.colorScheme.onSurface.withOpacity(_opacity)
                        : Colors.transparent,
                    highlightedColor: theme.colorScheme.onSurface,
                    size: 20,
                    animationDuration: const Duration(milliseconds: 100),
                    highlightedSize: 20,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left:
                        WispGrid.gridRowSpacing * 2 +
                        (widget.leadingItemWidth > 0
                            ? widget.leadingItemWidth + WispGrid.gridRowSpacing
                            : 0),
                    right: WispGrid.gridRowSpacing * 2,
                  ),
                  // idk why multiplying by 2 works
                  child: MultiSplitView(
                    controller: multiSplitController,
                    axis: Axis.horizontal,
                    builder: (context, area) {
                      if (area.id == 'endspace') return Container();

                      var sortedVisibleColumns = gridState.sortedVisibleColumns(
                        widget.columns,
                      );
                      final columnSetting = sortedVisibleColumns.elementAt(
                        min(area.index, sortedVisibleColumns.length - 1),
                      );

                      final column = widget.columns.firstWhere(
                        (column) => column.key == columnSetting.key,
                      );

                      Widget header = DraggableHeader(
                        columns: columns,
                        showDragHandle: isHovering,
                        header: columnSetting.key,
                        gridState: gridState,
                        updateGridState: updateGridState,
                        child: buildWispGridHeaderCellContent(
                          context,
                          column,
                          isHovering: isHovering,
                          gridState: gridState,
                          updateGridState: updateGridState,
                          defaultGridSort: widget.defaultGridSort,
                        ),
                      );

                      return ContextMenuRegion(
                        contextMenu: buildWispGridColumnContextMenu(
                          gridState: gridState,
                          columns: columns,
                          groups: widget.groups,
                          updateGridState: updateGridState,
                          columnKey: column.key,
                          extraEntries:
                              widget.perColumnContextMenuEntries[column.key],
                        ),
                        child: header,
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  ContextMenu buildHeaderContextMenu(
    WispGridState gridState, {
    String? columnKey,
  }) => buildWispGridHeaderContextMenu(
    gridState: gridState,
    columns: columns,
    groups: widget.groups,
    updateGridState: updateGridState,
    columnKey: columnKey,
  );
}

/// One header cell's contents: the column's own header widget, made sortable
/// and given the header text style. Shared by the scrolling header and the
/// frozen copy drawn over it.
Widget buildWispGridHeaderCellContent(
  BuildContext context,
  WispGridColumn column, {
  required bool isHovering,
  required WispGridState gridState,
  required Function(WispGridState? Function(WispGridState)) updateGridState,
  required String? defaultGridSort,
}) {
  Widget child =
      column.headerCellBuilder?.invoke(
        HeaderBuilderModifiers(isHovering: isHovering),
      ) ??
      Text(column.name);

  if (column.isSortable) {
    child = SortableHeader(
      columnSortField: column.key,
      defaultGridSort: defaultGridSort,
      gridState: gridState,
      updateGridState: updateGridState,
      child: child,
    );
  }

  return DefaultTextStyle.merge(
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontWeight: FontWeight.bold),
    child: child,
  );
}

/// The header menu for one column: the shared header menu plus whatever extra
/// entries the page supplies for that column.
ContextMenu buildWispGridColumnContextMenu({
  required WispGridState gridState,
  required List<WispGridColumn> columns,
  required List<WispGridGroup> groups,
  required Function(WispGridState? Function(WispGridState)) updateGridState,
  required String columnKey,
  List<ContextMenuEntry>? extraEntries,
}) {
  final shared = buildWispGridHeaderContextMenu(
    gridState: gridState,
    columns: columns,
    groups: groups,
    updateGridState: updateGridState,
    columnKey: columnKey,
  );
  if (extraEntries == null || extraEntries.isEmpty) return shared;
  return ContextMenu(
    entries: [...shared.entries, const MenuDivider(), ...extraEntries],
  );
}

/// The frozen columns' headers, drawn again so they stay in view while the
/// rest of the header scrolls sideways. Sorting and the right-click menu work
/// here; resizing and reordering are only offered on the scrolling header.
class WispGridFrozenHeaderRowView extends StatelessWidget {
  final WispGridState gridState;
  final Function(WispGridState? Function(WispGridState)) updateGridState;
  final List<WispGridColumn> columns;
  final List<WispGridGroup> groups;
  final String? defaultGridSort;
  final double leadingItemWidth;
  final Map<String, List<ContextMenuEntry>> perColumnContextMenuEntries;

  const WispGridFrozenHeaderRowView({
    super.key,
    required this.gridState,
    required this.updateGridState,
    required this.columns,
    required this.groups,
    this.defaultGridSort,
    this.leadingItemWidth = 0,
    this.perColumnContextMenuEntries = const {},
  });

  @override
  Widget build(BuildContext context) {
    final frozen = gridState.frozenVisibleColumns(columns);

    return HoverableWidget(
      child: Builder(
        builder: (context) {
          final isHovering = HoverData.of(context)?.isHovering ?? false;

          return Padding(
            // Matches the scrolling header's left padding, so the frozen
            // headers land on the same pixels as the ones underneath.
            padding: EdgeInsets.only(
              left:
                  WispGrid.gridRowSpacing * 2 +
                  (leadingItemWidth > 0
                      ? leadingItemWidth + WispGrid.gridRowSpacing
                      : 0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: WispGrid.gridRowSpacing,
              children: frozen.map((entry) {
                final column = columns.firstWhereOrNull(
                  (col) => col.key == entry.key,
                );
                if (column == null) {
                  return SizedBox(width: entry.value.width);
                }
                return SizedBox(
                  width: entry.value.width,
                  child: ContextMenuRegion(
                    contextMenu: buildWispGridColumnContextMenu(
                      gridState: gridState,
                      columns: columns,
                      groups: groups,
                      updateGridState: updateGridState,
                      columnKey: column.key,
                      extraEntries: perColumnContextMenuEntries[column.key],
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: buildWispGridHeaderCellContent(
                        context,
                        column,
                        isHovering: isHovering,
                        gridState: gridState,
                        updateGridState: updateGridState,
                        defaultGridSort: defaultGridSort,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

/// The grid header's right-click menu. When [columnKey] names the column the
/// user right-clicked, the menu also offers to freeze or unfreeze it.
ContextMenu buildWispGridHeaderContextMenu({
  required WispGridState gridState,
  required List<WispGridColumn> columns,
  required List<WispGridGroup> groups,
  required Function(WispGridState? Function(WispGridState)) updateGridState,
  String? columnKey,
}) {
  final groupingSetting = gridState.groupingSetting;
  final currentPrimaryKey = groupingSetting?.currentGroupedByKey;
  final currentSecondaryKey = groupingSetting?.secondaryGroupedByKey;
  // The "no grouping" entry is itself a group named "None", so leave it out
  // here — the menu already has its own "None" to clear the second level.
  final thenByCandidates = groups
      .where((g) => g.key != currentPrimaryKey && g.isGroupVisible)
      .toList();
  final showThenBy = groups.length > 1 && thenByCandidates.isNotEmpty;
  var sortedColumns = gridState.sortedColumns(columns);
  final clickedColumn = columnKey == null
      ? null
      : columns.firstWhereOrNull((col) => col.key == columnKey);
  final isClickedColumnFrozen =
      columnKey != null &&
      (sortedColumns
              .firstWhereOrNull((entry) => entry.key == columnKey)
              ?.value
              .isFrozen ??
          false);
  return ContextMenu(
    entries: [
      if (clickedColumn != null)
        MenuItem(
          label: isClickedColumnFrozen
              ? 'Unfreeze this column'
              : 'Freeze this column',
          icon: isClickedColumnFrozen ? Icons.lock_open : Icons.lock,
          onSelected: () {
            updateGridState((WispGridState state) {
              final columnSettings = state.sortedColumns(columns).toMap();
              final setting = columnSettings[columnKey]!;
              columnSettings[columnKey!] = setting.copyWith(
                isFrozen: !setting.isFrozen,
              );
              return state.copyWith(columnsState: columnSettings);
            });
          },
        ),
      if (groups.length > 1)
        MenuItem.submenu(
          label: "Group By",
          icon: Icons.horizontal_split,
          items: groups
              .map(
                (group) => MenuItem(
                  label: group.displayName,
                  icon: groupingSetting?.currentGroupedByKey == group.key
                      ? Icons.check
                      : null,
                  onSelected: () {
                    updateGridState((WispGridState state) {
                      final existing =
                          state.groupingSetting ??
                          GroupingSetting(currentGroupedByKey: group.key);
                      final clearSecondary =
                          existing.secondaryGroupedByKey == group.key;
                      return state.copyWith(
                        groupingSetting: existing.copyWith(
                          currentGroupedByKey: group.key,
                          secondaryGroupedByKey: clearSecondary
                              ? null
                              : existing.secondaryGroupedByKey,
                        ),
                      );
                    });
                  },
                ),
              )
              .toList(),
        ),
      if (showThenBy)
        MenuItem.submenu(
          label: "Then By",
          icon: Icons.subdirectory_arrow_right,
          items: [
            MenuItem(
              label: 'None',
              icon: currentSecondaryKey == null ? Icons.check : null,
              onSelected: () {
                updateGridState((WispGridState state) {
                  final existing = state.groupingSetting;
                  if (existing == null) return state;
                  return state.copyWith(
                    groupingSetting: existing.copyWith(
                      secondaryGroupedByKey: null,
                    ),
                  );
                });
              },
            ),
            ...thenByCandidates.map(
              (group) => MenuItem(
                label: group.displayName,
                icon: currentSecondaryKey == group.key ? Icons.check : null,
                onSelected: () {
                  updateGridState((WispGridState state) {
                    final existing = state.groupingSetting;
                    if (existing == null) return state;
                    return state.copyWith(
                      groupingSetting: existing.copyWith(
                        secondaryGroupedByKey: group.key,
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      MenuDivider(),
      MenuItem(
        label: 'Reset grid layout',
        icon: Icons.settings_backup_restore,
        onSelected: () {
          updateGridState((WispGridState state) => null);
        },
      ),
      MenuDivider(),
      MenuHeader(text: "Hide/Show Columns", disableUppercase: true),
      MenuItem(
        label: 'Show All',
        icon: Icons.visibility,
        onSelected: () {
          updateGridState((WispGridState state) {
            final columnSettings = state.sortedColumns(columns).toMap();
            for (final key in columnSettings.keys.toList()) {
              columnSettings[key] = columnSettings[key]!.copyWith(
                isVisible: true,
              );
            }
            return state.copyWith(columnsState: columnSettings);
          });
        },
      ),
      MenuItem(
        label: 'Hide All',
        icon: Icons.visibility_off,
        onSelected: () {
          updateGridState((WispGridState state) {
            final sorted = state.sortedColumns(columns).toList();
            final columnSettings = Map.fromEntries(sorted);
            // Keep the first column visible — the header is the only place
            // to reach the column-visibility menu, so we must never end up
            // with zero visible columns.
            final keepVisibleKey = sorted.firstOrNull?.key;
            for (final key in columnSettings.keys.toList()) {
              columnSettings[key] = columnSettings[key]!.copyWith(
                isVisible: key == keepVisibleKey,
              );
            }
            return state.copyWith(columnsState: columnSettings);
          });
        },
      ),
      MenuDivider(),
      // Visibility toggles
      ...sortedColumns.map((columnSetting) {
        final header = columnSetting.key;
        final column = columns.firstWhereOrNull((col) => col.key == header);
        final isVisible = columnSetting.value.isVisible;
        // Disable hiding the last remaining visible column.
        final visibleCount = sortedColumns
            .where((c) => c.value.isVisible)
            .length;
        final isLastVisible = isVisible && visibleCount <= 1;
        return CheckableMenuItem(
          label:
              column?.name.nullIfEmpty() ?? column?.key.toTitleCase() ?? "???",
          isChecked: isVisible,
          checkedIcon: Icons.visibility,
          uncheckedIcon: Icons.visibility_off,
          uncheckedIconOpacity: 0.4,
          enabled: !isLastVisible,
          onSelected: () {
            updateGridState((WispGridState state) {
              final columnSettings = state.sortedColumns(columns).toMap();
              final headerSetting = columnSettings[header]!;
              columnSettings[header] = headerSetting.copyWith(
                isVisible: !headerSetting.isVisible,
              );

              return state.copyWith(columnsState: columnSettings);
            });
          },
        );
      }),
    ],
  );
}

class DraggableHeader extends ConsumerWidget {
  final Widget child;
  final String header;
  final bool showDragHandle;
  final WispGridState gridState;
  final Function(WispGridState? Function(WispGridState)) updateGridState;
  final List<WispGridColumn> columns;

  const DraggableHeader({
    super.key,
    required this.child,
    required this.header,
    required this.showDragHandle,
    required this.gridState,
    required this.updateGridState,
    required this.columns,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var sortedVisibleColumns = gridState.sortedVisibleColumns(columns);
    final isLast = sortedVisibleColumns.lastOrNull?.key == header;

    Widget draggableChild({required bool isHovered}) {
      return Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          child,
          if (isHovered) Container(color: Colors.black.withOpacity(0.5)),
          Positioned(
            right: isLast ? 12 : 4,
            child: Opacity(
              opacity: showDragHandle ? 1 : 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: const Icon(Icons.drag_indicator, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return Draggable(
      data: header,
      feedback: Material(
        child: Theme(data: Theme.of(context), child: child),
      ),
      axis: Axis.horizontal,
      dragAnchorStrategy: (draggable, context, position) => const Offset(16, 8),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: draggableChild(isHovered: false),
      ),
      child: DragTarget(
        builder: (context, candidateData, rejectedData) {
          final isHovered = candidateData.isNotEmpty;
          return draggableChild(isHovered: isHovered);
        },
        onWillAcceptWithDetails: (data) => data.data != header,
        onAcceptWithDetails: (data) {
          updateGridState((WispGridState state) {
            final Map<String, WispGridColumnState> columnSettings = gridState
                .sortedVisibleColumns(columns)
                .toMap();
            final draggedHeader = data.data;
            final draggedSetting = columnSettings.remove(draggedHeader)!;

            final sorted = columnSettings.entries.toList()
              ..sort((a, b) => a.value.position.compareTo(b.value.position));

            final targetIndex = columnSettings[header]!.position.clamp(
              0,
              sorted.length,
            );
            sorted.insert(
              targetIndex,
              MapEntry(draggedHeader as String, draggedSetting),
            );

            return state.copyWith(
              columnsState: {
                for (int i = 0; i < sorted.length; i++)
                  sorted[i].key: sorted[i].value.copyWith(position: i),
              },
            );
          });
        },
      ),
    );
  }
}

class SortableHeader extends ConsumerStatefulWidget {
  final String columnSortField;
  final String? defaultGridSort;
  final Function(WispGridState Function(WispGridState)) updateGridState;
  final WispGridState gridState;
  final Widget child;

  const SortableHeader({
    super.key,
    required this.columnSortField,
    this.defaultGridSort,
    required this.updateGridState,
    required this.gridState,
    required this.child,
  });

  @override
  ConsumerState createState() => _SortableHeaderState();
}

class _SortableHeaderState extends ConsumerState<SortableHeader> {
  @override
  Widget build(BuildContext context) {
    final gridState = widget.gridState;
    final isSortDescending = gridState.isSortDescending;
    final isActive = gridState.sortedColumnKey != null
        ? gridState.sortedColumnKey == widget.columnSortField
        : widget.defaultGridSort == widget.columnSortField;

    return InkWell(
      onTap: () {
        widget.updateGridState((WispGridState state) {
          if (state.sortedColumnKey == widget.columnSortField) {
            // Currently sorting by this column - toggle sort direction
            return state.copyWith(isSortDescending: !state.isSortDescending);
          } else {
            // Switching to sort by this column - don't toggle sort direction.
            return state.copyWith(
              sortedColumnKey: widget.columnSortField.toString(),
            );
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.child,
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                isSortDescending ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
