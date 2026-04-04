import 'package:flutter/material.dart';
import 'package:trios/toolbar/app_action_buttons.dart';
import 'package:trios/toolbar/app_brand_header.dart';
import 'package:trios/toolbar/app_right_toolbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/toolbar/chatbot_button.dart';
import 'package:trios/toolbar/tab_button.dart';
import 'package:trios/trios/navigation.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/moving_tooltip.dart';

import '../launcher/launcher.dart';

/// Full top bar used in top-toolbar layout mode.
/// Contains brand, launcher, nav items, action buttons, and right-side status items.
class FullTopBar extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
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
          // Nav items
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 0, top: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                _coreTabButton(TriOSTools.dashboard),
                _coreTabButton(TriOSTools.modManager),
                _coreTabButton(TriOSTools.modProfiles),
                _coreTabButton(TriOSTools.catalog),
                _coreTabButton(TriOSTools.chipper),
                const SizedBox(width: 4),
                Row(
                  spacing: 2,
                  children: [
                    _viewerIconButton(TriOSTools.vramEstimator, theme),
                    _viewerIconButton(TriOSTools.ships, theme),
                    _viewerIconButton(TriOSTools.weapons, theme),
                    _viewerIconButton(TriOSTools.hullmods, theme),
                    _viewerIconButton(TriOSTools.portraits, theme),
                    _viewerIconButton(TriOSTools.tips, theme),
                  ],
                ),
              ],
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
  }

  Widget _coreTabButton(TriOSTools tool) {
    return MovingTooltipWidget.text(
      message: tool.tooltip,
      child: TabButton(
        text: tool.label,
        icon: tool.icon(),
        isSelected: currentPage == tool,
        onPressed: () => onTabChanged(tool),
      ),
    );
  }

  Widget _viewerIconButton(TriOSTools tool, ThemeData theme) {
    return MovingTooltipWidget.text(
      message: tool.tooltip,
      child: IconButton(
        icon: tool.icon(),
        selectedIcon: tool.icon(color: theme.colorScheme.primary),
        isSelected: currentPage == tool,
        onPressed: () => onTabChanged(tool),
      ),
    );
  }
}
