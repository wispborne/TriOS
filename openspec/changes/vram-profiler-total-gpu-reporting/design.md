## Context

TriOS' out-of-game VRAM Estimator ([lib/vram_estimator/](lib/vram_estimator/)) walks each mod's image files and produces an estimate of GPU texture memory the mod will consume. The number covers textures only by design — the estimator can't see render buffers, geometry data, shaders, or text rendering, and shouldn't try to.

The companion-mod profiler ([VramProfiler.java](TriOS-Companion-Mod/src/wisp/trios/VramProfiler.java)) is a developer tool — only Wisp uses it, to validate and refine the estimator. End users never see profiler output.

The user-visible problem: TriOS shows "Total: 1,584 MB"; Task Manager reports `java.exe` using 1,375 MB. The gap is real engine overhead, but the user has no way to know that or to predict their actual GPU memory headroom from TriOS alone.

**Three datapoints (all in-game, 0.98a-RC8):**

| Run | Cache (MB) | Task Mgr (MB) | Overhead (MB) | Overhead/cache | GraphicsLib |
|---|---|---|---|---|---|
| 5 mods | 588.8 | 650.3 | 61.5 | 10.5% | OFF |
| 10 mods | 1,019.7 | 1,375.2 | 355.5 | 34.9% | ON |
| 17 mods | 1,852.5 | 2,288.8 | 436.3 | 23.5% | ON |

Two cases emerge. With GraphicsLib disabled, overhead is ~10% of the texture cache. With GraphicsLib enabled, overhead is ~257 MB fixed (from its lighting effects: extra render buffers, shader programs, and intermediate textures) plus the same ~10% on top. The ~10% multiplier is the same in both cases because it's extra memory the GPU driver uses when storing any texture (alignment, padding) and doesn't depend on what the game is doing.

This change addresses both halves:
1. **Source of truth (companion mod)**: Capture total-GPU memory in profiler runs so Wisp can derive and refine the constants.
2. **User-facing (TriOS Dart)**: Compute engine overhead at display time from the active GraphicsLib state and the estimator's cache total. Surface it in the totals area alongside the existing texture estimate.

## Goals / Non-Goals

**Goals:**
- Give end users a "projected GPU memory" number that's realistic — comparable to what Task Manager shows, within ~10–15%.
- Keep texture estimates and per-mod numbers unchanged — they're correct for what they measure.
- Be honest about precision: the formula is based on limited data; tooltips say so.
- Give the dev a manifest field to read directly and adjust the constants as more data comes in.

**Non-Goals:**
- Splitting engine overhead across individual mods. It's a flat cost for the game itself, not caused by any particular mod.
- Auto-detecting overhead at runtime in TriOS (would require a profiler manifest from the user's own machine — not a thing for normal users).
- Configurable overhead in user settings. The user shouldn't have to know what engine overhead is.
- Byte-exact agreement with Task Manager. The GPU extensions report system-wide free memory (not per-app) and the formula is based on a small number of measurements — both are inherently approximate.
- A separate formula per Starsector version. Until evidence shows engine overhead changes meaningfully between versions, one set of constants covers all current versions; revisit when a new major version ships.

## Decisions

### Decision 1: Use vendor OpenGL extensions to capture the baseline data

`GL_NVX_gpu_memory_info` (NVIDIA) and `GL_ATI_meminfo` (AMD), queried inside the companion mod where the game's OpenGL context already exists. NVX gives `(dedicated − available) × 1024` for "used"; ATI exposes free-memory pools and we record what's reliable.

**Rationale:** Same process, same driver, no Java native code, no running external commands. Consistent with what the game sees. Documented and stable for ~10 years.

**Trade-off:** Both report system-wide free memory, not per-app. Acceptable — this only feeds the constants that Wisp updates manually, so a clean comparison run (no other GPU apps running) is fine.

### Decision 2: Manifest gains optional fields, no schema bump

New fields: `gpuMemoryTotalUsedBytes` (long, optional), `gpuMemoryDedicatedBytes` (long, optional), `gpuMemoryProvider` (string, always present: `"NVX"` / `"ATI"` / `"none"`), `gpuMemoryNote` (string, optional). `totalGpuBytes` keeps its texture-cache-only meaning so older readers continue to work.

### Decision 3: Engine overhead is a function that branches on GraphicsLib state, not a constant

Place the formula in `lib/vram_estimator/engine_overhead.dart`:

```dart
const int graphicsLibFixedOverheadBytes = 257 * 1024 * 1024;
const double cacheOverheadMultiplier = 0.10;

int engineOverheadBytes({
  required int estimatedCacheBytes,
  required bool graphicsLibEnabled,
}) {
  final fixed = graphicsLibEnabled ? graphicsLibFixedOverheadBytes : 0;
  final scaling = (estimatedCacheBytes * cacheOverheadMultiplier).round();
  return fixed + scaling;
}
```

**Rationale:**
- The data fits this form whether GraphicsLib is on or off; a single constant per game version doesn't work (the 5-mod and 10-mod points differ by 5×).
- GraphicsLib state is already known to TriOS (the estimator UI shows it today), so the branch is free.
- The constants are two numbers in one file; updating them is a one-line PR.
- No async, no I/O, no settings dependency — just arithmetic.

**Alternatives considered:**
- Single formula `a + b × cache` ignoring GraphicsLib: rejected — predicts +313 MB for the 5-mod case where actual was 61 MB, a 5× overshoot.
- Showing a range (min/max) instead of a single number: rejected for now — adds UI complexity without obviously helping the user; the GraphicsLib-aware formula already gives tighter results. Could revisit if it proves unstable.
- Per-game-version constants: rejected — no evidence engine overhead changes meaningfully across RCs of the same major version, and a table grows forever.

### Decision 4: Initial constants come from three measurements; refine after shipping

Ship with `graphicsLibFixedOverheadBytes = 257 MB` and `cacheOverheadMultiplier = 0.10`. These fit the available data within ~30 MB on each point. Tooltip language acknowledges the ±10–15% precision target.

**Rationale:** Three measurements is enough to identify the shape of the formula but not enough to pin down exact constants. Shipping is fine — the worst-case error (~30 MB on a 600+ MB total) is small compared to the size of the gap the change is closing. Wisp adds a "collect more measurements" task and refines the constants as more profiler data arrives.

**Future work (not part of this change):** A small dataset file (`engine_overhead_measurements.json` or similar) that records the profiler runs and could be used by a build-time check to re-derive the constants. Out of scope here.

### Decision 5: Unknown GraphicsLib state defaults to "enabled" for safety

If TriOS can't determine whether GraphicsLib is enabled (edge case — e.g., GraphicsLib is installed but its config can't be read), the function SHALL default to the GraphicsLib-enabled branch.

