### Requirement: ForumDataSource in ModRecordSource
The system SHALL define a `ForumDataSource` subclass of `ModRecordSource` with discriminator value `'forumData'`. Fields SHALL include: `topicId` (int?), `views` (int?), `replies` (int?), `lastPostDate` (DateTime?), `lastPostBy` (String?), `createdDate` (DateTime?), `isWip` (bool?), `isArchived` (bool?), `inModIndex` (bool?), `category` (String?), `gameVersion` (String?), `thumbnailPath` (String?). It SHALL implement `applyOverridesFrom` consistent with other source types.

#### Scenario: ForumDataSource stored in ModRecord
- **WHEN** forum data is populated for a mod
- **THEN** the `ModRecord.sources` map contains a `'forumData'` key with a `ForumDataSource` value

#### Scenario: ForumDataSource resolved with overrides
- **WHEN** a user override exists for `'forumData'`
- **THEN** `resolvedSources` merges the override fields over the auto-populated fields

### Requirement: ModRecord accessor for forum data
The `ModRecord` class SHALL provide a typed accessor `forumData` that returns the resolved `ForumDataSource?` from `resolvedSources['forumData']`.

#### Scenario: Access forum data from record
- **WHEN** a `ModRecord` has a `ForumDataSource` in its sources
- **THEN** `record.forumData` returns the resolved `ForumDataSource`

#### Scenario: Access forum data when absent
- **WHEN** a `ModRecord` has no `ForumDataSource`
- **THEN** `record.forumData` returns null

### Requirement: Auto-populate forum data into ModRecords
`ModRecordsStore._autoPopulate()` SHALL listen to the forum data provider and populate `ForumDataSource` entries by matching `ForumModIndex.topicId` against each record's `forumThreadId`. Matching SHALL cover both installed-mod records (via `VersionCheckerSource.forumThreadId` or `CatalogSource.forumThreadId`) and catalog-only records.

#### Scenario: Installed mod with matching forum thread
- **WHEN** an installed mod has `forumThreadId = "25658"` and the forum index contains `topicId = 25658`
- **THEN** the mod's `ModRecord` gains a `ForumDataSource` with `views`, `replies`, `lastPostDate`, etc. from the forum entry

#### Scenario: Catalog-only mod with matching forum thread
- **WHEN** a catalog-only mod record has `CatalogSource.forumThreadId = "25658"` and the forum index contains `topicId = 25658`
- **THEN** the record gains a `ForumDataSource`

#### Scenario: Mod with no forum thread ID
- **WHEN** a mod record has no `forumThreadId` in any source
- **THEN** no `ForumDataSource` is added (the record is unchanged)

### Requirement: Display forum stats in Catalog cards
The Catalog UI SHALL display view count and reply count on `ScrapedModCard` when forum data is available for a mod. Stats SHALL be formatted with locale-aware number formatting (e.g., "474,747 views").

#### Scenario: Card with forum data
- **WHEN** a mod in the catalog has matched forum data
- **THEN** the card displays view count and reply count

#### Scenario: Card without forum data
- **WHEN** a mod in the catalog has no matched forum data
- **THEN** the card displays without forum stats (no empty placeholders)

### Requirement: Sort catalog by forum stats
The Catalog page SHALL support sorting by view count (descending) and by last post date (most recent first), in addition to existing sort options.

#### Scenario: Sort by most viewed
- **WHEN** the user selects "Most Viewed" sort
- **THEN** mods are ordered by `ForumDataSource.views` descending, with mods lacking forum data sorted last

#### Scenario: Sort by last activity
- **WHEN** the user selects "Last Activity" sort
- **THEN** mods are ordered by `ForumDataSource.lastPostDate` descending, with mods lacking forum data sorted last

### Requirement: Filter catalog by forum status
The Catalog page SHALL support three-state filters for WIP status and archived status from forum data.

#### Scenario: Filter to WIP only
- **WHEN** the user sets the WIP filter to `true`
- **THEN** only mods where `ForumDataSource.isWip == true` are shown

#### Scenario: Exclude archived
- **WHEN** the user sets the archived filter to `false`
- **THEN** mods where `ForumDataSource.isArchived == true` are excluded

### Requirement: Debug settings for forum data management
The Debug Settings section SHALL provide controls for managing the forum data cache: a button to force-refresh (bypass 24h TTL and re-fetch), a button to clear the cached files, a status label showing cache age and entry count, and a button to view raw forum data stats in a dialog.

#### Scenario: Force refresh forum data
- **WHEN** the user clicks the "Force Refresh Forum Data" button in Debug Settings
- **THEN** the system deletes the cached files and re-fetches from the remote URL, regardless of cache age

#### Scenario: Clear forum data cache
- **WHEN** the user clicks the "Clear Forum Data Cache" button in Debug Settings
- **THEN** the cached forum data files are deleted and the forum data provider state is invalidated

#### Scenario: View forum data cache status
- **WHEN** forum data has been fetched and cached
- **THEN** the debug section displays the cache timestamp and total entry count (e.g., "Cached 2h ago, 872 entries")

#### Scenario: View forum data details dialog
- **WHEN** the user clicks the "Show Forum Data" button in Debug Settings
- **THEN** a dialog opens showing the bundle `updatedAt`, total index entries, number of entries matched to ModRecords, and a scrollable list of entries with topicId, title, views, and replies
