import 'package:flutter/material.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/expanding_constrained_aligned_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';

/// Shared toolbar for viewer pages (Ships, Weapons, Hullmods, etc.).
///
/// Displays: entity count, loading/refresh, search box, compare mode toggle,
/// and optional trailing actions (e.g. overflow menu).
class ViewerToolbar extends StatelessWidget {
  final String entityName;
  final int total;
  final int visible;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Widget searchBox;
  final bool splitPane;
  final VoidCallback? onToggleSplitPane;
  final List<Widget> trailingActions;

  const ViewerToolbar({
    super.key,
    required this.entityName,
    required this.total,
    required this.visible,
    required this.isLoading,
    required this.onRefresh,
    required this.searchBox,
    this.splitPane = false,
    this.onToggleSplitPane,
    this.trailingActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: 50,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Text(
                  '$total $entityName${total != visible ? " ($visible shown)" : ""}',
                  style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),
                ),
                const SizedBox(width: 4),
                if (isLoading)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (!isLoading)
                  MovingTooltipWidget.text(
                    message: "Refresh",
                    child: Disable(
                      isEnabled: !isLoading,
                      child: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: onRefresh,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                ExpandingConstrainedAlignedWidget(
                  alignment: Alignment.centerRight,
                  child: searchBox,
                ),
                const SizedBox(width: 8),
                if (onToggleSplitPane != null)
                  MovingTooltipWidget.text(
                    message:
                        "Split to show two displays that can be scrolled independently.",
                    child: TriOSToolbarCheckboxButton(
                      text: "Compare Mode",
                      value: splitPane,
                      onChanged: (_) => onToggleSplitPane!(),
                    ),
                  ),
                ...trailingActions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
