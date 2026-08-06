# Advanced viewer filters — design

## Overview

The change adds six things to the existing filter panel: a per-group include
logic mode, numeric range filter groups, a search box for chip names, an
expand-to-dialog button, collapsed group badges, and a shift-click-to-solo
shortcut. An "Advanced mode" toggle controls which of these are visible.

All changes live in the shared filter engine and widget layer. Ships and
weapons pages adopt them; other viewers can opt in later with no extra work.

## Key files

| Area | Files |
|---|---|
| Filter data model | `lib/widgets/filter_engine/filter_group.dart` |
| Filter controller | `lib/widgets/filter_engine/filter_scope_controller.dart` |
| Filter group renderer | `lib/widgets/filter_engine/filter_group_renderer.dart` |
| Chip filter widget | `lib/widgets/filter_widget.dart` |
| Filter panel shell | `lib/widgets/filter_widget.dart` (`FiltersPanel`) |
| Ships controller | `lib/ship_viewer/ships_page_controller.dart` |
| Ships page | `lib/ship_viewer/ships_page.dart` |
| Weapons controller | `lib/weapon_viewer/weapons_page_controller.dart` |
| Weapons page | `lib/weapon_viewer/weapons_page.dart` |
| Persisted state | `lib/trios/settings/settings.dart` |

## 1. Per-group include logic

### Model

Add a `logicMode` field to `ChipFilterGroup`:

```dart
enum ChipLogicMode { any, all }

class ChipFilterGroup<T> extends FilterGroup<T> {
  ChipLogicMode logicMode = ChipLogicMode.any;
  // ...existing fields...
}
```

### Matching

`ChipFilterGroup.matches` currently does:
1. If any value is excluded → reject.
2. If any value is included → item must have at least one included value.
3. Otherwise → accept.

Step 2 changes to respect `logicMode`:

```dart
if (hasIncluded) {
  if (logicMode == ChipLogicMode.all) {
    return includedValues.every((v) => values.contains(v));
  }
  return values.any((v) => includedValues.contains(v));
}
```

Exclude logic stays as-is (any excluded value vetoes).

### Serialization

`serialize()` adds `'_logic': logicMode.name` to the map, but only when the
mode isn't the default, so saved state for existing groups doesn't change.
`restore()` reads it back and falls back to `any` for unknown values. The chip
loading path in `FilterScopeController.loadPersisted` reads it too, since chip
values are staged rather than restored directly.

### UI

`GridFilterWidget` gets a logic-mode button in the group header, between the
group name and the include-all/clear-all buttons. The button shows "any" or
"all" as text and cycles on click.

Visibility rule: the button is shown when Advanced mode is on, **or** when
`logicMode != ChipLogicMode.any` (non-default stays visible).

## 2. Range filter group

### Model

New sealed subtype in `filter_group.dart`:

```dart
class RangeFilterGroup<T> extends FilterGroup<T> {
  final String id;
  final String name;
  final num Function(T) valueGetter;
  final String? suffix;
  final bool allowGreater;  // top handle = "and above"

  num min;
  num max;
  num curMin;
  num curMax;
}
```

`min`/`max` are the data range (computed from items). `curMin`/`curMax` are the
user's selection. `isActive` returns `curMin > min || curMax < max`.

### Matching

```dart
bool matches(T item) {
  final v = valueGetter(item);
  if (v < curMin) return false;
  if (allowGreater && curMax >= max) return true;
  return v <= curMax;
}
```

### Serialization

Stores `{'min': curMin, 'max': curMax}`. Restore clamps to the current data
range.

### UI

New widget: `RangeFilterWidget` (`lib/widgets/range_filter_widget.dart`),
built on Flutter's `RangeSlider`. Shows the selected range as text in the
header. Handles snap to values that exist in the data: the slider itself runs
free and `RangeFilterGroup.snapTo` rounds to the nearest real value on
release. (`RangeSlider.divisions` would draw a tick per stop, which turns into
a solid line when a stat has hundreds of distinct values.)

The `FilterGroupRenderer` dispatches `RangeFilterGroup` to this widget.

Visibility: always shown. Range sliders are self-explanatory — hiding them
behind a toggle hurts discoverability for no gain.

### Data range updates

When the item list changes (new mods loaded), `min`/`max` may shift. The
controller calls a new `updateRange(Iterable<T> items)` method on each
`RangeFilterGroup` that recomputes `min`/`max` and clamps `curMin`/`curMax`.

## 3. Advanced mode toggle

### What it controls

Advanced mode only governs one thing: the per-group logic-mode button. Range
sliders, search, badges, shift-click, and expand-to-dialog are always
available — they're all self-explanatory. The logic button ("any" / "all") is
the only control that raises a question for casual users.

The non-default escape hatch still applies: if a group's logic mode is set to
"all", its button stays visible even with Advanced off.

### State

Add `advancedFilters` (bool, default false) to each page's persisted state
class. Ships: `ShipsPageStatePersisted`. Weapons: `WeaponsPageStatePersisted`.

The controller exposes a `toggleAdvancedMode()` method that flips the flag
and persists.

### UI

A checkbox or switch in the `FiltersPanel` header row, after the "Filters"
label and before the expand button. Label: "Advanced".

When off:
- Logic-mode buttons are hidden (unless non-default).

