## MODIFIED Requirements

### Requirement: Sequential polling loop
The system SHALL replace `Timer.periodic` with a sequential async loop. The loop SHALL:
1. Wait for the configured delay (1500ms)
2. Read `AppState.isWindowFocused` live (not from a closure snapshot)
3. Skip the check if the window is not focused, unless `AppState.keepCheckingGameWhileUnfocused` is true and at least 5 seconds have passed since the last check
4. Perform the detection check
5. Repeat from step 1

The loop SHALL be cancellable via `ref.onDispose`.

#### Scenario: Window loses focus during polling
- **WHEN** `AppState.isWindowFocused` becomes false after the loop has started and `AppState.keepCheckingGameWhileUnfocused` is false
- **THEN** the loop SHALL skip detection checks until focus is regained

#### Scenario: Sync session open while unfocused
- **WHEN** `AppState.isWindowFocused` is false and `AppState.keepCheckingGameWhileUnfocused` is true
- **THEN** the loop SHALL keep running detection checks every 5 seconds, so the game closing is noticed without TriOS being focused

#### Scenario: Long-running detection check
- **WHEN** a detection check takes longer than the polling interval (e.g., >1500ms)
- **THEN** the next check SHALL NOT begin until the current one completes (no concurrent checks)

#### Scenario: Notifier disposal
- **WHEN** the `_GameRunningChecker` notifier is disposed
- **THEN** the polling loop SHALL stop and no further detection checks SHALL be performed
