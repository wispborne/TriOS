# Purpose

Defines the behavior of `WispGrid`'s row grouping system, including single-level grouping, optional two-level (primary + secondary) grouping, header rendering, collapse state, drag-and-drop, context menu, CSV export, persistence, and the pinned group.

## Requirements

### Requirement: Single-level grouping remains the default behavior

When `GroupingSetting.secondaryGroupedByKey` is `null` (including the missing-field case after upgrade), `WispGrid` SHALL render groups exactly as it did before this change: one header per group, followed by that group's rows, with no secondary subdivisions and no `## Subgroup:` markers in CSV output.

#### Scenario: Null secondary preserves existing behavior

- **GIVEN** a `WispGridState` with `groupingSetting.currentGroupedByKey = 'category'` and `secondaryGroupedByKey = null`
- **WHEN** the grid builds
- **THEN** each category emits one header followed by its rows
- **AND** the emitted widget list is identical to the pre-change behavior for the same inputs
- **AND** CSV export emits `# Group: <name>` lines without any `## Subgroup:` lines

#### Scenario: Unset secondary is indistinguishable from pre-upgrade persisted state

- **GIVEN** a `WispGridState` loaded from settings that was persisted before `secondaryGroupedByKey` existed
- **WHEN** dart_mappable constructs the instance
- **THEN** `secondaryGroupedByKey` is `null`
- **AND** the grid renders single-level with no error

### Requirement: Optional secondary grouping nests under the primary

When `secondaryGroupedByKey` names a grouping in `widget.groups`, and that grouping is not the same as `currentGroupedByKey`, `WispGrid` SHALL build a two-level grouped structure: primary buckets built via the primary grouping's `getAllGroupSortValues`, and within each primary bucket, secondary buckets built via the secondary grouping's `getAllGroupSortValues` over that bucket's items.

Emission order inside each primary bucket is: primary header → (per secondary bucket: secondary header → rows).

Secondary buckets SHALL sort in ascending order of sort value. Primary buckets continue to honor `groupingSetting.isSortDescending` for their direction.

#### Scenario: Two-level grouping emits nested headers

- **GIVEN** items with primary grouping = Category and secondary grouping = Enabled/Disabled
- **AND** two mods in Category "Faction" (one enabled, one disabled) and one mod in Category "Utility" (enabled)
- **WHEN** the grid builds
- **THEN** the emitted sequence contains (in order): primary header "Faction", secondary header "Enabled", one row, secondary header "Disabled", one row, primary header "Utility", secondary header "Enabled", one row
- **AND** empty secondary buckets are not emitted

#### Scenario: Secondary key equal to primary falls back to single-level

- **GIVEN** `currentGroupedByKey = 'category'` and `secondaryGroupedByKey = 'category'`
- **WHEN** the grid builds
- **THEN** the grid behaves as if `secondaryGroupedByKey` were `null`
- **AND** no secondary headers are emitted

#### Scenario: Multi-group items fan out at both levels independently

- **GIVEN** a mod assigned to two categories and `getAllGroupSortValues` returns two primary sort values for it
- **AND** `modsGridShowModInAllCategories` is true
- **WHEN** the grid builds with Category primary and Enabled secondary
- **THEN** the mod appears once under each of its categories
- **AND** inside each category the mod is placed into its enabled/disabled secondary bucket

### Requirement: Secondary headers render in small style regardless of user preference

Secondary group headers SHALL render using `GroupHeaderStyle.small`, ignoring `groupingSetting.headerStyle`. The user-configurable `headerStyle` continues to apply to the primary header only.

#### Scenario: User picks large style but secondary stays small

- **GIVEN** `groupingSetting.headerStyle = GroupHeaderStyle.large` and a secondary grouping is active
- **WHEN** the grid builds
- **THEN** primary headers render in the large style
- **AND** secondary headers render in the small (divider-line) style

### Requirement: Overlay widgets render on both primary and secondary headers

For each header (primary and secondary), `WispGrid` SHALL invoke the grouping's `overlayWidget(...)` hook with the items in that bucket and render the returned overlay alongside the header text, using the same positioning logic as today.

#### Scenario: VRAM sum shows per primary and per secondary bucket

- **GIVEN** `CategoryModGridGroup` primary and `EnabledStateModGridGroup` secondary
- **AND** a category "Faction" containing 5 enabled mods totalling 1.2 GB and 3 disabled mods totalling 400 MB
- **WHEN** the grid renders that category
- **THEN** the primary "Faction" header overlay reads 1.6 GB total
- **AND** the "Enabled" secondary header inside it reads 1.2 GB
- **AND** the "Disabled" secondary header inside it reads 400 MB

### Requirement: Collapse state is independent per level

Collapse state SHALL distinguish primary groups from secondary groups nested inside them, keyed so that collapsing one secondary group does not collapse another with the same sort value under a different primary. Collapsing a primary group SHALL suppress emission of all of its secondary headers and rows.

#### Scenario: Same secondary name under different primaries collapses independently

- **GIVEN** primaries "Faction" and "Utility" both containing "Enabled" and "Disabled" secondaries
- **WHEN** the user collapses "Enabled" under "Faction"
- **THEN** "Enabled" under "Utility" remains expanded
- **AND** "Disabled" under "Faction" remains expanded

