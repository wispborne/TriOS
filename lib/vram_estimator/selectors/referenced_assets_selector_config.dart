import 'package:dart_mappable/dart_mappable.dart';

part 'referenced_assets_selector_config.mapper.dart';

/// Persisted configuration for `ReferencedAssetsSelector`. Exposed to the
/// user through the VRAM estimator's "Reference scan debug" panel.
@MappableClass()
class ReferencedAssetsSelectorConfig
    with ReferencedAssetsSelectorConfigMappable {
  /// Parser ids currently enabled. Unknown ids are ignored silently at
  /// scan time; an empty set is legal (produces zero references).
  final Set<String> enabledParserIds;

  /// When true, the selector emits only referenced assets — the
  /// `VramMod.unreferencedImages` field on results will be null.
  /// Use for clean comparisons against folder-scan totals.
  final bool suppressUnreferenced;

  const ReferencedAssetsSelectorConfig({
    required this.enabledParserIds,
    this.suppressUnreferenced = false,
  });

  /// Every known parser enabled, no debug toggles set. The default state
  /// for a fresh install.
  static const ReferencedAssetsSelectorConfig allEnabled =
      ReferencedAssetsSelectorConfig(
        enabledParserIds: {
          'ships',
          'weapons',
          'factions',
          'portraits',
          'settings-graphics',
          'data-config-json',
          'data-csv',
          'graphicslib',
          'jar-strings',
          'java-sources',
          'frame-animations',
          'phase-glows',
        },
      );

  /// Deterministic hash used for the per-selector result cache key. Only
  /// includes fields that actually affect scan output.
  int get cacheHash => Object.hashAll([
    ...(enabledParserIds.toList()..sort()),
    suppressUnreferenced,
  ]);
}
