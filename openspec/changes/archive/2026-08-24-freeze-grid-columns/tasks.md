# Tasks: Freeze grid columns

- [x] Add `isFrozen` (default false) to `WispGridColumnState`; run build_runner; confirm old saved settings still load.
- [x] Sort frozen columns first in `sortedVisibleColumns` so header, rows, and overlay agree on positions.
- [x] Add a "Freeze column" toggle to the header right-click menu, persisted like column visibility.
- [x] Build the overlay: frozen header cells, frozen body cells, and the group-header slice, drawn at the left edge and driven by the existing horizontal scroll controller.
- [x] Give the overlay an opaque row background (including hover/selection states) and a right-edge divider or shadow.
- [x] Confirm freezing works on the Mods, Ships, Weapons, Hullmods, and Factions grids, with grouping on and off.
- [x] Check the overlay against the pinned-favorites row group and the VRAM overlay alignment in `wispgrid_group.dart`.
