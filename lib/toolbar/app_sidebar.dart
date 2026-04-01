import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/launcher/launcher.dart';
import 'package:trios/rules_autofresh/rules_hotreload.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/thirdparty/faded_scrollable/faded_scrollable.dart';
import 'package:trios/toolbar/chatbot_button.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/moving_tooltip.dart';

const _collapsedWidth = 56.0;
const _expandedWidth = 200.0;
const _animationDuration = Duration(milliseconds: 200);

class AppSidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
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
        child: Column(
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
                if (ref.watch(
                      appSettings.select((s) => s.showAprilFools2026),
                    ) !=
                    true) {
                  return const SizedBox.shrink();
                }
                return const ChatbotButton(size: 40, iconSize: 20);
              },
            ),
            // Core tools
            _SidebarNavItem.fromTool(
              tool: TriOSTools.dashboard,
              isSelected: currentPage == TriOSTools.dashboard,
              isCollapsed: isCollapsed,
              onTap: () => onTabChanged(TriOSTools.dashboard),
            ),
            _SidebarNavItem.fromTool(
              tool: TriOSTools.modManager,
              isSelected: currentPage == TriOSTools.modManager,
              isCollapsed: isCollapsed,
              onTap: () => onTabChanged(TriOSTools.modManager),
            ),
            _SidebarNavItem.fromTool(
              tool: TriOSTools.modProfiles,
              isSelected: currentPage == TriOSTools.modProfiles,
              isCollapsed: isCollapsed,
              onTap: () => onTabChanged(TriOSTools.modProfiles),
            ),
            _SidebarNavItem.fromTool(
              tool: TriOSTools.catalog,
              isSelected: currentPage == TriOSTools.catalog,
              isCollapsed: isCollapsed,
              onTap: () => onTabChanged(TriOSTools.catalog),
            ),
            _SidebarNavItem.fromTool(
              tool: TriOSTools.chipper,
              isSelected: currentPage == TriOSTools.chipper,
              isCollapsed: isCollapsed,
              onTap: () => onTabChanged(TriOSTools.chipper),
            ),
            const _SidebarDivider(),
            // Viewer tools
            Expanded(
              child: FadedScrollable(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _SidebarNavItem.fromTool(
                        tool: TriOSTools.ships,
                        isSelected: currentPage == TriOSTools.ships,
                        isCollapsed: isCollapsed,
                        onTap: () => onTabChanged(TriOSTools.ships),
                      ),
                      _SidebarNavItem.fromTool(
                        tool: TriOSTools.weapons,
                        isSelected: currentPage == TriOSTools.weapons,
                        isCollapsed: isCollapsed,
                        onTap: () => onTabChanged(TriOSTools.weapons),
                      ),
                      _SidebarNavItem.fromTool(
                        tool: TriOSTools.hullmods,
                        isSelected: currentPage == TriOSTools.hullmods,
                        isCollapsed: isCollapsed,
                        onTap: () => onTabChanged(TriOSTools.hullmods),
                      ),
                      _SidebarNavItem.fromTool(
                        tool: TriOSTools.portraits,
                        isSelected: currentPage == TriOSTools.portraits,
                        isCollapsed: isCollapsed,
                        onTap: () => onTabChanged(TriOSTools.portraits),
                      ),
                      _SidebarNavItem.fromTool(
                        tool: TriOSTools.vramEstimator,
                        isSelected: currentPage == TriOSTools.vramEstimator,
                        isCollapsed: isCollapsed,
                        onTap: () => onTabChanged(TriOSTools.vramEstimator),
                      ),
                      _SidebarNavItem.fromTool(
                        tool: TriOSTools.tips,
                        isSelected: currentPage == TriOSTools.tips,
                        isCollapsed: isCollapsed,
                        onTap: () => onTabChanged(TriOSTools.tips),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // const Spacer(),
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
          borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
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
  final VoidCallback onTap;
  final Widget icon;
  final String label;
  final String tooltip;

  const _SidebarNavItem({
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  _SidebarNavItem.fromTool({
    required TriOSTools tool,
    required bool isSelected,
    required bool isCollapsed,
    required VoidCallback onTap,
  }) : this(
         isSelected: isSelected,
         isCollapsed: isCollapsed,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
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
          "rules.csv hot reload is ${isEnabled ? "enabled" : "disabled"}."
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
