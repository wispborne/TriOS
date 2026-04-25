## 1. Dependency and settings scaffolding

- [ ] 1.1 Add `async_task: ^1.1.2` to `pubspec.yaml` under `dependencies` and run `flutter pub get`
- [ ] 1.2 Add `final bool vramEstimatorMultithreaded` field to `lib/trios/settings/settings.dart` with default `false` in the constructor (placed alongside the other `vramEstimator*` fields, around line 165 / 261)
- [ ] 1.3 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `settings.mapper.dart`
- [ ] 1.4 Verify `SafeDecodeHook` path: load a settings file that lacks the new key and confirm it decodes with the default `false`

## 2. Selector registry

- [ ] 2.1 Add a top-level `VramAssetSelector.fromId(String id, Object? config)` factory function in `lib/vram_estimator/selectors/vram_asset_selector.dart` (or a new `selector_registry.dart` next to it)
- [ ] 2.2 Wire `FolderScanSelector` (`id == 'folder-scan'`, no config) into the registry
- [ ] 2.3 Wire `ReferencedAssetsSelector` (`id == 'referenced-assets'`, `ReferencedAssetsSelectorConfig`) into the registry
- [ ] 2.4 Confirm `ReferencedAssetsSelectorConfig` is a `@MappableClass` and round-trips through `.toMap` / `fromMap` without loss (it already is per the existing spec; verify)
- [ ] 2.5 Add a short unit test covering `fromId` for both selectors, including the unknown-id fallback behavior documented in the existing spec

## 3. Extract the per-mod scan body

- [ ] 3.1 Define a new top-level serializable `VramCheckScanParams` class under `lib/vram_estimator/` (`@MappableClass` with `DirectoryHook` as needed): mod path, mod info, enabled mod ids list, selector id, selector config (as `Object?`), `GraphicsLibConfig`, feature flags (`showGfxLibDebugOutput`, `showPerformance`, `showSkippedFiles`, `showCountedFiles`), `maxFileHandles`
- [ ] 3.2 Define a `VramScanOutcome` return type carrying either `VramMod` or a `(modId, errorMessage, stackString)` failure, plus a captured per-mod log `StringBuffer` string
- [ ] 3.3 Extract the current `asyncMap(...)` closure body in `lib/vram_estimator/vram_checker_logic.dart` (lines ~123–320) into a top-level function `Future<VramScanOutcome> scanOneMod(VramCheckScanParams params, { AsyncTaskChannel? channel, ReadImageHeaders? imageReaderPool })`
- [ ] 3.4 Inside `scanOneMod`, reconstruct the selector via `VramAssetSelector.fromId(params.selectorId, params.selectorConfig)`; build a local `StringBuffer` and route per-mod `verboseOut`/`debugOut` into it; invoke progress via `channel?.send(...)` when `channel` is non-null, otherwise fall through to locally-held callbacks for the single-isolate path
- [ ] 3.5 Refactor the single-threaded `VramChecker.check()` path to drive its per-mod iteration through `scanOneMod(...)` (without a channel); confirm behavior unchanged by running `test/vram_estimator/vram_estimator_manager_test.dart` and a manual scan of a known mod list
- [ ] 3.6 Confirm no user-facing behavior or cache format change at this checkpoint (pure refactor landing)

## 4. Multithreaded execution path

- [ ] 4.1 Define an `AsyncTask<VramCheckScanParams, VramScanOutcome>` subclass `VramScanTask` whose `run()` calls `scanOneMod(parameters, channel: channelResolver(...))`; register it with the executor's `taskTypeRegister`
- [ ] 4.2 In `VramChecker.check()`, branch on `multithreaded` (new constructor field, passed from the notifier): if `false` or `variantsToCheck.length < 2`, take the single-isolate path from task 3.5; otherwise construct an `AsyncExecutor` with `parallelism = max(1, min(Platform.numberOfProcessors - 1, 4))`, `taskTypeRegister` wired to `VramScanTask`
- [ ] 4.3 Wrap immutable shared inputs (`GraphicsLibConfig`, `enabledModIds`) in `SharedData` so the executor copies them once per worker
- [ ] 4.4 Dispatch tasks via `executor.execute(task)`; for each task, open its channel and in parallel `await channel.waitMessage()` loop forwards progress messages to `onFileProgress` / `onModStart` on the main isolate; on task completion, invoke `modProgressOut(outcome.mod)` on the main isolate exactly once
- [ ] 4.5 Replay the task's captured log `StringBuffer` into `verboseOut` / `debugOut` after the task completes so log ordering remains per-mod-atomic
- [ ] 4.6 Shut down the `AsyncExecutor` in a `finally` block; confirm no dangling isolates via `Platform.isWindows` smoke test (look at Task Manager / `ps`)