**Rationale:** Overestimating overhead is much safer than underestimating — a user underestimating headroom doesn't crash; a user underestimating overhead might. The "enabled" branch is the larger of the two estimates.

### Decision 6: UI surfaces three values in the totals row only

Per-mod rows stay unchanged (texture-cache only — that's apples-to-apples for "which mod uses how much"). The estimator's totals area gains:

- **Mods total** — sum of per-mod texture-cache estimates (existing value).
- **Engine overhead** — `engineOverheadBytes(...)` for the active state, with an info icon.
- **Projected GPU memory** — Mods total + Engine overhead, with an info icon explaining this is what Task Manager would show.

Tooltip text:
- *Engine overhead (GraphicsLib enabled)*: "GPU memory used by the engine itself: render buffers, shaders, GraphicsLib's lighting effects (~250 MB), and GPU driver overhead (~10% of texture cache). Independent of which specific mods you have enabled."
- *Engine overhead (GraphicsLib disabled)*: "GPU memory used by the engine itself: render buffers, shaders, and GPU driver overhead (~10% of texture cache). Independent of which specific mods you have enabled."
- *Projected GPU memory*: "Approximate total GPU memory the game will use with these mods loaded. Comparable to Task Manager's 'Dedicated GPU memory' for java.exe — within ~10–15% on typical setups. Based on in-game profiler measurements."

### Decision 7: Companion-mod jar bundling unchanged

Same workflow as the prior profiler change: rebuild from the IntelliJ artifact configuration, copy the new jar to [assets/common/TriOS-Mod/jars/TriOS-Companion-Mod.jar](assets/common/TriOS-Mod/jars/TriOS-Companion-Mod.jar).

## Risks / Trade-offs

- **Constants drift across game or driver versions** → Tooltips say "approximate within 10–15%." Wisp re-runs profiler against vanilla after major Starsector updates and adjusts the two constants. The formula depends on GraphicsLib state, not game version, so version changes don't multiply the maintenance work.
- **Three measurements is thin** → Acknowledged in tooltips. Tasks list includes a "collect more measurements" step before locking down the constants.
- **Individual GraphicsLib settings (normal/material/surface, preload-all) likely contribute different fractions of the 257 MB step** → For now we treat GraphicsLib as binary enabled/disabled. Refining per-setting can come later if data shows it matters.
- **Driver-specific behavior (NVIDIA vs AMD vs Intel iGPU)** → All measurements so far are on NVIDIA. Constants may differ on AMD; tooltip language should not over-promise. Worth re-profiling on AMD after shipping.
- **Unknown GraphicsLib state defaults to "enabled"** → Safer (overestimates rather than underestimates). Documented in Decision 5.
- **Per-mod numbers no longer match the user-facing total** → They never did at the bytes-loaded level either, since per-mod doesn't include vanilla. Still: the totals row makes the relationship explicit (Mods + Engine = Projected) so the math is visible.
- **Tooltips on every new icon** → Non-negotiable per project memory.
