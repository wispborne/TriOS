import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/catalog/forum_data_manager.dart';
import 'package:trios/catalog/mod_browser_manager.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
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

/// Which clue produced a match. Recording it costs nothing and helps with
/// debugging and any future screen that wants to show how sure a match is.
enum CatalogLinkSignal { persistedRecord, threadId, nexusId, exactName, fuzzyName }

/// A resolved link between a catalog entry and an installed mod.
class CatalogLink {
  final CatalogMod entry;
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
/// Clues in order (first that hits wins): a saved install-time record link, the
/// version-checker forum thread id, the NexusMods id, an exact name, then a
/// close-enough (letters-and-numbers-only) name. The saved link comes first so
/// an install made through the Catalog stays linked even when the mod's own
/// `mod_info` name differs from the catalog name (the Ashpad/Aashpad case).
List<CatalogLink> matchCatalogToInstalled({
  required List<CatalogMod> entries,
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
      byFuzzy.putIfAbsent(name.alphanumericLower(), () => mod);
    }
    byFuzzy.putIfAbsent(mod.id.alphanumericLower(), () => mod);
    final vci = variant?.versionCheckerInfo;
    final threadId = vci?.modThreadId;
    if (threadId != null) byThreadId.putIfAbsent(threadId, () => mod);
    final nexusId = vci?.modNexusId;
    if (nexusId != null) byNexusId.putIfAbsent(nexusId, () => mod);
  }

  // Saved install-time links: catalog entry key -> installed mod id. Only kept
  // when that mod is actually installed, so a stale record can't win.
  final persistedModIdByKey = <String, String>{};
  if (records != null) {
    for (final record in records.records.values) {
      final modId = record.modId;
      final catalogName = record.catalog?.name;
      if (modId == null || catalogName == null) continue;
      if (!byModId.containsKey(modId)) continue;
      persistedModIdByKey[catalogEntryKey(catalogName)] = modId;
    }
  }

