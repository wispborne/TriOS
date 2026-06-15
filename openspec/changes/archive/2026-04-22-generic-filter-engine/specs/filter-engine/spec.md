## ADDED Requirements

### Requirement: Typed filter group taxonomy

The system SHALL provide a sealed `FilterGroup<T>` type with exactly four variants covering every filter shape used by viewer pages:

- `ChipFilterGroup<T>` — tri-state (include / exclude / none) multi-value chip set, identical in purpose to today's `GridFilter`.
- `BoolFilterGroup<T>` — a single on/off toggle rendered as a checkbox.
- `EnumFilterGroup<T, E extends Enum>` — a single-selection enum rendered as a dropdown.
- `CompositeFilterGroup<T>` — an ordered list of typed `FilterField<T>` leaves (Bool or Enum today), rendered as a single card under one lock toggle.

Each group SHALL expose a stable `id` unique within its scope, a display `name`, an `isActive` predicate, a `matches(T item)` predicate, and typed `serialize()` / `restore(Object?)` methods.

#### Scenario: Chip group matches follow tri-state include/exclude semantics

- **GIVEN** a `ChipFilterGroup<Ship>` on `hullSize` with states `{Frigate: true, Capital: false}`
- **WHEN** the group's `matches` is applied to a list of ships
- **THEN** ships whose hull size is `Capital` are rejected
- **AND** ships whose hull size is `Frigate` pass
- **AND** ships whose hull size is anything else are rejected (because a value is explicitly included)

#### Scenario: Bool group becomes inactive at its default value

- **GIVEN** a `BoolFilterGroup` `showEnabled` with default value `false`
- **WHEN** its current value is `false`
- **THEN** `isActive` reports `false`
- **AND** `matches` returns `true` for every item

#### Scenario: Enum group is active whenever selection differs from default

- **GIVEN** an `EnumFilterGroup<Ship, SpoilerLevel>` with default `showAllSpoilers` and current selection `showNone`
- **WHEN** asked for active state
- **THEN** `isActive` reports `true`

#### Scenario: Composite group aggregates its fields

- **GIVEN** a `CompositeFilterGroup` with fields `[BoolField('showEnabled'), EnumField('spoiler', SpoilerLevel.showNone)]`
- **WHEN** an item is tested
- **THEN** the group returns `true` only if every field's predicate accepts the item
- **AND** `activeCount` equals the number of fields whose `isActive` is true

### Requirement: Canonical chip filter application

The shared chip-filter algorithm SHALL handle both the single-value (`valueGetter`) and multi-value (`valuesGetter`) cases in a single implementation with identical semantics across all pages:

1. If any of the item's values is explicitly excluded (`false`), the item is rejected.
2. Otherwise, if any value in the group's state map is explicitly included (`true`), the item must have at least one included value.
3. Otherwise (only exclusions are present or the state is empty), the item is accepted.

This algorithm MUST replace all per-page chip-apply implementations.

#### Scenario: Multi-value chip group with only exclusions

- **GIVEN** a `ChipFilterGroup<Hullmod>` on `uiTags` with `valuesGetter` returning `['logistics', 'ballistic']` for a hullmod
- **AND** state `{cosmetic: false}`
- **WHEN** matching that hullmod
- **THEN** the hullmod passes because none of its values equals an excluded value and no value is explicitly included

#### Scenario: Single-value chip group unifies with multi-value path

- **GIVEN** a `ChipFilterGroup<Ship>` on `shieldType` with only `valueGetter` defined
- **WHEN** the engine applies the group
- **THEN** the same matching algorithm runs as for multi-value groups (treating the single value as a one-element list)

### Requirement: Scope-keyed controller toolkit

The system SHALL provide a `FilterScopeController<T>` construct identified by a `FilterScope(pageId, scopeId)` that:

