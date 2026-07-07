import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/themes/theme_modifiers.dart';
import 'package:trios/trios/app_lifecycle_provider.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/widgets/background_effects/aurora_effect.dart';
import 'package:trios/widgets/background_effects/background_effect.dart';
import 'package:trios/widgets/background_effects/circuitry_effect.dart';
import 'package:trios/widgets/background_effects/constellation_effect.dart';
import 'package:trios/widgets/background_effects/embers_effect.dart';
import 'package:trios/widgets/background_effects/motes_effect.dart';
import 'package:trios/widgets/background_effects/nebula_effect.dart';
import 'package:trios/widgets/background_effects/radar_effect.dart';
import 'package:trios/widgets/background_effects/rain_effect.dart';
import 'package:trios/widgets/background_effects/starfield_effect.dart';
import 'package:trios/widgets/rainbow_accent_bar.dart';

/// Hosts one animated background [BackgroundEffect] (chosen by the user) behind
/// [child]. Owns the shared scaffolding — motion easing tied to app focus,
/// canvas sizing, cursor tracking, theme-color resolution, and the on/off +
/// location gating — and delegates the per-style motion and drawing to the
/// current effect.
class GlitterBackground extends ConsumerStatefulWidget {
  final Widget child;

  /// Overall speed multiplier for the effect's motion.
  final double speed;

  /// Cohesion strength multiplier — how tightly motes pull together. Only the
  /// Motes style uses this.
  final double clustering;

  /// Particle density multiplier (1 particle per 4000 sq px at 1.0).
  final double coverage;

  final GlitterLocation? location;

  /// Whether the effect may be pushed away from the cursor (if it reacts at all).
  final bool reactToCursor;

  /// Multiplier on each effect's brightness-shimmer rate.
  final double pulseRate;

  const GlitterBackground({
    super.key,
    required this.child,
    this.speed = 0.25,
    this.clustering = 0.5,
    this.coverage = 1.5,
    this.location,
    this.reactToCursor = true,
    this.pulseRate = 0.5,
  });

  @override
  ConsumerState<GlitterBackground> createState() => _GlitterBackgroundState();
}

