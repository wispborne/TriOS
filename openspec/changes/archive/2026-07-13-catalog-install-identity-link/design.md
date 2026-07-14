# Design

## Current flow (and where the link is lost)

```
Catalog card / forum dialog (knows ScrapedMod + thread id)
  → executeDownloadCandidate(modName, url)          ← identity cut down to a name string
    → confirmAndDownloadModViaManager(modName, url)
      → DownloadManagerNotifier.downloadAndInstallMod(displayName, uri)
        → Download object (no source info)
        → batchInstallationProvider.addLateEntry(file, download)
          → finish: installedMods have real mod ids…
            → mergeSyntheticIntoReal(syntheticKey(modInfo.nameOrId), modId)  ← wrong key
```

Display side: `CatalogPageController._buildCatalogStatusMap()` matches catalog → installed by version-checker thread id, then exact name, then close-enough name, then fills gaps from records that have both a catalog source and a mod id. `ModRecordsStore._autoPopulate()` runs its own separate copy of nearly the same matching (it also checks NexusMods ids). The fix makes the saved-record path actually get used, and merges the two matchers into one shared module.

## New piece 1: shared linking module — `lib/catalog/catalog_links.dart`

One file that owns the "which installed mod is this catalog entry?" question. Three parts:

**One name key.** A single way to clean up catalog-entry name keys:

```dart
String catalogEntryKey(String name) => name.toLowerCase().trim();
```

