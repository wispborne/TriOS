### Requirement: The extras file is downloaded and kept

TriOS SHALL download `mod-catalog-extras.json` from the same repository as `mod-catalog.json`. It SHALL keep the file for 6 hours before downloading it again. When a download fails, it SHALL use the saved copy, whatever its age.

#### Scenario: Fresh copy on disk
- **WHEN** the saved copy is less than 6 hours old
- **THEN** TriOS SHALL read it and SHALL NOT download the file

#### Scenario: Offline with an old copy
- **WHEN** the download fails and a saved copy exists
- **THEN** TriOS SHALL read the saved copy and log a warning

#### Scenario: The file can't be read
- **WHEN** the download fails with no saved copy, or the file doesn't decode
- **THEN** the catalog SHALL still load and work, and the extras SHALL count as not available

### Requirement: Each catalog mod gets its extras record

Each `CatalogMod` SHALL carry the extras record whose key matches its catalog `id`, or nothing when there is no such record.

#### Scenario: A mod with a record
- **WHEN** the extras file has a record under the mod's catalog id
- **THEN** the mod's `extras` SHALL be that record

#### Scenario: A mod added after the extras file was built
- **WHEN** the catalog has a mod that the extras file doesn't list
- **THEN** the mod's `extras` SHALL be null, and the fallbacks SHALL apply to that mod only

### Requirement: One bad record doesn't hide the rest

A record that fails to decode SHALL be dropped on its own. The other records SHALL still load. An enum value TriOS doesn't know SHALL read as `unknown` instead of failing.

#### Scenario: One broken record
- **WHEN** one record in `mods` has a field of the wrong type
- **THEN** that record SHALL be dropped, every other record SHALL load, and one warning SHALL be logged with the number dropped

### Requirement: A newer schema counts as not available

TriOS SHALL read files whose `schemaVersion` is one it knows. A file with a higher `schemaVersion` SHALL count as not available.

#### Scenario: The scraper moves to schema 2
- **WHEN** the extras file says `schemaVersion: 2` and TriOS knows only 1
- **THEN** every mod's `extras` SHALL be null, and the fallbacks SHALL apply

### Requirement: Fallbacks when there is no record

When a mod has no extras record, TriOS SHALL use the data it already has:

- categories from the catalog entry's raw `categories`
- required and optional mods from the AI answer's `extras.needs` and `extras.optionalNeeds`, as names with no catalog id
- the "add to a running game" answer from the AI answer's `extras.canAdd`

Release history, mods that share a name, gallery pictures and the Discord post SHALL have no fallback.

#### Scenario: Categories without the extras file
- **WHEN** a mod has no extras record
- **THEN** its `categories` SHALL be the catalog entry's raw categories

#### Scenario: Requirements without the extras file
- **WHEN** a mod has no extras record, and its AI answer lists `needs: ["LazyLib"]`
- **THEN** its required mods SHALL be one entry named "LazyLib" with no catalog id

#### Scenario: The extras record wins
- **WHEN** a mod has an extras record with categories and needs
- **THEN** its `categories` and required mods SHALL come from the record, not the fallbacks

### Requirement: Other code can tell whether the extras are available

TriOS SHALL say whether the extras file is available as a whole. It SHALL also say whether each mod has a record.

#### Scenario: Whole file missing
- **WHEN** the file couldn't be read, has an unknown schema version, or holds no records
- **THEN** the "extras available" value SHALL be false
