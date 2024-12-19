import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/utils/extensions.dart';

import '../../widgets/MultiSplitViewMixin.dart';
import '../../widgets/hoverable_widget.dart';
import '../../widgets/moving_tooltip.dart';
import 'wisp_grid.dart';

class WispGridModHeaderRowView extends ConsumerStatefulWidget {
  const WispGridModHeaderRowView({super.key});

  @override
  ConsumerState createState() => _WispGridModHeaderRowViewState();
}

const _opacity = 0.5;

class _WispGridModHeaderRowViewState
    extends ConsumerState<WispGridModHeaderRowView> with MultiSplitViewMixin {
  bool _isResizing = false;

  @override
  List<Area> get areas => ref
      .read(modGridStateProvider)
      .columnSettings
      .entries
      .sortedByButBetter((entry) => entry.value.position)
      .map((entry) => Area(id: entry.key.toString(), size: entry.value.width))
      .toList();

  @override
  void initState() {
    super.initState();
    multiSplitController = MultiSplitViewController(areas: areas);
    multiSplitController.addListener(onMultiSplitViewChanged);
  }

  @override
  void didUpdateWidget(covariant WispGridModHeaderRowView oldWidget) {
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
      ref.read(modGridStateProvider.notifier).update((state) {
        final columnSettings = state.columnSettings.toMap();
        for (final area in multiSplitController.areas) {
          final header = ModGridHeader.values
              .firstWhere((header) => header.toString() == area.id);
          columnSettings[header] =
              columnSettings[header]!.copyWith(width: area.size);
        }
        return state.copyWith(columnSettings: columnSettings);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gridState = ref.watch(modGridStateProvider);
    final theme = Theme.of(context);

    return HoverableWidget(builder: (context, isHovering) {
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
        child: MultiSplitView(
            controller: multiSplitController,
            axis: Axis.horizontal,
            builder: (context, area) {
              // child: Row(
              // children: (gridState.columnSettings.entries.map((columnSetting) {
              final columnSetting =
                  gridState.columnSettings.entries.elementAt(area.index);

              return Builder(builder: (context) {
                final header = columnSetting.key;
                final state = columnSetting.value;
                final headerTextStyle = Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold);

                return switch (header) {
                  ModGridHeader.favorites => DraggableHeader(
                      showDragHandle: isHovering,
                      header: header,
                      child: SizedBox(
                        width: state.width,
                        child: Container(),
                      ),
                    ),
                  ModGridHeader.changeVariantButton => DraggableHeader(
                      showDragHandle: isHovering,
                      header: header,
                      child: SizedBox(width: state.width, child: Container())),
                  ModGridHeader.icons => DraggableHeader(
                      showDragHandle: isHovering,
                      header: header,
                      child: SizedBox(width: state.width, child: Container())),
                  ModGridHeader.modIcon => DraggableHeader(
                      showDragHandle: isHovering,
                      header: header,
                      child: SizedBox(width: state.width, child: Container())),
                  ModGridHeader.name => DraggableHeader(
                      showDragHandle: isHovering,
                      header: header,
                      child: SizedBox(
                          width: state.width,
                          child: SortableHeader(
                              columnSortField: ModGridSortField.name,
                              child: Text('Name', style: headerTextStyle))),
                    ),
                  ModGridHeader.author => DraggableHeader(
                      showDragHandle: isHovering,
                      header: header,
                      child: SizedBox(
                          width: state.width,
                          child: SortableHeader(
                              columnSortField: ModGridSortField.author,
                              child: Text('Author', style: headerTextStyle))),
                    ),
                  ModGridHeader.version => DraggableHeader(
                      showDragHandle: isHovering,
                      header: header,
                      child: SizedBox(
                          width: state.width,
                          child: SortableHeader(
                              columnSortField: ModGridSortField.version,
                              child: Text('Version', style: headerTextStyle))),
                    ),
                  ModGridHeader.vramImpact => DraggableHeader(
                      showDragHandle: isHovering,
                      header: header,
                      child: SizedBox(
                          width: state.width,
                          child: SortableHeader(
                              columnSortField: ModGridSortField.vramImpact,
                              child:
                                  Text('VRAM Impact', style: headerTextStyle))),
                    ),
                  ModGridHeader.gameVersion => DraggableHeader(
                      showDragHandle: isHovering,
                      header: header,
                      child: SizedBox(
                          width: state.width,
                          child: SortableHeader(
                              columnSortField: ModGridSortField.gameVersion,
                              child: Text('Game Version',
                                  style: headerTextStyle))),
                    ),
                };
              });
            }),
      );
    });
  }
}

