/// Shared merge rules for mod data. One entry point per data kind; loaders
/// hand in raw data per source and get merged data back.
///
/// No disk I/O (loaders own scanning and caching) and no viewer-model imports
/// (raw data in, merged data out).
///
/// Checked against decompiled Starsector 0.98a-RC8: `LoadingUtils`,
/// `StarfarerLauncher` (load order), `com.fs.util.C` (source stack).
library;

import 'package:trios/models/mod_variant.dart';
import 'package:trios/utils/log_collapser.dart';

/// Stands in for the game core when data is grouped by source.
const String kVanillaSourceKey = '__vanilla__';

/// Display name for game-core data.
const String kVanillaSourceName = 'Vanilla';

/// The marker a mod puts at the front of a list to wipe the base list first.
const String _coreClearArray = 'core_clearArray';

/// One place data can come from: the game core, or a single mod.
class MergeSource {
  /// The variant's smolId, or [kVanillaSourceKey] for the game core.
  final String key;

  /// Display name: the mod's name, or [kVanillaSourceName].
  final String name;

  /// Null for the game core.
  final ModVariant? variant;

  /// Whether this is the game core (used by the deep merge to pick the base).
  final bool isVanilla;

  const MergeSource({
    required this.key,
    required this.name,
    this.variant,
    this.isVanilla = false,
  });

  MergeSource.fromVariant(ModVariant this.variant)
    : key = variant.smolId,
      name = variant.modInfo.nameOrId,
      isVanilla = false;

  static const vanilla = MergeSource(
    key: kVanillaSourceKey,
    name: kVanillaSourceName,
    isVanilla: true,
  );

  @override
  String toString() => name;
}

/// Sources in the game's load order: mods sorted by `sortString` (falling
/// back to display name), then the game core last.
///
/// Difference from the game: ties between identical sort keys break by mod id
/// here. The game keeps its enabled-mods order, which TriOS can't reproduce.
List<MergeSource> orderedSources(Iterable<ModVariant> variants) => [
  for (final variant in variants.sortedByGameLoadOrder())
    MergeSource.fromVariant(variant),
  MergeSource.vanilla,
];

// ─────────────────────────────────────────────────────────────────────────────
// CSV / spreadsheet merge (first source keeps each key)
// ─────────────────────────────────────────────────────────────────────────────

/// A parsed row plus the source that supplied it.
typedef SourceItems<T> = ({MergeSource source, List<T> items});

/// A merged item paired with the source that supplied it.
typedef MergedItem<T> = ({T item, MergeSource source});

/// Merges parsed objects by id using the CSV rule: first source to supply an
/// id keeps it, later copies (including vanilla) are dropped.
List<T> mergeById<T>(List<SourceItems<T>> sources, String Function(T) idOf) {
  final issues = LogCollapser();
  final result = [
    for (final merged in _mergeFirstSourceWins<T>(
      sources,
      (item) => idOf(item),
      'items',
      issues,
    ))
      merged.item,
  ];
  issues.flush('Merging items');
  return result;
}

/// Merges rows keyed by [keyOf]. The first source to supply a key keeps it;
/// later copies are dropped.
///
/// Blank keys are skipped (vanilla uses blank rows as spacers). A duplicate
/// key within one source keeps the first copy and logs a warning (the game
/// treats this as fatal, but a viewer should not drop the whole list).
List<MergedItem<T>> _mergeFirstSourceWins<T>(
  List<SourceItems<T>> sources,
  String? Function(T) keyOf,
  String what,
  LogCollapser issues,
) {
  final winners = <String, MergedItem<T>>{};

  for (final entry in sources) {
    final seenHere = <String>{};
    for (final item in entry.items) {
      final key = keyOf(item);
      if (key == null || key.isEmpty) continue;

      if (!seenHere.add(key)) {
        issues.add(
          '[${entry.source.name}] duplicate $what key "$key" in one source; '
          'keeping the first and ignoring the rest.',
        );
        continue;
      }
      winners.putIfAbsent(key, () => (item: item, source: entry.source));
    }
  }

  return winners.values.toList();
}

/// Builds a spreadsheet key by joining [keyColumns] with ` | ` (the separator
/// `LoadingUtils` uses). Returns null when all columns are blank.
String? _csvKey(Map<String, dynamic> row, List<String> keyColumns) {
  final parts = [
    for (final column in keyColumns) row[column]?.toString().trim() ?? '',
  ];
  if (parts.every((part) => part.isEmpty)) return null;
  return parts.join(' | ');
}

