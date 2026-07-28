# Tasks

## 1. The pager widget

- [ ] Create `lib/widgets/dialog_pager.dart` with `DialogPager<T>`: takes
      `items`, `startIndex` and `itemBuilder(context, item, pagerControls)`,
      holds the current index in state.
- [ ] Draw `pagerControls`: chevron-left and chevron-right `IconButton`s with
      `MovingTooltipWidget.text` tooltips ("Previous (Left arrow)" /
      "Next (Right arrow)"), `onPressed: null` at the ends, and nothing at all
      when there are fewer than two items.
- [ ] Handle keys with a `Focus(autofocus: true, onKeyEvent: ...)` wrapper:
      Left/Up go back, Right/Down go forward, everything else passes through.
- [ ] Put a `ValueKey(index)` on the built child so the dialog's scroll view
      starts at the top on each move.

## 2. Ship dialog

- [ ] In `ship_details_dialog.dart`, move the dialog contents into
      `buildShipDetailsDialogBody(context, ref, ship, {pagerControls})`, keeping
      the 1050 width limit inside it.
- [ ] Slot `pagerControls` into the bottom button row, left of Close.
- [ ] Give `showShipDetailsDialog` an optional `siblings` list; wrap the body in
      `DialogPager<Ship>` starting at the ship's position (single-item list when
      `siblings` is null or doesn't contain it).

## 3. Weapon dialog

- [ ] Same split into `buildWeaponDetailsDialogBody(...)` with the 600 width
      limit.
- [ ] Same `pagerControls` slot and optional `siblings` on
      `showWeaponDetailsDialog`.

## 4. Hullmod dialog

- [ ] Same split into `buildHullmodDetailsDialogBody(...)` with the 600 width
      limit.
- [ ] Same `pagerControls` slot and optional `siblings` on
      `showHullmodDetailsDialog`.

## 5. Wire up the viewer grids

- [ ] `ships_page.dart`: pass the grid's displayed order as `siblings` on row
      tap, de-duplicated by id, falling back to the plain `items` list when the
      grid controller isn't ready yet.
- [ ] Same in `weapons_page.dart`.
- [ ] Same in `hullmods_page.dart`.
- [ ] Add a short comment noting that both split-pane grids share one sort, so
      one controller is enough.

## 6. Wire up the Codex

- [ ] In `codex_detail_panel.dart`, build the pageable list from
      `codexVisibleIndexProvider`: ship, weapon and hullmod entries only, in
      list order.
- [ ] Change `_dialogOpener` so those three types open one `Dialog` wrapping
      `DialogPager<CodexEntry>`, with an `itemBuilder` that switches on entry
      type and calls the matching body builder.
- [ ] Leave faction entries opening `FactionProfileDialog` as they do now.

## 7. Check it

- [ ] `fvm flutter analyze` is clean.
- [ ] Try it by hand: page through Ships with the buttons and with all four
      arrow keys; confirm the order matches the rows on screen with grouping on
      and sort reversed.
- [ ] Confirm Previous is greyed out on the first item and Next on the last.
- [ ] Confirm the grid behind doesn't scroll, and the dialog starts at the top
      after each move.
- [ ] Confirm arrow keys still move the caret in the dialog's selectable text
      when it has focus.
- [ ] Repeat the quick pass on Weapons and Hullmods, then walk a mixed run in
      the Codex (debug builds only).

## 8. Write it down

- [ ] Add `DialogPager` to the common widgets list in `CLAUDE.md`.
- [ ] Add a changelog line for Previous/Next in the details dialogs.
