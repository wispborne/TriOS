## Why

Every viewer page (ships, weapons, hullmods, portraits) hand-rolls the same filter machinery: tri-state chip application, an ad-hoc "checkbox card" with stringly-typed persistence keys (`'spoilerLevelToShow=showNone': true`), duplicated `activeFilterCount`/`clearAllFilters`/`updateFilterStates`, and its own `FilterGroupStager` wiring. The duplication totals ~150 lines per page, the chip-apply logic has already drifted between pages (ships/weapons vs hullmods), and `showEnabled`/spoiler-enum state is written to settings through two parallel paths (`appSettings.<page>PageState` *and* the filter-group lock), which is redundant and occasionally inconsistent.

A generic filter engine — a toolkit of typed filter groups and a scope-aware controller helper — collapses the duplication, gives heterogeneous groups (checkbox + dropdown in one card) a typed home, and lets portraits' per-pane filter scopes work without ad-hoc page-id suffixes.

## What Changes

- Add a `FilterGroup<T>` sealed type with variants: `ChipFilterGroup<T>` (today's `GridFilter`), `BoolFilterGroup<T>`, `EnumFilterGroup<T, E>`, and `CompositeFilterGroup<T>` (heterogeneous fields under one lock).
- Add `FilterScope` = `(pageId, scopeId)` as the persistence identity so a single page can host multiple independent filter scopes (portraits main/left/right).
- Add `FilterScopeController<T>` as a toolkit — **not a framework** — exposing `loadPersisted`, `applyChipFilters`, `applyNonChipFilters`, `activeCount`, `clearAll`, `maybePersist`. Page controllers keep their own pipeline ordering and call these as functions.
- Add `FilterGroupRenderer` widget that switches on the sealed group type to render chip panel / checkbox / dropdown / composite-card.
- Canonicalize chip filter application on the hullmods variant (cleanly handles both `valueGetter` and `valuesGetter` paths); the ships/weapons variant is replaced.
- **BREAKING (pre-release)** Widen `PersistedFilterGroup.selections` from `Map<String, bool?>` to `Map<String, Object?>` and bump `schemaVersion` to 2. No migration — v1 is unreleased.
- **BREAKING (semantics)** Filter-adjacent toggles (`showEnabled`, `showHidden`, `spoilerLevelToShow`, `weaponSpoilerLevel`, `hullmodSpoilerLevel`, portraits' `showOnlyWithMetadata`/`showOnlyReplaced`/`showOnlyEnabledMods`) are removed from `appSettings.<page>PageState` and persisted **only** via filter-group locks. Unlocked groups reset to defaults each session. Non-filter UI state (`showFilters`, `splitPane`, `useContainFit`, portrait `mode`/`portraitSize`) continues to always persist.
- Migrate ships, weapons, hullmods, and portraits (all three scopes) to the new engine. Portraits `left`/`right` scopes deliberately have no lock UI and no persistence.
- Remove the stringly-typed encoding (`'spoilerLevelToShow=showNone': true`) in favor of typed composite-field serialization.

## Capabilities

### New Capabilities

- `filter-engine`: typed filter groups, scope-aware controller toolkit, and renderer widget that all viewer pages use to define and apply filters.

### Modified Capabilities

- `filter-group-persistence`: settings schema widens to hold heterogeneous typed selections, persistence keys grow a scope component, and the shared lock UI covers composite (mixed checkbox + dropdown) groups.

## Impact

- **Code** — net reduction across `lib/ship_viewer/`, `lib/weapon_viewer/`, `lib/hullmod_viewer/`, `lib/portraits/` controllers (~500 lines removed). New module `lib/widgets/filter_engine/` (~400 lines added).
- **Settings schema** — `PersistedFilterGroup.selections` widens to `Map<String, Object?>`; `schemaVersion` → 2. `ShipsPageStatePersisted`, `WeaponsPageStatePersisted`, `HullmodsPageStatePersisted` lose their filter-adjacent booleans. `PortraitsPageStatePersisted` loses nothing (it only holds `mainShowFilters`).
- **User-visible behavior** — filter-adjacent toggles no longer persist unless the user locks their group. Chip filter state is unchanged behaviorally. Portraits left/right panes behave identically.
- **Dependencies** — none added.
- **Pre-existing filter locks on disk** — v1 entries are dropped silently on load (unreleased schema, documented in design).
