## 1. Companion mod: GPU memory query

- [x] 1.1 Add a `GpuMemoryQuery` helper class in `TriOS-Companion-Mod/src/wisp/trios/`. Public API: `GpuMemoryResult query()` returning `{provider, totalUsedBytes, dedicatedBytes, note}` where any field except `provider` may be null.
- [x] 1.2 Implement extension detection by parsing `GL11.glGetString(GL11.GL_EXTENSIONS)` for `GL_NVX_gpu_memory_info` and `GL_ATI_meminfo`. Prefer NVX when both are present.
- [x] 1.3 Implement the NVX path: `glGetInteger(0x9047)` for dedicated, `glGetInteger(0x9049)` for current available. Both reported in KB — multiply by 1024 for bytes. Used = dedicated − available.
- [x] 1.4 Implement the ATI path: `glGetInteger(0x87FC)` for `TEXTURE_FREE_MEMORY_ATI` (4-int array — first int is total free in KB). Record available; populate `dedicatedBytes` only if obtainable, otherwise leave null and explain how AMD reports this in `gpuMemoryNote`.
- [x] 1.5 Sanity-check results: reject negative or > 64 GB values, catch any exception from the query path, log a single warning, and return `provider = "none"`.
- [x] 1.6 Wire `GpuMemoryQuery.query()` into `VramProfiler.scan()` after the texture loop and before manifest writing. Store the result on `ScanResult` for the command to read.

## 2. Companion mod: Manifest and command feedback

- [x] 2.1 In `VramProfiler.writeManifest`, add the new fields: `gpuMemoryProvider` (always written) and `gpuMemoryTotalUsedBytes` / `gpuMemoryDedicatedBytes` / `gpuMemoryNote` (only when not null).
- [x] 2.2 In `TriOS_ProfileVram.runCommand`, format the success message with the three-line summary (texture count, texture-cache MB, total GPU MB, overhead MB, provider) when an extension is available; fall back to the existing single texture-cache line plus a "total unavailable on this driver" note when provider is `"none"`.
- [ ] 2.3 Rebuild `TriOS-Companion-Mod.jar` from the IntelliJ artifact configuration.
- [ ] 2.4 Copy the rebuilt jar to [assets/common/TriOS-Mod/jars/TriOS-Companion-Mod.jar](assets/common/TriOS-Mod/jars/TriOS-Companion-Mod.jar) so the bundled mod ships the new build.

## 3. Companion mod: Verification

- [ ] 3.1 Run `TriOS_ProfileVram` on the dev's NVIDIA box. Confirm console output shows three numbers and `Total GPU` is within ~10% of Task Manager's "Dedicated GPU memory" for `java.exe`.
- [ ] 3.2 Inspect `saves/common/trios_vram_manifest.data` and confirm new fields appear and parse as valid JSON.
- [ ] 3.3 Confirm `compare_vram.dart` and any other existing manifest reader keeps working (unknown fields ignored).

## 4. Tune the constants

- [ ] 4.1 Capture at least three additional in-game profiler runs, paired with Task Manager screenshots of `java.exe` "Dedicated GPU memory" taken within seconds of the scan. Aim for: (a) GraphicsLib OFF at low mod count, (b) GraphicsLib OFF at high mod count, (c) same mod set with GraphicsLib toggled on then off.
- [ ] 4.2 For each run, compute `engineOverhead = gpuMemoryTotalUsedBytes − totalGpuBytes` and record alongside the GraphicsLib state and the cache size.
- [ ] 4.3 From GraphicsLib-OFF runs, find the best-fit `cacheOverheadMultiplier` (should be near 0.10). From matched ON/OFF pairs at similar cache sizes, compute `graphicsLibFixedOverheadBytes` as the average difference between ON and OFF overhead.
- [ ] 4.4 Sanity-check that the values are close to the initial `0.10` and `257 MB`. If they differ by > 30%, investigate before shipping.
- [ ] 4.5 Record the measurement runs (date, GraphicsLib state, cache MB, Task Manager MB, derived overhead) as a comment block at the top of `lib/vram_estimator/engine_overhead.dart` so future updates have a reference.

## 5. Dart: Engine-overhead formula

- [x] 5.1 Create `lib/vram_estimator/engine_overhead.dart` with: top-level `const int graphicsLibFixedOverheadBytes`, `const double cacheOverheadMultiplier`, and a top-level `int engineOverheadBytes({required int estimatedCacheBytes, required bool graphicsLibEnabled})` function.
- [x] 5.2 Add unit tests in `test/`: GraphicsLib disabled returns `0.10 × cache`; GraphicsLib enabled returns `257 MB + 0.10 × cache`; both reproduce the 5/10/17-mod measurements within ±30 MB.

## 6. Dart: Totals display

- [x] 6.1 Locate the VRAM Estimator's totals widget (in `lib/vram_estimator/`). Identify where the existing single-value total is rendered.
- [x] 6.2 Replace the single total with a three-row layout: `Mods total` (existing value), `Engine overhead` (from `engineOverheadBytes(...)`), `Projected GPU memory` (sum of the two). Use 8dp grid spacing per project UI conventions.
- [x] 6.3 Read GraphicsLib enabled-state from the existing app-state provider TriOS uses to render the GraphicsLib breakdown line in the estimator UI today. Pass it into `engineOverheadBytes`. If the state cannot be determined, default to `true` and surface that in the tooltip per Decision 5.
- [x] 6.4 Add info icons with tooltips on the Engine overhead and Projected GPU memory rows. Tooltip text per design.md Decision 6, varying the Engine-overhead tooltip when GraphicsLib state is unknown ("GraphicsLib state could not be determined; assuming enabled for safety").
- [x] 6.5 Confirm both new icons satisfy the project rule: every new icon has a tooltip explaining its purpose.

## 7. Dart: Verification

- [x] 7.1 `flutter analyze` clean.
- [x] 7.2 `flutter test` passes (including the new unit tests for `engineOverheadBytes`).
- [ ] 7.3 Run the app, open the VRAM Estimator with mods enabled, and visually confirm: three rows render, numbers add up (`Mods + Engine = Projected`), tooltips appear on hover and read correctly.
- [ ] 7.4 Toggle GraphicsLib enabled-state in the active install and confirm the Engine overhead value changes by ~257 MB and the tooltip text adjusts accordingly.
- [ ] 7.5 Hand-test the unknown-state fallback by temporarily forcing the GraphicsLib detection to fail; confirm the tooltip mentions the fallback and the value uses the enabled branch.
- [ ] 7.6 Compare `Projected GPU memory` against Task Manager's "Dedicated GPU memory" for `java.exe` after the game has loaded; confirm they agree within ~10–15% across at least one GraphicsLib-OFF run and one GraphicsLib-ON run.
