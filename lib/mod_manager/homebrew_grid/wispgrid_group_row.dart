import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trios/mod_manager/homebrew_grid/wisp_grid.dart';
import 'package:trios/mod_manager/homebrew_grid/wispgrid_group.dart';
import 'package:trios/mod_tag_manager/category.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
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
  final WispGridState gridState;
  final Function(WispGridState? Function(WispGridState)) updateGridState;

  const WispGridGroupRowView({
    super.key,
    required this.grouping,
    required this.itemsInGroup,
    required this.isCollapsed,
    required this.shownIndex,
    required this.setCollapsed,
    required this.columns,
    required this.gridState,
    required this.updateGridState,
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
    final groupColor = widget.itemsInGroup.firstOrNull?.let(
      widget.grouping.getGroupColor,
    );
    final groupIcon = widget.itemsInGroup.firstOrNull?.let(
      widget.grouping.getGroupIcon,
    );

    final headerStyle =
        widget.gridState.groupingSetting?.headerStyle ?? GroupHeaderStyle.small;

    final overlayData = widget.grouping.overlayWidget(
      context,
      widget.itemsInGroup,
      ref,
      widget.shownIndex,
      widget.columns,
      horizontalPaddingOffset: headerStyle == GroupHeaderStyle.small
          ? 16.0
          : 0.0,
    );

    final headerContent = switch (headerStyle) {
      GroupHeaderStyle.large => _buildLargeHeader(
        context,
        groupName,
        itemsInGroup,
        groupColor,
        groupIcon,
        overlayData,
      ),
      GroupHeaderStyle.medium => _buildMediumHeader(
        context,
        groupName,
        itemsInGroup,
        groupColor,
        groupIcon,
        overlayData,
      ),
      GroupHeaderStyle.small => _buildSmallHeader(
        context,
        groupName,
        itemsInGroup,
        groupColor,
        groupIcon,
        overlayData,
      ),
    };

    return widget.grouping.wrapGroupWidget(
      context,
      widget.itemsInGroup,
      ref,
      widget.shownIndex,
      widget.columns,
      additionalMenuEntries: _buildGroupHeaderContextMenu().entries,
      child: headerContent,
    );
  }

  Widget _buildLargeHeader(
    BuildContext context,
    String groupName,
    List<T> itemsInGroup,
    Color? groupColor,
    CategoryIcon? groupIcon,
    OverlayWidgetData? overlayData,
  ) {
    return Card(
      child: InkWell(
        onTap: () {
          widget.setCollapsed(!widget.isCollapsed);
        },
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Stack(
            alignment: .centerLeft,
            children: [
              Row(
                spacing: 4,
                crossAxisAlignment: .center,
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
                  if (groupIcon != null)
                    Padding(
                      padding: const .only(right: 6),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: groupIcon.toWidget(size: 24, color: groupColor),
                      ),
                    ),
                  if (groupColor != null && groupIcon == null)
                    Padding(
                      padding: const .only(right: 8),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: groupColor,
                          borderRadius: .circular(4),
                        ),
                      ),
                    ),
                  Text(
                    "${groupName.trim()} (${itemsInGroup.length})",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.robotoSlab(
                      textStyle: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              if (overlayData != null)
                Positioned(left: overlayData.left, child: overlayData.child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediumHeader(
    BuildContext context,
    String groupName,
    List<T> itemsInGroup,
    Color? groupColor,
    CategoryIcon? groupIcon,
    OverlayWidgetData? overlayData,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: InkWell(
        onTap: () {
          widget.setCollapsed(!widget.isCollapsed);
        },
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          child: Stack(
            alignment: .centerLeft,
            children: [
              Row(
                spacing: 4,
                crossAxisAlignment: .center,
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
                  if (groupIcon != null)
                    Padding(
                      padding: const .only(right: 4),
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: groupIcon.toWidget(size: 16, color: groupColor),
                      ),
                    ),
                  if (groupColor != null && groupIcon == null)
                    Padding(
                      padding: const .only(right: 6),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: groupColor,
                          borderRadius: .circular(2),
                        ),
                      ),
                    ),
                  Text(
                    "${groupName.trim()} (${itemsInGroup.length})",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.robotoSlab(
                      textStyle: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              if (overlayData != null)
                Positioned(left: overlayData.left, child: overlayData.child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallHeader(
    BuildContext context,
    String groupName,
    List<T> itemsInGroup,
    Color? groupColor,
    CategoryIcon? groupIcon,
    OverlayWidgetData? overlayData,
  ) {
    final dividerColor = Theme.of(context).colorScheme.outlineVariant;
    // final dividerColor = groupColor?.withAlpha(150) ?? Theme.of(context).colorScheme.outlineVariant;

    return InkWell(
      onTap: () => widget.setCollapsed(!widget.isCollapsed),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Stack(
        alignment: .centerLeft,
        children: [
          Row(
            children: [
              // SizedBox(
              //   width: 32,
              //   child: Divider(color: dividerColor, height: 1),
              // ),
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
              if (groupIcon != null)
                Padding(
                  padding: const .only(right: 4),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: groupIcon.toWidget(size: 16, color: groupColor),
                  ),
                ),
              if (groupColor != null && groupIcon == null)
                Padding(
                  padding: const .only(right: 6),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: groupColor,
                      borderRadius: .circular(2),
                    ),
                  ),
                ),
              Padding(
                padding: const .only(left: 4, right: 8),
                child: Text(
                  "${groupName.trim()} (${itemsInGroup.length})",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.robotoSlab(
                    textStyle: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
              Expanded(child: Divider(color: dividerColor, height: 1)),
            ],
          ),
          if (overlayData != null)
            Builder(
              builder: (context) {
                const leftMargin = 8.0;
                return Positioned(
                  left: overlayData.left - leftMargin,
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const .only(left: leftMargin),
                      child: overlayData.child,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  ContextMenu _buildGroupHeaderContextMenu() {
    final currentStyle =
        widget.gridState.groupingSetting?.headerStyle ?? GroupHeaderStyle.small;

    return ContextMenu(
      entries: [
        MenuItem.submenu(
          label: 'Header Style',
          icon: Icons.view_agenda_outlined,
          items: [
            MenuItem(
              label: 'Tall Card',
              icon: currentStyle == GroupHeaderStyle.large ? Icons.check : null,
              onSelected: () => _setHeaderStyle(GroupHeaderStyle.large),
            ),
            MenuItem(
              label: 'Short Card',
              icon: currentStyle == GroupHeaderStyle.medium
                  ? Icons.check
                  : null,
              onSelected: () => _setHeaderStyle(GroupHeaderStyle.medium),
            ),
            MenuItem(
              label: 'Line',
              icon: currentStyle == GroupHeaderStyle.small ? Icons.check : null,
              onSelected: () => _setHeaderStyle(GroupHeaderStyle.small),
            ),
          ],
        ),
      ],
    );
  }

  void _setHeaderStyle(GroupHeaderStyle style) {
    widget.updateGridState((WispGridState state) {
      final current = state.groupingSetting;
      if (current == null) return state;
      return state.copyWith(
        groupingSetting: current.copyWith(headerStyle: style),
      );
    });
  }
}
