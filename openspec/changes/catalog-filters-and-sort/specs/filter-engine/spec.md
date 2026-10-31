## MODIFIED Requirements

### Requirement: Typed filter group taxonomy

The system SHALL provide a sealed `FilterGroup<T>` type with exactly six variants covering every filter shape used by viewer pages:

- `ChipFilterGroup<T>`: tri-state (include / exclude / none) multi-value chip set.
- `BoolFilterGroup<T>`: a single on/off toggle rendered as a checkbox.
- `EnumFilterGroup<T, E extends Enum>`: a single-selection enum rendered as a dropdown.
- `RangeFilterGroup<T>`: a numeric low/high range rendered as a two-handle slider.
- `CompositeFilterGroup<T>`: an ordered list of typed `FilterField<T>` leaves, rendered as a single card under one lock toggle.
- `CustomFilterGroup<T>`: an abstract group that a page subclasses, supplying the matching, active state, saved form and controls. Used when one rule reads several settings together, so the settings can't be split into independent fields.

Each group SHALL expose a stable `id` unique within its scope, a display `name`, an `isActive` predicate, a `matches(T item)` predicate, and typed `serialize()` / `restore(Object?)` methods.

#### Scenario: Chip group matches follow tri-state include/exclude semantics

- **GIVEN** a `ChipFilterGroup<Ship>` on `hullSize` with states `{Frigate: true, Capital: false}`
- **WHEN** the group's `matches` is applied to a list of ships
- **THEN** ships whose hull size is `Capital` are rejected
- **AND** ships whose hull size is `Frigate` pass
- **AND** ships whose hull size is anything else are rejected (because a value is explicitly included)

#### Scenario: Custom group uses the page's rule

- **GIVEN** a `CustomFilterGroup` subclass whose `matches` keeps only even numbers
- **WHEN** the controller applies the scope's non-chip filters
- **THEN** only even numbers remain
- **AND** the renderer draws the page's controls inside a standard group card with a lock button

### Requirement: Canonical chip filter application

The shared chip-filter algorithm SHALL handle both the single-value (`valueGetter`) and multi-value (`valuesGetter`) cases in a single implementation with identical semantics across all pages:

1. For each excluded value that the group lists in `explicitNoChecks`, the item SHALL be rejected unless that value's check says the item said no.
2. Otherwise, if any of the item's values is explicitly excluded (`false`), the item is rejected.
3. Otherwise, if any value in the group's state map is explicitly included (`true`), the item must match the group's logic mode: at least one included value under `ChipLogicMode.any`, or every included value under `ChipLogicMode.all`.
4. Otherwise (only exclusions are present or the state is empty), the item is accepted.

`explicitNoChecks` is optional. When it is not set, step 1 does nothing and the algorithm is unchanged. They are for answers with three outcomes (yes, no, unknown), where excluding should mean "said no" and not "didn't say yes".

This algorithm MUST replace all per-page chip-apply implementations.

#### Scenario: Multi-value chip group with only exclusions

- **GIVEN** a `ChipFilterGroup<Hullmod>` on `uiTags` with `valuesGetter` returning `['logistics', 'ballistic']` for a hullmod
- **AND** state `{cosmetic: false}`
- **WHEN** matching that hullmod
- **THEN** the hullmod passes because none of its values equals an excluded value and no value is explicitly included

#### Scenario: Excluding an explicit-no value keeps only the items that said no

- **GIVEN** a chip group whose `explicitNoChecks` has a check for `safeToAdd`
- **AND** item A has value `safeToAdd`, the check says item B said no, and item C has neither
- **WHEN** the `safeToAdd` chip is excluded
- **THEN** only item B passes

#### Scenario: Single-value chip group unifies with multi-value path

- **GIVEN** a `ChipFilterGroup<Ship>` on `shieldType` with only `valueGetter` defined
- **WHEN** the engine applies the group
- **THEN** the same matching algorithm runs as for multi-value groups (treating the single value as a one-element list)

## ADDED Requirements

### Requirement: Range groups can label their values

`RangeFilterGroup<T>` SHALL accept an optional `valueLabel: String Function(num)`. When set, `RangeFilterWidget` SHALL use it for the range summary and the handle labels, instead of printing the number. `suffix` SHALL be ignored when `valueLabel` is set.

This lets a page store a date as a day number and show it as a date.

#### Scenario: A date range shows dates

- **GIVEN** a range group over day numbers with a `valueLabel` that formats a day number as "14 Mar 2024"
- **WHEN** the slider is set from 2024-03-14 to the top of the data
- **THEN** the summary reads "14 Mar 2024+"

### Requirement: Filtering can also build chip count lists

`FilterScopeController.applyWithCountItems` SHALL apply every active group in one pass and return the matching items. It SHALL also return, for each chip group, the items that pass every *other* active group. The matching items SHALL be the same as applying the chip groups and then the non-chip groups.

#### Scenario: A count list leaves out only its own group

- **GIVEN** a chip group that includes "small" and another active group that keeps even numbers
- **WHEN** `applyWithCountItems` runs over 0 to 9
- **THEN** the matching items are 0, 2 and 4
- **AND** the chip group's count list is 0, 2, 4, 6 and 8

### Requirement: Chip counts can come from a separate list

`FilterGroupRenderer` and `GridFilterWidget` SHALL accept an optional `countItems` list. When it is set and `showCounts` is true, each chip's count SHALL be taken from `countItems`. The list of chips SHALL still come from `items`. When `countItems` is not set, counts come from `items` as before.

This lets a page show "how many mods would this chip leave", while keeping every chip on screen.

#### Scenario: A chip with no matches stays visible

- **GIVEN** `items` holds mods in categories A and B, and `countItems` holds only mods in category A
- **WHEN** the Category group renders with counts
- **THEN** both chips are shown, and the B chip's count is 0
