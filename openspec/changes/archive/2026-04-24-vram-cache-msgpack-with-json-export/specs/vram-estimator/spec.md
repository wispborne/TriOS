## ADDED Requirements

### Requirement: VRAM cache is persisted in msgpack format

The VRAM estimator SHALL persist its scan-result cache (the full `VramEstimatorManagerState`) to disk in msgpack format under the filename `TriOS-VRAM_CheckerCache.mp`, located in the TriOS cache directory. The serialized payload SHALL be produced by the same `toMap` function used for JSON serialization, so switching the on-disk format SHALL NOT change the logical cache shape or which fields round-trip.

#### Scenario: Cache is written as msgpack on scan completion
- **WHEN** a VRAM scan completes and the estimator schedules a cache write
- **THEN** the file `TriOS-VRAM_CheckerCache.mp` SHALL be created (or overwritten) in the TriOS cache directory with a msgpack-encoded payload, and no `TriOS-VRAM_CheckerCache.json` SHALL be created or modified

#### Scenario: Cache round-trips losslessly
- **WHEN** a `VramEstimatorManagerState` is serialized to msgpack and then deserialized via the manager's `fromMap`
- **THEN** the resulting state SHALL have the same `modVramInfo` keys, the same per-`VramMod` referenced and unreferenced image rows, and the same `lastUpdated` timestamp as the original, subject only to the reset of transient scan fields (`isScanning`, `isCancelled`, `currentlyScanningModName`, `totalModsToScan`, `modsScannedThisRun`) that already occurs in `fromMap`

#### Scenario: Reading an absent msgpack cache produces the initial empty state
- **WHEN** TriOS launches and no `TriOS-VRAM_CheckerCache.mp` exists in the cache directory
- **THEN** the estimator SHALL initialize with `VramEstimatorManagerState.initial()` (empty `modVramInfo`, null `lastUpdated`), matching the pre-change behavior for a missing cache

### Requirement: Legacy JSON cache is deleted on first launch after upgrade

On the first TriOS launch after upgrading past this change, the VRAM estimator SHALL delete any `TriOS-VRAM_CheckerCache.json` file and its `TriOS-VRAM_CheckerCache.json_backup.bak` sibling present in the TriOS cache directory. No attempt SHALL be made to convert the JSON contents to msgpack; the user's next scan regenerates the cache. Subsequent launches SHALL be silent no-ops when the legacy files are not present.

#### Scenario: Legacy JSON cache is removed when present
- **WHEN** TriOS launches and both `TriOS-VRAM_CheckerCache.json` and (optionally) `TriOS-VRAM_CheckerCache.json_backup.bak` exist in the TriOS cache directory
- **THEN** the estimator SHALL delete those files before performing its first read, and SHALL log a single informational line indicating the legacy cache was removed

#### Scenario: No-op when legacy files are absent
- **WHEN** TriOS launches and no `TriOS-VRAM_CheckerCache.json` or `_backup.bak` file exists in the TriOS cache directory
- **THEN** the estimator SHALL NOT attempt any deletion and SHALL NOT emit an informational line about legacy-cache removal

#### Scenario: Deletion failure does not block startup
- **WHEN** the legacy JSON file exists but cannot be deleted (for example, held open by another process)
- **THEN** the estimator SHALL log a warning, SHALL NOT rethrow, and SHALL continue with normal startup so the `.mp` cache path still works

### Requirement: User can export the VRAM cache as JSON on demand

The VRAM estimator page SHALL expose a user-triggered action that exports the current in-memory `VramEstimatorManagerState` as a pretty-printed JSON file to a user-chosen location. The action SHALL be available from the estimator's toolbar as an icon button with a tooltip that identifies its purpose. The export SHALL use the same `toMap` output that drives msgpack persistence, so the exported JSON SHALL be a faithful textual representation of what is stored in the `.mp` cache.

#### Scenario: Toolbar exposes the export action
- **WHEN** the VRAM estimator page renders
- **THEN** its toolbar SHALL include an icon button for "Export cache as JSON" with a tooltip describing the action

#### Scenario: Export writes pretty-printed JSON to the chosen path
- **WHEN** the user activates the export action, the current `modVramInfo` is non-empty, and the user selects a destination file in the save-file dialog
- **THEN** the estimator SHALL write a pretty-printed JSON document at that path whose decoded structure equals `toMap(currentState)`, and SHALL surface a confirmation (snackbar or equivalent) citing the resolved path

#### Scenario: Export matches msgpack cache semantically
- **WHEN** the user exports the cache as JSON immediately after a scan completes and the `.mp` cache has been persisted
- **THEN** decoding the exported JSON into a `Map<String, dynamic>` and decoding the `.mp` file into a `Map<String, dynamic>` via msgpack SHALL yield the same `modVramInfo` keys and the same per-`VramMod` image rows (modulo representation of scalar types, e.g., the same logical `DateTime` value in each)

#### Scenario: Export is a no-op when the cache is empty
- **WHEN** the user activates the export action and `modVramInfo` is empty (no scan has ever produced results this session, and no persisted cache was loaded)
- **THEN** the export action SHALL be disabled, OR if activated SHALL surface a brief message indicating there is nothing to export; in neither case SHALL a file be written

#### Scenario: Cancelled save dialog does not write a file
- **WHEN** the user activates the export action and cancels the save-file dialog
- **THEN** no file SHALL be written, no confirmation SHALL be shown, and no error SHALL be logged

#### Scenario: Export does not mutate the persisted cache
- **WHEN** the user exports the cache as JSON
- **THEN** the `.mp` cache file on disk SHALL NOT be created, modified, renamed, or deleted as a side effect of the export
