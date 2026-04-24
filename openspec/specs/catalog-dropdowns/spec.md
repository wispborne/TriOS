### Requirement: Sort dropdown
The Catalog **top toolbar** SHALL include a sort dropdown with options: Name A-Z, Name Z-A, Newest, Oldest, Game Version. The selected sort SHALL be applied after all filters (including the new filter-panel groups). Name sorting SHALL place mods starting with non-alphanumeric characters at the end. The Sort dropdown is NOT migrated to the filter panel because sort is not a filter.

#### Scenario: Sort by name ascending
- **WHEN** user selects "Name A-Z"
- **THEN** mods are sorted alphabetically by name, with bracket/special-char names at the end

#### Scenario: Sort by newest
- **WHEN** user selects "Newest"
- **THEN** mods are sorted by `dateTimeCreated` descending (newest first)

#### Scenario: Sort by game version
- **WHEN** user selects "Game Version"
- **THEN** mods are sorted by `gameVersionReq` newest-first using version comparison, with ties broken by name

#### Scenario: Sort is applied after the filter panel
- **WHEN** the filter panel has any active chip / composite state and the user chooses a sort option
- **THEN** the sort runs on `displayedMods` after `applyChipFilters` and `applyNonChipFilters` have produced the filtered list
