## Context

TriOS uses a chain of platform-specific `ProcessDetector` implementations to poll whether Starsector is running (every 1500ms when the window is focused). The `_GameRunningChecker` in `app_state.dart` iterates detectors, returning the first conclusive `Result`. Each detector already exposes a `name` getter. The current `Result` model only carries `wasSuccessful` and `errors` — it does not track *which* detector matched or how long the check took.

Settings are a `@MappableClass` persisted to JSON via dart_mappable. The toolbar is split into two layouts (`FullTopBar` / `CompactTopBar`), both rendering action buttons from `app_action_buttons.dart`.

## Goals / Non-Goals

**Goals:**
- Add a persisted `debugMode` setting with UI toggle.
- Surface process-detection diagnostics in a toolbar icon tooltip when debug mode is on.
- Surface memory/cache statistics (item counts for key providers) in the same tooltip.
- Make the debug-mode check cheap so other widgets can conditionally enrich tooltips in the future.

**Non-Goals:**
- A full debug panel or overlay (just a toolbar icon + tooltip for now).
- Changing how process detection or caching works internally (only exposing existing state).
- Byte-level memory profiling (counts are sufficient; Dart doesn't expose object sizes cheaply).
- Adding debug info to other tooltips in this change (future work).

## Decisions

### 1. Extend Result vs. separate diagnostics class

**Decision:** Create a new `ProcessDetectionDiagnostics` class rather than extending `Result`.

**Rationale:** `Result` is a generic model used elsewhere. Coupling detector metadata to it would leak process-detection concerns into unrelated code. A dedicated diagnostics class keeps the data co-located with the feature.

**Alternative considered:** Adding `detectorName` and `duration` fields to `Result` — rejected because `Result` is intentionally minimal and reused.

### 2. Where to store diagnostics state

**Decision:** Add a new public provider `AppState.processDetectionDiagnostics` backed by a `StateProvider<ProcessDetectionDiagnostics?>`. The `_GameRunningChecker` updates it after each poll cycle.

**Rationale:** Keeps diagnostics reactive (widgets can `ref.watch`) without changing the existing `_isGameRunning` provider contract. The diagnostics provider is nullable (null when detection is disabled).

### 3. Toolbar icon placement

**Decision:** Add a `DebugToolbarButton` widget in `app_action_buttons.dart`, conditionally included in both toolbar layouts when `debugMode` is `true`. Place it at the start of the action buttons row (leftmost, before game folder button) so it's prominent.

**Rationale:** Consistent with existing action-button patterns. Conditional rendering avoids any cost when debug mode is off.

### 4. Tooltip implementation

**Decision:** Use `MovingTooltipWidget.framed()` with a custom widget showing structured diagnostics (detector chain, matched detector, result, duration, errors).

**Rationale:** `MovingTooltipWidget.text()` only supports a single string. The diagnostics need multi-line structured content with labels and values.

### 5. Duration measurement

**Decision:** Wrap the `_runDetectors` call with a `Stopwatch` inside `_GameRunningChecker._poll()` and the initial `build()` check. Store the elapsed duration in the diagnostics.

**Rationale:** Minimal-impact measurement at the right granularity (entire detector chain, not individual detectors).

### 6. Cache stats — item counts from existing providers

**Decision:** The tooltip widget reads item counts directly from existing Riverpod providers at render time. No new caching infrastructure or separate stats provider is needed.

**Providers to read (all already exist):**
| Label | Provider | Count expression |
|---|---|---|
| Mod Variants | `AppState.modVariants` | `.value?.length` |
| Ships | `shipListNotifierProvider` | `.value?.length` |
| Weapons | `weaponListNotifierProvider` | `.value?.length` |
| Hullmods | `hullmodListNotifierProvider` | `.value?.length` |
| Portraits | `AppState.portraits` | `.value?.values.expand((e) => e).length` |
| Version Check Results | `AppState.versionCheckResults` | `.value?.remoteResults.length` |
| Mod Records | `modRecordsStore` | `.value?.modRecords.length` |
| VRAM Estimates | `AppState.vramEstimatorProvider` | `.value?.modVramInfo.length` |
| Changelogs | `AppState.changelogsProvider` | `.value?.length` |
| Forum Index | `forumDataProvider` | `.value?.index.length` |
| Mod Catalog | `browseModsNotifierProvider` | `.value?.mods.length` |

**Rationale:** These providers are already loaded and watched elsewhere. Reading `.value?.length` is O(1) on Dart lists/maps — no iteration cost. This avoids any new state management and keeps the debug tooltip a pure read-only consumer.

**Alternative considered:** A dedicated `CacheStatsProvider` that aggregates counts — rejected as unnecessary indirection when the tooltip widget can read providers directly.

### 7. Tooltip layout — sectioned content

**Decision:** The tooltip widget is structured in two sections separated by a divider: "Process Detection" (top) and "Cache Stats" (bottom). Cache stats are displayed as a compact two-column list (label + count).

**Rationale:** Keeps the tooltip scannable. Two logical sections map to the two diagnostic domains. A table/grid layout for cache stats is compact and avoids vertical sprawl.

## Risks / Trade-offs

- **Stale tooltip data**: Diagnostics update every 1500ms (only when focused). The tooltip will show "last check" data, not real-time. This is acceptable — the polling interval is fast enough for debugging purposes.
- **Settings migration**: Adding a new field with a default value (`false`) to `Settings` requires no migration — dart_mappable's `ignoreNull: true` handles missing fields gracefully.
- **Future debug info coupling**: Other widgets wanting debug tooltips will need to independently check the `debugMode` setting. This is simple (`ref.watch(appSettings.select((s) => s.debugMode))`) and avoids a centralized debug registry.
- **Cache stats accuracy**: Counts reflect what's currently loaded in providers. If a provider hasn't been visited yet (e.g., user hasn't opened the Ships page), its count will show as null/loading. This is accurate — it shows what's actually in memory, not what *could* be loaded.
