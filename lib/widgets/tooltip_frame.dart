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
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}
