import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/widgets/background_effects/background_effect.dart';

/// Faint grid-aligned traces with bright pulses of light running along them,
/// like current in a wire — a launcher/"OS" feel. Pulses loop around each trace.
class CircuitryEffect implements BackgroundEffect {
  /// Overall speed multiplier applied to each pulse's travel speed.
  final double speed;

  /// Trace density multiplier.
  final double coverage;

  CircuitryEffect({required this.speed, required this.coverage});

  static const double _gridSize = 44.0;
  static const int _maxWires = 60;

  List<_Wire> _wires = const [];

  @override
  BackgroundStyle get style => BackgroundStyle.circuitry;

  @override
  bool get reactsToCursor => false;

  @override
  void seed(Size size, Random random) {
    final cols = max(2, (size.width / _gridSize).floor());
    final rows = max(2, (size.height / _gridSize).floor());
    final wireCount = activeParticleCount(
      size,
      coverage,
      _maxWires,
      baseDensity: 1 / 16000,
    ).clamp(4, _maxWires);

    _wires = List.generate(
      wireCount,
      (_) => _Wire.random(random, cols, rows, _gridSize),
    );
  }

  @override
  void resize(Size oldSize, Size newSize) {
    if (oldSize.isEmpty || newSize.isEmpty) return;
    final sx = newSize.width / oldSize.width;
    final sy = newSize.height / oldSize.height;
    for (final w in _wires) {
      w.rescale(sx, sy);
    }
  }

  @override
  void update(double dt, double elapsedSeconds, Size size, Offset? cursor) {
    if (dt <= 0 || _wires.isEmpty) return;
    for (final w in _wires) {
      if (w.total <= 0) continue;
      w.pulsePos = (w.pulsePos + w.pulseSpeed * speed * dt) % w.total;
    }
  }

  @override
  void paint(Canvas canvas, Size size, BackgroundPaintContext ctx) {
    if (size.isEmpty || _wires.isEmpty) return;

    final tracePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final pulsePaint = Paint()..style = PaintingStyle.fill;

    for (final w in _wires) {
      if (w.total <= 0) continue;

      final color = ctx.colors[w.colorIndex % ctx.colors.length];

      // The faint trace.
      final path = Path()..moveTo(w.points.first.dx, w.points.first.dy);
      for (var i = 1; i < w.points.length; i++) {
        path.lineTo(w.points[i].dx, w.points[i].dy);
      }
      tracePaint.color = color.withValues(
        alpha: (0.10 * ctx.opacityScale).clamp(0.0, 1.0),
      );
      canvas.drawPath(path, tracePaint);

      // The bright pulse and a small node at each trace end.
      final head = w.pointAt(w.pulsePos);
      pulsePaint.color = color.withValues(
        alpha: (0.7 * ctx.opacityScale).clamp(0.0, 1.0),
      );
      canvas.drawCircle(head, 2.2, pulsePaint);
      pulsePaint.color = color.withValues(
        alpha: (0.25 * ctx.opacityScale).clamp(0.0, 1.0),
      );
      canvas.drawCircle(w.points.last, 1.6, pulsePaint);
    }
  }
}

class _Wire {
  final List<Offset> points;
  final List<double> _cumulative; // arc length at each point
  double total;
  final double pulseSpeed; // pixels/second, before speed scaling
  final int colorIndex;
  double pulsePos = 0;

  _Wire(this.points, this.pulseSpeed, this.colorIndex)
    : _cumulative = _lengths(points),
      total = _lengths(points).last;

  factory _Wire.random(Random random, int cols, int rows, double grid) {
    // A grid-aligned random walk that turns 90° at each step.
    var cx = random.nextInt(cols + 1);
    var cy = random.nextInt(rows + 1);
    final points = <Offset>[Offset(cx * grid, cy * grid)];
    var horizontal = random.nextBool();
    final segments = random.nextInt(4) + 3;

    for (var s = 0; s < segments; s++) {
      final len = random.nextInt(3) + 1;
      final dir = random.nextBool() ? 1 : -1;
      if (horizontal) {
        cx = (cx + dir * len).clamp(0, cols);
      } else {
        cy = (cy + dir * len).clamp(0, rows);
      }
      final next = Offset(cx * grid, cy * grid);
      if (next != points.last) points.add(next);
      horizontal = !horizontal;
    }

    return _Wire(
      points,
      random.nextDouble() * 50 + 40,
      random.nextInt(1 << 16),
    );
  }

  static List<double> _lengths(List<Offset> pts) {
    final out = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      out.add(out.last + (pts[i] - pts[i - 1]).distance);
    }
    return out;
  }

  void rescale(double sx, double sy) {
    for (var i = 0; i < points.length; i++) {
      points[i] = Offset(points[i].dx * sx, points[i].dy * sy);
    }
    final lens = _lengths(points);
    for (var i = 0; i < lens.length; i++) {
      _cumulative[i] = lens[i];
    }
    total = lens.last;
    if (total > 0) pulsePos %= total;
  }

  /// The point at arc-length [pos] along the trace.
  Offset pointAt(double pos) {
    if (points.length < 2 || total <= 0) return points.first;
    for (var i = 1; i < points.length; i++) {
      if (pos <= _cumulative[i]) {
        final segLen = _cumulative[i] - _cumulative[i - 1];
        final t = segLen > 0 ? (pos - _cumulative[i - 1]) / segLen : 0.0;
        return Offset.lerp(points[i - 1], points[i], t)!;
      }
    }
    return points.last;
  }
}
