## 1. Settings Model

- [x] 1.1 Add `debugMode` field (bool, default `false`) to `Settings` class in `lib/trios/settings/settings.dart`
- [x] 1.2 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `settings.mapper.dart`

## 2. Process Detection Diagnostics

- [x] 2.1 Create `ProcessDetectionDiagnostics` class in `lib/trios/process_detection/` with fields: `detectorNames` (List<String>), `matchedDetectorName` (String?), `wasGameRunning` (bool), `checkDuration` (Duration), `errors` (List<Exception>)
- [x] 2.2 Add `AppState.processDetectionDiagnostics` StateProvider in `lib/trios/app_state.dart`
- [x] 2.3 Update `_GameRunningChecker._runDetectors` to track which detector matched and wrap calls with a `Stopwatch`
- [x] 2.4 Update `_GameRunningChecker._poll` and `build` to populate the diagnostics provider after each check

## 3. Debug Toolbar Button

- [x] 3.1 Create `DebugToolbarButton` widget in `lib/toolbar/app_action_buttons.dart` using `MovingTooltipWidget.framed()` with a custom tooltip widget
- [x] 3.2 Build the tooltip content widget with two sections: "Process Detection" (detection enabled/disabled, detector chain, matched detector, result, duration, errors) and "Cache Stats" (item counts from providers: modVariants, ships, weapons, hullmods, portraits, versionCheckResults, modRecords, vramEstimator, changelogs, forumData, browseMods)
- [x] 3.3 Handle loading/error states for cache counts — show dash for loading, "error" for errored providers
- [x] 3.4 Add `DebugToolbarButton` to `FullTopBar` action buttons row, conditionally rendered when `debugMode` is true
- [x] 3.5 Add `DebugToolbarButton` to `CompactTopBar` action buttons, conditionally rendered when `debugMode` is true

## 4. Settings UI

- [x] 4.1 Add a debug mode toggle to the Settings page with label "Debug mode" and description text

## 5. Verification

- [x] 5.1 Verify the app builds without errors after all changes
- [x] 5.2 Verify the debug icon appears only when debug mode is enabled and tooltip shows correct diagnostics and cache stats
