## Context

`_GameRunningChecker` in `lib/trios/app_state.dart` (lines 409–664) is a Riverpod `AsyncNotifier<Result>` that polls every 1.5s to detect whether Starsector is running. It currently tries JpsAtHome (spawns a JVM using the Attach API) first on all platforms, then falls back to WMIC on Windows or `ps aux` on Unix. All detection logic lives in private methods on the class.

The project already depends on `win32` 5.15.0 and `ffi`, with existing Win32 FFI usage in `lib/utils/platform_specific.dart` (process tokens, file operations). The `Result` class in `lib/models/result.dart` provides `Result(bool wasSuccessful, List<Exception> errors)` with factory constructors.

The game's JRE directory is known via `getJreDir(gamePath)` in `lib/utils/platform_paths.dart` (e.g., `<gamePath>/jre` on Windows). The game runs as `java.exe` with `com.fs.starfarer.StarfarerLauncher` in the command line. Users may launch via TriOS (using the game's bundled JRE) or via alternative scripts like `fr.bat` (potentially using a different JRE).

## Goals / Non-Goals

**Goals:**
- Fix the stale `isWindowFocused` closure in the polling timer
- Eliminate concurrent callback pileup from `Timer.periodic`
- Add zero-subprocess Win32 API detection as the primary method on Windows
- Make each detection method a self-contained, swappable module
- Preserve the public `AppState.isGameRunning` provider interface unchanged

**Non-Goals:**
- Replacing WMIC with PowerShell/Get-CimInstance (future work if WMIC is removed from Windows)
- Reading process command lines via `NtQueryInformationProcess`/PEB (complex FFI, WMIC suffices for now)
- Changing the polling interval or adding event-driven detection
- Detecting Starsector processes that aren't `java.exe` (e.g., native launcher)

## Decisions

### 1. ProcessDetector interface with ordered chain
**Choice:** Abstract `ProcessDetector` class. Each implementation returns `Result` if conclusive, `null` if inconclusive. The checker iterates through an ordered list, stopping at the first conclusive result.

**Rationale:** Clean separation of concerns. Each detector is independently testable. Adding new detection methods (e.g., PowerShell) requires only a new class and adding it to the chain. The null-return convention makes the fallback pattern explicit.

**Alternative considered:** Single method with platform switches — rejected because it couples all detection logic together and makes adding/removing methods require editing shared code.

### 2. Win32 detection via EnumProcesses + QueryFullProcessImageName
**Choice:** Use `EnumProcesses` to get all PIDs, then `OpenProcess` + `QueryFullProcessImageName` to get the full exe path for each. Compare paths against the game's JRE directory.

**Rationale:** `EnumProcesses` and `QueryFullProcessImageName` are both available in `win32` 5.15.0 (verified in `kernel32.g.dart`). `CreateToolhelp32Snapshot`/`Process32First`/`Process32Next` are NOT available in the package. Full path matching lets us distinguish the game's `java.exe` from unrelated Java processes without needing command-line access.

**Alternative considered:** `CreateToolhelp32Snapshot` — not exported by the `win32` package. Would require manual FFI bindings for no benefit over `EnumProcesses`.

### 3. Two-tier Win32 detection logic
**Choice:** Three outcomes from the Win32 detector:
1. A process's full path starts with the game's JRE dir → `Result(true)` (definitive)
2. No `java.exe` processes exist at all → `Result(false)` (definitive)
3. `java.exe` exists but path doesn't match → `null` (inconclusive, fall through to WMIC)

**Rationale:** Case 1 handles normal launches (most common). Case 2 handles the most common "not running" scenario with zero subprocess cost. Case 3 handles alternative launchers like `fr.bat` that may use a different JRE — falls through to WMIC which checks the command line for `StarfarerLauncher`.

### 4. Sequential async loop instead of Timer.periodic
**Choice:** Replace `Timer.periodic` with a `while (!_cancelled)` loop that awaits `Future.delayed` then performs the check.

**Rationale:** Eliminates both bugs by construction: `ref.read(AppState.isWindowFocused)` is called inside the loop body (always live), and the next iteration can't start until the current check completes (no concurrency). The trade-off is the effective interval becomes `check_duration + 1500ms` rather than a fixed 1500ms, but sub-second precision is irrelevant for "is the game running?"

**Alternative considered:** `Timer.periodic` with `_isPolling` guard flag and `ref.read` inside callback — fixes the bugs but adds complexity that the loop pattern avoids.

### 5. Platform detection chains
**Choice:**
- Windows: `[Win32ProcessDetector, WmicProcessDetector]`
- Unix: `[UnixProcessDetector, JpsProcessDetector]`

**Rationale:** On Windows, Win32 is conclusive in the two most common cases (game running via bundled JRE, or no Java at all) with zero subprocess cost. WMIC only runs when an unknown `java.exe` is present. JPS is removed from Windows entirely — it spawns a JVM every poll, which is heavier than WMIC with no benefit.

On Unix, `ps aux` is tried first because it's lightweight and universal. It outputs full command lines, so it can match `StarfarerLauncher` directly. JPS is kept as a fallback but is unlikely to be needed.

## Risks / Trade-offs

- **WMIC deprecation** — WMIC is deprecated in Windows 11 and may be removed in future releases. The Win32 fast-path makes WMIC a rare fallback (only when an unrecognized `java.exe` is running), reducing exposure. → Mitigation: monitor WMIC availability; future work can add a `Get-CimInstance` detector if needed.

- **Process access rights** — `OpenProcess` with `PROCESS_QUERY_LIMITED_INFORMATION` may fail for elevated/system processes, returning 0. → Mitigation: skip those PIDs silently. Starsector does not run as a system service or elevated process.

- **Polling interval drift** — The sequential loop has interval `check_duration + 1500ms` rather than a fixed 1500ms. Under normal conditions, check_duration is <5ms (Win32) or <200ms (WMIC), so effective interval is ~1.5–1.7s. → Acceptable trade-off for eliminating concurrency bugs.

- **FFI memory safety** — Win32 FFI requires manual memory management (`calloc`/`free`, `CloseHandle`). → Mitigation: follow the established try/finally pattern from `lib/utils/platform_specific.dart`. Keep the FFI surface small and isolated.
