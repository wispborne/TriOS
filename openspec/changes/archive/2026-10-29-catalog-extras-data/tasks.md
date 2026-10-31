# Tasks

## 1. Before building

- [x] 1.1 Check every field name and shape in `design.md` against the scraper change `mod-catalog-extras-file`, and fix `design.md` where they differ.
- [x] 1.2 Get the user's sign-off on the Data Sources card titles and subtitles in `design.md`.

## 2. Downloading

- [x] 2.1 In `CachedJsonFetcher.fetch`, treat any status other than 200 as a failed fetch, so error pages are never saved.
- [x] 2.2 Add `Constants.modCatalogExtrasUrl`.
- [x] 2.3 Add `lib/catalog/catalog_extras_manager.dart` with the fetcher (`mod_catalog_extras.json`, 6 hours), `isLoadingCatalogExtras`, and `catalogExtrasProvider`.

## 3. Models

- [x] 3.1 Add the classes listed in `design.md` to `lib/catalog/models/catalog_extras.dart`, next to the `CatalogAiUse` classes from `catalog-search`. Give each enum an `unknown` default.
- [x] 3.2 Decode `mods` one record at a time. Drop bad records and log one line with the count.
- [x] 3.3 Treat a `schemaVersion` above 1 as not available.
- [x] 3.4 Add `catalogExtrasByIdProvider` and `catalogExtrasAvailableProvider`.
- [x] 3.5 Add `needs`, `optionalNeeds`, `canRemove`, `removalCompatibility` and `updateNotes` to `ForumLlmExtras`. `canAdd`, `aiUse`, `isTool` and `nicknames` come from `catalog-search`, which lands first. Regenerate the mappers.
- [x] 3.6 Run `dart run build_runner build --delete-conflicting-outputs`.

## 4. Joining to catalog mods

- [x] 4.1 Add the `extras` parameter to `gatherCatalogMod` and the `extras` field to `CatalogMod`.
- [x] 4.2 In `catalogModsProvider`, watch `catalogExtrasByIdProvider` and pass each entry's record by `entry.id`.
- [x] 4.3 Add the `categories`, `requiredMods`, `optionalMods` and `canAddToSaveAnswer` getters with their fallbacks. Make `canAddToSave` from `catalog-search` read `canAddToSaveAnswer`.

## 5. Data Sources dialog

- [x] 5.1 Add the third card for the extras file. blocked by 1.2
- [x] 5.2 Change the first two cards' titles and subtitles to the signed-off text. Point the second card's link at `wispborne/StarsectorModRepo`. blocked by 1.2

## 6. Tests and checks

- [x] 6.1 Add the tests listed in `design.md`.
- [x] 6.2 Run `fvm flutter analyze` and `fvm flutter test`.
- [x] 6.3 Sync the spec changes in this folder into `openspec/specs/` when archiving.
