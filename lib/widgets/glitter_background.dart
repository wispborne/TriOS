import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/trios/app_lifecycle_provider.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/rainbow_accent_bar.dart';

class GlitterBackground extends ConsumerStatefulWidget {
  final Widget child;

  /// Overall speed multiplier applied to [maxSpeed].
  final double speed;

  /// Cohesion strength multiplier — how tightly motes pull together.
  final double clustering;

  /// Particle density multiplier (1 particle per 4000 sq px at 1.0).
  final double coverage;

  final GlitterLocation? location;

  /// Top drift speed in pixels/second, before [speed] scaling.
  final double maxSpeed;

  /// Distance (px) within which motes push apart.
  final double separationRange;

  /// Distance (px) within which motes match each other's heading.
  final double alignmentRange;

  /// Distance (px) within which motes drift toward their local center.
  final double cohesionRange;

  /// Steering force pushing motes apart when within [separationRange].
  final double separationWeight;

  /// Steering force aligning a mote with its neighbors' heading.
  final double alignmentWeight;

  /// Steering force pulling a mote toward its local center of mass.
  final double cohesionWeight;

  /// Strength of the slow sine "wind" the whole flock drifts on.
  final double windWeight;

  /// Strength of the steering that keeps motes inside the canvas.
  final double boundaryWeight;

  /// How far (px) from each edge the containment steering begins.
  final double boundaryMargin;

  /// Whether motes are gently pushed away from the cursor.
  final bool reactToCursor;

  /// Distance (px) within which the cursor pushes motes away.
  final double cursorRange;

  /// Strength of the cursor's push on nearby motes.
  final double cursorWeight;

  /// Multiplier on each mote's brightness-shimmer rate.
  final double pulseRate;

  const GlitterBackground({
    super.key,
    required this.child,
    this.speed = 0.25,
    this.clustering = 0.5,
    this.coverage = 1.5,
    this.location,
    this.maxSpeed = 45.0,
    this.separationRange = 16.0,
    this.alignmentRange = 55.0,
    this.cohesionRange = 75.0,
    this.separationWeight = 90.0,
    this.alignmentWeight = 12.0,
    this.cohesionWeight = 10.0,
    this.windWeight = 25.0,
    this.boundaryWeight = 220.0,
    this.boundaryMargin = 48.0,
    this.reactToCursor = true,
    this.cursorRange = 90.0,
    this.cursorWeight = 320.0,
    this.pulseRate = 0.5,
  });

  @override
  ConsumerState<GlitterBackground> createState() => _GlitterBackgroundState();
}

