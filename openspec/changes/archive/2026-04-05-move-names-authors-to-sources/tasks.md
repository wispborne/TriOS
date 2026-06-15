## 1. Source Sub-Entry Changes

- [x] 1.1 Add `name` (`String?`) and `author` (`String?`) fields to `InstalledSource`
- [x] 1.2 Rename `CatalogSource.catalogName` to `name`, add `authors` (`List<String>?`) field
- [x] 1.3 Update `applyOverridesFrom()` on `InstalledSource` to include `name` and `author`
- [x] 1.4 Update `applyOverridesFrom()` on `CatalogSource` to include `name` (renamed) and `authors`

## 2. ModRecord Changes

- [x] 2.1 Remove `names` and `authors` stored fields from `ModRecord`
- [x] 2.2 Add computed `allNames` getter (union of name fields from all resolved sources)
- [x] 2.3 Add computed `allAuthors` getter (union of author fields from all resolved sources)
- [x] 2.4 Update `merge()` to remove names/authors union logic (sources merge handles it)
- [x] 2.5 Update `ModRecord` constructor — remove `names` and `authors` parameters

## 3. Auto-Population Updates

- [x] 3.1 Update `_autoPopulate` in `ModRecordsStore`: populate `InstalledSource.name` and `InstalledSource.author` from `modInfo`
- [x] 3.2 Update `_buildCatalogSource`: use `name` instead of `catalogName`, populate `authors` from `scraped.getAuthors()`
- [x] 3.3 Update catalog-only record creation: remove top-level `names`/`authors` from `ModRecord` constructor calls
- [x] 3.4 Update installed record creation: remove top-level `names`/`authors` from `ModRecord` constructor calls

## 4. Dialog Updates

- [x] 4.1 Update `mod_record_sources_dialog.dart`: replace `record.names`/`record.authors` with `record.allNames`/`record.allAuthors`
- [x] 4.2 Update Catalog section: display `name` instead of `catalogName`
- [x] 4.3 Update Installed section: display `name` and `author` fields
- [x] 4.4 Update `_hasAnyField` in dialog to include new source fields

## 5. Regenerate and Verify

- [x] 5.1 Run `dart run build_runner build --delete-conflicting-outputs`
- [x] 5.2 Fix any references to `catalogName` across the codebase (`mod_browser_page.dart`, `mod_manager_logic.dart`, `mod_records_store.dart`)
- [x] 5.3 Run `dart analyze lib/` — zero errors or warnings
