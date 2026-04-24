import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/launcher/launcher.dart';
import 'package:trios/rules_autofresh/rules_hotreload.dart';
import 'package:trios/thirdparty/faded_scrollable/faded_scrollable.dart';
import 'package:trios/thirdparty/flutter_context_menu/flutter_context_menu.dart';
import 'package:trios/toolbar/chatbot_button.dart';
import 'package:trios/toolbar/nav_order_controller.dart';
import 'package:trios/toolbar/nav_order_entry.dart';
import 'package:trios/toolbar/nav_reorder_menu.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';

const _collapsedWidth = 56.0;
const _expandedWidth = 200.0;
const _animationDuration = Duration(milliseconds: 200);

class AppSidebar extends ConsumerWidget {
  final TriOSTools currentPage;
  final ValueChanged<TriOSTools> onTabChanged;
  final bool isCollapsed;
  final VoidCallback onToggleCollapsed;
  final bool showBorder;

  const AppSidebar({
    super.key,
    required this.currentPage,
    required this.onTabChanged,
    required this.isCollapsed,
    required this.onToggleCollapsed,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final navState = ref.watch(navOrderProvider);
    final controller = ref.read(navOrderProvider.notifier);

    final sidebar = AnimatedContainer(
      duration: _animationDuration,
      width: isCollapsed ? _collapsedWidth : _expandedWidth,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                right: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                ),
              )
            : null,
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 8),
                _SidebarToggleButton(
                  isCollapsed: isCollapsed,
                  onToggle: onToggleCollapsed,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: isCollapsed ? 0 : 16),
                  child: Align(
                    alignment: isCollapsed
                        ? Alignment.center
                        : Alignment.centerLeft,
                    child: const LauncherButton(
                      showTextInsteadOfIcon: false,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                    return const ChatbotButton(size: 40, iconSize: 16);
                  },
                ),
                // Reorderable nav list fills the remaining space.
                Expanded(
                  child: _ReorderableNavList(
                    entries: navState.entries,
                    isInDragMode: navState.isInDragMode,
                    isCollapsed: isCollapsed,
                    currentPage: currentPage,
                    onTabChanged: onTabChanged,
                    onReorder: controller.reorder,
                  ),
                ),
                if (navState.isInDragMode)
                  _DragModeDoneBanner(onDone: () => controller.exitDragMode()),
                _SidebarRulesHotReload(isCollapsed: isCollapsed),
                const _SidebarDivider(),
                _SidebarLayoutToggle(isCollapsed: isCollapsed),
                _SidebarNavItem.fromTool(
                  tool: TriOSTools.settings,
                  isSelected: currentPage == TriOSTools.settings,
                  isCollapsed: isCollapsed,
                  onTap: () => onTabChanged(TriOSTools.settings),
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (navState.isInDragMode)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: MovingTooltipWidget.text(
                  message: "Tab rearrange mode is on",
                  child: SizedBox(
                    width: 4,
                    child: Container(color: theme.statusColors.success),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Wrap the whole sidebar in a right-click ContextMenuRegion + Esc-to-exit
    // keyboard handler. Pinned children (Settings, rules.csv, layout toggle,
    // etc.) use their own onTap handlers which absorb left-clicks; the
    // ContextMenuRegion only reacts to onSecondaryTap (right-click) so normal
    // clicks on pinned items still navigate. If a pinned item ever needed its
    // own right-click menu, it would need to consume the secondary tap.
    return Focus(
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
      child: ContextMenuRegion(
        contextMenu: buildNavReorderContextMenu(context, ref),
        child: sidebar,
      ),
    );
  }
}

/// The reorderable portion of the sidebar: driven by `NavOrderController.entries`.
/// In drag mode we use a `ReorderableListView`; otherwise a plain `Column` in a
/// scrollable, matching the previous layout's behavior.
class _ReorderableNavList extends StatelessWidget {
  final List<NavOrderEntry> entries;
  final bool isInDragMode;
  final bool isCollapsed;
  final TriOSTools currentPage;
  final ValueChanged<TriOSTools> onTabChanged;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _ReorderableNavList({
    required this.entries,
    required this.isInDragMode,
    required this.isCollapsed,
    required this.currentPage,
    required this.onTabChanged,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (isInDragMode) {
      return ReorderableListView.builder(
        padding: EdgeInsets.zero,
        // We wrap each item in a `ReorderableDragStartListener` below so the
        // whole icon row is the drag handle — users don't need to grab a
        // dedicated handle.
        buildDefaultDragHandles: false,
        itemCount: entries.length,
        onReorder: onReorder,
        itemBuilder: (ctx, i) {
          final entry = entries[i];
          final key = ValueKey(_entryKey(entry, i));
          return ReorderableDragStartListener(
            key: key,
            index: i,
            child: _buildEntry(ctx, entry, key: ValueKey('child-${key.value}')),
          );
        },
      );
    }

    return FadedScrollable(
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (var i = 0; i < entries.length; i++)
              _buildEntry(
                context,
                entries[i],
                key: ValueKey(_entryKey(entries[i], i)),
              ),
          ],
        ),
      ),
    );
  }

