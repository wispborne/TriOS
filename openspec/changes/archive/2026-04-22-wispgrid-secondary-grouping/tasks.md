## 1. State model

- [x] 1.1 Add `secondaryGroupedByKey: String?` to `GroupingSetting` in `lib/mod_manager/homebrew_grid/wisp_grid_state.dart`. Keep `currentGroupedByKey`, `isSortDescending`, and `headerStyle` unchanged.
- [x] 1.2 Run `dart run build_runner build --delete-conflicting-outputs` and commit the regenerated `wisp_grid_state.mapper.dart`.
- [x] 1.3 Verify existing persisted `WispGridState` entries in settings load with `secondaryGroupedByKey == null` (no crash, no behavior change).

## 2. Build-pipeline refactor

- [x] 2.1 In `_WispGridState.build` (`lib/mod_manager/homebrew_grid/wisp_grid.dart`), resolve `secondaryGrouping` as `widget.groups.firstWhereOrNull((g) => g.key == groupingSetting?.secondaryGroupedByKey)`. Treat it as `null` if it equals the primary grouping.
- [x] 2.2 Replace the existing `Map<Comparable?, List<T>>` build with a two-step build:
  - Primary: `Map<Comparable?, List<T>>` using `grouping.getAllGroupSortValues`.
  - Secondary (only when `secondaryGrouping != null`): for each primary bucket, `Map<Comparable?, List<T>>` using `secondaryGrouping.getAllGroupSortValues` over that bucket's items.
- [x] 2.3 Sort primary entries with the existing `groupingSetting?.isSortDescending` rule. Sort secondary entries in ascending order of sort value (no descending option for now).
- [x] 2.4 Preserve pinned-group synthesis (`__pinned__`) at the top; pinned group is never secondary-grouped.

## 3. Rendering

- [x] 3.1 Extend `WispGridGroupRowView` with an optional `headerStyleOverride: GroupHeaderStyle?` parameter. When null, fall back to `gridState.groupingSetting?.headerStyle` as today.
- [x] 3.2 In the build walk, emit the primary header with no override (uses user's `headerStyle`), and emit secondary headers with `headerStyleOverride: GroupHeaderStyle.small`.
- [x] 3.3 Pass the correct `itemsInGroup` to each secondary header (the inner bucket only).
- [x] 3.4 Confirm overlay widgets render on both primary and secondary headers (no special-casing — the existing `overlayWidget` hook is called with the level's own `itemsInGroup`).
- [x] 3.5 Update `_isGroupHeader` recognition if any header-widget wrapper changes; otherwise leave untouched.
- [x] 3.6 Update `_buildItemSliver`'s `itemExtentBuilder` to return `GroupHeaderStyle.small` height (28.0) for secondary headers specifically; via a new `_headerStyleFor(Widget)` that reads `WispGridGroupRowView.headerStyleOverride` (unwrapping any `_DragTargetGroupHeader` wrapper).

## 4. Drag-and-drop

- [x] 4.1 Wrap the secondary group header in a `_DragTargetGroupHeader` when `secondaryGrouping.supportsDragAndDrop` is true (mirrors existing primary logic).
- [x] 4.2 Confirm per-row `DragTarget` continues to wire to the *primary* grouping only (current mod-manager behavior: rows are dragged along the category dimension). Do not duplicate row-level drag targeting onto the secondary grouping.
- [ ] 4.3 Manual-verify: with Category primary + Enabled secondary, dragging a row still moves categories; dropping on the "Enabled"/"Disabled" headers does nothing (since `EnabledStateModGridGroup` doesn't override `onItemsDropped`). *(Requires runtime verification by the user.)*

## 5. Collapse state

- [x] 5.1 Replace `collapseStates: Map<Object?, bool>` keying with a compound key. Chose a small `_CollapseKey(primary, secondary?)` class with `==`/`hashCode` based on both fields. In-memory only (no persistence).
- [x] 5.2 Update `setCollapsed` callbacks on primary and secondary headers to write the correct keys.
- [x] 5.3 Primary-collapsed short-circuits secondary emission (skip inner loop entirely).

## 6. Context menu

- [x] 6.1 In `wispgrid_group_row.dart:_buildGroupHeaderContextMenu`, add a sibling `MenuItem.submenu` labeled "Then By" immediately after the existing "Group By" submenu. Icon: `Icons.subdirectory_arrow_right`.
- [x] 6.2 Populate "Then By" with:
  - A leading `MenuItem` "None" (sets `secondaryGroupedByKey` to `null`), checked when current secondary is null.
  - One entry per group in `widget.groups` whose key != `groupingSetting?.currentGroupedByKey`, checked when it matches the current secondary.
- [x] 6.3 Hide the "Then By" submenu entirely when `widget.groups.length <= 1`.
- [x] 6.4 Hide the "Then By" submenu when the candidate list would contain only "None" (covered by the `thenByCandidates.isNotEmpty` check).
- [x] 6.5 Selecting a secondary option updates `GroupingSetting.secondaryGroupedByKey` via `widget.updateGridState`.
- [x] 6.6 If the user changes the primary to a key that currently equals the secondary, clear `secondaryGroupedByKey` to `null` in the same update.

## 7. CSV export

- [x] 7.1 Extend `_lastDisplayedItemsInGroups` to carry two levels: replaced with `_lastRenderedGroups: List<_RenderedGroup<T>>`, each holding a list of `_RenderedSubgroup<T>`. Single-level case still works (one synthetic subgroup with `grouping == null`).
- [x] 7.2 In `WispGridCsvExport.toCsv`, emit `# Group: <primary name>` per primary, then for each secondary subgroup emit `## Subgroup: <secondary name>` followed by the item rows. When secondary is `null`, omit the `## Subgroup:` line.
- [ ] 7.3 Add a test — ideally a small widget test or a pure-logic test — confirming CSV shape in both single-level and two-level cases. *(Skipped — WispGrid has no existing test coverage; manual verification planned during runtime check.)*

## 8. Verification

- [ ] 8.1 Build and manually verify on the mods page. *(Requires runtime verification by the user.)*
- [ ] 8.2 Spot-check ships, weapons, hullmods, portraits pages. *(Requires runtime verification by the user.)*
- [ ] 8.3 Confirm settings round-trip. *(Requires runtime verification by the user.)*
- [x] 8.4 Run `dart analyze`; no new warnings introduced (existing pre-existing warnings unchanged).
- [x] 8.5 Update `changelog.md` with an `Added` entry for two-level grouping on WispGrid.

## 9. Docs

- [x] 9.1 Added a short note to `.claude/CLAUDE.md` under "WispGrid" describing the two-level grouping.
