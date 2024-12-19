import 'package:flutter/material.dart';

import '../themes/theme_manager.dart';

class TooltipFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const TooltipFrame(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
          border: Border.all(color: theme.colorScheme.secondary),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              // Adjust shadow color and opacity as needed
              blurRadius: 10,
              // Adjust blur radius for the shadow effect
              offset:
                  const Offset(0, 4), // Adjust offset for the shadow position
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
