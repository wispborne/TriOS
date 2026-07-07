import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/widgets/background_effects/background_effect.dart';

/// Thin streaks falling with a faint trail. Reads as rain on a window; with the
/// rainbow palette the streaks take on the theme's colors. Drops that fall past
/// the bottom wrap back to the top.
class RainEffect implements BackgroundEffect {
  /// Overall speed multiplier applied to [_baseFall].
  final double speed;

  /// Drop density multiplier.
  final double coverage;

  RainEffect({required this.speed, required this.coverage});

  static const int _maxDrops = 300;

  // Fall speed in pixels/second, before [speed] scaling.
  static const double _baseFall = 260.0;

  List<_Drop> _drops = const [];
  final _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  BackgroundStyle get style => BackgroundStyle.rain;

  @override
  bool get reactsToCursor => false;

  @override
  void seed(Size size, Random random) {
    _drops = List.generate(_maxDrops, (_) => _Drop(random));
    for (final d in _drops) {
      d.position = Offset(
        d.normalizedX * size.width,
        d.normalizedY * size.height,
      );
    }
  }

  @override
  void resize(Size oldSize, Size newSize) {
    if (oldSize.isEmpty || newSize.isEmpty) return;
    final sx = newSize.width / oldSize.width;
    final sy = newSize.height / oldSize.height;
    for (final d in _drops) {
      d.position = Offset(d.position.dx * sx, d.position.dy * sy);
    }
  }

  @override
  void update(double dt, double elapsedSeconds, Size size, Offset? cursor) {
    if (size.isEmpty || dt <= 0 || _drops.isEmpty) return;

    final fall = _baseFall * speed;
    for (final d in _drops) {
      var y = d.position.dy + fall * d.speedFactor * dt;
      if (y - d.length > size.height) {
        y = -d.length;
      }
      d.position = Offset(d.position.dx, y);
    }
  }

  @override
  void paint(Canvas canvas, Size size, BackgroundPaintContext ctx) {
    if (size.isEmpty || _drops.isEmpty) return;

    final count = activeParticleCount(size, ctx.coverage, _drops.length);
    for (var i = 0; i < count; i++) {
      final d = _drops[i];
      final head = d.position;
      final tail = Offset(head.dx, head.dy - d.length);

      final colorIndex =
          (d.colorSeed * ctx.colors.length).floor() % ctx.colors.length;
      final color = ctx.colors[colorIndex];
      final alpha = (d.baseOpacity * ctx.opacityScale).clamp(0.0, 1.0);

      // Bright head fading to a transparent tail.
      _paint
        ..strokeWidth = d.thickness
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromPoints(tail, head));
      canvas.drawLine(tail, head, _paint);
    }
  }
}

class _Drop {
  final double normalizedX;
  final double normalizedY;
  final double length;
  final double thickness;
  final double speedFactor;
  final double baseOpacity;
  final double colorSeed;

  Offset position = Offset.zero;

  _Drop(Random random)
    : normalizedX = random.nextDouble(),
      normalizedY = random.nextDouble(),
      length = random.nextDouble() * 14 + 8,
      thickness = random.nextDouble() * 0.8 + 0.6,
      speedFactor = random.nextDouble() * 0.6 + 0.7,
      baseOpacity = random.nextDouble() * 0.3 + 0.2,
      colorSeed = random.nextDouble();
}
