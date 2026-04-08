## Why

`ModRecord` currently has top-level `names` and `authors` fields that aggregate values from all sources. But this information originates from specific sources (installed mod_info.json, catalog, etc.), and storing it top-level loses provenance. It also creates redundancy — the same name/author data exists in the source sub-entries (implicitly via catalog name, mod info name) and again at the top level. Moving these into the source sub-entries where they naturally belong makes the model cleaner and more consistent: only the record key/mod ID lives at the top level; everything else comes from a source.

## What Changes

- **BREAKING**: Remove `names` (`Set<String>`) and `authors` (`Set<String>`) fields from `ModRecord`
- Add `name` (`String?`) and `author` (`String?`) fields to `InstalledSource` (from mod_info.json)
- Add `name` (`String?`) field to `CatalogSource` (already has `catalogName`, may rename for consistency)
- Add `authors` (`List<String>?`) field to `CatalogSource` (from catalog author data)
- Add computed getters on `ModRecord` that aggregate names/authors across all resolved sources
- Update auto-population in `ModRecordsStore` to populate source-level name/author fields instead of top-level
- Update dialog to display names/authors from resolved sources

## Capabilities

### New Capabilities

- `source-level-identity`: Move mod name and author information from top-level ModRecord fields into individual ModRecordSource sub-entries, with computed aggregation getters

### Modified Capabilities

## Impact

- `lib/mod_records/mod_record.dart` — remove fields, add computed getters
- `lib/mod_records/mod_record_source.dart` — add name/author fields to subtypes
- `lib/mod_records/mod_records_store.dart` — update population logic
- `lib/mod_records/mod_record_sources_dialog.dart` — update display to use source-level fields
- Existing JSON files (`trios_mod_records-v1.json`) will lose top-level names/authors on next write; data is re-derived from sources on next auto-populate
- Generated mapper files need regeneration
