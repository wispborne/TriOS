import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_links.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_record_source.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';
import 'package:trios/utils/logging.dart';

import '../catalog/forum_data_manager.dart';
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

    // Re-populate whenever forum data is refreshed.
    ref.listen(forumDataProvider, (prev, next) {
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
    final forumIndex = ref.read(forumDataByTopicId);
    final now = DateTime.now();
    bool isDirty = false;

    final records = Map<String, ModRecord>.of(current.records);

    // Match catalog entries to installed mods with the shared matcher, which
    // puts saved install-time links first. Keyed by mod id so every variant of
    // a mod sees the same entry, and refreshed from current catalog data each
    // pass so linked records stay up to date as the catalog changes.
    final links = matchCatalogToInstalled(
      entries: catalog,
      installedMods: ref.read(AppState.mods),
      records: current,
    );
    final matchedCatalogByModId = <String, CatalogMod>{};
    for (final link in links) {
      matchedCatalogByModId.putIfAbsent(link.mod.id, () => link.entry);
    }
    final matchedCatalogNames = {for (final link in links) link.entry.name};

    // Process installed mods.
    for (final variant in modVariants) {
      final modId = variant.modInfo.id;
      final existing = records[modId];
      final vci = variant.versionCheckerInfo;

      // Build source sub-entries.
      final sourcesMap = <String, ModRecordSource>{};

      // 1. Installed source.
      sourcesMap['installed'] = InstalledSource(
        name: variant.modInfo.name,
        author: variant.modInfo.author,
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

      // 3. Catalog source, from the shared matcher (refreshed each pass).
      final matchedCatalog = matchedCatalogByModId[modId];
      if (matchedCatalog != null) {
        sourcesMap['catalog'] = _buildCatalogSource(matchedCatalog, now);
      }

      final newRecord = ModRecord(
        recordKey: modId,
        modId: modId,
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
    for (final catalogMod in catalog) {
      if (matchedCatalogNames.contains(catalogMod.name)) continue;

      final syntheticKey = ModRecord.syntheticKey(catalogMod.name);

      // Skip if already merged into a real-ID record.
      if (records.values.any(
        (r) => r.catalog?.name == catalogMod.name && r.modId != null,
      )) {
        if (records.containsKey(syntheticKey)) {
          records.remove(syntheticKey);
          isDirty = true;
        }
        continue;
      }

      final existing = records[syntheticKey];
      final catalogSource = _buildCatalogSource(catalogMod, now);

      final newRecord = ModRecord(
        recordKey: syntheticKey,
        firstSeen: existing?.firstSeen ?? now,
        sources: {'catalog': catalogSource},
      );

      final merged = existing != null ? existing.merge(newRecord) : newRecord;
      if (records[syntheticKey] != merged) {
        records[syntheticKey] = merged;
        isDirty = true;
      }
    }

    // Attach forum data to records that have a matching forumThreadId.
    if (forumIndex.isNotEmpty) {
      for (final entry in records.entries) {
        final record = entry.value;
        final threadId = record.forumThreadId;
        if (threadId == null) continue;
        final topicId = int.tryParse(threadId);
        if (topicId == null) continue;
        final forumEntry = forumIndex[topicId];
        if (forumEntry == null) continue;

        final forumSource = ForumDataSource(
          topicId: forumEntry.topicId,
          views: forumEntry.views,
          replies: forumEntry.replies,
          lastPostDate: forumEntry.lastPostDate,
          lastPostBy: forumEntry.lastPostBy,
          createdDate: forumEntry.createdDate,
          isWip: forumEntry.isWip,
          isArchived: forumEntry.isArchivedModIndex,
          inModIndex: forumEntry.inModIndex,
          category: forumEntry.category,
          gameVersion: forumEntry.gameVersion,
          thumbnailPath: forumEntry.thumbnailPath,
          lastSeen: now,
        );

        final existingForum = record.sources['forumData'];
        if (existingForum is ForumDataSource &&
            existingForum.topicId == forumSource.topicId &&
            existingForum.views == forumSource.views &&
            existingForum.replies == forumSource.replies) {
          continue; // No change.
        }

        final updatedSources = Map<String, ModRecordSource>.of(record.sources);
        updatedSources['forumData'] = forumSource;
        records[entry.key] = record.copyWith(sources: updatedSources);
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

  /// Builds a [CatalogSource] from a [CatalogMod].
  CatalogSource _buildCatalogSource(CatalogMod catalogMod, DateTime now) {
    final urls = catalogMod.getUrls();
    final forumUrl = urls[ModUrlType.Forum];
    final nexusUrl = urls[ModUrlType.NexusMods];
    return CatalogSource(
      name: catalogMod.name,
      authors: catalogMod.getAuthors().isNotEmpty
          ? catalogMod.getAuthors()
          : null,
      forumUrl: forumUrl,
      nexusUrl: nexusUrl,
      discordUrl: urls[ModUrlType.Discord],
      directDownloadUrl: urls[ModUrlType.DirectDownload],
      downloadPageUrl: urls[ModUrlType.DownloadPage],
      forumThreadId: extractForumThreadId(forumUrl),
      nexusModsId: extractNexusModId(nexusUrl),
      categories: catalogMod.getCategories(),
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

  /// Links an installed mod to the catalog entry it was installed from. Called
  /// at install completion, once the real mod id is known.
  ///
  /// Merges the catalog-only record (keyed by the catalog name, e.g. "Ashpad")
  /// into the real mod's record — carrying over its catalog source, forum data,
  /// and any user overrides — then makes sure a catalog source is attached even
  /// when there was no catalog-only record to merge.
  Future<void> linkCatalogEntryToMod(
    String modId,
    DownloadSourceHint hint,
  ) async {
    final catalogName = hint.catalogName;
    if (catalogName == null) return;

    final syntheticKey = ModRecord.syntheticKey(catalogName);
    if (state.valueOrNull?.records.containsKey(syntheticKey) == true) {
      await mergeSyntheticIntoReal(syntheticKey, modId);
    }

    await updateRecord(modId, (existing) {
      final now = DateTime.now();
      final base =
          existing ??
          ModRecord(recordKey: modId, modId: modId, firstSeen: now);
      // The merge above may already have carried a catalog source over.
      if (base.sources['catalog'] != null) {
        return base.copyWith(modId: modId);
      }
      // Otherwise attach one: from the current catalog entry when it's loaded,
      // a bare one built from the hint when it isn't.
      final catalog =
          ref.read(browseModsNotifierProvider).valueOrNull?.items ??
          const <CatalogMod>[];
      final key = catalogEntryKey(catalogName);
      final catalogMod = catalog.firstWhereOrNull(
        (m) => catalogEntryKey(m.name) == key,
      );
      final catalogSource = catalogMod != null
          ? _buildCatalogSource(catalogMod, now)
          : CatalogSource(
              name: catalogName,
              forumThreadId: hint.forumThreadId,
              nexusModsId: hint.nexusModsId,
              lastSeen: now,
            );
      final updatedSources = Map<String, ModRecordSource>.of(base.sources);
      updatedSources['catalog'] = catalogSource;
      return base.copyWith(modId: modId, sources: updatedSources);
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
      (r) => r!.catalog?.name?.toLowerCase().trim() == normalized,
      orElse: () => null,
    );
  }

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
