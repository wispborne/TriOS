import 'dart:io';

import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/references/_json_utils.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Parses every `.json` file under `data/config/**/` and emits any string
/// value that looks like an image path. Covers `custom_entities.json`,
/// `planets.json`, `engine_styles.json`, `hull_styles.json`, and the pile
/// of mod-specific configs (`modSettings.json`, `exerelinFactionConfig/*.json`,
/// etc.) that no schema-specific parser owns. Also scans `settings.json`
/// itself for path-shaped strings outside the `graphics` block (terrain
/// textures, campaign entity sprites, etc.) — the dedicated
/// `SettingsGraphicsReferences` parser covers only the `graphics` block
/// and misses these.
///
/// A string qualifies as a reference if, after `PathNormalizer.normalize`,
/// it either ends in a known image extension or starts with `graphics/`.
/// Non-path strings (ids, plugin class names, tag lists) are dropped.
class DataConfigJsonReferences extends ReferenceParser {
  @override
  String get id => 'data-config-json';

  @override
  String get displayName => 'data/config JSON files';

  @override
  String get description =>
      'Image paths found in JSON files under data/config/ (beyond settings.json).';

  @override
  Future<Map<String, Set<String>>> collect(
    VramCheckerMod mod,
    List<VramModFile> allFiles,
    VramSelectorContext ctx,
  ) async {
    final refs = <String, Set<String>>{};

    for (final f in allFiles) {
      if (ctx.isCancelled()) break;
      final rel = PathNormalizer.normalize(f.relativePath);
      if (!rel.startsWith('data/config/')) continue;
      if (!rel.endsWith('.json')) continue;
      await _parse(f.file, f.relativePath, refs, ctx);
      // Yield between files so a mod with many / large JSON configs
      // doesn't monopolize the UI thread.
      await Future<void>.delayed(Duration.zero);
    }

    return refs;
  }

  Future<void> _parse(
    File file,
    String source,
    Map<String, Set<String>> refs,
    VramSelectorContext ctx,
  ) async {
    try {
      // Strip inline comments first (parseJsonToMap's fixups only catch
      // whole-line `//`), then parseJsonToMapAsync handles the rest.
      // Walking the structured result yields only string values (not
      // keys), which is what we want — keys are config names, not paths.
      final raw = await file.readAsString();
      final cleaned = stripJsonComments(raw, stripHashLineComments: true);
      final decoded = await cleaned.parseJsonToMapAsync();
      _collectStrings(decoded, refs, source);
    } catch (e) {
      ctx.verboseOut(
        '[DataConfigJsonReferences] Failed to parse ${file.path}: $e',
      );
    }
  }

  void _collectStrings(
    dynamic node,
    Map<String, Set<String>> refs,
    String source,
  ) {
    if (node is String) {
      _addIfPathShaped(node, refs, source);
    } else if (node is List) {
      for (final v in node) {
        _collectStrings(v, refs, source);
      }
    } else if (node is Map) {
      for (final v in node.values) {
        _collectStrings(v, refs, source);
      }
    }
  }

  void _addIfPathShaped(
    String value,
    Map<String, Set<String>> refs,
    String source,
  ) {
    if (value.isEmpty) return;
    final normalized = PathNormalizer.normalize(value);
    if (normalized.isEmpty) return;
    final isPathShaped = PathNormalizer.hasImageExtension(normalized) ||
        normalized.startsWith('graphics/');
    if (!isPathShaped) return;
    addRefsWithSource(refs, PathNormalizer.expand(value), source);
  }
}
