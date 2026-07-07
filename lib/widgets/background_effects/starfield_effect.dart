import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/widgets/background_effects/background_effect.dart';

/// Points of light drifting slowly across the surface. Bigger points drift
/// faster than smaller ones, giving a parallax "moving through space" feel.
/// Drift follows the surface's long axis (down a tall sidebar, sideways across a
/// wide toolbar), and points wrap around to the far edge. No flocking, so it's
/// cheaper than [MotesEffect].
class StarfieldEffect implements BackgroundEffect {
  /// Overall speed multiplier applied to [_baseDrift].
  final double speed;

  /// Particle density multiplier.
  final double coverage;

  StarfieldEffect({required this.speed, required this.coverage});

  static const int _maxStars = 300;

  // Top drift speed in pixels/second (for the nearest, largest stars), before
  // [speed] scaling.
  static const double _baseDrift = 22.0;

  List<_Star> _stars = const [];
  final _paint = Paint()..style = PaintingStyle.fill;

  @override
  BackgroundStyle get style => BackgroundStyle.starfield;

  @override
  bool get reactsToCursor => false;

  @override
  void seed(Size size, Random random) {
    _stars = List.generate(_maxStars, (_) => _Star(random));
    for (final s in _stars) {
      s.position = Offset(
        s.normalizedX * size.width,
        s.normalizedY * size.height,
      );
    }
  }

  @override
  void resize(Size oldSize, Size newSize) {
    if (oldSize.isEmpty || newSize.isEmpty) return;
    final sx = newSize.width / oldSize.width;
    final sy = newSize.height / oldSize.height;
    for (final s in _stars) {
      s.position = Offset(s.position.dx * sx, s.position.dy * sy);
    }
  }

  @override
  void update(double dt, double elapsedSeconds, Size size, Offset? cursor) {
    if (size.isEmpty || dt <= 0 || _stars.isEmpty) return;

    // Drift along the surface's long axis so the motion reads well in both a
    // tall sidebar and a wide toolbar.
    final horizontal = size.width >= size.height;
    final base = _baseDrift * speed;

    for (final s in _stars) {
      // Parallax: nearer (bigger) stars move faster.
      final v = base * (0.3 + 0.7 * s.depth);
      if (horizontal) {
        var x = s.position.dx + v * dt;
        if (x > size.width + s.radius) x = -s.radius;
        s.position = Offset(x, s.position.dy);
      } else {
        var y = s.position.dy + v * dt;
        if (y > size.height + s.radius) y = -s.radius;
        s.position = Offset(s.position.dx, y);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size, BackgroundPaintContext ctx) {
    if (size.isEmpty || _stars.isEmpty) return;

    final count = activeParticleCount(size, ctx.coverage, _stars.length);

    for (var i = 0; i < count; i++) {
      final s = _stars[i];
      final pt = ctx.elapsedSeconds + s.timeOffset;
      final twinkle = 0.6 + 0.4 * sin(pt * s.twinkleSpeed * 2 * pi * ctx.pulseRate);
      final opacity = (s.baseOpacity * twinkle * ctx.opacityScale)
          .clamp(0.0, 1.0);

      final colorIndex =
          (s.colorSeed * ctx.colors.length).floor() % ctx.colors.length;
      _paint.color = ctx.colors[colorIndex].withValues(alpha: opacity);
      canvas.drawCircle(s.position, s.radius, _paint);
    }
  }
}

class _Star {
  final double normalizedX;
  final double normalizedY;
  final double radius;
  final double baseOpacity;
  final double colorSeed;
  final double twinkleSpeed;
  final double timeOffset;

  // 0 (smallest/farthest) .. 1 (largest/nearest), derived from [radius].
  final double depth;

  Offset position = Offset.zero;

  factory _Star(Random random) {
    // Radius range 0.6 .. 2.4 px; depth is where it falls in that range.
    final radius = random.nextDouble() * 1.8 + 0.6;
    return _Star._(
      normalizedX: random.nextDouble(),
      normalizedY: random.nextDouble(),
      radius: radius,
      depth: (radius - 0.6) / 1.8,
      baseOpacity: random.nextDouble() * 0.35 + 0.15,
      colorSeed: random.nextDouble(),
      twinkleSpeed: random.nextDouble() * 1.2 + 0.3,
      timeOffset: random.nextDouble() * 100,
    );
  }

  _Star._({
    required this.normalizedX,
    required this.normalizedY,
    required this.radius,
    required this.depth,
    required this.baseOpacity,
    required this.colorSeed,
    required this.twinkleSpeed,
    required this.timeOffset,
  });
}
