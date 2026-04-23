# Filter Group Persistence Specification

## Purpose

Define how viewer pages (ships, weapons, hullmods, portraits, and similar) let users opt-in to persisting individual filter group selections across app sessions via a per-group lock toggle, with stable keying, safe reapplication after manager data is ready, and a backwards-compatible settings schema.

## Requirements

### Requirement: Per-filter-group persistence lock affordance

Each filter group rendered in a viewer page's filter panel SHALL display a small lock-icon toggle in its header. The toggle MUST default to the off (unlocked) state for every filter group on first use. The toggle MUST have a tooltip explaining that enabling it persists the group's selections across app sessions.

#### Scenario: Default state is unlocked

- **WHEN** a user opens a viewer page for the first time after this change ships
- **THEN** every filter group header displays an unlocked-lock icon and no filter state is persisted

#### Scenario: Lock tooltip is present

- **WHEN** the user hovers over the lock icon on a filter group
- **THEN** a tooltip explains that enabling the lock will remember this filter group's selections between sessions

### Requirement: Enabling the lock persists current selections

When a user enables the lock on a filter group, the system SHALL immediately write the group's current tri-state selection map to persisted settings under a stable key derived from the page identifier and the filter group identifier. Future edits to the group's selections while the lock remains enabled MUST update the persisted entry.

#### Scenario: Locking a group with active filters saves them

- **GIVEN** the Ships page has a "Hull Size" filter group with "Frigate" included and "Capital" excluded
- **WHEN** the user enables the lock on the "Hull Size" group
- **THEN** the system persists the selection `{Frigate: true, Capital: false}` under the key for `(ships, hullSize)`

#### Scenario: Locking a group with no active filters saves an empty entry

- **GIVEN** a filter group with no selections
- **WHEN** the user enables the lock
- **THEN** the system persists an empty selection map under that group's key so that reloads restore the empty state rather than ignoring the lock

#### Scenario: Editing selections while locked updates persistence

- **GIVEN** a filter group whose lock is on and current persisted entry is `{A: true}`
- **WHEN** the user toggles value `B` to included
- **THEN** the persisted entry is updated to `{A: true, B: true}`

### Requirement: Disabling the lock clears persistence but preserves live state

When a user disables the lock on a filter group, the system SHALL remove the group's entry from persisted settings. The current in-memory filter selections MUST remain unchanged.

#### Scenario: Unlocking removes persistence without clearing selections

- **GIVEN** a filter group with lock on and persisted entry `{A: true}`
- **WHEN** the user disables the lock
- **THEN** the persisted entry for that group is removed
- **AND** the group's in-memory selection map still contains `{A: true}`
- **AND** subsequent app restarts do not reapply `{A: true}`

### Requirement: Persisted filters reapply only after manager data is ready

On viewer page load, persisted filter selections for locked groups SHALL be staged and applied only after the page's underlying data manager has finished its initial load. Saved selections MUST NOT be cleared, ignored, or overwritten by a transient empty or loading state from the manager.

#### Scenario: Reapply waits for manager readiness

- **GIVEN** the Ships page has a locked "Hull Size" group with saved selections `{Frigate: true}`
- **AND** `shipManagerProvider` is in the `AsyncLoading` state
- **WHEN** the page builds
- **THEN** the filter group does not yet show live filter state changes driven by persistence
- **AND** the selection is staged internally pending manager readiness

#### Scenario: Reapply occurs when manager resolves

- **GIVEN** the conditions above
- **WHEN** `shipManagerProvider` transitions to `AsyncData`
- **THEN** the saved selection `{Frigate: true}` is written into the live filter state for the "Hull Size" group
- **AND** the page's result list reflects the filter

#### Scenario: Transient empty manager does not drop persisted filters

- **GIVEN** a locked filter group with a saved selection
- **WHEN** the manager momentarily emits an empty list before the real data arrives
- **THEN** the saved selection is not discarded
- **AND** the selection is applied once the non-empty data arrives

#### Scenario: User edits after reapply are not overwritten

- **GIVEN** persisted filters have been successfully applied on page load
- **WHEN** the user subsequently toggles a filter value
- **THEN** the reapply step does not re-run and does not overwrite the edit

### Requirement: Stable keying via page identifier and filter group identifier

Each filter scope SHALL declare a stable `(pageId, scopeId)` pair, and each filter group SHALL declare a stable string identifier. The persistence key MUST combine the three as `"<pageId>::<scopeId>::<filterGroupId>"` and MUST NOT be derived from user-facing display names. For pages that host only a single filter scope, the scope id `main` SHALL be used.

#### Scenario: Renaming a filter's display name does not break persistence

