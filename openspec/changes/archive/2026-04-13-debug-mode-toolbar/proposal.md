## Why

Diagnosing TriOS behavior (especially process detection) currently requires reading logs or adding temporary debug code. A built-in debug mode would let users and developers inspect internal state at a glance via enriched tooltips and a dedicated toolbar icon, reducing friction when troubleshooting issues.

## What Changes

- Add a `debugMode` boolean setting to `Settings`, defaulting to `false`.
- Add a toggle for debug mode in the Settings page UI.
- When debug mode is enabled, show a new debug icon in the top toolbar (both `FullTopBar` and `CompactTopBar` layouts).
- The debug icon's tooltip displays live process-detection diagnostics: which detectors are in the chain, which one (if any) detected the game running, the detection result, and how long the last check took.
- The debug icon's tooltip also displays memory/cache statistics: counts and approximate sizes for key in-memory caches (mod variants, ships, weapons, hullmods, portraits, version checker results, mod records, VRAM estimates, changelogs, forum/catalog data).
- Establish a pattern for future debug-mode enhancements: other widgets can check the debug setting to enrich their own tooltips with internal state.

### Future Debug Mode Ideas

These are not in scope for this change but demonstrate the value of the debug mode foundation:

- **Mod load timing**: Show how long each mod's metadata took to parse in the mod manager grid tooltips.
- **Settings file path**: Display the resolved settings JSON path and last-write timestamp in the settings page.
- **Provider state inspector**: Show Riverpod provider states (loading/error/data) for key providers when hovering over relevant UI sections.
- **HTTP request log**: Show recent network requests (mod index fetches, update checks) with status codes and durations in a debug panel or tooltip.

## Capabilities

### New Capabilities
- `debug-mode-setting`: User setting to enable/disable debug mode, persisted in settings JSON.
- `debug-toolbar-icon`: Toolbar icon (visible only when debug mode is on) with a rich tooltip showing process-detection diagnostics and memory/cache statistics.

### Modified Capabilities

_(none)_

## Impact

- **Settings model** (`lib/trios/settings/settings.dart`): New `debugMode` field + code-gen rebuild.
- **Toolbar** (`lib/toolbar/app_action_buttons.dart`, `full_top_bar.dart`, `compact_top_bar.dart`): New conditional debug button.
- **Process detection** (`lib/trios/app_state.dart`): Expose additional diagnostic data (detector name, check duration) for the tooltip to consume. The `Result` model or a new diagnostics class may need a small extension.
- **Cache providers** (`app_state.dart` and viewer managers): Read item counts from existing providers (`modVariants`, `shipListNotifierProvider`, `weaponListNotifierProvider`, `hullmodListNotifierProvider`, `portraits`, `versionCheckResults`, `modRecordsStore`, `vramEstimatorProvider`, `changelogsProvider`, `forumDataProvider`, `browseModsNotifierProvider`).
- **Settings UI**: New toggle row for debug mode.
