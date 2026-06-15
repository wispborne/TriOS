import 'dart:io';

import 'package:csv/csv.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/references/_json_utils.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Parses `data/hulls/*.ship` (JSON `spriteName`) and
/// `data/hulls/ship_data.csv` (`sprite name` column).
class ShipReferences extends ReferenceParser {
  @override
  String get id => 'ships';

  @override
  String get displayName => 'Ship hulls (.ship + ship_data.csv)';

  @override
  String get description =>
      'Sprite paths referenced by .ship JSON files and ship_data.csv.';

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
      if (rel.startsWith('data/hulls/') && rel.endsWith('.ship')) {
        await _parseShipJson(f.file, f.relativePath, refs, ctx);
      } else if (rel == 'data/hulls/ship_data.csv') {
        await _parseShipDataCsv(f.file, f.relativePath, refs, ctx);
      }
    }

    return refs;
  }

  Future<void> _parseShipJson(
    File file,
    String source,
    Map<String, Set<String>> refs,
    VramSelectorContext ctx,
  ) async {
    try {
      // stripJsonComments handles inline `//`, `/* */`, and `#` comments
      // that parseJsonToMap's internal fixups miss (it only strips
      // whole-line `//`). parseJsonToMapAsync then handles unquoted enum
      // values, trailing commas, tabs etc. via its YAML fallback.
      final raw = await file.readAsString();
      final cleaned = stripJsonComments(raw, stripHashLineComments: true);
      final decoded = await cleaned.parseJsonToMapAsync();
      final sprite = decoded['spriteName'];
      if (sprite is String && sprite.isNotEmpty) {
        addRefsWithSource(refs, PathNormalizer.expand(sprite), source);
      }
    } catch (e) {
      ctx.verboseOut('[ShipReferences] Failed to parse ${file.path}: $e');
    }
  }

  Future<void> _parseShipDataCsv(
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
      final spriteCol = header.indexOf('sprite name');
      if (spriteCol < 0) return;
      for (final row in rows.skip(1)) {
        if (spriteCol >= row.length) continue;
        final value = row[spriteCol];
        if (value is String && value.isNotEmpty) {
          addRefsWithSource(refs, PathNormalizer.expand(value), source);
        }
      }
    } catch (e) {
      ctx.verboseOut('[ShipReferences] Failed to parse ${file.path}: $e');
    }
  }
}
