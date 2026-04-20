## Context

Four viewer pages (ships, weapons, hullmods, portraits) each hand-roll the same filter machinery. An audit of `lib/ship_viewer/ships_page_controller.dart`, `lib/weapon_viewer/weapons_page_controller.dart`, `lib/hullmod_viewer/hullmods_page_controller.dart`, and `lib/portraits/portraits_page_controller.dart` surfaced the concrete duplication and several quirks that naïve abstraction would miss:

- **Three parallel filter scopes on a single page.** Portraits hosts `main`, `left`, and `right` panes, each with its own `GridFilter` list and pane state. Only `main` persists; the others are transient. Today this is keyed via ad-hoc page-id suffixes (`'${kPortraitsPageId}_left'`) at render time — a scope concept is missing from the model.
- **Pipeline ordering differs by page.** Ships runs `enabled → spoilers → [snapshot] → chips → search`; weapons/hullmods insert a `hidden` filter; portraits runs `enabled → metadata → chips → replaced → search` (with `replaced` *after* chips). A fixed engine pipeline would force incorrect behavior on at least one page.
- **Chip-apply algorithm has drifted.** Ships/weapons use one branch shape for `valuesGetter`; hullmods uses a cleaner branch that treats both `valueGetter` and `valuesGetter` uniformly. The divergence is unintentional.
- **Checkbox card is stringly-typed.** Encoding enum state as `{'spoilerLevelToShow=showNone': true}` in `Map<String, bool?>` is fragile; adding a second enum leaks into the same namespace. Heterogeneous "checkbox + dropdown" cards have no typed model.
- **Double-write persistence.** `showEnabled` on ships is written to both `appSettings.shipsPageState` (always) and the filter-group lock (when locked). `showHidden` on hullmods only writes to the lock. The mismatch is accidental; the lock's stated semantics ("opt-in remembering across sessions") imply *only* the lock path should exist for filter-adjacent toggles.
- **Pre-release schema.** `PersistedFilterGroup` schema v1 has not shipped. No migration is required for a clean break to v2.

## Goals / Non-Goals

**Goals:**

- Eliminate duplicated chip-apply logic, `activeFilterCount`, `clearAllFilters`, `updateFilterStates`, `checkboxesSnapshot`, `_maybePersistCheckboxes`, and `_checkboxesLockApplied` wiring across all four controllers.
- Give heterogeneous "checkbox + dropdown in one lockable card" a typed home.
- Make portraits' per-pane filter scopes a first-class concept instead of an ad-hoc string-suffix hack.
- Make the lock the *single* persistence path for filter-adjacent toggles (ending the ships double-write).
- Keep page controllers in charge of their own pipeline ordering.

**Non-Goals:**

- Not building a one-engine-owns-everything framework. The engine is a toolkit; pages call it as functions around their page-specific operations.
- Not migrating search, isLoading, split-pane, portrait-size, or mode into the engine — those are not filters.
- Not changing chip UX, filter chip appearance, or tri-state semantics.
- Not writing a v1→v2 settings migration — v1 is unreleased.
- Not adding lock buttons to portraits left/right scopes. They remain transient by policy.

## Decisions

### Sealed `FilterGroup<T>` hierarchy with four variants

```
FilterGroup<T>
├── ChipFilterGroup<T>                  // today's GridFilter, renamed
├── BoolFilterGroup<T>                  // a checkbox, predicate-driven
├── EnumFilterGroup<T, E extends Enum>  // a dropdown, predicate-driven
└── CompositeFilterGroup<T>             // heterogeneous fields, one lock
       ├── fields: List<FilterField<T>>
       │   ├── BoolField<T>
       │   └── EnumField<T, E>
```

**Why sealed and typed rather than a single `FilterGroup` with mode flags:** exhaustive `switch` in the renderer forces compile-time coverage of new group types; serialization logic is grouped with each variant instead of branching on a discriminator.

**Alternative considered — keep `GridFilter` untyped and add sibling widgets for checkbox/enum cards.** Rejected: leaves the stringly-typed encoding in place and doesn't unify `activeCount`/`clearAll`/persistence mechanics.