  final links = <CatalogLink>[];
  for (final entry in entries) {
    final key = catalogEntryKey(entry.name);
    if (key.isEmpty) continue;

    Mod? mod;
    CatalogLinkSignal? signal;

    final persistedId = persistedModIdByKey[key];
    if (persistedId != null) {
      mod = byModId[persistedId];
      signal = CatalogLinkSignal.persistedRecord;
    }

    // An add-on entry shares the parent thread's forum URL, so matching it by
    // thread id would wrongly link it to the parent's installed mod. Add-ons
    // only match by their own name (or a saved link).
    if (mod == null && !entry.isPartOfThread) {
      final threadId = extractForumThreadId(entry.urls?[ModUrlType.Forum]);
      if (threadId != null && byThreadId.containsKey(threadId)) {
        mod = byThreadId[threadId];
        signal = CatalogLinkSignal.threadId;
      }
    }

    if (mod == null && !entry.isPartOfThread) {
      final nexusId = extractNexusModId(entry.urls?[ModUrlType.NexusMods]);
      if (nexusId != null && byNexusId.containsKey(nexusId)) {
        mod = byNexusId[nexusId];
        signal = CatalogLinkSignal.nexusId;
      }
    }

    if (mod == null && byName.containsKey(key)) {
      mod = byName[key];
      signal = CatalogLinkSignal.exactName;
    }

    if (mod == null) {
      final fuzzy = entry.name.alphanumericLower();
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
  final Map<String, CatalogLink> _byModId;

  CatalogLinks(List<CatalogLink> links)
    : _byEntryKey = {
        for (final link in links) catalogEntryKey(link.entry.name): link,
      },
      _byModId = {for (final link in links) link.mod.id: link};

  /// All links, in no particular order.
  Iterable<CatalogLink> get all => _byEntryKey.values;

  /// The installed mod for a catalog entry, or null when it isn't installed.
  Mod? modForEntry(CatalogMod entry) => _byEntryKey[catalogEntryKey(entry.name)]?.mod;

  /// The link for a catalog entry name, or null when it isn't installed.
  CatalogLink? linkForName(String name) => _byEntryKey[catalogEntryKey(name)];

  /// The catalog link for an installed mod id, or null when it has no entry.
  CatalogLink? linkForModId(String modId) => _byModId[modId];
}

/// The full catalog list the page shows: real entries plus the made-up "part of
/// a thread" add-on entries. Both the Catalog page and [catalogLinksProvider]
/// watch this so they always work from the same list.
final catalogEntriesProvider = Provider<List<CatalogMod>>((ref) {
  final repo = ref.watch(browseModsNotifierProvider).value;
  final realMods = repo?.items ?? const <CatalogMod>[];
  final forumLookup = ref.watch(forumDataByTopicId);
  return withSynthesizedAddonEntries(realMods, forumLookup);
});

/// The one place the app reads catalog links from. Recomputes only when the
/// records, the installed mods, or the catalog changes.
final catalogLinksProvider = Provider<CatalogLinks>((ref) {
  final entries = ref.watch(catalogEntriesProvider);
  final mods = ref.watch(AppState.mods);
  final records = ref.watch(modRecordsStore).valueOrNull;
  return CatalogLinks(
    matchCatalogToInstalled(
      entries: entries,
      installedMods: mods,
      records: records,
    ),
  );
});

/// Adds made-up cards for mods that only live inside another mod's forum
/// thread. For each thread that lists more than one mod, every mod that doesn't
/// already have its own catalog entry becomes a made-up card, marked with the
/// thread title so the card can show `part of <thread>`.
///
/// A thread's "main" mod isn't special-cased: the catalog entry that
/// points at the thread often has a different name (e.g. it's a different mod in
/// the same thread), so relying on the name match below is what keeps the real
/// main mod from being both listed and made up — and stops a main mod with no
/// catalog entry of its own from going missing.
///
/// Drops duplicate made-up names across threads (first thread wins), so a mod
/// that appears in several threads isn't listed twice.
List<CatalogMod> withSynthesizedAddonEntries(
  List<CatalogMod> realMods,
  Map<int, ForumModIndex> forumLookup,
) {
  if (realMods.isEmpty || forumLookup.isEmpty) return realMods;

  final existingNames = {
    for (final mod in realMods)
      if (mod.name.trim().isNotEmpty) mod.name.toLowerCase().trim(),
  };
  final synthesizedNames = <String>{};
  final synthesized = <CatalogMod>[];

  for (final mod in realMods) {
    final forumUrl = mod.urls?[ModUrlType.Forum];
    final topicId = extractForumTopicId(forumUrl);
    if (topicId == null) continue;
    final index = forumLookup[topicId];
    final llm = index?.llm;
    if (index == null || llm == null || llm.mods.length < 2) continue;

    for (final llmMod in llm.mods) {
      final key = llmMod.name.toLowerCase().trim();
      if (key.isEmpty) continue;
      if (existingNames.contains(key)) continue;
      if (!synthesizedNames.add(key)) continue;

      synthesized.add(
        CatalogMod(
          name: llmMod.name,
          summary: llmMod.extras?.summary?.sentence,
          description: llmMod.extras?.summary?.paragraph,
          // Prefer the thread's game version; fall back to the parent mod's
          // so add-ons stay visible under the default Game Version filter
          // even when the thread itself lists no version.
          gameVersionReq: index.gameVersion ?? mod.gameVersionReq,
          authorsList: mod.authorsList,
          urls: {ModUrlType.Forum: ?forumUrl},
          partOfThreadTitle: index.title,
        ),
      );
    }
  }

  if (synthesized.isEmpty) return realMods;
  return [...realMods, ...synthesized];
}

/// Look up a catalog entry's installed mod straight from a [Mod]. Pass the
/// watched [CatalogLinks] (from [catalogLinksProvider]) so the caller keeps the
/// watch and the models stay free of provider reads.
extension ModCatalogLinkExt on Mod {
  CatalogLink? catalogLink(CatalogLinks links) => links.linkForModId(id);

  CatalogMod? catalogEntry(CatalogLinks links) =>
      links.linkForModId(id)?.entry;
}

/// Look up an installed mod straight from a [CatalogMod]. Pass the watched
/// [CatalogLinks] (from [catalogLinksProvider]).
extension CatalogModLinkExt on CatalogMod {
  Mod? installedMod(CatalogLinks links) => links.modForEntry(this);

  bool isInstalled(CatalogLinks links) => links.modForEntry(this) != null;
}
