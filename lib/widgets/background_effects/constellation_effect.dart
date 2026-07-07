import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/widgets/background_effects/background_effect.dart';

/// Drifting points that draw a thin line between any two that are close enough —
/// the classic "network" look. Nodes bounce softly off the edges so the web
/// stays in view.
class ConstellationEffect implements BackgroundEffect {
  /// Overall speed multiplier applied to [_baseSpeed].
  final double speed;

  /// Node density multiplier.
  final double coverage;

  ConstellationEffect({required this.speed, required this.coverage});

  static const int _maxNodes = 160;
  static const double _baseSpeed = 14.0;

  // Distance (px) within which two nodes are linked by a line.
  static const double _linkDistance = 96.0;

  List<_Node> _nodes = const [];
  final _dotPaint = Paint()..style = PaintingStyle.fill;
  final _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @override
  BackgroundStyle get style => BackgroundStyle.constellation;

  @override
  bool get reactsToCursor => false;

  @override
  void seed(Size size, Random random) {
    _nodes = List.generate(_maxNodes, (_) => _Node(random));
    for (final n in _nodes) {
      n.position = Offset(
        n.normalizedX * size.width,
        n.normalizedY * size.height,
      );
    }
  }

  @override
  void resize(Size oldSize, Size newSize) {
    if (oldSize.isEmpty || newSize.isEmpty) return;
    final sx = newSize.width / oldSize.width;
    final sy = newSize.height / oldSize.height;
    for (final n in _nodes) {
      n.position = Offset(n.position.dx * sx, n.position.dy * sy);
    }
  }

  int _activeCount(Size size) =>
      activeParticleCount(size, coverage, _nodes.length, baseDensity: 1 / 8000);

  @override
  void update(double dt, double elapsedSeconds, Size size, Offset? cursor) {
    if (size.isEmpty || dt <= 0 || _nodes.isEmpty) return;

    final count = _activeCount(size);
    for (var i = 0; i < count; i++) {
      final n = _nodes[i];
      var pos = n.position + n.velocity * (_baseSpeed * speed * dt);
      var vx = n.velocity.dx;
      var vy = n.velocity.dy;

      // Reflect off the edges.
      if (pos.dx < 0) {
        pos = Offset(-pos.dx, pos.dy);
        vx = -vx;
      } else if (pos.dx > size.width) {
        pos = Offset(2 * size.width - pos.dx, pos.dy);
        vx = -vx;
      }
      if (pos.dy < 0) {
        pos = Offset(pos.dx, -pos.dy);
        vy = -vy;
      } else if (pos.dy > size.height) {
        pos = Offset(pos.dx, 2 * size.height - pos.dy);
        vy = -vy;
      }

      n.position = pos;
      n.velocity = Offset(vx, vy);
    }
  }

  @override
  void paint(Canvas canvas, Size size, BackgroundPaintContext ctx) {
    if (size.isEmpty || _nodes.isEmpty) return;

    final count = _activeCount(size);

    // Lines first, so the dots sit on top.
    for (var i = 0; i < count; i++) {
      final a = _nodes[i].position;
      for (var j = i + 1; j < count; j++) {
        final b = _nodes[j].position;
        final dist = (a - b).distance;
        if (dist >= _linkDistance) continue;
        final strength = 1.0 - dist / _linkDistance;
        final lineColor =
            ctx.colors[(i + j) % ctx.colors.length];
        _linePaint.color = lineColor.withValues(
          alpha: (0.22 * strength * ctx.opacityScale).clamp(0.0, 1.0),
        );
        canvas.drawLine(a, b, _linePaint);
      }
    }

    for (var i = 0; i < count; i++) {
      final n = _nodes[i];
      final pt = ctx.elapsedSeconds + n.timeOffset;
      final twinkle =
          0.6 + 0.4 * sin(pt * n.twinkleSpeed * 2 * pi * ctx.pulseRate);
      final colorIndex =
          (n.colorSeed * ctx.colors.length).floor() % ctx.colors.length;
      _dotPaint.color = ctx.colors[colorIndex].withValues(
        alpha: (n.baseOpacity * twinkle * ctx.opacityScale).clamp(0.0, 1.0),
      );
      canvas.drawCircle(n.position, n.radius, _dotPaint);
    }
  }
}

class _Node {
  final double normalizedX;
  final double normalizedY;
  final double radius;
  final double baseOpacity;
  final double colorSeed;
  final double twinkleSpeed;
  final double timeOffset;
  Offset velocity;
  Offset position = Offset.zero;

  factory _Node(Random random) {
    final angle = random.nextDouble() * 2 * pi;
    return _Node._(
      normalizedX: random.nextDouble(),
      normalizedY: random.nextDouble(),
      radius: random.nextDouble() * 1.2 + 1.0,
      baseOpacity: random.nextDouble() * 0.3 + 0.25,
      colorSeed: random.nextDouble(),
      twinkleSpeed: random.nextDouble() * 0.8 + 0.2,
      timeOffset: random.nextDouble() * 100,
      velocity: Offset(cos(angle), sin(angle)) * (random.nextDouble() * 0.6 + 0.4),
    );
  }

  _Node._({
    required this.normalizedX,
    required this.normalizedY,
    required this.radius,
    required this.baseOpacity,
    required this.colorSeed,
    required this.twinkleSpeed,
    required this.timeOffset,
    required this.velocity,
  });
}
