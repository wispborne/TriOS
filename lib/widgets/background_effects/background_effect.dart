import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trios/themes/theme_modifiers.dart';

/// Immutable per-frame inputs the host hands each effect at paint time.
///
/// Motion state (particle positions, etc.) lives inside each effect; this only
/// carries the shared drawing inputs the host resolves each frame.
class BackgroundPaintContext {
  /// Palette the effect draws from (theme colors, or the rainbow palette).
  final List<Color> colors;

  /// Multiplier on drawn opacity (the Pride theme renders less transparent).
  final double opacityScale;

  /// Whether the rainbow palette is in use. Motes draw spinning polygons in
  /// this mode instead of circles.
  final bool isRainbow;

  /// Warped animation time in seconds, eased by the host's motion envelope.
  final double elapsedSeconds;

  /// Particle density multiplier.
  final double coverage;

  /// Multiplier on each effect's brightness-shimmer rate.
  final double pulseRate;

  const BackgroundPaintContext({
    required this.colors,
    required this.opacityScale,
    required this.isRainbow,
    required this.elapsedSeconds,
    required this.coverage,
    required this.pulseRate,
  });
}

/// One selectable animated background style. The host widget owns the shared
/// scaffolding (motion easing, sizing, cursor, colors, gating) and delegates the
/// per-style motion and drawing to a [BackgroundEffect].
abstract class BackgroundEffect {
  /// The style this effect implements, so the host can detect a style change.
  BackgroundStyle get style;

  /// Whether the host should track the cursor and feed it to [update].
  bool get reactsToCursor;

  /// (Re)seed internal state for a known canvas [size]. Called on first layout
  /// and whenever the style switches.
  void seed(Size size, Random random);

  /// Rescale seeded positions when the canvas resizes.
  void resize(Size oldSize, Size newSize);

  /// Advance one frame by [dt] seconds. [cursor] is null when the pointer is
  /// away (or the effect doesn't react to it).
  void update(double dt, double elapsedSeconds, Size size, Offset? cursor);

  /// Draw the current frame.
  void paint(Canvas canvas, Size size, BackgroundPaintContext ctx);
}

/// 1 particle per 4000 sq px at coverage 1.0.
const _baseDensity = 1.0 / 4000.0;

/// Number of particles to simulate and draw for a canvas of [size], given
/// [coverage] and the available [max].
int activeParticleCount(
  Size size,
  double coverage,
  int max, {
  double baseDensity = _baseDensity,
}) {
  final area = size.width * size.height;
  return (area * baseDensity * coverage).round().clamp(0, max);
}
