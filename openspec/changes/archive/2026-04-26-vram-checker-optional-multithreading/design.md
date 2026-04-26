## Context

`VramChecker.check()` runs a single async pipeline on the main isolate:

1. `Stream.fromIterable(variantsToCheck).asyncMap(processOneMod)` — **one mod at a time**, sequentially.
2. Per mod: enumerate files (`Directory.list(recursive: true)`), parse GraphicsLib CSV, run the selector, read PNG headers concurrently (`Future.wait`), compute VRAM bytes, emit result.

The two existing selectors (`FolderScanSelector`, `ReferencedAssetsSelector`) bundle the heaviest CPU work: the referenced-assets path parses `.jar` constant pools, loose `.java` source, `data/config/*.json`, `.ship`/`.wpn`/`.faction` JSON, multiple CSVs, and `settings.json`. For any mod of meaningful size, these are CPU-bound and fully independent across mods. `jar_string_references.dart` already fires a per-mod `Isolate.run()` for the single JAR pass — but that buys one dimension of parallelism per mod, not parallelism **across** mods.

Progress flows back to the UI through three callbacks (`onModStart`, `onFileProgress`, `modProgressOut`) and a user-visible log stream (`verboseOut`, `debugOut`). The Riverpod notifier buffers these and flushes every 250 ms. Cancellation is a polled bool function.

The request is to make the per-mod loop optionally run across an isolate pool via `async_task` ^1.1.2, behind a user-visible flag.

## Goals / Non-Goals

**Goals:**
- Opt-in flag `Settings.vramEstimatorMultithreaded` (default `false`) that routes the per-mod loop across an `async_task` `AsyncExecutor`.
- Exact output parity between single-threaded and multithreaded modes for the same inputs (`modVramInfo` map equality, ignoring ordering nondeterminism in log/progress streams).
- Progress and cancellation continue to flow to the UI with the same shape the notifier already consumes.
- A clear kill switch: if `async_task` misbehaves or isolates explode, setting the flag back to `false` restores today's exact code path.

**Non-Goals:**
- Parallelizing image-header reads *within* a single mod (already I/O-concurrent via `Future.wait`; moving them to isolates adds serialization cost without a clear win).
- Replacing `AppWorker` (the existing single-isolate pool) — unrelated and separately queued.
- Changing the default to multithreaded in this change. Ship it off by default, gather real-world numbers, flip later in a separate change if warranted.
- Changing any selector's semantics or output shape.
- Parallelizing the `ReferencedAssetsSelector` parser list (each parser within a mod) — an orthogonal optimization worth a separate change.

## Decisions

### Decision: Use `async_task`'s `AsyncExecutor` with `parallelism = min(corecount - 1, 4)`

`async_task` transparently uses `dart:isolate` on native platforms. We instantiate one `AsyncExecutor` per `VramChecker.check()` call and shut it down in a `finally` block.

**Parallelism cap rationale**: The VRAM scan is CPU-bound during selector work and I/O-bound during header reads. `maxFileHandles = 2000` is a per-isolate limit; stacking isolates multiplies the effective OS file-handle pressure. Capping at 4 keeps us well under OS limits on Windows/macOS/Linux even with the default handle cap and leaves room for the UI isolate. We expose the cap as a private constant initially; if users push for it we can surface a setting later.

**Alternatives considered:**
- **Reuse `AppWorker`** — it's a single-isolate queue, not a pool; serializing mods through it would give no parallelism.
- **Raw `Isolate.spawn` + SendPort plumbing** — we'd reinvent `async_task`'s executor, channel, and `SharedData`. The whole point of picking this package is to skip that work.
- **`compute()` per mod** — spawns and tears down an isolate per call. For N=30+ mods this is measurably slower than a pooled executor (Flutter docs call this out). Rejected.

### Decision: Split the per-mod closure into a pure top-level function

The current `asyncMap` body closes over `this.progressText`, `this.selector`, `this.onFileProgress`, and more. None of that crosses an isolate boundary cleanly. We extract it into a top-level `_scanOneMod(VramCheckScanParams params, AsyncTaskChannel? channel)` function:

- `VramCheckScanParams` is a plain-data struct (`@MappableClass` for safety even though `async_task` handles primitives fine): enabled mod ids for this variant, mod path, selector id + its serializable config, `GraphicsLibConfig`, feature flags (`showPerformance`, `showCountedFiles`, `showSkippedFiles`, `showGfxLibDebugOutput`), `maxFileHandles`, and a cancel token.
- The selector is **reconstructed inside the worker** from `(selectorId, selectorConfig)`. Both existing selectors already have serializable config (`ReferencedAssetsSelectorConfig` is `@MappableClass`; `FolderScanSelector` is stateless). A new registry function `VramAssetSelector.fromId(id, config)` lives next to the selectors.
- Logging inside the worker writes to a local `StringBuffer`; the buffer is returned alongside the `VramMod` result and the main isolate replays it into `verboseOut`/`debugOut` in mod order after each mod completes. This preserves the log ordering users see today without serializing every `print` across an isolate boundary.

**Alternatives considered:**
- **Pass the selector instance directly as a `SharedData`** — would require making every selector `async_task`-aware and confirming its transitive fields are isolate-safe. The registry-reconstruct path is simpler and keeps selectors ignorant of the executor.
- **Leave logging synchronous via channel messages** — doable but chatty; we'd ship hundreds of tiny messages per mod. Deferring the log buffer until the task completes matches the existing 250 ms batching the notifier already does.

### Decision: Route `onFileProgress` through `AsyncTaskChannel`; batch `onModStart` / `modProgressOut` to task start/end

