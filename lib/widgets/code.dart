import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A widget that styles its child like code, with monospaced font and background.
class Code extends StatelessWidget {
  /// The child widget to render inside this code-styled container.
  final Widget child;

  /// Creates a code-styled container with default text styling.
  const Code({super.key, required this.child});

  /// Builds the code widget, applying monospaced text styling and background.
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: GoogleFonts.robotoMono().copyWith(fontSize: 14),
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: child,
        ),
      ),
    );
  }
}
