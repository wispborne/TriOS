## ADDED Requirements

### Requirement: Forum data bundle model
The system SHALL define a `ForumModIndex` model representing a single entry from the forum data bundle's `index` array. Fields SHALL include: `topicId` (int), `title` (String), `category` (String?), `inModIndex` (bool), `isArchivedModIndex` (bool), `gameVersion` (String?), `author` (String), `replies` (int), `views` (int), `createdDate` (DateTime?), `lastPostDate` (DateTime?), `lastPostBy` (String?), `topicUrl` (String), `thumbnailPath` (String?), `scrapedAt` (DateTime?), `isWip` (bool), `sourceBoard` (int?). The model SHALL use `@MappableClass` for serialization.

#### Scenario: Parse a valid index entry
- **WHEN** the JSON contains a valid index entry with all fields populated
- **THEN** the model is deserialized with correct types, and date strings in `"MMMM d, yyyy, hh:mm:ss a"` format are parsed to `DateTime`

#### Scenario: Parse entry with null optional fields
- **WHEN** the JSON contains an entry where `category`, `gameVersion`, `lastPostDate`, `lastPostBy`, `thumbnailPath`, or `sourceBoard` are null
- **THEN** the corresponding model fields are null without error

### Requirement: Forum data bundle wrapper
The system SHALL define a `ForumDataBundle` model representing the top-level bundle structure with fields: `updatedAt` (DateTime), `index` (List<ForumModIndex>). The `details` and `assumedDownloads` fields SHALL NOT be parsed.

#### Scenario: Parse bundle with index only
- **WHEN** the full JSON bundle is deserialized
- **THEN** only `updatedAt` and `index` are populated; `details` and `assumedDownloads` are ignored

### Requirement: Fetch forum data with caching
The system SHALL provide a Riverpod provider that fetches the forum data bundle from the configured URL and caches it locally. The cache TTL SHALL be 24 hours. The provider SHALL emit a `ForumDataBundle` on success.

#### Scenario: First fetch with no cache
- **WHEN** no cached forum data exists on disk
- **THEN** the system fetches from the remote URL, parses the `index` array, caches the response, and emits the result

#### Scenario: Fetch with valid cache
- **WHEN** cached forum data exists and is less than 24 hours old
- **THEN** the system reads from cache without making a network request

#### Scenario: Fetch with expired cache
- **WHEN** cached forum data exists but is older than 24 hours
- **THEN** the system fetches fresh data from the remote URL and updates the cache

#### Scenario: Fetch failure with valid cache
- **WHEN** the remote URL is unreachable but a cache file exists (regardless of age)
- **THEN** the system falls back to the cached data and logs a warning

#### Scenario: Fetch failure with no cache
- **WHEN** the remote URL is unreachable and no cache exists
- **THEN** the provider logs a warning and does not emit (forum data is unavailable, no crash)

### Requirement: Lookup by topic ID
The system SHALL provide a method to look up a `ForumModIndex` entry by its `topicId`. The lookup SHALL be O(1) via an internal map built at parse time.

#### Scenario: Lookup existing topic
- **WHEN** a lookup is performed with a `topicId` that exists in the index
- **THEN** the corresponding `ForumModIndex` entry is returned

#### Scenario: Lookup missing topic
- **WHEN** a lookup is performed with a `topicId` that does not exist
- **THEN** null is returned
