## 1. Data Model

- [x] 1.1 Create `lib/mod_records/` feature directory
- [x] 1.2 Define `ModRecordSource` sealed class hierarchy with subtypes: `InstalledSource`, `VersionCheckerSource`, `CatalogSource`, `DownloadHistorySource`
- [x] 1.3 Define `ModRecord` with thin top-level fields (recordKey, modId, names, authors, firstSeen) and `Map<String, ModRecordSource> sources`
- [x] 1.4 Define `ModRecords` wrapper class with `@MappableClass`
- [x] 1.5 Run `dart run build_runner build --delete-conflicting-outputs` to generate mapper files

## 2. Persistence Layer

- [x] 2.1 Create `ModRecordsManager` extending `GenericAsyncSettingsManager` for `trios_mod_records-v2.json`
- [x] 2.2 Create Riverpod provider for `ModRecordsStore` (AsyncNotifier pattern)

## 3. Record Merging & Key Utilities

- [x] 3.1 Implement synthetic key generation: `catalog:{normalized_name}`
- [x] 3.2 Implement `ModRecord.merge()` — merge sources maps (keep newer by lastSeen), union names/authors
- [x] 3.3 Implement convenience getters on ModRecord: `installed`, `catalog`, `versionChecker`, `downloadHistory`, `forumThreadId`, `nexusModsId`
- [x] 3.4 Implement helpers: `forumUrlFromThreadId`, `nexusUrlFromModId`

## 4. Auto-Population (Startup Cross-Reference)

- [x] 4.1 Build `InstalledSource` from ModInfo for each installed mod
- [x] 4.2 Build `VersionCheckerSource` from VersionCheckerInfo
- [x] 4.3 Match catalog entries by forum thread ID, Nexus ID, then name — build `CatalogSource`
- [x] 4.4 Create single record per mod with all matched sources as sub-entries
- [x] 4.5 Create synthetic-key records for unmatched catalog entries (catalog source only)
- [x] 4.6 Wire auto-population into startup + listen for mod variant and catalog changes

## 5. Action-Triggered Enrichment

- [x] 5.1 Hook into download manager: add `DownloadHistorySource` on download completion
- [x] 5.2 Hook into install logic: add/update `InstalledSource` on install, merge synthetic records
- [x] 5.3 Catalog `lastSeen` updated via auto-populate listener on catalog refresh

## 6. Lookup Providers

- [x] 6.1 Lookup by mod ID (direct map access)
- [x] 6.2 Lookup by forum thread ID (via convenience getter)
- [x] 6.3 Lookup by Nexus mod ID (via convenience getter)
- [x] 6.4 Lookup by catalog name

## 7. User Overrides Layer

- [x] 7.1 Add `applyOverridesFrom()` method to each `ModRecordSource` subtype (field-level merge: override wins when non-null)
- [x] 7.2 Add `userOverrides` field (`Map<String, ModRecordSource>`) to `ModRecord`
- [x] 7.3 Add `resolvedSources` getter that merges `userOverrides` onto `sources` field-by-field via `applyOverridesFrom()`
- [x] 7.4 Update typed getters (`installed`, `catalog`, `versionChecker`, `downloadHistory`) to read from `resolvedSources`
- [x] 7.5 Update `merge()` to preserve `userOverrides` from both sides
- [x] 7.6 Update dialog `_onSave()` to write sparse overrides to `userOverrides` (only fields differing from auto-populated source)
- [x] 7.7 Regenerate mappers, verify `dart analyze` — zero errors/warnings

## 8. UI: Mod Sources Dialog

- [x] 8.1 Create `ModRecordSourcesDialog` (`ConsumerStatefulWidget`) with collapsible sections per source type
- [x] 8.2 Editable `TextField`s for URLs/IDs, read-only `SimpleDataRow` for paths/timestamps
- [x] 8.3 Dirty tracking and explicit Save button
- [x] 8.4 Add "Mod Sources" `MenuItem` in `buildMenuItemDebugging()` (Troubleshoot context menu)

## 9. Verification

- [ ] 9.1 Manual test: install a mod with version checker info → verify record has installed + versionChecker + catalog sources
- [ ] 9.2 Manual test: download a mod → verify downloadHistory source is added
- [ ] 9.3 Manual test: verify catalog-only mods get a single record with catalog source
- [ ] 9.4 Manual test: install a previously catalog-only mod → verify synthetic record merges into real-ID record
- [ ] 9.5 Manual test: restart app → verify all records persist and reload correctly
- [ ] 9.6 Manual test: edit a field via dialog → Save → trigger auto-population → verify user edit survives
- [ ] 9.7 Manual test: verify JSON file contains both `sources` and `userOverrides` on edited records
