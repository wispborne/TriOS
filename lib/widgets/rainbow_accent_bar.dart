import 'package:flutter/material.dart';

/// Rainbow pride colors shared across accent widgets.
const _rainbowColors = [
  Color(0xFFFF0000), // Red
  Color(0xFFFF8C00), // Orange
  Color(0xFFFFD700), // Yellow
  Color(0xFF00C853), // Green
  Color(0xFF2979FF), // Blue
  Color(0xFFAA00FF), // Violet
];

/// A thin bar with a rainbow gradient, used as an accent for pride themes.
class RainbowAccentBar extends StatelessWidget {
  final Axis axis;
  final double thickness;

  const RainbowAccentBar({
    super.key,
    required this.axis,
    this.thickness = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: axis == Axis.vertical ? thickness : double.infinity,
      height: axis == Axis.horizontal ? thickness : double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _rainbowColors,
          begin: axis == Axis.vertical
              ? Alignment.topCenter
              : Alignment.centerLeft,
          end: axis == Axis.vertical
              ? Alignment.bottomCenter
              : Alignment.centerRight,
        ),
      ),
    );
  }
}

/// Wraps a child widget with a rainbow gradient border.
class RainbowBorder extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;

  const RainbowBorder({
    super.key,
    required this.child,
    this.borderWidth = 2.0,
    this.borderRadius = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: _rainbowColors),
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
