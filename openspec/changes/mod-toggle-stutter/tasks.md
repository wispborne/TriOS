# Tasks: Fix mod-toggle UI stutter

## 1. Fix `smolIds` content equality

- [ ] 1.1 In `lib/trios/app_state.dart`, change the `smolIds` provider so it only emits a new value when the list content actually changes (not just the list reference). Either convert to a `Notifier` that compares before updating, or use a helper that caches the previous sorted list and returns the same reference when content matches.

## 2. Memoize search index rebuilds

- [ ] 2.1 In `ShipsPageController.build()` (`lib/ship_viewer/ships_page_controller.dart`), skip `_updateSearchIndices()` when `allShips` is the same list reference as the previous build. Cache the result and the source list identity.
- [ ] 2.2 Apply the same memoization in `WeaponsPageController.build()` (`lib/weapon_viewer/weapons_page_controller.dart`).
- [ ] 2.3 Apply the same memoization in `HullmodsPageController.build()` (`lib/hullmod_viewer/hullmods_page_controller.dart`).

## 3. Skip unnecessary filter recomputation

- [ ] 3.1 In `ShipsPageController.build()`, detect when only `AppState.mods` changed (items unchanged) and the "Only Enabled Mods" filter (`showEnabled`) is inactive (value is `null`). In that case, return the previous state with only loading/metadata fields updated — skip `_processAllFilters()`.
- [ ] 3.2 Apply the same optimization in `WeaponsPageController.build()`.
- [ ] 3.3 Apply the same optimization in `HullmodsPageController.build()`.

## 4. Verify

- [ ] 4.1 Launch app, visit all three viewer pages, navigate back to mod manager, toggle a mod on/off. Confirm stutter is reduced.
- [ ] 4.2 With "Only Enabled Mods" filter active, toggle a mod. Confirm the filter updates correctly (items appear/disappear as expected).
- [ ] 4.3 Add a new mod folder while viewers are loaded. Confirm viewers pick up the new data (smolIds equality fix doesn't suppress real changes).
