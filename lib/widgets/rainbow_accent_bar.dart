import 'package:flutter/material.dart';
import 'package:trios/trios/constants_theme.dart';

/// Rainbow pride colors shared across accent widgets.
const rainbowColors = [
  Color(0xFFFF0000), // Red
  Color(0xFFFF8C00), // Orange
  Color(0xFFFFD700), // Yellow
  Color(0xFF00C853), // Green
  Color(0xFF2979FF), // Blue
  Color(0xFFAA00FF), // Violet
];

/// Wraps a child widget with a rainbow gradient border.
class RainbowBorder extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final double alpha;

  const RainbowBorder({
    super.key,
    required this.child,
    this.borderWidth = 2.0,
    this.borderRadius = TriOSThemeConstants.cornerRadius,
    this.alpha = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: alpha == 1.0
              ? rainbowColors
              : rainbowColors
                    .map((color) => color.withValues(alpha: alpha))
                    .toList(),
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: child,
      ),
    );
  }
}
