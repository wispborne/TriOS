## ADDED Requirements

### Requirement: VRAM scan can run across an isolate pool via async_task

The VRAM estimator SHALL accept an opt-in flag `Settings.vramEstimatorMultithreaded` that, when `true`, executes the per-mod scan body across an `async_task` `AsyncExecutor` isolate pool instead of the current single-isolate sequential `asyncMap` loop. When the flag is `false` (the default), the estimator SHALL use the pre-existing single-isolate code path with no executor, no isolate spawn, and no dependency on `async_task` at runtime.

The flag SHALL be persisted in `Settings`, default to `false` for new installs and for existing installs loading pre-change settings files, and SHALL be changeable at runtime without restarting the app. Changing the flag SHALL NOT invalidate cached scan results.

The multithreaded path SHALL use a worker pool sized at `min(Platform.numberOfProcessors - 1, 4)` with a floor of 1.

#### Scenario: Default behavior is unchanged when the flag is off
- **WHEN** `Settings.vramEstimatorMultithreaded` is `false` and a VRAM scan is started
- **THEN** the estimator SHALL execute every mod on the main isolate using the pre-change sequential `asyncMap` pipeline, and SHALL NOT instantiate any `AsyncExecutor` or spawn worker isolates for the scan

#### Scenario: Flag enables the pooled execution path
- **WHEN** `Settings.vramEstimatorMultithreaded` is `true` and a scan runs on a mod list with 2 or more variants
- **THEN** the estimator SHALL instantiate an `AsyncExecutor` with `parallelism = min(numberOfProcessors - 1, 4)` (minimum 1), SHALL dispatch per-mod scan tasks to it, and SHALL close the executor before `check()` returns or throws

#### Scenario: Single-variant scan bypasses the executor even when the flag is on
- **WHEN** `Settings.vramEstimatorMultithreaded` is `true` and `variantsToCheck.length < 2`
- **THEN** the estimator SHALL run the scan on the main isolate without instantiating an `AsyncExecutor`, because isolate spawn cost exceeds any benefit for a single mod

#### Scenario: Flag persists across app restarts
- **WHEN** the user enables multithreading, closes the app, and relaunches
- **THEN** `Settings.vramEstimatorMultithreaded` SHALL read back as `true` and the next scan SHALL use the pooled path

#### Scenario: Missing field in older settings files defaults to false
- **WHEN** a settings file written before this change is loaded (with no `vramEstimatorMultithreaded` key)
- **THEN** the estimator SHALL treat the flag as `false` and SHALL NOT fail to load the settings

### Requirement: Multithreaded and single-threaded scans produce the same logical result

For the same inputs (mod list, selector id, selector config, `GraphicsLibConfig`, flag states), a scan run with `vramEstimatorMultithreaded == false` and a scan run with `vramEstimatorMultithreaded == true` SHALL produce the same `VramEstimatorManagerState.modVramInfo` map: the same set of mod-id keys, and for each key a `VramMod` with the same referenced image rows (as sets) and the same unreferenced image rows (as sets, or both `null`). Iteration order of rows within a table and ordering of log lines across mods are not part of this parity guarantee.

#### Scenario: Output parity for folder-scan mode
- **WHEN** a fixed mod list is scanned once with `vramEstimatorMultithreaded == false` and once with `vramEstimatorMultithreaded == true`, both with `FolderScanSelector`
- **THEN** the two resulting `modVramInfo` maps SHALL have the same keys, and for each key the `images` table rows SHALL be equal as sets and `unreferencedImages` SHALL be `null` in both

#### Scenario: Output parity for reference mode
- **WHEN** a fixed mod list is scanned twice under `ReferencedAssetsSelector` with identical `ReferencedAssetsSelectorConfig`, once with the flag off and once with the flag on
- **THEN** the two resulting `modVramInfo` maps SHALL have the same keys, and for each key both `images` and `unreferencedImages` SHALL be equal as sets

### Requirement: Per-mod scan logic is reconstructable inside an isolate

The per-mod scan body SHALL be encapsulated in a pure, top-level function that takes a serializable parameter object (`VramCheckScanParams`) and is callable both on the main isolate (single-threaded mode) and inside an `async_task` worker (multithreaded mode). The single-threaded mode SHALL call this same function; both modes SHALL NOT duplicate scan logic.

Selectors SHALL be reconstructable inside a worker from a `(selectorId, selectorConfig)` pair via a `VramAssetSelector.fromId` registry. Every selector registered today (`FolderScanSelector`, `ReferencedAssetsSelector`) SHALL be reachable through this registry, and adding a new selector SHALL require registering it there.

