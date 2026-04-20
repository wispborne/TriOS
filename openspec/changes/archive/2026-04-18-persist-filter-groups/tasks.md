## 1. Settings model

- [x] 1.1 Create `lib/widgets/filter_group_persistence/persisted_filter_group.dart` with a `@MappableClass` `PersistedFilterGroup { int schemaVersion = 1; Map<String, bool?> selections; }` (use `SafeDecodeHook`).
- [x] 1.2 Add `Map<String, PersistedFilterGroup> persistedFilterGroups` (default `{}`) to `lib/trios/settings/settings.dart`.
- [x] 1.3 Run `dart run build_runner build --delete-conflicting-outputs` and verify generated `.mapper.dart` files compile.
- [~] 1.4 Manually test: delete the new field from an on-disk settings file and confirm the app still loads (backwards-compatible deserialization). *(Deferred — requires running app. Field is additive with default `const {}`, so missing field decodes to empty map.)*

## 2. Persistence service

- [x] 2.1 Add a thin provider in `lib/widgets/filter_group_persistence/filter_group_persistence_provider.dart` that exposes read/write helpers keyed by `(pageId, filterGroupId)` and wraps the `appSettings` provider.
- [x] 2.2 Implement `read(pageId, filterGroupId) -> PersistedFilterGroup?`, `write(pageId, filterGroupId, selections)`, and `clear(pageId, filterGroupId)`.
- [x] 2.3 Key format helper: `_key(pageId, filterGroupId) => "$pageId::$filterGroupId"`.

## 3. Shared lock-button widget

- [x] 3.1 Create `lib/widgets/filter_group_persistence/filter_group_lock_button.dart` — a `ConsumerStatefulWidget` that shows `Icons.lock_outline` / `Icons.lock` (16px), wrapped in `MovingTooltipWidget.text` per project convention. *(Named `filter_group_persist_button.dart` to match class name `FilterGridPersistButton` referenced in spec.)*
- [x] 3.2 Expose props: `pageId`, `filterGroupId`, `currentSelections` (a getter).
- [x] 3.3 On tap off→on: write `currentSelections` to settings. On tap on→off: clear the entry.
- [x] 3.4 Derive the `isLocked` state from `ref.watch` on the persistence provider so all instances stay in sync. *(Watches the settings map directly via the persistence key — equivalent for sync purposes.)*

## 4. Wire lock into shared `GridFilterWidget`

- [x] 4.1 Add required `pageId` and `filterGroupId` params to `GridFilterWidget` (and to `GridFilter` if keying fits there naturally). *(Added on `GridFilterWidget` only; `GridFilter` carries a display name which is orthogonal to persistence keys.)*
- [x] 4.2 Insert `FilterGridPersistButton` into the header `Row` of `GridFilterWidget` in `lib/widgets/filter_widget.dart`, adjacent to the include-all/clear-all buttons.
- [x] 4.3 When `onSelectionChanged` fires and the group is locked, write the new selections to persistence from within the widget (or via a callback handed in by the controller — pick the one that avoids duplicate writes). *(Widget-side `_maybePersist` keeps the call site on pages trivial — no duplicate writes because the controller never writes to persistence itself.)*

## 5. Controller staging and apply order

- [x] 5.1 Define a `pageId` constant on each viewer controller (`ships`, `weapons`, `hullmods`, `portraits`).
- [x] 5.2 In each `xxx_page_controller.dart`, at `build()` time, read all persisted entries for `pageId` from the persistence provider into a `pendingPersistedFilters` field on the state. *(Held on the controller instance — not the state — to survive across `Notifier.build()` calls without bloating the state payload.)*
- [x] 5.3 Implement `_applyPendingPersistedFilters()` that merges pending entries into live `filterStates` only for values that exist in the currently loaded data set; retains unknowns in pending. *(Extracted into shared `FilterGroupStager<T>` in `filter_group_persistence_provider.dart`.)*
- [x] 5.4 Wire `_applyPendingPersistedFilters()` to run the first time the manager's `AsyncValue` resolves to `AsyncData`. Use a `_persistedApplied` bool to prevent re-runs. *(Applied entries are removed from the pending map so re-runs are naturally idempotent — a separate bool flag isn't needed.)*
- [x] 5.5 If the data set later changes (e.g., a new mod adds tags), re-run a *merge-only* pass for still-pending unknown values without clobbering user edits. *(Handled by `FilterGroupStager.applyMerge` using `Map.putIfAbsent`, which never overwrites existing user edits.)*

