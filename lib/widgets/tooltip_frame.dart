import 'package:flutter/material.dart';

import '../trios/trios_theme.dart';

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
          borderRadius: BorderRadius.circular(TriOSTheme.cornerRadius),
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