### `FilterScope = (pageId, scopeId)` as the persistence identity

Portraits needs three independent filter scopes on one page. Today's persistence key is `"<pageId>::<filterGroupId>"`. We widen to `"<pageId>::<scopeId>::<filterGroupId>"`. Single-scope pages use `scopeId = 'main'`.

**Why explicit scope rather than keeping pageId suffixes:** the stager, persistence provider, and lock button all need to agree on the same identity. A dedicated `FilterScope` type makes that impossible to forget; string suffixes have already leaked past their intended point of use.

**Alternative considered — tag each `GridFilter` with an optional scope field.** Rejected: scopes naturally group sets of filters (the whole panel), not individual filters; leads to every filter re-declaring the same scope.

### `FilterScopeController<T>` is a toolkit, not a framework

It exposes functions (`applyChipFilters`, `applyNonChipFilters`, `activeCount`, `clearAll`, `loadPersisted`, `maybePersist`, `setChipSelections`). Page controllers still own `build()` and their pipeline:

```dart
@override ShipsPageState build() {
  // …load data as before…
  _filters.loadPersisted(ref.read(fgp));
  var items = _filters.applyNonChipFilters(allShips);   // enabled, spoilers
  final beforeChips = items;
  items = _filters.applyChipFilters(items);             // hull size, mod, etc.
  items = _search(items, state.currentSearchQuery);
  return state.copyWith(
    filteredShips: items,
    shipsBeforeGridFilter: beforeChips,
  );
}
```

**Why toolkit over mixin:** pipeline order differs per page (portraits applies `replaced` *after* chips); a mixin that owns `build()` or `process()` pushes page-specific operations into hooks with unclear ordering. Functions compose cleanly.

**Alternative considered — a `Notifier` subclass that owns filtering end-to-end.** Rejected after examining portraits: every page would need to override enough hooks that the abstraction paid for nothing.

### Canonicalize chip-apply on the hullmods variant

Hullmods' `_applyFilters` handles both the `valuesGetter`-present and `valuesGetter`-null paths cleanly. Ships/weapons have a subtle bug where the fallback path mixes the two shapes. The shared engine adopts hullmods' shape verbatim and removes the others.

### Composite serialization replaces stringly-typed checkbox-lock encoding

Today:
```json
{ "showEnabled": true, "spoilerLevelToShow=showNone": true }
```

New:
```json
{
  "schemaVersion": 2,
  "selections": { "showEnabled": true, "spoiler": "showNone" }
}
```

`PersistedFilterGroup.selections` widens from `Map<String, bool?>` to `Map<String, Object?>`. The envelope still uses dart_mappable; the runtime type is `Object?` because field values can be `bool`, `String` (enum `.name`), or `null`.

**Why drop v1 entries:** schema v1 is pre-release; writing a migration for unreleased state would cost more than it's worth.

### Persistence is the single source for filter-adjacent toggles

Before: `showEnabled` is written to `appSettings.<page>PageState` on every toggle AND to the filter-group lock when locked. After: it's only written to the lock. If the user doesn't lock the group, `showEnabled` resets to its default on each session.

This matches the lock's documented semantics. It is a user-visible behavior change; the proposal's `What Changes` calls this out.

**Non-filter UI state** (`showFilters`, `splitPane`, `useContainFit`, portrait `mode`/`portraitSize`) stays in `appSettings.<page>PageState` and always persists. This split is clean because those fields are window/layout preferences, not filter selections.

### `FilterGroupRenderer` widget switches on the sealed type

```dart
Widget build(BuildContext context) => switch (group) {
  ChipFilterGroup<T> g      => GridFilterWidget(filter: g, ...),
  BoolFilterGroup<T> g      => _BoolRow(group: g),
  EnumFilterGroup<T, dynamic> g => _EnumRow(group: g),
  CompositeFilterGroup<T> g => _CompositeCard(group: g, scope: scope),
};
```

