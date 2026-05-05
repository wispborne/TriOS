import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector_config.dart';
import 'package:trios/vram_estimator/selectors/references/data_config_json_references.dart';
import 'package:trios/vram_estimator/selectors/references/data_csv_references.dart';
import 'package:trios/vram_estimator/selectors/references/faction_references.dart';
import 'package:trios/vram_estimator/selectors/references/frame_animation_references.dart';
import 'package:trios/vram_estimator/selectors/references/graphicslib_references.dart';
import 'package:trios/vram_estimator/selectors/references/jar_string_references.dart';
import 'package:trios/vram_estimator/selectors/references/java_source_references.dart';
import 'package:trios/vram_estimator/selectors/references/phase_glow_references.dart';
import 'package:trios/vram_estimator/selectors/references/portrait_references.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/references/settings_graphics_references.dart';
import 'package:trios/vram_estimator/selectors/references/ship_references.dart';
import 'package:trios/vram_estimator/selectors/references/weapon_references.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';
import 'package:trios/vram_estimator/selectors/vram_selector_id.dart';

// ADD NEW REFERENCE PARSERS BELOW. Each must normalize its paths via
// PathNormalizer so union / intersection work on a single canonical form.
// Adding a new parser is: (a) one new file under references/, (b) one
// entry in this list, (c) add its id to
// ReferencedAssetsSelectorConfig.allEnabled if you want it on by default.
final List<ReferenceParser> _allParsers = <ReferenceParser>[
  ShipReferences(),
  WeaponReferences(),
  FactionReferences(),
  PortraitReferences(),
  SettingsGraphicsReferences(),
  DataConfigJsonReferences(),
  DataCsvReferences(),
  GraphicsLibReferenceParser(),
  JarStringReferences(),
  JavaSourceReferences(),
  FrameAnimationReferences(),
  PhaseGlowReferences(),
];

/// Expose the registered parsers so the settings UI can render one
/// checkbox per parser without the UI knowing their identities.
List<ReferenceParser> get registeredReferenceParsers =>
    List.unmodifiable(_allParsers);

/// Selects only image files a mod actually references. Parses static
/// reference sources (data files, GraphicsLib CSV, JAR strings, Java
/// source strings) to build a referenced-path set, intersects with
/// on-disk image files, and (unless `suppressUnreferenced` is set)
/// reports the rest as `AssetProvenance.unreferenced` for advisory
/// display.
class ReferencedAssetsSelector extends VramAssetSelector {
  final ReferencedAssetsSelectorConfig config;

  ReferencedAssetsSelector({required this.config});

  @override
  VramSelectorId get id => VramSelectorId.referenced;

  @override
  String get displayName => 'Selective Scan';

  @override
  String get description =>
      "Searches the mod's text files and code for image paths. "
      "More accurate than folder scan, but takes longer.";

