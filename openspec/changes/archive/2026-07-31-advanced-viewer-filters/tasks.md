# Advanced viewer filters — tasks

## Filter engine (shared layer)

- [x] Add `ChipLogicMode` enum (`any`, `all`) and `logicMode` field to `ChipFilterGroup`
- [x] Update `ChipFilterGroup.matches` to branch on `logicMode` for include checks
- [x] Update `ChipFilterGroup.serialize` / `restore` to persist logic mode
- [x] Add `RangeFilterGroup<T>` sealed subtype to `filter_group.dart` with `valueGetter`, `min`/`max`/`curMin`/`curMax`, `allowGreater`, `suffix`, `matches`, `serialize`/`restore`/`clear`
- [x] Add `updateRange(Iterable<T> items)` method on `RangeFilterGroup` to recompute min/max from data and clamp selection

## Filter UI (shared widgets)

- [x] Add logic-mode toggle button to `GridFilterWidget` header row (between group name and include-all button)
- [x] Wire logic button visibility: shown when advanced is on, or when `logicMode != any`
- [x] Add shift-click-to-solo in `GridFilterWidget._toggleValue` — clear group, set clicked chip to include
- [x] Add "Exclude all" icon button next to include-all and clear-all in `GridFilterWidget`
- [x] Build `RangeFilterWidget` — Flutter `RangeSlider`, header with range text, "and above" top label
- [x] Space the slider track one notch per real value (`stopIndexFor`), so lopsided stats like hull stay usable
- [x] Add `RangeFilterGroup` dispatch case to `FilterGroupRenderer.build`
- [x] Add search `TextField` to `FiltersPanel` header area with debounced input
- [x] Pass search term through to each `GridFilterWidget`; hide chips that don't match, hide groups with zero visible chips
- [x] Make include-all, clear-all, exclude-all respect the search term (only affect visible chips)
- [x] Add `isAdvanced` to `FiltersPanel`, shared with groups via the `FilterPanelOptions` inherited widget
- [x] Hide logic buttons (when default) when `isAdvanced` is false; range groups are always visible
- [x] Keep collapsed group count badges visible when group is collapsed (include count, exclude count) — already the case
- [x] Add expand-to-dialog button to `FiltersPanel` header
- [x] Build dialog wrapper: `showFilterPanelDialog` with wider `FiltersPanel` reusing the same controller and callbacks

## Ships page

- [x] Add `advancedFilters` bool to `ShipsPageStatePersisted`, default false
- [x] Add `setAdvancedMode()` to ships page controller
- [x] Add `RangeFilterGroup` instances to the ships filter group list (deployment points, speed, ordnance points, armor, hull, flux dissipation, flux capacity, max burn, fuel capacity, cargo capacity, crew capacity)
- [x] Call `updateRange` on range groups when the item list changes
- [x] Pass `isAdvanced` from persisted state through to `FiltersPanel`
- [x] Wire the advanced toggle in the ships page UI

## Weapons page

- [x] Add `advancedFilters` bool to `WeaponsPageStatePersisted`, default false
- [x] Add `setAdvancedMode()` to weapons page controller
- [x] Add `RangeFilterGroup` instances to the weapons filter group list (damage, OP cost, range, DPS, flux/sec, turn rate, ammo)
- [x] Call `updateRange` on range groups when the item list changes
- [x] Pass `isAdvanced` from persisted state through to `FiltersPanel`
- [x] Wire the advanced toggle in the weapons page UI

## Verification

- [x] Test: chip logic "all" mode correctly requires every included value to be present
- [x] Test: chip logic "any" mode matches existing behavior (at least one included value)
- [x] Test: range filter correctly includes/excludes by numeric bounds
- [x] Test: range filter "allow greater" top stop includes values above max
- [x] Test: every value in the data gets its own evenly spaced notch, and one
      runaway value doesn't squash the rest of the track
- [x] Test: shift-click solos a chip (clears group, sets clicked to include)
- [x] Test: panel search hides non-matching chips and empty groups
- [x] Test: include-all / clear-all / exclude-all respect the search term
- [x] Test: logic mode persists through serialize/restore
- [x] Test: range filter persists through serialize/restore
- [x] Test: advanced mode toggle persists per page — covered by the shared
      `_persistState` path plus generated mapper field; not separately tested
      because it needs the on-disk settings stack
- [x] Test: range filters are always visible regardless of advanced mode
- [x] Test: non-default logic mode stays visible when advanced is off
