## Why

`_GameRunningChecker` in `lib/trios/app_state.dart` polls every 1.5s to detect whether Starsector is running. It has three bugs: a stale `isWindowFocused` closure that never updates after `build()`, no concurrency guard on `Timer.periodic` causing async callbacks to pile up, and on Windows it unnecessarily spawns a JVM (JpsAtHome) every poll when WMIC already works. The detection methods are also tightly coupled inside one class, making them hard to test or swap.

## What Changes

- Add a Win32 API process detector using `EnumProcesses` + `OpenProcess` + `QueryFullProcessImageName` (already available in `win32` 5.15.0). Matches running processes against the game's JRE directory path for conclusive, zero-subprocess detection on Windows.
- Extract each detection method (Win32, WMIC, JPS, `ps aux`) into a self-contained `ProcessDetector` implementation behind a common interface.
- Replace `Timer.periodic` with a sequential async loop that reads `isWindowFocused` live each iteration, eliminating both the stale closure and concurrent callback bugs by construction.
- Change platform detection order: Windows uses Win32 → WMIC (JPS removed); Unix uses `ps aux` → JPS.

## Capabilities

### New Capabilities
- `win32-process-detection`: Pure Win32 API process detection using EnumProcesses. Matches process exe paths against the game's JRE directory for conclusive detection without spawning subprocesses.

### Modified Capabilities
- `game-running-check`: Refactored into a modular detector chain with a fixed timer architecture. Detection methods are now independent, swappable implementations of a common `ProcessDetector` interface.

## Impact

- **New files**: `lib/trios/process_detection/` directory with `process_detector.dart`, `win32_process_detector.dart`, `wmic_process_detector.dart`, `jps_process_detector.dart`, `unix_process_detector.dart`.
- **Modified files**: `lib/trios/app_state.dart` — `_GameRunningChecker` gutted and rewritten to use detector chain + async loop.
- **Dependencies**: No new packages — uses existing `win32` 5.15.0 and `ffi` packages.
- **Public API**: `AppState.isGameRunning` provider interface is unchanged; all changes are internal.