class _GlitterBackgroundState extends ConsumerState<GlitterBackground>
    with SingleTickerProviderStateMixin {
  // Time constant (seconds) for easing motion in/out so the effect doesn't
  // suddenly start or stop moving.
  static const double _envelopeTau = 0.6;

  late final AnimationController _controller;

  // Real wall clock, used to compute per-frame deltas. Always running.
  final Stopwatch _stopwatch = Stopwatch();
  double _lastRealSeconds = 0;

  // Warped time fed to the effect. Advances at a rate scaled by [_envelope], so
  // motion eases rather than jumping when started/stopped.
  double _animationSeconds = 0;

  // Eased motion factor, 0 (stopped) .. 1 (full speed).
  double _envelope = 0;

  // Desired motion state, toggled by app lifecycle.
  bool _motionEnabled = false;

  final Random _random = Random();

  // The current background effect. Rebuilt when the selected style changes.
  BackgroundEffect? _effect;

  // Canvas size, captured during layout so the effect's motion step (which runs
  // in the tick, before paint) can work in pixel space. The effect is seeded
  // once the size is first known.
  Size? _size;
  bool _seeded = false;

  // Cursor position in canvas pixels, or null when the pointer is away. Updated
  // without setState — the running animation loop reads it each frame.
  Offset? _cursor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..addListener(_tick);
    _stopwatch.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  /// Per-frame tick: advances warped time by the real delta scaled by an eased
  /// envelope, then advances the current effect's motion.
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

    final effect = _effect;
    final size = _size;
    if (effect != null && size != null && _seeded) {
      final cursor = widget.reactToCursor && effect.reactsToCursor
          ? _cursor
          : null;
      effect.update(simDt, _animationSeconds, size, cursor);
    }

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

  /// Swaps in a fresh effect when the selected [style] changes, and marks it to
  /// reseed at the next layout.
  void _ensureEffect(BackgroundStyle style) {
    if (_effect?.style == style) return;
    _effect = switch (style) {
      BackgroundStyle.motes => MotesEffect(
        speed: widget.speed,
        clustering: widget.clustering,
        coverage: widget.coverage,
      ),
      BackgroundStyle.starfield => StarfieldEffect(
        speed: widget.speed,
        coverage: widget.coverage,
      ),
      BackgroundStyle.nebula => NebulaEffect(speed: widget.speed),
      BackgroundStyle.constellation => ConstellationEffect(
        speed: widget.speed,
        coverage: widget.coverage,
      ),
      BackgroundStyle.embers => EmbersEffect(
        speed: widget.speed,
        coverage: widget.coverage,
      ),
      BackgroundStyle.aurora => AuroraEffect(speed: widget.speed),
      BackgroundStyle.rain => RainEffect(
        speed: widget.speed,
        coverage: widget.coverage,
      ),
      BackgroundStyle.radar => RadarEffect(
        speed: widget.speed,
        coverage: widget.coverage,
      ),
      BackgroundStyle.circuitry => CircuitryEffect(
        speed: widget.speed,
        coverage: widget.coverage,
      ),
    };
    _seeded = false;
  }

  /// Captures the canvas size during layout. Seeds the effect the first time the
  /// size is known (or after a style switch), and rescales it on resize so the
  /// motion stays in view.
  void _updateSize(Size size) {
    if (size.isEmpty) {
      _size = size;
      return;
    }
    final effect = _effect;
    if (effect == null) {
      _size = size;
      return;
    }
    if (!_seeded) {
      effect.seed(size, _random);
      _seeded = true;
    } else {
      final old = _size;
      if (old != null && !old.isEmpty && old != size) {
        effect.resize(old, size);
      }
    }
    _size = size;
  }

  /// Colors come from [themeKey]'s theme, or the active theme when null. The
  /// Pride theme uses the rainbow palette instead of its swatch, and renders
  /// less transparent (a higher [opacityScale]).
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

    _ensureEffect(modifiers.backgroundStyle);
    final effect = _effect!;

    final lifecycle = ref.watch(appLifecycleProvider);
    _setMotion(lifecycle == AppLifecycleState.resumed);

    final resolved = _resolveColors(context, modifiers.glitterThemeKey);
    final paintContext = BackgroundPaintContext(
      colors: resolved.colors,
      opacityScale: resolved.opacityScale,
      isRainbow: resolved.isRainbow,
      elapsedSeconds: _animationSeconds,
      coverage: widget.coverage,
      pulseRate: widget.pulseRate,
    );

    // Clip only the effect layer to the bounds, not the child. The child may
    // legitimately overflow (e.g. a blurred icon glow), and clipping it here
    // would chop that into a hard rectangle.
    final stack = Stack(
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
                      painter: _BackgroundPainter(
                        effect: effect,
                        context: paintContext,
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
    );

    // Skip cursor tracking entirely for styles that don't react to it.
    if (!widget.reactToCursor || !effect.reactsToCursor) return stack;

    // MouseRegion tracks the cursor so the effect can dodge it. opaque: false
    // and hover-only handlers mean it never blocks clicks or the child's own
    // hover effects/tooltips.
    return MouseRegion(
      opaque: false,
      hitTestBehavior: HitTestBehavior.translucent,
      onHover: (event) => _cursor = event.localPosition,
      onExit: (_) => _cursor = null,
      child: stack,
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final BackgroundEffect effect;
  final BackgroundPaintContext context;

  _BackgroundPainter({required this.effect, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    effect.paint(canvas, size, context);
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.effect != effect ||
      old.context.elapsedSeconds != context.elapsedSeconds ||
      old.context.opacityScale != context.opacityScale ||
      old.context.coverage != context.coverage ||
      old.context.pulseRate != context.pulseRate;
}
