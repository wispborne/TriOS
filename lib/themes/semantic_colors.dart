import 'package:flutter/material.dart';
import 'package:material_color_utilities/hct/hct.dart';
import 'package:material_color_utilities/palettes/tonal_palette.dart';

/// Controls which algorithm generates semantic color variants from a seed.
enum SemanticColorStrategy {
  /// Uses [ColorScheme.fromSeed] and extracts primary roles.
  fromSeed,

  /// Uses [material_color_utilities] TonalPalette with M3 tone mappings.
  tonalPalette,
}

/// The active strategy. Change this to compare outputs.
const semanticColorStrategy = SemanticColorStrategy.tonalPalette;

/// A set of 4 color roles for a single semantic status.
class SemanticColorGroup {
  final Color base;
  final Color onBase;
  final Color container;
  final Color onContainer;

  const SemanticColorGroup({
    required this.base,
    required this.onBase,
    required this.container,
    required this.onContainer,
  });
}

/// Default seed colors for each semantic role.
const _defaultSuccessSeed = Color(0xFF4CAF50);
const _defaultWarningSeed = Color(0xFFFDD818);
const _defaultInfoSeed = Color(0xFF2196F3);
const _defaultNeutralSeed = Color(0xFF9E9E9E);

/// Generates a [SemanticColorGroup] from a seed color using the active strategy.
SemanticColorGroup generateSemanticColors({
  required Color seed,
  required Brightness brightness,
  SemanticColorStrategy strategy = semanticColorStrategy,
}) {
  return switch (strategy) {
    SemanticColorStrategy.fromSeed => _generateFromSeed(seed, brightness),
    SemanticColorStrategy.tonalPalette =>
      _generateFromTonalPalette(seed, brightness),
  };
}

SemanticColorGroup _generateFromSeed(Color seed, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );
  return SemanticColorGroup(
    base: scheme.primary,
    onBase: scheme.onPrimary,
    container: scheme.primaryContainer,
    onContainer: scheme.onPrimaryContainer,
  );
}

SemanticColorGroup _generateFromTonalPalette(
  Color seed,
  Brightness brightness,
) {
  final hct = Hct.fromInt(seed.toARGB32());
  final palette = TonalPalette.of(hct.hue, hct.chroma);

  if (brightness == Brightness.dark) {
    return SemanticColorGroup(
      base: Color(palette.get(80)),
      onBase: Color(palette.get(20)),
      container: Color(palette.get(30)),
      onContainer: Color(palette.get(90)),
    );
  } else {
    return SemanticColorGroup(
      base: Color(palette.get(40)),
      onBase: Color(palette.get(100)),
      container: Color(palette.get(90)),
      onContainer: Color(palette.get(10)),
    );
  }
}

/// Generates all four semantic color groups for a theme.
({
  SemanticColorGroup success,
  SemanticColorGroup warning,
  SemanticColorGroup info,
  SemanticColorGroup neutral,
}) generateAllSemanticColors({
  required Brightness brightness,
  Color? successSeed,
  Color? warningSeed,
  Color? infoSeed,
  Color? neutralSeed,
  SemanticColorStrategy strategy = semanticColorStrategy,
}) {
  return (
    success: generateSemanticColors(
      seed: successSeed ?? _defaultSuccessSeed,
      brightness: brightness,
      strategy: strategy,
    ),
    warning: generateSemanticColors(
      seed: warningSeed ?? _defaultWarningSeed,
      brightness: brightness,
      strategy: strategy,
    ),
    info: generateSemanticColors(
      seed: infoSeed ?? _defaultInfoSeed,
      brightness: brightness,
      strategy: strategy,
    ),
    neutral: generateSemanticColors(
      seed: neutralSeed ?? _defaultNeutralSeed,
      brightness: brightness,
      strategy: strategy,
    ),
  );
}
