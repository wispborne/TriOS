import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/mod_manager/homebrew_grid/vram_checker_explanation.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/MultiSplitViewMixin.dart';
import 'package:trios/widgets/hoverable_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';

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
      .read(appSettings.select((s) => s.modsGridState))
      .sortedVisibleColumns
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
      ref.read(appSettings.notifier).update((state) {
        final columnSettings =
            Map.fromEntries(state.modsGridState.sortedColumns);
        for (final area in multiSplitController.areas) {
          final header = ModGridHeader.values
              .firstWhereOrNull((header) => header.toString() == area.id);
          if (header == null) continue;
          columnSettings[header] =
              columnSettings[header]!.copyWith(width: area.size);
        }
        return state.copyWith(
            modsGridState:
                state.modsGridState.copyWith(columnSettings: columnSettings));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gridState = ref.watch(appSettings.select((s) => s.modsGridState));
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

                  final columnSetting = gridState.sortedVisibleColumns
                      .elementAt(min(area.index,
                          gridState.sortedVisibleColumns.length - 1));

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
                          child:
                              SizedBox(width: state.width, child: Container())),
                      ModGridHeader.icons => DraggableHeader(
                          showDragHandle: isHovering,
                          header: header,
                          child: SortableHeader(
                              columnSortField: ModGridSortField.icons,
                              child: SizedBox(
                                  width: state.width, child: Container()))),
                      ModGridHeader.modIcon => DraggableHeader(
                          showDragHandle: isHovering,
                          header: header,
                          child:
                              SizedBox(width: state.width, child: Container())),
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
                                  child:
                                      Text('Author', style: headerTextStyle))),
                        ),
                      ModGridHeader.version => DraggableHeader(
                          showDragHandle: isHovering,
                          header: header,
                          child: SizedBox(
                              width: state.width,
                              child: SortableHeader(
                                  columnSortField: ModGridSortField.version,
                                  child:
                                      Text('Version', style: headerTextStyle))),
                        ),
                      ModGridHeader.vramImpact => DraggableHeader(
                          showDragHandle: isHovering,
                          header: header,
                          child: SizedBox(
                              width: state.width,
                              child: MovingTooltipWidget.text(
                                message:
                                    'An *estimate* of how much VRAM is used based on the images in the mod folder.'
                                    '\nThis may be inaccurate.',
                                child: SortableHeader(
                                    columnSortField:
                                        ModGridSortField.vramImpact,
                                    child: Row(
                                      children: [
                                        Text('VRAM Est.',
                                            style: headerTextStyle),
                                        const SizedBox(width: 4),
                                        MovingTooltipWidget.text(
                                          message:
                                              "About VRAM & VRAM Estimator",
                                          child: IconButton(
                                            onPressed: () => showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    VramCheckerExplanationDialog()),
                                            padding: const EdgeInsets.all(2),
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(
                                              Icons.info_outline,
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      ],
                                    )),
                              )),
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
                      ModGridHeader.firstSeen => DraggableHeader(
                          showDragHandle: isHovering,
                          header: header,
                          child: SizedBox(
                              width: state.width,
                              child: SortableHeader(
                                  columnSortField: ModGridSortField.firstSeen,
                                  child: Text('First Seen',
                                      style: headerTextStyle))),
                        ),
                      ModGridHeader.lastEnabled => DraggableHeader(
                          showDragHandle: isHovering,
                          header: header,
                          child: SizedBox(
                              width: state.width,
                              child: SortableHeader(
                                  columnSortField: ModGridSortField.lastEnabled,
                                  child: Text('Last Enabled',
                                      style: headerTextStyle))),
                        ),
                    };
                  });
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
              ref
                  .read(appSettings.notifier)
                  .update((s) => s.copyWith(modsGridState: WispGridState()));
            }),
        MenuItem.submenu(
            label: "Group By",
            icon: Icons.horizontal_split,
            items: [
              MenuItem(
                label: "Enabled",
                icon: groupingSetting.grouping == ModGridGroupEnum.enabledState
                    ? Icons.check
                    : null,
                onSelected: () {
                  ref.read(appSettings.notifier).update((s) => s.copyWith(
                      modsGridState: s.modsGridState.copyWith(
                          groupingSetting: GroupingSetting(
                              grouping: ModGridGroupEnum.enabledState))));
                },
              ),
              MenuItem(
                label: "Mod Type",
                icon: groupingSetting.grouping == ModGridGroupEnum.modType
                    ? Icons.check
                    : null,
                onSelected: () {
                  ref.read(appSettings.notifier).update((s) => s.copyWith(
                      modsGridState: s.modsGridState.copyWith(
                          groupingSetting: GroupingSetting(
                              grouping: ModGridGroupEnum.modType))));
                },
              ),
              MenuItem(
                  label: "Game Version",
                  icon: groupingSetting.grouping == ModGridGroupEnum.gameVersion
                      ? Icons.check
                      : null,
                  onSelected: () {
                    ref.read(appSettings.notifier).update((s) => s.copyWith(
                        modsGridState: s.modsGridState.copyWith(
                            groupingSetting: GroupingSetting(
                                grouping: ModGridGroupEnum.gameVersion))));
                  }),
              MenuItem(
                label: "Author",
                icon: groupingSetting.grouping == ModGridGroupEnum.author
                    ? Icons.check
                    : null,
                onSelected: () {
                  ref.read(appSettings.notifier).update((s) => s.copyWith(
                      modsGridState: s.modsGridState.copyWith(
                          groupingSetting: GroupingSetting(
                              grouping: ModGridGroupEnum.author))));
                },
              ),
            ]),
        MenuDivider(),
        MenuHeader(text: "Hide/Show Columns", disableUppercase: true),
        // Visibility toggles
        ...gridState.columnSettings.entries.map((columnSetting) {
          final header = columnSetting.key;
          final isVisible = gridState.columnSettings[header]?.isVisible ?? true;
          return MenuItem(
            label: header.displayName,
            icon: isVisible ? Icons.visibility : Icons.visibility_off,
            onSelected: () {
              ref.read(appSettings.notifier).update((s) {
                final columnSettings = s.modsGridState.columnSettings.toMap();
                final headerSetting = columnSettings[header]!;
                columnSettings[header] =
                    headerSetting.copyWith(isVisible: !headerSetting.isVisible);

                return s.copyWith(
                    modsGridState: s.modsGridState
                        .copyWith(columnSettings: columnSettings));
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
    var gridState = ref.watch(appSettings.select((s) => s.modsGridState));
    final isFirst = gridState.sortedVisibleColumns.firstOrNull?.key == header;
    final isLast = gridState.sortedVisibleColumns.lastOrNull?.key == header;

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
                    ref.read(appSettings.notifier).update((state) =>
                        state.copyWith(modsGridState: WispGridState()));
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

    return Draggable<ModGridHeader>(
      data: header,
      feedback: const Icon(Icons.drag_indicator, size: 16),
      axis: Axis.horizontal,
      dragAnchorStrategy: (draggable, context, position) => const Offset(16, 8),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: draggableChild(false),
      ),
      child: DragTarget<ModGridHeader>(
        builder: (context, candidateData, rejectedData) {
          final isHovered = candidateData.isNotEmpty;
          return draggableChild(isHovered);
        },
        onWillAcceptWithDetails: (data) => data.data != header,
        onAcceptWithDetails: (data) {
          ref.read(appSettings.notifier).update((state) {
            final columnSettings = state.modsGridState.columnSettings.toMap();
            final draggedHeader = data.data;
            final draggedSetting = columnSettings.remove(draggedHeader)!;

            final sorted = columnSettings.entries.toList()
              ..sort((a, b) => a.value.position.compareTo(b.value.position));

            final targetIndex =
                columnSettings[header]!.position.clamp(0, sorted.length);
            sorted.insert(targetIndex, MapEntry(draggedHeader, draggedSetting));

            return state.copyWith(
                modsGridState: state.modsGridState.copyWith(columnSettings: {
              for (int i = 0; i < sorted.length; i++)
                sorted[i].key: sorted[i].value.copyWith(position: i),
            }));
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
    final gridState = ref.watch(appSettings.select((s) => s.modsGridState));
    final isSortDescending = gridState.isSortDescending;
    final isActive = gridState.sortField == widget.columnSortField;

    return InkWell(
      onTap: () {
        ref.read(appSettings.notifier).update((state) {
          // if (state.sortField == widget.columnSortField.toString()) {
          return state.copyWith(
              modsGridState: state.modsGridState.copyWith(
            sortField: widget.columnSortField,
            isSortDescending: !state.modsGridState.isSortDescending,
          ));
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
