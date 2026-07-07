import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/widgets/background_effects/background_effect.dart';

/// A slow sweep line rotating from the center, with faint range rings and blips
/// that flare as the sweep passes over them and then fade — a sonar / sensor
/// ping. Cheap and resolution-independent.
class RadarEffect implements BackgroundEffect {
  /// Overall speed multiplier applied to [_sweepSpeed].
  final double speed;

  /// Blip density multiplier.
  final double coverage;

  RadarEffect({required this.speed, required this.coverage});

  // Sweep rate in radians/second, before [speed] scaling.
  static const double _sweepSpeed = 0.6;

  // How far behind the sweep (radians) a blip stays lit before fading out.
  static const double _fadeWindow = 1.4;

  static const int _maxBlips = 120;
  static const double _trail = 0.7;

  List<_Blip> _blips = const [];

  @override
  BackgroundStyle get style => BackgroundStyle.radar;

  @override
  bool get reactsToCursor => false;

  @override
  void seed(Size size, Random random) {
    _blips = List.generate(_maxBlips, (_) => _Blip(random));
  }

  @override
  void resize(Size oldSize, Size newSize) {}

  @override
  void update(double dt, double elapsedSeconds, Size size, Offset? cursor) {}

  @override
  void paint(Canvas canvas, Size size, BackgroundPaintContext ctx) {
    if (size.isEmpty || _blips.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxR = sqrt(
      center.dx * center.dx + center.dy * center.dy,
    );
    final sweep = (ctx.elapsedSeconds * _sweepSpeed * speed) % (2 * pi);
    final color = ctx.colors.first;

    // Range rings.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = color.withValues(alpha: (0.10 * ctx.opacityScale).clamp(0.0, 1.0));
    for (final f in const [0.34, 0.67, 1.0]) {
      canvas.drawCircle(center, maxR * f, ringPaint);
    }

    // Trailing wedge behind the leading edge.
    final wedge = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: maxR),
        sweep - _trail,
        _trail,
        false,
      )
      ..close();
    canvas.drawPath(
      wedge,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(
          alpha: (0.07 * ctx.opacityScale).clamp(0.0, 1.0),
        ),
    );

    // Leading sweep line.
    canvas.drawLine(
      center,
      center + Offset(cos(sweep), sin(sweep)) * maxR,
      Paint()
        ..strokeWidth = 1.4
        ..color = color.withValues(
          alpha: (0.35 * ctx.opacityScale).clamp(0.0, 1.0),
        ),
    );

    // Blips: bright right after the sweep passes, then dim to a faint resting glow.
    final blipPaint = Paint()..style = PaintingStyle.fill;
    final count = activeParticleCount(
      size,
      coverage,
      _blips.length,
      baseDensity: 1 / 12000,
    );
    for (var i = 0; i < count; i++) {
      final b = _blips[i];
      final pos = Offset(b.normalizedX * size.width, b.normalizedY * size.height);
      final angle = atan2(pos.dy - center.dy, pos.dx - center.dx);
      final behind = ((sweep - angle) % (2 * pi) + 2 * pi) % (2 * pi);
      final fresh = behind < _fadeWindow ? 1.0 - behind / _fadeWindow : 0.0;
      final glow = 0.15 + 0.85 * fresh;

      final colorIndex =
          (b.colorSeed * ctx.colors.length).floor() % ctx.colors.length;
      blipPaint.color = ctx.colors[colorIndex].withValues(
        alpha: (b.baseOpacity * glow * ctx.opacityScale).clamp(0.0, 1.0),
      );
      canvas.drawCircle(pos, b.radius + fresh * 1.5, blipPaint);
    }
  }
}

class _Blip {
  final double normalizedX;
  final double normalizedY;
  final double radius;
  final double baseOpacity;
  final double colorSeed;

  _Blip(Random random)
    : normalizedX = random.nextDouble(),
      normalizedY = random.nextDouble(),
      radius = random.nextDouble() * 1.3 + 0.8,
      baseOpacity = random.nextDouble() * 0.3 + 0.3,
      colorSeed = random.nextDouble();
}