When on:
- Logic-mode buttons appear on every chip group.

`FiltersPanel` gets a new `isAdvanced` parameter and an `onAdvancedChanged`
callback.

The pages build their filter group widgets *before* the panel exists (they
pass a `List<Widget>`), so `isAdvanced` can't be handed to them as a
constructor argument. Instead `FiltersPanel` wraps the group column in a
`FilterPanelOptions` inherited widget carrying `isAdvanced` and the panel's
search term. `FilterGroupRenderer` and `GridFilterWidget` read it from the
build context. Pages only pass the flag to `FiltersPanel`, and panels that
don't opt in behave exactly as before.

`FiltersPanel`'s group column no longer sets `spacing: 4`. Groups hidden by
the search box return an empty widget, and the spacing would leave a gap for
each one. Each group card already carries its own margin.

## 4. Search inside the filter panel

### UI

A `TextField` at the top of `FiltersPanel`, below the header and above the
groups. Debounced at 150ms.

### Behavior

`FiltersPanel` passes the search term down. Each `GridFilterWidget` filters its
chips: a chip is hidden if neither its display name nor its raw value contains
the search term (case-insensitive). If a group has zero visible chips, the
entire group is hidden.

Range filter groups match against their name only — they have no chips.

The existing include-all and clear-all buttons respect the search: they only
affect visible (matching) chips. A new "Exclude all" button works the same way.

### Implementation

`GridFilterWidget` already computes `_uniqueValues`. The search just adds a
display filter on top. No changes to the data model — this is pure UI.

## 5. Expand to dialog

### UI

A button in the `FiltersPanel` header (expand icon). On click, opens a
`showDialog` with a wider container holding the same `FiltersPanel` widget.

The dialog version uses the same controller, same state, same `onChanged`
callbacks. Changes are live — the grid behind the dialog updates immediately.
No Save/Cancel buttons; close the dialog when done.

### Implementation

`showFilterPanelDialog(context, panelBuilder)` in `filter_widget.dart` opens a
`ConstrainedBox` (max 640×800) holding whatever `panelBuilder` returns, plus a
"Done" button. The page supplies the builder and wraps it in a `Consumer` that
watches its own controller, then calls its existing `buildFilterPanel` with
`inDialog: true` (wider, no expand button, "hide" closes the dialog).

The builder has to rebuild from live state. Filter groups are mutated in
place, so if the dialog reused the widget objects the page already built,
Flutter would skip the rebuild and the dialog would show stale chips.

The dialog closes via the "Done" button or clicking outside.

## 6. Collapsible group badges and shift-click

### Badges

`GridFilterWidget` already supports collapsing, and the include/exclude count
badges already live in the header row, which is drawn whether the group is
open or shut.

The header did need a rework for space, though. The panel is 300 wide, every
`IconButton` was claiming a 48px tap target, and a `Spacer` was splitting the
leftover room with the group name — so with the new buttons in place, "Weapon
Slot Type" rendered as "W…". Fixed by:

- Buttons shrunk to 24×28 (`tapTargetSize: shrinkWrap`, no padding), including
  the shared lock button.
- The name is `Expanded` with no `Spacer` after it, so it takes everything the
  buttons don't need.
- Open group: name, any/all, the three chip buttons, lock — no counts, since
  the chips themselves show what's picked. Name gets ~130px.
- Shut group: name, any/all, counts, lock — no chip buttons, since acting on
  chips nobody can see is a trap. Name gets ~164px.

Both fit the longest group names on the ships and weapons pages.

### Shift-click to solo

In `GridFilterWidget._toggleValue`, check `HardwareKeyboard.instance` for
shift. If shift is held:
1. Clear all chips in the group.
2. Set the clicked chip to include.

Single change in one method.

### "Exclude all" button

Add an "Exclude all" icon button next to the existing include-all and clear-all
buttons. Sets all visible chips (respecting search) to exclude. This rounds out
the button set: include all, clear all, exclude all.

## Pipeline integration

`FilterScopeController` currently has `applyChipFilters` and
`applyNonChipFilters`. Range filters are a new group type, so they need to be
applied somewhere. `applyNonChipFilters` already iterates non-chip groups and
calls `matches`, so the ships page picks them up with no change.

The weapons page doesn't call `applyNonChipFilters` — it applies its
enabled/hidden/spoiler rules by hand — so it gets a new
`applyRangeFilters(items)` on the controller, which runs only the range
groups.

Two more controller helpers: `updateRanges(items)` refreshes every range
group's min/max (called with the full item list when it changes, so slider
ends don't move as you filter), and `clearRanges()` resets them.

The page controllers add `RangeFilterGroup` instances to their `groups` list
alongside the existing chip and composite groups.

## What doesn't change

- `FilterScopeController`'s `applyChipFilters` / `applyNonChipFilters` split.
- The search DSL and `SmartSearchBar`. Range sliders and the DSL are
  independent paths into the same filter pipeline.
- `FilterGroupPersistence` and `FilterGridPersistButton`. Range and chip-logic
  state serializes through the existing `serialize()`/`restore()` contract.
- The sealed `FilterGroup` hierarchy structure. `RangeFilterGroup` is a new
  subtype added to the sealed family; existing subtypes are unchanged.
