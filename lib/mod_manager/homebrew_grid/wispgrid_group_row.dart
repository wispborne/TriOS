import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/utils/extensions.dart';

import 'wisp_grid_state.dart';

class WispGridGroupRowView<T extends WispGridItem>
    extends ConsumerStatefulWidget {
  final WispGridGroup grouping;
  final List<T> itemsInGroup;
  final bool isCollapsed;
  final int shownIndex;
  final Function(bool isCollapsed) setCollapsed;
  final List<WispGridColumn<T>> columns;

  const WispGridGroupRowView({
    super.key,
    required this.grouping,
    required this.itemsInGroup,
    required this.isCollapsed,
    required this.shownIndex,
    required this.setCollapsed,
    required this.columns,
  });

  @override
  ConsumerState createState() => _WispGridRowState<T>();
}

class _WispGridRowState<T extends WispGridItem>
    extends ConsumerState<WispGridGroupRowView<T>> {
  @override
  Widget build(BuildContext context) {
    final itemsInGroup = widget.itemsInGroup;
    final groupName =
        widget.itemsInGroup.firstOrNull?.let(widget.grouping.getGroupName) ??
        "";
    ;

    final overlayWidget = widget.grouping.overlayWidget(
      context,
      widget.itemsInGroup,
      ref,
      widget.shownIndex,
      widget.columns,
    );
    return Card(
      child: InkWell(
        onTap: () {
          widget.setCollapsed(!widget.isCollapsed);
        },
        // no ripple
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Icon(
                      widget.isCollapsed
                          ? Icons.keyboard_arrow_right
                          : Icons.keyboard_arrow_down,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    "${groupName.trim()} (${itemsInGroup.length})",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: ThemeManager.orbitron,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (overlayWidget != null) overlayWidget,
            ],
          ),
        ),
      ),
    );
  }
}
