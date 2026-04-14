## 1. ProcessDetector Interface

- [x] 1.1 Create `lib/trios/process_detection/process_detector.dart` with abstract `ProcessDetector` class (name getter, `isStarsectorRunning` method returning `Future<Result?>`)

## 2. Extract Existing Detectors

- [x] 2.1 Create `lib/trios/process_detection/wmic_process_detector.dart` — extract `_checkIfAnyProcessIsRunningUsingWmic` logic from `app_state.dart`
- [x] 2.2 Create `lib/trios/process_detection/jps_process_detector.dart` — extract `_checkIfAnyProcessIsRunningUsingGivenJre` logic, constructor takes `javaExecutablePath`
- [x] 2.3 Create `lib/trios/process_detection/unix_process_detector.dart` — extract `ps aux` logic from `app_state.dart`

## 3. Win32 Process Detector

- [x] 3.1 Create `lib/trios/process_detection/win32_process_detector.dart` — constructor takes game JRE directory path
- [x] 3.2 Implement `EnumProcesses` call to get all PIDs
- [x] 3.3 Implement `OpenProcess` + `QueryFullProcessImageName` loop to get full exe paths for each PID
- [x] 3.4 Implement two-tier matching: path match against JRE dir (conclusive true), no java.exe (conclusive false), java.exe but no path match (null/inconclusive)
- [x] 3.5 Implement FFI memory safety: calloc/free in try/finally, CloseHandle for process handles

## 4. Refactor _GameRunningChecker

- [x] 4.1 Add detector chain construction in `build()`: Win32 + WMIC on Windows, Unix + JPS on macOS/Linux
- [x] 4.2 Replace `Timer.periodic` with sequential async `_poll` loop using `while (!_cancelled)` pattern
- [x] 4.3 Read `AppState.isWindowFocused` via `ref.read()` inside the loop body (not captured in closure)
- [x] 4.4 Wire `ref.onDispose` to set `_cancelled = true` for cleanup
- [x] 4.5 Remove all private detection methods from `_GameRunningChecker` (now in separate detector classes)

## 5. Verification

- [x] 5.1 Run `dart analyze` — no errors
- [x] 5.2 Verify app builds and runs on Windows
- [x] 5.3 Verify logs show correct detector being used (Win32 or WMIC on Windows)
