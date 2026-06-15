import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// A source of references within a mod — a ship data CSV, a faction file,
/// the constant pool of a JAR, etc. Each parser returns a map of
/// normalized referenced paths -> the set of source files (normalized
/// relative paths) that produced each reference; [ReferencedAssetsSelector]
/// unions them.
///
/// Every parser MUST normalize its outputs via `PathNormalizer` so the
/// union and subsequent intersection with on-disk files work on a single
/// canonical form. Enforced by convention + per-parser unit tests.
abstract class ReferenceParser {
  /// Stable key — persisted in settings and printed in profiling logs.
  /// Keep short, kebab-case, unique across all registered parsers.
  String get id;

  /// Human-readable label. Shown in the debug UI checkbox list.
  String get displayName;

  /// One-line summary of what this parser looks at. Used for tooltips.
  String get description;

  /// Return every normalized path this parser sees referenced in the mod,
  /// mapped to the set of source files that produced the reference.
  /// Source paths are normalized relative to the mod folder (e.g.
  /// `data/weapons/foo.wpn`). Parsers that cannot attribute to a specific
  /// file MAY emit an empty source set; the selector will display just
  /// the parser id for those entries.
  ///
  /// Implementations should short-circuit on `ctx.isCancelled()` in tight
  /// loops.
  Future<Map<String, Set<String>>> collect(
    VramCheckerMod mod,
    List<VramModFile> allFiles,
    VramSelectorContext ctx,
  );
}

/// Insert every path in [paths] into [refs], associating each with
/// [source] (if non-empty). Parsers call this from their collect loops
/// so the map-vs-set bookkeeping doesn't pollute the scan logic.
void addRefsWithSource(
  Map<String, Set<String>> refs,
  Iterable<String> paths,
  String? source,
) {
  final src = source == null || source.isEmpty
      ? null
      : PathNormalizer.normalize(source);
  for (final p in paths) {
    final sources = refs.putIfAbsent(p, () => <String>{});
    if (src != null) sources.add(src);
  }
}
