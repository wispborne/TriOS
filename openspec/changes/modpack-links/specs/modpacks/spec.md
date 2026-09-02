## ADDED Requirements

### Requirement: Shared modpack definition
TriOS SHALL represent a shared modpack with format version 1, an opaque
case-sensitive pack ID made from 16 random bytes as exactly 22 unpadded
base64url characters, a positive JavaScript-safe integer version, a non-empty
name, ordered unique items, and optional shared metadata. A committed
definition SHALL contain at least one item.

Each item SHALL use a case-sensitive mod ID and an explicit Version Checker or
fixed-download HTTP or HTTPS source. It MAY include name and version display
snapshots, a creator note of at most 2,000 characters, catalog recovery clues,
and an optional single-line status of at most 40 characters.

#### Scenario: Item status is absent
- **WHEN** an item has no status
- **THEN** TriOS SHALL display no status and SHALL NOT assign a default

#### Scenario: Standard or custom item status is present
- **WHEN** an item uses Required, Recommended, Optional, or a valid custom status
- **THEN** TriOS SHALL preserve and display it without changing selection, installation, dependency, validation, or enabling behavior

#### Scenario: Recorded item version differs
- **WHEN** an installed mod version differs from the item's recorded version
- **THEN** TriOS SHALL still treat the item as installed and SHALL display the installed version followed by the recorded modpack version in parentheses

#### Scenario: Starsector-version label is present
- **WHEN** a definition contains a Starsector-version label
- **THEN** TriOS SHALL display it without using it to accept, reject, select, or install any item

#### Scenario: Unknown optional field is read
- **WHEN** TriOS reads a known format containing an unknown optional field
- **THEN** it SHALL preserve that field through comparison, editing, link generation, and file export

#### Scenario: Unknown definition format is read
- **WHEN** TriOS reads an unsupported format version
- **THEN** it SHALL ask the person to update TriOS and SHALL NOT edit, install, or reshare the definition

### Requirement: Modpack identity and versioning
TriOS SHALL allocate a pack ID when a new draft is created. New packs and
copies SHALL start at version 1. Saving changed shared content SHALL increment
the version once. Draft autosaves, no-op saves, Copy link, Export, and Publish
SHALL NOT increment it.

#### Scenario: Shared content changes
- **WHEN** the person saves changed metadata, items, item order, statuses, notes, sources, or preserved unknown fields
- **THEN** TriOS SHALL increment the saved pack version once

#### Scenario: Existing pack is copied
- **WHEN** the person chooses Duplicate, Add as a copy, or Save as a new modpack
- **THEN** TriOS SHALL assign a new pack ID and set the copy's version to 1

### Requirement: Drafts remain separate from saved packs
TriOS SHALL autosave one draft per pack ID. A draft MAY be empty or invalid and
SHALL remain separate from the last committed definition. The library SHALL
show draft-only packs and saved packs with unsaved changes.

#### Scenario: Person leaves an editor
- **WHEN** the person edits a pack and uses Back without saving
- **THEN** TriOS SHALL keep the draft without prompting and SHALL keep normal library actions on the committed definition

#### Scenario: Person discards a saved pack's draft
- **WHEN** the person chooses Discard changes
- **THEN** TriOS SHALL restore the committed definition

#### Scenario: Person discards a draft-only pack
- **WHEN** the person chooses Discard changes for a pack that has never been committed
- **THEN** TriOS SHALL remove that draft

#### Scenario: Draft is invalid
- **WHEN** a draft is empty or has invalid fields or sources
- **THEN** TriOS SHALL keep autosaving it locally while disabling commit and sharing actions

### Requirement: Modpack storage
One modpack store SHALL own saved definitions, drafts, local update data,
last-export data, and per-item install failures in one modpacks.json file.
Only that store SHALL assign IDs or versions and commit, copy, replace, or
delete packs. Installed coverage and current installation state SHALL be
calculated rather than saved.

#### Scenario: Modpack storage is corrupt
- **WHEN** TriOS cannot read modpacks.json
- **THEN** it SHALL preserve the backup and offer to restore it or start with an empty library instead of silently replacing the file

### Requirement: Deterministic link and file transport
TriOS SHALL encode shared definitions as UTF-8 JSON with fixed known-field
ordering, sorted unknown object keys, and preserved item order. Links SHALL use
zlib deflate, unpadded base64url, and a separate 1. transport prefix. Files
SHALL use readable JSON or Hjson and the .trios-modpack extension.

