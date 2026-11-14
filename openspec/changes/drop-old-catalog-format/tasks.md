# Tasks

## 1. Check it's time

- [ ] 1.1 Confirm the live `mod-catalog-details.json` on StarsectorModRepo has `meta.llmFormat: 2`.
- [ ] 1.2 Confirm the live `mod-catalog-extras.json` has `schemaVersion: 2`.
- [ ] 1.3 Confirm a TriOS release that reads the new format has been out for a while.

## 2. Remove the conversion

- [ ] 2.1 In `forum_llm_data.dart`, remove `OldLlmFormatHook`, the hook on `ForumLlmMod`, `isOldFormatLlmMod`, `forumLlmModToNewFormat`, `_oldOnlyKeys` and the helpers only they use. Keep `RequiredModsHook`.
- [ ] 2.2 In `catalog_extras.dart`, remove `catalogExtrasRecordToSchema2`, `_releaseToSchema2` and `aiUseToNewFormat`.
- [ ] 2.3 In `parseCatalogExtrasFile`, return no records for a schema older than 2, and log why. Add `minKnownSchemaVersion` and use it in `isKnownSchema`.
- [ ] 2.4 Regenerate the mappers.

## 3. Tests

- [ ] 3.1 Rewrite the old-format tests in `test/forum_llm_data_test.dart` to use new-format data.
- [ ] 3.2 In `test/catalog/catalog_extras_test.dart`, remove the schema 1 tests and `_schema1Record`. Add a test that a schema 1 file gives no records.
- [ ] 3.3 In `test/catalog/mod_catalog_files_test.dart`, rewrite the old-format tests and remove `_nexerelinOldExtras`.
- [ ] 3.4 Run `fvm flutter analyze` and `fvm flutter test`.
