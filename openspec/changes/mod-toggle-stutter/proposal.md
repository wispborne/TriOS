# Proposal: Fix mod-toggle UI stutter after visiting Viewer pages

## Problem

Toggling a mod (enable/disable) causes noticeable UI stutter — but only after the user has visited Viewer pages (Ships, Weapons, Hullmods). On a fresh launch the toggle is smooth.

The root cause is a cascade of synchronous main-thread work triggered by the mod state change:

1. **All three viewer controllers rebuild simultaneously.** Each controller (`ShipsPageController`, `WeaponsPageController`, `HullmodsPageController`) calls `ref.watch(AppState.mods)`. When any mod is toggled, all three rebuild at once — even if the user is on a completely different tab.

2. **Each rebuild does O(N) work.** The controller `build()` calls `_updateSearchIndices(allItems)` and `_processAllFilters(state, mods)` every time, even when the underlying item lists haven't changed (only the mod enable state changed).

3. **Pages stay alive via `AutomaticKeepAliveClientMixin`.** Viewer pages aren't disposed when the user navigates away, so all three controllers remain active and watching providers.

4. **`smolIds` provider creates a new `List` on every `modVariants` change.** The comment says it only emits on add/remove, but Dart's `List` uses reference equality, so Riverpod treats every recomputation as a change — even when the actual smolIds are identical. This triggers the dirty flag in all three managers unnecessarily.

## Proposed solution

Reduce the amount of work that runs on the main thread when a mod is toggled, by:

- Skipping search index rebuilds when the item list reference hasn't changed
- Using `DeepCollectionEquality` (or equivalent) on `smolIds` so it only notifies when the list content actually changes
- Making viewer controllers selectively watch mod enable state only when their "Only Enabled Mods" filter is active

## Scope

- Viewer page controllers (ships, weapons, hullmods)
- `AppState.smolIds` provider
- `CachedStreamListNotifier` is NOT in scope — it already handles caching well

## Non-goals

- Moving CSV parsing to isolates (the managers' full rebuild isn't the bottleneck here — it's the controller cascade)
- Changing the `AutomaticKeepAliveClientMixin` behavior (users expect instant tab switching)
- Rearchitecting the provider dependency graph
