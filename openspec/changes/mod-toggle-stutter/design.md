# Design: Fix mod-toggle UI stutter

## Analysis

When a mod is toggled, this chain fires:

```
changeActiveModVariant()
  → reloadModVariants()
    → AppState.modVariants updates
      → AppState.mods recomputes (new Mod list with updated enable state)
      → AppState.smolIds recomputes (new List, same content)
        → 3× manager dirty flag set (unnecessary — smolIds didn't actually change)
      → 3× controller build() re-runs (watches AppState.mods)
        → 3× _updateSearchIndices() — O(N) per viewer, even though items are unchanged
        → 3× _processAllFilters() — O(N) per viewer, evaluating all predicates
```

All of this is synchronous on the main isolate. With hundreds of ships/weapons/hullmods loaded, the combined work blocks rendering for multiple frames.

## Changes

### 1. Fix `smolIds` false positives

**File:** `lib/trios/app_state.dart` (line 140–143)

The `smolIds` provider returns a new `List<String>` every time `modVariants` changes, even when the actual IDs are the same. Since `List` uses reference equality, Riverpod always considers it changed.

**Fix:** Use `collection`'s `ListEquality` or a manual deep-equality check so the provider only notifies downstream listeners when the smolId set actually changes (i.e., a mod was added or removed from disk).

```dart
static final smolIds = Provider<List<String>>((ref) {
  final mods = ref.watch(AppState.modVariants).value ?? [];
  return mods.map((mod) => mod.smolId).toList()..sort();
}, dependencies: [AppState.modVariants]);
```

Options:
- **A) Wrap with `select`**: Not directly applicable since this is a derived Provider, not a watch site.
- **B) Cache previous value and compare**: Store the previous list and return the same reference if content is equal. Use a simple loop comparison since the list is sorted.

Going with **B** — add a top-level `_previousSmolIds` or convert to a `Notifier` that can compare before emitting.

### 2. Memoize search index rebuild in controllers

**Files:**
- `lib/ship_viewer/ships_page_controller.dart` (line 208)
- `lib/weapon_viewer/weapons_page_controller.dart`
- `lib/hullmod_viewer/hullmods_page_controller.dart`

Each controller calls `_updateSearchIndices(allItems)` on every `build()`. When only mod enable state changed, `allItems` is the exact same list reference (the manager stream hasn't re-emitted).

**Fix:** Cache the search indices keyed on the item list's identity. If `identical(allItems, _previousItems)`, return the cached indices.

```dart
Map<String, List<String>> _cachedSearchIndices = {};
List<T>? _searchIndexSource;

Map<String, List<String>> _updateSearchIndicesIfNeeded(List<T> items) {
  if (identical(items, _searchIndexSource)) return _cachedSearchIndices;
  _searchIndexSource = items;
  _cachedSearchIndices = _updateSearchIndices(items);
  return _cachedSearchIndices;
}
```

### 3. Skip filter recomputation when mod state is irrelevant

**Files:** Same three controllers.

`_processAllFilters()` evaluates every filter predicate against every item. The "Only Enabled Mods" filter is the only one that depends on `AppState.mods`. If it's in the indifferent state (`null`), the entire filter pass produces the same result regardless of which mods are enabled.

**Fix:** Track whether `mods` actually changed vs other watched values. If only `mods` changed and no active filter depends on mod enable state, return the previous state without recomputing filters.

Implementation: compare the `mods` reference to the previous one. If it changed but the item lists and filter config haven't, check whether any active filter reads mod state. The "Only Enabled Mods" BoolField has id `'showEnabled'` — if its value is `null` (indifferent), skip the rebuild.

Simpler alternative: just check if `mods` is the only thing that changed and the filter isn't active, then early-return `stateOrNull` with just the updated `isLoading` field.

## Files changed

| File | Change |
|------|--------|
| `lib/trios/app_state.dart` | Fix `smolIds` to use content equality |
| `lib/ship_viewer/ships_page_controller.dart` | Memoize search indices; skip filter recomputation when mod state is irrelevant |
| `lib/weapon_viewer/weapons_page_controller.dart` | Same |
| `lib/hullmod_viewer/hullmods_page_controller.dart` | Same |

## Risks

- **Stale filter results**: If the memoization check is wrong, the "Only Enabled Mods" filter could show stale results. Mitigated by only skipping when the filter is provably inactive.
- **Identity check fragility**: `identical()` depends on Riverpod not creating new list wrappers. The stream-based managers yield the same list objects across re-emissions, so this should be safe.
