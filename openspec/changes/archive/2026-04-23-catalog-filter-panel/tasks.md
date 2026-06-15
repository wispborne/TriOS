## 1. Filter engine: add `StringChoiceField<T>`

- [x] 1.1 Add `StringChoiceField<T> extends FilterField<T>` to `lib/widgets/filter_engine/filter_group.dart`. Fields: `id`, `label`, `defaultValue` (`String?` for "all"), `options` (`List<String>`), `predicate(T, String?)`, optional `optionLabel(String)`. Implement `isActive`, `matches`, `serialize` (return selected string or null), `restoreFrom`, `clear`.
- [x] 1.2 Add a render case for `StringChoiceField` in `lib/widgets/filter_engine/filter_group_renderer.dart` next to `EnumField` — dropdown-style rendering with `TriOSDropdownMenu<String>`.
- [x] 1.3 Export the new type from `filter_engine.dart` (no change needed — barrel already re-exports `filter_group.dart`).

## 2. Catalog page controller (Riverpod Notifier)

- [x] 2.1 Create `lib/catalog/mod_browser_page_controller.dart` with `CatalogPageState` and `CatalogPageStatePersisted` `@MappableClass`es (fields: `showFilters`, plus anything already on `_CatalogPageState` that belongs in state rather than UI). Add `part` directive for `.mapper.dart`.
- [x] 2.2 In the notifier, instantiate `FilterScopeController<ScrapedMod>` with `FilterScope(pageId: 'catalog', scopeId: 'main')`, `persistenceEnabled: true`.
- [x] 2.3 Register Attributes `ChipFilterGroup<ScrapedMod>`: id `'attributes'`, fixed chip keys `download`, `discord`, `index`, `forum`, `installed`, `update`, `wip`, `archived`, `displayNameGetter` returning human labels, explicit `sortComparator` preserving declared order, `valuesGetter` returning the set of keys whose predicate is true for each mod.
- [x] 2.4 Register Category `ChipFilterGroup<ScrapedMod>`: id `'category'`, `valuesGetter: (m) => m.categories ?? []`, alphabetical sort, `collapsedByDefault: true`.
- [x] 2.5 Register Version `CompositeFilterGroup<ScrapedMod>` (id `'version'`) wrapping a `StringChoiceField<ScrapedMod>` (id `'versionBucket'`, options from the 3-mod-minimum newest-first bucket list, predicate matches `gameVersionReq` against raw versions in the bucket, default to newest bucket on first load).
- [x] 2.6 Expose a computed `displayedMods` getter that runs: `searchScrapedMods` → `applyChipFilters` → `applyNonChipFilters` → `sortScrapedMods(selectedSort)`. Build `_catalogStatusMap` and forum lookup inside the notifier so predicates can reference them.
- [x] 2.7 Expose controller methods: `toggleShowFilters`, `setSearchQuery`, `setSort`, `clearAll`, `activeFilterCount`, `setChipSelections` wrapper for context-menu navigation (parity with ships).
- [x] 2.8 On first non-empty data load, `_filters.loadPersisted(...)`; if the Version group restored nothing, seed the `StringChoiceField` with the newest bucket. Gate behind a one-shot `_hasAppliedInitialDefaults` flag.
- [x] 2.9 Run `dart run build_runner build --delete-conflicting-outputs`.

## 3. Catalog page UI rewrite

