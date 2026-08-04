# Filter Engine Specification

## Purpose

The filter engine provides a typed, scope-keyed toolkit that viewer pages (ships, weapons, hullmods, portraits) use to declare, apply, render, and persist their filter groups through a shared sealed `FilterGroup<T>` taxonomy. It unifies tri-state chip filters, boolean toggles, enum dropdowns, numeric range sliders, and heterogeneous composite cards behind a single controller and renderer, eliminating per-page filter implementations while letting each page compose its own pipeline order.

## Requirements

### Requirement: Typed filter group taxonomy

The system SHALL provide a sealed `FilterGroup<T>` type with exactly five variants covering every filter shape used by viewer pages:

- `ChipFilterGroup<T>` — tri-state (include / exclude / none) multi-value chip set, identical in purpose to today's `GridFilter`.
- `BoolFilterGroup<T>` — a single on/off toggle rendered as a checkbox.
- `EnumFilterGroup<T, E extends Enum>` — a single-selection enum rendered as a dropdown.
- `RangeFilterGroup<T>` — a numeric low/high range rendered as a two-handle slider.
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
2. Otherwise, if any value in the group's state map is explicitly included (`true`), the item must match the group's logic mode: at least one included value under `ChipLogicMode.any`, or every included value under `ChipLogicMode.all`.
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

### Requirement: Per-group include logic mode

Every `ChipFilterGroup<T>` SHALL carry a `logicMode` of `ChipLogicMode.any` (the default) or `ChipLogicMode.all`, deciding how the values the user included are combined. Exclusion is unaffected: any excluded value vetoes the item under both modes.

The mode SHALL be part of the group's saved state, stored under the reserved key `_logic` and written only when it differs from the default, so state saved before this feature loads unchanged. An unrecognised value MUST fall back to `any`. `clear()` MUST reset the mode along with the chip states.

#### Scenario: "All" requires every included value

- **GIVEN** a `ChipFilterGroup<Ship>` on weapon slot types in `all` mode with `{BALLISTIC: true, MISSILE: true}`
- **WHEN** ships are matched
- **THEN** only ships that have both a ballistic slot and a missile slot pass
- **AND** a ship with just one of the two is rejected

#### Scenario: "Any" keeps the original behaviour

- **GIVEN** the same group in `any` mode with the same selections
- **WHEN** ships are matched
- **THEN** a ship with either slot type passes

#### Scenario: Logic mode survives a save and reload

- **GIVEN** a locked chip group set to `all`
- **WHEN** its state is saved and later restored
- **THEN** the group is in `all` mode again
- **AND** a group left at `any` writes no `_logic` key at all

### Requirement: Numeric range filter group

A `RangeFilterGroup<T>` SHALL filter items by a number read from each item, with:

- `min` and `max` taken from the data, refreshed by `updateRange(Iterable<T> items)`.
- `curMin` and `curMax` for what the user picked. `isActive` is true only while a handle sits inside the data range.
- `stops`: every distinct value in the data, sorted. `stopIndexFor(value)` returns the position of the nearest stop.
- `allowGreater` (default true): with the top handle at the far right, anything at or above `max` passes, so a value the group has not seen cannot fall off the end.

An item whose value is null SHALL be rejected while the filter is active, and accepted while it is not — a missing number cannot be "between 10 and 30".

`updateRange` SHALL be called with the page's full item list, not the filtered subset, so the ends of the slider do not move as other filters are applied. A handle sitting at either end SHALL stay at that end when the data range grows or shrinks; a handle inside the range SHALL be clamped to the new range. A range read from saved settings before any data has loaded SHALL be held and applied on the next `updateRange`.

#### Scenario: Range keeps only items inside the bounds

- **GIVEN** a deployment-points range over ships worth 5, 10, 20 and 60 points
- **AND** the range set to 10–20
- **WHEN** ships are matched
- **THEN** the 10 and 20 point ships pass and the 5 and 60 point ships are rejected

#### Scenario: The top handle means "and above"