#### Scenario: Collapsing primary hides all its secondaries

- **GIVEN** a primary "Faction" with two secondaries "Enabled" and "Disabled"
- **WHEN** the user collapses "Faction"
- **THEN** neither secondary header is emitted
- **AND** no rows inside "Faction" are emitted

### Requirement: Drag-and-drop targets the level it is dropped on

When a row is dropped on a group header, `WispGrid` SHALL invoke `onItemsDropped` on the grouping owning that header (primary or secondary), not the other level. The per-row `DragTarget` continues to be wired to the primary grouping only.

#### Scenario: Drop on secondary header fires the secondary grouping's handler

- **GIVEN** Category primary (supports D&D) and a hypothetical secondary grouping that supports D&D
- **WHEN** the user drops a row on a secondary header
- **THEN** the secondary grouping's `onItemsDropped` is invoked with that secondary's items as the target group
- **AND** the primary grouping's `onItemsDropped` is not invoked

#### Scenario: Enabled-state secondary header ignores drops

- **GIVEN** Category primary and Enabled secondary (which does not override `onItemsDropped`)
- **WHEN** the user drops a row on "Enabled" or "Disabled"
- **THEN** no state change occurs (the base `onItemsDropped` is a no-op)

### Requirement: Context menu exposes "Then By" as a sibling of "Group By"

The group-header context menu SHALL include a "Then By" submenu adjacent to (not nested inside) the existing "Group By" submenu when and only when:

- `widget.groups.length > 1`, AND
- the candidate list for secondary — all groupings minus the current primary, plus a leading "None" — contains at least one non-"None" option.

The "Then By" submenu SHALL contain a "None" entry that clears the secondary, plus one entry per grouping other than the current primary. Selecting an entry updates `GroupingSetting.secondaryGroupedByKey`. If the user later changes the primary to a key that is currently set as the secondary, `secondaryGroupedByKey` SHALL be cleared to `null` in the same state update.

#### Scenario: Two groupings available — Then By visible with one option + None

- **GIVEN** `widget.groups` contains exactly `[Category, Enabled]` and primary = `Category`
- **WHEN** the group-header context menu opens
- **THEN** "Group By" shows `Category` (checked), `Enabled`
- **AND** "Then By" shows `None` (checked when secondary is null), `Enabled`

#### Scenario: Only one grouping — Then By hidden

- **GIVEN** `widget.groups` has length 1
- **WHEN** the group-header context menu opens
- **THEN** neither "Group By" nor "Then By" appears (existing rule already hides "Group By")

#### Scenario: Primary change clears secondary when they would collide

- **GIVEN** primary = `Category` and secondary = `Enabled`
- **WHEN** the user picks `Enabled` from "Group By"
- **THEN** `currentGroupedByKey` becomes `Enabled`
- **AND** `secondaryGroupedByKey` becomes `null` in the same update

### Requirement: CSV export emits a two-tier structure

`WispGridCsvExport.toCsv` SHALL emit a `# Group: <primary name>` line for each primary bucket and, when secondary grouping is active, a `## Subgroup: <secondary name>` line before each secondary bucket's rows. When secondary grouping is inactive, no `## Subgroup:` lines are emitted.

#### Scenario: Two-level CSV has both markers

- **GIVEN** Category primary and Enabled secondary, with "Faction" > Enabled (1 row) and Disabled (1 row), and "Utility" > Enabled (1 row)
- **WHEN** CSV is exported with headers enabled
- **THEN** the output contains the headers row, then `# Group: Faction`, `## Subgroup: Enabled`, the row, `## Subgroup: Disabled`, the row, `# Group: Utility`, `## Subgroup: Enabled`, the row

#### Scenario: Single-level CSV is unchanged

- **GIVEN** Category primary with secondary grouping inactive
- **WHEN** CSV is exported
- **THEN** the output contains only `# Group: <name>` lines and rows — no `## Subgroup:` lines appear anywhere

### Requirement: Secondary grouping persists alongside primary

`GroupingSetting` SHALL carry `secondaryGroupedByKey` as a nullable field that is serialized and deserialized by dart_mappable alongside existing fields. No settings migration is required. Loading a `GroupingSetting` that was persisted before this field existed SHALL yield `secondaryGroupedByKey == null`.

#### Scenario: Round-trip preserves secondary

- **GIVEN** a user selects secondary = `enabledState` on the mods grid
- **WHEN** the app restarts and loads settings
- **THEN** `GroupingSetting.secondaryGroupedByKey` equals `'enabledState'`
- **AND** the grid builds two-level on first render

### Requirement: Pinned group is never secondary-grouped

The synthetic pinned group at the top of `WispGrid` SHALL render as a single-level group regardless of `secondaryGroupedByKey`. Its items are not subdivided by the secondary grouping.

#### Scenario: Pinned items stay flat under secondary grouping

- **GIVEN** a non-empty `widget.pinnedItems` and an active secondary grouping
- **WHEN** the grid builds
- **THEN** the pinned group emits exactly one header followed by its rows
- **AND** no `## Subgroup:` markers appear in the pinned group's CSV section
