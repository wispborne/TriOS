# Design

## The shape of it

Right now each `show*DetailsDialog()` function calls `showDialog()` and builds
the whole thing — outer `Dialog`, size limit, scroll view, content, button row —
in one closure over a single item.

We split that in two:

1. A **body builder** per type: given one item (and the shared button-row extras),
   return the dialog's contents. This is nearly all of the existing code, just
   moved into a function that takes the item as a parameter.
2. A **pager** that owns the current position in a list, handles the keys, draws
   the Previous/Next buttons, and calls the body builder for whichever item is
   current.

`showDialog()` is called once. Moving to another item is a `setState` inside the
pager, not a new route. That's what keeps the grid behind untouched and makes
the transition instant.

## New file: `lib/widgets/dialog_pager.dart`

```dart
class DialogPager<T> extends StatefulWidget {
  final List<T> items;
  final int startIndex;
  /// Builds the dialog's contents for [item]. [pagerControls] is the
  /// Previous/Next button pair, to be placed in the bottom button row.
  final Widget Function(BuildContext context, T item, Widget pagerControls)
      itemBuilder;
}
```

State: `int _index`.

- Wraps its child in `Focus(autofocus: true, onKeyEvent: ...)`. On
  `KeyDownEvent` or `KeyRepeatEvent` (so holding the key keeps stepping) for
  `arrowLeft`/`arrowUp` it steps back, `arrowRight`/`arrowDown` steps forward,
  and returns `KeyEventResult.handled`; anything else returns `ignored`.
- One catch: key events travel from the focused widget *up* through its
  ancestors, and the arrow-key handling for text editing lives at the app root
  (`DefaultTextEditingShortcuts`), above the dialog. So without a guard this
  `Focus` would steal arrow keys from a focused text field or selected text.
  The handler returns `ignored` whenever the focused widget is inside an
  editable text:
  `FocusManager.instance.primaryFocus?.context?.findAncestorStateOfType<EditableTextState>() != null`.
  Don't guard on "the pager's own node has focus" instead — clicking Previous
  or Next moves focus to that button, and arrow keys would then stop paging and
  start moving focus between buttons.
- `pagerControls` is a `Row` of two `IconButton`s
  (`Icons.chevron_left` / `Icons.chevron_right`), each wrapped in
  `MovingTooltipWidget.text` per the project's tooltip convention. `onPressed`
  is null at the ends, which is what greys them out. If `items.length < 2` the
  row is an empty `SizedBox.shrink()`.
- The scroll reset comes free: the pager wraps the widget returned by
  `itemBuilder` in `KeyedSubtree(key: ValueKey(_index))`, so the
  `SingleChildScrollView` inside is a new element each move and starts at the
  top.

`DialogPager` is generic and knows nothing about ships. The Codex case (mixed
types) uses `DialogPager<CodexEntry>` with an `itemBuilder` that switches on the
entry type — that's why the pager is generic over `T` rather than tied to one
model.

## Changes to the three dialog files

Same pattern in `ship_details_dialog.dart`, `weapon_details_dialog.dart` and
`hullmod_details_dialog.dart`:

- Add a public body builder, e.g.

  ```dart
  Widget buildShipDetailsDialogBody(
    BuildContext context,
    WidgetRef ref,
    Ship ship, {
    Widget pagerControls = const SizedBox.shrink(),
  });
  ```

  It returns the current `ConstrainedBox` → `Padding` → `SingleChildScrollView`
  → `Column` tree. The only edit inside is the header: `pagerControls` goes in
  the top-right corner, just left of the Close icon. For the ship and weapon
  dialogs that corner lives in their private info-pane builder, which takes
  `pagerControls` as an extra parameter.

  Each type keeps its own width limit inside its own builder (ship 1050, weapon
  and hullmod 600), so a mixed-type Codex pager resizes naturally as it moves.

- Change the show function to take an optional list:

  ```dart
  void showShipDetailsDialog(
    BuildContext context,
    WidgetRef ref,
    Ship ship, {
    List<Ship>? siblings,
  });
  ```

  It finds `ship`'s position in `siblings` by id (falling back to a
  single-item list if it isn't there or `siblings` is null) and returns
  `Dialog(child: DialogPager<Ship>(...))`.

  Keeping `siblings` optional means every existing call site still compiles and
  behaves exactly as before.

