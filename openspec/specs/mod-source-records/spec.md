## Requirements

### Requirement: ModRecord data model
The system SHALL define a `ModRecord` class with the following fields:
- `recordKey` (String, required) — mod ID or synthetic key (`catalog:{normalized_name}`)
- `modId` (String?) — the canonical mod ID from mod_info.json
- `names` (Set<String>) — all known names for this mod
- `authors` (Set<String>) — all known authors
- `forumThreadId` (String?) — Fractalsoftworks forum thread ID
- `nexusModsId` (String?) — NexusMods mod ID
- `forumUrl` (String?) — full forum thread URL
- `nexusUrl` (String?) — full NexusMods URL
- `directDownloadUrl` (String?) — most recent known direct download URL
- `downloadPageUrl` (String?) — download page URL (if different from direct)
- `changelogUrl` (String?) — changelog URL
- `masterVersionFileUrl` (String?) — version checker master file URL
- `discordUrl` (String?) — Discord link
- `catalogName` (String?) — name as it appears in the mod catalog
- `lastInstalledPath` (String?) — path to the last known install directory
- `lastInstalledVersion` (String?) — version string of the last installed version
- `lastSeenInCatalog` (DateTime?) — last time this mod was seen in the catalog
- `lastSeenInstalled` (DateTime?) — last time this mod was found on disk
- `firstSeen` (DateTime?) — when this mod was first encountered by TriOS
- `lastDownloadedFrom` (String?) — URL the mod was most recently downloaded from
- `lastDownloadedAt` (DateTime?) — timestamp of most recent download

All fields except `recordKey` SHALL be nullable to allow incremental population.

#### Scenario: Record created from installed mod
- **WHEN** a mod is scanned from disk with mod ID "lazylib" and version checker info containing forumThreadId "5969"
- **THEN** a ModRecord is created with recordKey "lazylib", modId "lazylib", forumThreadId "5969", and forumUrl constructed from the thread ID

#### Scenario: Record created from catalog-only mod
- **WHEN** a catalog mod named "Unknown Skies" has no known mod ID
- **THEN** a ModRecord is created with recordKey "catalog:unknown-skies", catalogName "Unknown Skies", and modId null

### Requirement: Persistent storage
The system SHALL persist mod records to `trios_mod_records-v1.json` in the app config directory using `GenericAsyncSettingsManager`. The file SHALL contain a JSON map keyed by `recordKey`. The manager SHALL use dart_mappable for serialization, debounced writes, and mutex-based concurrency control.

#### Scenario: Records survive app restart
- **WHEN** the app writes mod records and is restarted
- **THEN** all previously written records are loaded from `trios_mod_records-v1.json` on startup

#### Scenario: Concurrent writes are safe
- **WHEN** multiple sources update records simultaneously
- **THEN** writes are serialized via mutex and debounced to prevent file corruption

### Requirement: Auto-population on startup
The system SHALL automatically cross-reference all available data sources after mod variants are loaded and the catalog cache is available. For each installed mod, the system SHALL:
1. Create or update a record keyed by mod ID
2. Populate fields from ModInfo (name, author)
3. Populate fields from VersionCheckerInfo (forumThreadId, nexusModsId, directDownloadUrl, changelogUrl, masterVersionFileUrl)
4. Attempt to match against catalog entries and populate catalog-sourced fields (catalogName, additional URLs, lastSeenInCatalog)

For each unmatched catalog entry, the system SHALL create a record with a synthetic key.

#### Scenario: Installed mod matched to catalog by forum thread ID
- **WHEN** installed mod "lazylib" has VersionCheckerInfo with forumThreadId "5969" AND a catalog entry has a forum URL containing "topic=5969"
- **THEN** the record for "lazylib" is enriched with catalog data (catalogName, additional URLs, images)

#### Scenario: Installed mod matched to catalog by Nexus ID
- **WHEN** installed mod has VersionCheckerInfo with modNexusId "123" AND a catalog entry has a Nexus URL containing "/mods/123"
- **THEN** the record is enriched with catalog data

#### Scenario: Installed mod matched to catalog by name
- **WHEN** no thread ID or Nexus ID match is found, but a catalog entry name closely matches the installed mod name
- **THEN** the record is enriched with catalog data using the name-based match

#### Scenario: Catalog-only mod has no installed match
- **WHEN** a catalog entry cannot be matched to any installed mod
- **THEN** a new record is created with synthetic key `catalog:{normalized_name}`

### Requirement: Action-triggered enrichment
The system SHALL update mod records when the user performs these actions:
- **Download**: Record the download URL (`lastDownloadedFrom`) and timestamp (`lastDownloadedAt`)
- **Install**: Record the install path (`lastInstalledPath`) and version (`lastInstalledVersion`). If this is the first install of a catalog-only mod, merge the synthetic-key record into the real mod ID record.
- **Browse catalog**: Update `lastSeenInCatalog` and any newly available catalog fields

#### Scenario: User downloads a mod
- **WHEN** the user downloads a mod from "https://example.com/mod.zip" for mod ID "lazylib"
- **THEN** the record for "lazylib" has `lastDownloadedFrom` set to "https://example.com/mod.zip" and `lastDownloadedAt` set to the current timestamp

#### Scenario: Catalog-only mod is installed and gets a real ID
- **WHEN** a mod tracked with synthetic key "catalog:unknown-skies" is installed and its mod_info.json reveals mod ID "unknown_skies"
- **THEN** the synthetic record is deleted, a new record keyed "unknown_skies" is created (or updated), and all data from the synthetic record is merged in

### Requirement: Lookup by any identifier
The system SHALL provide Riverpod providers to look up a ModRecord by:
- mod ID (direct map lookup)
- forum thread ID
- Nexus mod ID
- catalog name (normalized)

Each lookup SHALL return `ModRecord?` (null if not found).

#### Scenario: Lookup by forum thread ID
- **WHEN** a caller queries for forum thread ID "5969"
- **THEN** the system returns the ModRecord that has `forumThreadId == "5969"`, or null if none exists

#### Scenario: Lookup by Nexus ID
- **WHEN** a caller queries for Nexus mod ID "123"
- **THEN** the system returns the ModRecord that has `nexusModsId == "123"`, or null if none exists

### Requirement: Record merging
When two records are discovered to represent the same mod (e.g., a synthetic catalog record and a newly-installed real-ID record), the system SHALL merge them by:
1. Keeping the real mod ID as the record key
2. Taking the non-null value for each field (preferring the more recently updated value if both are non-null)
3. Unioning set fields (names, authors)
4. Deleting the synthetic record

#### Scenario: Merge preserves all data
- **WHEN** synthetic record has catalogName "Unknown Skies" and nexusUrl, and installed record has modId "unknown_skies" and forumThreadId
- **THEN** merged record has recordKey "unknown_skies", catalogName "Unknown Skies", nexusUrl, AND forumThreadId
