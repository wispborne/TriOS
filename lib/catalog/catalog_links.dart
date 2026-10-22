import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/catalog_download_resolver.dart';
import 'package:trios/catalog/catalog_manager.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_records_store.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/catalog_search.dart';
import 'package:trios/utils/extensions.dart';

/// One place that answers "which installed mod is this catalog entry?".
///
/// Everything to do with linking a catalog entry to an installed mod lives
/// here: the one standard name key, the one matching function, and the provider
/// the rest of the app reads. Nothing else should build its own matcher or its
/// own name key — that's what let the Catalog page and the records store drift
/// apart and disagree.

/// The one standard way to turn a catalog entry name into a lookup key.
///
/// Used for status-map keys and matcher indexes. [ModRecord.syntheticKey] keeps
/// its own stricter slug (its output is saved on disk and must not change), but
/// its lowercase-and-trim step is the same idea as this.
String catalogEntryKey(String name) => name.toLowerCase().trim();

String _catalogNameMatchKey(String name) =>
    cleanModDisplayName(name).alphanumericLower();

/// Tells catalog entries apart: the permanent id when the entry has one, else
/// the name key. Two entries can share a name, so the name alone isn't enough.
String _entryLinkKey(ModRepoEntry entry) =>
    entry.id ?? catalogEntryKey(entry.name);

/// Which clue produced a match. Recording it costs nothing and helps with
/// debugging and any future screen that wants to show how sure a match is.
enum CatalogLinkSignal { persistedRecord, threadId, nexusId, exactName, fuzzyName }

/// A resolved link between a catalog entry and an installed mod.
class CatalogLink {
  final ModRepoEntry entry;
  final Mod mod;
  final CatalogLinkSignal signal;

  const CatalogLink({
    required this.entry,
    required this.mod,
    required this.signal,
  });
}

/// Matches catalog entries to installed mods. Pure — no reads from providers.
///
/// Clues in order (first that hits wins): a saved install-time record link (by
/// catalog id, then by catalog name), the version-checker forum thread id, the
/// NexusMods id, an exact name, then a close-enough name with version text
/// removed. The saved link normally comes
/// first so an install made through the Catalog stays linked even when the
/// mod's own `mod_info` name differs from the catalog name (the Ashpad/Aashpad
/// case). A match to another entry's own name wins over a shared forum thread
/// or an old saved link made from that thread.
List<CatalogLink> matchCatalogToInstalled({
  required List<ModRepoEntry> entries,
  required List<Mod> installedMods,
  required ModRecords? records,
}) {
  // Index installed mods by the clues a catalog entry can match on.
  final byModId = <String, Mod>{};
  final byThreadId = <String, Mod>{};
  final byNexusId = <String, Mod>{};
  final byName = <String, Mod>{};
  final byFuzzy = <String, Mod>{};
  for (final mod in installedMods) {
    byModId[mod.id] = mod;
    final variant = mod.findHighestVersion;
    final name = variant?.modInfo.name;
    if (name != null && name.trim().isNotEmpty) {
      byName.putIfAbsent(catalogEntryKey(name), () => mod);
      byFuzzy.putIfAbsent(_catalogNameMatchKey(name), () => mod);
    }
    byFuzzy.putIfAbsent(_catalogNameMatchKey(mod.id), () => mod);
    final vci = variant?.versionCheckerInfo;
    final threadId = vci?.modThreadId;
    if (threadId != null) byThreadId.putIfAbsent(threadId, () => mod);
    final nexusId = vci?.modNexusId;
    if (nexusId != null) byNexusId.putIfAbsent(nexusId, () => mod);
  }

  // Saved install-time links: catalog id or catalog entry key -> installed mod
  // id. Only kept when that mod is actually installed, so a stale record can't
  // win. A record with an id links by id only, since two catalog entries can
  // share a name. Records saved before the catalog had ids link by name.
  final persistedModIdByCatalogId = <String, String>{};
  final persistedModIdByKey = <String, String>{};
  if (records != null) {
    for (final record in records.records.values) {
      final modId = record.modId;
      if (modId == null || !byModId.containsKey(modId)) continue;
      final catalogId = record.catalog?.catalogId;
      final catalogName = record.catalog?.name;
      if (catalogId != null) {
        persistedModIdByCatalogId[catalogId] = modId;
      } else if (catalogName != null) {
        persistedModIdByKey[catalogEntryKey(catalogName)] = modId;
      }
    }
  }

  // A forum thread can contain a parent mod and several separate child mods.
  // Reserve an installed mod for any catalog entry that matches its own name.
  // This stops the shared thread id, or an old bad saved link made from that
  // thread id, from assigning the child to the parent entry instead.
  final nameMatchedEntryKeysByModId = <String, Set<String>>{};
  for (final entry in entries) {
    final nameKey = catalogEntryKey(entry.name);
    if (nameKey.isEmpty) continue;
    final nameMatchedMod =
        byName[nameKey] ?? byFuzzy[_catalogNameMatchKey(entry.name)];
    if (nameMatchedMod == null) continue;
    nameMatchedEntryKeysByModId
        .putIfAbsent(nameMatchedMod.id, () => <String>{})
        .add(_entryLinkKey(entry));
  }

  bool hasNameMatchToAnotherEntry(Mod mod, String entryKey) {
    final matchingKeys = nameMatchedEntryKeysByModId[mod.id];
    return matchingKeys != null && matchingKeys.any((key) => key != entryKey);
  }

  final links = <CatalogLink>[];
  for (final entry in entries) {
    final nameKey = catalogEntryKey(entry.name);
    if (nameKey.isEmpty) continue;
    final key = _entryLinkKey(entry);

    Mod? mod;
    CatalogLinkSignal? signal;

    for (final persistedId in [
      if (entry.id != null) persistedModIdByCatalogId[entry.id],
      persistedModIdByKey[nameKey],
    ]) {
      if (persistedId == null) continue;
      final persistedMod = byModId[persistedId];
      if (persistedMod != null &&
          !hasNameMatchToAnotherEntry(persistedMod, key)) {
        mod = persistedMod;
        signal = CatalogLinkSignal.persistedRecord;
        break;
      }
    }

    // An add-on entry shares the parent thread's forum URL, so matching it by
    // thread id would wrongly link it to the parent's installed mod. Add-ons
    // only match by their own name (or a saved link).
    if (mod == null && !entry.isPartOfThread) {
      final threadId = extractForumThreadId(entry.urls?[ModUrlType.Forum]);
      if (threadId != null && byThreadId.containsKey(threadId)) {
        final threadMod = byThreadId[threadId]!;
        if (!hasNameMatchToAnotherEntry(threadMod, key)) {
          mod = threadMod;
          signal = CatalogLinkSignal.threadId;
        }
      }
    }

    if (mod == null && !entry.isPartOfThread) {
      final nexusId = extractNexusModId(entry.urls?[ModUrlType.NexusMods]);
      if (nexusId != null && byNexusId.containsKey(nexusId)) {
        final nexusMod = byNexusId[nexusId]!;
        if (!hasNameMatchToAnotherEntry(nexusMod, key)) {
          mod = nexusMod;
          signal = CatalogLinkSignal.nexusId;
        }
      }
    }

    if (mod == null && byName.containsKey(nameKey)) {
      mod = byName[nameKey];
      signal = CatalogLinkSignal.exactName;
    }

    if (mod == null) {
      final fuzzy = _catalogNameMatchKey(entry.name);
      if (byFuzzy.containsKey(fuzzy)) {
        mod = byFuzzy[fuzzy];
        signal = CatalogLinkSignal.fuzzyName;
      }
    }

    if (mod != null && signal != null) {
      links.add(CatalogLink(entry: entry, mod: mod, signal: signal));
    }
  }
  return links;
}