  String _entryKey(NavOrderEntry entry, int index) {
    return switch (entry) {
      NavToolEntry(:final tool) => 'tool-${tool.name}',
      NavDividerEntry() => 'divider-$index',
    };
  }

  Widget _buildEntry(
    BuildContext context,
    NavOrderEntry entry, {
    required Key key,
  }) {
    return switch (entry) {
      NavToolEntry(:final tool) => _SidebarNavItem.fromTool(
        key: key,
        tool: tool,
        isSelected: currentPage == tool,
        isCollapsed: isCollapsed,
        isInDragMode: isInDragMode,
        onTap: () {
          // Suppress navigation while in drag mode so misclicks don't
          // switch tabs mid-drag.
          if (!isInDragMode) onTabChanged(tool);
        },
      ),
      NavDividerEntry() => Padding(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Divider(height: 1, thickness: 1),
      ),
    };
  }
}

class _DragModeDoneBanner extends StatelessWidget {
  final VoidCallback onDone;

  const _DragModeDoneBanner({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: MovingTooltipWidget.text(
        message: 'Exit rearrange mode',
        child: IconButton(
          onPressed: onDone,
          icon: Icon(
            Icons.check,
            size: 16,
            color: theme.statusColors.onSuccess,
          ),
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          style: IconButton.styleFrom(
            backgroundColor: theme.statusColors.success,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ),
    );
  }
}

class _SidebarToggleButton extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const _SidebarToggleButton({
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: MovingTooltipWidget.text(
        message: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
        child: InkWell(
          borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
          onTap: onToggle,
          child: Center(
            child: Icon(
              isCollapsed ? Icons.menu : Icons.menu_open,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final bool isSelected;
  final bool isCollapsed;
  final bool isInDragMode;
  final VoidCallback onTap;
  final Widget icon;
  final String label;
  final String tooltip;

  const _SidebarNavItem({
    super.key,
    required this.isSelected,
    required this.isCollapsed,
    this.isInDragMode = false,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  _SidebarNavItem.fromTool({
    Key? key,
    required TriOSTools tool,
    required bool isSelected,
    required bool isCollapsed,
    bool isInDragMode = false,
    required VoidCallback onTap,
  }) : this(
         key: key,
         isSelected: isSelected,
         isCollapsed: isCollapsed,
         isInDragMode: isInDragMode,
         onTap: onTap,
         icon: tool.icon(size: 20),
         label: tool.label,
         tooltip: tool.tooltip,
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.8);

    final content = SizedBox(
      height: 40,
      child: MouseRegion(
        cursor: isInDragMode
            ? SystemMouseCursors.grab
            : SystemMouseCursors.click,
        child: InkWell(
          borderRadius: BorderRadius.circular(TriOSThemeConstants.cornerRadius),
          onTap: onTap,
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                  )
                : null,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 16),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              spacing: 12,
              children: [
                IconTheme(
                  data: IconThemeData(color: foreground, size: 20),
                  child: SizedBox(width: 24, height: 24, child: icon),
                ),
                if (!isCollapsed)
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return MovingTooltipWidget.text(message: tooltip, child: content);
    }
    return content;
  }
}

class _SidebarRulesHotReload extends ConsumerWidget {
  final bool isCollapsed;

  const _SidebarRulesHotReload({required this.isCollapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(
      appSettings.select((value) => value.isRulesHotReloadEnabled),
    );

    return _SidebarNavItem(
      isSelected: false,
      isCollapsed: isCollapsed,
      onTap: () => ref
          .read(appSettings.notifier)
          .update((s) => s.copyWith(isRulesHotReloadEnabled: !isEnabled)),
      icon: RulesHotReload(isEnabled: isEnabled, showText: false),
      label: "rules.csv",
      tooltip:
          "When enabled, modifying a mod's rules.csv will\nreload in-game rules as long as dev mode is enabled."
          "\n\nrules.csv hot reload is ${isEnabled ? "enabled" : "disabled"}."
          "\nClick to ${isEnabled ? "disable" : "enable"}.",
    );
  }
}

class _SidebarLayoutToggle extends ConsumerWidget {
  final bool isCollapsed;

  const _SidebarLayoutToggle({required this.isCollapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SidebarNavItem(
      isSelected: false,
      isCollapsed: isCollapsed,
      onTap: () => ref
          .read(appSettings.notifier)
          .update((s) => s.copyWith(useTopToolbar: !s.useTopToolbar)),
      icon: Icon(Icons.web, size: 20),
      label: "Switch layout",
      tooltip: "Switch to top toolbar",
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Divider(height: 1, thickness: 1),
    );
  }
}