  @override
  Future<List<SelectedAsset>> select(
    VramCheckerMod mod,
    List<VramModFile> allFiles,
    VramSelectorContext ctx,
  ) async {
    // Run enabled parsers. Attribution is always tracked — the dialog
    // surfaces it per row, and the overhead is negligible compared to
    // the scan itself.
    //
    // Per-path attribution carries two levels: the parser id that found
    // the reference, and the set of source files (normalized relative
    // paths) that each parser attributes the reference to. The flattened
    // `"parserId: source"` strings are produced only at the intersection
    // step so we don't repeatedly build them for paths that don't end up
    // on disk.
    final referencedPaths = <String>{};
    final attribution = <String, Map<String, Set<String>>>{};

    void mergeParserResult(
      String parserId,
      Map<String, Set<String>> result,
    ) {
      for (final entry in result.entries) {
        referencedPaths.add(entry.key);
        final byParser = attribution.putIfAbsent(
          entry.key,
          () => <String, Set<String>>{},
        );
        byParser.putIfAbsent(parserId, () => <String>{}).addAll(entry.value);
      }
    }

    for (final parser in _allParsers) {
      if (ctx.isCancelled()) break;
      if (!config.enabledParserIds.contains(parser.id)) continue;
      try {
        final start = ctx.showPerformance
            ? DateTime.timestamp().millisecondsSinceEpoch
            : 0;
        final result = await parser.collect(mod, allFiles, ctx);
        mergeParserResult(parser.id, result);
        if (ctx.showPerformance) {
          final took = DateTime.timestamp().millisecondsSinceEpoch - start;
          ctx.verboseOut(
            "[VramChecker] parser=${parser.id} mod=${mod.modId} "
            "paths=${result.length} time=${took}ms",
          );
        }
      } catch (e) {
        ctx.verboseOut(
          '[ReferencedAssetsSelector] Parser "${parser.id}" failed: $e',
        );
      }
    }

    // Second pass(es): expand the referenced set with engine-auto-loaded
    // siblings. These depend on the union of everything above, so they
    // can't be regular parsers. Each matched sibling is attributed to the
    // already-referenced anchor path(s) that caused the match.
    Future<void> runExpander(
      String parserId,
      Future<Map<String, Set<String>>> Function() run,
      String label,
    ) async {
      if (ctx.isCancelled()) return;
      if (!config.enabledParserIds.contains(parserId)) return;
      try {
        final start = ctx.showPerformance
            ? DateTime.timestamp().millisecondsSinceEpoch
            : 0;
        final result = await run();
        mergeParserResult(parserId, result);
        if (ctx.showPerformance) {
          final took =
              DateTime.timestamp().millisecondsSinceEpoch - start;
          ctx.verboseOut(
            "[VramChecker] parser=$parserId mod=${mod.modId} "
            "paths=${result.length} time=${took}ms",
          );
        }
      } catch (e) {
        ctx.verboseOut(
          '[ReferencedAssetsSelector] $label expansion failed: $e',
        );
      }
    }

    await runExpander(
      FrameAnimationReferences.parserId,
      () => FrameAnimationReferences.expand(
        referencedPaths: referencedPaths,
        allFiles: allFiles,
        ctx: ctx,
      ),
      'Frame-animation',
    );
    await runExpander(
      PhaseGlowReferences.parserId,
      () => PhaseGlowReferences.expand(
        referencedPaths: referencedPaths,
        allFiles: allFiles,
        ctx: ctx,
      ),
      'Phase-glow',
    );

    // Intersect with on-disk image files; produce SelectedAsset entries.
    final intersectStart = ctx.showPerformance
        ? DateTime.timestamp().millisecondsSinceEpoch
        : 0;
    final result = <SelectedAsset>[];
    var sinceYield = 0;
    for (final file in allFiles) {
      if (ctx.isCancelled()) break;
      if (!_isImage(file)) continue;
      // Periodic yield — a mod with many thousand images would otherwise
      // hold the UI thread for the full length of this loop.
      if (++sinceYield >= 512) {
        sinceYield = 0;
        await Future<void>.delayed(Duration.zero);
      }

      final normalized = PathNormalizer.normalize(file.relativePath);
      final mapType = GraphicsLibReferences.mapTypeFor(
        mod,
        file,
        ctx.graphicsLibEntries,
      );
      final isReferenced = referencedPaths.contains(normalized);

      if (isReferenced) {
        result.add(
          SelectedAsset(
            file: file,
            graphicsLibType: mapType,
            provenance: AssetProvenance.referenced,
            referencedBy: _flattenAttribution(attribution[normalized]),
          ),
        );
      } else if (!config.suppressUnreferenced) {
        result.add(
          SelectedAsset(
            file: file,
            graphicsLibType: mapType,
            provenance: AssetProvenance.unreferenced,
          ),
        );
      }
    }

    if (ctx.showPerformance) {
      final took = DateTime.timestamp().millisecondsSinceEpoch - intersectStart;
      ctx.verboseOut(
        "[VramChecker] intersect mod=${mod.modId} "
        "referencedPaths=${referencedPaths.length} "
        "selectedAssets=${result.length} time=${took}ms",
      );
    }

    return result;
  }

  /// Flatten per-parser attribution into the `List<String>` consumed by
  /// `SelectedAsset.referencedBy` and the dialog. Each entry is either
  /// `"parserId"` (when no source file is known) or
  /// `"parserId: data/path/to/source.ext"`. Parsers and sources are sorted
  /// for deterministic display order.
  static List<String> _flattenAttribution(
    Map<String, Set<String>>? byParser,
  ) {
    if (byParser == null || byParser.isEmpty) return const <String>[];
    final out = <String>[];
    final parserIds = byParser.keys.toList()..sort();
    for (final pid in parserIds) {
      final sources = byParser[pid]!;
      if (sources.isEmpty) {
        out.add(pid);
      } else {
        final sorted = sources.toList()..sort();
        for (final src in sorted) {
          out.add('$pid: $src');
        }
      }
    }
    return List.unmodifiable(out);
  }

  static bool _isImage(VramModFile file) {
    final p = file.file.path.toLowerCase();
    return p.endsWith('.png') ||
        p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.gif') ||
        p.endsWith('.webp');
  }
}
