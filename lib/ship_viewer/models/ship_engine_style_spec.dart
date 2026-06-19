import 'package:flutter/material.dart';

/// A single entry from `data/config/engine_styles.json`.
///
/// We only keep what the ship viewer needs to render a static engine glow:
/// the flame [engineColor] and the relative size of the round base glow.
class EngineStyleSpec {
  /// Flame tint. Parsed from the `[r, g, b, a]` `engineColor` array (0–255).
  final Color? engineColor;

  /// Multiplier on the round base glow size (`COBRA_BOMBER` uses 3.5, etc.).
  final double glowSizeMult;

  const EngineStyleSpec({this.engineColor, this.glowSizeMult = 1.0});

  static EngineStyleSpec fromJson(Map<dynamic, dynamic> json) {
    return EngineStyleSpec(
      engineColor: _color(json['engineColor']),
      glowSizeMult: _toDouble(json['glowSizeMult']) ?? 1.0,
    );
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
