import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/widgets/background_effects/background_effect.dart';

/// The original flocking "motes" — drifting glitter that swarms Boids-style,
/// mirroring the in-game motes' `doFlocking` (see MoteAI.java): separation,
/// alignment, cohesion, and a breathing pulse on the separation range. The
/// game's attractor pull is replaced by a slow sine "wind", and its "stay near
/// the source ship" rule by soft containment within the canvas bounds.
class MotesEffect implements BackgroundEffect {
  /// Overall speed multiplier applied to [_maxSpeedBase].
  final double speed;

  /// Cohesion strength multiplier — how tightly motes pull together.
  final double clustering;

  /// Particle density multiplier.
  final double coverage;

  MotesEffect({
    required this.speed,
    required this.clustering,
    required this.coverage,
  });

  // Number of particles in the pool. The active count drawn/simulated scales
  // with canvas area and [coverage] up to this cap.
  static const int _maxParticles = 300;

  // Flocking tuning. These were the original GlitterBackground defaults; no
  // caller varied them, so they live here as constants now.
  static const double _maxSpeedBase = 45.0;
  static const double _separationRange = 16.0;
  static const double _alignmentRange = 55.0;
  static const double _cohesionRange = 75.0;
  static const double _separationWeight = 90.0;
  static const double _alignmentWeight = 12.0;
  static const double _cohesionWeight = 10.0;
  static const double _windWeight = 25.0;
  static const double _boundaryWeight = 220.0;
  static const double _boundaryMargin = 48.0;
  static const double _cursorRange = 90.0;
  static const double _cursorWeight = 320.0;

  List<_MoteParticle> _particles = const [];
  final _paint = Paint()..style = PaintingStyle.fill;

  @override
  BackgroundStyle get style => BackgroundStyle.motes;

  @override
  bool get reactsToCursor => true;

  // Top speed a mote can drift, in pixels/second. [speed] scales it.
  double get _maxSpeed => _maxSpeedBase * speed;

  @override
  void seed(Size size, Random random) {
    _particles = List.generate(_maxParticles, (_) => _MoteParticle(random));
    for (final p in _particles) {
      p.position = Offset(
        p.normalizedX * size.width,
        p.normalizedY * size.height,
      );
      final angle = p.colorSeed * 2 * pi;
      final speed = _maxSpeed * 0.5;
      p.velocity = Offset(cos(angle), sin(angle)) * speed;
    }
  }

  @override
  void resize(Size oldSize, Size newSize) {
    if (oldSize.isEmpty || newSize.isEmpty) return;
    final sx = newSize.width / oldSize.width;
    final sy = newSize.height / oldSize.height;
    for (final p in _particles) {
      p.position = Offset(p.position.dx * sx, p.position.dy * sy);
    }
  }

  /// Advances the flock by [dt] seconds using Boids-style steering.
  @override
  void update(double dt, double elapsedSeconds, Size size, Offset? cursor) {
    if (size.isEmpty || dt <= 0 || _particles.isEmpty) return;

    final count = activeParticleCount(size, coverage, _particles.length);
    final t = elapsedSeconds;

    // Breathing pulse on the separation range, like the game's motes.
    final sepRange = _separationRange * (1.0 + sin(t) * 0.25);

    // Layered sine waves → the whole flock drifts on a slow, organic wind.
    final wind = Offset(
      sin(t * 0.7) * 0.5 + sin(t * 0.3) * 0.3,
      sin(t * 0.5 + 1.0) * 0.3 + sin(t * 0.9 + 2.0) * 0.2,
    );

    final maxSpeed = _maxSpeed;
    final minSpeed = maxSpeed * 0.25;
    final cohesionWeight = _cohesionWeight * clustering * 2.0;
    final margin = min(_boundaryMargin, size.shortestSide / 3.0);

    for (var i = 0; i < count; i++) {
      final p = _particles[i];
      var steer = Offset.zero;
      var alignVel = Offset.zero;
      var alignCount = 0;
      var cohPos = Offset.zero;
      var cohCount = 0;

      for (var j = 0; j < count; j++) {
        if (i == j) continue;
        final q = _particles[j];
        final delta = p.position - q.position;
        final dist = delta.distance;
        if (dist <= 0) continue;

        // Separation: push away from motes that are too close.
        if (dist < sepRange) {
          steer +=
              (delta / dist) *
              (_separationWeight * (1.0 - dist / sepRange));
        }
        // Alignment: match heading of nearby motes.
        if (dist < _alignmentRange) {
          alignVel += q.velocity;
          alignCount++;
        }
        // Cohesion: drift toward the local center of mass.
        if (dist < _cohesionRange) {
          cohPos += q.position;
          cohCount++;
        }
      }

      if (alignCount > 0) {
        steer +=
            _normalize(alignVel / alignCount.toDouble()) * _alignmentWeight;
      }
      if (cohCount > 0) {
        final center = cohPos / cohCount.toDouble();
        steer += _normalize(center - p.position) * cohesionWeight;
      }

      steer += wind * _windWeight;
      steer += _boundaryForce(p.position, size, margin);

      // Gently shove away from the cursor, fading out with distance.
      if (cursor != null) {
        final away = p.position - cursor;
        final dist = away.distance;
        if (dist > 0 && dist < _cursorRange) {
          final falloff = 1.0 - dist / _cursorRange;
          steer += (away / dist) * (_cursorWeight * falloff * falloff);
        }
      }

      var vel = p.velocity + steer * dt;
      final spd = vel.distance;
      if (spd > maxSpeed) {
        vel = vel / spd * maxSpeed;
      } else if (spd > 0 && spd < minSpeed) {
        vel = vel / spd * minSpeed;
      } else if (spd == 0) {
        final a = p.timeOffset;
        vel = Offset(cos(a), sin(a)) * minSpeed;
      }
      p.velocity = vel;
      p.position += vel * dt;
    }
  }

