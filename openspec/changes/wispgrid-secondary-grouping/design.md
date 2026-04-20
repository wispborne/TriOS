## Context

`WispGrid` supports one grouping dimension at a time via `WispGridState.groupingSetting.currentGroupedByKey`. The build pipeline produces `Map<Comparable?, List<T>>` keyed by group sort value, emits a header row per entry, and flattens into a `CustomScrollView`. Drag-and-drop, overlays (VRAM sum), context menus, CSV export, and collapse-state are all wired against that single-dimension model.

Users commonly want Category → Enabled/Disabled. Today that requires toggling the active grouping back and forth. A second level should slot in without disturbing single-level usage.

## Goals / Non-Goals

**Goals**
- Optional secondary grouping with near-zero impact on single-level code paths.
- Persisted (via settings) alongside primary.
- Keeps existing D&D, overlay, and context-menu semantics intact per grouping.
- Works for every existing viewer page that uses `WispGrid` without per-page changes.

**Non-Goals**
- Three or more levels of grouping. Deferred until there's a real use case — if ever needed, the same nullable-field pattern can extend (or the structure can be generalized to a list at that point).
- Per-level header-style customization. Secondary is fixed to `small`.
- Secondary sort-direction toggle.
- Per-level D&D coordination (e.g. "move across both dimensions at once"). The aim-at-the-level rule covers the stated use case.
- Opt-out flag per-page. All grids using `WispGrid` inherit the menu.

## Decisions

### Data model: nullable field, not a list

```dart
@MappableClass()
class GroupingSetting {
  final String currentGroupedByKey;
  final String? secondaryGroupedByKey;   // NEW — null = single-level
  final bool isSortDescending;
  final GroupHeaderStyle headerStyle;
  // no isSecondarySortDescending for now
}
```

A list-of-`GroupingLevel` model would be more future-proof but requires a settings migration and a larger refactor. A nullable sibling field is a one-line mappable addition. We can always generalize later — `secondaryGroupedByKey == null` would translate cleanly to a one-element list, and a third level only becomes interesting if we first see sustained demand for two.

### Build-pipeline shape

Today (simplified from `wisp_grid.dart:253-272`):

```
sortedItems → grouped: Map<Comparable?, List<T>> → sorted entries → [header + rows]
```

With secondary set:

```
sortedItems →
  grouped: Map<Comparable?, Map<Comparable?, List<T>>> →
  sortedPrimaryEntries →
    for each primary entry:
      [primary header, for each secondary entry: [secondary header, ...rows]]
```

The inner secondary map is built using the secondary grouping's `getAllGroupSortValues` in the exact same shape as the current outer map. Multi-group items fan out independently at each level.

Secondary sort order is the grouping's natural ascending order (the same as today's single-level `!isSortDescending` path). Primary keeps its existing `isSortDescending` control.

### Rendering: reuse `WispGridGroupRowView`

Both primary and secondary headers are rendered through the same `WispGridGroupRowView` widget. The difference is:
- Primary: `widget.gridState.groupingSetting?.headerStyle` (as today).
- Secondary: style forced to `GroupHeaderStyle.small`, regardless of user preference.

The cleanest way to express this is to pass an explicit `headerStyle` override into `WispGridGroupRowView`, defaulting to the current (null → use `gridState`), and pass `.small` for secondary headers. This avoids leaking "is-primary-vs-secondary" knowledge into the row widget.

Overlays render on both. The existing `overlayWidget(…)` hook on `WispGridGroup` is called identically for both headers. `itemsInGroup` passed to secondary is the inner bucket (already correct for VRAM-sum semantics — a secondary header under "Category: Faction Mods" → "Enabled" gets the enabled-Faction items). Visual crowding is a risk, but users asked for them everywhere; revisit if feedback says otherwise.

### Collapse state key

Current: `Map<Object?, bool>` keyed by `groupSortValue`.

Extend to a compound key:

```dart
class _CollapseKey {
  final Comparable? primary;
  final Comparable? secondary;  // null when this is the primary header
  // equals/hashCode on (primary, secondary)
}
```

