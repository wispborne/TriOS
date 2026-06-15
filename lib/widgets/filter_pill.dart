import 'package:flutter/material.dart';

class FilterPill extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? deleteTooltip;

  const FilterPill({
    super.key,
    required this.label,
    required this.onDeleted,
    this.backgroundColor,
    this.foregroundColor,
    this.deleteTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.cardColor;
    final fgColor = foregroundColor ?? theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 0, 2),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: fgColor),
              ),
            ),
            Tooltip(
              message: deleteTooltip ?? 'Remove "$label"',
              child: InkWell(
                onTap: onDeleted,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Icon(Icons.close, size: 12, color: fgColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