`onFileProgress` fires dozens to hundreds of times per mod (once per selected asset). We open an `AsyncTaskChannel` per task and send compact `(processed, total, recentPath)` tuples. The main isolate's executor loop awaits `channel.waitMessage()` in a parallel read loop and invokes the original callbacks on the main isolate. This keeps the Riverpod buffering/flushing logic untouched.

`onModStart` becomes a single message at the top of the task (or is derived from the task-started event). `modProgressOut` is synthesized from the task's return value. Both are called on the main isolate *exactly once per mod*, same as today.

### Decision: Cancellation via a shared `CancelToken` wrapper

`async_task` does not expose first-class cancellation. We use two cooperating mechanisms:
- **Before dispatch**: check `isCancelled()` before submitting each task; short-circuit if the user cancelled while earlier mods were still running.
- **In-flight**: send a "cancel" message on the task's channel. Worker code polls the channel between selector phases (same cadence as today's `ctx.isCancelled` calls) and throws the same `"Cancelled"` exception the current code does.

An outstanding in-flight task may keep running for a few seconds after cancel (the same is true today between `isCancelled()` poll points). That's acceptable — the user sees the scanning UI dismiss immediately because the main-isolate state flips, and the straggler's result is discarded.

### Decision: Share read-only data via `SharedData`

`GraphicsLibConfig`, the full list of `enabledModIds`, and the selector config are all immutable and read by every task. Wrap them once in `SharedData` so `async_task` copies them into each isolate only on first use, not per-task. Measured differently: for 50 mods this avoids 49 redundant copies of ~1–10 KB config blobs — negligible memory, but it's the package's idiomatic pattern and costs nothing.

### Decision: Keep the single-isolate path as the primary code path

`VramChecker.check()` keeps its existing body for `multithreaded == false`. The multithreaded path is a separate method `_checkMultithreaded()` that calls the same `_scanOneMod` top-level function the worker uses (inlined on the main isolate). This guarantees both paths exercise the same scan logic — if they ever diverge, that's the bug. The branch happens at the top of `check()` based on the flag.

### Decision: Flag wiring

- `Settings.vramEstimatorMultithreaded: bool`, default `false`, added to `lib/trios/settings/settings.dart`.
- `VramEstimatorNotifier.startEstimating()` reads the setting and passes it to `VramChecker`.
- UI toggle lives in the existing reference-scan debug panel (rendered for any selector, not just `ReferencedAssetsSelector`, since this flag is selector-independent) with a tooltip. Following the project convention, the toggle uses the checkbox/switch widgets already used in that panel. Tooltip text explains the trade-off.

## Risks / Trade-offs

- **[Risk]** Running selectors in isolates surfaces hidden statefulness. → **Mitigation**: both existing selectors are already stateless beyond their `@MappableClass` config. The `VramAssetSelector.fromId` registry forces new selectors to declare serializable config; a compile-time error is preferable to a silent deadlock.
- **[Risk]** `maxFileHandles` is per-isolate, so effective file-handle pressure is `maxFileHandles * parallelism`. At parallelism=4 and maxFileHandles=2000, worst-case 8000 concurrent handles. Windows' default handle limit is ~10k per process, but some machines are lower. → **Mitigation**: cap parallelism at 4 by default; document the effective cap. If users report handle exhaustion, divide the limit by parallelism inside the worker.
- **[Risk]** Exception propagation across isolates drops stack traces. → **Mitigation**: catch in the worker, return a result variant `VramScanOutcome.failed(modId, messageAndStack)`, rethrow on the main isolate with the captured stack concatenated — matches today's error UX.
- **[Risk]** Isolate spawn cost dominates for tiny mod lists (<5 mods). → **Mitigation**: when the flag is on but `variantsToCheck.length < 2`, fall back to the single-isolate path. No visible UX change; just a guard in the branch.
- **[Trade-off]** Log ordering in verbose mode is per-mod rather than per-line when multithreaded. Mods may log in completion order, not start order. → Documented; mod names are in every log line so readability is unaffected.
- **[Trade-off]** Adding a native-only dependency (`async_task`) on desktop-only project is a non-issue (`async_task` supports all desktop platforms), but bumps the dependency closure by `async_task` + `async_extension` + `ffi`. Acceptable.

## Migration Plan

1. Add `async_task ^1.1.2` to `pubspec.yaml`.
2. Land `VramAssetSelector.fromId(id, config)` registry + add it to both existing selectors (no behavior change for single-threaded users).
3. Land the top-level `_scanOneMod` extraction, refactoring the current `asyncMap` body to call it. Multithreaded flag does not yet exist; this is a pure refactor with the single-isolate code still driving. Verified by running the existing unit test (`test/vram_estimator/vram_estimator_manager_test.dart`) and a manual scan.
4. Add the `Settings.vramEstimatorMultithreaded` field + generated mapper.
5. Add the multithreaded branch in `VramChecker.check()` using the executor.
6. Add the UI toggle.
7. Update `openspec/specs/vram-estimator/spec.md` requirements via the change's spec deltas.

Rollback: flip the flag off. If the flag itself is the problem, the single-isolate path is untouched — a revert of the branch in `check()` plus the settings field is a 20-line diff.

## Open Questions

- Should `parallelism` be a setting too, or a constant? Starting as a constant; revisit if users ask.
- Should we expose a single knob "force multithreaded for reference-mode only"? The reference-mode selector is where the CPU cost actually lives, so there's a case for auto-enabling multithreading only when `ReferencedAssetsSelector` is active. Deferred — let's ship the raw flag first and see if it's obvious.