Collapsing a primary short-circuits the inner loop — its secondaries and rows are not emitted. The compound key survives restart-free (collapse state is in-memory only today; we don't plan to persist it here either).

### Drag-and-drop targeting

Existing rule: each group's `supportsDragAndDrop` flag wraps its header in a `DragTarget`, and dropping calls `grouping.onItemsDropped(droppedKeys, targetGroupItems, ref)`.

With two levels, each header (primary and secondary) wraps in a DragTarget for its own grouping. Dropping on a secondary "Enabled" header fires `EnabledStateModGridGroup.onItemsDropped` (a no-op today, as enabled-state grouping doesn't support D&D). Dropping on a primary "Category: Foo" header fires `CategoryModGridGroup.onItemsDropped` exactly as today.

The per-row `DragTarget` for reorder/move stays attached to the grouping whose D&D capability is active. When both primary and secondary groupings support D&D, the row target defaults to the *primary* grouping (same as today's single-level behavior where the only grouping is the primary one). This keeps the current mod-manager UX: dragging a mod row targets its category.

### Context menu: sibling submenus

`wispgrid_group_row.dart:386-412` already builds a "Group By" submenu. Add a sibling "Then By" submenu right after. Visibility rules:

- `widget.groups.length <= 1` → no "Then By".
- Candidate list for "Then By" = `widget.groups` minus the current primary pick, plus a "None" item. If this list would be just `[None]` (i.e. only two groupings exist and primary already claims one), hide the submenu. With `groups.length <= 1` already excluded, this reduces to: hide when `groups.length == 1 + (primary exists)` i.e. two groupings where one is primary.

Selection of the same key as the primary is prevented at the UI level (excluded from the list). If a persisted secondary somehow equals the persisted primary (e.g. future code edit), the build loop treats secondary as `None` (ignore it) rather than crashing.

### CSV export

`WispGridCsvExport.toCsv` iterates `_lastDisplayedItemsInGroups`. We extend the storage to `List<MapEntry<WispGridGroup<T>?, List<MapEntry<WispGridGroup<T>?, List<T>>>>>` or a small typed class — something like:

```dart
class _RenderedGroup<T> {
  final WispGridGroup<T>? grouping;
  final String? displayName;
  final List<_RenderedSubgroup<T>> subgroups;  // length 1 if no secondary
}
class _RenderedSubgroup<T> {
  final WispGridGroup<T>? grouping;
  final String? displayName;
  final List<T> items;
}
```

CSV becomes:

```
# Group: Faction Mods
## Subgroup: Enabled
... rows ...
## Subgroup: Disabled
... rows ...
# Group: Utility
## Subgroup: Enabled
... rows ...
```

When secondary is `null`, a single synthetic subgroup holds the items and no `## Subgroup:` line is emitted (preserves current output).

### Persistence

`GroupingSetting` is `@MappableClass` and persisted through `WispGridState` on `appSettings`. Adding a nullable `secondaryGroupedByKey: String?` is a safe schema addition — dart_mappable handles missing fields as `null` when the constructor parameter is nullable. No migration. No version bump.

### `itemExtent` / variable heights

`_buildItemSliver` already handles variable header heights via `itemExtentBuilder`. Secondary headers are always `small` (28.0). `_isGroupHeader` recognises any `WispGridGroupRowView` regardless of level, so the current logic works. No changes needed beyond passing the right `headerStyle`.

## Risks / Trade-offs

- **Visual noise from double overlays.** Users asked for overlays on all headers; if VRAM sums become distracting under deep categories, revisit — possibly a per-grouping opt-out on `WispGridGroup` later. Not gating the change.
- **Other viewer pages inherit the new menu entry.** Ships/weapons/hullmods/portraits register a smaller group list (mostly one or two entries). With the `<= 1` rule, many won't show "Then By" at all. Confirm during implementation that grids with 2+ groupings (mods page is the main one) read correctly; no per-page opt-out planned.
- **Drag targets stacking.** A secondary header sits under a primary header; its DragTarget must not eat events meant for the primary (or vice versa). With normal Flutter hit-testing and the current row-by-row sliver structure, each header is a separate widget with its own bounds — no overlap. Verify during implementation.
- **Nullable-field model's upper bound.** If three levels ever becomes desirable, we'll refactor `GroupingSetting` to a list at that point. The single-nullable-field model is an explicit YAGNI bet.

## Migration plan

No schema migration required. In-flight changes to `GroupingSetting` appear only as a new nullable field; existing users load with `secondaryGroupedByKey == null` and see zero behavior change.

## Open Questions

None remaining after the explore-mode discussion. All four user decisions are captured:
- Overlays on all headers.
- Secondary style fixed to `small`.
- "Group By" and "Then By" as sibling submenus.
- Hide "Then By" when list would be trivially empty (≤1 total groupings, or only "None" left after excluding primary).
- No secondary sort toggle.
