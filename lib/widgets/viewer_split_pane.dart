import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

/// Shared MultiSplitView wrapper with consistent divider styling for viewer pages.
class ViewerSplitPane extends StatelessWidget {
  final MultiSplitViewController controller;
  final Widget Function(String areaId) gridBuilder;

  const ViewerSplitPane({
    super.key,
    required this.controller,
    required this.gridBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: MultiSplitViewTheme(
        data: MultiSplitViewThemeData(
          dividerThickness: 16,
          dividerPainter: DividerPainters.dashed(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            highlightedColor: theme.colorScheme.onSurface,
            highlightedThickness: 2,
            gap: 1,
          ),
        ),
        child: MultiSplitView(
          controller: controller,
          axis: Axis.vertical,
          builder: (context, area) {
            final id = area.id as String?;
            if (id == null) return const SizedBox.shrink();
            return gridBuilder(id);
          },
        ),
      ),
    );
  }
}