## 5. Cancellation

- [ ] 5.1 Before dispatching each task in the pooled path, check `isCancelled()`; if true, stop submitting new tasks and break out of the loop
- [ ] 5.2 Propagate cancellation in-flight by sending a `"cancel"` message on the task's channel when `isCancelled()` first flips to true; poll for it in `scanOneMod` at the same phase boundaries the single-threaded path already checks (between enumeration, GraphicsLib parse, selector invocation, and header reads)
- [ ] 5.3 Ensure a cancelled task rethrows the same `Exception("Cancelled")` the single-threaded path throws, and that `check()` discards cancelled-task outcomes from the returned mod list
- [ ] 5.4 Confirm `finally`-block executor shutdown runs on both the cancel and the error paths

## 6. Per-task error isolation

- [ ] 6.1 In `scanOneMod`, wrap the body in `try`/`catch`; on failure return `VramScanOutcome.failed(modId, message, stack)` instead of throwing
- [ ] 6.2 In the main-isolate dispatcher, on a failed outcome: log via `Fimber.e` with mod id + stack, continue processing remaining mods, and leave the failed mod out of the returned `modVramInfo` map
- [ ] 6.3 Add a targeted test feeding a mod variant that triggers a worker exception (e.g., a variant whose path does not exist) and asserting the remaining mods still complete

## 7. Notifier / manager wiring

- [ ] 7.1 In `lib/vram_estimator/vram_estimator_manager.dart`, read `appSettings.vramEstimatorMultithreaded` inside `startEstimating()` and pass it into `VramChecker(...)` as a new constructor field
- [ ] 7.2 Confirm no change to `VramEstimatorManagerState` on-disk shape and that the msgpack cache still round-trips (existing `unit test` covers this)

## 8. UI toggle

- [ ] 8.1 Add a toggle control for `vramEstimatorMultithreaded` inside the existing debug panel used by the VRAM estimator page (see `lib/vram_estimator/vram_estimator_page.dart` around the debug panel render at ~line 345)
- [ ] 8.2 Render the toggle regardless of active selector (it is selector-independent), with a tooltip explaining the trade-off (faster scans vs. higher CPU and file-handle pressure)
- [ ] 8.3 Wire the toggle's `onChanged` to update `Settings` via the existing settings notifier pattern; confirm the new value is persisted and read back after a restart
- [ ] 8.4 Verify the toggle does NOT invalidate cached scan results (flipping it mid-session leaves displayed totals intact until the next explicit scan)

## 9. Verification

- [ ] 9.1 Run `dart analyze` and resolve any issues introduced by the new code
- [ ] 9.2 Run `dart run build_runner build --delete-conflicting-outputs` one more time to regenerate any mappers touched by new `@MappableClass` types
- [ ] 9.3 Add a parity test in `test/vram_estimator/` that runs `scanOneMod` against a fixture mod layout twice (once via the main-isolate path, once via the executor path) and asserts `modVramInfo` equality in the sense defined by the spec (set-equal rows per bucket)
- [ ] 9.4 Manual scan of the local mod folder with the flag OFF, then ON; visually confirm same per-mod totals in the UI, faster wall-clock time with flag ON on a mod list of 10+ variants
- [ ] 9.5 Manual cancel test: start a multithreaded scan, cancel mid-scan; confirm UI dismisses, no orphaned isolates remain (check Task Manager on Windows)
- [ ] 9.6 Manual failure-isolation test: temporarily point one mod variant to a bogus path; confirm scan completes for the other variants with a logged error for the bad one

## 10. Spec update

- [ ] 10.1 Merge the delta requirements from `openspec/changes/vram-checker-optional-multithreading/specs/vram-estimator/spec.md` into `openspec/specs/vram-estimator/spec.md` via the standard archive step when this change is archived
