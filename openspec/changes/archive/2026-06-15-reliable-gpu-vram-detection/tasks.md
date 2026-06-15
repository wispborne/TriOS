# Tasks

## Model

- [x] Change `GPUInfo.freeVRAM` from `double` to `double?` (total VRAM in bytes; null = unknown) in `lib/vram_estimator/models/gpu_info.dart`.
- [x] Update `WindowsGPUInfo` and `MacOSGPUInfo` to match the nullable field. (Collapsed the three platform classes into one private `_GPUInfo` impl.)
- [x] Make `getGPUInfo()` return `Future<GPUInfo?>` using `Process.run` (async) instead of `Process.runSync`.
- [x] Add `AppState.gpuInfo = FutureProvider<GPUInfo?>((ref) => getGPUInfo())` in `lib/trios/app_state.dart`.

## Windows

- [x] Rewrite the Windows branch of `getGPUInfo()` to query `reg.exe` for `HardwareInformation.qwMemorySize` under the display-adapter Class key `{4d36e968-e325-11ce-bfc1-08002be10318}`.
- [x] Parse the `REG_QWORD` hex values, convert to int bytes, and select the largest.
- [x] Read `DriverDesc` best-effort for the adapter name; leave `gpuString` null if unavailable.
- [x] Return unknown (`freeVRAM = null`) when no `qwMemorySize` value is found.

## Linux

- [x] Add a Linux branch to `getGPUInfo()`.
- [x] Read AMD totals by globbing `/sys/class/drm/card*/device/mem_info_vram_total` (bytes).
- [x] Read NVIDIA total via `nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits`, converting MiB to bytes; catch and skip if `nvidia-smi` is absent.
- [x] Select the largest value across sources; return unknown if none found.

## Consumer

- [x] In `lib/vram_estimator/vram_checker_logic.dart`, `await` the now-async `getGPUInfo()` and guard the "not enough VRAM" warning on a non-null `freeVRAM` so unknown suppresses the warning.
- [x] Confirm the GPU-name summary line still prints when `gpuString` is available.

## Estimator page bar

- [x] In `lib/vram_estimator/vram_estimator_page.dart`, in the shared `Column` above the `switch (graphType)` chart, watch `AppState.gpuInfo` for the total VRAM.
- [x] When total VRAM is known, render the total + a `ThemedLinearProgressIndicator` so it shows for both the bar and pie views.
- [x] Set the bar fill to `(estimated / total).clamp(0.0, 1.0)`, where estimated = enabled scanned mods' `getBytesUsedByDedupedImages()` + vanilla baseline (`vramState.vanillaVramBytes ?? VANILLA_GAME_VRAM_USAGE_IN_BYTES`). (Used **enabled** scanned mods, not all, so the bar agrees with the warning — see note below.)
- [x] Label the bar `estimated / total` using `bytesAsReadableMB()`.
- [x] When total VRAM is unknown, render nothing (no total, no bar).
- [x] Remove the stale commented-out "Total System VRAM" block from `lib/vram_estimator/charts/bar_chart.dart`.

## Cleanup

- [x] Remove the `windows_system_info` import from `gpu_info.dart`.
- [x] Remove `windows_system_info` from `pubspec.yaml`. (Note: `flutter pub get` could not run in this environment — Flutter SDK 3.44.0 installed vs 3.44.2 required by pubspec. Run it in your normal dev environment.)

## Verify

- [ ] `flutter analyze` passes. (Could not run here: analysis server crashes on shutdown due to a perf-file lock held by the open IntelliJ instance, and `pub get` is blocked by the SDK mismatch above. Verified by manual review instead.)
- [ ] Manual check on Windows: reported VRAM matches the actual card for a >4 GB GPU (no ~4095 MB cap).
- [ ] Manual check on Linux (AMD): reported VRAM matches `mem_info_vram_total`.
- [ ] Manual check: an Intel/unknown GPU produces no VRAM warning.
- [ ] Manual check: the estimator page shows the total + usage bar when VRAM is known, and hides it when unknown.
- [ ] Manual check: the bar appears on both the bar chart and the pie chart.
