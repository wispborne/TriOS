# Previous/Next in the ship, weapon and hullmod dialogs

## The problem

Clicking a row in the Ships, Weapons or Hullmods viewer opens a details dialog.
To look at the next item you have to close the dialog, find the next row, and
click it again. Comparing a run of similar ships means doing that over and over.
The Codex has the same problem: open an entry's dialog, close it, pick the next
one from the list.

## The solution

Put **Previous** and **Next** buttons in the three details dialogs (ship,
weapon, hullmod), and make the arrow keys do the same thing. The dialog stays
open and swaps to the item before or after the current one.

The order is whatever the user is looking at — the grid's current sort,
grouping and filters, not the raw data order. In the Codex it's the current
list of visible entries.

Rules we settled on:

- **Stop at the ends.** Previous is greyed out on the first item, Next is greyed
  out on the last. No wrapping around.
- **All four arrow keys move.** Left and Up go back, Right and Down go forward.
- **The grid behind the dialog does not move.** It keeps its scroll position.
- **The Codex walks its own list**, and can cross between kinds — ship to weapon
  to hullmod — because that's the order the Codex shows them in.

## In scope

- Previous/Next buttons and arrow keys in the ship, weapon and hullmod details
  dialogs.
- Paging follows the displayed order from the viewer grids.
- Paging follows the visible entry list in the Codex, including moving between
  ships, weapons and hullmods.

## Out of scope

- The faction dialog (`FactionProfileDialog`) and the catalog mod dialog. The
  ask was the three viewer dialogs. Faction entries in the Codex list are
  skipped over while paging, and opening a faction still gives a dialog with no
  arrows.
- Fighters/wings and ship systems, which have no standalone dialog at all.
- Moving or highlighting the row in the grid underneath.
- Any change to what the dialogs actually show.
