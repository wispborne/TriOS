import 'dart:io';

import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/references/_json_utils.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Parses `data/world/factions/*.faction` for `logo`, `crest`, and the
/// portrait arrays under `portraits`.
class FactionReferences extends ReferenceParser {
  @override
  String get id => 'factions';

  @override
  String get displayName => 'Factions (.faction)';

  @override
  String get description =>
      'Logo, crest, and portrait paths referenced by .faction JSON files.';

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
      if (rel.startsWith('data/world/factions/') && rel.endsWith('.faction')) {
        await _parseFaction(f.file, f.relativePath, refs, ctx);
      }
    }

    return refs;
  }

  Future<void> _parseFaction(
    File file,
    String source,
    Map<String, Set<String>> refs,
    VramSelectorContext ctx,
  ) async {
    try {
      // Strip inline comments first (parseJsonToMap's fixups only catch
      // whole-line `//`), then parseJsonToMapAsync handles the rest.
      final raw = await file.readAsString();
      final cleaned = stripJsonComments(raw, stripHashLineComments: true);
      final decoded = await cleaned.parseJsonToMapAsync();
      for (final key in const ['logo', 'crest']) {
        final v = decoded[key];
        if (v is String && v.isNotEmpty) {
          addRefsWithSource(refs, PathNormalizer.expand(v), source);
        }
      }
      final portraits = decoded['portraits'];
      if (portraits is Map) {
        _collectStrings(portraits, refs, source);
      }
    } catch (e) {
      ctx.verboseOut('[FactionReferences] Failed to parse ${file.path}: $e');
    }
  }

  void _collectStrings(
    dynamic node,
    Map<String, Set<String>> refs,
    String source,
  ) {
    if (node is String && node.isNotEmpty) {
      addRefsWithSource(refs, PathNormalizer.expand(node), source);
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
}
