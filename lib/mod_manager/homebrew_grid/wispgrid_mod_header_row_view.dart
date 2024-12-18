import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';
import 'package:trios/thirdparty/dartx/map.dart';
import 'package:trios/utils/extensions.dart';

import '../../widgets/MultiSplitViewMixin.dart';
import '../../widgets/hoverable_widget.dart';
import 'wisp_grid.dart';

class WispGridModHeaderRowView extends ConsumerStatefulWidget {
  const WispGridModHeaderRowView({super.key});

  @override
  ConsumerState createState() => _WispGridModHeaderRowViewState();
}

class _WispGridModHeaderRowViewState
    extends ConsumerState<WispGridModHeaderRowView> with MultiSplitViewMixin {
  @override
  List<Area> get areas => ref
      .read(modGridStateProvider)
      .columnSettings
      .entries
      .sortedByButBetter((entry) => entry.value.position)
      .map((entry) => Area(id: entry.key.toString(), size: entry.value.width))
      .toList();

  @override
  void onMultiSplitViewChanged() {
    super.onMultiSplitViewChanged();
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
                  ? theme.colorScheme.onSurface.withOpacity(0.2)
                  : Colors.transparent,
              highlightedColor: theme.colorScheme.onSurface,
              size: 20,
              animationDuration: const Duration(milliseconds: 50),
              highlightedSize: 20,
            )),
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
                  ModGridHeader.favorites => SizedBox(
                      width: state.width,
                    ),
                  ModGridHeader.changeVariantButton =>
                    SizedBox(width: state.width, child: Container()),
                  ModGridHeader.icons =>
                    SizedBox(width: state.width, child: Container()),
                  ModGridHeader.modIcon =>
                    SizedBox(width: state.width, child: Container()),
                  ModGridHeader.name => SizedBox(
                      width: state.width,
                      child: SortableHeader(
                          columnSortField: ModGridSortField.name,
                          child: Text('Name', style: headerTextStyle))),
                  ModGridHeader.author => SizedBox(
                      width: state.width,
                      child: SortableHeader(
                          columnSortField: ModGridSortField.author,
                          child: Text('Author', style: headerTextStyle))),
                  ModGridHeader.version => SizedBox(
                      width: state.width,
                      child: SortableHeader(
                          columnSortField: ModGridSortField.version,
                          child: Text('Version', style: headerTextStyle))),
                  ModGridHeader.vramImpact => SizedBox(
                      width: state.width,
                      child: SortableHeader(
                          columnSortField: ModGridSortField.vramImpact,
                          child: Text('VRAM Impact', style: headerTextStyle))),
                  ModGridHeader.gameVersion => SizedBox(
                      width: state.width,
                      child: SortableHeader(
                          columnSortField: ModGridSortField.gameVersion,
                          child: Text('Game Version', style: headerTextStyle))),
                };
              });
            }),
      );
    });
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