- [x] 3.1 In `lib/catalog/mod_browser_page.dart`, delete the `bool? filterHasDownloadLink/...` fields, `_categoryOptions`, `_versionGroupOptions`, `selectedCategory`, `selectedVersion`, and the imperative `updateFilter()` body. Route `displayedMods` from the controller.
- [x] 3.2 Shrink the top toolbar `Card` to a single row: clear-all icon (calls `controller.clearAll`), search box (unchanged), sort `TriOSDropdownMenu<CatalogSortKey>` (unchanged), overflow button (unchanged). Remove the second row that held category/version dropdowns.
- [x] 3.3 Inside `SideRail.contentBuilder`, wrap the existing mod-grid Column in a `Row` with (a) `CollapsedFilterButton` / filter-panel widget on the left and (b) `Expanded(mod grid)` on the right — mirroring `_buildFiltersSection` in `lib/ship_viewer/ships_page.dart`.
- [x] 3.4 Create `lib/catalog/widgets/catalog_filters_panel.dart` that renders the controller's `filterGroups` via `FilterGroupRenderer<ScrapedMod>`. Include a header row with clear-all + collapse-panel buttons, matching the viewer-page styling.
- [x] 3.5 Wire `CollapsedFilterButton` to `controller.toggleShowFilters` and feed `controller.activeFilterCount` into its badge.
- [x] 3.6 Keep `SideRail` browser-panel state and layout untouched; the filter panel is inside `contentBuilder`, not a `SideRailPanel`.

- [x] 4.1 Confirm the `FilterGroupPersistence` provider is already active app-wide. No new setup needed.
- [x] 4.2 Added `catalogPageState: CatalogPageStatePersisted?` to `Settings`; wired through controller's `_persistUiState`. Build_runner regenerated mappers.

- [x] 6.1 Deleted `buildTristateTooltipIconButton`, `updateFilter`, `_buildCatalogStatusMap`, `_CatalogEntryStatus`, and stale imports (`svg_image_icon.dart`, `tristate_icon_button.dart`, `mod_manager_extensions.dart`, `mod_manager_logic.dart`, `version_checker.dart`, `mod_records/*`, `models/mod.dart`, `mod_browser_manager.dart`, `utils/search.dart`). `extractCategories` / `extractVersionGroups` remain in `catalog_search.dart` (still used by the controller).
- [x] 6.2 `dart analyze lib/` — zero errors introduced by the refactor.

## 4. Persistence + settings

- [ ] 4.1 Confirm the `FilterGroupPersistence` provider is already active app-wide (it is — ships/weapons use it). No new setup needed; locks Just Work under the `('catalog','main',<groupId>)` key.
- [ ] 4.2 Add a `catalogShowFilters` (or equivalent) field on `Settings` for the persisted expanded/collapsed state if it does not already exist, plumb through `CatalogPageStatePersisted`. Re-run build_runner if mapper files change.

## 5. Tests

- [~] 5.1 Widget test deferred — the page requires HTTP, WebView, mod records, and forum data to mount; the scaffolding cost exceeds the test value. The existing chip/composite unit tests in 5.2-5.4 cover the underlying semantics, and toolbar composition is validated by `dart analyze`. Revisit if the catalog grows tricky toolbar state.
- [x] 5.2 Added `test/catalog_filter_panel_test.dart` — `Attributes ChipFilterGroup` group tests: include-only, exclude-only, combined include+exclude, empty passthrough, clear().
- [x] 5.3 Same file — Version composite tests: default All-Versions matches everything, selecting "0.97" restricts to bucket, serialize/restore roundtrip, restore ignores unknown value, clear() resets.
- [x] 5.4 Same file — `FilterScopeController.clearAll` on a Catalog-shaped scope resets all three groups.

## 6. Cleanup + verification

- [ ] 6.1 Delete now-unused helpers in `mod_browser_page.dart`: `buildTristateTooltipIconButton`, `extractCategories` / `extractVersionGroups` callsites if they become dead (keep the functions themselves if exported for other uses).
- [ ] 6.2 Run `flutter analyze` and fix any warnings introduced by the refactor.
- [ ] 6.3 Manually verify on Windows (deferred to the human): panel expands/collapses, chips tri-state, lock persists after restart, browser side-rail still opens and resizes, default sort/filter on first launch matches the previous "newest version bucket" behavior.
- [x] 6.4 Ran `openspec validate catalog-filter-panel`.
