import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/mod_records/mod_record_source.dart';

part 'mod_record.mapper.dart';

/// A persistent record that links all known sources of information about a mod.
///
/// Each record has a thin top level (identity + aggregated names/authors) and
/// a [sources] map containing typed sub-entries for each place the mod was found
/// (installed on disk, in the catalog, version checker, download history).
@MappableClass()
class ModRecord with ModRecordMappable {
  /// Primary key: mod ID or `catalog:{normalized_name}`.
  final String recordKey;

  /// The canonical mod ID from mod_info.json, if known.
  final String? modId;

  /// All known display names for this mod (unioned from all sources).
  final Set<String> names;

  /// All known authors for this mod (unioned from all sources).
  final Set<String> authors;

  /// When this mod was first encountered by TriOS.
  final DateTime? firstSeen;

  /// Source-specific data, keyed by source type string
  /// ('installed', 'catalog', 'versionChecker', 'downloadHistory').
  final Map<String, ModRecordSource> sources;

  ModRecord({
    required this.recordKey,
    this.modId,
    this.names = const {},
    this.authors = const {},
    this.firstSeen,
    this.sources = const {},
  });

  // --- Typed source accessors ---

  InstalledSource? get installed => sources['installed'] as InstalledSource?;

  CatalogSource? get catalog => sources['catalog'] as CatalogSource?;

  VersionCheckerSource? get versionChecker =>
      sources['versionChecker'] as VersionCheckerSource?;

  DownloadHistorySource? get downloadHistory =>
      sources['downloadHistory'] as DownloadHistorySource?;

  // --- Convenience getters that resolve across sources ---

  /// Forum thread ID from version checker or catalog.
  String? get forumThreadId =>
      versionChecker?.forumThreadId ?? catalog?.forumThreadId;

  /// NexusMods mod ID from version checker or catalog.
  String? get nexusModsId =>
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
  /// Unions names/authors. Keeps real mod ID over synthetic.
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
    return ModRecord(
      recordKey: modId ?? other.modId ?? recordKey,
      modId: modId ?? other.modId,
      names: {...names, ...other.names},
      authors: {...authors, ...other.authors},
      firstSeen: _earliest(firstSeen, other.firstSeen),
      sources: mergedSources,
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
