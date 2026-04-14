### Requirement: Win32 process enumeration
The system SHALL enumerate running processes on Windows using the Win32 API (`EnumProcesses`) without spawning any subprocess. For each process ID, it SHALL obtain the full executable path via `OpenProcess` and `QueryFullProcessImageName`.

#### Scenario: No java.exe processes running
- **WHEN** no process on the system has an executable named `java.exe`
- **THEN** the detector SHALL return a conclusive negative result (game is not running)

#### Scenario: Game's JRE java.exe is running
- **WHEN** a `java.exe` process exists whose full path starts with the game's JRE directory (case-insensitive)
- **THEN** the detector SHALL return a conclusive positive result (game is running)

#### Scenario: Unrelated java.exe is running
- **WHEN** one or more `java.exe` processes exist but none have a path starting with the game's JRE directory
- **THEN** the detector SHALL return an inconclusive result (null), allowing the next detector in the chain to run

#### Scenario: Process access denied
- **WHEN** `OpenProcess` fails for a given PID (returns 0), such as for system or elevated processes
- **THEN** the detector SHALL skip that PID and continue checking remaining processes

### Requirement: FFI memory safety
The detector SHALL use `calloc` for memory allocation and `free`/`CloseHandle` for cleanup in try/finally blocks, following the pattern established in `lib/utils/platform_specific.dart`.

#### Scenario: Normal execution cleanup
- **WHEN** the detector completes process enumeration (whether successful or not)
- **THEN** all allocated memory SHALL be freed and all process handles SHALL be closed

#### Scenario: Exception during enumeration
- **WHEN** an exception occurs during process enumeration
- **THEN** all allocated memory and handles SHALL still be cleaned up via finally blocks
