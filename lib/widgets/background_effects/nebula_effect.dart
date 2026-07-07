import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/widgets/background_effects/background_effect.dart';

/// A few soft, slow clouds of theme color that drift and slowly bloom and fade.
/// Ambient glow rather than particles — cheap to draw, and it sits back behind
/// the UI instead of drawing the eye like [MotesEffect] does.
class NebulaEffect implements BackgroundEffect {
  /// Overall speed multiplier applied to each blob's drift and pulse rate.
  final double speed;

  NebulaEffect({required this.speed});

  static const int _blobCount = 4;
  static const double _baseAlpha = 0.14;

  List<_Blob> _blobs = const [];

  @override
  BackgroundStyle get style => BackgroundStyle.nebula;

  @override
  bool get reactsToCursor => false;

  @override
  void seed(Size size, Random random) {
    _blobs = List.generate(_blobCount, (i) => _Blob(random, i));
  }

  // Positions are normalized and recomputed from elapsed time each paint, so the
  // effect is resolution-independent — nothing to rescale or integrate.
  @override
  void resize(Size oldSize, Size newSize) {}

  @override
  void update(double dt, double elapsedSeconds, Size size, Offset? cursor) {}

  @override
  void paint(Canvas canvas, Size size, BackgroundPaintContext ctx) {
    if (size.isEmpty || _blobs.isEmpty) return;

    final t = ctx.elapsedSeconds;
    final shortest = size.shortestSide;
    final paint = Paint();

    for (final b in _blobs) {
      final cx =
          (b.cx + b.driftX * sin(t * b.speedX * speed + b.phaseX)) * size.width;
      final cy =
          (b.cy + b.driftY * sin(t * b.speedY * speed + b.phaseY)) *
          size.height;
      final center = Offset(cx, cy);
      final radius = b.radiusFactor * shortest;

      final pulse = 0.5 + 0.5 * sin(t * b.pulseSpeed * speed + b.phasePulse);
      final alpha = (_baseAlpha * pulse * ctx.opacityScale).clamp(0.0, 1.0);

      final color = ctx.colors[b.colorIndex % ctx.colors.length];
      paint.shader = RadialGradient(
        colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }
}

class _Blob {
  final double cx; // base center, normalized 0..1
  final double cy;
  final double radiusFactor; // fraction of the surface's shorter side
  final double driftX; // normalized drift amplitude
  final double driftY;
  final double speedX; // sine rate (rad/s), before [speed] scaling
  final double speedY;
  final double pulseSpeed;
  final double phaseX;
  final double phaseY;
  final double phasePulse;
  final int colorIndex;

  _Blob(Random random, this.colorIndex)
    : cx = random.nextDouble(),
      cy = random.nextDouble(),
      radiusFactor = random.nextDouble() * 0.4 + 0.5,
      driftX = random.nextDouble() * 0.1 + 0.05,
      driftY = random.nextDouble() * 0.1 + 0.05,
      speedX = random.nextDouble() * 0.1 + 0.05,
      speedY = random.nextDouble() * 0.1 + 0.05,
      pulseSpeed = random.nextDouble() * 0.2 + 0.15,
      phaseX = random.nextDouble() * 2 * pi,
      phaseY = random.nextDouble() * 2 * pi,
      phasePulse = random.nextDouble() * 2 * pi;
}
