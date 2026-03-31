import 'dart:math';

import 'package:flutter/material.dart';

/// Wraps a child widget with an animated rotating conic-gradient border
/// and optional outer glow. The gradient rotates continuously.
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final double borderRadius;
  final double borderWidth;
  final double glowStrokeWidth;
  final double glowBlur;
  final Duration duration;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    required this.colors,
    this.borderRadius = 8,
    this.borderWidth = 1.5,
    this.glowStrokeWidth = 3,
    this.glowBlur = 3,
    this.duration = const Duration(milliseconds: 4000),
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _RoundedRectGlowPainter(
            angle: _controller.value * 2 * pi,
            colors: widget.colors,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
            glowStrokeWidth: widget.glowStrokeWidth,
            glowBlur: widget.glowBlur,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Paints a rotating conic gradient border as a rounded rectangle
/// with an optional outer glow.
class _RoundedRectGlowPainter extends CustomPainter {
  final double angle;
  final List<Color> colors;
  final double borderRadius;
  final double borderWidth;
  final double glowStrokeWidth;
  final double glowBlur;

  _RoundedRectGlowPainter({
    required this.angle,
    required this.colors,
    required this.borderRadius,
    required this.borderWidth,
    required this.glowStrokeWidth,
    required this.glowBlur,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final gradient = SweepGradient(
      transform: GradientRotation(angle),
      colors: colors,
    );

    // Outer glow — blurred.
    if (glowStrokeWidth > 0) {
      final glowPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = glowStrokeWidth
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur);

      canvas.drawRRect(rrect, glowPaint);
    }

    // Crisp border.
    final borderPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(_RoundedRectGlowPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.colors != colors;
  }
}
