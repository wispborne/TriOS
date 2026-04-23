import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Auto-discovers frame-animation sibling files when another parser has
/// already referenced the frame-0 file of the sequence. Starsector's
/// engine, given a sprite path ending in digits (e.g. `foo_00.png` or
/// `foo00.png`), walks the trailing number upward and loads every
/// sequential frame from the same folder — so those higher-numbered
/// siblings are "used" even though nothing names them explicitly.
///
/// See https://starsector.wiki.gg/wiki/Simple_weapon_animation.
///
/// This parser's `collect()` is a no-op — the real work is the static
/// [expand] helper, which `ReferencedAssetsSelector` invokes as a second
/// pass after the rest of the parsers have produced their referenced
/// sets. It's wired into `_allParsers` purely so the settings UI renders
/// a toggle for it via `registeredReferenceParsers`.
class FrameAnimationReferences extends ReferenceParser {
  static const String parserId = 'frame-animations';

  @override
  String get id => parserId;

  @override
  String get displayName => 'Frame animations';

  @override
  String get description =>
      "Finds auto-loaded frame siblings of referenced sprites. When a "
      "weapon/effect references e.g. foo_00.png, Starsector's engine also "
      "loads foo_01.png, foo_02.png, ... from the same folder.";

  @override
  Future<Map<String, Set<String>>> collect(
    VramCheckerMod mod,
    List<VramModFile> allFiles,
    VramSelectorContext ctx,
  ) async {
    // Intentional no-op. This parser only contributes via [expand], which
    // the selector runs after all other parsers have finished.
    return const <String, Set<String>>{};
  }

  static const _imageExtensions = <String>[
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
  ];

  /// Trailing-digit extractor. For a filename stem like
  /// `uaf_black_sorceress_spell_circle_1_00`, yields prefix
  /// `uaf_black_sorceress_spell_circle_1_` and digits `00`.
  static final RegExp _trailingDigits = RegExp(r'^(.*?)(\d+)$');

  /// Walk referenced image paths; for each one whose filename ends in
  /// digits, gather same-folder siblings matching `{prefix}\d+.{ext}`.
  ///
  /// Returns a map of matched disk path -> set of already-referenced
  /// anchor paths that caused the match (the frame-0 files the engine
  /// would have incremented from). The selector unions the keys into
  /// `referencedPaths` and forwards the anchor paths as attribution
  /// sources so the UI can show e.g. `frame-animations:
  /// graphics/.../foo_00.png`.
  static Future<Map<String, Set<String>>> expand({
    required Set<String> referencedPaths,
    required List<VramModFile> allFiles,
    required VramSelectorContext ctx,
  }) async {
    if (referencedPaths.isEmpty) return const <String, Set<String>>{};

    // Group on-disk image files by parent folder so we only touch the
    // relevant folder's siblings per referenced anchor.
    final byFolder = <String, List<_SiblingFile>>{};
    var sinceYield = 0;
    for (final f in allFiles) {
      if (ctx.isCancelled()) return const <String, Set<String>>{};
      final normalized = PathNormalizer.normalize(f.relativePath);
      if (!PathNormalizer.hasImageExtension(normalized)) continue;
      final slash = normalized.lastIndexOf('/');
      final folder = slash < 0 ? '' : normalized.substring(0, slash);
      final name = slash < 0 ? normalized : normalized.substring(slash + 1);
      (byFolder[folder] ??= <_SiblingFile>[])
          .add(_SiblingFile(path: normalized, name: name));
      if (++sinceYield >= 512) {
        sinceYield = 0;
        await Future<void>.delayed(Duration.zero);
      }
    }

    // Group referenced paths by (folder, animation prefix). Multiple refs
    // can anchor the same prefix (different frames of the same sequence
    // cited in separate data files, or `PathNormalizer.expand` having
    // produced multiple extension variants). Track them all so every
    // matched sibling can be attributed back to the refs that caused it.
    final anchors = <String, _Anchor>{};
    for (final ref in referencedPaths) {
      final ext = _imageExtensions.firstWhere(
        ref.endsWith,
        orElse: () => '',
      );
      if (ext.isEmpty) continue;
      final slash = ref.lastIndexOf('/');
      final folder = slash < 0 ? '' : ref.substring(0, slash);
      final filename = slash < 0 ? ref : ref.substring(slash + 1);
      final stem = filename.substring(0, filename.length - ext.length);
      if (stem.isEmpty) continue;
      final m = _trailingDigits.firstMatch(stem);
      if (m == null) continue;
      final prefix = m.group(1)!;
      // All-digit filenames (no alphabetical prefix) are almost never
      // animations — skip to avoid accidentally matching every numbered
      // file in a folder.
      if (prefix.isEmpty) continue;
      final key = '$folder|$prefix';
      anchors
          .putIfAbsent(key, () => _Anchor(folder: folder, prefix: prefix))
          .anchorRefs
          .add(ref);
    }

    if (anchors.isEmpty) return const <String, Set<String>>{};

    final result = <String, Set<String>>{};
    sinceYield = 0;
    for (final a in anchors.values) {
      if (ctx.isCancelled()) break;
      final siblings = byFolder[a.folder];
      if (siblings == null || siblings.isEmpty) continue;

      final pattern = RegExp(
        '^${RegExp.escape(a.prefix)}(\\d+)\\.(png|jpg|jpeg|gif|webp)\$',
        caseSensitive: false,
      );
      for (final sib in siblings) {
        if (pattern.firstMatch(sib.name) != null) {
          (result[sib.path] ??= <String>{}).addAll(a.anchorRefs);
        }
      }

      if (++sinceYield >= 128) {
        sinceYield = 0;
        await Future<void>.delayed(Duration.zero);
      }
    }

    return result;
  }
}

class _SiblingFile {
  final String path;
  final String name;
  const _SiblingFile({required this.path, required this.name});
}

class _Anchor {
  final String folder;
  final String prefix;
  final Set<String> anchorRefs = <String>{};
  _Anchor({required this.folder, required this.prefix});
}
