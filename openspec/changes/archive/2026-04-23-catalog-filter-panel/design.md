## Context

The Catalog page (`lib/catalog/mod_browser_page.dart`) predates the generic filter engine that was introduced for the ships / weapons / hullmods / portraits pages. Its top toolbar owns:

- 8 `buildTristateTooltipIconButton`s (download link, Discord, Index, Forum/Modding, Installed, Has Update, WIP, Archived) each backed by a `bool?` field on `_CatalogPageState`.
- 3 `TriOSDropdownMenu`s (category string, version group key, `CatalogSortKey` enum).
- A `SearchController`-backed search box and an overflow menu.

The filtering logic lives in a 130-line imperative `updateFilter()` method that runs the pipeline by hand. No locks, no clear-all, no active-count badge, no per-group persistence. All state is ephemeral per `_CatalogPageState`.

Meanwhile `lib/widgets/filter_engine/` already provides everything this page needs:

- `ChipFilterGroup<T>` with native tri-state chip semantics.
- `EnumFilterGroup<T, E>` / `BoolFilterGroup<T>` / `CompositeFilterGroup<T>`.
- `FilterScopeController<T>` toolkit with `applyChipFilters` / `applyNonChipFilters` / `activeCount` / `clearAll` / `setChipSelections` / `loadPersisted` / `maybePersist`.
- `FilterGroupRenderer<T>` + `FiltersPanel` + `CollapsedFilterButton` UI.
- Persistence via `PersistedFilterGroup` keyed by `(pageId, scopeId, groupId)`.

Constraints: the Catalog page already hosts a right-side `SideRail` browser panel. We must keep that side rail intact while adding a **left-side** filters panel. Layout becomes: `[FiltersPanel | mod grid | SideRailPanel(browser)]`.

Stakeholders: Catalog is the second most visited page after the Mod Manager; filter state changes must not cause the grid to reset scroll position or re-hydrate unnecessarily.

## Goals / Non-Goals

**Goals:**

- Bring Catalog filtering in line with the ships/weapons/hullmods/portraits pages — same collapsible panel, same lock button, same chip semantics, same `activeCount` badge, same clear-all.
- Delete the ad-hoc imperative `updateFilter()` body and the standalone `bool?` fields. Filter state lives in one place: a `FilterScopeController<ScrapedMod>` owned by a new `CatalogPageController` (Riverpod `Notifier`).
- Persist lockable groups under `FilterScope(pageId: 'catalog', scopeId: 'main')`.
- Preserve existing behavior: tri-state semantics on the attribute filters, the same "has download", "installed", "has update", "WIP", "archived" predicates, and the same sort order pipeline.

**Non-Goals:**

- Migrating the Sort dropdown into the filter engine. Sort is not a filter, the engine has no sort abstraction, and sort does not need to persist per-group locks (it persists via its own setting if at all, which is outside this change).
- Changing the data model for `ScrapedMod`, the catalog scraping pipeline, or the browser side rail.
- Persisting the search-box text across sessions. Existing behavior is non-persistent; keep it.
- Visually matching the eight icons 1:1 in the chip group (see Decisions).

## Decisions

### Decision 1: Collapse the 8 tri-state icon filters into one `ChipFilterGroup<ScrapedMod>` called "Attributes".

The existing icon buttons already model tri-state (include / exclude / null). That is exactly what `ChipFilterGroup` natively expresses, with the canonical chip-match algorithm already handling the "at least one include ∧ no exclude" logic we currently reimplement by hand eight times.

Map each filter to a chip-value string:

- `hasDownloadLink` → `'download'`
- `discord` → `'discord'`
- `index` → `'index'`
- `forumModding` → `'forum'`
- `installed` → `'installed'`
- `hasUpdate` → `'update'`
- `wip` → `'wip'`
- `archived` → `'archived'`

`valuesGetter` on the group returns the set of chip-value strings that apply to each `ScrapedMod` (derived from `urls`, `sources`, `_catalogStatusMap`, and the forum lookup). `displayNameGetter` returns the human label ("Has Download", "Discord", "Index", "Forum", "Installed", "Has Update", "WIP", "Archived"). `useDefaultSort` is **false** and we provide an explicit `sortComparator` that preserves the existing left-to-right ordering — we do NOT want alphabetical order to scramble a familiar layout.

**Alternative considered:** leave the eight icons as a bespoke widget inside the filter panel, bypassing the chip renderer to preserve icons. Rejected because it forks the UX (no `GridFilterWidget` lock button, no standard collapse header, no `activeCount` integration on those eight).

**Alternative considered:** extend `ChipFilterGroup` / `GridFilterWidget` with an optional `iconGetter(String value)`. Worth doing eventually but out of scope — the feature is a latent enhancement to every viewer page, not a Catalog-specific need, and can be a follow-up change. For now, text labels are acceptable; they match every other viewer page.

### Decision 2: Category becomes a `ChipFilterGroup<ScrapedMod>`, not an `EnumFilterGroup`.

`ScrapedMod.categories` is a `List<String>?` — multi-valued per mod. A `ChipFilterGroup` with `valuesGetter: (m) => m.categories ?? []` gets us: multi-select, exclude-this-category, and free persistence. The current single-select dropdown is strictly less capable.

