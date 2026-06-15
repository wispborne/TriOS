## REMOVED Requirements

### Requirement: Category dropdown filter
**Reason**: The category dropdown is replaced by a `ChipFilterGroup<ScrapedMod>` in the new Catalog filter panel (see `catalog-filter-panel` capability). The chip group supports multi-select, exclude, and per-group persistence — strictly a superset of the dropdown's functionality.
**Migration**: Remove the `TriOSDropdownMenu<String>` for categories from `mod_browser_page.dart`. Add a `ChipFilterGroup<ScrapedMod>` with id `'category'`, `valuesGetter: (m) => m.categories ?? []`, alphabetical sort, `collapsedByDefault: true`, registered in the `FilterScope(pageId: 'catalog', scopeId: 'main')` controller.

### Requirement: Game Version dropdown filter
**Reason**: The version dropdown is replaced by a `CompositeFilterGroup`-wrapped single-select `StringChoiceField<ScrapedMod>` in the new Catalog filter panel (see `catalog-filter-panel` capability). Wrapping in a composite lets the selection be persisted via the group's lock button, which the standalone dropdown could not do.
**Migration**: Remove the `TriOSDropdownMenu<String>` for game versions from `mod_browser_page.dart`. Register the replacement filter group with id `'version'` in the same catalog scope. The 3-mod minimum bucket threshold and newest-first ordering remain identical and are now enforced by the field's option list.

### Requirement: Dropdowns integrate with existing filter pipeline
**Reason**: There is no longer a distinct "dropdowns" pipeline stage. The Catalog page runs a single unified pipeline (search → chips → composite → sort) orchestrated by `FilterScopeController<ScrapedMod>`; the requirement is now captured as "Filter pipeline order is search → chips → composite → sort" in the `catalog-filter-panel` spec.
**Migration**: None — the observable behavior (search runs before filters, filters run before sort) is unchanged. Delete the old imperative `updateFilter()` body and compute `displayedMods` via `FilterScopeController` calls instead.

## MODIFIED Requirements

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
