import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/thirdparty/dartx/function.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/widgets/MultiSplitViewMixin.dart';
import 'package:trios/widgets/hoverable_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';

import 'wisp_grid.dart';

class WispGridHeader {
  final String? sortField;
  final Builder child;

  const WispGridHeader({
    this.sortField,
    required this.child,
  });
}

typedef WispGridHeaderBuilder = WispGridHeader Function(
  MapEntry<ModGridHeader, WispGridColumnState> columnSetting,
  bool isHovering,
);

class WispGridHeaderRowView extends ConsumerStatefulWidget {
  final WispGridState gridState;
  final Function(WispGridState Function(WispGridState)) updateGridState;
  final List<WispGridColumn> columns;
  final List<WispGridGroup> groups;

  const WispGridHeaderRowView({
    super.key,
    required this.gridState,
    required this.updateGridState,
    required this.columns,
    required this.groups,
  });

  @override
  ConsumerState createState() => _WispGridHeaderRowViewState();
}

const _opacity = 0.5;

class _WispGridHeaderRowViewState extends ConsumerState<WispGridHeaderRowView>
    with MultiSplitViewMixin {
  bool _isResizing = false;

  List<WispGridColumn> get columns => widget.columns;

  Function(WispGridState Function(WispGridState)) get updateGridState =>
      widget.updateGridState;

  WispGridState get gridState => widget.gridState;

  @override
  List<Area> get areas => gridState
      .sortedVisibleColumns(columns)
      .map((entry) => Area(id: entry.key.toString(), size: entry.value.width))
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
    if (multiSplitController.areas.length != updatedAreas.length ||
        !listEquals(multiSplitController.areas.map((a) => a.size).toList(),
            updatedAreas.map((a) => a.size).toList())) {
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
          final header = columns
              .firstWhereOrNull((header) => header.key.toString() == area.id);
          if (header == null) continue;
          columnSettings[header.key] =
              columnSettings[header.key]!.copyWith(width: area.size);
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
      child: HoverableWidget(child: Builder(builder: (context) {
        final isHovering = HoverData.of(context)?.isHovering ?? false;
        return MultiSplitViewTheme(
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
            padding: const EdgeInsets.symmetric(
                horizontal: WispGrid.gridRowSpacing * 2),
            // idk why multiplying by 2 works
            child: MultiSplitView(
                controller: multiSplitController,
                axis: Axis.horizontal,
                builder: (context, area) {
                  if (area.id == 'endspace') return Container();

                  var sortedVisibleColumns =
                      gridState.sortedVisibleColumns(widget.columns);
                  final columnSetting = sortedVisibleColumns.elementAt(
                      min(area.index, sortedVisibleColumns.length - 1));

                  final column = widget.columns
                      .firstWhere((column) => column.key == columnSetting.key);
                  Widget headerWidget =
                      column.headerCellBuilder?.invoke(HeaderBuilderModifiers(
                    isHovering: isHovering,
                  )) ?? Text(column.name);
                  Widget child = headerWidget;

                  if (column.isSortable) {
                    child = SortableHeader(
                      columnSortField: column.key,
                      gridState: gridState,
                      updateGridState: updateGridState,
                      child: child,
                    );
                  }

                  final headerTextStyle = Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold);

                  return DraggableHeader(
                    columns: columns,
                    showDragHandle: isHovering,
                    header: columnSetting.key,
                    gridState: gridState,
                    updateGridState: updateGridState,
                    child: DefaultTextStyle.merge(
                        style: headerTextStyle, child: child),
                  );
                }),
          ),
        );
      })),
    );
  }

  ContextMenu buildHeaderContextMenu(WispGridState gridState) {
    final groupingSetting = gridState.groupingSetting;
    return ContextMenu(
      entries: [
        MenuItem(
            label: 'Reset grid layout',
            icon: Icons.settings_backup_restore,
            onSelected: () {
              updateGridState((WispGridState state) => state.empty());
            }),
        MenuItem.submenu(
          label: "Group By",
          icon: Icons.horizontal_split,
          items: widget.groups
              .map((group) => MenuItem(
                    label: group.displayName,
                    icon: groupingSetting?.currentGroupedByKey == group.key
                        ? Icons.check
                        : null,
                    onSelected: () {
                      updateGridState((WispGridState state) => state.copyWith(
                          groupingSetting:
                              GroupingSetting(currentGroupedByKey: group.key)));
                    },
                  ))
              .toList(),

          // [
          //   MenuItem(
          //     label: "Enabled",
          //     icon: groupingSetting.currentGroupedByKey ==
          //             ModGridGroupEnum.enabledState
          //         ? Icons.check
          //         : null,
          //     onSelected: () {
          //       updateGridState((WispGridState state) => state.copyWith(
          //           groupingSetting: GroupingSetting(
          //               currentGroupedByKey: ModGridGroupEnum.enabledState)));
          //     },
          //   ),
          //   MenuItem(
          //     label: "Mod Type",
          //     icon:
          //         groupingSetting.currentGroupedByKey == ModGridGroupEnum.modType
          //             ? Icons.check
          //             : null,
          //     onSelected: () {
          //       updateGridState((WispGridState state) => state.copyWith(
          //           groupingSetting: GroupingSetting(
          //               currentGroupedByKey: ModGridGroupEnum.modType)));
          //     },
          //   ),
          //   MenuItem(
          //       label: "Game Version",
          //       icon: groupingSetting.currentGroupedByKey ==
          //               ModGridGroupEnum.gameVersion
          //           ? Icons.check
          //           : null,
          //       onSelected: () {
          //         updateGridState((WispGridState state) => state.copyWith(
          //             groupingSetting: GroupingSetting(
          //                 currentGroupedByKey: ModGridGroupEnum.gameVersion)));
          //       }),
          //   MenuItem(
          //     label: "Author",
          //     icon: groupingSetting.currentGroupedByKey == ModGridGroupEnum.author
          //         ? Icons.check
          //         : null,
          //     onSelected: () {
          //       updateGridState((WispGridState state) => state.copyWith(
          //           groupingSetting: GroupingSetting(
          //               currentGroupedByKey: ModGridGroupEnum.author)));
          //     },
          //   ),
          // ]
        ),
        MenuDivider(),
        MenuHeader(text: "Hide/Show Columns", disableUppercase: true),
        // Visibility toggles
        ...gridState.columnsState.entries.map((columnSetting) {
          final header = columnSetting.key;
          final column = columns.firstWhereOrNull((col) => col.key == header);
          final isVisible = gridState.columnsState[header]?.isVisible ?? true;
          return MenuItem(
            label: column?.name ?? "???",
            icon: isVisible ? Icons.visibility : Icons.visibility_off,
            onSelected: () {
              updateGridState((WispGridState state) {
                final columnSettings = state.columnsState;
                final headerSetting = columnSettings[header]!;
                columnSettings[header] =
                    headerSetting.copyWith(isVisible: !headerSetting.isVisible);

                return state.copyWith(columnsState: columnSettings);
              });
            },
          );
        })
      ],
    );
  }
}

