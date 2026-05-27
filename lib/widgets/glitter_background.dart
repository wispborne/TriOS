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
  final double speed;
  final double clustering;
  final double coverage;
  final GlitterLocation? location;

  const GlitterBackground({
    super.key,
    required this.child,
    this.speed = 0.25,
    this.clustering = 0.5,
    this.coverage = 1.5,
    this.location,
  });

  @override
  ConsumerState<GlitterBackground> createState() => _GlitterBackgroundState();
}

class _GlitterBackgroundState extends ConsumerState<GlitterBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Stopwatch _stopwatch = Stopwatch();
  late final List<_GlitterParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _stopwatch.start();

    final random = Random();
    final clusterCenters = List.generate(
      5,
      (_) => Offset(random.nextDouble(), random.nextDouble()),
    );
    _particles = List.generate(
      300,
      (_) => _GlitterParticle(random, clusterCenters),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  /// Glitter colors come from [themeKey]'s theme, or the active theme when
  /// null. The Pride theme uses the rainbow palette instead of its swatch, and
  /// renders less transparent (a higher [opacityScale]).
  ({List<Color> colors, double opacityScale}) _resolveColors(
    BuildContext context,
    String? themeKey,
  ) {
    final themeState = ref.watch(AppState.themeData).value;
    final theme = themeKey != null
        ? themeState?.availableThemes[themeKey]
        : themeState?.currentTheme;

    if (theme?.id == "Pride") {
      return (colors: rainbowColors, opacityScale: 2.0);
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
    if (lifecycle != AppLifecycleState.resumed) {
      _controller.stop();
      _stopwatch.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
      _stopwatch.start();
    }

    final resolved = _resolveColors(context, modifiers.glitterThemeKey);
    final colors = resolved.colors;

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _GlitterPainter(
                    particles: _particles,
                    elapsedSeconds: _stopwatch.elapsedMilliseconds / 1000.0,
                    colors: colors,
                    speed: widget.speed,
                    clustering: widget.clustering,
                    coverage: widget.coverage,
                    opacityScale: resolved.opacityScale,
                  ),
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _GlitterParticle {
  final double normalizedX;
  final double normalizedY;
  final double driftSpeed;
  final double wobbleAmplitude;
  final double wobbleFrequency;
  final double wobblePhase;
  final double radius;
  final double baseOpacity;
  final double colorSeed;
  final double timeOffset;
  final double shimmerSpeed;

  final int sides;
  final double rotationSpeed;
  final double initialRotation;
  final double clusterCenterX;
  final double clusterCenterY;

  _GlitterParticle(Random random, List<Offset> clusterCenters)
    : normalizedX = random.nextDouble(),
      normalizedY = random.nextDouble(),
      driftSpeed = random.nextDouble() * 15 + 5,
      wobbleAmplitude = random.nextDouble() * 7 + 3,
      wobbleFrequency = random.nextDouble() * 0.5 + 0.3,
      wobblePhase = random.nextDouble() * 2 * pi,
      radius = random.nextDouble() * 2 + 1,
      baseOpacity = random.nextDouble() * 0.3 + 0.15,
      colorSeed = random.nextDouble(),
      timeOffset = random.nextDouble() * 100,
      shimmerSpeed = random.nextDouble() * 1.5 + 0.5,
      sides = random.nextInt(2) + 3,
      rotationSpeed = (random.nextDouble() - 0.5) * 2,
      initialRotation = random.nextDouble() * 2 * pi,
      clusterCenterX = clusterCenters[random.nextInt(clusterCenters.length)].dx,
      clusterCenterY = clusterCenters[random.nextInt(clusterCenters.length)].dy;
}

// 1 particle per 4000 sq px at coverage 1.0.
const _baseDensity = 1.0 / 4000.0;

class _GlitterPainter extends CustomPainter {
  final List<_GlitterParticle> particles;
  final double elapsedSeconds;
  final List<Color> colors;
  final double speed;
  final double clustering;
  final double coverage;
  final double opacityScale;
  final _paint = Paint()..style = PaintingStyle.fill;

  _GlitterPainter({
    required this.particles,
    required this.elapsedSeconds,
    required this.colors,
    required this.speed,
    required this.clustering,
    required this.coverage,
    required this.opacityScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final t = elapsedSeconds * speed;
    final area = size.width * size.height;
    final count = (area * _baseDensity * coverage).round().clamp(
      0,
      particles.length,
    );

    // Layered sine waves → organic wind gusts.
    final windX = sin(t * 0.7) * 0.5 + sin(t * 0.3) * 0.3 + sin(t * 1.1) * 0.2;
    final windY = sin(t * 0.5 + 1.0) * 0.3 + sin(t * 0.9 + 2.0) * 0.2;

    for (var i = 0; i < count; i++) {
      final p = particles[i];
      final windSensitivity = 1.0 + (3.0 - p.radius) * 0.8;
      final pt = t + p.timeOffset;

      // Lerp between spread-out position and cluster center.
      final nx =
          p.normalizedX + (p.clusterCenterX - p.normalizedX) * clustering;
      final ny =
          p.normalizedY + (p.clusterCenterY - p.normalizedY) * clustering;

      final baseX = nx * size.width + p.driftSpeed * t;
      final gustX = windX * 40 * windSensitivity;
      final x = (baseX + gustX) % size.width;

      final baseY = ny * size.height;
      final wobble =
          p.wobbleAmplitude *
          sin(2 * pi * p.wobbleFrequency * t + p.wobblePhase);
      final gustY = windY * 20 * windSensitivity;
      final y = baseY + wobble + gustY;

      final shimmer = 0.5 + 0.5 * sin(pt * p.shimmerSpeed * 2 * pi);
      final opacity = (p.baseOpacity * (0.5 + 0.5 * shimmer) * opacityScale)
          .clamp(0.0, 1.0);

      final colorIndex = (p.colorSeed * colors.length).floor() % colors.length;
      _paint.color = colors[colorIndex].withValues(alpha: opacity);

      final rotation = p.initialRotation + pt * p.rotationSpeed;
      final path = Path();
      for (var i = 0; i < p.sides; i++) {
        final angle = rotation + (2 * pi * i / p.sides);
        final vx = x + p.radius * cos(angle);
        final vy = y + p.radius * sin(angle);
        if (i == 0) {
          path.moveTo(vx, vy);
        } else {
          path.lineTo(vx, vy);
        }
      }
      path.close();
      canvas.drawPath(path, _paint);
    }
  }

  @override
  bool shouldRepaint(_GlitterPainter old) =>
      old.elapsedSeconds != elapsedSeconds ||
      old.speed != speed ||
      old.clustering != clustering ||
      old.coverage != coverage ||
      old.opacityScale != opacityScale;
}