Group id: `'category'`. Sort: alphabetical (default). Collapsed by default: **true** (there can be many categories; keep the panel short).

### Decision 3: Version becomes an `EnumFilterGroup<ScrapedMod, _VersionChoice>` wrapped in a `CompositeFilterGroup`.

Version is intentionally single-select (choosing "0.97" and "0.98" simultaneously rarely makes sense; the base-version bucketing logic already groups RCs/letter-suffixes together). Enum fits. We define a synthetic `enum VersionChoice` at runtime by seeding an `EnumField` over dynamic string keys — except `EnumField` requires an `E extends Enum`, which precludes dynamic keys.

Two subpaths:

- **3a (chosen):** keep the previous "All Versions / <versionKey>" model with a fixed enum `VersionFilterMode { all, only }` plus a companion string slot for the currently-selected version bucket. Since the list of version buckets is data-driven, model this as a tiny `StringSelectField` or — simplest — as a custom `FilterField<ScrapedMod>` inside a `CompositeFilterGroup`. This keeps us inside the existing sealed API by subclassing `FilterField<T>`.
- **3b:** leave the version dropdown in the top toolbar, not in the panel. Rejected because (a) the user asked for dropdowns-at-top → panel-on-side, and (b) it fragments the filter state across two systems.

Group id: `'version'`, wrapped in a `CompositeFilterGroup` id `'version'` so it gets a lock button. Default selection: the newest version bucket key (matches current "default to the highest version on first load" behavior in `mod_browser_page.dart:230`).

Because `FilterField` is a sealed class, 3a requires a small extension — we add a `StringChoiceField<T>` implementation next to the existing `BoolField` / `EnumField` in `filter_engine/filter_group.dart`. This is a local, additive change to the sealed type that unlocks version (and any future data-driven single-choice filter). The alternative — coercing into an `EnumField` with a placeholder enum — is strictly worse.

**Alternative considered:** a `ChipFilterGroup` for versions. Rejected because version bucketing is not naturally multi-select and the existing UX treats it as single-choice.

### Decision 4: Keep Sort in the top toolbar.

Sort runs as the final pipeline step in `updateFilter()` today. That stays. The top toolbar after this change contains: clear-all button (mirrors the filter panel's clear-all so it's reachable even when panel is collapsed), search box, sort dropdown, overflow menu. No filter icons and no category/version dropdowns.

### Decision 5: Introduce a `CatalogPageController` (Riverpod `Notifier<CatalogPageState>`) and move `displayedMods` off `_CatalogPageState`.

The controller owns `FilterScopeController<ScrapedMod>`, the sort key, the search query, and the derived `filteredMods`. Mirrors the ships/weapons/hullmods/portraits pattern. The `ConsumerStatefulWidget` stays but shrinks to UI concerns: the WebView, the split panel state, the search-controller text field.

`CatalogPageState` is a `@MappableClass` with a `CatalogPageStatePersisted` nested class for `showFilters` / `splitPane`-equivalent toggles. Persistence piggybacks on app settings as the other viewer pages do.

### Decision 6: Pipeline order.

`updateFilter()` is replaced by a pure getter on `CatalogPageState` that computes:

1. Search (text) — `searchScrapedMods(allMods, query)` if non-empty.
2. `applyChipFilters` (Attributes + Category).
3. `applyNonChipFilters` (Version composite).
4. `sortScrapedMods(..., selectedSort, ...)`.

This matches the spec requirement "dropdowns integrate with existing filter pipeline" (search → chips → composite → sort), which is what the old code did with different plumbing.

### Decision 7: Layout.

```
Column
 ├─ Top toolbar (search, clear-all, sort, overflow)
 └─ Expanded
     └─ SideRail  (panel=browser, right side)
         └─ contentBuilder: Row
             ├─ CollapsedFilterButton  | FiltersPanel   (left)
             └─ Expanded: mod grid
```

The existing `SideRail` browser panel is unchanged. The new filter panel nests inside the `SideRail.contentBuilder`, following the way ships does it (`Row { filtersSection, Expanded(grid) }`).

## Risks / Trade-offs

- **Loss of per-filter icons for the eight attribute filters** → Mitigation: keep the textual chip labels short and familiar, and tooltips via chip tooltips. A follow-up change can add optional icons to `ChipFilterGroup` across all viewer pages.
- **Version-filter requires extending the sealed `FilterField` hierarchy** → Mitigation: the addition of `StringChoiceField<T>` is small, local, and mirrors `EnumField` almost exactly. It benefits every future page that needs a data-driven single-choice field. No other page is affected because the sealed dispatch in `FilterGroupRenderer` needs a single new case.
- **Scroll position or grid state resets when filters change** → Mitigation: `displayedMods` is already recomputed on every filter change today; the controller holds the derived list so grid rebuilds remain O(filtered). No change in render cost.
- **First-load defaults (select newest version) must still fire exactly once** → Mitigation: port the `_hasAppliedInitialDefaults` gate into the controller; call `_filters.loadPersisted(...)` first, then apply the version default only if the persisted load did not restore a value.
- **Tri-state semantics of the eight chips look unfamiliar** → Mitigation: they are identical to the semantics on every other viewer page. The tooltip says "click to include / click again to exclude". No functional regression.
