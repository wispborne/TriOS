import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/models/graphics_lib_info.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';
import 'package:trios/vram_estimator/selectors/references/reference_parser.dart';
import 'package:trios/vram_estimator/selectors/vram_asset_selector.dart';

/// A [ReferenceParser] that exposes a mod's GraphicsLib CSV entries as
/// references. Reference-mode uses this so CSV-declared maps survive the
/// reference filter regardless of whether a base sprite is referenced.
class GraphicsLibReferenceParser extends ReferenceParser {
  @override
  String get id => 'graphicslib';

  @override
  String get displayName => 'GraphicsLib maps (CSV + cache folder)';

  @override
  String get description =>
      "Map paths declared in the mod's GraphicsLib CSV, plus GraphicsLib "
      "mod's own cache/ folder. Kept independently of base-sprite references.";

  @override
  Future<Map<String, Set<String>>> collect(
    VramCheckerMod mod,
    List<VramModFile> allFiles,
    VramSelectorContext ctx,
  ) async {
    return GraphicsLibReferences.referencedPathsWithSources(
      mod,
      allFiles,
      ctx.graphicsLibEntries,
    );
  }
}

/// Parses a mod's GraphicsLib CSV (columns `id,type,map,path`) and provides
/// helpers to classify images by [MapType]. Shared by every selector so
/// the CSV is parsed once per mod regardless of which selector is active.
class GraphicsLibReferences {
  static const _csvReader = CsvToListConverter(
    allowInvalid: true,
    convertEmptyTo: null,
  );

  /// Parse the GraphicsLib CSV from the given mod's files, if any.
  /// Returns an empty list when no matching CSV is found. Async so large
  /// CSVs don't block the UI thread on disk read.
  static Future<List<GraphicsLibInfo>> parse(
    VramCheckerMod mod,
    List<VramModFile> allFiles, {
    void Function(String)? onError,
  }) async {
    final csvFiles =
        allFiles.where((it) => it.file.nameWithExtension.endsWith(".csv"));
    List<List<dynamic>?>? csvRows;
    for (final file in csvFiles) {
      try {
        final contents =
            (await file.file.readAsString()).replaceAll("\r\n", "\n");
        final rows = _csvReader.convert(contents, eol: "\n");
        if (rows.isNotEmpty &&
            rows.first?.containsAll(["id", "type", "map", "path"]) == true) {
          csvRows = rows;
          break;
        }
      } catch (e) {
        onError?.call("Unable to read ${file.file.path}: $e");
      }
    }

    if (csvRows == null) {
      return [];
    }

    final idCol = csvRows.first!.indexOf("id");
    final mapCol = csvRows.first!.indexOf("map");
    final pathCol = csvRows.first!.indexOf("path");

    return csvRows
        .map((List<dynamic>? row) {
          try {
            final mapType = switch (row![mapCol]) {
              "normal" => MapType.Normal,
              "material" => MapType.Material,
              "surface" => MapType.Surface,
              _ => null,
            };
            if (mapType == null) return null;
            final path = row[pathCol].trim();
            return GraphicsLibInfo(row[idCol], mapType, p.normalize(path));
          } catch (e) {
            onError?.call("$row - $e");
          }
          return null;
        })
        .nonNulls
        .toList();
  }

  /// Expose GraphicsLib CSV rows as a set of normalized referenced paths,
  /// plus any images in GraphicsLib mod's `cache/` folder. Used by
  /// `ReferencedAssetsSelector` to ensure maps survive the reference filter.
  static Set<String> referencedPaths(
    VramCheckerMod mod,
    List<VramModFile> allFiles,
    List<GraphicsLibInfo> csvEntries,
  ) {
    return referencedPathsWithSources(mod, allFiles, csvEntries).keys.toSet();
  }

  /// Like [referencedPaths] but also reports the source file for each
  /// reference. CSV-declared maps are attributed to the first GraphicsLib
  /// CSV found in the mod; cache folder images are attributed to
  /// themselves (each file is its own source).
  static Map<String, Set<String>> referencedPathsWithSources(
    VramCheckerMod mod,
    List<VramModFile> allFiles,
    List<GraphicsLibInfo> csvEntries,
  ) {
    final refs = <String, Set<String>>{};

    // GraphicsLib CSV source attribution: `parse()` finds the CSV by
    // header match but doesn't expose which file it picked. We don't
    // re-scan here (duplicate I/O); instead, best-effort attribute to
    // a `.csv` whose path looks like a GraphicsLib manifest. If none
    // fits, attribution falls back to just the parser id.
    final csvSource = csvEntries.isEmpty
        ? null
        : allFiles
            .firstWhereOrNull(
              (f) {
                final norm = PathNormalizer.normalize(f.relativePath);
                return norm.endsWith('.csv') &&
                    (norm.contains('graphics_options') ||
                        norm.contains('data/config/'));
              },
            )
            ?.relativePath;

    for (final entry in csvEntries) {
      addRefsWithSource(
        refs,
        PathNormalizer.expand(entry.relativeFilePath),
        csvSource,
      );
    }
    if (mod.modId == Constants.graphicsLibId) {
      for (final f in allFiles) {
        if (f.file.path.contains('cache')) {
          addRefsWithSource(
            refs,
            PathNormalizer.expand(f.relativePath),
            f.relativePath,
          );
        }
      }
    }
    return refs;
  }

  /// Return the [MapType] for a file in a mod, combining CSV lookup with the
  /// GraphicsLib-mod `cache/` hardcode (everything in that folder is a
  /// Normal map, regardless of CSV contents).
  static MapType? mapTypeFor(
    VramCheckerMod mod,
    VramModFile file,
    List<GraphicsLibInfo> csvEntries,
  ) {
    if (mod.modId == Constants.graphicsLibId &&
        file.file.path.contains("cache")) {
      return MapType.Normal;
    }
    return csvEntries
        .firstWhereOrNull((it) => it.relativeFilePath == file.relativePath)
        ?.mapType;
  }
}
