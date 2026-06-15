# Reliable cross-vendor GPU VRAM detection

## Problem

`getGPUInfo()` in `lib/vram_estimator/models/gpu_info.dart` reports total GPU
VRAM, which feeds the "you may not have enough free VRAM to run your current
modlist" warning in `lib/vram_estimator/vram_checker_logic.dart`. Today it is
unreliable on every platform:

- **Windows** uses the `windows_system_info` package, which reads the WMI
  `Win32_VideoController.AdapterRAM` field. That field is a signed 32-bit
  integer that caps at ~4 GiB, so any card with more than 4 GB is reported as
  ~4095 MB. On the most common modern gaming GPUs the warning compares the
  modlist against a number that is silently 2–6× too low, producing false
  "not enough VRAM" warnings.
- **macOS** runs `sysctl` and reads `hw.memsize_usable` — that is total system
  RAM, not VRAM. The value is mislabeled.
- **Linux** is unhandled; `getGPUInfo()` returns `null`, so the warning never
  has data.

## Why not the in-game companion mod

The companion mod can query VRAM via OpenGL while the game runs, but the GL
extensions only return a usable *total* on NVIDIA (`GL_NVX_gpu_memory_info`).
AMD's `GL_ATI_meminfo` reports free memory only — never total — and Intel
exposes neither. Since AMD coverage is required, the in-game GL approach is a
dead end for this use case.

## Solution

Replace the launcher-side detection with reliable, cross-vendor, per-platform
sources that report true 64-bit total VRAM with no new native dependencies:

- **Windows** — read `HardwareInformation.qwMemorySize` (a 64-bit QWORD) from
  the display-adapter registry key under
  `HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}`.
  This is correct for all vendors and is not subject to the 4 GiB cap.
- **Linux** — read the amdgpu kernel driver's sysfs file
  `/sys/class/drm/card*/device/mem_info_vram_total` for AMD (present whenever an
  AMD GPU is working, since amdgpu is in the mainline kernel), and shell out to
  `nvidia-smi --query-gpu=memory.total` for NVIDIA. Intel integrated GPUs have
  no dedicated VRAM and report unknown.
- **Unknown handling** — when no reliable total can be obtained (Intel iGPU,
  missing driver, parse failure), report VRAM as unknown and **suppress** the
  warning rather than firing a bogus one.

When more than one GPU is present, pick the one with the most VRAM (the existing
Windows behavior), which is the right answer for the "will it fit" question.

## Scope

- Rewrite the Windows and Linux branches of `getGPUInfo()`.
- Introduce an explicit "unknown VRAM" state and make the warning logic skip
  when VRAM is unknown.
- Remove the dependency on `windows_system_info` if nothing else uses it.
- Expose GPU info as a Riverpod provider in `AppState` (caches the detection
  result so it isn't re-run on every rebuild).
- On the VRAM Estimator page, show total VRAM with a progress bar of
  estimated-usage / total — only when the total is known. Place it in the
  region shared by both chart types so it appears for the bar and pie views.

## Non-goals

- macOS VRAM detection — out of scope; the existing macOS branch is left as-is.
- Vulkan-based detection — rejected (extra FFI binding plus a bundled native lib
  on macOS, for a heuristic warning).
- Changing the VRAM estimation formula or the warning threshold.
- Reading the companion mod's profiler output.