## Getting the displayed order out of the grids

`WispGridController.lastDisplayedItemsReadonly` already exposes the on-screen
order after sorting and grouping. Each viewer page already keeps a
`_gridController` field, set in `onLoaded`.

In `ships_page.dart`, `weapons_page.dart` and `hullmods_page.dart` the row
`onTap` becomes:

```dart
onTap: () => showShipDetailsDialog(
  context,
  ref,
  item,
  siblings: _gridController?.lastDisplayedItemsReadonly ?? items,
),
```

Three things to handle:

- **Duplicates.** A grouping that returns several sort values for one item
  (`getAllGroupSortValues`) puts that item in the displayed list more than once.
  The three viewer grids' groupings all return a single value today, so this
  can't happen yet — but de-duplicate by id anyway; it's cheap insurance.
- **Split panes.** These pages render two grids (top and bottom) that share one
  grid state and one item list, so both display the same order. But both call
  `onLoaded` and the last one wins — the bottom grid. Turning the split pane
  off disposes the bottom grid, leaving `_gridController` pointing at a dead
  grid whose order stops updating when the sort changes. Fix: assign
  `_gridController` only from the top grid (`isTop == true`), which always
  exists. (This also fixes the same latent staleness in the CSV export, which
  uses the same field.)
- **Collapsed groups.** The grid builds its displayed-items list before group
  collapse is applied, so paging steps through items whose rows are hidden
  inside a collapsed group. We accept that: the order is still the displayed
  order, and skipping them would mean exposing collapse state out of the grid.
  The spec says so explicitly.

## The Codex

`codex_detail_panel.dart` already reads `codexVisibleIndexProvider` for the
visible entry list. `_dialogOpener` becomes: build a pageable list from
`visible` — keep only `ShipCodexEntry`, `WeaponCodexEntry` and
`HullmodCodexEntry`, in list order — find the current entry in it, and open a
single `Dialog` wrapping `DialogPager<CodexEntry>` whose `itemBuilder` switches
on type and calls the matching body builder. The ship dialog uses
`insetPadding: 32` and the other two use 16; the codex's single `Dialog` has to
pick one, and uses 16.

Faction entries keep their existing `FactionProfileDialog` with no arrows, and
are simply absent from the pageable list. Wings and ship systems already return
null (no dialog).

## Files touched

| File | Change |
| --- | --- |
| `lib/widgets/dialog_pager.dart` | New. The pager widget. |
| `lib/ship_viewer/widgets/ship_details_dialog.dart` | Split body out; optional `siblings`. |
| `lib/weapon_viewer/widgets/weapon_details_dialog.dart` | Same. |
| `lib/hullmod_viewer/widgets/hullmod_details_dialog.dart` | Same. |
| `lib/ship_viewer/ships_page.dart` | Pass displayed order on row tap. |
| `lib/weapon_viewer/weapons_page.dart` | Same. |
| `lib/hullmod_viewer/hullmods_page.dart` | Same. |
| `lib/codex/widgets/codex_detail_panel.dart` | Mixed-type pager for codex entries. |
| `CLAUDE.md` | Add `DialogPager` to the common widgets list. |
| `changelog.md` | One line for the release notes. |

No model changes, so no `build_runner` run and no settings/serialization work.

## Decisions and the alternatives we passed on

- **One dialog that swaps contents, not a stack of pushed routes.** Pushing a
  new dialog per step would build up a back stack and flash on every move.
- **Capture the order when the dialog opens.** Watching the grid live would mean
  the list shifting under the user if a background refresh lands mid-look.
- **No wrapping at the ends**, per the user's call. Greying the button out is
  the clearest signal that you've reached the end.
- **Plain `Focus`, not `CallbackShortcuts` at the app level.** Keeps the key
  handling inside the dialog. Focused text fields win because the handler
  checks for an editable text before acting — not because of where the `Focus`
  sits in the tree (ancestor handlers run before the root-level text-editing
  shortcuts, so the check is required).
