import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/widgets/background_effects/background_effect.dart';

/// Flickering specks that drift slowly upward with a gentle side-to-side wobble,
/// like embers off a fire or dust in a sunbeam. Warmer and cozier than the cool
/// glitter. Specks that leave the top wrap back to the bottom.
class EmbersEffect implements BackgroundEffect {
  /// Overall speed multiplier applied to [_baseRise].
  final double speed;

  /// Particle density multiplier.
  final double coverage;

  EmbersEffect({required this.speed, required this.coverage});

  static const int _maxEmbers = 300;

  // Rise speed in pixels/second, before [speed] scaling.
  static const double _baseRise = 20.0;

  List<_Ember> _embers = const [];
  final _paint = Paint()..style = PaintingStyle.fill;

  @override
  BackgroundStyle get style => BackgroundStyle.embers;

  @override
  bool get reactsToCursor => false;

  @override
  void seed(Size size, Random random) {
    _embers = List.generate(_maxEmbers, (_) => _Ember(random));
    for (final e in _embers) {
      e.y = e.normalizedY * size.height;
    }
  }

  @override
  void resize(Size oldSize, Size newSize) {
    if (oldSize.isEmpty || newSize.isEmpty) return;
    final sy = newSize.height / oldSize.height;
    for (final e in _embers) {
      e.y *= sy;
    }
  }

  @override
  void update(double dt, double elapsedSeconds, Size size, Offset? cursor) {
    if (size.isEmpty || dt <= 0 || _embers.isEmpty) return;

    final rise = _baseRise * speed;
    for (final e in _embers) {
      e.y -= rise * e.riseFactor * dt;
      if (e.y < -e.radius) {
        e.y = size.height + e.radius;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size, BackgroundPaintContext ctx) {
    if (size.isEmpty || _embers.isEmpty) return;

    final count = activeParticleCount(size, ctx.coverage, _embers.length);
    for (var i = 0; i < count; i++) {
      final e = _embers[i];
      final pt = ctx.elapsedSeconds + e.timeOffset;
      final wobble = sin(pt * e.wobbleFreq) * e.wobbleAmp;
      final x = e.normalizedX * size.width + wobble;

      final flicker = 0.5 + 0.5 * sin(pt * e.flickerSpeed * 2 * pi * ctx.pulseRate);
      final opacity = (e.baseOpacity * flicker * ctx.opacityScale)
          .clamp(0.0, 1.0);

      final colorIndex =
          (e.colorSeed * ctx.colors.length).floor() % ctx.colors.length;
      _paint.color = ctx.colors[colorIndex].withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, e.y), e.radius, _paint);
    }
  }
}

class _Ember {
  final double normalizedX;
  final double normalizedY;
  final double radius;
  final double baseOpacity;
  final double colorSeed;
  final double riseFactor;
  final double wobbleAmp;
  final double wobbleFreq;
  final double flickerSpeed;
  final double timeOffset;

  double y = 0;

  _Ember(Random random)
    : normalizedX = random.nextDouble(),
      normalizedY = random.nextDouble(),
      radius = random.nextDouble() * 1.4 + 0.6,
      baseOpacity = random.nextDouble() * 0.35 + 0.2,
      colorSeed = random.nextDouble(),
      riseFactor = random.nextDouble() * 0.7 + 0.5,
      wobbleAmp = random.nextDouble() * 6 + 2,
      wobbleFreq = random.nextDouble() * 1.2 + 0.4,
      flickerSpeed = random.nextDouble() * 1.5 + 0.5,
      timeOffset = random.nextDouble() * 100;
}
