## Context

TriOS has four "viewer" pages (Ships, Weapons, Hullmods, Portraits) that share a filter UX built on `GridFilterWidget` and `FiltersPanel` in `lib/widgets/filter_widget.dart`. Each viewer also uses a bespoke checkbox-filter card (e.g., "civilian", "has phase cloak") defined per-page. Filter state lives in each page's `Notifier<XxxPageState>` controller and is discarded on app shutdown.

Settings are persisted centrally through `lib/trios/settings/settings.dart`, a `@MappableClass` serialized via `dart_mappable` through the `appSettings` Riverpod provider. Viewer controllers read settings at init and watch manager providers (e.g., `shipManagerProvider`) that start in `AsyncLoading` and resolve to a list of items. Filter state in the controllers is keyed by filter name (a `String`) and maps values to tri-state `bool?`.

Constraints:
- Must not break existing settings deserialization — purely additive.
- Filter selections can reference IDs that no longer exist when a mod is uninstalled; reapply must be robust to "unknown" entries.
- Manager data may arrive after the page is built; reapply must not flash-clear selections.

## Goals / Non-Goals

**Goals:**
- Opt-in, per-filter-group persistence with a tiny lock icon inside each filter group header.
- One shared widget (`FilterGridPersistButton`) reusable from `GridFilterWidget` and from the per-page checkbox-filter cards.
- Stable keying via `(pageId, filterGroupId)` so selections survive app updates and filter reordering.
- Load-safe reapply: saved selections are staged and applied only after the underlying manager reports data-ready.
- Default-off; existing behavior is unchanged for users who never click the lock.

**Non-Goals:**
- No "persist all filters with one switch" master toggle.
- No cross-page filter sharing or filter presets/named profiles.
- No sync across machines; local settings only.
- No persistence of UI-only state (expanded/collapsed, search text) — that is unrelated and out of scope.
- No migration of historical filter state — persistence starts empty on first load after this change.

## Decisions

### Decision 1: Storage shape — single map on `Settings`

Add `Map<String, PersistedFilterGroup> persistedFilterGroups` to `Settings`, where:
- Key: `"<pageId>::<filterGroupId>"` (e.g., `"ships::hullSize"`).
- Value: `PersistedFilterGroup` = a `@MappableClass` carrying the tri-state map (`Map<String, bool?>`) plus a schema version int.

**Alternatives considered:**
- Separate per-page nested maps. Rejected: more model churn for no real payoff; the flat map is trivial to query and easy to garbage-collect by prefix if a page is removed.
- A dedicated JSON file in the app data directory. Rejected: filter state is tiny (bytes), and lives naturally next to other viewer-page prefs already kept in `Settings`.

### Decision 2: UI affordance — lock icon as `IconButton` inside header row

The lock toggle is a small `IconButton` (16px icon) placed in the existing header `Row` of `GridFilterWidget`, next to the include-all/clear-all buttons. Icons: `Icons.lock_outline` (off) / `Icons.lock` (on), with a `MovingTooltipWidget` explaining the behavior. Per project convention (memory: "All new icons must have tooltips"), this is mandatory.

For checkbox-filter cards, expose the same `FilterGridPersistButton` widget so each page can drop it into that card's header.

**Alternatives considered:**
- A checkbox. Rejected — would visually compete with the filter chips, which already use checkbox-like affordances.
- A star/pin icon. Rejected — "lock" conveys "stick in place" more clearly than "favorite".

### Decision 3: Staging and apply order — two-phase reapply guarded by manager readiness

Each viewer's controller gains a `pendingPersistedFilters: Map<String, Map<String, bool?>>` (keyed by filterGroupId) populated at controller init from `Settings.persistedFilterGroups`. The controller's existing logic that depends on manager data (already `ref.watch`-ing an `AsyncNotifier`) runs an `_applyPendingPersistedFilters()` step the first time data becomes available. The step:
1. Iterates each locked group.
2. For each saved `(value, tristate)` entry, writes it into the group's `filterStates` map only if a filter with that name is registered for the page. Unknown filter values are silently retained in the pending map (in case they later become valid, e.g., after a different manager loads) but not applied into live state — this avoids dropping persisted data on a transient empty manager load.
3. Sets a `_persistedApplied` flag so we don't overwrite later user edits.

Writes go the other way: whenever a locked group's `onSelectionChanged` fires, the controller updates both the live state and the persisted settings entry (debounced at the settings layer if already debounced elsewhere; otherwise written immediately, since settings writes are cheap).

**Alternatives considered:**
- Apply persisted state unconditionally in controller `build()`. Rejected: would race with manager readiness and risk being overwritten by a default empty `filterStates`.
- Block UI until persisted filters are ready. Rejected: persisted state is already available synchronously from settings; only the data-dependent validation needs to wait.

### Decision 4: Keying — stable per-group IDs provided by call site

Each viewer page passes an explicit `filterGroupId: String` (e.g., `'hullSize'`, `'shipTags'`) when constructing a `GridFilterWidget` or the shared lock button. Required, not inferred from the display name, so renames and translations don't break persistence. `pageId` is a property of the viewer page's controller (e.g., `'ships'`).

**Alternatives considered:**
- Derive key from `GridFilter.name`. Rejected: display names are user-facing and could change; also conflicts with future localization.

### Decision 5: Toggling the lock off clears the saved entry but NOT the live state

When a user turns the lock off, we remove the settings entry for that group. The in-memory `filterStates` is unchanged, so the user's current view stays put — they just no longer persist the group going forward. This matches the "lock" metaphor: unlocking releases persistence, not selections.

## Risks / Trade-offs

- **Stale persisted values reference deleted mods/items.** → Mitigation: unknown values are retained in the pending map and are simply inert until (if ever) the matching item reappears. We never delete them proactively, so reinstalling a mod re-lights its filters. A user-visible "clear all persisted filters" settings action is out of scope but easy to add later.
- **Two filter groups on different pages with the same id collide.** → Mitigation: the storage key is `"<pageId>::<filterGroupId>"`. Page IDs are centrally defined and reviewed.
- **User enables the lock before the manager has loaded.** → Mitigation: lock-on writes the *current* (possibly empty) filterStates to settings. This is correct behavior ("lock what I see now, even if empty").
- **Schema evolution.** → Mitigation: `PersistedFilterGroup` carries `int schemaVersion` (initial value 1). A future mapping hook can drop entries with unknown versions.
- **Settings write amplification** from chip-toggle storms is theoretically possible. → Mitigation: existing settings save path is already the write channel for viewer prefs and handles frequent writes without issue; no new debounce introduced unless profiling shows a problem.
