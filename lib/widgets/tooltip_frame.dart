import 'package:flutter/material.dart';

import '../themes/theme_manager.dart';

class TooltipFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;

  const TooltipFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.cardColor,
          borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
          border: Border.all(color: borderColor ?? theme.colorScheme.secondary),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              // Adjust shadow color and opacity as needed
              blurRadius: 10,
              // Adjust blur radius for the shadow effect
              offset: const Offset(
                0,
                4,
              ), // Adjust offset for the shadow position
            ),
          ],
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
