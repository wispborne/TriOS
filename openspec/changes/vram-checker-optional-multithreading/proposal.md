## Why

The VRAM scanner iterates over mods sequentially via `Stream.fromIterable().asyncMap()`. On large mod lists the wall-clock scan time is dominated by per-mod CPU work (JAR constant-pool parsing, `.java` string extraction, `.csv`/`.json` parsing, PNG header decoding). Most of that work is independent across mods and sits idle on a single isolate. Running several mods in parallel across an isolate pool is the biggest remaining win, but it is not universally desirable — users on low-core machines, or developers trying to profile a deterministic run, benefit from a single-threaded path. Users have asked for faster scans; rather than hard-code a concurrency model, we want an opt-in flag backed by the [`async_task`](https://pub.dev/packages/async_task) package.

## What Changes

- Add a new opt-in setting `Settings.vramEstimatorMultithreaded` (bool, default `false`) that, when enabled, runs the per-mod scan loop across an `async_task` `AsyncExecutor` isolate pool instead of the current single-isolate `asyncMap` loop.
- Add a dependency on `async_task ^1.1.2`.
- Refactor `VramChecker` so the per-mod scan body is extracted into a pure, self-contained unit that can run either (a) inline on the main isolate (existing behavior) or (b) as an `AsyncTask` on a worker isolate. Shared read-only inputs (enabled mod ids, GraphicsLib config, selector config, reference-source roots) move into serializable parameter objects; non-serializable dependencies (filesystem, logging) are reconstructed inside the worker from those parameters.
- Route per-mod progress (`onModStart`, `onFileProgress`, `modProgressOut`) through `AsyncTaskChannel` messages when running in multithreaded mode, marshaling them back to the main isolate so the existing progress-buffering and UI path is unchanged.
- Propagate cancellation into the worker pool: the existing `isCancelled()` flag is checked before dispatching each mod, and an in-flight cancellation message is sent through the channel so running tasks can short-circuit.
- Honor `maxFileHandles` globally by sizing the pool with a conservative `parallelism` value (derived from core count, capped) and by keeping the existing per-task file-handle semaphore inside each worker. The existing `withFileHandleLimit` scope is per-isolate; each worker gets its own limiter, so the effective cap becomes `maxFileHandles * parallelism`. We will document this and keep the per-isolate default low enough that the product still respects OS limits.
- Add a UI toggle for the flag in the VRAM estimator's existing debug panel (reference-scan debug panel) with a tooltip explaining the trade-off.
- Preserve exact output parity: a scan run with the flag off and a scan run with the flag on SHALL produce the same `VramEstimatorManagerState` for the same inputs, subject only to nondeterministic ordering of progress callbacks.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `vram-estimator`: adds a requirement that the scan can optionally run across an isolate pool via `async_task`, gated on `Settings.vramEstimatorMultithreaded`, with output parity guarantees, progress/cancellation plumbing across isolate boundaries, and a debug-panel toggle.

## Impact

- **Code**: `lib/vram_estimator/vram_checker_logic.dart` (largest change — per-mod scan extraction, executor wiring, channel-based progress), `lib/vram_estimator/vram_estimator_manager.dart` (reads the new setting, passes it to `VramChecker`), `lib/trios/settings/settings.dart` + `.mapper.dart` (new field), `lib/vram_estimator/widgets/scan_progress_panel.dart` or the reference-scan debug panel (new toggle), possibly a small serializable-parameters file under `lib/vram_estimator/`.
- **Dependencies**: adds `async_task ^1.1.2` to `pubspec.yaml`.
- **Spec**: `openspec/specs/vram-estimator/spec.md` gains a new requirement section covering the opt-in multithreading mode and its output-parity guarantee.
- **Performance**: parallel mode improves wall-clock scan time proportional to `parallelism` on CPU-bound workloads; single-isolate mode is unchanged.
- **Risk**: isolate boundaries surface any hidden non-serializable state in `VramAssetSelector` implementations — selectors must be reconstructable from a serializable config. Both existing selectors (`FolderScanSelector`, `ReferencedAssetsSelector`) already meet this bar since their configuration is already a `@MappableClass`.
- **Out of scope**: converting image-header reads inside a single mod to use `async_task` (they are already I/O-concurrent via `Future.wait`), rewriting the existing `AppWorker` pool to use `async_task`, and changing the default flag value.
