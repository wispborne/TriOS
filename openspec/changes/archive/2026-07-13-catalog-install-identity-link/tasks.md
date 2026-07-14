# Tasks

## 1. Shared linking module (`lib/catalog/catalog_links.dart`)

- [x] Add `catalogEntryKey(String name)` as the one standard name-key function; make `ModRecord.syntheticKey` hand off its cleanup step to it, with a test proving the output is exactly the same as the current scheme for existing names (keys are saved on disk). *(Deviation: kept `syntheticKey`'s algorithm inline and byte-identical, locked by a test, rather than importing the catalog/Riverpod graph into the leaf `ModRecord` model. It agrees with `catalogEntryKey` on lower+trim.)*
- [x] Add `CatalogLinkSignal`, `CatalogLink`, and the plain `matchCatalogToInstalled()` function with clues in order: saved record link → version-checker thread id → NexusMods id → exact name → close-enough name.
- [x] Pull the made-up add-on entry list (currently `CatalogPageController._withSynthesizedAddonEntries`) into a small provider both the controller and `catalogLinksProvider` can watch (`catalogEntriesProvider` + `withSynthesizedAddonEntries`).
- [x] Add `catalogLinksProvider` (watches mod records, installed mods, catalog + made-up entries) with `modForEntry()` and `linkForModId()`.
- [x] Add easy-to-find extensions in the same file: `Mod.catalogLink(links)` / `Mod.catalogEntry(links)` and `ScrapedMod.installedMod(links)` / `ScrapedMod.isInstalled(links)`. *(The dialogs consume via `statusForModName`, which takes a name string; the extensions are the public API for future callers that hold a `Mod`/`ScrapedMod`.)*
- [x] Unit-test the matcher: saved link beats name guesses, Ashpad/Aashpad links through the saved record, close-enough fallback still works, add-on entries sharing a thread id don't steal the parent's match.

## 2. Carry the source hint through the download pipeline

- [x] Add `DownloadSourceHint` (catalogName, forumThreadId, nexusModsId) with a `fromScrapedMod()` factory, and a `sourceHint` field on `Download` in `lib/trios/download_manager/download_manager.dart`; accept and store it in `addDownload` and `downloadAndInstallMod` as a required (nullable) parameter — updated all current call sites, non-catalog ones passing null.
- [x] In `downloadAndInstallMod`, stop writing the download-history record when `modInfo == null` (it gets written at finish instead, under the real mod id).
- [x] Add `sourceHint` to `confirmAndDownloadModViaManager` in `lib/catalog/download_confirm.dart` and pass it on.
- [x] Add required `sourceHint` to `executeDownloadCandidate` in `lib/catalog/download_candidate_actions.dart`; pass it to both the download-manager path and the deep-link path.
- [x] Build the hint at each catalog call site from the `ScrapedMod` / forum row in hand: `scraped_mod_card.dart`, `scraped_mod_details_dialog.dart`, and `forum_post_dialog.dart` (uses the download row's own mod name, not the thread title, for multi-mod threads). *(The `mod_browser_page.dart` embedded-browser download isn't a catalog-entry call site, so it passes null.)*
- [x] Carry the hint through `handleUriString` in `lib/trios/deep_link/deep_link_handler.dart`, using it in `_downloadAndInstall` only when the deep link pointed at exactly one mod entry (no dependencies).

## 3. Write the link when the install finishes

- [x] Add `linkCatalogEntryToMod(String modId, DownloadSourceHint hint)` to `ModRecordsStore`: join the catalog-only record keyed by the catalog name into the real record, then make sure a `CatalogSource` (from the current catalog entry when there is one, bare otherwise) is attached.
- [x] In the batch-install finish step (`batch_installation_notifier.dart`), call `linkCatalogEntryToMod` for installed mods whose `entry.download?.sourceHint` has a catalog name (only when the archive produced exactly one mod, so a multi-mod archive doesn't mis-tag); keep the existing installed-name merge as fallback.
- [x] In the same finish step, write `DownloadHistorySource` onto the real mod-id record for entries that have a download.
- [x] Unit-test the key-selection logic (catalog name → `syntheticKey`) via the matcher/`syntheticKey` tests. *(The store itself needs heavy Riverpod + on-disk settings scaffolding to instantiate; per the task, covered the key logic instead of a full store integration test.)*

## 4. Read the shared link everywhere

- [x] Replace `ModRecordsStore._autoPopulate`'s inline matching with `matchCatalogToInstalled()`; refresh linked `CatalogSource` data from the current catalog entry each pass.
- [x] Delete `CatalogPageController._buildCatalogStatusMap`; back `statusForModName`, `updatesCount`, and the Installed / Has Update filter checks with `catalogLinksProvider` plus version-check results.
- [x] Confirm the forum post dialog and details dialog `isInstalled` callbacks (both go through `statusForModName`) still work, including for made-up add-on cards. *(Compiles clean; `statusForModName` now reads the shared provider.)*

## 5. Verify

- [x] `flutter analyze` and `flutter test` pass. *(Analyze: no new issues in the changed files; only pre-existing project lints remain. Tests: all 418 pass, including 18 new matcher/key tests.)*
- [ ] Manual check (user): install a catalog mod whose catalog name differs from its mod_info name; the card, forum post dialog, and details dialog should all show "Installed", and the mod record sources dialog should show the catalog source attached to the real mod id.
- [ ] Manual check (user): install a multi-mod thread add-on from the forum post dialog and confirm the add-on card (not the parent) flips to "Installed".
- [ ] Manual check (user): a version-checker update download (non-catalog path) still installs and records history normally with a null hint.
