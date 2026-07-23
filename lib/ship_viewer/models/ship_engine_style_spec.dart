import 'package:flutter/material.dart';

/// How a style draws its contrail. Parsed from the `mode` key; the game
/// defaults to particles when the key is absent.
enum ContrailMode { particles, quadStrip, none }

/// A single entry from `data/config/engine_styles.json`.
///
/// We only keep what the ship viewer needs to draw an engine flame: the tint,
/// the size of the round bloom at the nozzle, and which of the two flame
/// sprites the game picks.
class EngineStyleSpec {
  /// Flame tint. Parsed from the `[r, g, b, a]` `engineColor` array (0–255).
  final Color? engineColor;

  /// Tint for the round bloom at the nozzle, when the style sets one. Only a
  /// few styles do (OMEGA); everything else blooms in [engineColor].
  final Color? glowAlternateColor;

  /// Multiplier on the round bloom size (`COBRA_BOMBER` uses 3.5, etc.).
  final double glowSizeMult;

  /// True when the style's `type` is `SMOKE`. The game draws smoke flames with
  /// `engineglow32s.png` and glow flames with `engineglow32.png`.
  final bool isSmoke;

  /// Replaces the flame sprite, when the style names one. `THREAT` uses a beam
  /// core here, `OMEGA` a second engine glow.
  final String? glowSprite;

  /// Replaces the sprite laid over the flame, when the style names one.
  /// `THREAT` blanks it out with `empty.png`.
  final String? glowOutline;

  /// True for `"omegaMode":true` styles. The game draws these as one wide pass
  /// stamped twice instead of six stacked ones.
  final bool omegaMode;

  /// How this style's contrail is drawn (particles, one ribbon, or nothing).
  final ContrailMode contrailMode;

  /// Contrail tint (in combat; the campaign colour is separate and unused
  /// here). Null means the style gave none, which also means no contrail.
  final Color? contrailColor;

  /// Seconds each contrail particle (or ribbon segment) lives. With the drift
  /// speed, this sets how far the trail reaches.
  final double contrailDuration;

  /// The contrail's starting width is the engine slot's width times this.
  final double contrailSizeMult;

  /// Particles: each grows to `start × this` over its life (LOW_TECH's 2.5
  /// billows out). Ribbon: width changes by this fraction at the far end
  /// (OMEGA's -1 tapers to a point).
  final double contrailEndMult;

  /// Particles drift aft at the ship's top speed times this (on top of the
  /// ship moving out from under them at top speed).
  final double contrailMaxSpeedMult;

  /// Ribbon only: the head sits this fraction of the flame length aft of the
  /// nozzle (times the at-rest glow of 0.4).
  final double contrailSpawnDistMult;

  const EngineStyleSpec({
    this.engineColor,
    this.glowAlternateColor,
    this.glowSizeMult = 1.0,
    this.isSmoke = false,
    this.glowSprite,
    this.glowOutline,
    this.omegaMode = false,
    this.contrailMode = ContrailMode.particles,
    this.contrailColor,
    this.contrailDuration = 0,
    this.contrailSizeMult = 0,
    this.contrailEndMult = 0.5,
    this.contrailMaxSpeedMult = 0,
    this.contrailSpawnDistMult = 0.7,
  });

  static EngineStyleSpec fromJson(Map<dynamic, dynamic> json) {
    final mode = switch ((json['mode'] as String?)?.trim().toUpperCase()) {
      'QUAD_STRIP' => ContrailMode.quadStrip,
      'NONE' => ContrailMode.none,
      _ => ContrailMode.particles,
    };
    // The particle and ribbon modes read different keys for the same three
    // ideas: how wide, how long-lived, and what happens to the width over the
    // trail. Same defaults as the game where it has one; the required keys
    // fall back to "no contrail" instead of throwing.
    final isRibbon = mode == ContrailMode.quadStrip;
    return EngineStyleSpec(
      engineColor: _color(json['engineColor']),
      glowAlternateColor: _color(json['glowAlternateColor']),
      glowSizeMult: _toDouble(json['glowSizeMult']) ?? 1.0,
      isSmoke: (json['type'] as String?)?.trim().toUpperCase() == 'SMOKE',
      glowSprite: _path(json['glowSprite']),
      glowOutline: _path(json['glowOutline']),
      omegaMode: json['omegaMode'] == true,
      contrailMode: mode,
      contrailColor: _color(json['contrailColor']),
      contrailDuration:
          _toDouble(
            json[isRibbon ? 'contrailDuration' : 'contrailParticleDuration'],
          ) ??
          0,
      contrailSizeMult:
          _toDouble(
            json[isRibbon ? 'contrailWidthMult' : 'contrailParticleSizeMult'],
          ) ??
          0,
      contrailEndMult:
          _toDouble(
            json[isRibbon
                ? 'contrailWidthAddedFractionAtEnd'
                : 'contrailParticleFinalSizeMult'],
          ) ??
          0.5,
      contrailMaxSpeedMult: _toDouble(json['contrailMaxSpeedMult']) ?? 0,
      contrailSpawnDistMult: _toDouble(json['contrailSpawnDistMult']) ?? 0.7,
    );
  }

  static String? _path(dynamic value) {
    if (value is! String) return null;
    final path = value.trim();
    return path.isEmpty ? null : path;
  }

  static Color? _color(dynamic value) {
    if (value is! List || value.length < 3) return null;
    final c = value
        .map((e) => (_toDouble(e)?.toInt() ?? 0).clamp(0, 255))
        .toList();
    return Color.fromARGB(c.length >= 4 ? c[3] : 255, c[0], c[1], c[2]);
  }

  static final _floatSuffix = RegExp(r'[fF]$');

  /// Coerces a JSON value to a double, tolerating Starsector's `0.5f`-style
  /// number literals (which arrive as strings) and plain numeric strings.
  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(_floatSuffix, '').trim());
    }
    return null;
  }
}
