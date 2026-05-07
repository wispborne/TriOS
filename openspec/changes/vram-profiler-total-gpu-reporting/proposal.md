## Why

TriOS' VRAM Estimator currently reports a textures-only number per mod and as a total. A user who compares that total against Task Manager (or against the GPU memory their machine actually has free) sees a 10–35% gap they can't account for — engine overhead the estimator deliberately doesn't model (render buffers, depth buffer, geometry data, compiled shaders, text rendering, GraphicsLib's lighting effects, and extra memory the GPU driver uses internally). The user is left wondering whether TriOS is wrong, or whether they have less headroom than they think.

Data from three in-game profiler runs (3,098 / 4,375 / 4,856 textures) shows engine overhead is not a fixed constant but tracks two factors: (1) whether GraphicsLib is enabled (≈250 MB step from its lighting effects) and (2) total texture-cache size (the GPU driver uses ~10% extra memory on top of the raw texture data for internal bookkeeping). Both factors are visible to TriOS today. This change gives the user an honest "projected total GPU memory" by adding an engine-overhead estimate that accounts for GraphicsLib state, and it gives the dev (Wisp) the in-game profiler data needed to keep the constants tuned.

## What Changes

**Companion mod (data source for tuning):**
- Query vendor OpenGL extensions (`GL_NVX_gpu_memory_info` for NVIDIA, `GL_ATI_meminfo` for AMD) to obtain the GPU driver's view of total memory in use.
- Extend the profiler manifest with optional fields (`gpuMemoryTotalUsedBytes`, `gpuMemoryDedicatedBytes`, `gpuMemoryProvider`, `gpuMemoryNote`); the existing `totalGpuBytes` keeps its texture-cache-only meaning.
- Update the in-game console command feedback to show the three-line breakdown.
- Degrades gracefully on Intel iGPU / drivers without the extensions (provider = `"none"`).

**TriOS Dart (user-facing):**
- Add an engine-overhead formula in `lib/vram_estimator/engine_overhead.dart`. Initial form: `overhead = (graphicsLibEnabled ? graphicsLibFixedBytes : 0) + overheadMultiplier × cacheBytes`. The GraphicsLib step and the multiplier are constants Wisp updates from profiler runs.
- Update the VRAM Estimator's **totals** display to show three values: "Mods total" (existing texture-cache sum), "Engine overhead" (computed from the model), "Projected GPU memory" (sum of the two).
- Add tooltips explaining each value, that the overhead estimate accounts for GraphicsLib state, and that the projected total roughly matches Task Manager's "Dedicated GPU memory" for `java.exe` within ±10–15%.
- Per-mod rows stay unchanged — engine overhead is not per-mod attributable.
- The active GraphicsLib state is already known to TriOS (it's surfaced in the estimator UI today), so no new wiring needed.

## Capabilities

### New Capabilities
<!-- None — this extends two existing capabilities. -->

### Modified Capabilities
- `gpu-vram-profiler`: Manifest gains optional GPU-total fields; console-command feedback gains a three-line summary when an extension is available.
- `vram-estimator`: Adds an engine-overhead estimate (branching on GraphicsLib state) to the totals display so the user-visible "projected total" reflects realistic GPU memory usage, not texture-cache only.

## Impact

- **Companion mod (Java)**: [VramProfiler.java](TriOS-Companion-Mod/src/wisp/trios/VramProfiler.java) and [TriOS_ProfileVram.java](TriOS-Companion-Mod/src/wisp/trios/TriOS_ProfileVram.java) gain the extension query path and three-line feedback. The shipped jar must be rebuilt and re-bundled in [assets/common/TriOS-Mod/jars/](assets/common/TriOS-Mod/jars/).
- **Dart code**: A new file in [lib/vram_estimator/](lib/vram_estimator/) computes engine overhead from the texture estimate + GraphicsLib state. The VRAM Estimator's totals widget is updated to show the three-value breakdown with tooltips.
- **Per-mod display**: Unchanged. Engine overhead is not split per mod.
- **Backward compatibility**: New manifest fields are optional; older readers ignore them. The Dart engine-overhead function has safe defaults if GraphicsLib state is unknown.
- **Maintenance burden**: Wisp updates the constants when profiler data shows they've drifted — at minimum once Starsector ships a new major version. The constants are just two numbers, not per-version tables; they don't grow unbounded.
- **Precision**: The initial constants come from three measurements. Tooltip wording acknowledges ±10–15% precision. More profiler runs across mod loads (and across GraphicsLib settings combinations) will tighten them after shipping.
