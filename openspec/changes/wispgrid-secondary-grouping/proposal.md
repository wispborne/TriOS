## Why

Users want to group by Category *and* Enabled/Disabled at the same time — "show me Faction mods split into what's enabled vs disabled, then show me Utility mods split the same way." Today `WispGrid` supports exactly one grouping dimension at a time (`GroupingSetting.currentGroupedByKey`), so this has to be faked by repeatedly switching the active grouping.

Adding a second level of grouping — primary (e.g. Category) with an optional secondary (e.g. Enabled) nested underneath — lets users see both dimensions together without losing the existing single-level behavior.

## What Changes

- Extend `GroupingSetting` with a nullable `secondaryGroupedByKey: String?`. When `null`, the grid behaves exactly as today.
- Refactor the build pipeline in `_WispGridState.build` to emit a nested `Map<Comparable?, Map<Comparable?, List<T>>>` when a secondary key is set, and to walk primary → secondary → rows.
- Secondary group headers always render in `GroupHeaderStyle.small` (the divider-line style). The user-configurable `headerStyle` continues to apply to the primary header only.
- Overlay widgets (e.g. VRAM sum) render on both primary and secondary headers.
- Context menu on group headers grows a sibling **"Then By"** submenu next to **"Group By"**. The secondary list contains `None` plus all groupings except the primary pick. The "Then By" submenu is **hidden** when it would be trivially useless:
  - `widget.groups.length <= 1`, or
  - the non-primary grouping list would be empty (only "None" left).
- Collapse state extends to a compound key so primary and secondary groups collapse independently. Collapsing a primary hides all its secondaries (natural consequence of the render walk).
- Drag-and-drop targets the level the user drops on. Dropping on a secondary header fires that grouping's `onItemsDropped`; the primary grouping is not involved for that operation.
- CSV export emits a second-tier `## Subgroup: …` marker under the existing `# Group: …`.
- No secondary sort-direction toggle for now. Secondary groups sort with their grouping's natural order (ascending by sort value).
- Multi-group items (`getAllGroupSortValues` returning >1) fan out at the primary level exactly as today; within each primary bucket, secondary grouping runs normally over the contained items.

## Capabilities

### New Capabilities

- `wispgrid-grouping`: the set of rules `WispGrid` follows to build, sort, render, and serialize grouped rows — including primary/secondary group selection, nested header rendering, collapse state, drag-and-drop targeting, and overlay placement.

## Impact

- **Code** — touches `lib/mod_manager/homebrew_grid/wisp_grid.dart` (build loop, collapse state), `wisp_grid_state.dart` (`GroupingSetting` field), `wispgrid_group_row.dart` (context menu), regenerated `.mapper.dart`. No touch to the `WispGridGroup` subclasses themselves.
- **Settings schema** — `GroupingSetting` gains a nullable field. Existing persisted states load unchanged (null secondary = current behavior). No migration needed.
- **User-visible behavior** — default behavior (single-level grouping) is unchanged. Users opt in by choosing a "Then By" value. All existing viewer pages (ships, weapons, hullmods, portraits) inherit the new menu entry; worth a pass during implementation to confirm it reads sensibly everywhere, but no per-page opt-out planned.
- **Dependencies** — none added.
