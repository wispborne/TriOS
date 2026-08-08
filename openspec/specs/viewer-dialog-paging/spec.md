# Paging through details dialogs

## What it does

The ship, weapon and hullmod details dialogs can move to the item before or
after the current one without closing.

## Behaviour

### The controls

- Each of the three dialogs shows a **Previous** and a **Next** control in its
  top-right corner, to the left of the **Close** icon.
- They are icon buttons (left and right chevrons) with tooltips reading
  "Previous (Left arrow)" and "Next (Right arrow)".
- **Previous** is disabled on the first item in the list. **Next** is disabled
  on the last. Nothing wraps around.
- When the dialog was opened with no list — a single item and nothing to page
  through — neither control is shown at all.

### The keys

- Left arrow and Up arrow do the same as Previous.
- Right arrow and Down arrow do the same as Next.
- Holding an arrow key down keeps stepping (key repeat works).
- At the ends of the list the key does nothing.
- Arrow keys are ignored while a text field or a piece of selected text inside
  the dialog has keyboard focus, so text selection still works normally.

### The order

- Opened from a viewer grid: the order is the order shown on screen — the
  grid's current sort direction, grouping and filters. It is captured when the
  dialog opens and does not change while the dialog is open.
- Items inside a collapsed group are still part of the order: paging steps
  through entries whose rows are hidden under a collapsed group header.
- Opened from the Codex: the order is the Codex's current list of visible
  entries. Paging can move between kinds, so Next on the last ship goes to the
  first weapon if that's what the Codex list shows.
- Entries with no details dialog of their own — fighters/wings, ship systems and
  factions — are skipped while paging.

### What stays put

- Moving to another item does not scroll or change the grid behind the dialog.
- The dialog's own scroll position resets to the top on each move, so a long
  ship dialog doesn't leave the user halfway down the next ship.

## How we'll know it's done

- Opening a ship from the Ships grid and pressing Right steps through ships in
  the same order as the rows below the dialog, including when the grid is
  grouped by mod and sorted descending.
- Previous is greyed out on the first row's dialog; Next is greyed out on the
  last row's dialog.
- The same works in the Weapons and Hullmods viewers.
- Opening an entry from the Codex and pressing Right walks the Codex's visible
  list, changing dialog layout when it crosses from ships to weapons to
  hullmods, and skipping wings, ship systems and factions.
- Closing and reopening the grid behind the dialog shows the same scroll
  position it had before.
