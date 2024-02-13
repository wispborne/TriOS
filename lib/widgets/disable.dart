import 'package:flutter/material.dart';

class Disable extends StatelessWidget {
  final Widget child;
  final bool isEnabled;

  const Disable({super.key, required this.child, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isEnabled, // Disables interaction
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5, // Grays out when disabled
          child: child,
        ),
      ),
    );
  }
}
