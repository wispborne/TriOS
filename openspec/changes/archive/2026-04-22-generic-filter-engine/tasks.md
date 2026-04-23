## 1. Engine foundation

- [x] 1.1 Create `lib/widgets/filter_engine/` directory and wire its barrel file.
- [x] 1.2 Add `FilterScope` value type (`pageId`, `scopeId`) with `keyFor(groupId)` helper producing `"pageId::scopeId::groupId"`.
- [x] 1.3 Define sealed `FilterGroup<T>` base class with `id`, `name`, `isActive`, `matches(T)`, `serialize()`, `restore(Object?)`, and `clear()`.
- [x] 1.4 Implement `ChipFilterGroup<T>` (port fields from today's `GridFilter`: `valueGetter`, `valuesGetter`, `displayNameGetter`, `sortComparator`, `useDefaultSort`, `collapsedByDefault`, `filterStates`).
- [x] 1.5 Implement the canonical chip-match algorithm from hullmods' `_applyFilters` as a method on `ChipFilterGroup.matches`, handling both single- and multi-value paths uniformly.
- [x] 1.6 Implement `BoolFilterGroup<T>` with `defaultValue`, current `value`, and `predicate: bool Function(T)` (predicate applies only when `value` is true).
- [x] 1.7 Implement `EnumFilterGroup<T, E extends Enum>` with `defaultValue`, `options`, `selected`, and `predicate: bool Function(T, E)`. Expose `optionValues: List<Enum>`, `selectedAsObject`, `setFromObject(Object?)` to avoid leaking `E` through the renderer.
- [x] 1.8 Implement `FilterField<T>` sealed base with `BoolField<T>` and `EnumField<T, E extends Enum>` variants, each carrying default/current state, predicate, and typed serialize/restore.
- [x] 1.9 Implement `CompositeFilterGroup<T>` holding an ordered `fields: List<FilterField<T>>`; `matches` is the AND of all field predicates; `isActive` is true if any field is active; `activeCount` is the count of active fields; `serialize` emits `{fieldId: nativeValue, …}`; `restore` reads by id and ignores unknowns.

## 2. Scope controller

- [x] 2.1 Implement `FilterScopeController<T>` with constructor taking `FilterScope` and `List<FilterGroup<T>>`.
- [x] 2.2 Add `applyChipFilters(Iterable<T>) -> List<T>` iterating only `ChipFilterGroup` instances.
- [x] 2.3 Add `applyNonChipFilters(Iterable<T>) -> List<T>` iterating `BoolFilterGroup`, `EnumFilterGroup`, and `CompositeFilterGroup`.
- [x] 2.4 Add `activeCount` summing each group's `activeCount`.
- [x] 2.5 Add `clearAll()` resetting every group to its default.
- [x] 2.6 Add `setChipSelections(String groupId, Map<String, bool?>)` for context-menu navigation.
- [x] 2.7 Add `loadPersisted(FilterGroupPersistence)` staging entries from settings and applying them when chip values exist in current data (re-use `FilterGroupStager`'s apply-merge semantics). For composite groups, restore directly — no staging needed, values are intrinsic.
- [x] 2.8 Add `maybePersist(String groupId)` that writes the group's serialized state if the lock for `scope::groupId` is currently on.
- [x] 2.9 Add `persistenceEnabled: bool` flag (default true) that, when false, makes `loadPersisted` and `maybePersist` no-ops (used by portraits `left`/`right` scopes).

## 3. Persistence layer changes

- [x] 3.1 Widen `PersistedFilterGroup.selections` from `Map<String, bool?>` to `Map<String, Object?>` in `lib/widgets/filter_group_persistence/persisted_filter_group.dart`; bump default `schemaVersion` to 2.
- [x] 3.2 Update `FilterGroupPersistence.keyFor` to accept `(pageId, scopeId, groupId)` and produce `"pageId::scopeId::groupId"`. Deprecate the 2-arg overload (direct call sites migrated in this change).
- [x] 3.3 Update `FilterGroupPersistence.read`/`write`/`clear`/`allForPage` signatures to include scope. `allForPage` becomes `allForScope(pageId, scopeId)`.
- [x] 3.4 On settings load, drop any `PersistedFilterGroup` entries whose `schemaVersion` is not 2 (log at info level). Implement via a mapping hook or a post-load filter pass.
- [x] 3.5 Update `FilterGroupStager` to take a `FilterScope` instead of a `pageId`, and to key staging entries by scope.
- [x] 3.6 Run `dart run build_runner build --delete-conflicting-outputs` and commit regenerated `.mapper.dart` files.

## 4. Renderer widget

- [x] 4.1 Create `FilterGroupRenderer` widget that accepts a `FilterGroup<T>`, the owning `FilterScope`, the items list (for chip value sorting/display), and an `onChanged` callback.
- [x] 4.2 Dispatch `ChipFilterGroup<T>` to the existing `GridFilterWidget`, replacing its `GridFilter` input with `ChipFilterGroup`.
- [x] 4.3 Add `_BoolRow` sub-widget rendering a `CheckboxListTile` for standalone `BoolFilterGroup` (no lock icon).
- [x] 4.4 Add `_EnumRow` sub-widget rendering a `TriOSDropdownMenu` for standalone `EnumFilterGroup` (no lock icon). Use `optionValues`/`selectedAsObject`/`setFromObject` to keep `E` opaque.
- [x] 4.5 Add `_CompositeCard` sub-widget rendering one card with header `FilterGridPersistButton` (keyed by `scope + group.id`) plus one sub-widget per field (`BoolField` → `CheckboxListTile`, `EnumField` → `TriOSDropdownMenu`). Accept optional per-field display metadata (labels, tooltips, icons) supplied by the page.
- [x] 4.6 Update `GridFilterWidget` to consume `ChipFilterGroup` and a `FilterScope` (replacing the current `pageId` string) so its internal lock persistence uses the new 3-part key.

## 5. Ships migration

- [x] 5.1 Define ships filter groups in `ShipsPageController.build` as a `FilterScopeController<Ship>` for scope `(ships, main)`. Convert existing chip filters to `ChipFilterGroup<Ship>`.
- [x] 5.2 Replace the ad-hoc checkbox card with a `CompositeFilterGroup<Ship>` id `general` containing `BoolField('showEnabled', …)` and `EnumField<SpoilerLevel>('spoiler', …)`. Hold display metadata (tooltips, labels) alongside.
- [x] 5.3 Replace `_processAllFilters`, `_applyFilters`, `_filterByEnabled`, `_filterBySpoilers` with calls into `_filters.applyNonChipFilters` and `_filters.applyChipFilters`. Preserve the `shipsBeforeGridFilter` snapshot between the two calls.
- [x] 5.4 Remove `checkboxesSnapshot`, `_maybePersistCheckboxes`, `_checkboxesLockApplied`, and the `persistence.read(kShipsPageId, 'checkboxes')` block. Persistence now lives inside the composite group.
- [x] 5.5 Remove `showEnabled` and `spoilerLevelToShow` from `ShipsPageStatePersisted`. Regenerate mappers.
- [x] 5.6 Update `toggleShowEnabled`/`setShowSpoilers` to mutate the composite group's fields via the controller and call `_filters.maybePersist('general')`.
- [x] 5.7 Update `updateFilterStates(GridFilter, Map)` to become `setChipSelections(String, Map)` and route through the scope controller.
- [x] 5.8 Update `clearAllFilters` to call `_filters.clearAll()`.
- [x] 5.9 Update `activeFilterCount` to return `_filters.activeCount`.
- [x] 5.10 Update `ships_page.dart` filter panel to iterate `_filters.groups` and render each via `FilterGroupRenderer`. Remove `_buildCheckboxFilters`.
- [x] 5.11 Verify context-menu-triggered mod filter (`AppState.viewerFilterRequest` handling in `ships_page.dart`) still works via `setChipSelections('mod', {...})`.
- [x] 5.12 Manual-verify: every existing ships filter behaves identically; lock on chip groups round-trips; locking the `general` composite persists both `showEnabled` and `spoiler`; unlocking clears only the persisted entry, not live state.

## 6. Weapons migration

- [x] 6.1 Convert weapons filters to a `FilterScopeController<Weapon>` for scope `(weapons, main)`.
- [x] 6.2 Replace the checkbox card with `CompositeFilterGroup<Weapon>` id `general` holding `BoolField('showEnabled')`, `BoolField('showHidden')`, `EnumField<WeaponSpoilerLevel>('spoiler')`.
- [x] 6.3 Replace `_processAllFilters`, `_applyFilters`, `_filterByEnabled`, `_filterByHidden`, `_filterByWeaponSpoilers` with scope-controller calls preserving current pipeline order (`enabled → hidden → spoiler → [snapshot] → chips → search`).
- [x] 6.4 Remove `checkboxesSnapshot`, `_maybePersistCheckboxes`, `_checkboxesLockApplied`, and the `persistence.read(kWeaponsPageId, 'checkboxes')` block.
- [x] 6.5 Remove `showEnabled`, `showHidden` from `WeaponsPageStatePersisted`; remove `weaponSpoilerLevel` field from `WeaponsPageState`. Regenerate mappers.
- [x] 6.6 Update toggle methods (`toggleShowEnabled`, `toggleShowHidden`, `setWeaponSpoilerLevel`) to mutate composite fields via the controller.
- [x] 6.7 Update `weapons_page.dart` filter panel to iterate `_filters.groups` via `FilterGroupRenderer`. Remove `_buildCheckboxFilters`.
- [x] 6.8 Manual-verify: all weapons filters work; lock round-trips; no double-write.

## 7. Hullmods migration

- [x] 7.1 Convert hullmods filters to a `FilterScopeController<Hullmod>` for scope `(hullmods, main)`.
- [x] 7.2 Replace the checkbox card with `CompositeFilterGroup<Hullmod>` id `general` holding `BoolField('showEnabled')`, `BoolField('showHidden')`, `EnumField<HullmodSpoilerLevel>('spoiler')`.
- [x] 7.3 Replace page's `_applyFilters` — this was the canonical implementation; delete it in favor of the engine's shared version.
- [x] 7.4 Remove page's `_processAllFilters`, `_filterByEnabled`, `_filterByHidden`, `_filterByHullmodSpoilers` in favor of scope-controller calls preserving pipeline order.
- [x] 7.5 Remove `checkboxesSnapshot`, `_maybePersistCheckboxes`, `_checkboxesLockApplied`, and the `persistence.read(kHullmodsPageId, 'checkboxes')` block.
- [x] 7.6 Remove `showEnabled` from `HullmodsPageStatePersisted`; remove `showHidden` and `hullmodSpoilerLevel` fields from `HullmodsPageState`. Regenerate mappers.
- [x] 7.7 Update toggle methods to mutate composite fields via the controller.
- [x] 7.8 Update `hullmods_page.dart` filter panel to iterate `_filters.groups` via `FilterGroupRenderer`. Remove `_buildCheckboxFilters`.
- [x] 7.9 Manual-verify: all hullmods filters work; lock round-trips; no double-write.

## 8. Portraits migration

- [x] 8.1 Build three `FilterScopeController<PortraitFilterItem>` instances on `PortraitsPageController`: `main`, `left`, `right`, with scopes `(portraits, main)`, `(portraits, left)`, `(portraits, right)`.
- [x] 8.2 Set `persistenceEnabled: false` on the `left` and `right` controllers so they never write to or read from settings.
- [x] 8.3 Define the chip groups (`mod`, `gender`) on each controller; all three share the same declarations.
- [x] 8.4 Add `CompositeFilterGroup<PortraitFilterItem>` id `general` to the `main` scope holding `BoolField('showOnlyWithMetadata')`, `BoolField('showOnlyReplaced')`, `BoolField('showOnlyEnabledMods')`. On `left`/`right` scopes the same composite appears (for consistent UI) but persistence is disabled.
- [x] 8.5 Replace `_applyGridFilters`, `_filterToOnlyEnabledMods`, and the ad-hoc metadata/replaced filtering with scope-controller calls. Preserve the unique pipeline: `enabled → metadata → chips → replaced → search` — `replaced` runs after chips via a page-local pass since it depends on `state.replacements`.
- [x] 8.6 Remove `checkboxesSnapshot`, `_maybePersistMainCheckboxes`, `_checkboxesLockApplied` from the controller.
- [x] 8.7 Remove `showOnlyWithMetadata`, `showOnlyReplaced`, `showOnlyEnabledMods` from `FilterPaneState` (they now live inside the composite group of each scope). Regenerate mappers.
- [x] 8.8 Update `portraits_page.dart`'s filter panel rendering to iterate the active pane's scope groups via `FilterGroupRenderer`, passing the pane-specific scope so the key produces `portraits::main::…` or `portraits::left::…` correctly.
- [x] 8.9 Remove `_buildCheckboxFilters` from `portraits_page.dart`.
- [x] 8.10 Manual-verify: all three panes filter correctly; lock on `main` round-trips; `left`/`right` chip selections never appear in `appSettings.persistedFilterGroups`; main-pane `showOnlyWithMetadata` and friends persist only when `general` is locked.

## 9. Cleanup and validation

- [x] 9.1 Remove now-unused imports and dead code (`GridFilter` alias if kept for transition, page-local filter helpers, stringly-typed encoding references).
- [x] 9.2 Rename the class `GridFilter` if kept only as an alias; otherwise confirm deletion and update the file header of `lib/widgets/filter_widget.dart`.
- [x] 9.3 Grep for leftover `checkboxesSnapshot`, `_maybePersist*Checkboxes`, `_checkboxesLockApplied`, `'spoilerLevelToShow='`, `'weaponSpoilerLevel='`, `'hullmodSpoilerLevel='` literal strings; confirm zero results outside archived specs.
- [x] 9.4 Grep for `filterCategories` in controller state classes; ensure each now references the scope controller's groups via a getter rather than storing a separate list.
- [x] 9.5 Run the full Dart analyzer and fix any warnings introduced by the refactor.
- [x] 9.6 Update `changelog.md` with a `Changed` entry describing the filter-state persistence behavior change (unlocked groups no longer persist) and a `Internal` entry about the engine.
- [x] 9.7 Build and smoke-test each viewer page end-to-end: toggle every filter type, lock and unlock each group, restart the app, confirm persisted state reloads and unpersisted state resets.

## 10. Docs

- [x] 10.1 Add a short section to `.claude/CLAUDE.md` under "Viewer Page Pattern" documenting how to declare filter groups on a new viewer page using `FilterScopeController` and `FilterGroupRenderer`.
- [x] 10.2 If a README exists under `lib/widgets/filter_engine/`, describe the four group variants, how to compose them, and the rule that standalone bool/enum groups don't persist (persist via composite).