class DraggableHeader extends ConsumerWidget {
  final Widget child;
  final String header;
  final bool showDragHandle;
  final WispGridState gridState;
  final Function(WispGridState Function(WispGridState)) updateGridState;
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
    final isFirst = sortedVisibleColumns.firstOrNull?.key == header;
    final isLast = sortedVisibleColumns.lastOrNull?.key == header;

    Widget draggableChild(bool isHovered) {
      return Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          child,
          if (isHovered) Container(color: Colors.black.withOpacity(0.5)),
          if (isFirst)
            MovingTooltipWidget.text(
              message: 'Reset grid layout',
              child: Opacity(
                opacity: showDragHandle ? 1 : 0,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  style: ElevatedButton.styleFrom(shape: const CircleBorder()),
                  onPressed: () {
                    updateGridState((WispGridState state) => state.empty());
                  },
                  icon: const Icon(Icons.settings_backup_restore),
                ),
              ),
            )
          else
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
      feedback: const Icon(Icons.drag_indicator, size: 16),
      axis: Axis.horizontal,
      dragAnchorStrategy: (draggable, context, position) => const Offset(16, 8),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: draggableChild(false),
      ),
      child: DragTarget(
        builder: (context, candidateData, rejectedData) {
          final isHovered = candidateData.isNotEmpty;
          return draggableChild(isHovered);
        },
        onWillAcceptWithDetails: (data) => data.data != header,
        onAcceptWithDetails: (data) {
          updateGridState((WispGridState state) {
            final columnSettings = state.columnsState;
            final draggedHeader = data.data;
            final draggedSetting = columnSettings.remove(draggedHeader)!;

            final sorted = columnSettings.entries.toList()
              ..sort((a, b) => a.value.position.compareTo(b.value.position));

            final targetIndex =
                columnSettings[header]!.position.clamp(0, sorted.length);
            sorted.insert(
                targetIndex, MapEntry(draggedHeader as String, draggedSetting));

            return state.copyWith(columnsState: {
              for (int i = 0; i < sorted.length; i++)
                sorted[i].key: sorted[i].value.copyWith(position: i),
            });
          });
        },
      ),
    );
  }
}

class SortableHeader extends ConsumerStatefulWidget {
  final String columnSortField;
  final Function(WispGridState Function(WispGridState)) updateGridState;
  final WispGridState gridState;
  final Widget child;

  const SortableHeader({
    super.key,
    required this.columnSortField,
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
    final isActive = gridState.sortedColumnKey == widget.columnSortField;

    return InkWell(
      onTap: () {
        widget.updateGridState((WispGridState state) {
          // if (state.sortField == widget.columnSortField.toString()) {
          return state.copyWith(
            sortedColumnKey: widget.columnSortField,
            isSortDescending: !state.isSortDescending,
          );
          // } else {
          //   return state.copyWith(
          //       sortField: widget.columnSortField.toString(),
          //       isSortDescending: !state.isSortDescending);
          // }
        });
      },
      child: Row(
        children: [
          widget.child,
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                  isSortDescending
                      ? Icons.arrow_drop_down
                      : Icons.arrow_drop_up,
                  size: 20),
            )
        ],
      ),
    );
  }
}