  /// Soft steering back toward the canvas when a mote nears (or passes) an edge,
  /// scaled by how far into the [margin] band it is.
  Offset _boundaryForce(Offset pos, Size size, double margin) {
    var ax = 0.0;
    var ay = 0.0;
    if (pos.dx < margin) {
      ax = (margin - pos.dx) / margin;
    } else if (pos.dx > size.width - margin) {
      ax = -(pos.dx - (size.width - margin)) / margin;
    }
    if (pos.dy < margin) {
      ay = (margin - pos.dy) / margin;
    } else if (pos.dy > size.height - margin) {
      ay = -(pos.dy - (size.height - margin)) / margin;
    }
    return Offset(ax, ay) * _boundaryWeight;
  }

  Offset _normalize(Offset o) {
    final d = o.distance;
    return d > 0 ? o / d : Offset.zero;
  }

  @override
  void paint(Canvas canvas, Size size, BackgroundPaintContext ctx) {
    if (size.isEmpty || _particles.isEmpty) return;

    final count = activeParticleCount(size, ctx.coverage, _particles.length);
    final useCircles = !ctx.isRainbow;

    for (var i = 0; i < count; i++) {
      final p = _particles[i];
      final pt = ctx.elapsedSeconds + p.timeOffset;
      final x = p.position.dx;
      final y = p.position.dy;

      final shimmer =
          0.5 + 0.5 * sin(pt * p.shimmerSpeed * 2 * pi * ctx.pulseRate);
      final opacity = (p.baseOpacity * (0.5 + 0.5 * shimmer) * ctx.opacityScale)
          .clamp(0.0, 1.0);

      final colorIndex =
          (p.colorSeed * ctx.colors.length).floor() % ctx.colors.length;
      _paint.color = ctx.colors[colorIndex].withValues(alpha: opacity);

      if (useCircles) {
        canvas.drawCircle(Offset(x, y), p.radius, _paint);
      } else {
        final rotation = p.initialRotation + pt * p.rotationSpeed;
        final path = Path();
        for (var j = 0; j < p.sides; j++) {
          final angle = rotation + (2 * pi * j / p.sides);
          final vx = x + p.radius * cos(angle);
          final vy = y + p.radius * sin(angle);
          if (j == 0) {
            path.moveTo(vx, vy);
          } else {
            path.lineTo(vx, vy);
          }
        }
        path.close();
        canvas.drawPath(path, _paint);
      }
    }
  }
}

class _MoteParticle {
  // Immutable visual traits.
  final double normalizedX;
  final double normalizedY;
  final double radius;
  final double baseOpacity;
  final double colorSeed;
  final double timeOffset;
  final double shimmerSpeed;
  final int sides;
  final double rotationSpeed;
  final double initialRotation;

  // Mutable flocking state, in canvas pixels. Seeded once the canvas size is
  // known, then integrated each frame by the flocking simulation.
  Offset position = Offset.zero;
  Offset velocity = Offset.zero;

  _MoteParticle(Random random)
    : normalizedX = random.nextDouble(),
      normalizedY = random.nextDouble(),
      radius = random.nextDouble() * 2 + 1,
      baseOpacity = random.nextDouble() * 0.3 + 0.15,
      colorSeed = random.nextDouble(),
      timeOffset = random.nextDouble() * 100,
      shimmerSpeed = random.nextDouble() * 1.5 + 0.5,
      sides = random.nextInt(2) + 3,
      rotationSpeed = (random.nextDouble() - 0.5) * 2,
      initialRotation = random.nextDouble() * 2 * pi;
}
