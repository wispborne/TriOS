## ADDED Requirements

### Requirement: ProcessDetector interface
The system SHALL define an abstract `ProcessDetector` class with:
- A `name` property (String) for logging identification
- A `isStarsectorRunning(List<String> executableNames)` method returning `Future<Result?>`

A return value of `Result` SHALL indicate a conclusive answer. A return value of `null` SHALL indicate the detector could not determine the answer and the next detector should be tried.

#### Scenario: Conclusive positive detection
- **WHEN** a detector determines the game is running
- **THEN** it SHALL return `Result(true, [])` or `Result.unmitigatedSuccess()`

#### Scenario: Conclusive negative detection
- **WHEN** a detector determines the game is not running
- **THEN** it SHALL return `Result(false, [])` or `Result.unmitigatedFailure([])`

#### Scenario: Inconclusive detection
- **WHEN** a detector cannot determine whether the game is running
- **THEN** it SHALL return `null`

### Requirement: Detector chain execution
The system SHALL iterate through an ordered list of `ProcessDetector` instances, calling each in sequence. It SHALL stop at the first conclusive (non-null) result. If all detectors return null, it SHALL return `Result.unmitigatedFailure(errors)` with accumulated exceptions.

#### Scenario: First detector is conclusive
- **WHEN** the first detector in the chain returns a non-null Result
- **THEN** subsequent detectors SHALL NOT be called

#### Scenario: First detector inconclusive, second conclusive
- **WHEN** the first detector returns null and the second returns a non-null Result
- **THEN** the second detector's Result SHALL be returned

#### Scenario: All detectors inconclusive
- **WHEN** all detectors in the chain return null
- **THEN** the system SHALL return a failure Result containing all accumulated exceptions

### Requirement: Platform-specific detector chains
On Windows, the detector chain SHALL be `[Win32ProcessDetector, WmicProcessDetector]`. JpsProcessDetector SHALL NOT be included on Windows.

On macOS and Linux, the detector chain SHALL be `[UnixProcessDetector, JpsProcessDetector]`.

#### Scenario: Windows detection order
- **WHEN** running on Windows
- **THEN** the system SHALL try Win32 API detection first, then WMIC as fallback

#### Scenario: Unix detection order
- **WHEN** running on macOS or Linux
- **THEN** the system SHALL try `ps aux` first, then JPS as fallback

### Requirement: Sequential polling loop
The system SHALL replace `Timer.periodic` with a sequential async loop. The loop SHALL:
1. Wait for the configured delay (1500ms)
2. Read `AppState.isWindowFocused` live (not from a closure snapshot)
3. Skip the check if the window is not focused
4. Perform the detection check
5. Repeat from step 1

The loop SHALL be cancellable via `ref.onDispose`.

#### Scenario: Window loses focus during polling
- **WHEN** `AppState.isWindowFocused` becomes false after the loop has started
- **THEN** the loop SHALL skip detection checks until focus is regained

#### Scenario: Long-running detection check
- **WHEN** a detection check takes longer than the polling interval (e.g., >1500ms)
- **THEN** the next check SHALL NOT begin until the current one completes (no concurrent checks)

#### Scenario: Notifier disposal
- **WHEN** the `_GameRunningChecker` notifier is disposed
- **THEN** the polling loop SHALL stop and no further detection checks SHALL be performed

### Requirement: Public API preservation
The public providers `AppState.isGameRunning` (FutureProvider<bool>) and `AppState.gameRunningCheckError` (FutureProvider<List<Exception>?>) SHALL maintain their existing type signatures and behavior. All changes SHALL be internal to `_GameRunningChecker`.

#### Scenario: Consumer code unchanged
- **WHEN** existing code calls `ref.watch(AppState.isGameRunning)`
- **THEN** it SHALL receive a `bool` indicating whether the game is running, with no API changes required