/// The resolved catalog links, ready to look up from either side.
class CatalogLinks {
  final Map<String, CatalogLink> _byEntryKey;
  final Map<String, CatalogLink> _byName;
  final Map<String, CatalogLink> _byModId;

  CatalogLinks(List<CatalogLink> links)
    : _byEntryKey = {for (final link in links) _entryLinkKey(link.entry): link},
      _byName = {
        for (final link in links.reversed)
          catalogEntryKey(link.entry.name): link,
      },
      _byModId = {for (final link in links) link.mod.id: link};

  /// All links, in no particular order.
  Iterable<CatalogLink> get all => _byEntryKey.values;

  /// The installed mod for a catalog entry, or null when it isn't installed.
  Mod? modForEntry(ModRepoEntry entry) => _byEntryKey[_entryLinkKey(entry)]?.mod;

  /// The link for a catalog entry name, or null when it isn't installed. When
  /// two entries share the name, the first one's link.
  CatalogLink? linkForName(String name) => _byName[catalogEntryKey(name)];

  /// The catalog link for an installed mod id, or null when it has no entry.
  CatalogLink? linkForModId(String modId) => _byModId[modId];
}

/// The full catalog list. Both the Catalog page and [catalogLinksProvider]
/// watch this so they always work from the same list.
final modRepoEntriesProvider = Provider<List<ModRepoEntry>>((ref) {
  final repo = ref.watch(browseModsNotifierProvider).value;
  return repo?.items ?? const <ModRepoEntry>[];
});

/// The one place the app reads catalog links from. Recomputes only when the
/// records, the installed mods, or the catalog changes.
final catalogLinksProvider = Provider<CatalogLinks>((ref) {
  final entries = ref.watch(modRepoEntriesProvider);
  final mods = ref.watch(AppState.mods);
  final records = ref.watch(modRecordsStore).value;
  return CatalogLinks(
    matchCatalogToInstalled(
      entries: entries,
      installedMods: mods,
      records: records,
    ),
  );
});

/// Look up a catalog entry's installed mod straight from a [Mod]. Pass the
/// watched [CatalogLinks] (from [catalogLinksProvider]) so the caller keeps the
/// watch and the models stay free of provider reads.
extension ModCatalogLinkExt on Mod {
  CatalogLink? catalogLink(CatalogLinks links) => links.linkForModId(id);

  ModRepoEntry? catalogEntry(CatalogLinks links) =>
      links.linkForModId(id)?.entry;
}

/// Look up an installed mod straight from a [ModRepoEntry]. Pass the watched
/// [CatalogLinks] (from [catalogLinksProvider]).
extension ModRepoEntryLinkExt on ModRepoEntry {
  Mod? installedMod(CatalogLinks links) => links.modForEntry(this);

  bool isInstalled(CatalogLinks links) => links.modForEntry(this) != null;
}