TriOS SHALL reject links longer than 30,000 characters, expanded definitions
over 4 MiB, definitions over 5,000 items, excessive nesting or string lengths,
mixed single-mod and modpack links, and malformed numeric versions.

#### Scenario: Equal definitions are encoded
- **WHEN** two parsed definitions contain the same known and preserved unknown data
- **THEN** TriOS SHALL produce the same canonical payload while retaining manual item order

#### Scenario: Link is too large
- **WHEN** an outgoing link exceeds 30,000 characters
- **THEN** TriOS SHALL suggest shortening descriptions or notes, removing items, or exporting a .trios-modpack file

### Requirement: Incoming definitions are untrusted
Links, dropped files, and operating-system file opens SHALL use one incoming
handler and one codec. TriOS SHALL show the embedded definition without saving,
installing, or contacting its update URL. It MAY check that URL only after the
person asks, adds or accepts the pack, or starts installation.

TriOS SHALL block loopback, private, and link-local network targets for update
and item addresses, recheck every redirect target, and enforce response-size
and timeout limits.

#### Scenario: Incoming update check finishes late
- **WHEN** an add or installation has already started from the embedded definition
- **THEN** a later online result SHALL NOT replace the definition used by that action

#### Scenario: Incoming definition conflicts with saved work
- **WHEN** an incoming definition shares an ID with a different saved definition or draft
- **THEN** TriOS SHALL show a comparison and require an explicit replace, copy, discard-draft, or cancel choice as appropriate

#### Scenario: Incoming definition is identical
- **WHEN** its ID and exact definition match saved data
- **THEN** TriOS SHALL open the existing saved pack or draft instead of making a duplicate

### Requirement: Online updates are complete definitions
TriOS SHALL compare saved packs with their update URLs in the background and on
manual refresh. It SHALL persist the complete last successful online
definition and timestamp and retain them after a failed check. Accepting an
update SHALL replace the definition as a whole and SHALL NOT merge fields.

#### Scenario: Update uses another pack ID
- **WHEN** an update URL returns a definition with another ID
- **THEN** TriOS SHALL treat it as a broken update, refuse replacement, and MAY offer to add it as a separate pack

#### Scenario: Saved pack has a draft
- **WHEN** an update is available while unsaved changes exist
- **THEN** TriOS SHALL require the person to commit, copy, or discard the draft before accepting the update

#### Scenario: Saved update is reviewed
- **WHEN** the person chooses Review update
- **THEN** TriOS SHALL show a dialog over the full pack page with pack information changes and Added, Removed, and Changed item groups

### Requirement: Item sources are validated before sharing
TriOS SHALL validate every item source before Copy link, Export, or Publish
finishes. It SHALL show the checks in a new section on the pack page, allow
cancellation, show failures and repair actions, and finish the requested action
automatically when all checks pass. Successful checks MAY be reused for 60
minutes while the exact address and source type remain unchanged.

#### Scenario: Draft source preference changes
- **WHEN** the creator changes an item's source in a draft
- **THEN** TriOS SHALL NOT change the mod's preferred share source until the draft is committed

#### Scenario: Catalog recovery succeeds
- **WHEN** installation succeeds through an explicitly chosen catalog recovery
- **THEN** TriOS SHALL update the normal mod record immediately without editing or versioning the pack

### Requirement: Modpacks library follows modern page patterns
TriOS SHALL provide a first-class Modpacks page using the same keep-alive page,
Riverpod controller, current and persisted page state, toolbar, smart search,
filter, and adaptive-card patterns as modern TriOS viewer pages. It SHALL NOT
add a navigation update counter in this change.

Cards SHALL mix saved and draft-only packs and show name, author, pack and game
versions, installed/total count, and applicable Draft, Unsaved changes, Update
available, Failed, and Installing labels. Hover details SHALL include the
description, homepage, update URL, and installed/missing counts, but not source
problems, failed installs, last-check time, or item-status counts.

#### Scenario: Draft-only card is opened
- **WHEN** the person clicks a draft-only card
- **THEN** TriOS SHALL open its editor directly

#### Scenario: Saved card is opened
- **WHEN** the person clicks a saved card
- **THEN** TriOS SHALL open its full pack page

#### Scenario: Installation is running
- **WHEN** a pack has a current installation
- **THEN** its card SHALL move ahead of normal sorting and show progress and Stop

