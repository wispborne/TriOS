import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/models/scraped_mod.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_record_source.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';
import 'package:trios/utils/logging.dart';

import '../catalog/mod_browser_manager.dart';

/// Riverpod provider for the mod records store.
final modRecordsStore =
    AsyncNotifierProvider<ModRecordsStore, ModRecords>(ModRecordsStore.new);

/// Manages persistent mod source records, providing CRUD operations and
/// auto-population from installed mods, version checker data, and the catalog.
class ModRecordsStore extends GenericSettingsAsyncNotifier<ModRecords> {
  @override
  GenericAsyncSettingsManager<ModRecords> createSettingsManager() =>
      _ModRecordsManager();

  @override
  ModRecords createDefaultState() => const ModRecords();

  @override
  Future<ModRecords> build() async {
    final records = await super.build();

    // Auto-populate after initial load.
    _autoPopulate(records);

    // Re-populate whenever mod variants change.
    ref.listen(AppState.modVariants, (prev, next) {
      final current = state.valueOrNull;
      if (current != null && next.hasValue) {
        _autoPopulate(current);
      }
    });

    // Re-populate whenever catalog data is refreshed.
    ref.listen(browseModsNotifierProvider, (prev, next) {
      final current = state.valueOrNull;
      if (current != null && next.hasValue) {
        _autoPopulate(current);
      }
    });

    return records;
  }

  /// Cross-references installed mods, version checker info, and the catalog
  /// to build/update records with typed source sub-entries.
  void _autoPopulate(ModRecords current) {
    final modVariants = ref.read(AppState.modVariants).value ?? [];
    final catalogAsync = ref.read(browseModsNotifierProvider);
    final catalog = catalogAsync.valueOrNull?.items ?? [];
    final now = DateTime.now();
    bool isDirty = false;

    final records = Map<String, ModRecord>.of(current.records);

    // Build indexes from catalog for matching.
    final catalogByForumThreadId = <String, ScrapedMod>{};
    final catalogByNexusId = <String, ScrapedMod>{};
    final catalogByNormalizedName = <String, ScrapedMod>{};
    // Alphanumeric-only index for fuzzy matching (e.g. "Box Util" → "boxutil").
    final catalogByAlphanumName = <String, ScrapedMod>{};
    final matchedCatalogNames = <String>{};

    for (final scraped in catalog) {
      final forumUrl = scraped.urls?[ModUrlType.Forum];
      if (forumUrl != null) {
        final threadId = _extractForumThreadId(forumUrl);
        if (threadId != null) {
          catalogByForumThreadId[threadId] = scraped;
        }
      }

      final nexusUrl = scraped.urls?[ModUrlType.NexusMods];
      if (nexusUrl != null) {
        final nexusId = _extractNexusModId(nexusUrl);
        if (nexusId != null) {
          catalogByNexusId[nexusId] = scraped;
        }
      }

      catalogByNormalizedName[scraped.name.toLowerCase().trim()] = scraped;
      catalogByAlphanumName[_alphanumOnly(scraped.name)] = scraped;
    }

    // Process installed mods.
    for (final variant in modVariants) {
      final modId = variant.modInfo.id;
      final existing = records[modId];
      final vci = variant.versionCheckerInfo;

      final names = <String>{};
      if (variant.modInfo.name != null) names.add(variant.modInfo.name!);
      final authors = <String>{};
      if (variant.modInfo.author != null) authors.add(variant.modInfo.author!);

      // Build source sub-entries.
      final sourcesMap = <String, ModRecordSource>{};

      // 1. Installed source.
      sourcesMap['installed'] = InstalledSource(
        installPath: variant.modFolder.path,
        version: variant.bestVersion?.toString(),
        lastSeen: now,
      );

      // 2. Version checker source (if available).
      if (vci != null &&
          (vci.modThreadId != null ||
              vci.modNexusId != null ||
              vci.directDownloadURL != null ||
              vci.masterVersionFile != null)) {
        sourcesMap['versionChecker'] = VersionCheckerSource(
          forumThreadId: vci.modThreadId,
          nexusModsId: vci.modNexusId,
          directDownloadUrl: vci.directDownloadURL,
          changelogUrl: vci.changelogURL,
          masterVersionFileUrl: vci.masterVersionFile,
          lastSeen: now,
        );
      }

      // 3. Catalog source (try to match by thread ID, Nexus ID, then name).
      ScrapedMod? matchedCatalog;
      final forumThreadId = vci?.modThreadId;
      final nexusModsId = vci?.modNexusId;

      if (forumThreadId != null &&
          catalogByForumThreadId.containsKey(forumThreadId)) {
        matchedCatalog = catalogByForumThreadId[forumThreadId];
      } else if (nexusModsId != null &&
          catalogByNexusId.containsKey(nexusModsId)) {
        matchedCatalog = catalogByNexusId[nexusModsId];
      } else {
        // Try exact name match first.
        final nameKey = (variant.modInfo.name ?? modId).toLowerCase().trim();
        if (catalogByNormalizedName.containsKey(nameKey)) {
          matchedCatalog = catalogByNormalizedName[nameKey];
        } else {
          // Fuzzy match: strip all non-alphanumeric chars, compare.
          // Try both mod name and mod ID (e.g. "BoxUtil" matches "Box Util").
          final fuzzyName = _alphanumOnly(variant.modInfo.name ?? modId);
          matchedCatalog = catalogByAlphanumName[fuzzyName];
          if (matchedCatalog == null && variant.modInfo.name != null) {
            // Also try mod ID if name didn't match.
            matchedCatalog = catalogByAlphanumName[_alphanumOnly(modId)];
          }
        }
      }

      if (matchedCatalog != null) {
        matchedCatalogNames.add(matchedCatalog.name);
        if (matchedCatalog.getAuthors().isNotEmpty) {
          authors.addAll(matchedCatalog.getAuthors());
        }
        sourcesMap['catalog'] = _buildCatalogSource(matchedCatalog, now);
      }

      final newRecord = ModRecord(
        recordKey: modId,
        modId: modId,
        names: names,
        authors: authors,
        firstSeen: existing?.firstSeen ?? now,
        sources: sourcesMap,
      );

      final merged = existing != null ? existing.merge(newRecord) : newRecord;
      if (records[modId] != merged) {
        records[modId] = merged;
        isDirty = true;
      }
    }

    // Create records for unmatched catalog entries (catalog-only mods).
    for (final scraped in catalog) {
      if (matchedCatalogNames.contains(scraped.name)) continue;

      final syntheticKey = ModRecord.syntheticKey(scraped.name);

      // Skip if already merged into a real-ID record.
      if (records.values.any(
        (r) => r.catalog?.catalogName == scraped.name && r.modId != null,
      )) {
        if (records.containsKey(syntheticKey)) {
          records.remove(syntheticKey);
          isDirty = true;
        }
        continue;
      }

      final existing = records[syntheticKey];
      final catalogSource = _buildCatalogSource(scraped, now);

      final newRecord = ModRecord(
        recordKey: syntheticKey,
        names: {scraped.name},
        authors: scraped.getAuthors().toSet(),
        firstSeen: existing?.firstSeen ?? now,
        sources: {'catalog': catalogSource},
      );

      final merged = existing != null ? existing.merge(newRecord) : newRecord;
      if (records[syntheticKey] != merged) {
        records[syntheticKey] = merged;
        isDirty = true;
      }
    }

    if (isDirty) {
      Fimber.i(
        "ModRecords auto-populated: ${records.length} records "
        "(${modVariants.length} installed, ${catalog.length} catalog).",
      );
      updateState((s) => ModRecords(records: records));
    }
  }

