import 'package:material_ui/material_ui.dart';
import 'package:trios/widgets/filter_engine/filter_scope.dart';
import 'package:trios/widgets/filter_group_persistence/filter_group_persist_button.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';

/// The card that composite, custom and range filter groups sit in: a header
/// with the group's name, [trailing] and the lock button, then [children].
/// Clicking the header hides [children].
class CollapsibleFilterCard extends StatefulWidget {
  final String name;
  final String? tooltip;
  final FilterScope scope;
  final String groupId;
  final Map<String, Object?> Function() currentSelections;

  /// Shown right after the name while [children] are hidden, so a group never
  /// filters with nothing on screen to say so.
  final Widget? collapsedBadge;

  /// Shown between the name and the lock button, open or shut.
  final List<Widget> trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const CollapsibleFilterCard({
    super.key,
    required this.name,
    this.tooltip,
    required this.scope,
    required this.groupId,
    required this.currentSelections,
    this.collapsedBadge,
    this.trailing = const [],
    required this.children,
    this.margin = const .symmetric(horizontal: 4, vertical: 2),
    this.padding = const .all(8),
  });

  @override
  State<CollapsibleFilterCard> createState() => _CollapsibleFilterCardState();
}

class _CollapsibleFilterCardState extends State<CollapsibleFilterCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: widget.margin,
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: widget.padding,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: .circular(8),
              child: Row(
                children: [
                  // Expanded with no Spacer after it, so the name gets all the
                  // room the trailing widgets don't need.
                  Expanded(
                    child: Row(
                      spacing: 4,
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const .symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: MovingTooltipWidget.text(
                              message: widget.tooltip,
                              child: TextTriOS(
                                widget.name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!_isExpanded) ?widget.collapsedBadge,
                      ],
                    ),
                  ),
                  ...widget.trailing,
                  FilterGridPersistButton(
                    scope: widget.scope,
                    filterGroupId: widget.groupId,
                    currentSelections: widget.currentSelections,
                  ),
                ],
              ),
            ),
            if (_isExpanded) ...widget.children,
          ],
        ),
      ),
    );
  }
}