- Holds a list of `FilterGroup<T>` instances for that scope.
- Exposes `applyChipFilters(Iterable<T>) -> List<T>` applying only chip groups.
- Exposes `applyNonChipFilters(Iterable<T>) -> List<T>` applying bool, enum, and composite groups.
- Exposes `activeCount` (sum over all groups' `activeCount`).
- Exposes `clearAll()` that resets every group to its default state.
- Exposes `loadPersisted(FilterGroupPersistence)` and `maybePersist(groupId)` for wiring persistence on locked groups.

The controller MUST NOT impose a fixed pipeline order — callers chain `applyChipFilters` and `applyNonChipFilters` in whatever order their page requires, around page-specific operations (search, extra filters, snapshots).

#### Scenario: Multiple scopes within a single page do not collide

- **GIVEN** the portraits page constructs three `FilterScopeController`s with scopes `(portraits, main)`, `(portraits, left)`, `(portraits, right)`
- **WHEN** each scope's chip groups are toggled independently
- **THEN** toggling chips on `main` does not affect `left` or `right`
- **AND** persisting `main`'s locked groups does not write under `left`'s or `right`'s keys

#### Scenario: Page controls its pipeline order

- **GIVEN** a page whose pipeline is `applyNonChipFilters → snapshot → applyChipFilters → search`
- **WHEN** the page rebuilds filtered items
- **THEN** it calls the toolkit methods in that exact order
- **AND** the engine does not re-order, combine, or reapply them implicitly

### Requirement: Persistence scoping

Persistence keys SHALL be derived from `(pageId, scopeId, groupId)`. The encoded key MUST be stable under display-name changes and MUST NOT collide across scopes within the same page.

#### Scenario: Portraits main persists, left and right do not

- **GIVEN** a `FilterScopeController` for `(portraits, main)` with a locked chip group `gender`
- **AND** a `FilterScopeController` for `(portraits, left)` with the same `gender` group
- **WHEN** the user toggles values on both groups
- **THEN** the `main` group's selections are written to settings under the `(portraits, main, gender)` key
- **AND** the `left` group's selections are never written to settings (the scope is configured as transient)

#### Scenario: Scope id prevents within-page collisions

- **GIVEN** two scopes on the same page with group ids that happen to match
- **WHEN** both are locked with different selections
- **THEN** the two scopes' entries occupy distinct keys that include the scope id

### Requirement: Typed serialization for composite groups

Composite groups SHALL serialize their fields to a typed `Map<String, Object?>` whose keys are the field ids and whose values are the field's native type (`bool` for `BoolField`, the enum `.name` string for `EnumField`). Loading MUST restore each field by key, ignoring unknown keys, and MUST fall back to each field's default when the persisted value is missing or of the wrong type.

Chip groups continue to serialize as `Map<String, bool?>` (wrapped in the same widened `Map<String, Object?>` envelope at the persistence layer).

#### Scenario: Composite group round-trips

- **GIVEN** a composite group with `BoolField('showEnabled', value: true)` and `EnumField<SpoilerLevel>('spoiler', value: showNone)`
- **WHEN** it is serialized and then restored
- **THEN** the restored fields have `showEnabled = true` and `spoiler = showNone`

#### Scenario: Missing field falls back to default

- **GIVEN** a persisted composite entry that lacks the `spoiler` key
- **WHEN** the group restores from that entry
- **THEN** the `spoiler` field holds its declared default value

#### Scenario: Unknown field key is ignored

- **GIVEN** a persisted composite entry containing a field key that no longer exists in code
- **WHEN** the group restores
- **THEN** the unknown key is silently ignored and other fields restore normally

### Requirement: Generic filter group renderer widget

The system SHALL provide a `FilterGroupRenderer` widget that accepts any `FilterGroup<T>` and renders the correct UI by type:

- `ChipFilterGroup<T>` → today's `GridFilterWidget` (chip panel with lock button).
- `BoolFilterGroup<T>` → `CheckboxListTile` (no standalone lock; locks only via composite).
- `EnumFilterGroup<T, E>` → `TriOSDropdownMenu<E>` (no standalone lock; locks only via composite).
- `CompositeFilterGroup<T>` → a card with one lock button in the header and each field rendered via its field-specific sub-renderer.

Page controllers SHALL render their filter panel by iterating the scope's groups and wrapping each in a `FilterGroupRenderer`.

#### Scenario: Mixed composite card renders heterogeneously

- **GIVEN** a composite group with `[BoolField, EnumField]`
- **WHEN** rendered
- **THEN** the card displays a single lock button in the header
- **AND** the checkbox and dropdown appear as siblings inside the card body in declaration order

#### Scenario: Bool and enum groups outside a composite do not render a standalone lock

- **GIVEN** a standalone `BoolFilterGroup` or `EnumFilterGroup` in a scope's group list
- **WHEN** rendered
- **THEN** no lock icon is shown for that group
- **AND** persistence for that group is only possible by placing it inside a `CompositeFilterGroup`

### Requirement: Imperative group mutation for context-menu navigation

The `FilterScopeController<T>` SHALL expose a public method to imperatively set a chip group's selections by group id. This enables features like the viewers' "jump to this mod" context menu, which today mutates `GridFilter.filterStates` directly.

#### Scenario: Setting selections from context-menu navigation

- **GIVEN** the ships page's scope has a `mod` chip group
- **WHEN** the user right-clicks a ship row and picks "Show this mod's weapons only"
- **THEN** the weapons page's scope controller receives a `setChipSelections('mod', {'Mod Name': true})` call
- **AND** the weapons page filters to show only that mod's weapons on its next rebuild

### Requirement: Page-scope migration coverage

The following pages and scopes SHALL be migrated to the filter engine as part of this change:

- Ships — scope `(ships, main)`
- Weapons — scope `(weapons, main)`
- Hullmods — scope `(hullmods, main)`
- Portraits — scopes `(portraits, main)`, `(portraits, left)`, `(portraits, right)`

Ships/weapons/hullmods scopes SHALL expose lock buttons on every group and persist locked groups. The portraits `left` and `right` scopes SHALL NOT display lock buttons and MUST NOT persist to settings under any circumstance.

#### Scenario: Every migrated page uses the engine

- **WHEN** any of the four pages builds its filter panel
- **THEN** all filter UI is produced by iterating a `FilterScopeController`'s groups through `FilterGroupRenderer`
- **AND** no per-page `_applyFilters`, `_processAllFilters`, `checkboxesSnapshot`, `_maybePersistCheckboxes`, or `_checkboxesLockApplied` remains

#### Scenario: Portraits left/right scopes are transient

- **GIVEN** the portraits page in replacer mode
- **WHEN** the user toggles chip values on the left scope
- **THEN** nothing is written to `appSettings.persistedFilterGroups`
- **AND** the left scope's filter selections reset when the page state is discarded