#### Scenario: Registry reconstructs FolderScanSelector
- **WHEN** `VramAssetSelector.fromId('folder-scan', null)` is called
- **THEN** it SHALL return a `FolderScanSelector` instance functionally equivalent to one constructed directly

#### Scenario: Registry reconstructs ReferencedAssetsSelector with config
- **WHEN** `VramAssetSelector.fromId('referenced-assets', config)` is called with a valid `ReferencedAssetsSelectorConfig`
- **THEN** it SHALL return a `ReferencedAssetsSelector` whose behavior is identical to one constructed with that config directly

#### Scenario: Both modes share one scan body
- **WHEN** code coverage is examined for the per-mod scan body after both a single-threaded and a multithreaded run
- **THEN** both runs SHALL have entered the same top-level scan function; the single-threaded path SHALL NOT carry its own duplicate copy of the per-mod logic

### Requirement: Progress and cancellation flow correctly through isolate boundaries

In multithreaded mode, the estimator SHALL deliver `onModStart`, `onFileProgress`, and `modProgressOut` callbacks to the main isolate with the same shape and cardinality as the single-threaded path: `onModStart` fires exactly once per mod, `onFileProgress` fires at least once with `(0, total, null)` at the start of each mod and once per completed asset thereafter, and `modProgressOut` fires exactly once per mod with the final `VramMod` result. Per-asset progress SHALL be delivered via `AsyncTaskChannel`. The main isolate SHALL invoke the callbacks on itself, preserving the existing Riverpod buffering and flushing behavior.

The `isCancelled()` predicate SHALL be honored at two points: (a) before each task is dispatched to the executor (no further tasks submitted after cancel), and (b) inside the worker via a channel cancel-message poll at the same phase boundaries the single-threaded path already checks (`isCancelled()` between enumeration, GraphicsLib parse, selector invocation, and header reads).

#### Scenario: Cancellation before dispatch stops the scan
- **WHEN** the user cancels while earlier mods are still scanning in multithreaded mode
- **THEN** the estimator SHALL NOT submit any additional mod tasks to the executor after the cancel is observed

#### Scenario: In-flight tasks observe cancellation
- **WHEN** the user cancels while a task is actively scanning a mod in multithreaded mode
- **THEN** that worker SHALL, at its next `isCancelled` poll point, abort with the same `"Cancelled"` exception the single-threaded path throws; the main isolate SHALL discard that task's result

#### Scenario: Progress callbacks fire on the main isolate
- **WHEN** a mod scan completes in multithreaded mode
- **THEN** `modProgressOut(mod)` SHALL be invoked on the main isolate (so Riverpod state updates work without cross-isolate synchronization) exactly once for that mod

### Requirement: Multithreaded mode exposes a debug-panel toggle

The VRAM estimator page SHALL render a toggle for `Settings.vramEstimatorMultithreaded` in its debug panel. The toggle SHALL have a tooltip that briefly describes the trade-off (faster scans vs. higher CPU and file-handle pressure). Changing the toggle SHALL update `Settings` immediately; the new value SHALL take effect on the next scan.

#### Scenario: Toggle is visible in the debug panel
- **WHEN** the VRAM estimator page's debug panel is rendered
- **THEN** the panel SHALL include a labeled control for "Multithreaded scanning" (or equivalent) with a tooltip

#### Scenario: Toggle writes through to settings
- **WHEN** the user flips the toggle
- **THEN** `Settings.vramEstimatorMultithreaded` SHALL be updated and persisted, and the next invocation of `startEstimating` SHALL read the new value

#### Scenario: Toggle does not invalidate cached scan results
- **WHEN** the user flips the toggle between scans
- **THEN** the estimator SHALL NOT clear any cached `VramMod` results; cached results SHALL remain displayed until the user triggers a new scan

### Requirement: Worker errors propagate with usable diagnostics

When a worker task throws or the executor fails, the estimator SHALL surface the error on the main isolate with a message that identifies the failing mod and includes the worker-side stack (or a textual capture thereof). A single failing mod SHALL NOT abort the entire scan; the estimator SHALL record the failure, continue processing remaining mods, and leave the failed mod out of the resulting `modVramInfo` map, matching the robustness the single-threaded path already provides for per-mod exceptions.

#### Scenario: Worker exception does not abort the scan
- **WHEN** a task for mod `X` throws inside a worker during a multi-mod scan
- **THEN** the estimator SHALL log the error with mod `X`'s id and stack, SHALL continue processing remaining mods, and the final `modVramInfo` SHALL contain entries for every mod whose task succeeded

#### Scenario: Executor teardown on cancellation or completion
- **WHEN** a multithreaded scan completes (successfully, via cancellation, or via executor-level failure)
- **THEN** the `AsyncExecutor` instance created for that scan SHALL be shut down before `check()` returns control, so worker isolates do not leak
