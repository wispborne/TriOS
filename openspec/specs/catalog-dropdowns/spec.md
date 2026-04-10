### Requirement: Category dropdown filter
The Catalog toolbar SHALL include a dropdown that lists all unique categories from the mod data, sorted alphabetically. Selecting a category SHALL filter the mod list to only show mods containing that category. An "All Categories" option SHALL show all mods regardless of category. Empty categories (null or blank) SHALL be excluded from the dropdown.

#### Scenario: User selects a category
- **WHEN** user selects "Total Conversion" from the category dropdown
- **THEN** only mods whose `categories` list includes "Total Conversion" are shown

#### Scenario: User resets category filter
- **WHEN** user selects "All Categories" from the category dropdown
- **THEN** no category filtering is applied and all mods are shown (subject to other filters)

#### Scenario: Categories are populated from data
- **WHEN** the catalog data loads
- **THEN** the category dropdown is populated with all unique non-empty categories sorted alphabetically

### Requirement: Game Version dropdown filter
The Catalog toolbar SHALL include a dropdown that lists game versions, normalized by base version (stripping RC suffixes and letter suffixes for grouping). Only base versions with 3 or more mods SHALL be shown. Versions SHALL be sorted newest-first using the version comparator. Selecting a version SHALL filter to mods matching any raw version variant under that base version.

#### Scenario: User selects a game version
- **WHEN** user selects "0.97" from the version dropdown
- **THEN** only mods whose `gameVersionReq` normalizes to base version "0.97" are shown (e.g., "0.97a", "0.97a-RC11")

#### Scenario: Version dropdown excludes rare versions
- **WHEN** a base version has fewer than 3 mods targeting it
- **THEN** that version SHALL NOT appear in the dropdown

#### Scenario: User resets version filter
- **WHEN** user selects "All Versions" from the version dropdown
- **THEN** no version filtering is applied

### Requirement: Sort dropdown
The Catalog toolbar SHALL include a sort dropdown with options: Name A-Z, Name Z-A, Newest, Oldest, Game Version. The selected sort SHALL be applied after all filters. Name sorting SHALL place mods starting with non-alphanumeric characters at the end.

#### Scenario: Sort by name ascending
- **WHEN** user selects "Name A-Z"
- **THEN** mods are sorted alphabetically by name, with bracket/special-char names at the end

#### Scenario: Sort by newest
- **WHEN** user selects "Newest"
- **THEN** mods are sorted by `dateTimeCreated` descending (newest first)

#### Scenario: Sort by game version
- **WHEN** user selects "Game Version"
- **THEN** mods are sorted by `gameVersionReq` newest-first using version comparison, with ties broken by name

### Requirement: Dropdowns integrate with existing filter pipeline
The category and version dropdowns SHALL be applied in the `updateFilter()` pipeline after text search and before existing tristate filters. Sort SHALL be applied last, after all filtering.

#### Scenario: Combined filtering
- **WHEN** user has search text "weapons", category "Faction", and version "0.97" selected
- **THEN** the mod list shows only mods matching all three criteria simultaneously
