import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// Auto-discovers phase-glow sibling files when another parser has already
/// referenced the base sprite. When a ship enters phase, Starsector loads
/// `{sprite}_glow.png` and/or `{sprite}_glow{N}.png` from the same folder
/// as the ship's main sprite — these are never named explicitly in any
/// hull/weapon/effect file.
///
/// Examples:
/// - `rat_gabriel.png` → `rat_gabriel_glow1.png`, `rat_gabriel_glow2.png`
/// - `rat_morkoth.png` → `rat_morkoth_glow.png`
///
/// Like [FrameAnimationReferences], this parser's `collect()` is a no-op
/// — the real work is the static [expand] helper that the selector calls
/// as a post-pass once the other parsers' output is aggregated.
class PhaseGlowReferences extends ReferenceParser {
  static const String parserId = 'phase-glows';

  @override
  String get id => parserId;

  @override
  String get displayName => 'Phase glows';

  @override
  String get description =>
      "Finds ship phase-glow siblings (e.g. foo_glow.png, foo_glow1.png) "
      "of referenced sprites. Starsector auto-loads these from the same "
      "folder when the base ship sprite is referenced.";

  @override
  Future<Map<String, Set<String>>> collect(
    VramCheckerMod mod,
    List<VramModFile> allFiles,
    VramSelectorContext ctx,
  ) async {
    return const <String, Set<String>>{};
  }

  static const _imageExtensions = <String>[
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
  ];

  /// Matches a filename stem that itself is a glow — so we don't try to
  /// find glows-of-glows, which would just waste cycles.
  static final RegExp _endsInGlow = RegExp(r'_glow\d*$', caseSensitive: false);

  /// Walk referenced image paths; for each one, look for same-folder
  /// siblings matching `{stem}_glow.{ext}` or `{stem}_glow{digits}.{ext}`.
  ///
  /// Returns a map of matched disk path -> set of already-referenced
  /// anchor paths that caused the match (the base sprite whose glow this
  /// is). Caller unions the keys into `referencedPaths` and forwards the
  /// anchor paths as attribution sources.
  static Future<Map<String, Set<String>>> expand({
    required Set<String> referencedPaths,
    required List<VramModFile> allFiles,
    required VramSelectorContext ctx,
  }) async {
    if (referencedPaths.isEmpty) return const <String, Set<String>>{};

    // Group on-disk image files by parent folder — Starsector's glow
    // loader only looks in the same folder as the base sprite.
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

    // Group referenced paths by (folder, stem) so each stem is scanned
    // once even when `PathNormalizer.expand` emitted multiple extension
    // variants. Track every anchor ref per stem for attribution.
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
      // Skip stems that are themselves glows — chains like `foo_glow_glow`
      // don't exist and the sibling scan below would just be noise.
      if (_endsInGlow.hasMatch(stem)) continue;
      final key = '$folder|$stem';
      anchors
          .putIfAbsent(key, () => _Anchor(folder: folder, stem: stem))
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

      // `_glow` optionally followed by digits, then extension. Matches both
      // `foo_glow.png` (morkoth-style) and `foo_glow1.png` (gabriel-style).
      final pattern = RegExp(
        '^${RegExp.escape(a.stem)}_glow(\\d*)\\.(png|jpg|jpeg|gif|webp)\$',
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
  final String stem;
  final Set<String> anchorRefs = <String>{};
  _Anchor({required this.folder, required this.stem});
}
