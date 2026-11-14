# Design

## How long old copies last

TriOS keeps a cached copy of each file and fetches a new one when the copy is older than a set age: 24 hours for the details file (`forum_data_manager.dart`) and 6 hours for the extras file (`catalog_extras_manager.dart`). If the fetch fails, it keeps using the old copy. So an install that is online gets the new format within a day. An install that stays offline keeps its old copy until it can fetch again.

After this change, an old details file still loads without errors. The old fields are simply not read, so those mods show no AI info until the next fetch. That is acceptable this long after the switch.

## What to remove

In `lib/catalog/models/forum_llm_data.dart`:

- `OldLlmFormatHook`, and the `hook:` on `@MappableClass` for `ForumLlmMod`.
- `isOldFormatLlmMod`, `forumLlmModToNewFormat`, `_oldOnlyKeys`, and the helpers only they use (`_asMap`, `_renamed`, `_put`, `_putObject`).
- Keep `RequiredModsHook`. The scraper can still write `parentMod` as names joined by commas.

In `lib/catalog/models/catalog_extras.dart`:

- `catalogExtrasRecordToSchema2`, `_releaseToSchema2` and `aiUseToNewFormat`.
- In `parseCatalogExtrasFile`, stop converting schema 1 records. Return no records for a schema older than 2, and log it the same way as a schema that is too new. Add a `minKnownSchemaVersion = 2` next to `knownSchemaVersion`, and make `isKnownSchema` check both.

Then regenerate the mappers.

## Tests

- `test/forum_llm_data_test.dart`: rewrite the old-format tests ("parses a full llm block in the old format", "old save, requirement and AI fields read in their new places", "an old mod with no tool answer…", the `requires` string tests, and the `extras`-based summary, source code and changelog tests) to use new-format data. Keep the new-format test as it is.
- `test/catalog/catalog_extras_test.dart`: remove `_schema1Record` and the two schema 1 tests. Add a test that a schema 1 file gives no records.
- `test/catalog/mod_catalog_files_test.dart`: rewrite the old-format tests and remove `_nexerelinOldExtras`. The new-format test already covers the same fields.
- Other test files build models in Dart rather than from JSON, so they need no change.
