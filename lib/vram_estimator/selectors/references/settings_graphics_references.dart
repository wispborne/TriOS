import 'dart:io';

import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/references/_json_utils.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Parses `data/config/settings.json`'s `graphics` block, which maps
/// category → id → path for sprites registered globally with the game.
class SettingsGraphicsReferences extends ReferenceParser {
  @override
  String get id => 'settings-graphics';

  @override
  String get displayName => 'settings.json graphics block';

  @override
  String get description =>
      'Paths declared in data/config/settings.json under the graphics block.';

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
      if (rel == 'data/config/settings.json') {
        await _parse(f.file, f.relativePath, refs, ctx);
      }
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
      final raw = await file.readAsString();
      final cleaned = stripJsonComments(raw, stripHashLineComments: true);
      final decoded = await cleaned.parseJsonToMapAsync();
      final graphics = decoded['graphics'];
      if (graphics is! Map) return;
      // Structure: graphics: { category: { id: "path/to/sprite.png" } }
      // Accept strings at any depth for resilience.
      _collectStrings(graphics, refs, source);
    } catch (e) {
      ctx.verboseOut(
        '[SettingsGraphicsReferences] Failed to parse ${file.path}: $e',
      );
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
