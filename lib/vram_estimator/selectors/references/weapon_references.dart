import 'dart:io';

import 'package:csv/csv.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/references/_json_utils.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Parses `data/weapons/*.wpn` and `data/weapons/proj/*.proj` (JSON sprite
/// fields) plus `data/weapons/weapon_data.csv`.
class WeaponReferences extends ReferenceParser {
  @override
  String get id => 'weapons';

  @override
  String get displayName => 'Weapons (.wpn + .proj + weapon_data.csv)';

  @override
  String get description =>
      'Sprite paths referenced by weapon JSON files, projectile JSON files, '
      'and weapon_data.csv.';

  static const _csvReader = CsvToListConverter(
    allowInvalid: true,
    convertEmptyTo: null,
  );

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
      if (rel.startsWith('data/weapons/')) {
        if (rel.endsWith('.wpn') || rel.endsWith('.proj')) {
          await _parseJsonSprites(f.file, f.relativePath, refs, ctx);
        } else if (rel == 'data/weapons/weapon_data.csv') {
          await _parseWeaponDataCsv(f.file, f.relativePath, refs, ctx);
        }
      }
    }

    return refs;
  }

  Future<void> _parseJsonSprites(
    File file,
    String source,
    Map<String, Set<String>> refs,
    VramSelectorContext ctx,
  ) async {
    try {
      // Strip inline comments first (parseJsonToMap's fixups only handle
      // whole-line `//`, not inline ones or `#`), then parseJsonToMapAsync
      // handles unquoted enum values / trailing commas via its YAML
      // fallback.
      final raw = await file.readAsString();
      final cleaned = stripJsonComments(raw, stripHashLineComments: true);
      final decoded = await cleaned.parseJsonToMapAsync();
      _collectPathShapedStrings(decoded, refs, source);
    } catch (e) {
      ctx.verboseOut('[WeaponReferences] Failed to parse ${file.path}: $e');
    }
  }

  /// Recursively walk the JSON and collect every path-shaped string — one
  /// that either ends in a known image extension or starts with `graphics/`.
  /// Replaces the older approach of enumerating specific sprite keys
  /// (`turretSprite`, `spriteName`, ...): beam weapons use `coreTexture`
  /// and `fringeTexture`, charge-up cycles use array-valued keys like
  /// `turretChargeUpSprites`, and new sprite fields appear over time.
  /// Filtering by shape catches every current and future variant with no
  /// maintenance cost, and non-path weapon fields (engine class names,
  /// numeric params, enum tokens) don't pass the filter.
  void _collectPathShapedStrings(
    dynamic node,
    Map<String, Set<String>> refs,
    String source,
  ) {
    if (node is String) {
      if (node.isEmpty) return;
      final normalized = PathNormalizer.normalize(node);
      if (normalized.isEmpty) return;
      final isPathShaped = PathNormalizer.hasImageExtension(normalized) ||
          normalized.startsWith('graphics/');
      if (isPathShaped) {
        addRefsWithSource(refs, PathNormalizer.expand(node), source);
      }
    } else if (node is List) {
      for (final v in node) {
        _collectPathShapedStrings(v, refs, source);
      }
    } else if (node is Map) {
      for (final v in node.values) {
        _collectPathShapedStrings(v, refs, source);
      }
    }
  }

  Future<void> _parseWeaponDataCsv(
    File file,
    String source,
    Map<String, Set<String>> refs,
    VramSelectorContext ctx,
  ) async {
    try {
      final rows = _csvReader.convert(
        (await file.readAsString()).replaceAll('\r\n', '\n'),
        eol: '\n',
      );
      if (rows.isEmpty) return;
      final header = rows.first;
      // Various sprite columns seen in weapon_data.csv across SS versions.
      final candidateCols = <int>[
        header.indexOf('turret sprite'),
        header.indexOf('hardpoint sprite'),
        header.indexOf('turret under sprite'),
        header.indexOf('hardpoint under sprite'),
        header.indexOf('sprite name'),
      ].where((i) => i >= 0).toList();
      if (candidateCols.isEmpty) return;

      for (final row in rows.skip(1)) {
        for (final col in candidateCols) {
          if (col >= row.length) continue;
          final value = row[col];
          if (value is String && value.isNotEmpty) {
            addRefsWithSource(refs, PathNormalizer.expand(value), source);
          }
        }
      }
    } catch (e) {
      ctx.verboseOut('[WeaponReferences] Failed to parse ${file.path}: $e');
    }
  }
}
