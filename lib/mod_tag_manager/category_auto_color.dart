import 'dart:math';

import 'package:flutter/painting.dart';

import 'category.dart';

/// Predefined palette of visually distinct colors for categories.
const List<Color> categoryColorPalette = [
  Color(0xFF4CAF50), // Green
  Color(0xFF2196F3), // Blue
  Color(0xFFFF9800), // Orange
  Color(0xFF9C27B0), // Purple
  Color(0xFFE91E63), // Pink
  Color(0xFF009688), // Teal
  Color(0xFFFF5722), // Deep Orange
  Color(0xFF3F51B5), // Indigo
  Color(0xFFCDDC39), // Lime
  Color(0xFF00BCD4), // Cyan
  Color(0xFF795548), // Brown
  Color(0xFF607D8B), // Blue Grey
];

/// Picks an auto-color for a new category that is visually distinct
/// from existing category colors.
Color pickAutoColor(List<Category> existingCategories) {
  final usedColors =
      existingCategories.map((c) => c.color).whereType<Color>().toList();

  if (usedColors.isEmpty) return categoryColorPalette.first;

  // Try to find an unused palette color.
  for (final color in categoryColorPalette) {
    if (!usedColors.any((c) => _colorDistance(c, color) < 30)) {
      return color;
    }
  }

  // Fallback: find the largest gap in the hue spectrum and place a color there.
  return _pickByHueGap(usedColors);
}

/// Computes a simple distance between two colors in HSL hue space.
double _colorDistance(Color a, Color b) {
  final hslA = HSLColor.fromColor(a);
  final hslB = HSLColor.fromColor(b);
  final hueDiff = (hslA.hue - hslB.hue).abs();
  return min(hueDiff, 360 - hueDiff);
}

/// Finds the largest gap in the hue spectrum of existing colors
/// and returns a color at the midpoint.
Color _pickByHueGap(List<Color> usedColors) {
  final hues = usedColors.map((c) => HSLColor.fromColor(c).hue).toList()
    ..sort();

  double maxGap = 0;
  double gapStart = 0;
  for (var i = 0; i < hues.length; i++) {
    final next = i + 1 < hues.length ? hues[i + 1] : hues[0] + 360;
    final gap = next - hues[i];
    if (gap > maxGap) {
      maxGap = gap;
      gapStart = hues[i];
    }
  }

  final newHue = (gapStart + maxGap / 2) % 360;
  return HSLColor.fromAHSL(1.0, newHue, 0.55, 0.55).toColor();
}