class _GlitterBackgroundState extends ConsumerState<GlitterBackground>
    with SingleTickerProviderStateMixin {
  // Time constant (seconds) for easing motion in/out so particles don't
  // suddenly start or stop moving.
  static const double _envelopeTau = 0.6;

  late final AnimationController _controller;

  // Real wall clock, used to compute per-frame deltas. Always running.
  final Stopwatch _stopwatch = Stopwatch();
  double _lastRealSeconds = 0;

  // Warped time fed to the painter. Advances at a rate scaled by [_envelope],
  // so motion eases rather than jumping when started/stopped.
  double _animationSeconds = 0;

  // Eased motion factor, 0 (stopped) .. 1 (full speed).
  double _envelope = 0;

  // Desired motion state, toggled by app lifecycle.
  bool _motionEnabled = false;
  late final List<_GlitterParticle> _particles;
  final Random _random = Random();

  // Canvas size, captured during layout so the flocking step (which runs in the
  // tick, before paint) can work in pixel space. Particles are seeded once it's
  // first known.
  Size? _size;
  bool _seeded = false;

  // Cursor position in canvas pixels, or null when the pointer is away. Motes
  // are gently pushed away from it. Updated without setState — the running
  // animation loop reads it each frame.
  Offset? _cursor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..addListener(_tick);
    _stopwatch.start();

    _particles = List.generate(300, (_) => _GlitterParticle(_random));
  }

  @override
  void dispose() {
    _controller.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  /// Per-frame tick: advances warped time by the real delta scaled by an eased
  /// envelope. Runs before [AnimatedBuilder]'s own listener (registered first),
  /// so the painter reads a fresh [_animationSeconds].
  void _tick() {
    final now = _stopwatch.elapsedMilliseconds / 1000.0;
    // Clamp the delta so a long pause doesn't produce one giant jump.
    final dt = (now - _lastRealSeconds).clamp(0.0, 0.1);
    _lastRealSeconds = now;

    final target = _motionEnabled ? 1.0 : 0.0;
    _envelope =
        (_envelope + (target - _envelope) * (1 - exp(-dt / _envelopeTau)))
            .clamp(0.0, 1.0);
    final simDt = dt * _envelope;
    _animationSeconds += simDt;
    _simulateFlock(simDt);

    // Once fully eased out, stop ticking to save CPU.
    if (!_motionEnabled && _envelope < 0.001) {
      _envelope = 0;
      _controller.stop();
    }
  }

  /// Sets the desired motion state and keeps the controller ticking while
  /// either moving or still easing out.
  void _setMotion(bool enabled) {
    _motionEnabled = enabled;
    if ((enabled || _envelope > 0.001) && !_controller.isAnimating) {
      _lastRealSeconds = _stopwatch.elapsedMilliseconds / 1000.0;
      _controller.repeat();
    }
  }

  /// Captures the canvas size during layout. Seeds particle positions the first
  /// time the size is known, and rescales them proportionally on resize so the
  /// flock stays in view.
  void _updateSize(Size size) {
    if (size.isEmpty) {
      _size = size;
      return;
    }
    if (!_seeded) {
      for (final p in _particles) {
        p.position = Offset(
          p.normalizedX * size.width,
          p.normalizedY * size.height,
        );
        final angle = p.colorSeed * 2 * pi;
        final speed = _maxSpeed * 0.5;
        p.velocity = Offset(cos(angle), sin(angle)) * speed;
      }
      _seeded = true;
    } else {
      final old = _size;
      if (old != null && !old.isEmpty && old != size) {
        final sx = size.width / old.width;
        final sy = size.height / old.height;
        for (final p in _particles) {
          p.position = Offset(p.position.dx * sx, p.position.dy * sy);
        }
      }
    }
    _size = size;
  }

  // Top speed a mote can drift, in pixels/second. [widget.speed] scales it.
  double get _maxSpeed => widget.maxSpeed * widget.speed;

  /// Advances the flock by [dt] seconds using Boids-style steering, mirroring
  /// the in-game motes' `doFlocking` (see MoteAI.java): separation, alignment,
  /// cohesion, and a breathing pulse on the separation range. The game's
  /// attractor pull is replaced by a slow sine "wind", and its "stay near the
  /// source ship" rule by soft containment within the canvas bounds.
  void _simulateFlock(double dt) {
    final size = _size;
    if (size == null || size.isEmpty || dt <= 0 || !_seeded) return;

    final count = _activeCount(size, widget.coverage, _particles.length);
    final t = _animationSeconds;

    // Breathing pulse on the separation range, like the game's motes.
    final sepRange = widget.separationRange * (1.0 + sin(t) * 0.25);

    // Layered sine waves → the whole flock drifts on a slow, organic wind.
    final wind = Offset(
      sin(t * 0.7) * 0.5 + sin(t * 0.3) * 0.3,
      sin(t * 0.5 + 1.0) * 0.3 + sin(t * 0.9 + 2.0) * 0.2,
    );

    final maxSpeed = _maxSpeed;
    final minSpeed = maxSpeed * 0.25;
    final cohesionWeight = widget.cohesionWeight * widget.clustering * 2.0;
    final margin = min(widget.boundaryMargin, size.shortestSide / 3.0);
    final cursor = _cursor;

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
              (widget.separationWeight * (1.0 - dist / sepRange));
        }
        // Alignment: match heading of nearby motes.
        if (dist < widget.alignmentRange) {
          alignVel += q.velocity;
          alignCount++;
        }
        // Cohesion: drift toward the local center of mass.
        if (dist < widget.cohesionRange) {
          cohPos += q.position;
          cohCount++;
        }
      }

      if (alignCount > 0) {
        steer +=
            _normalize(alignVel / alignCount.toDouble()) *
            widget.alignmentWeight;
      }
      if (cohCount > 0) {
        final center = cohPos / cohCount.toDouble();
        steer += _normalize(center - p.position) * cohesionWeight;
      }

      steer += wind * widget.windWeight;
      steer += _boundaryForce(p.position, size, margin);

      // Gently shove away from the cursor, fading out with distance.
      if (cursor != null) {
        final away = p.position - cursor;
        final dist = away.distance;
        if (dist > 0 && dist < widget.cursorRange) {
          final falloff = 1.0 - dist / widget.cursorRange;
          steer += (away / dist) * (widget.cursorWeight * falloff * falloff);
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

  /// Glitter colors come from [themeKey]'s theme, or the active theme when
  /// null. The Pride theme uses the rainbow palette instead of its swatch, and
  /// renders less transparent (a higher [opacityScale]).
  ({List<Color> colors, double opacityScale, bool isRainbow}) _resolveColors(
    BuildContext context,
    String? themeKey,
  ) {
    final themeState = ref.watch(AppState.themeData).value;
    final theme = themeKey != null
        ? themeState?.availableThemes[themeKey]
        : themeState?.currentTheme;

    if (theme?.rainbowAccent == true) {
      return (colors: rainbowColors, opacityScale: 2.0, isRainbow: true);
    }

    final colorScheme = theme != null
        ? ThemeManager.convertToThemeData(theme).colorScheme
        : Theme.of(context).colorScheme;
    return (
      colors: [
        colorScheme.primary,
        colorScheme.secondary,
        colorScheme.tertiary,
      ],
      opacityScale: 1.0,
      isRainbow: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final modifiers = ref.watch(appSettings.select((s) => s.themeModifiers));
    final activeThemeId = ref.watch(AppState.themeData).value?.currentTheme.id;

    if (!modifiers.motesEnabled(activeThemeId)) return widget.child;

    final locations = modifiers.glitterLocations;
    if (widget.location != null && !locations.contains(widget.location)) {
      return widget.child;
    }

    final lifecycle = ref.watch(appLifecycleProvider);
    _setMotion(lifecycle == AppLifecycleState.resumed);

    final resolved = _resolveColors(context, modifiers.glitterThemeKey);
    final colors = resolved.colors;

    // Clip only the motes layer to the bounds, not the child. The child may
    // legitimately overflow (e.g. a blurred icon glow), and clipping it here
    // would chop that into a hard rectangle.
    //
    // MouseRegion tracks the cursor so motes can dodge it. opaque: false and
    // hover-only handlers mean it never blocks clicks or the child's own hover
    // effects/tooltips.
    return MouseRegion(
      opaque: false,
      hitTestBehavior: HitTestBehavior.translucent,
      onHover: (event) => _cursor = event.localPosition,
      onExit: (_) => _cursor = null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _updateSize(constraints.biggest);
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _GlitterPainter(
                        particles: _particles,
                        elapsedSeconds: _animationSeconds,
                        colors: colors,
                        coverage: widget.coverage,
                        opacityScale: resolved.opacityScale,
                        useCircles: !resolved.isRainbow,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
          widget.child,
        ],
      ),
    );
  }
}

class _GlitterParticle {
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

  _GlitterParticle(Random random)
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

// 1 particle per 4000 sq px at coverage 1.0.
const _baseDensity = 1.0 / 4000.0;

// Flocking tuning (pixels and pixels/second²), adapted from the game's MoteAI.
const double _separationRange = 16.0;
const double _alignmentRange = 55.0;
const double _cohesionRange = 75.0;
const double _separationWeight = 90.0;
const double _alignmentWeight = 12.0;
const double _cohesionWeight = 10.0;
const double _windWeight = 25.0;
const double _boundaryWeight = 220.0;
const double _boundaryMargin = 48.0;
const double _cursorRange = 90.0;
const double _cursorWeight = 320.0;

/// Number of particles to simulate and draw for a canvas of [size], given
/// [coverage] and the available [max].
int _activeCount(Size size, double coverage, int max) {
  final area = size.width * size.height;
  return (area * _baseDensity * coverage).round().clamp(0, max);
}

class _GlitterPainter extends CustomPainter {
  final List<_GlitterParticle> particles;
  final double elapsedSeconds;
  final List<Color> colors;
  final double coverage;
  final double opacityScale;
  final bool useCircles;
  final _paint = Paint()..style = PaintingStyle.fill;

  _GlitterPainter({
    required this.particles,
    required this.elapsedSeconds,
    required this.colors,
    required this.coverage,
    required this.opacityScale,
    required this.useCircles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final count = _activeCount(size, coverage, particles.length);

    for (var i = 0; i < count; i++) {
      final p = particles[i];
      final pt = elapsedSeconds + p.timeOffset;
      final x = p.position.dx;
      final y = p.position.dy;

      final shimmer = 0.5 + 0.5 * sin(pt * p.shimmerSpeed * pi);
      final opacity = (p.baseOpacity * (0.5 + 0.5 * shimmer) * opacityScale)
          .clamp(0.0, 1.0);

      final colorIndex = (p.colorSeed * colors.length).floor() % colors.length;
      _paint.color = colors[colorIndex].withValues(alpha: opacity);

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

  @override
  bool shouldRepaint(_GlitterPainter old) =>
      old.elapsedSeconds != elapsedSeconds ||
      old.coverage != coverage ||
      old.opacityScale != opacityScale;
}
