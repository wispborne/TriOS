import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/widgets/background_effects/background_effect.dart';

/// Slow, soft curtains of theme color that wave and overlap — northern lights.
/// The ribbons run along the surface's long axis (down a tall sidebar, across a
/// wide toolbar) and their translucent overlap gives the glow. No particles, so
/// it's cheap and resolution-independent.
class AuroraEffect implements BackgroundEffect {
  /// Overall speed multiplier applied to each ribbon's wave rate.
  final double speed;

  AuroraEffect({required this.speed});

  static const int _ribbonCount = 5;
  static const double _baseAlpha = 0.11;

  // Points sampled along the long axis when tracing a ribbon.
  static const int _samples = 24;

  List<_Ribbon> _ribbons = const [];

  @override
  BackgroundStyle get style => BackgroundStyle.aurora;

  @override
  bool get reactsToCursor => false;

  @override
  void seed(Size size, Random random) {
    _ribbons = List.generate(_ribbonCount, (i) => _Ribbon(random, i));
  }

  @override
  void resize(Size oldSize, Size newSize) {}

  @override
  void update(double dt, double elapsedSeconds, Size size, Offset? cursor) {}

  @override
  void paint(Canvas canvas, Size size, BackgroundPaintContext ctx) {
    if (size.isEmpty || _ribbons.isEmpty) return;

    final t = ctx.elapsedSeconds;
    final vertical = size.height >= size.width;
    final longSize = vertical ? size.height : size.width;
    final crossSize = vertical ? size.width : size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final r in _ribbons) {
      final halfWidth = r.widthFrac * crossSize * 0.5;

      // Where the ribbon's center sits along the cross axis, as u runs 0..1
      // along the long axis.
      double center(double u) {
        final wave =
            r.amp1 * sin(u * r.k1 * 2 * pi + t * r.s1 * speed + r.phase) +
            r.amp2 * sin(u * r.k2 * 2 * pi + t * r.s2 * speed);
        return (r.base + wave).clamp(0.05, 0.95) * crossSize;
      }

      Offset at(double along, double cross) =>
          vertical ? Offset(cross, along) : Offset(along, cross);

      final path = Path();
      for (var i = 0; i <= _samples; i++) {
        final u = i / _samples;
        final along = u * longSize;
        final c = center(u);
        final p = at(along, c - halfWidth);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      for (var i = _samples; i >= 0; i--) {
        final u = i / _samples;
        final along = u * longSize;
        final c = center(u);
        final p = at(along, c + halfWidth);
        path.lineTo(p.dx, p.dy);
      }
      path.close();

      final pulse = 0.6 + 0.4 * sin(t * r.pulseSpeed * speed + r.pulsePhase);
      final alpha = (_baseAlpha * pulse * ctx.opacityScale).clamp(0.0, 1.0);
      paint.color = ctx.colors[r.colorIndex % ctx.colors.length].withValues(
        alpha: alpha,
      );
      canvas.drawPath(path, paint);
    }
  }
}

class _Ribbon {
  final double base; // center position along cross axis, normalized 0..1
  final double widthFrac; // ribbon width as a fraction of the cross axis
  final double amp1;
  final double amp2;
  final double k1; // spatial wave count along the long axis
  final double k2;
  final double s1; // temporal wave rate
  final double s2;
  final double phase;
  final double pulseSpeed;
  final double pulsePhase;
  final int colorIndex;

  _Ribbon(Random random, this.colorIndex)
    : base = random.nextDouble() * 0.6 + 0.2,
      widthFrac = random.nextDouble() * 0.25 + 0.2,
      amp1 = random.nextDouble() * 0.12 + 0.06,
      amp2 = random.nextDouble() * 0.06 + 0.02,
      k1 = random.nextDouble() * 1.5 + 0.5,
      k2 = random.nextDouble() * 2.5 + 1.0,
      s1 = random.nextDouble() * 0.4 + 0.2,
      s2 = random.nextDouble() * 0.5 + 0.2,
      phase = random.nextDouble() * 2 * pi,
      pulseSpeed = random.nextDouble() * 0.3 + 0.15,
      pulsePhase = random.nextDouble() * 2 * pi;
}
