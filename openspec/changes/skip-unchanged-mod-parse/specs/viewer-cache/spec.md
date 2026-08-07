# Viewer Cache — skipping unchanged mods

Adds to the existing `viewer-cache` capability. Everything already specified there still holds; this only adds a way to skip work.

## ADDED Requirements

### Requirement: Parsers record the files they read

A domain's `parseVanilla` and `parseVariant` SHALL record every directory they list and every file they read, through a recorder the base class hands them. Exception: the graphics index does not record. Its scan reads no files — it is itself a recursive listing of `graphics/` — so a fingerprint check would repeat the same walk and save nearly nothing while storing a near-copy of the payload. It keeps its full scan every launch.

The recorder collects:

- **Directories** — the path relative to the source folder, and the sorted names of every entry the listing returned, including entries the parse then ignored.
- **Files** — the path relative to the source folder, and the file's last-modified time in milliseconds since epoch.

A directory that was listed recursively SHALL be recorded with every entry from the whole walk, nested paths included, so a file added inside an existing subfolder still changes the fingerprint.

A directory that was listed and found absent SHALL be recorded with an empty entry list, so its later creation is noticed.

Paths SHALL be stored relative to the source folder and with forward slashes, so a mod folder that moves does not invalidate its own cache.

#### Scenario: A parse records what it touched

- **GIVEN** the ships parse lists `data/hulls`, `data/hulls/skins` and `data/variants` for a mod
- **AND** reads `ship_data.csv`, twelve `.ship` files and three `.variant` files
- **WHEN** the parse finishes
- **THEN** the recorder holds three directories with their full entry name lists
- **AND** sixteen files with their last-modified times

#### Scenario: A file added in a nested subfolder is noticed

- **GIVEN** a mod's skins live in `data/hulls/skins/lowtech/`, listed as part of the recursive `data/hulls/skins` walk
- **AND** the user adds a new `.skin` file to `data/hulls/skins/lowtech/`
- **WHEN** the fingerprint is checked on the next launch
- **THEN** the recorded entries for `data/hulls/skins` no longer match
- **AND** `parseVariant` runs

#### Scenario: An absent directory is still recorded

- **GIVEN** a mod has no `data/hulls/skins` folder
- **WHEN** the ships parse checks for it
- **THEN** `data/hulls/skins` is recorded with an empty entry list

### Requirement: The fingerprint is stored in the cache envelope

The recorded directories and files SHALL be written into the cache envelope as an optional `fingerprint` field, next to the existing `schemaVersion`, `smolId` and `payload`.

The field MUST be optional in both directions. An envelope written before this change has no `fingerprint` and MUST still decode. An envelope carrying a `fingerprint` MUST still decode in a TriOS build that does not know the field.

Adding the field MUST NOT require a `schemaVersion` bump, because it changes nothing about how the payload is read.

#### Scenario: A cache file from an older TriOS still loads

- **GIVEN** a cache file written before this change, with no `fingerprint`
- **WHEN** the cache is loaded
- **THEN** the payload is served as a cache hit, exactly as today
- **AND** the variant is treated as needing a fresh parse
- **AND** the fresh parse writes a fingerprint for next time

### Requirement: An unchanged mod is not re-parsed

Before calling `parseVariant` or `parseVanilla` for a source in Phase 2, the base class SHALL check the fingerprint that came with that source's cached payload. The parse SHALL be skipped when all of these hold:

- A cached payload was loaded for that source in Phase 1.
- That payload carried a fingerprint.
- Every recorded directory re-lists to the same set of entry names.
- Every recorded file still exists and reports the same last-modified time.

When the parse is skipped, the source's cached slice stays in place, no cache write is queued, and the source counts as unchanged for the purpose of deciding whether to push a rebuilt list.

When any check fails, the parse runs as it does today.

#### Scenario: Nothing changed since last launch

- **GIVEN** a mod's ships cache carries a fingerprint
- **AND** none of its recorded files or directories have changed
- **WHEN** Phase 2 reaches that mod
- **THEN** `parseVariant` is not called for it
- **AND** its cached slice is kept unchanged
- **AND** no cache write is queued for it

#### Scenario: A modder edits a ship file in place

- **GIVEN** a mod's ships cache carries a fingerprint
- **AND** the user has edited `data/hulls/atlas.ship`, changing its last-modified time
- **WHEN** Phase 2 reaches that mod
- **THEN** `parseVariant` runs
- **AND** the fresh payload and a new fingerprint are written to the cache

#### Scenario: A modder adds a new ship file

- **GIVEN** a mod's ships cache carries a fingerprint recorded when `data/hulls` held twelve entries
- **AND** the user has added a thirteenth `.ship` file
- **WHEN** Phase 2 reaches that mod
- **THEN** the directory entry names no longer match
- **AND** `parseVariant` runs

#### Scenario: A recorded file is deleted

- **GIVEN** a mod's ships cache records `data/hulls/atlas.ship`
- **AND** the user has deleted it
- **WHEN** Phase 2 reaches that mod
- **THEN** the missing file fails the check
- **AND** `parseVariant` runs

### Requirement: Refresh forces a full re-parse

The refresh button on a viewer SHALL cause the next build to ignore every fingerprint and parse every source. This is the user's answer when a viewer looks stale for any reason, including one this check cannot detect.

The request SHALL survive a build that is superseded before finishing: it is cleared only when a forced build completes its full scan, so the build that replaces a superseded one still parses everything.

Pruning MUST still run after a forced build, as it does after any full scan.

#### Scenario: Refresh ignores fingerprints

- **GIVEN** every mod's fingerprint currently matches
- **WHEN** the user presses refresh on the ships viewer
- **THEN** every mod is parsed fresh
- **AND** fingerprints are rewritten from that parse

### Requirement: A parser that starts reading new files bumps its schema version

The fingerprint records what a parse read last time, not what it would read now. If a domain's parse changes to read files it did not read before, the stored fingerprints no longer describe it, and an unchanged mod could be skipped when it should be re-read.

A change to which files a domain's parse reads SHALL be accompanied by a `schemaVersion` bump for that domain, which discards every cached fingerprint along with the payloads.

#### Scenario: A new file type is added to a parse

- **GIVEN** the ships parse is changed to also read `data/config/ship_roles.json`
- **WHEN** that change ships
- **THEN** the ships `schemaVersion` is bumped in the same change
- **AND** every cached ships payload is treated as a miss on first launch
