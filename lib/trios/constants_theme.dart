import 'package:flutter/material.dart';

/// Starsector-specific theme constants.
///
/// These are visual constants tied to the Starsector game aesthetic,
/// separated from the generic [ThemeManager] to keep it reusable.
abstract final class TriOSThemeConstants {
  static const Color vanillaErrorColor = Color.fromARGB(255, 252, 99, 0);
  static const Color vanillaWarningColor = Color.fromARGB(255, 253, 212, 24);
  static const Color vanillaCyanColor = Color(0xFFaadeff);
  static const Color vanillaYellowGoldColor = Color(0xFFDCB834);
  static const String orbitron = "Orbitron";
  static const double cornerRadius = 6;
  static final BoxShadow boxShadow = BoxShadow(
    color: Colors.black.withOpacity(0.5),
    spreadRadius: 4,
    blurRadius: 7,
    offset: const Offset(0, 3),
  );
}