class DraggableHeader extends ConsumerWidget {
  final Widget child;
  final ModGridHeader header;
  final bool showDragHandle;

  const DraggableHeader({
    super.key,
    required this.child,
    required this.header,
    required this.showDragHandle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFirst = ref
            .watch(modGridStateProvider)
            .columnSettings
            .entries
            .firstOrNull
            ?.key ==
        header;
    final isLast = ref
            .watch(modGridStateProvider)
            .columnSettings
            .entries
            .lastOrNull
            ?.key ==
        header;

    draggableChild(bool isHovered) {
      return Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: isHovered ? _opacity : 1,
            child: child,
          ),
          if (isFirst)
            MovingTooltipWidget.text(
              message: 'Reset grid',
              child: Opacity(
                opacity: showDragHandle ? 1 : 0,
                child: IconButton(
                    padding: EdgeInsets.zero,
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                    ),
                    onPressed: () {
                      ref
                          .read(modGridStateProvider.notifier)
                          .update((state) => WispGridState());
                    },
                    icon: Icon(Icons.settings_backup_restore)),
              ),
            )
          else
            Positioned(
              right: isLast ? 12 : 4,
              child: Opacity(
                opacity: showDragHandle ? 1 : 0,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Opacity(
                      opacity: _opacity,
                      child: Icon(Icons.drag_indicator, size: 16)),
                ),
              ),
            ),
        ],
      );
    }

    return Draggable<ModGridHeader>(
      data: header,
      feedback: Icon(Icons.drag_indicator, size: 16),
      axis: Axis.horizontal,
      dragAnchorStrategy: (draggable, context, position) => Offset(16, 8),
      childWhenDragging: Opacity(opacity: 0.5, child: draggableChild(false)),
      child: DragTarget<ModGridHeader>(
        builder: (context, candidateData, rejectedData) {
          final isHovered = candidateData.isNotEmpty;
          return draggableChild(isHovered);
        },
        onWillAcceptWithDetails: (data) => data.data != header,
        onAcceptWithDetails: (data) {
          ref.read(modGridStateProvider.notifier).update((state) {
            final columnSettings = state.columnSettings.toMap();
            final draggedHeader = data.data;
            final draggedSetting = columnSettings.remove(draggedHeader)!;

            final sorted = columnSettings.entries.toList()
              ..sort((a, b) => a.value.position.compareTo(b.value.position));

            final targetIndex =
                columnSettings[header]!.position.clamp(0, sorted.length);
            sorted.insert(targetIndex, MapEntry(draggedHeader, draggedSetting));

            return state.copyWith(columnSettings: {
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
  final ModGridSortField columnSortField;
  final Widget child;

  const SortableHeader(
      {super.key, required this.columnSortField, required this.child});

  @override
  ConsumerState createState() => _SortableHeaderState();
}

class _SortableHeaderState extends ConsumerState<SortableHeader> {
  @override
  Widget build(BuildContext context) {
    final gridState = ref.watch(modGridStateProvider);
    final isSortDescending = gridState.isSortDescending;
    final isActive = gridState.sortField == widget.columnSortField;

    return InkWell(
      onTap: () {
        ref.read(modGridStateProvider.notifier).update((state) {
          // if (state.sortField == widget.columnSortField.toString()) {
          return state.copyWith(
            sortField: widget.columnSortField,
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