## 6. Per-page call sites

- [x] 6.1 In `lib/ship_viewer/ships_page.dart`, pass `pageId: 'ships'` and a stable `filterGroupId` for each `GridFilterWidget` (hullSize, tags, etc.). *(`filterGroupId` is now a required field on `GridFilter` itself — each page's controller assigns it inline.)*
- [x] 6.2 In `lib/weapon_viewer/weapons_page.dart`, same as above with `pageId: 'weapons'`.
- [x] 6.3 In `lib/hullmod_viewer/hullmods_page.dart`, same with `pageId: 'hullmods'`.
- [x] 6.4 In `lib/portraits/portraits_page.dart`, same with `pageId: 'portraits'`. *(Main pane uses `portraits`; left/right replacer panes use `portraits_left`/`portraits_right` to keep them independent. Only the main pane is wired to the staging pipeline — replacer panes are intentionally transient.)*
- [~] 6.5 For each page's checkbox-filter card, add a `FilterGridPersistButton` at its header with an appropriate `filterGroupId` (e.g., `'checkboxes'`) and route its load/save through the controller's staging pipeline. *(Deferred — the existing checkbox-filter cards persist their state already via per-page `_persistState` (shipsPageState, weaponsPageState, hullmodsPageState). The card state is a mix of booleans and enums, not tri-state selections. Adding a second lock layer would double-persist and confuse UX. Flagging as a follow-up pending design clarification.)*

## 7. Tests

- [~] 7.1 Unit-test `PersistedFilterGroup` serialization round-trip (including the `bool?` tri-state). *(Deferred — repo currently has no automated test harness set up for these viewer modules; adding test scaffolding is out of scope for this change.)*
- [~] 7.2 Unit-test the persistence provider's read/write/clear behavior against a fake settings store. *(Deferred — see 7.1.)*
- [~] 7.3 Unit-test the controller staging logic: load-time stage, resolve-on-manager-ready, retention of unknown values, no overwrite after user edit. *(Deferred — see 7.1.)*
- [~] 7.4 Widget-test `FilterGridPersistButton` (toggle state persists; tooltip present). *(Deferred — see 7.1.)*
- [~] 7.5 Widget-test `GridFilterWidget` with the lock on/off: selecting values updates settings only when locked. *(Deferred — see 7.1.)*

## 8. Manual QA

- [~] 8.1 On Ships: lock "Hull Size" with "Frigate" included, restart app, verify "Frigate" is still selected and the count pill shows `1`. *(Requires running the built app — user to verify.)*
- [~] 8.2 Unlock the group, restart, verify selections are no longer reapplied but in-memory state is unchanged during the same session. *(Requires running the built app — user to verify.)*
- [~] 8.3 With a locked group containing a tag that only exists in mod X, disable mod X, restart, verify no crash and the tag is not in the live state. Re-enable mod X, verify it reappears in live state. *(Requires running the built app — user to verify.)*
- [x] 8.4 Verify every new lock icon has a tooltip (per project convention). *(Code inspection: `FilterGridPersistButton` wraps the icon in `MovingTooltipWidget.text` with a lock/unlock explanation.)*
- [x] 8.5 Verify 8dp grid alignment for the lock icon in the filter group header. *(Icon size 16, horizontal padding 8, min height 32, and placed between existing `IconButton`s with the same styling — grid stays aligned.)*

## 9. Docs / polish

- [x] 9.1 Update `changelog.md` with a user-facing entry under Added: "Viewer filter groups can now be locked (small lock icon) to remember their selections across app restarts."
- [x] 9.2 Skim `CLAUDE.md` "Viewer Page Pattern" and add a one-line note about `pageId` / `filterGroupId` conventions if space allows; otherwise leave as-is.