#### Scenario: Library has no packs
- **WHEN** the library is empty
- **THEN** TriOS SHALL show New modpack and Import modpack actions

#### Scenario: Search or filters hide every pack
- **WHEN** no cards match the current search and filters
- **THEN** TriOS SHALL offer Clear search and Clear filters

### Requirement: Full pack page
The full page SHALL place Back, Edit, Copy link, Export, Install, and overflow
at the top in that order. Delete and Duplicate SHALL be in overflow. All pack
information SHALL appear in one compact read-only block.

The item grid SHALL default to icon, name, author, status, installed state,
combined installed/recorded version, and dependency warnings. It SHALL support
other normal mod columns, read-only sorting with manual pack order as the
default, multiple expanded items, and Expand all and Collapse all.

### Requirement: Modpack editor
The editor SHALL always keep the person's mods on the left and pack items on
the right, regardless of window size. Pack fields SHALL appear above the lists
as Settings-style text fields when editable and compact read-only values when
collapsed. New and invalid packs SHALL start expanded; valid saved packs SHALL
start collapsed.

The left grid SHALL show one row per mod ID, preferring the active variant and
then the highest installed version, and SHALL support the normal Mod Manager
columns with independent defaults. The right grid SHALL use manual ordering
only, support drag handles, controlled checkbox selection, Add/Remove selected,
bulk Set status, multiple expanded items, and separate search for each side.

#### Scenario: Custom status is entered
- **WHEN** the creator enters a single-line custom status of 40 characters or fewer
- **THEN** TriOS SHALL trim it, reject blank or control-character values, recognize standard labels case-insensitively, and preserve custom capitalization

### Requirement: Dependencies remain advisory
TriOS SHALL show required dependencies missing from the pack and MAY offer to
add them after explicit confirmation. It SHALL recompute warnings before
installation. Cycles, conflicts, missing dependencies, and removing a depended-
on item SHALL NOT invalidate the pack or force an item into installation.
TriOS SHALL NOT automatically add a fuzzy or catalog match.

### Requirement: Selective background installation
Installing SHALL first save, replace, or copy the pack into the library.
Preparation SHALL produce a selectable plan; the installer SHALL accept only a
saved library entry and the confirmed selection.

The confirmation dialog SHALL show a checkable table in pack order with icon,
name, status, source, note indicator, installed state, version, and dependency
warnings. Missing installable items SHALL be selected by default. Installed
items SHALL remain visible and unselected. Every item, including one labelled
Required, MAY be unchecked.

After starting, the dialog SHALL show live progress with Close and Stop.
Closing SHALL leave installation running, keep TriOS usable, and show the same
progress on the Modpacks page. More than one pack MAY install at once, but the
same pack SHALL NOT start twice.

#### Scenario: Person stops an installation
- **WHEN** the person chooses Stop
- **THEN** active operations SHALL finish safely, no new operations SHALL start, completed installs SHALL remain, automatic enabling SHALL not run, and a later Install action SHALL create a fresh attempt

#### Scenario: TriOS restarts during or after a partial installation
- **WHEN** the person later chooses Install for that saved pack
- **THEN** TriOS SHALL build a new plan from the saved definition and current mod list rather than restore an old job

### Requirement: Shared installation limits
All modpack installations SHALL share a fair global scheduler limited to two
downloads and the configured one-through-six concurrent extraction/install
operations. Existing download and archive-install behavior SHALL be reused.

An archive SHALL contain the declared mod ID. TriOS SHALL install only selected
declared IDs, ignore and report extra mods, and fail an item whose ID is absent
or wrong. Per-item failures SHALL be keyed by item ID and source fingerprint,
cleared by success or source change, and SHALL NOT include stopped or unstarted
items.

### Requirement: Optional enabling is profile-safe
The installation dialog SHALL offer an unchecked Enable installed items after
installation option. If selected, TriOS SHALL use normal Mod Manager behavior
and dependency confirmation to enable every pack item that is installed after
the attempt, including preinstalled and newly installed items. Stop SHALL skip
this action. Modpack code SHALL never modify saved profile membership.

#### Scenario: A profile is tracked
- **WHEN** a modpack action changes the current enabled loadout
- **THEN** the current loadout SHALL become Modified and the tracked profile SHALL remain unchanged

### Requirement: TriLink uses the same format
TriOS SHALL own the modpack format description and golden examples. TriLink
SHALL use copied golden examples to decode and display the embedded pack
without a hosted pack database and without fetching its update URL.
