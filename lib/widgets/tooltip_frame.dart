import 'package:flutter/material.dart';

import '../themes/theme_manager.dart';

class TooltipFrame extends StatelessWidget {
  final Widget child;

  const TooltipFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(ThemeManager.cornerRadius),
          border: Border.all(color: theme.colorScheme.onSurface),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              // Adjust shadow color and opacity as needed
              blurRadius: 10,
              // Adjust blur radius for the shadow effect
              offset: const Offset(0, 4), // Adjust offset for the shadow position
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}