/// A merged spreadsheet row paired with the source that supplied it.
typedef MergedRow = ({Map<String, dynamic> row, MergeSource source});

/// Merges `descriptions.csv` rows, keyed on `id` + `type`.
List<MergedRow> mergeDescriptions(
  List<SourceItems<Map<String, dynamic>>> sources,
) {
  final issues = LogCollapser();
  final result = _mergeFirstSourceWins<Map<String, dynamic>>(
    sources,
    (row) => _csvKey(row, const ['id', 'type']),
    'descriptions.csv',
    issues,
  ).map((merged) => (row: merged.item, source: merged.source)).toList();
  issues.flush('Merging descriptions.csv');
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Deep merge for JSON side files and config (lowest-priority mod wins)
// ─────────────────────────────────────────────────────────────────────────────

/// How many list entries one source added (for attribution display).
typedef MergeContribution = ({String source, int count});

/// The result of deep merging one file across every source.
class DeepMergeResult {
  /// The merged JSON.
  final Map<String, dynamic> merged;

  /// Dotted key path → how many list entries each source contributed.
  final Map<String, List<MergeContribution>> sectionAttributions;

  /// Dotted key path of the parent → entry or field name → the source that set
  /// it last.
  final Map<String, Map<String, String>> itemAttributions;

  /// Sources that supplied a copy of this file, in application order (game
  /// core first, then mods highest-priority first). Last listed wins scalars.
  final List<MergeSource> contributors;

  const DeepMergeResult({
    required this.merged,
    required this.sectionAttributions,
    required this.itemAttributions,
    required this.contributors,
  });

  static const empty = DeepMergeResult(
    merged: {},
    sectionAttributions: {},
    itemAttributions: {},
    contributors: [],
  );

  /// The source whose scalar values take effect (the last one applied).
  MergeSource? get winningSource =>
      contributors.isEmpty ? null : contributors.last;

  /// Top-level keys each source changed (set a scalar or added list entries).
  /// Used for the mod-attribution display.
  Map<String, Set<String>> topLevelKeysBySource() {
    final result = <String, Set<String>>{};
    void add(String source, String key) =>
        (result[source] ??= <String>{}).add(key);

    itemAttributions.forEach((parentPath, fields) {
      if (parentPath.isEmpty) {
        // Top-level scalars: the field name is itself the top-level key.
        fields.forEach((field, source) => add(source, field));
      } else {
        final top = parentPath.split('.').first;
        for (final source in fields.values) {
          add(source, top);
        }
      }
    });
    sectionAttributions.forEach((path, contribs) {
      final top = path.split('.').first;
      for (final c in contribs) {
        add(c.source, top);
      }
    });
    return result;
  }
}

/// One source's copy of a file, keyed by its path relative to the folder that
/// holds it (`hegemony`, `submarkets/researchfacil`, `homing_laser.wpn`).
typedef SourceFiles = ({
  MergeSource source,
  Map<String, Map<String, dynamic>> filesByPath,
});

/// One source's copy of a single, well-known file.
typedef SourceJson = ({MergeSource source, Map<String, dynamic> json});

/// Deep merges one file across sources.
///
/// The game core is the base. Mods are applied over it highest-priority first,
/// so the alphabetically last mod wins any single value (the opposite direction
/// of the CSV merge).
///
/// [sources] should be in [orderedSources] order. The game core's copy is
/// pulled out and used as the base regardless of its position in the list.
DeepMergeResult _deepMerge(List<SourceJson> sources, LogCollapser issues) {
  final vanilla = sources.where((s) => s.source.isVanilla).toList();
  final mods = sources.where((s) => !s.source.isVanilla).toList();
  final inApplicationOrder = [...vanilla, ...mods];
  if (inApplicationOrder.isEmpty) return DeepMergeResult.empty;

  final merged = <String, dynamic>{};
  final sectionAttributions = <String, List<MergeContribution>>{};
  final itemAttributions = <String, Map<String, String>>{};

  for (final source in inApplicationOrder) {
    _mergeInto(
      merged,
      source.json,
      source.source.name,
      sectionAttributions,
      itemAttributions,
      issues,
      prefix: '',
    );
  }

  return DeepMergeResult(
    merged: merged,
    sectionAttributions: sectionAttributions,
    itemAttributions: itemAttributions,
    contributors: inApplicationOrder.map((s) => s.source).toList(),
  );
}

/// List fields the game treats as a set, so a repeated entry is not a second
/// anything. Two mods both listing a hull's built-in hullmods would otherwise
/// show each one twice.
///
/// Everything not named here keeps its duplicates. `builtInWings` needs them:
/// listing a fighter twice is how a ship gets two bays of it.
const _setLikeListKeys = {
  'builtinmods',
  'removebuiltinmods',
  'hints',
  'addhints',
  'removehints',
  'tags',
  'removetags',
  'renderhints',
};

/// Drops entries of [incoming] that [existing] already has, keeping the order
/// of what is left. Only used for [_setLikeListKeys].
List<dynamic> _withoutRepeats(List<dynamic> existing, List<dynamic> incoming) {
  final seen = existing.toSet();
  return [
    for (final item in incoming)
      if (seen.add(item)) item,
  ];
}

/// Whether a list replaces the base instead of appending.
///
/// From `LoadingUtils.java:384-390`: replaces when the key starts with
/// `music_` (any length), or when the list has exactly 4 entries and the key
/// contains `color` or `button` (case-insensitive). The 4-entry check does
/// not gate the `music_` case.
bool _replacesWholeList(String key, int length) {
  final lower = key.toLowerCase();
  if (lower.startsWith('music_')) return true;
  return length == 4 && (lower.contains('color') || lower.contains('button'));
}

void _mergeInto(
  Map<String, dynamic> target,
  Map<String, dynamic> overlay,
  String sourceName,
  Map<String, List<MergeContribution>> sectionAttributions,
  Map<String, Map<String, String>> itemAttributions,
  LogCollapser issues, {
  required String prefix,
}) {
  for (final entry in overlay.entries) {
    final key = entry.key;
    final overlayValue = entry.value;
    final fullKey = prefix.isEmpty ? key : '$prefix.$key';
    final existing = target[key];

    if (overlayValue is List) {
      if (existing != null && existing is! List) {
        // Type mismatch (game treats this as fatal; we warn and keep the base).
        issues.add(
          '[$sourceName] "$fullKey" is a list here but not in the base data; '
          'keeping the base value.',
        );
        continue;
      }
      final base = existing is List ? existing : const [];

      // Game checks index 0 only, case-sensitive.
      final clears =
          overlayValue.isNotEmpty && overlayValue.first == _coreClearArray;
      // Game leaves the marker in the merged list; TriOS strips it so it
      // doesn't show up as a fleet entry.
      final incoming = overlayValue
          .where((e) => e != _coreClearArray)
          .toList();
      final afterClear = clears ? const [] : base;

      if (clears) {
        sectionAttributions.remove(fullKey);
        itemAttributions.remove(fullKey);
      }

      // Game checks the base list's length. When there is no base, use the
      // incoming length (appending and replacing produce the same result).
      final lengthForRule = afterClear.isEmpty
          ? incoming.length
          : afterClear.length;
      if (_replacesWholeList(key, lengthForRule)) {
        target[key] = incoming;
        continue;
      }

      final added = _setLikeListKeys.contains(key.toLowerCase())
          ? _withoutRepeats(afterClear, incoming)
          : incoming;

      target[key] = [...afterClear, ...added];
      if (added.isNotEmpty) {
        _addContribution(
          sectionAttributions,
          fullKey,
          sourceName,
          added.length,
        );
        for (final item in added) {
          if (item is String) {
            itemAttributions.putIfAbsent(fullKey, () => {})[item] = sourceName;
          }
        }
      }
    } else if (overlayValue is Map<String, dynamic>) {
      if (existing != null && existing is! Map<String, dynamic>) {
        // Type mismatch (same as the list case above).
        issues.add(
          '[$sourceName] "$fullKey" is an object here but not in the base data; '
          'keeping the base value.',
        );
        continue;
      }
      final Map<String, dynamic> child;
      if (existing is Map<String, dynamic>) {
        child = existing;
      } else {
        child = <String, dynamic>{};
        target[key] = child;
      }
      _mergeInto(
        child,
        overlayValue,
        sourceName,
        sectionAttributions,
        itemAttributions,
        issues,
        prefix: fullKey,
      );
    } else {
      // Scalar: last writer wins. Recorded under the parent section for
      // per-field attribution.
      target[key] = overlayValue;
      itemAttributions.putIfAbsent(prefix, () => {})[key] = sourceName;
    }
  }
}

void _addContribution(
  Map<String, List<MergeContribution>> attributions,
  String key,
  String sourceName,
  int count,
) {
  final list = attributions.putIfAbsent(key, () => []);
  final index = list.indexWhere((c) => c.source == sourceName);
  if (index >= 0) {
    list[index] = (source: sourceName, count: list[index].count + count);
  } else {
    list.add((source: sourceName, count: count));
  }
}

/// Deep merges every `.faction` file across sources, one result per path.
///
/// Matched on path relative to `data/world/factions`, not on the `id` field
/// inside the file. See [_deepMerge] for merge direction.
Map<String, DeepMergeResult> mergeFactions(List<SourceFiles> sources) {
  final issues = LogCollapser();
  final result = _mergeFilesByPath(sources, issues);
  issues.flush('Merging factions');
  return result;
}

/// Deep merges `data/config/engine_styles.json` across sources.
DeepMergeResult mergeEngineStyles(List<SourceJson> sources) {
  final issues = LogCollapser();
  final result = _deepMerge(sources, issues);
  issues.flush('Merging engine styles');
  return result;
}

/// Deep merges `data/world/factions/default_ship_roles.json`.
DeepMergeResult mergeShipRoles(List<SourceJson> sources) {
  final issues = LogCollapser();
  final result = _deepMerge(sources, issues);
  issues.flush('Merging ship roles');
  return result;
}

/// Deep merges `data/config/hull_styles.json` across sources.
DeepMergeResult mergeHullStyles(List<SourceJson> sources) {
  final issues = LogCollapser();
  final result = _deepMerge(sources, issues);
  issues.flush('Merging hull styles');
  return result;
}

Map<String, DeepMergeResult> _mergeFilesByPath(
  List<SourceFiles> sources,
  LogCollapser issues,
) {
  final paths = <String>{for (final s in sources) ...s.filesByPath.keys};
  return {
    for (final path in paths)
      path: _deepMerge([
        for (final source in sources)
          if (source.filesByPath[path] case final json?)
            (source: source.source, json: json),
      ], issues),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Paired merge: CSV rows + side files resolved independently, then joined
// ─────────────────────────────────────────────────────────────────────────────

/// A spreadsheet row paired with its side file, both already resolved.
///
/// Rows and side files are resolved independently, so [rowSource] and
/// [sideFileSource] can be different mods.
class MergedSpec {
  final String id;

  /// The spreadsheet row that takes effect.
  final Map<String, dynamic> row;

  /// The source that supplied [row] (what the game attributes the item to).
  final MergeSource rowSource;

  /// The merged side file, or null when no source provides one.
  final Map<String, dynamic>? sideFile;

  /// The source whose side-file values take effect (last applied). Null when
  /// there is no side file.
  final MergeSource? sideFileSource;

  /// The side file's path relative to its data folder, e.g. `homing_laser.wpn`.
  final String? sideFilePath;

  /// Every source that supplied a row for this id, in priority order.
  /// [rowSource] is first; the rest are overridden.
  final List<MergeSource> rowContributors;

  /// Sources that supplied a side file, in application order
  /// ([sideFileSource] is last). Empty when there is no side file.
  final List<MergeSource> sideFileContributors;

  /// Top-level side-file keys each source changed.
  /// See [DeepMergeResult.topLevelKeysBySource].
  final Map<String, Set<String>> sideFileChangedKeys;

  const MergedSpec({
    required this.id,
    required this.row,
    required this.rowSource,
    this.sideFile,
    this.sideFileSource,
    this.sideFilePath,
    this.rowContributors = const [],
    this.sideFileContributors = const [],
    this.sideFileChangedKeys = const {},
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Mod attribution (display-ready mod sources for one item)
// ─────────────────────────────────────────────────────────────────────────────

/// One source's contribution to an item, for the mod-attribution display.
class ModSourceChange {
  final String sourceName;
  final bool isVanilla;

  /// Whether this source's scalar values take effect in the side file.
  final bool isWinner;

  /// Friendly names of the areas this source changed. Empty for vanilla.
  final List<String> areas;

  const ModSourceChange({
    required this.sourceName,
    required this.isVanilla,
    required this.isWinner,
    required this.areas,
  });
}

/// Mod-attribution summary for one ship or weapon, ready to display.
class ItemModSources {
  /// False for ship skins, which have no spreadsheet row of their own.
  final bool hasStatsRow;

  /// The source whose spreadsheet row the game uses.
  final String statsWinner;

  /// Other sources with a row for this id (overridden, no effect).
  final List<String> statsIgnored;

  /// Side-file contributors, effective source first, vanilla last.
  final List<ModSourceChange> fileSources;

  const ItemModSources({
    required this.hasStatsRow,
    required this.statsWinner,
    required this.statsIgnored,
    required this.fileSources,
  });

  /// The effective side-file source, or null when there is none.
  String? get fileWinner => fileSources.isEmpty ? null : fileSources.first.sourceName;
}

/// Maps raw top-level keys to friendly area names using [friendly], collapsing
/// duplicates. Keys mapped to empty string are hidden. Unknown keys become
/// "other details".
List<String> mapAreaNames(Set<String> rawKeys, Map<String, String> friendly) {
  final out = <String>[];
  friendly.forEach((rawKey, name) {
    if (name.isEmpty) return;
    if (rawKeys.contains(rawKey) && !out.contains(name)) out.add(name);
  });
  if (rawKeys.any((k) => !friendly.containsKey(k))) out.add('other details');
  return out;
}

/// Builds the display-ready mod-source attribution for one merged item.
///
/// [areaNames] maps raw side-file keys to friendly names (domain-specific,
/// so each loader passes its own).
ItemModSources buildItemModSources({
  required List<MergeSource> rowContributors,
  required List<MergeSource> sideFileContributors,
  required Map<String, Set<String>> sideFileChangedKeys,
  required Map<String, String> areaNames,
  bool hasStatsRow = true,
}) {
  final statsWinner = rowContributors.isNotEmpty
      ? rowContributors.first.name
      : kVanillaSourceName;
  final statsIgnored = rowContributors.skip(1).map((s) => s.name).toList();

  final fileSources = <ModSourceChange>[];
  if (sideFileContributors.isNotEmpty) {
    // The last source applied wins the shared values.
    final winner = sideFileContributors.last;
    ModSourceChange toChange(MergeSource s) => ModSourceChange(
      sourceName: s.name,
      isVanilla: s.isVanilla,
      isWinner: identical(s, winner),
      areas: s.isVanilla
          ? const []
          : mapAreaNames(sideFileChangedKeys[s.name] ?? const {}, areaNames),
    );

    fileSources.add(toChange(winner));
    final rest = sideFileContributors.where((s) => !identical(s, winner));
    // Other mods first, the game core (the base) last.
    for (final s in rest.where((s) => !s.isVanilla)) {
      fileSources.add(toChange(s));
    }
    for (final s in rest.where((s) => s.isVanilla)) {
      fileSources.add(toChange(s));
    }
  }

  return ItemModSources(
    hasStatsRow: hasStatsRow,
    statsWinner: statsWinner,
    statsIgnored: statsIgnored,
    fileSources: fileSources,
  );
}

/// Merges `weapon_data.csv` rows and `.wpn` side files, paired by id.
List<MergedSpec> mergeWeapons({
  required List<SourceItems<Map<String, dynamic>>> rows,
  required List<SourceFiles> sideFiles,
}) {
  final issues = LogCollapser();
  final result = _mergeSpecs(
    rows: rows,
    sideFiles: sideFiles,
    what: 'weapon',
    sideFileKind: '.wpn',
    sideFileIdField: 'id',
    issues: issues,
  );
  issues.flush('Merging weapons');
  return result;
}

/// Merges `ship_data.csv` rows and `.ship` side files, paired by id.
List<MergedSpec> mergeShips({
  required List<SourceItems<Map<String, dynamic>>> rows,
  required List<SourceFiles> sideFiles,
}) {
  final issues = LogCollapser();
  final result = _mergeSpecs(
    rows: rows,
    sideFiles: sideFiles,
    what: 'ship',
    // `.ship` files name their hull `hullId`, not `id`.
    sideFileKind: '.ship',
    sideFileIdField: 'hullId',
    issues: issues,
  );
  issues.flush('Merging ships');
  return result;
}

/// Merges `.skin` files by path. Skins have no spreadsheet row, so they are
/// separate from [mergeShips].
Map<String, DeepMergeResult> mergeShipSkins(List<SourceFiles> sources) {
  final issues = LogCollapser();
  final result = _mergeFilesByPath(sources, issues);
  issues.flush('Merging ship skins');
  return result;
}

/// Shared implementation for [mergeWeapons] and [mergeShips].
///
/// CSV rows and side files are resolved independently, then paired by id.
///
/// Differences from the game: a row with no side file anywhere still produces
/// an item (empty side-file fields + warning) instead of being dropped. Two
/// side files in one source with the same id are resolved alphabetically by
/// path (the game uses an unsorted folder listing, so the result is random).
List<MergedSpec> _mergeSpecs({
  required List<SourceItems<Map<String, dynamic>>> rows,
  required List<SourceFiles> sideFiles,
  required String what,
  required String sideFileKind,
  required String sideFileIdField,
  required LogCollapser issues,
}) {
  final mergedRows = _mergeFirstSourceWins<Map<String, dynamic>>(
    rows,
    (row) => _csvKey(row, const ['id']),
    '$what id',
    issues,
  );

  // Row sources per id, in priority order (first is the effective one).
  final rowSourcesById = <String, List<MergeSource>>{};
  for (final entry in rows) {
    final seenHere = <String>{};
    for (final item in entry.items) {
      final key = _csvKey(item, const ['id']);
      if (key == null || !seenHere.add(key)) continue;
      (rowSourcesById[key] ??= []).add(entry.source);
    }
  }

  final mergedFiles = _mergeFilesByPath(sideFiles, issues);

  // Map each item id to its merged side file. Duplicate ids across paths
  // keep the first (higher-priority source).
  final byId = <String, ({String path, DeepMergeResult file})>{};
  for (final path in _pathsInResolutionOrder(sideFiles)) {
    final file = mergedFiles[path];
    if (file == null) continue;
    final id = file.merged[sideFileIdField]?.toString();
    if (id == null || id.isEmpty) continue;

    final existing = byId[id];
    if (existing != null) {
      issues.add(
        'Two $sideFileKind files both declare $what id "$id": '
        '"${existing.path}" is used and "$path" is ignored.',
      );
      continue;
    }
    byId[id] = (path: path, file: file);
  }

  final specs = <MergedSpec>[];
  final pairedIds = <String>{};

  for (final merged in mergedRows) {
    final id = merged.item['id'].toString().trim();
    final side = byId[id];
    if (side == null) {
      issues.add(
        '[${merged.source.name}] no $sideFileKind file for $what id "$id" in '
        'any mod. Showing the row without it (the $what will be missing in '
        'the game too).',
      );
    } else {
      pairedIds.add(id);
    }

    specs.add(
      MergedSpec(
        id: id,
        row: merged.item,
        rowSource: merged.source,
        sideFile: side?.file.merged,
        sideFileSource: side?.file.winningSource,
        sideFilePath: side?.path,
        rowContributors: rowSourcesById[id] ?? [merged.source],
        sideFileContributors: side?.file.contributors ?? const [],
        sideFileChangedKeys:
            side?.file.topLevelKeysBySource() ?? const {},
      ),
    );
  }

  // Side files with no matching CSV row are skipped (game drops them too).
  for (final entry in byId.entries) {
    if (pairedIds.contains(entry.key)) continue;
    issues.add(
      '$sideFileKind file "${entry.value.path}" declares $what id '
      '"${entry.key}", which no spreadsheet row defines. Skipping it.',
    );
  }

  return specs;
}

/// Side-file paths in resolution order: source by source in [orderedSources]
/// order, alphabetically within one source.
///
/// The alphabetical part is TriOS's own (the game's folder listing is
/// unsorted, so its order within one source is nondeterministic).
List<String> _pathsInResolutionOrder(List<SourceFiles> sources) {
  final seen = <String>{};
  final ordered = <String>[];
  for (final source in sources) {
    for (final path in source.filesByPath.keys.toList()..sort()) {
      if (seen.add(path)) ordered.add(path);
    }
  }
  return ordered;
}
