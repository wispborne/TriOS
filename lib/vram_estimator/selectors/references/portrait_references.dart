import 'dart:io';

import 'package:csv/csv.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Parses `data/characters/portraits/portraits.csv`. Most SS mods list
/// portrait paths directly in their `.faction` files, but some also use the
/// dedicated CSV — scan both for coverage.
class PortraitReferences extends ReferenceParser {
  @override
  String get id => 'portraits';

  @override
  String get displayName => 'Portraits (portraits.csv)';

  @override
  String get description =>
      'Portrait paths listed in data/characters/portraits/portraits.csv.';

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
      if (rel == 'data/characters/portraits/portraits.csv') {
        await _parseCsv(f.file, f.relativePath, refs, ctx);
      }
    }

    return refs;
  }

  Future<void> _parseCsv(
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
      // Accept any cell that looks like a path — portrait CSVs vary in schema
      // between mods. Normalizer + intersection step drops non-matches.
      for (final row in rows.skip(1)) {
        for (final cell in row) {
          if (cell is String &&
              cell.isNotEmpty &&
              (cell.contains('/') || cell.contains('\\'))) {
            addRefsWithSource(refs, PathNormalizer.expand(cell), source);
          }
        }
      }
    } catch (e) {
      ctx.verboseOut('[PortraitReferences] Failed to parse ${file.path}: $e');
    }
  }
}
