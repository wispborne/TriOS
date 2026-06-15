import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:trios/catalog/side_rail/side_rail_panel.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Minimum width (logical pixels) before the panel snap-collapses.
const double kSideRailPanelMinWidth = 400;

/// Minimum width (logical pixels) the content area must retain.
/// Matches one column of `WispAdaptiveGridView` at its `minItemWidth`.
const double kSideRailContentMinWidth = 390;

/// Width of the vertical tab rail on the right edge.
const double kSideRailStripWidth = 32;

/// IDE-style right-side rail with a collapsible tool panel.
///
/// The rail strip is always visible and shows one tab per registered
/// [SideRailPanel]. Clicking a tab toggles the panel open/closed. Only
/// one panel is open at a time.
///
/// This widget is a controlled component: parent owns the [openPanelId]
/// and [panelWidth] state and wires the callbacks.
class SideRail extends StatefulWidget {
  final List<SideRailPanel> panels;
  final String? openPanelId;
  final double panelWidth;
  final WidgetBuilder contentBuilder;
  final void Function(String id) onPanelToggled;
  final void Function(double width) onPanelResized;
  final VoidCallback onPanelSnapCollapsed;

  /// Horizontal gap (logical pixels) between the main area (content + optional
  /// panel) and the rail tab strip.
  final double railSpacing;

  const SideRail({
    super.key,
    required this.panels,
    required this.openPanelId,
    required this.panelWidth,
    required this.contentBuilder,
    required this.onPanelToggled,
    required this.onPanelResized,
    required this.onPanelSnapCollapsed,
    this.railSpacing = 0,
  });

  @override
  State<SideRail> createState() => _SideRailState();
}

class _SideRailState extends State<SideRail> {
  MultiSplitViewController? _controller;
  String? _wiredPanelId;
  double? _wiredPanelWidth;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Build (or rebuild) the split controller when panel identity or width changes.
  void _ensureController() {
    final openId = widget.openPanelId;
    if (openId == null) {
      _controller?.dispose();
      _controller = null;
      _wiredPanelId = null;
      _wiredPanelWidth = null;
      return;
    }

    // If already wired for this panel+width, reuse.
    if (_controller != null &&
        _wiredPanelId == openId &&
        _wiredPanelWidth == widget.panelWidth) {
      return;
    }

    _controller?.dispose();
    _controller = MultiSplitViewController(
      areas: [
        Area(id: 'content', flex: 1, min: kSideRailContentMinWidth),
        Area(id: 'panel', size: widget.panelWidth),
      ],
    );
    _wiredPanelId = openId;
    _wiredPanelWidth = widget.panelWidth;
  }

  @override
  Widget build(BuildContext context) {
    _ensureController();
    final theme = Theme.of(context);

    final openId = widget.openPanelId;
    final openPanel = openId == null
        ? null
        : widget.panels.firstWhere(
            (p) => p.id == openId,
            orElse: () => widget.panels.first,
          );

    final mainArea = openPanel == null
        ? widget.contentBuilder(context)
        : MultiSplitViewTheme(
            data: MultiSplitViewThemeData(
              dividerThickness: 16,
              dividerPainter: DividerPainters.dashed(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                highlightedColor: theme.colorScheme.onSurface,
                highlightedThickness: 2,
                gap: 1,
                animationDuration: const Duration(milliseconds: 100),
              ),
            ),
            child: MultiSplitView(
              controller: _controller,
              axis: Axis.horizontal,
              onDividerDragEnd: (_) => _handleDragEnd(),
              builder: (context, area) {
                if (area.id == 'content') {
                  return widget.contentBuilder(context);
                }
                if (area.id == 'panel') {
                  return openPanel.builder(context);
                }
                return const SizedBox.shrink();
              },
            ),
          );

    return Row(
      children: [
        Expanded(child: mainArea),
        if (widget.railSpacing > 0) SizedBox(width: widget.railSpacing),
        _buildRailStrip(theme),
      ],
    );
  }

  void _handleDragEnd() {
    final controller = _controller;
    if (controller == null) return;
    final panelArea = controller.areas.firstWhere(
      (a) => a.id == 'panel',
      orElse: () => Area(id: 'panel', size: widget.panelWidth),
    );
    final newSize = panelArea.size;
    if (newSize == null) return;

    if (newSize < kSideRailPanelMinWidth) {
      widget.onPanelSnapCollapsed();
    } else if ((newSize - widget.panelWidth).abs() > 0.5) {
      widget.onPanelResized(newSize);
    }
  }

  Widget _buildRailStrip(ThemeData theme) {
    return Container(
      width: kSideRailStripWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final panel in widget.panels)
            _RailTab(
              panel: panel,
              isActive: panel.id == widget.openPanelId,
              onTap: () => widget.onPanelToggled(panel.id),
            ),
        ],
      ),
    );
  }
}

class _RailTab extends StatelessWidget {
  final SideRailPanel panel;
  final bool isActive;
  final VoidCallback onTap;

  const _RailTab({
    required this.panel,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isActive
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;
    final fg = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return MovingTooltipWidget.text(
      message: isActive ? 'Hide ${panel.label}' : 'Show ${panel.label}',
      child: Material(
        color: bg,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: kSideRailStripWidth,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(panel.icon, size: 18, color: fg),
                const SizedBox(height: 6),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    panel.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: fg,
                      fontWeight: isActive ? FontWeight.w600 : null,
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