Used for status-map keys, matcher indexes, and `ModRecord.syntheticKey` (which keeps its `catalog:` prefix and stricter slug but hands off the cleanup step). Today three different ways of doing this coexist (`toLowerCase().trim()`, `alphanumericLower()`, `syntheticKey`'s regex); the Ashpad merge failure was a wrong-key bug. `alphanumericLower()` stays, but only *inside* the matcher as the close-enough clue — never as a key that callers build themselves.

**Matcher.** A plain function used by both the records store and the provider below:

```dart
enum CatalogLinkSignal { persistedRecord, threadId, nexusId, exactName, fuzzyName }

class CatalogLink {
  final ScrapedMod entry;
  final Mod mod;
  final CatalogLinkSignal signal;
}

List<CatalogLink> matchCatalogToInstalled({
  required List<ScrapedMod> entries,
  required List<Mod> installedMods,
  required ModRecords? records, // saved install-time links win
});
```

Clues in order: saved record link (a record with a mod id whose catalog source names the entry) → version-checker thread id → NexusMods id → exact name → close-enough name. Recording *which* clue matched costs nothing and helps with debugging and any future screen that wants to show how sure the match is.

**Provider.** What the whole app reads:

```dart
final catalogLinksProvider = Provider<CatalogLinks>(...); // watches records, mods, catalog

class CatalogLinks {
  Mod? modForEntry(ScrapedMod entry);      // "is this card installed?"
  CatalogLink? linkForModId(String modId); // "what's this mod's catalog entry?"
  // internally: Map<String /*catalogEntryKey*/, CatalogLink>, Map<String /*modId*/, CatalogLink>
}
```

Built from `modRecordsStore` + `AppState.mods` + the catalog (including the made-up add-on entries). The Catalog page, dialogs, and future features watch this instead of building their own maps. It also moves the matching work out of the controller's `build()` — it now runs only when one of the three inputs changes.

**Easy-to-find extensions.** In the same file, so autocomplete shows the link from either side. The `links` argument is passed in on purpose — same style as `mod.updateCheck(versionCheckState)` and `variant.mod(mods)` — which keeps the models free of persistence, keeps the import direction catalog → models, and forces callers to have watched the provider:

```dart
extension ModCatalogLinkExt on Mod {
  CatalogLink? catalogLink(CatalogLinks links) => links.linkForModId(id);
  ScrapedMod? catalogEntry(CatalogLinks links) => links.linkForModId(id)?.entry;
}

extension ScrapedModLinkExt on ScrapedMod {
  Mod? installedMod(CatalogLinks links) => links.modForEntry(this);
  bool isInstalled(CatalogLinks links) => links.modForEntry(this) != null;
}
```

No `Ref`-taking versions — hiding the watch behind an extension invites stale-state bugs.

Which piece depends on which, to avoid a loop: the records store's `_autoPopulate` calls the plain `matchCatalogToInstalled` function directly (records are an *input* to it); the provider sits on top of records. The provider never feeds back into the store.

## New piece 2: `DownloadSourceHint`

A small unchangeable class (plain Dart, not saved to disk — it lives only for the length of a download):

```dart
class DownloadSourceHint {
  final String? catalogName;    // exact catalog name, e.g. "Ashpad"
  final String? forumThreadId;
  final String? nexusModsId;
}
```

Location: `lib/trios/download_manager/download_manager.dart` (next to `Download`).

Why not save it straight to disk? The saved form already exists — `CatalogSource` on a `ModRecord`. The hint just carries the info from the click to the moment we know the mod ID.

Why carry `catalogName` and not only the thread id? One forum thread can hold several mods (the made-up "part of <thread>" add-on cards share the parent's thread URL). The name points at the exact catalog entry; the thread id alone could mean any of them.

## Changes by file

### 1. `lib/trios/download_manager/download_manager.dart`

- Add `final DownloadSourceHint? sourceHint` to `Download` (constructor param, default null).
- `addDownload(...)` and `downloadAndInstallMod(...)` get a **required** (nullable) `sourceHint` param, stored on the `Download`. Required-but-nullable means every current and future call site has to state its source out loud — passing `sourceHint: null` is a choice you can see, not a silent default. Non-catalog callers (version-checker updates, drag-drop) pass null.
- Download-history record fix: keep the existing write only when `modInfo != null` (key = mod id). When `modInfo == null`, skip it — the finish step (below) writes download history once we know the real mod ID. This stops the disconnected records filed under a display name.

### 2. `lib/catalog/download_confirm.dart`

`confirmAndDownloadModViaManager` gets an optional `sourceHint` and passes it on to `downloadAndInstallMod`.

### 3. Catalog callers — build the hint where the `ScrapedMod` is in hand

- `lib/catalog/download_candidate_actions.dart`: `executeDownloadCandidate` gets a **required** `sourceHint` param and passes it to `confirmAndDownloadModViaManager` and to the deep-link handler (below). Build the hint from the catalog mod: name, `extractForumThreadId(urls[Forum])`, `extractNexusModId(urls[NexusMods])` — add a `DownloadSourceHint.fromScrapedMod()` factory so call sites can't put it together wrong.
- Callers that make the call: `scraped_mod_card.dart`, `mod_browser_page.dart`, `forum_post_dialog.dart` (its `_confirmAndDownload` uses the dialog's topic id + the mod name the row belongs to), `scraped_mod_details_dialog.dart`.

### 4. Deep-link path — `lib/trios/deep_link/deep_link_handler.dart`

`handleUriString` gets an optional `sourceHint`. It is used in `_downloadAndInstall` **only when the deep link points at exactly one mod entry** — a trilink from a catalog card is one mod; applying one catalog identity to a multi-mod link would link the wrong things.

### 5. `lib/mod_records/mod_records_store.dart`

New method used when the install finishes:

```dart
Future<void> linkCatalogEntryToMod(String modId, DownloadSourceHint hint)
```

- Joins the catalog-only record `ModRecord.syntheticKey(hint.catalogName)` into `modId` (through the existing `mergeSyntheticIntoReal`), which carries over the catalog source, forum data, and any user overrides.
- If there was no catalog-only record (or it had no catalog source), looks up the catalog mod by name in the current catalog and attaches a fresh `CatalogSource` (reusing `_buildCatalogSource`); falls back to a bare `CatalogSource(name, forumThreadId, nexusModsId)` when the catalog isn't loaded.

`_autoPopulate` change: replace its inline thread-id/nexus/name/close-enough matching with a call to the shared `matchCatalogToInstalled`, which puts the saved record link first. This makes the install-time link the one to trust, stops the guesses from overwriting it with a different entry, and deletes one of the two copies of the matcher. It also refreshes the `CatalogSource` from current catalog data on each pass, so linked records stay up to date as the catalog changes.

### 6. `lib/mod_manager/batch_installation/batch_installation_notifier.dart` (finish step, ~line 656)

For each installed `modInfo`:

- If `entry.download?.sourceHint` has a catalog name → `store.linkCatalogEntryToMod(modId, hint)`.
- Keep the existing installed-name merge as a fallback for files installed without a hint (drag-drop of a file whose name happens to match).
- If `entry.download != null`, also write the `DownloadHistorySource` (url from `download.task.request.url`) onto the `modId` record here — replacing the disconnected display-name write.

### 7. `lib/catalog/mod_browser_page_controller.dart`

Delete `_buildCatalogStatusMap` (the second copy of the matcher). The controller watches `catalogLinksProvider` instead; `statusForModName` becomes a thin lookup that pairs the link's `Mod` with its version-check result. `updatesCount` and the Installed / Has Update filter checks read the same provider, so cards, filters, the forum post dialog, and the details dialog (all already going through `statusForModName`) get the same state from one source. The made-up add-on entries the controller builds are passed into the provider's catalog input so add-on cards keep working.

## Decisions

- **One matcher, one key, one provider**: matching and name cleanup live only in `catalog_links.dart`. The records store uses the plain matcher function; everything else uses the provider. New link-dependent features watch `catalogLinksProvider` and never rewrite matching.
- **Hint instead of saving at download time**: the mod ID doesn't exist until the file is unpacked; writing records under guesses is what caused the disconnected-records bug. All record writes happen at finish, under the real mod ID.
- **The name is the main key of a catalog entry** everywhere (status map, catalog-only record keys); the thread id is extra info. This matches the existing design and dodges the multiple-mods-per-thread problem.
- **`sourceHint` is required-but-nullable at the one entry point** (`executeDownloadCandidate`, `downloadAndInstallMod`), so forgetting to link a new install path is a compile error, not a silent gap.
- **Multi-entry deep links get no hint** rather than a wrong one.

## Risks

- `dart_mappable` codegen is **not** needed: `DownloadSourceHint` is not saved to disk, and no `@MappableClass` gains fields.
- The forum post dialog offers a download row per mod for multi-mod threads; the hint has to use the row's mod name, not always the thread title, or add-ons would link to the parent entry. (`buildDownloadGroups` already knows each group's mod name.)
- `ModRecord.syntheticKey` output is saved in `trios_mod_records-v1.json` as record keys. Handing its cleanup step to `catalogEntryKey` must not change the strings it makes for existing names — keep its `catalog:` prefix and slug rules exactly the same, and cover it with a test. Otherwise old records would lose their link.
- `catalogLinksProvider` must watch the same made-up add-on list the page shows, or add-on cards would lose their installed state. Pull `_withSynthesizedAddonEntries` (or its output) somewhere both can reach — simplest is a small provider the controller also watches.
