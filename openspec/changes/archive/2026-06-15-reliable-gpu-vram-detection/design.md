# Design

## Overview

Rewrite the Windows and Linux branches of `getGPUInfo()` in
`lib/vram_estimator/models/gpu_info.dart` to read true 64-bit total VRAM from
reliable per-vendor sources, and adjust the single consumer in
`lib/vram_estimator/vram_checker_logic.dart` so that an unknown VRAM value
suppresses the warning instead of triggering one. No new native dependencies;
detection is done with registry/CLI reads via `Process.run`, consistent with
the existing macOS branch.

## Model change: represent "unknown" explicitly

Today `GPUInfo.freeVRAM` is a non-nullable `double` and "no info" is expressed
by `getGPUInfo()` returning `null`. That conflates "no GPU info at all" with
"GPU found but size unknown," and the Windows path never returns unknown — it
always returns the (wrong) WMI number.

Make total VRAM nullable so a known GPU with an unknown size is representable:

```dart
abstract class GPUInfo {
  abstract double? freeVRAM;        // total VRAM in bytes; null = unknown
  abstract List<String>? gpuString; // best-effort adapter name(s)
}
```

`freeVRAM` keeps its (misleading) name to avoid churn across the field's
definition and the consumer; it has always held *total* VRAM, in **bytes**.
Renaming it is explicitly out of scope.

## Async detection + Riverpod provider

Detection shells out (`reg.exe`, `nvidia-smi`) and reads sysfs, so make
`getGPUInfo()` return `Future<GPUInfo?>` and use `Process.run` (async) rather
than `Process.runSync`, to avoid blocking. Expose it as a cached provider in
`AppState` (`lib/trios/app_state.dart`):

```dart
static final gpuInfo = FutureProvider<GPUInfo?>((ref) => getGPUInfo());
```

A `FutureProvider` runs the detection once and caches the result, so UI widgets
that `ref.watch(AppState.gpuInfo)` never re-trigger the shell-outs on rebuild —
this is the mechanism that keeps the cost off the build path. The existing
warning consumer in `vram_checker_logic.dart` runs outside the widget tree, so
it keeps calling `getGPUInfo()` directly (now `await`ed).

## Windows: registry `qwMemorySize`

Read from:

```
HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}
```

Each display adapter is a numbered subkey (`0000`, `0001`, …) with a
`HardwareInformation.qwMemorySize` value (REG_QWORD, 64-bit bytes) and a
`DriverDesc` value (adapter name).

Implementation: shell out to `reg.exe` (a plain CLI, not PowerShell) with a
recursive query, parse the results, and pick the adapter with the largest
VRAM:

```
reg query "HKLM\...\{4d36e968-...}" /s /v HardwareInformation.qwMemorySize
```

Parse each `REG_QWORD    0x...` line, convert the hex to an int (already bytes),
and take the max. `DriverDesc` is read best-effort for the adapter name; if the
name can't be matched to the winning adapter, leave `gpuString` null. If no
`qwMemorySize` value is found, return unknown (`freeVRAM = null`).

Rationale for `reg.exe` over `win32`/FFI: zero new dependencies, matches the
existing `Process.runSync` style in this file, and the value is a simple hex
integer that's trivial to parse. A `win32` FFI read is the fallback if `reg.exe`
parsing proves brittle.

## Linux: sysfs (AMD) + `nvidia-smi` (NVIDIA)

Collect candidate totals from both sources and take the max:

- **AMD** — glob `/sys/class/drm/card*/device/mem_info_vram_total`. Connector
  directories (`card0-HDMI-A-1`, render nodes) don't have this file, so the glob
  naturally selects real GPU devices. Each file is a plain integer in **bytes**.
- **NVIDIA** — run:
  ```
  nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits
  ```
  Output is one integer per GPU in **MiB**; multiply by 1024 × 1024 to get
  bytes. If `nvidia-smi` is missing, `Process.run` throws — catch and skip.
  Optionally also query `name` for `gpuString`.

If neither source yields a value (e.g. Intel integrated GPU — no dedicated
VRAM), return unknown (`freeVRAM = null`).

## Consumer change: unknown suppresses the warning

In `lib/vram_estimator/vram_checker_logic.dart`, the warning is computed inside
`getGPUInfo()?.also((info) { ... })`. Guard the warning on a known value:

```dart
final vram = info.freeVRAM;
if (vram != null && vram - (totalBytesOfEnabledMods + vanillaTotal) < threshold) {
  // emit warning
}
```

The GPU-name summary line still prints when available; only the warning is
gated on a known VRAM total. With `freeVRAM` null on unknown, no bogus warning
fires.

Note (not changed here): the existing threshold literal `300000` is far smaller
than the "300 MB" the comment claims (300 MB in bytes is `300000000`). This is a
pre-existing discrepancy and is left untouched to keep this change surgical.

## Dependency cleanup

`windows_system_info` is imported only by `gpu_info.dart`. Once the Windows
branch no longer uses it, remove the import and drop the package from
`pubspec.yaml`.

## VRAM usage bar on the estimator page

The bar must show for **both** the bar and pie charts, so it goes in the shared
region of `lib/vram_estimator/vram_estimator_page.dart` — the `Column` that
holds the toolbar and then the `switch (graphType)` chart (around line 219–245),
**above** the `Expanded` that swaps between `VramBarChart` and `VramPieChart`.
It does NOT go in `bar_chart.dart` (that would only cover the bar view). The
old commented-out "Total System VRAM" block in `bar_chart.dart` can be removed.

The page watches the provider and the scan state, both already in scope:

```dart
final gpu = ref.watch(AppState.gpuInfo).valueOrNull;
final total = gpu?.freeVRAM;
```

When `total != null`, render a small header with the total and a
`ThemedLinearProgressIndicator`:

- **Denominator** — `total` from `AppState.gpuInfo`.
- **Numerator (estimated usage)** — the same estimate the warning uses:
  `modVramInfo.getBytesUsedByDedupedImages()` plus the vanilla baseline
  (`vramState.vanillaVramBytes ?? VANILLA_GAME_VRAM_USAGE_IN_BYTES`), so the bar
  and the warning never disagree. Use the full scanned modlist, not the
  slider-filtered subset, so the bar reflects the real modlist. `vramState` is
  already read on the page via `AppState.vramEstimatorProvider`.
- **Fill** = `(estimated / total).clamp(0.0, 1.0)` so an over-budget modlist
  pins the bar at full instead of overflowing.
- Label with `estimated.bytesAsReadableMB()` / `total.bytesAsReadableMB()`.

When `total` is null, render nothing — matching the "unknown suppresses"
behavior of the warning.

## macOS

Left as-is (out of scope). The existing branch still reads `hw.memsize_usable`;
with `freeVRAM` now nullable, no consumer change is needed for it.

## Files touched

- `lib/vram_estimator/models/gpu_info.dart` — rewrite Windows + Linux branches,
  nullable `freeVRAM`, make `getGPUInfo()` async.
- `lib/trios/app_state.dart` — add the `gpuInfo` `FutureProvider`.
- `lib/vram_estimator/vram_estimator_page.dart` — total + usage progress bar in
  the shared region, shown only when VRAM is known.
- `lib/vram_estimator/charts/bar_chart.dart` — remove the stale commented-out
  "Total System VRAM" block.
- `lib/vram_estimator/vram_checker_logic.dart` — guard warning on known VRAM;
  `await` the now-async `getGPUInfo()`.
- `pubspec.yaml` — remove `windows_system_info`.
