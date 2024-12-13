import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid_state.dart';

import 'wisp_grid.dart';

class WispGridModHeaderRowView extends ConsumerStatefulWidget {
  const WispGridModHeaderRowView({super.key});

  @override
  ConsumerState createState() => _WispGridModHeaderRowViewState();
}

class _WispGridModHeaderRowViewState
    extends ConsumerState<WispGridModHeaderRowView> {
  @override
  Widget build(BuildContext context) {
    final gridState = ref.watch(modGridStateProvider);

    return Row(
        children: (gridState.columnSettings.entries.map((columnSetting) {
      return Builder(builder: (context) {
        final header = columnSetting.key;
        final state = columnSetting.value;
        final headerTextStyle =
            Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);

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
    }).toList()));
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
    final isActive = gridState.sortField == widget.columnSortField.toString();

    return InkWell(
      onTap: () {
        // ref.read(modGridStateProvider.notifier).toggleSortField(
        //     widget.columnSortField, isSortDescending);
      },
      child: Row(
        children: [
          widget.child,
          if (isActive)
            Icon(isSortDescending ? Icons.arrow_downward : Icons.arrow_upward)
        ],
      ),
    );
  }
}
