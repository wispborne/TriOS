import 'dart:io';

import 'package:csv/csv.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Scans every `.csv` file under `data/` (beyond the hull/weapon/portrait
/// tables already owned by dedicated parsers) and emits any cell value
/// that looks like an image path. Covers mod-defined tables under
/// `data/campaign/`, `data/world/`, `data/strings/`, etc. whose cells
/// point at sprites — e.g. `data/campaign/frontiers/*_facilities.csv`
/// rows citing an icon PNG.
///
/// A cell qualifies as a reference if, after `PathNormalizer.normalize`,
/// it either ends in a known image extension or starts with `graphics/`.
/// The filter drops ids, display names, tag lists, and other non-path
/// cells reliably (same shape as [DataConfigJsonReferences]).
class DataCsvReferences extends ReferenceParser {
  @override
  String get id => 'data-csv';

  @override
  String get displayName => 'data/ CSV files';

  @override
  String get description =>
      'Image paths found in any CSV under data/ beyond the hull, weapon, '
      'and portrait tables (e.g. mod-defined campaign / world tables).';

  static const _csvReader = CsvToListConverter(
    allowInvalid: true,
    convertEmptyTo: null,
  );

  /// CSVs already covered by dedicated parsers — skip to avoid duplicate
  /// I/O and attribution noise. Compared against `PathNormalizer.normalize`d
  /// paths (lowercase, forward slashes).
  static const _alreadyHandled = <String>{
    'data/hulls/ship_data.csv',
    'data/weapons/weapon_data.csv',
    'data/characters/portraits/portraits.csv',
  };

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
      if (!rel.startsWith('data/')) continue;
      if (!rel.endsWith('.csv')) continue;
      if (_alreadyHandled.contains(rel)) continue;
      await _parse(f.file, f.relativePath, refs, ctx);
      // Yield between files so a mod with many CSVs doesn't monopolize
      // the UI thread.
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
      final rows = _csvReader.convert(
        (await file.readAsString()).replaceAll('\r\n', '\n'),
        eol: '\n',
      );
      if (rows.isEmpty) return;

      // Skip GraphicsLib manifests — they're owned by graphicslib_references.
      // Same header matcher as GraphicsLibReferences.parse(): id/type/map/path.
      final header = rows.first;
      if (header.contains('id') &&
          header.contains('type') &&
          header.contains('map') &&
          header.contains('path')) {
        return;
      }

      // Scan every cell in every row (header included — column names are
      // rarely path-shaped, the filter drops them anyway, and the check
      // is cheap).
      for (final row in rows) {
        for (final cell in row) {
          if (cell is! String || cell.isEmpty) continue;
          _addIfPathShaped(cell, refs, source);
        }
      }
    } catch (e) {
      ctx.verboseOut('[DataCsvReferences] Failed to parse ${file.path}: $e');
    }
  }

  void _addIfPathShaped(
    String value,
    Map<String, Set<String>> refs,
    String source,
  ) {
    final normalized = PathNormalizer.normalize(value);
    if (normalized.isEmpty) return;
    final isPathShaped = PathNormalizer.hasImageExtension(normalized) ||
        normalized.startsWith('graphics/');
    if (!isPathShaped) return;
    addRefsWithSource(refs, PathNormalizer.expand(value), source);
  }
}