- **GIVEN** a filter group with id `hullSize` and display name "Hull Size"
- **AND** the user has locked and persisted selections for it
- **WHEN** the display name is later changed to "Size"
- **THEN** persisted selections still load correctly under the same `ships::main::hullSize` key

#### Scenario: Two pages with the same filter group id do not collide

- **GIVEN** the Ships and Weapons pages each have a filter group with id `tags`
- **WHEN** each is locked with different selections
- **THEN** the two groups' persisted entries are stored under distinct keys (`ships::main::tags` and `weapons::main::tags`) and do not overwrite each other

#### Scenario: Two scopes on the same page do not collide

- **GIVEN** the Portraits page's `main` and `left` scopes each declare a `gender` group
- **WHEN** a user locks the `main` scope's `gender` group
- **THEN** the persisted entry uses the key `portraits::main::gender`
- **AND** the `left` scope's `gender` group is never persisted under any key (it is transient)

### Requirement: Persisted selections referring to unknown values are retained inertly

When a persisted selection contains values that are no longer present in the underlying data set (e.g., a mod that added that tag has been uninstalled), the system SHALL retain those values in the persisted entry but MUST NOT apply them to the live filter state. If those values later reappear in the data set, they SHALL be applied then.

#### Scenario: Unknown value is retained across sessions

- **GIVEN** a locked filter group whose persisted entry includes `{tagFromModX: true}`
- **AND** mod X is currently uninstalled so `tagFromModX` does not appear in the data
- **WHEN** the page loads
- **THEN** the live filter state does not contain `tagFromModX`
- **AND** the persisted entry continues to include `tagFromModX`

#### Scenario: Unknown value re-activates when data reappears

- **GIVEN** the conditions above
- **WHEN** the user reinstalls mod X and the manager reloads
- **THEN** `tagFromModX` is applied to the live filter state

### Requirement: Shared lock-button widget reused across filter group types

A shared widget (`FilterGridPersistButton`) SHALL provide the lock toggle. It MUST be used by the `FilterGroupRenderer` for `ChipFilterGroup` and `CompositeFilterGroup` renderings. Standalone `BoolFilterGroup` and `EnumFilterGroup` outside of a composite MUST NOT display a lock button — persistence for heterogeneous page-level toggles SHALL be expressed by wrapping the relevant bool/enum groups in a `CompositeFilterGroup`.

#### Scenario: Chip group renders with a lock button

- **WHEN** the Ships page renders a `ChipFilterGroup` via `FilterGroupRenderer`
- **THEN** its header contains a `FilterGridPersistButton`

#### Scenario: Composite card renders with one lock button

- **WHEN** a viewer page renders a `CompositeFilterGroup` of mixed bool and enum fields
- **THEN** the card header contains exactly one `FilterGridPersistButton` with a `filterGroupId` equal to the composite group's id

#### Scenario: Standalone bool or enum groups do not render a lock button

- **GIVEN** a scope that declares a bare `BoolFilterGroup` or `EnumFilterGroup` (not wrapped in a composite)
- **WHEN** the group is rendered
- **THEN** no lock icon appears
- **AND** toggling the group changes in-memory state only (it resets on next session)

### Requirement: Additive, backwards-compatible settings schema

The settings model SHALL hold `persistedFilterGroups` as a map of `(pageId::scopeId::filterGroupId) → PersistedFilterGroup`. The `PersistedFilterGroup` envelope's `selections` field MUST be typed as `Map<String, Object?>` to accommodate both tri-state chip selections (`bool?` values) and heterogeneous composite-group field values (`bool`, `String` enum names, etc.). The schema version MUST be 2.

On load, entries whose `schemaVersion` is missing or less than 2 SHALL be silently dropped (the v1 schema was unreleased, so no migration is required).

#### Scenario: Widened selections envelope round-trips composite entries

- **GIVEN** a composite filter group whose fields are `[BoolField('showEnabled', true), EnumField('spoiler', SpoilerLevel.showNone)]`
- **WHEN** the group is locked and serialized
- **THEN** the persisted entry stores `selections: {showEnabled: true, spoiler: 'showNone'}` with `schemaVersion: 2`

#### Scenario: Widened selections envelope still round-trips chip entries

- **GIVEN** a chip filter group with selections `{Frigate: true, Capital: false}`
- **WHEN** it is locked and serialized
- **THEN** the persisted entry stores `selections: {Frigate: true, Capital: false}` with `schemaVersion: 2`
- **AND** loading yields the same tri-state map

#### Scenario: v1 entries are dropped on load

- **GIVEN** an on-disk settings file containing a `PersistedFilterGroup` without `schemaVersion` set to 2
- **WHEN** settings load
- **THEN** that entry is silently discarded
- **AND** no error or log-level-higher-than-info is emitted (v1 was pre-release)
