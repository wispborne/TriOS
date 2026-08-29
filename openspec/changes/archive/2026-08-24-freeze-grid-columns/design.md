# Design: Freeze grid columns

## Why an overlay, not a structural split

Today one horizontal `SingleChildScrollView` wraps the entire grid — header and body together (`lib/mod_manager/homebrew_grid/wisp_grid.dart:696-715`). A "real" frozen column would split every row, the header, and every group header into a fixed left part and a scrolling right part, with all the right parts scroll-synced. Flutter doesn't allow one `ScrollController` across many attached scroll views, so that means linked-controller machinery, splitting the header's `MultiSplitView` resize model in two, and redoing the grid-width accounting that feeds persisted column widths. That is a rewrite of WispGrid's layout.

Instead: keep the layout as is and draw the frozen columns a second time, as a fixed layer stacked over the left edge of the horizontal scroll view.

- The horizontal offset already lives in one place, `_gridScrollControllerHorizontal`. The overlay listens to it: while the frozen columns' own position is still in view, the overlay is invisible; once the user scrolls past them, the overlay shows the frozen cells at the left edge.
- The overlay needs an opaque background (the grid's row background color, including hover/selection states) so scrolled content doesn't show through beneath it, plus a right-edge divider or shadow so it reads as "on top".
- Cost: frozen cells are built twice (once in the normal row where they may be scrolled out of view, once in the overlay). Accepted — it's a handful of cells per visible row.

If the overlay turns out to have bad seams (misaligned rows, hover states fighting), the structural split is the fallback; the state model below is the same either way.

## State model

- Add `isFrozen: bool` (default false) to `WispGridColumnState` (`lib/mod_manager/homebrew_grid/wisp_grid_state.dart:66-76`). The class is dart_mappable, so the new field is additive and old saved settings still load. Run build_runner after.
- Do not name anything "pinned" — `pinnedItems` / `_PinnedWispGridGroup` already mean rows held at the top (`wisp_grid.dart`).
- Display order: `sortedVisibleColumns` sorts frozen columns first (stable within each group), so the normal row layout, the header, and the overlay all agree on positions. Freezing a column visibly moves it to the left edge; unfreezing returns it to its position among the unfrozen columns.

## Overlay contents

Three row kinds need frozen counterparts:

- Header row: the frozen columns' headers, still sortable and still resizable. Resizing from the overlay can be deferred — resize via the normal header when scrolled left is acceptable for a first version.
- Body rows: the frozen columns' cells, with the row's hover/selection background.
- Group header rows (`wispgrid_group_row.dart`): group headers span the row; the overlay shows their leftmost slice so the group name stays readable.

Vertical scrolling needs no syncing — the overlay lives inside the same vertical scroll context, positioned over each row (a per-row `Stack`, or one grid-level `Stack` with a column of overlay cells that shares the vertical scroll position).

## UI

- Header right-click menu (`wispgrid_header_row_view.dart`): a single "Freeze this column" / "Unfreeze this column" item that acts on the column you right-clicked, sitting just under "Reset grid layout". Persisted through the same `updateGridState` path as visibility.
  - Not a checkbox per column next to the show/hide toggles, as first sketched: the ship viewer's menu already lists 45 visibility toggles, and a second list that long would bury everything else.
- Frozen state applies per grid page, saved in the existing per-page `WispGridState.columnsState`.

## Files that change

- `lib/mod_manager/homebrew_grid/wisp_grid_state.dart` — `isFrozen` field, ordering in `sortedVisibleColumns`. Plus generated `.mapper.dart`.
- `lib/mod_manager/homebrew_grid/wisp_grid.dart` — the overlay layer.
- `lib/mod_manager/homebrew_grid/wispgrid_row_view.dart`, `wispgrid_group_row.dart` — expose what the overlay needs to rebuild a row's frozen cells with correct backgrounds.
- `lib/mod_manager/homebrew_grid/wispgrid_header_row_view.dart` — menu toggle, frozen header rendering.
