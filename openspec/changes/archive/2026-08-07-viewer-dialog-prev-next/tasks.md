# Tasks

## 1. The pager widget

- [x] Create `lib/widgets/dialog_pager.dart` with `DialogPager<T>`: takes
      `items`, `startIndex` and `itemBuilder(context, item, pagerControls)`,
      holds the current index in state.
- [x] Draw `pagerControls`: chevron-left and chevron-right `IconButton`s with
      `MovingTooltipWidget.text` tooltips ("Previous (Left arrow)" /
      "Next (Right arrow)"), `onPressed: null` at the ends, and nothing at all
      when there are fewer than two items.
- [x] Handle keys with a `Focus(autofocus: true, onKeyEvent: ...)` wrapper:
      Left/Up go back, Right/Down go forward, on both `KeyDownEvent` and
      `KeyRepeatEvent` so holding the key keeps stepping. Everything else
      passes through.
- [x] In the key handler, return `ignored` when the focused widget is inside an
      editable text (`FocusManager.instance.primaryFocus?.context
      ?.findAncestorStateOfType<EditableTextState>() != null`), so arrow keys
      still move the caret in text fields and selected text. Without this the
      pager's `Focus` intercepts arrow keys before the app-root text-editing
      shortcuts see them.
- [x] Wrap the built child in `KeyedSubtree(key: ValueKey(index))` so the
      dialog's scroll view starts at the top on each move.

## 2. Ship dialog

- [x] In `ship_details_dialog.dart`, move the dialog contents into
      `buildShipDetailsDialogBody(context, ref, ship, {pagerControls})`, keeping
      the 1050 width limit inside it.
- [x] Slot `pagerControls` into the top-right corner, left of the Close icon.
- [x] Give `showShipDetailsDialog` an optional `siblings` list; wrap the body in
      `DialogPager<Ship>` starting at the ship's position (single-item list when
      `siblings` is null or doesn't contain it).

## 3. Weapon dialog

- [x] Same split into `buildWeaponDetailsDialogBody(...)` with the 600 width
      limit.
- [x] Same `pagerControls` slot and optional `siblings` on
      `showWeaponDetailsDialog`.

## 4. Hullmod dialog

- [x] Same split into `buildHullmodDetailsDialogBody(...)` with the 600 width
      limit.
- [x] Same `pagerControls` slot and optional `siblings` on
      `showHullmodDetailsDialog`.

## 5. Wire up the viewer grids

- [x] `ships_page.dart`: pass the grid's displayed order as `siblings` on row
      tap, de-duplicated by id, falling back to the plain `items` list when the
      grid controller isn't ready yet.
- [x] Same in `weapons_page.dart`.
- [x] Same in `hullmods_page.dart`.
- [x] In all three pages, assign `_gridController` only from the top grid
      (`isTop == true`). The bottom grid is disposed when the split pane turns
      off, and a controller pointing at it hands out a stale order after the
      sort changes. Add a short comment saying why.

## 6. Wire up the Codex

- [x] In `codex_detail_panel.dart`, build the pageable list from
      `codexVisibleIndexProvider`: ship, weapon and hullmod entries only, in
      list order.
- [x] Change `_dialogOpener` so those three types open one `Dialog` wrapping
      `DialogPager<CodexEntry>`, with an `itemBuilder` that switches on entry
      type and calls the matching body builder.
- [x] Leave faction entries opening `FactionProfileDialog` as they do now.

## 7. Check it

- [x] Widget test for `DialogPager` (new file in `test/widgets/`): Previous is
      disabled on the first item and Next on the last, arrow keys page in both
      directions, controls are hidden with fewer than two items, and arrow keys
      are ignored while a text field inside the dialog has focus.
- [x] `fvm flutter analyze` is clean.
- [x] Try it by hand: page through Ships with the buttons and with all four
      arrow keys; confirm the order matches the rows on screen with grouping on
      and sort reversed.
- [x] Confirm Previous is greyed out on the first item and Next on the last.
- [x] Confirm the grid behind doesn't scroll, and the dialog starts at the top
      after each move.
- [x] Confirm arrow keys still move the caret in the dialog's selectable text
      when it has focus.
- [x] Repeat the quick pass on Weapons and Hullmods, then walk a mixed run in
      the Codex (debug builds only).

## 8. Write it down

- [x] Add `DialogPager` to the common widgets list in `CLAUDE.md`.
- [x] Add a changelog line for Previous/Next in the details dialogs.
