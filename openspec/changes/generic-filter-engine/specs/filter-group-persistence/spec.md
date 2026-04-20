## MODIFIED Requirements

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

## REMOVED Requirements

_None. Existing lock-button UX, reapply-after-ready staging, unknown-value retention, and default-unlocked behavior from v1 are retained in full — only scoping and serialization are widened._
