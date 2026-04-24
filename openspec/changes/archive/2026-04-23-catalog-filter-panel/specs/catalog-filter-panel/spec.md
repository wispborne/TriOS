## ADDED Requirements

### Requirement: Collapsible filter panel on the Catalog page

The Catalog page SHALL host a collapsible left-side filter panel built on the shared filter engine (`FilterScopeController<ScrapedMod>`), matching the pattern used by the ships, weapons, hullmods, and portraits pages. The panel SHALL be toggleable via a `CollapsedFilterButton` when collapsed and SHALL display an active-filter count badge. The panel SHALL contain (in order) an Attributes chip group, a Category chip group, and a Version selection group.

#### Scenario: User expands the filter panel
- **WHEN** the user taps the `CollapsedFilterButton` on the Catalog page
- **THEN** the filter panel expands and renders the Attributes, Category, and Version groups using `FilterGroupRenderer<ScrapedMod>`

#### Scenario: Collapse button shows active-filter count
- **WHEN** the user has two chip values in "include" state on the Attributes group and a Category selected
- **THEN** the `CollapsedFilterButton` badge displays the sum of `activeCount` across all groups

#### Scenario: Filter panel coexists with the browser side rail
- **WHEN** the user opens the Browser side panel and the filter panel is expanded
- **THEN** both panels remain visible simultaneously with the mod grid between them; resizing the browser panel does not disturb the filter panel

### Requirement: Attributes chip group replaces the eight tri-state icon buttons

The Attributes chip group SHALL be a `ChipFilterGroup<ScrapedMod>` with the following fixed chip values: `download`, `discord`, `index`, `forum`, `installed`, `update`, `wip`, `archived`. The chip-label display SHALL be "Has Download", "Discord", "Index", "Forum", "Installed", "Has Update", "WIP", "Archived" respectively. The group SHALL preserve the declared chip order (not sort alphabetically). Each chip SHALL cycle through tri-state (null → include → exclude → null) and apply the canonical `ChipFilterGroup.matches` algorithm.

#### Scenario: User includes a single attribute
- **WHEN** the user clicks the "Has Download" chip once (state becomes `true`)
- **THEN** the mod grid shows only mods where `urls?.containsKey(ModUrlType.DirectDownload) == true`

#### Scenario: User excludes an attribute
- **WHEN** the user clicks the "Discord" chip twice (state becomes `false`)
- **THEN** the mod grid excludes mods whose `sources` contain `ModSource.Discord`

#### Scenario: User combines include and exclude
- **WHEN** the user sets "Installed" to `true` and "Archived" to `false`
- **THEN** the mod grid shows only mods that are installed AND are not archived

#### Scenario: Attributes-group chip values derive from runtime data
- **WHEN** the group's `valuesGetter` is evaluated for a mod
- **THEN** it returns the set of chip-value keys whose corresponding predicate evaluates `true` for that mod (keys derived from `urls`, `sources`, `_catalogStatusMap`, and the forum-data lookup)

### Requirement: Category chip group replaces the Category dropdown

The Catalog page SHALL expose categories as a `ChipFilterGroup<ScrapedMod>` where `valuesGetter` returns `mod.categories ?? []`. Chips SHALL be sorted alphabetically. The group SHALL default to collapsed because category lists can be long. Empty and null category values SHALL NOT appear as chips.

#### Scenario: User selects one category
- **WHEN** the user clicks the "Total Conversion" chip (state `true`)
- **THEN** the mod grid shows only mods whose `categories` list contains "Total Conversion"

#### Scenario: User selects multiple categories
- **WHEN** the user sets both "Total Conversion" and "Faction" to `true`
- **THEN** the mod grid shows mods whose `categories` list intersects `{Total Conversion, Faction}` (standard chip-group semantics)

#### Scenario: Category group appears collapsed by default
- **WHEN** the filter panel first renders
- **THEN** the Category group shows only its header row and must be expanded to reveal chips

### Requirement: Version selection group replaces the Version dropdown

The Catalog page SHALL expose game version as a single-select filter inside a `CompositeFilterGroup<ScrapedMod>` so that it can be persisted with a lock. Only base-version buckets with 3 or more mods SHALL appear as choices, and buckets SHALL be ordered newest-first by the version comparator. An "All Versions" choice SHALL be present. On first-ever load (no persisted state), the selection SHALL default to the newest available version bucket.

#### Scenario: User selects a version bucket
- **WHEN** the user selects "0.97" from the Version dropdown inside the filter panel
- **THEN** the mod grid shows only mods whose `gameVersionReq` falls into the 0.97 base-version bucket (matching the raw-versions set for that bucket)

#### Scenario: User resets to All Versions
- **WHEN** the user selects "All Versions"
- **THEN** no version filtering is applied

#### Scenario: Newest version is selected on first load
- **WHEN** the Catalog page first loads for a user with no persisted catalog filter state
- **THEN** the Version group selection is set to the newest version bucket key

### Requirement: Top toolbar contains only search, sort, clear-all, and overflow

After this change, the Catalog top toolbar SHALL NOT host filter icons, a Category dropdown, or a Version dropdown. The toolbar SHALL contain the clear-all filters button, the search box, the Sort dropdown, and the overflow menu. The filter icons and Category/Version dropdowns SHALL live exclusively inside the filter panel.

#### Scenario: Toolbar contents after migration
- **WHEN** the Catalog page renders after this change
- **THEN** the toolbar displays (left to right) clear-all, search box, sort dropdown, overflow menu — and no tri-state icon filters, no Category dropdown, no Version dropdown

#### Scenario: Clear-all clears every filter group
- **WHEN** the user clicks clear-all in the toolbar
- **THEN** `FilterScopeController.clearAll()` is invoked and every group's state resets; the grid repopulates with all mods subject only to search text and sort

### Requirement: Catalog filter state persists per-group via locks

Each filter group in the Catalog panel SHALL support persistence via its lock button, keyed by `FilterScope(pageId: 'catalog', scopeId: 'main')` and the group's `id`. Locked groups SHALL restore their selections on subsequent app launches. The filter-panel expanded / collapsed state SHALL itself persist on app settings.

#### Scenario: Locked Attributes group survives restart
- **WHEN** the user locks the Attributes group with `installed = true` and restarts the app
- **THEN** on reopen, the Attributes group restores `installed = true` and the grid is filtered accordingly

#### Scenario: Unlocked group does not persist
- **WHEN** the user sets Category chips but does not lock the Category group, then restarts
- **THEN** on reopen the Category group has no selections

#### Scenario: Panel expand/collapse persists
- **WHEN** the user collapses the filter panel and restarts the app
- **THEN** the panel opens collapsed on next launch

### Requirement: Filter pipeline order is search → chips → composite → sort

The Catalog filter pipeline SHALL execute in this order: (1) text search via `searchScrapedMods`, (2) `FilterScopeController.applyChipFilters` for Attributes and Category, (3) `FilterScopeController.applyNonChipFilters` for the Version composite, (4) `sortScrapedMods` with the currently-selected `CatalogSortKey`. The `displayedMods` list SHALL be derived from this pipeline and SHALL be what the `WispAdaptiveGridView` renders.

#### Scenario: Combined filters and sort
- **WHEN** the user has search text "weapons", Category "Faction" set to `true`, Version "0.97" selected, and Sort "Newest"
- **THEN** `displayedMods` equals `sort(newest, applyNonChipFilters(applyChipFilters(search("weapons", allMods))))` subject to the above groups