Standalone `BoolFilterGroup` / `EnumFilterGroup` do not render a lock icon. If a page wants a bool/enum toggle to persist, it must declare it inside a `CompositeFilterGroup` — which today matches exactly how ships/weapons/hullmods/portraits use their "checkbox card."

### File layout

```
lib/widgets/filter_engine/
├── filter_group.dart                   // sealed hierarchy + FilterField
├── filter_scope.dart                   // FilterScope value type
├── filter_scope_controller.dart        // toolkit
├── filter_group_renderer.dart          // widget dispatcher
├── chip_filter_group.dart              // ChipFilterGroup + matching algorithm
├── composite_filter_group.dart         // CompositeFilterGroup + BoolField/EnumField
└── filter_engine.mapper.dart           // generated
```

`lib/widgets/filter_widget.dart` and `lib/widgets/filter_group_persistence/` stay where they are; `GridFilterWidget`, `FiltersPanel`, and `FilterGroupStager` are refactored in place to consume the new types.

## Risks / Trade-offs

- **[Risk] Pages silently break the new pipeline contract by forgetting `applyNonChipFilters` or calling it after `applyChipFilters`.** → Mitigation: the toolkit's methods are pure `Iterable -> List` transforms, so mis-ordering surfaces as incorrect filtered output, caught by manual verification of each migrated page during Tasks.
- **[Risk] Ships users lose their persisted `showEnabled=true` preference on upgrade because the double-write is collapsing to lock-only.** → Mitigation: if the user had *locked* the ships checkbox card, their preference survives. If they had never locked it, the preference was quietly being persisted through the other path — and will now reset to `false` on first session after upgrade. This is the intended behavior (the lock's documented contract); called out in the proposal. No code mitigation needed.
- **[Risk] Dart's sealed + generic `EnumFilterGroup<T, E extends Enum>` interplay in exhaustive switches.** Dart supports exhaustive `switch` on sealed types, but the existentially-quantified `E` in `EnumFilterGroup<T, E>` requires a wildcard pattern in consumers. → Mitigation: hide the `E` behind an interface method on `EnumFilterGroup` (e.g. `List<Object> get optionValues`, `Object? get selectedAsObject`) so the renderer doesn't need to reason about `E` directly.
- **[Risk] Dropping v1 persisted filter entries silently on load could confuse a pre-release tester.** → Mitigation: low-value concern because v1 was never shipped; log at info level on drop so it's visible in traces without alarm.
- **[Risk] `FilterScopeController` isn't a Riverpod provider — it's a plain object held by the page `Notifier`.** State changes to groups won't automatically trigger a notifier rebuild. → Mitigation: the controller exposes mutation methods that the notifier calls explicitly, then manually reassigns state (same pattern today uses for `filter.filterStates.clear()` + `state = state.copyWith(filterCategories: List.from(...))`).
- **[Trade-off] Lockable-only-via-composite for bool/enum groups.** Users can't opt a standalone `showEnabled` toggle into persistence without wrapping it in a composite. → Accepted: every page we audited already uses a composite card shape; if a future page wants a lone lockable bool, adding a single-field composite is one line.

## Migration Plan

No user-facing migration. Steps for the code migration happen in `tasks.md`. Settings migration for v1 entries is a silent drop on load because the schema is pre-release.

**Rollback** — a single `git revert` undoes the change. Because v1 settings entries are dropped (not consumed destructively), rolling back does not corrupt on-disk settings; the filter-lock map simply reverts to whatever v1 entries were present before the upgrade (or remains empty if the user locked anything under v2, which would also get dropped on load by the rolled-back v1 code that doesn't understand them).

## Open Questions

- **Should `FilterScopeController` be a Riverpod provider factory in its own right?** Today pages instantiate it inside their `Notifier` and call it like a field. If we wanted per-scope lifetime tied to Riverpod, it could be a family provider. Deferred — current shape is simpler and matches the notifier-lifecycle assumption of today's code.
- **Should `BoolField` and `EnumField` also be allowed as top-level scope groups for rendering (without lock)?** The spec says yes. If that's never used in practice, we could constrain them to composites and simplify the renderer. Keeping flexibility for now; revisit if unused after migration.
