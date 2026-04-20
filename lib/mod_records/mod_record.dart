import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_records/mod_record_source.dart';

part 'mod_record.mapper.dart';

/// A persistent record that links all known sources of information about a mod.
///
/// Each record has a thin top level (identity only) and a [sources] map
/// containing typed sub-entries for each place the mod was found
/// (installed on disk, in the catalog, version checker, download history).
/// Names and authors live within the source sub-entries; use [allNames] and
/// [allAuthors] to aggregate across resolved sources.
@MappableClass()
class ModRecord with ModRecordMappable {
  /// Primary key: mod ID or `catalog:{normalized_name}`.
  final String recordKey;

  /// The canonical mod ID from mod_info.json, if known.
  final String? modId;

  /// When this mod was first encountered by TriOS.
  final DateTime? firstSeen;

  /// Source-specific data, keyed by source type string
  /// ('installed', 'catalog', 'versionChecker', 'downloadHistory').
  /// Written by auto-population only.
  final Map<String, ModRecordSource> sources;

  /// User-edited overrides, keyed by the same source type strings.
  /// Fields that are non-null here take priority over [sources].
  /// Auto-population never touches this map.
  final Map<String, ModRecordSource> userOverrides;

  ModRecord({
    required this.recordKey,
    this.modId,
    this.firstSeen,
    this.sources = const {},
    this.userOverrides = const {},
  });

  // --- Resolved sources (auto-populated + user overrides) ---
  //
  // All computed values below are `late final`: cached on first access per
  // instance. `ModRecord` is immutable — new values only arrive via copyWith
  // or merge, which build fresh instances — so these caches never go stale.
  // dart_mappable only looks at constructor-declared fields, so these extras
  // don't affect serialization, ==, or hashCode.

  /// Merges [userOverrides] onto [sources] field-by-field.
  /// For matching keys of the same runtime type, calls applyOverridesFrom.
  /// If only one side has a key, uses it directly.
  late final Map<String, ModRecordSource> resolvedSources =
      _computeResolvedSources();

  Map<String, ModRecordSource> _computeResolvedSources() {
    if (userOverrides.isEmpty) return sources;
    if (sources.isEmpty) return userOverrides;

    final allKeys = {...sources.keys, ...userOverrides.keys};
    final resolved = <String, ModRecordSource>{};
    for (final key in allKeys) {
      final source = sources[key];
      final override = userOverrides[key];
      if (source != null && override != null) {
        // Same-type merge via applyOverridesFrom.
        resolved[key] = switch (source) {
          InstalledSource s when override is InstalledSource =>
            s.applyOverridesFrom(override),
          VersionCheckerSource s when override is VersionCheckerSource =>
            s.applyOverridesFrom(override),
          CatalogSource s when override is CatalogSource =>
            s.applyOverridesFrom(override),
          DownloadHistorySource s when override is DownloadHistorySource =>
            s.applyOverridesFrom(override),
          ForumDataSource s when override is ForumDataSource =>
            s.applyOverridesFrom(override),
          // Different types: override wins entirely.
          _ => override,
        };
      } else {
        resolved[key] = override ?? source!;
      }
    }
    return resolved;
  }

  // --- Typed source accessors (use resolved values) ---

  late final InstalledSource? installed =
      resolvedSources['installed'] as InstalledSource?;

  late final CatalogSource? catalog =
      resolvedSources['catalog'] as CatalogSource?;

  late final VersionCheckerSource? versionChecker =
      resolvedSources['versionChecker'] as VersionCheckerSource?;

  late final DownloadHistorySource? downloadHistory =
      resolvedSources['downloadHistory'] as DownloadHistorySource?;

  late final ForumDataSource? forumData =
      resolvedSources['forumData'] as ForumDataSource?;

  // --- Computed aggregation getters ---

  /// All known display names aggregated from resolved sources.
  late final Set<String> allNames = _computeAllNames();

  Set<String> _computeAllNames() {
    final names = <String>{};
    final instName = installed?.name;
    if (instName != null) names.add(instName);
    final catName = catalog?.name;
    if (catName != null) names.add(catName);
    return names;
  }

  /// All known authors aggregated from resolved sources.
  late final Set<String> allAuthors = _computeAllAuthors();

  Set<String> _computeAllAuthors() {
    final authors = <String>{};
    final instAuthor = installed?.author;
    if (instAuthor != null) authors.add(instAuthor);
    final catAuthors = catalog?.authors;
    if (catAuthors != null) authors.addAll(catAuthors);
    return authors;
  }

  // --- Convenience getters that resolve across sources ---

  /// Forum thread ID from version checker or catalog.
  late final String? forumThreadId =
      versionChecker?.forumThreadId ?? catalog?.forumThreadId;

  /// NexusMods mod ID from version checker or catalog.
  late final String? nexusModsId =
      versionChecker?.nexusModsId ?? catalog?.nexusModsId;

  // --- Static helpers ---

  /// Generates a synthetic key for a catalog-only mod.
  static String syntheticKey(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    return 'catalog:$normalized';
  }

  /// Constructs a forum URL from a thread ID.
  static String forumUrlFromThreadId(String threadId) =>
      'https://fractalsoftworks.com/forum/index.php?topic=$threadId';

  /// Constructs a NexusMods URL from a mod ID.
  static String nexusUrlFromModId(String nexusId) =>
      'https://www.nexusmods.com/starsector/mods/$nexusId';

  /// Merges this record with [other], combining sources maps.
  /// For each source key, keeps the newer one (by lastSeen).
  /// Keeps real mod ID over synthetic.
  /// Preserves userOverrides from both sides (this side wins on conflicts).
  ModRecord merge(ModRecord other) {
    final mergedSources = Map<String, ModRecordSource>.of(sources);
    for (final entry in other.sources.entries) {
      final existing = mergedSources[entry.key];
      if (existing == null) {
        mergedSources[entry.key] = entry.value;
      } else {
        // Prefer the newer source (by lastSeen), or the incoming one if equal/null.
        final existingTime = existing.lastSeen;
        final otherTime = entry.value.lastSeen;
        if (existingTime == null ||
            (otherTime != null && !existingTime.isAfter(otherTime))) {
          mergedSources[entry.key] = entry.value;
        }
      }
    }

    // Merge userOverrides: keep ours, add any from other that we don't have.
    final mergedOverrides = Map<String, ModRecordSource>.of(userOverrides);
    for (final entry in other.userOverrides.entries) {
      mergedOverrides.putIfAbsent(entry.key, () => entry.value);
    }

    return ModRecord(
      recordKey: modId ?? other.modId ?? recordKey,
      modId: modId ?? other.modId,
      firstSeen: _earliest(firstSeen, other.firstSeen),
      sources: mergedSources,
      userOverrides: mergedOverrides,
    );
  }

  static DateTime? _earliest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }
}

/// Wrapper class for persisting a map of [ModRecord]s.
@MappableClass()
class ModRecords with ModRecordsMappable {
  final Map<String, ModRecord> records;

  const ModRecords({this.records = const {}});
}
