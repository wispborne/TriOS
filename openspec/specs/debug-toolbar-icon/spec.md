## Requirements

### Requirement: Debug icon visibility
The toolbar SHALL display a debug icon when `debugMode` is `true`. The icon SHALL NOT be visible when `debugMode` is `false`. This applies to both `FullTopBar` and `CompactTopBar` layouts.

#### Scenario: Debug mode enabled shows icon
- **WHEN** `debugMode` is `true`
- **THEN** a debug icon SHALL appear in the toolbar action buttons area

#### Scenario: Debug mode disabled hides icon
- **WHEN** `debugMode` is `false`
- **THEN** no debug icon SHALL appear in the toolbar

### Requirement: Debug icon has tooltip with text label
The debug icon SHALL have a tooltip that identifies it as the debug/diagnostics indicator.

#### Scenario: Hovering over debug icon
- **WHEN** the user hovers over the debug icon
- **THEN** a tooltip SHALL appear showing process-detection diagnostics and cache statistics

### Requirement: Tooltip shows process detection diagnostics
The debug icon tooltip SHALL display the following information about process detection:
- Whether process detection is enabled or disabled (the `checkIfGameIsRunning` setting).
- The list of detectors in the current chain, with their names (from `ProcessDetector.name`).
- Which detector (if any) detected the game as running, identified by name.
- The result of the last check: running, not running, or error.
- The duration of the last detection check in milliseconds.
- Any errors from the last check.

#### Scenario: Game is not running
- **WHEN** the user hovers over the debug icon and the game is not detected
- **THEN** the tooltip SHALL show the detector chain, indicate no detector matched, show the result as "not running", and display the last check duration

#### Scenario: Game is running
- **WHEN** the user hovers over the debug icon and a detector has found the game running
- **THEN** the tooltip SHALL show the detector chain, identify which detector matched, show the result as "running", and display the last check duration

#### Scenario: Detection disabled
- **WHEN** process detection is disabled via `checkIfGameIsRunning = false`
- **THEN** the tooltip SHALL indicate that process detection is disabled

#### Scenario: Detection errors occurred
- **WHEN** the last detection check produced errors
- **THEN** the tooltip SHALL display the error messages alongside the other diagnostics

### Requirement: Process detection diagnostics data
The `_GameRunningChecker` SHALL expose diagnostic data including: the detector chain names, which detector matched (if any), the detection result, the elapsed duration of the last check, and any errors. This data SHALL be available via a Riverpod provider for the tooltip widget to consume.

#### Scenario: Diagnostics update each poll cycle
- **WHEN** a detection poll cycle completes
- **THEN** the diagnostics provider SHALL be updated with the latest check results and timing

#### Scenario: Diagnostics reflect initial check
- **WHEN** the `_GameRunningChecker` performs its initial build check
- **THEN** the diagnostics provider SHALL be populated with the initial check results

### Requirement: Tooltip shows cache statistics
The debug icon tooltip SHALL display a "Cache Stats" section showing item counts for in-memory caches. The following caches SHALL be listed with their current item count:
- Mod Variants (from `AppState.modVariants`)
- Ships (from `shipListNotifierProvider`)
- Weapons (from `weaponListNotifierProvider`)
- Hullmods (from `hullmodListNotifierProvider`)
- Portraits (from `AppState.portraits`, total across all mod variants)
- Version Check Results (from `AppState.versionCheckResults`)
- Mod Records (from `modRecordsStore`)
- VRAM Estimates (from `AppState.vramEstimatorProvider`)
- Changelogs (from `AppState.changelogsProvider`)
- Forum Index (from `forumDataProvider`)
- Mod Catalog (from `browseModsNotifierProvider`)

If a provider has not yet loaded, the count SHALL display as "loading" or a dash. If a provider is in an error state, the count SHALL display as "error".

#### Scenario: All caches loaded
- **WHEN** all listed providers have completed loading
- **THEN** the tooltip SHALL show each cache label with its integer item count

#### Scenario: Some caches not yet loaded
- **WHEN** one or more providers are still loading (e.g., user has not visited the Ships page)
- **THEN** those cache entries SHALL show a loading indicator or dash instead of a count

#### Scenario: A cache provider has errored
- **WHEN** a provider is in an error state
- **THEN** that cache entry SHALL display "error" instead of a count
