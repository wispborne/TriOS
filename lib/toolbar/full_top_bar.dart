import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/toolbar/app_action_buttons.dart';
import 'package:trios/toolbar/app_brand_header.dart';
import 'package:trios/toolbar/app_right_toolbar.dart';
import 'package:trios/toolbar/chatbot_button.dart';
import 'package:trios/toolbar/nav_order_controller.dart';
import 'package:trios/toolbar/nav_order_entry.dart';
import 'package:trios/toolbar/nav_reorder_menu.dart';
import 'package:trios/toolbar/tab_button.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';

import '../launcher/launcher.dart';

/// Full top bar used in top-toolbar layout mode.
/// Contains brand, launcher, nav items, action buttons, and right-side status items.
class FullTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final TriOSTools currentPage;
  final ValueChanged<TriOSTools> onTabChanged;
  final ScrollController scrollController;

  const FullTopBar({
    super.key,
    required this.currentPage,
    required this.onTabChanged,
    required this.scrollController,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final navState = ref.watch(navOrderProvider);
    final controller = ref.read(navOrderProvider.notifier);

    // Split entries: core tools are rendered as "text + icon" TabButtons (as
    // before), viewers as compact IconButtons. The boundary is the divider
    // entry; everything before the divider is core-styled, everything after
    // is viewer-styled.
    final entries = navState.entries;
    final dividerIndex = entries.indexWhere((e) => e is NavDividerEntry);
    final coreSlice = dividerIndex == -1
        ? entries
        : entries.sublist(0, dividerIndex);
    final viewersSlice = dividerIndex == -1
        ? const <NavOrderEntry>[]
        : entries.sublist(dividerIndex + 1);

    final navChildren = <Widget>[
      for (var i = 0; i < coreSlice.length; i++)
        _buildEntry(
          context,
          entry: coreSlice[i],
          indexInEntries: i,
          isInDragMode: navState.isInDragMode,
          onReorder: controller.reorder,
          theme: theme,
          asCoreStyle: true,
        ),
      _buildEntry(
        context,
        entry: const NavDividerEntry(),
        indexInEntries: dividerIndex == -1 ? coreSlice.length : dividerIndex,
        isInDragMode: navState.isInDragMode,
        onReorder: controller.reorder,
        theme: theme,
        asCoreStyle: false,
      ),
      for (var i = 0; i < viewersSlice.length; i++)
        _buildEntry(
          context,
          entry: viewersSlice[i],
          indexInEntries:
              (dividerIndex == -1 ? coreSlice.length : dividerIndex) + 1 + i,
          isInDragMode: navState.isInDragMode,
          onReorder: controller.reorder,
          theme: theme,
          asCoreStyle: false,
        ),
    ];

    final appBar = AppBar(
      title: Row(
        children: [
          const AppBrandHeader(compact: false),
          const LauncherButton(
            showTextInsteadOfIcon: false,
            iconHeight: 38,
            iconWidth: 42,
            fontSize: 30,
            iconOffset: Offset(0, -1),
          ),
          // Nav items (reorderable). The right-click menu is attached below
          // via a ContextMenuRegion wrapping this whole Row — right-clicking
          // the chatbot button or the reorderable icons both pop the menu,
          // but clicks still pass through for navigation.
          ContextMenuRegion(
            contextMenu: buildNavReorderContextMenu(context, ref),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 0, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final settings = ref.watch(appSettings);
                      final now = DateTime.now();
                      final isAprilFools =
                          now.month == 4 && now.day == 1 && now.year == 2026;
                      final show =
                          settings.forceShowAprilFools2026 == true ||
                          (settings.showAprilFools2026 == true && isAprilFools);
                      if (!show) return const SizedBox.shrink();
                      return const ChatbotButton(size: 40, iconSize: 18);
                    },
                  ),
                  ...navChildren,
                ],
              ),
            ),
          ),
          // "Done" sits outside the reorderable nav row so it doesn't
          // mingle with draggable icons. A compact green circle to match
          // the sidebar's Done affordance.
          if (navState.isInDragMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: MovingTooltipWidget.text(
                message: 'Exit rearrange mode',
                child: SizedBox.square(
                  dimension: 32,
                  child: FilledButton(
                    onPressed: controller.exitDragMode,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                      backgroundColor: theme.statusColors.success,
                      foregroundColor: theme.statusColors.onSuccess,
                    ),
                    child: const Icon(Icons.check, size: 18),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          SizedBox(
            width: 1,
            height: 24,
            child: Container(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          const DebugToolbarButton(),
          const GameFolderButton(),
          const LogFileButton(),
          const BugReportButton(),
          const ToolbarLayoutToggle(),
          SettingsNavButton(
            currentPage: currentPage,
            onTabChanged: onTabChanged,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 1,
            height: 36,
            child: Container(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
          // Right-side status items
          Expanded(
            child: Scrollbar(
              controller: scrollController,
              scrollbarOrientation: ScrollbarOrientation.top,
              thickness: 4,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                reverse: true,
                clipBehavior: Clip.antiAlias,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilePermissionShield(),
                    const AdminPermissionShield(),
                    const ChangelogButton(),
                    const AboutButton(),
                    const DonateButton(),
                    const RulesHotReloadButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Esc exits drag mode. The Focus lives outside the AppBar so the Scaffold
    // still owns the app bar.
    final focused = Focus(
      autofocus: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            navState.isInDragMode) {
          controller.exitDragMode();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: appBar,
    );

    // The AppBar still implements PreferredSizeWidget via [preferredSize].
    // Overlay the 4-px green status stripe at the absolute top edge by
    // stacking it ABOVE the AppBar itself (not inside `title:`, which would
    // put the stripe below AppBar padding / centering). Mirrors the sidebar's
    // left-edge stripe.
    return PreferredSize(
      preferredSize: preferredSize,
      child: Stack(
        children: [
          focused,
          if (navState.isInDragMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: MovingTooltipWidget.text(
                message: 'Tab rearrange mode is on',
                child: Container(height: 2, color: theme.statusColors.success),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntry(
    BuildContext context, {
    required NavOrderEntry entry,
    required int indexInEntries,
    required bool isInDragMode,
    required void Function(int oldIndex, int newIndex) onReorder,
    required ThemeData theme,
    required bool asCoreStyle,
  }) {
    final child = switch (entry) {
      NavToolEntry(:final tool) =>
        asCoreStyle
            ? _coreTabButton(tool, isInDragMode)
            : _viewerIconButton(tool, theme, isInDragMode),
      NavDividerEntry() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          width: 1,
          height: 24,
          child: Container(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    };

    if (!isInDragMode) return child;

    // In drag mode: wrap in LongPressDraggable + DragTarget. The feedback is
    // a translucent copy of the child; on accept, we call controller.reorder.
    return _DragWrapper(
      index: indexInEntries,
      onReorder: onReorder,
      child: child,
    );
  }

  Widget _coreTabButton(TriOSTools tool, bool isInDragMode) {
    return MovingTooltipWidget.text(
      message: tool.tooltip,
      child: TabButton(
        text: tool.label,
        icon: tool.icon(),
        isSelected: currentPage == tool,
        // Suppress navigation while rearranging.
        onPressed: isInDragMode ? () {} : () => onTabChanged(tool),
      ),
    );
  }

  Widget _viewerIconButton(
    TriOSTools tool,
    ThemeData theme,
    bool isInDragMode,
  ) {
    return MovingTooltipWidget.text(
      message: tool.tooltip,
      child: IconButton(
        icon: tool.icon(),
        selectedIcon: tool.icon(color: theme.colorScheme.primary),
        isSelected: currentPage == tool,
        onPressed: isInDragMode ? () {} : () => onTabChanged(tool),
      ),
    );
  }
}

/// Wraps a top-bar entry so it becomes draggable (as a source) and can accept
/// drops of other entries. Uses `LongPressDraggable` so the user must hold the
/// icon briefly before dragging — this avoids accidental drags if a user left-
/// clicks while in drag mode.
class _DragWrapper extends StatelessWidget {
  final int index;
  final Widget child;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _DragWrapper({
    required this.index,
    required this.child,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        final from = details.data;
        // ReorderableListView convention: newIndex is the target position
        // as if the moved item were not yet removed. We pass `index + 1` if
        // dragging from an earlier index, else `index`. The controller handles
        // the normalization.
        final to = from < index ? index + 1 : index;
        onReorder(from, to);
      },
      builder: (ctx, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return LongPressDraggable<int>(
          data: index,
          delay: const Duration(milliseconds: 150),
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(opacity: 0.7, child: child),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: child),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            // Drop-target highlight only while another icon is hovering over
            // this one. No persistent per-icon border — matches the sidebar's
            // clean look.
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isHovered
                    ? Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.2)
                    : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
