## ADDED Requirements

### Requirement: Forum mod details model
The system SHALL define a `ForumModDetails` model representing a single entry from the forum data bundle's `details` map. Fields SHALL include: `topicId` (int), `title` (String), `category` (String?), `gameVersion` (String?), `author` (String), `authorTitle` (String?), `authorPostCount` (int?), `authorAvatarPath` (String?), `postDate` (DateTime?), `lastEditDate` (DateTime?), `contentHtml` (String), `images` (List<String>?), `links` (List<String>?), `scrapedAt` (DateTime?), `isPlaceholderDetail` (bool). The model SHALL use `@MappableClass` for serialization and SHALL reuse `ForumDateHook` for date field parsing.

#### Scenario: Parse a valid details entry
- **WHEN** the JSON contains a valid details entry with all fields populated
- **THEN** the model is deserialized with correct types, and date strings in SMF format are parsed to `DateTime`

#### Scenario: Parse details entry with null optional fields
- **WHEN** the JSON contains an entry where `category`, `gameVersion`, `authorTitle`, `authorPostCount`, `authorAvatarPath`, `postDate`, `lastEditDate`, `images`, `links`, or `scrapedAt` are null
- **THEN** the corresponding model fields are null without error and `contentHtml` is still populated

#### Scenario: Placeholder detail flag preserved
- **WHEN** the JSON contains an entry with `isPlaceholderDetail: true`
- **THEN** the parsed model's `isPlaceholderDetail` is `true`

### Requirement: Forum details on-demand lookup
The system SHALL expose the per-topic `ForumModDetails` (from the `details` section of `forum-data-bundle.json`) via a Riverpod provider, keyed by `topicId`. The `details` section SHALL NOT be parsed as part of the primary `forumDataProvider` hot path; it SHALL be parsed on demand, off the UI isolate (via `compute` or equivalent), to keep catalog rendering responsive.

The `details` keys in the JSON are strings; the provider SHALL convert them to `int` keys when building the lookup map.

#### Scenario: On-demand details parsing
- **WHEN** a consumer first requests the forum details for any `topicId`
- **THEN** the system reads the cached bundle file, decodes only the `details` section off the UI isolate, maps each entry through `ForumModDetailsMapper.fromMap`, caches the resulting `Map<int, ForumModDetails>`, and resolves the request

#### Scenario: Lookup existing topic details
- **WHEN** a consumer requests details for a `topicId` that exists in the parsed map
- **THEN** the corresponding `ForumModDetails` is returned

#### Scenario: Lookup missing topic details
- **WHEN** a consumer requests details for a `topicId` that does not exist in the parsed map
- **THEN** null is returned and no exception is thrown

#### Scenario: Primary forum data provider unaffected
- **WHEN** `forumDataProvider` emits a bundle
- **THEN** it emits only `updatedAt` and `index`, exactly as before, without waiting for `details` to be parsed

#### Scenario: Details parsing does not block catalog
- **WHEN** the details provider is parsing the `details` section
- **THEN** the catalog list continues to render and respond to user interaction, and only the Forum Post Dialog invocation awaits the parse result
