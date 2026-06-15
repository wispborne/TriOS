## ADDED Requirements

### Requirement: Source sub-entries carry name and author data
Each `ModRecordSource` subtype that originates name or author information SHALL store that data directly. `InstalledSource` SHALL have `name` and `author` fields (from mod_info.json). `CatalogSource` SHALL have `name` (already has `catalogName`) and `authors` (`List<String>?`) fields.

#### Scenario: Installed mod populates source-level name and author
- **WHEN** auto-population processes an installed mod variant with `modInfo.name = "LazyLib"` and `modInfo.author = "LazyWizard"`
- **THEN** the `InstalledSource` for that record SHALL have `name = "LazyLib"` and `author = "LazyWizard"`

#### Scenario: Catalog entry populates source-level name and authors
- **WHEN** auto-population processes a catalog entry with `name = "LazyLib"` and `authors = ["LazyWizard"]`
- **THEN** the `CatalogSource` for that record SHALL have `name = "LazyLib"` and `authors = ["LazyWizard"]`

### Requirement: ModRecord provides computed name/author aggregation
`ModRecord` SHALL provide computed getters that aggregate names and authors across all resolved sources. These getters replace the removed top-level `names` and `authors` fields.

#### Scenario: Aggregated names from multiple sources
- **WHEN** a record has `InstalledSource.name = "zz BoxUtil"` and `CatalogSource.name = "Box Util"`
- **THEN** `record.allNames` SHALL return `{"zz BoxUtil", "Box Util"}`

#### Scenario: Aggregated authors from multiple sources
- **WHEN** a record has `InstalledSource.author = "Bob"` and `CatalogSource.authors = ["Bob", "Alice"]`
- **THEN** `record.allAuthors` SHALL return `{"Bob", "Alice"}`

#### Scenario: Record with no name data
- **WHEN** a record has no sources with name information
- **THEN** `record.allNames` SHALL return an empty set

### Requirement: Top-level names and authors fields are removed
`ModRecord` SHALL NOT have stored `names` or `authors` fields. Name and author data SHALL only exist within source sub-entries.

#### Scenario: ModRecord serialization excludes names/authors
- **WHEN** a `ModRecord` is serialized to JSON
- **THEN** the JSON SHALL NOT contain top-level `names` or `authors` keys

#### Scenario: Legacy JSON with top-level names/authors loads without error
- **WHEN** the app reads a JSON file containing records with top-level `names` and `authors` fields
- **THEN** the fields SHALL be ignored and data SHALL be re-derived from source sub-entries on next auto-populate

### Requirement: applyOverridesFrom handles new fields
Each source subtype's `applyOverridesFrom()` method SHALL include the new name/author fields in its field-level merge logic.

#### Scenario: User override for installed source name
- **WHEN** an `InstalledSource` has `name = "zz BoxUtil"` and a user override has `name = "BoxUtil"`
- **THEN** the resolved `InstalledSource` SHALL have `name = "BoxUtil"`

## REMOVED Requirements

### Requirement: Top-level names field on ModRecord
**Reason**: Replaced by source-level name fields and computed `allNames` getter
**Migration**: Use `record.allNames` instead of `record.names`

### Requirement: Top-level authors field on ModRecord
**Reason**: Replaced by source-level author fields and computed `allAuthors` getter
**Migration**: Use `record.allAuthors` instead of `record.authors`
