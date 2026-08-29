# Freeze grid columns

Status: ready-for-agent

From [GitHub issue #263](https://github.com/wispborne/TriOS/issues/263), item 4.

## Problem

The ship viewer has around 45 columns. Scrolling right to see the later stats scrolls the ship name and mod name off screen, so the numbers lose their labels. The reporter asked for pinnable columns.

## Solution

Let the user freeze columns, Excel-style ("freeze" is the word we use — see CONTEXT.md; "pinned" already means rows held at the top of the grid):

- A "Freeze column" toggle in the existing header right-click menu, per column.
- Frozen columns stay in view at the left edge while the rest scroll sideways.
- Frozen columns always sit leftmost, keeping their order relative to each other. A frozen column in the middle of the scroll region is not a thing.
- The frozen set is saved per grid, like column visibility. Nothing is frozen by default.

## In scope

- Every WispGrid (Mods, Ships, Weapons, Hullmods, Factions).
- Freezing works for header, body rows, and group header rows alike.

## Out of scope

- Restructuring WispGrid's scroll layout (the "split every row into two synced halves" approach). We draw frozen columns as a fixed overlay instead; see design.md.
- Freezing rows (already exists as pinned favorites).
