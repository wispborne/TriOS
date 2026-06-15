## Why

The Catalog page currently stuffs all filtering controls — eight tri-state icon buttons plus three dropdowns (category, version, sort) — into a 80px-tall toolbar at the top of the page. This is cramped, inconsistent with the other viewer pages (ships, weapons, hullmods, portraits), and bypasses the shared filter infrastructure, so catalog filters cannot be persisted with locks, cannot be cleared in bulk, and have no active-count indicator. Moving these to a collapsible side filter panel built on the existing `FilterGroup` / `FilterScopeController` engine unifies the UX and deletes a large amount of ad-hoc filter code in `mod_browser_page.dart`.

## What Changes

- Add a Filters side panel to the Catalog page, following the `CollapsedFilterButton` + `FiltersPanel` pattern used by ships/weapons/hullmods/portraits pages.
- Migrate the eight tri-state icon filters (download link, Discord, Index, Forum/Modding, Installed, Has Update, WIP, Archived) into a single `ChipFilterGroup<ScrapedMod>` "Attributes" group, using the chip engine's native tri-state (include / exclude / null) semantics. Chip labels keep the existing icons and tooltip wording.
- Migrate the Category dropdown into a `ChipFilterGroup<ScrapedMod>` (backed by `ScrapedMod.categories`), enabling multi-select that the previous dropdown could not express.
- Migrate the Game Version dropdown into an `EnumFilterGroup<ScrapedMod, _>` wrapped inside a `CompositeFilterGroup` so its selection can be persisted via the group's lock.
- Keep the Sort dropdown in the top toolbar — sort is not a filter and has no place in the filter engine.
- Reduce the top toolbar to: search box, clear-all button, overflow menu, sort dropdown. The filter icon / collapsed filter button moves to the left edge of the page content, matching the viewer pages.
- Delete the now-redundant `updateFilter()` body, the ad-hoc `filterHasDownloadLink`/`filterDiscord`/... state fields, and the `_versionGroupOptions` / `_categoryOptions` caches — replaced by `FilterScopeController<ScrapedMod>` driving `displayedMods`.
- Register a new `FilterScope(pageId: 'catalog')` with `persistenceEnabled: true` so locks on the Attributes / Category / Version-and-Sort groups restore across sessions, consistent with ships/weapons/hullmods/portraits.

## Capabilities

### New Capabilities

- `catalog-filter-panel`: Filters panel on the Catalog page driven by the shared filter engine — Attributes chips, Category chips, Version dropdown, collapse button with active-count badge, clear-all, per-group lock for persistence.

### Modified Capabilities

- `catalog-dropdowns`: Category and Version are no longer dropdowns in the top toolbar; they become filter-engine groups inside the new filter panel. The Sort dropdown remains in the top toolbar. The "Dropdowns integrate with existing filter pipeline" requirement is superseded by the new filter engine pipeline.

## Impact

- **Code**: `lib/catalog/mod_browser_page.dart` (largest change — toolbar rewrite, filter state removed), new `lib/catalog/mod_browser_page_controller.dart` wrapping `FilterScopeController<ScrapedMod>`, new `lib/catalog/widgets/catalog_filters_panel.dart`, adjusted layout to host both the filter panel (left) and the existing browser `SideRail` panel (right).
- **Settings / persistence**: No new settings fields. Filter-group lock state is stored under existing `PersistedFilterGroup` keyed by `('catalog', 'main', <groupId>)` — no migration needed since these keys are new.
- **UX**: The eight icon filters move from the top bar into the left panel as a labeled chip group; they keep tri-state semantics (click cycles include → exclude → off). Users get bulk clear, active-count badges, and locks they did not have before.
- **Specs**: `openspec/specs/catalog-dropdowns/spec.md` loses its category/version requirements (captured as deltas); the sort requirement stays. New `openspec/specs/catalog-filter-panel/spec.md` is added.
- **Dependencies**: None. Uses existing `lib/widgets/filter_engine/` and `lib/widgets/collapsed_filter_button.dart` / `lib/widgets/filter_widget.dart`.