  /// Builds a [CatalogSource] from a [ScrapedMod].
  CatalogSource _buildCatalogSource(ScrapedMod scraped, DateTime now) {
    final urls = scraped.getUrls();
    final forumUrl = urls[ModUrlType.Forum];
    final nexusUrl = urls[ModUrlType.NexusMods];
    return CatalogSource(
      catalogName: scraped.name,
      forumUrl: forumUrl,
      nexusUrl: nexusUrl,
      discordUrl: urls[ModUrlType.Discord],
      directDownloadUrl: urls[ModUrlType.DirectDownload],
      downloadPageUrl: urls[ModUrlType.DownloadPage],
      forumThreadId:
          forumUrl != null ? _extractForumThreadId(forumUrl) : null,
      nexusModsId: nexusUrl != null ? _extractNexusModId(nexusUrl) : null,
      categories: scraped.getCategories(),
      lastSeen: now,
    );
  }

  /// Updates the record for [key] with the given mutator function.
  Future<void> updateRecord(
    String key,
    ModRecord Function(ModRecord? existing) updater,
  ) async {
    await updateState((current) {
      final records = Map<String, ModRecord>.of(current.records);
      records[key] = updater(records[key]);
      return ModRecords(records: records);
    });
  }

  /// Merges a synthetic-key record into a real mod ID record.
  /// Call this when a catalog-only mod is installed and its real ID is discovered.
  Future<void> mergeSyntheticIntoReal(
    String syntheticKey,
    String realModId,
  ) async {
    await updateState((current) {
      final records = Map<String, ModRecord>.of(current.records);
      final synthetic = records.remove(syntheticKey);
      if (synthetic != null) {
        final existing = records[realModId];
        final merged =
            existing != null
                ? existing.merge(synthetic)
                : synthetic.copyWith(recordKey: realModId, modId: realModId);
        records[realModId] = merged;
      }
      return ModRecords(records: records);
    });
  }

  // --- Lookup helpers ---

  ModRecord? lookupByModId(String modId) =>
      state.valueOrNull?.records[modId];

  ModRecord? lookupByForumThreadId(String threadId) =>
      state.valueOrNull?.records.values.cast<ModRecord?>().firstWhere(
        (r) => r!.forumThreadId == threadId,
        orElse: () => null,
      );

  ModRecord? lookupByNexusModId(String nexusId) =>
      state.valueOrNull?.records.values.cast<ModRecord?>().firstWhere(
        (r) => r!.nexusModsId == nexusId,
        orElse: () => null,
      );

  ModRecord? lookupByCatalogName(String name) {
    final normalized = name.toLowerCase().trim();
    return state.valueOrNull?.records.values.cast<ModRecord?>().firstWhere(
      (r) => r!.catalog?.catalogName?.toLowerCase().trim() == normalized,
      orElse: () => null,
    );
  }

  // --- URL extraction helpers ---

  static String? _extractForumThreadId(String url) {
    final match = RegExp(r'topic=(\d+)').firstMatch(url);
    return match?.group(1);
  }

  static String? _extractNexusModId(String url) {
    final match = RegExp(r'/mods/(\d+)').firstMatch(url);
    return match?.group(1);
  }

  /// Strips all non-alphanumeric characters and lowercases for fuzzy matching.
  /// e.g. "Box Util" → "boxutil", "zz BoxUtil" → "zzboxutil".
  static String _alphanumOnly(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

/// Persistence manager for mod records.
class _ModRecordsManager extends GenericAsyncSettingsManager<ModRecords> {
  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => 'trios_mod_records-v1.${fileFormat.name}';

  @override
  ModRecords Function(Map<String, dynamic> map) get fromMap =>
      (json) => ModRecordsMapper.fromMap(json);

  @override
  Map<String, dynamic> Function(ModRecords) get toMap =>
      (state) => state.toMap();
}