- **GIVEN** the same group with the range set to 20 up to the top of the data
- **WHEN** a ship worth more than any ship seen so far is matched
- **THEN** it passes

#### Scenario: Handles at the ends follow the data

- **GIVEN** a range group with both handles at the ends of the data
- **WHEN** new mods raise the highest value
- **THEN** the top handle moves to the new highest value
- **AND** the group is still inactive

#### Scenario: A saved range waits for the data

- **GIVEN** a locked range group restored from settings before any items have loaded
- **WHEN** the item list arrives
- **THEN** the saved low and high are applied, clamped to the range the data actually holds

### Requirement: Range slider track spaced by value, not by size

The slider for a `RangeFilterGroup` SHALL space its track one notch per distinct value in the data, every notch the same width, and MUST NOT space it in proportion to the numbers.

Ship stats are far too lopsided for a to-scale track: vanilla hull runs from 30 to 10,000,000 across 52 distinct values, with a median of 5,000. Spaced by value, every real warship would sit inside the first fraction of a percent of the track and could not be picked with a mouse. Mods widen the gap further.

Handle positions SHALL round to whole notches as the user drags, so handles step from one real value to the next. The readout and the end labels SHALL always show the real numbers.

#### Scenario: One runaway value does not squash the track

- **GIVEN** a hull range over values 1,000, 5,000, 20,000 and 10,000,000
- **WHEN** the slider is drawn
- **THEN** the track has four evenly spaced notches
- **AND** the 20,000 ship sits at the third of four notches, not at the far left

#### Scenario: Handles land on real values

- **GIVEN** a range whose data holds 5, 10, 20 and 60
- **WHEN** a handle is dragged to a position between two notches
- **THEN** it settles on whichever of the two values is nearer

### Requirement: Scope-keyed controller toolkit

The system SHALL provide a `FilterScopeController<T>` construct identified by a `FilterScope(pageId, scopeId)` that:

- Holds a list of `FilterGroup<T>` instances for that scope.
- Exposes `applyChipFilters(Iterable<T>) -> List<T>` applying only chip groups.
- Exposes `applyNonChipFilters(Iterable<T>) -> List<T>` applying bool, enum, range, and composite groups.
- Exposes `applyRangeFilters(Iterable<T>) -> List<T>` applying only range groups, for pages that apply their other non-chip rules by hand and so never call `applyNonChipFilters`.
- Exposes `updateRanges(Iterable<T>)` refreshing every range group's data range.
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

Chip groups continue to serialize as `Map<String, bool?>` (wrapped in the same widened `Map<String, Object?>` envelope at the persistence layer), plus the reserved `_logic` key when the group's logic mode is not the default. Range groups serialize as `{'min': curMin, 'max': curMax}`.

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

#### Scenario: The reserved logic key is never treated as a chip

- **GIVEN** a saved chip group holding both chip values and a `_logic` entry
- **WHEN** it is restored, whether directly or through the controller's staged chip loading
- **THEN** `_logic` sets the group's logic mode
- **AND** no chip named `_logic` appears in the panel

### Requirement: Generic filter group renderer widget

The system SHALL provide a `FilterGroupRenderer` widget that accepts any `FilterGroup<T>` and renders the correct UI by type:

- `ChipFilterGroup<T>` → today's `GridFilterWidget` (chip panel with lock button).
- `BoolFilterGroup<T>` → `CheckboxListTile` (no standalone lock; locks only via composite).
- `EnumFilterGroup<T, E>` → `TriOSDropdownMenu<E>` (no standalone lock; locks only via composite).
- `RangeFilterGroup<T>` → `RangeFilterWidget` (two-handle slider with a lock button).
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

### Requirement: Filter panel search and advanced mode

`FiltersPanel` SHALL offer an opt-in search box and an opt-in "Advanced" toggle, and SHALL share both with the groups below it through a `FilterPanelOptions` inherited widget. Pages build their group widgets before the panel exists, so these MUST NOT be constructor arguments on the group widgets. A panel that opts into neither MUST look and behave exactly as it did before.

Search behaviour:

- Typing SHALL be debounced, and matching SHALL ignore capitals.
- A chip stays when its value or its display name matches. A group whose own name matches keeps all of its chips.
- A group with nothing left to show SHALL be hidden entirely, taking up no space.
- Groups with no chips (sliders, checkboxes, dropdowns, composite cards) SHALL match on their name, and a composite card also on its field labels.

Advanced mode SHALL govern only the per-group logic button. Sliders, search, badges, shift-to-solo and the expand button are always available. Advanced mode SHALL be remembered per page, not globally.

#### Scenario: Search narrows the panel

- **GIVEN** a panel with a Hull Size group and a Shield Type group
- **WHEN** the user searches for "fri"
- **THEN** the Frigate chip is shown and the other hull-size chips are hidden
- **AND** the Shield Type group disappears from the panel

#### Scenario: A group is found by its own name

- **GIVEN** the same panel
- **WHEN** the user searches for "shield"
- **THEN** the Shield Type group shows all of its chips
- **AND** the Hull Size group disappears

#### Scenario: Sliders do not hide with advanced mode off

- **GIVEN** a scope holding a range group
- **WHEN** the panel is drawn with advanced mode off
- **THEN** the slider is shown

### Requirement: Filter group header controls

A chip group's header SHALL hold, in order: the group's name, the logic button, then either the chip buttons or the counts, then the lock button.

- The name SHALL take all the width the other controls do not need. Buttons SHALL be sized to their icons rather than to a default tap target, so a 300-wide panel still leaves room to read names like "Tech/Manufacturer".
- Include-all, exclude-all and clear-all SHALL appear only while the group is open. Acting on chips that are off screen is a trap.
- The include and exclude counts SHALL appear only while the group is shut, where they stand in for the chips nobody can see.
- The logic button SHALL appear when advanced mode is on, **or** whenever the group's logic mode is not the default — a group must never filter differently with nothing on screen to say why.
- Include-all, exclude-all and clear-all SHALL act only on the chips the search box is showing. Holding shift SHALL act on the whole group instead.
- Shift-clicking a chip SHALL clear the rest of the group and include just that one.

#### Scenario: A non-default logic mode stays visible

- **GIVEN** a group set to `all`
- **WHEN** the panel is drawn with advanced mode off
- **THEN** the group's "all" button is still shown

#### Scenario: Include all respects the search

- **GIVEN** a hull-size group and a search for "fri"
- **WHEN** the user clicks include-all
- **THEN** only the Frigate chip is included

#### Scenario: Shift-click solos a chip

- **GIVEN** a group with several chips included and excluded
- **WHEN** the user shift-clicks one chip
- **THEN** that chip is the only one included and every other chip in the group is cleared

### Requirement: Filter panel in a dialog

`FiltersPanel` SHALL offer an opt-in button that reopens the same filters in a roomier dialog. The dialog SHALL apply changes as they are made, with no Save or Cancel, and the grid behind it SHALL update at the same time.

The dialog's contents MUST be rebuilt from live state each time that state changes. Filter groups are mutated in place, so a dialog that reused the widget objects the page already built would show stale chips.

#### Scenario: Editing in the dialog updates the grid behind it

- **GIVEN** the filter dialog is open over a viewer page
- **WHEN** the user toggles a chip in the dialog
- **THEN** the chip shows its new state in the dialog
- **AND** the grid behind the dialog re-filters straight away

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

### Requirement: Range slider adoption

The ships and weapons pages SHALL carry range groups over their main numeric stats. Other viewer pages MAY adopt them later with no further work in the engine.

- Ships: deployment points, max speed, ordnance points, armor, hull, flux dissipation, flux capacity, max burn, fuel capacity, cargo capacity, crew capacity.
- Weapons: damage per shot, damage per second, ordnance points, range, flux per second, turn rate, ammo.

#### Scenario: A slider covers the whole item list

- **GIVEN** the ships page with several chip filters applied
- **WHEN** the deployment-points slider is drawn
- **THEN** its ends come from every loaded ship, not from the filtered subset
