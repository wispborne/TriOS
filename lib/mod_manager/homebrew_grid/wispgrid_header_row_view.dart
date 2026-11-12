import 'dart:math';

import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_column_fit.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/thirdparty/dartx/function.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/hoverable_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';

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

class WispGridHeaderRowView extends StatelessWidget {
  final WispGridState gridState;
  final Function(WispGridState? Function(WispGridState)) updateGridState;
  final List<WispGridColumn> columns;
  final List<WispGridGroup> groups;
  final String? defaultGridSort;

  /// How wide each column needs to be to show all of its text.
  final Map<String, double> contentWidths;

  /// Per-column additional context menu entries, keyed by column key.
  final Map<String, List<ContextMenuEntry>> perColumnContextMenuEntries;

  const WispGridHeaderRowView({
    super.key,
    required this.gridState,
    required this.updateGridState,
    required this.columns,
    required this.groups,
    required this.contentWidths,
    this.defaultGridSort,
    this.perColumnContextMenuEntries = const {},
  });

  void _setColumnWidth(String columnKey, double width) => updateGridState(
    (state) => setColumnWidths(state, columns, {columnKey: width}),
  );

  @override
  Widget build(BuildContext context) {
    return ContextMenuRegion(
      contextMenu: buildWispGridHeaderContextMenu(
        gridState: gridState,
        columns: columns,
        groups: groups,
        updateGridState: updateGridState,
        contentWidths: contentWidths,
      ),
      child: HoverableWidget(
        child: Builder(
          builder: (context) {
            final isHovering = HoverData.of(context)?.isHovering ?? false;
            return MovingTooltipWidget.text(
              message:
                  'Click to sort. Drag\'n\'drop to reorder. Drag an edge to resize. Double-click an edge '
                  'to auto-size.\n'
                  'Right-click for more options.',
              child: Padding(
                padding: const .symmetric(
                  horizontal: WispGrid.gridRowSpacing * 2,
                ),
                child: Row(
                  crossAxisAlignment: .stretch,
                  children: [
                    for (final entry in gridState.sortedVisibleColumns(
                      columns,
                    )) ...[
                      SizedBox(
                        width: entry.value.width,
                        child: _buildHeaderCell(context, entry, isHovering),
                      ),
                      _ColumnResizeHandle(
                        key: wispGridResizeHandleKey(entry.key),
                        columnWidth: entry.value.width,
                        isHeaderHovered: isHovering,
                        onWidthChanged: (width) =>
                            _setColumnWidth(entry.key, width),
                        onFitToContents: switch (contentWidths[entry.key]) {
                          final contentWidth? => () => _setColumnWidth(
                            entry.key,
                            contentWidth,
                          ),
                          null => null,
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    BuildContext context,
    MapEntry<String, WispGridColumnState> columnSetting,
    bool isHovering,
  ) {
    final column = columns.firstWhere(
      (column) => column.key == columnSetting.key,
    );

    return ContextMenuRegion(
      contextMenu: buildWispGridColumnContextMenu(
        gridState: gridState,
        columns: columns,
        groups: groups,
        updateGridState: updateGridState,
        columnKey: column.key,
        contentWidths: contentWidths,
        extraEntries: perColumnContextMenuEntries[column.key],
      ),
      child: DraggableHeader(
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
          defaultGridSort: defaultGridSort,
        ),
      ),
    );
  }
}

/// Identifies a column's drag strip.
ValueKey<String> wispGridResizeHandleKey(String columnKey) =>
    ValueKey('wispGridResizeHandle-$columnKey');

/// The strip on a column's right edge. Dragging it changes only that column.
/// The columns after it move over, as in a spreadsheet.
class _ColumnResizeHandle extends StatefulWidget {
  final double columnWidth;
  final bool isHeaderHovered;
  final ValueChanged<double> onWidthChanged;

  /// Null for columns with no text to fit to.
  final VoidCallback? onFitToContents;

  const _ColumnResizeHandle({
    super.key,
    required this.columnWidth,
    required this.isHeaderHovered,
    required this.onWidthChanged,
    required this.onFitToContents,
  });

  @override
  State<_ColumnResizeHandle> createState() => _ColumnResizeHandleState();
}

class _ColumnResizeHandleState extends State<_ColumnResizeHandle> {
  bool _isDragging = false;

  /// Follows the mouse and can go below the minimum, so the column only starts
  /// growing again once the mouse is back at its edge.
  double _dragWidth = 0;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: .opaque,
        onDoubleTap: widget.onFitToContents,
        // Count movement from the moment of the press, so the edge stays
        // under the mouse.
        dragStartBehavior: .down,
        onHorizontalDragStart: (_) => setState(() {
          _isDragging = true;
          _dragWidth = widget.columnWidth;
        }),
        onHorizontalDragUpdate: (details) {
          _dragWidth += details.primaryDelta!;
          widget.onWidthChanged(max(_dragWidth, WispGrid.minColumnWidth));
        },
        onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
        onHorizontalDragCancel: () => setState(() => _isDragging = false),
        child: SizedBox(
          width: WispGrid.gridRowSpacing,
          child: Center(
            child: Container(
              width: 2,
              height: 20,
              color: _isDragging
                  ? color
                  : widget.isHeaderHovered
                  ? color.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
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
  required Map<String, double> contentWidths,
  List<ContextMenuEntry>? extraEntries,
}) {
  final shared = buildWispGridHeaderContextMenu(
    gridState: gridState,
    columns: columns,
    groups: groups,
    updateGridState: updateGridState,
    columnKey: columnKey,
    contentWidths: contentWidths,
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
  final Map<String, double> contentWidths;
  final Map<String, List<ContextMenuEntry>> perColumnContextMenuEntries;

  const WispGridFrozenHeaderRowView({
    super.key,
    required this.gridState,
    required this.updateGridState,
    required this.columns,
    required this.groups,
    required this.contentWidths,
    this.defaultGridSort,
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
            padding: const EdgeInsets.only(left: WispGrid.gridRowSpacing * 2),
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
                      contentWidths: contentWidths,
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
  required Map<String, double> contentWidths,
  String? columnKey,
}) {
  final clickedColumnContentWidth = contentWidths[columnKey];
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
      MenuItem.submenu(
        label: 'Column Width',
        icon: Icons.width_normal,
        items: [
          if (clickedColumnContentWidth != null)
            MenuItem(
              label: 'Auto-size',
              icon: Icons.width_normal,
              onSelected: () {
                updateGridState(
                  (state) => setColumnWidths(state, columns, {
                    columnKey!: clickedColumnContentWidth,
                  }),
                );
              },
            ),
          if (contentWidths.isNotEmpty)
            MenuItem(
              label: 'Auto-size all',
              icon: Icons.width_full,
              onSelected: () {
                updateGridState(
                  (state) => setColumnWidths(state, columns, contentWidths),
                );
              },
            ),
          if (clickedColumn != null)
            MenuItem(
              label: 'Reset to default',
              icon: Icons.settings_backup_restore,
              onSelected: () {
                updateGridState(
                  (state) => resetColumnWidths(state, columns, [columnKey!]),
                );
              },
            ),
          MenuItem(
            label: 'Reset all to defaults',
            icon: Icons.settings_backup_restore,
            onSelected: () {
              updateGridState(
                (state) => resetColumnWidths(
                  state,
                  columns,
                  columns.map((column) => column.key),
                ),
              );
            },
          ),
        ],
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
            // Must be the saved state. The widget's gridState holds automatic
            // widths, which would be saved as if the user had set them.
            final Map<String, WispGridColumnState> columnSettings = state
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
