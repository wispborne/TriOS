## Why

Users on the Ships, Weapons, Hullmods, and Portraits viewer pages currently lose all of their applied filter selections every time the app restarts. This is frustrating for users who repeatedly narrow a viewer to the same categories (e.g., "only civilian ships", "only energy weapons"), but blanket persistence of *every* filter state would be equally annoying — filters set for a one-off search would stick around forever. A lightweight, opt-in persistence mechanism lets power users pin the filters that matter without disturbing casual, exploratory filtering.

## What Changes

- Introduce a shared per-filter-group "persistence lock" affordance: a small lock icon rendered in the corner of each filter group's header, disabled by default.
- When the lock is enabled, the filter group's current selections (and any future edits while the lock remains on) are saved to app settings, keyed by a stable `(pageId, filterGroupId)` pair.
- On page load, locked filter groups reapply their saved selections. Values are held in a staged state until the underlying manager finishes loading data, so a half-loaded dataset cannot clear them.
- Toggling the lock off clears the saved entry for that group but leaves the current in-memory selections untouched.
- Apply to `GridFilterWidget` (shared) and to the checkbox-filter cards used by Ships, Weapons, Hullmods, and Portraits viewer pages.

## Capabilities

### New Capabilities
- `filter-group-persistence`: Opt-in per-filter-group persistence of user filter selections across app sessions, with a shared lock-icon UI, stable keying, and load-order guarantees that prevent saved filters from being dropped while manager data is still loading.

### Modified Capabilities
<!-- None: no existing spec covers filter state behavior. -->

## Impact

- **Shared widgets**: `lib/widgets/filter_widget.dart` (`GridFilterWidget`, `FiltersPanel`) gains the lock affordance and a persistence hook. A new small widget (`FilterGridPersistButton`) is added for reuse by checkbox-filter cards.
- **Viewer pages**: `lib/ship_viewer/ships_page.dart`, `lib/weapon_viewer/weapons_page.dart`, `lib/hullmod_viewer/hullmods_page.dart`, `lib/portraits/portraits_page.dart` — each filter group call-site passes a stable `persistenceKey` and participates in the staged-apply flow.
- **Viewer controllers**: Each `xxx_page_controller.dart` gains a "pending persisted filters" staging area and an apply step that runs once its manager reports data-ready.
- **Settings model**: `lib/trios/settings/settings.dart` gains a new `persistedFilterGroups` field (a map of string key → serialized filter-group state). Requires `dart run build_runner build --delete-conflicting-outputs`.
- **No breaking changes** to existing saved settings — new field is additive with a default empty map.
