# Batch Mod Installation — Design

## Architecture Overview

```
User Action (file picker / drag-drop)
        │
        ▼
BatchInstallationNotifier.create(files)
        │
        ▼
Phase 1: PRE-SCAN  (parallel, all archives)
  - 7z list contents
  - Extract & parse mod_info.json only
  - Classify: valid / corrupt / no-mod-info / duplicate
        │
        ▼
Phase 2: CONFIRMATION  (one dialog, if 2+ mods or problems exist)
  - Summary: N ready, N conflicts, N invalid
  - Batch conflict policy: skip or replace
  - Per-mod override dropdowns for conflicts
  - User confirms or cancels
        │
        ▼
Phase 3: EXTRACTION  (N concurrent workers, from settings)
  - Pulls from queue, extracts via existing installMod()
  - Reports per-mod progress back to batch state
  - Checks cancellation token between mods
        │
        ▼
Phase 4: FINALIZE  (once)
  - Single incremental reloadModVariants(onlyFolders: [...])
  - Record ActivityEntry per mod via existing ToastDisplayer bridge
  - Show summary
```

## Data Model

### New: `BatchInstallation`

```dart
/// Lives in a Riverpod StateNotifier.
class BatchInstallation {
  final String id;                    // UUID
  final List<BatchEntry> entries;
  final BatchStatus status;           // pending, scanning, confirming, installing, complete
  final ConflictPolicy conflictPolicy; // skip, replace (batch default)
  final ValueNotifier<bool> cancelled;
}

class BatchEntry {
  final String id;
  final File archiveFile;
  final BatchEntryStatus status;      // queued, scanning, scanned, extracting, done, failed, skipped
  final ScannedArchive? scanResult;   // populated after pre-scan
  final ConflictPolicy? overridePolicy; // per-mod override, null = use batch default
  final (int, int)? extractionProgress; // (filesExtracted, totalFiles)
  final Object? error;
}

class ScannedArchive {
  final ModInfo modInfo;
  final int fileCount;
  final int? estimatedSizeBytes;      // from 7z listing
  final ModVariant? existingVariant;  // non-null if already installed
  final bool hasMultipleMods;         // archive contains >1 mod_info.json
}

enum BatchStatus { pending, scanning, confirming, installing, complete }
enum BatchEntryStatus { queued, scanning, scanned, extracting, done, failed, skipped }
enum ConflictPolicy { skip, replace }
```

### New: Settings field

```dart
// Added to Settings class
final int concurrentExtractions; // default: 2, range: 1-6
```

## Key Design Decisions

### Batch provider is separate from DownloadManager

`BatchInstallationNotifier` is a new Riverpod provider. It does not extend or modify `DownloadManager`. This keeps the batch logic self-contained and allows incremental migration later (phases 2-4 in the proposal).

**Boundary rule:** BatchInstallation owns everything from "I have a file on disk" onward. It never does HTTP. If a file needs downloading first, that happens in DownloadManager and the result is handed to the batch.

### Pre-scan uses existing 7z infrastructure

The pre-scan calls `SevenZip.listFiles()` and then extracts only `mod_info.json` via `SevenZip.extractEntriesInArchive()` with a `fileFilter` that selects only mod info files. This is already supported — no changes to the extraction engine.

Pre-scanning all archives can run with high parallelism (6-8) since it's lightweight I/O. This is separate from the extraction concurrency setting.

### Extraction reuses `installMod()`

The inner `installMod()` method in `mod_manager_logic.dart` does the actual file extraction work. The batch orchestrator calls it directly, bypassing `installModFromSourceWithDefaultUI()` which handles single-mod UI concerns (progress binding, reload, dialog). The batch orchestrator handles those concerns itself at the batch level.

### Concurrency pool

A simple worker pool using a semaphore pattern:

```dart
final pool = Pool(settings.concurrentExtractions); // from `pool` package or manual Semaphore
for (final entry in entriesToInstall) {
  pool.withResource(() => extractEntry(entry));
}
```

The `pool` package (`package:pool`) provides this. Alternatively, a manual implementation with a counter and completer queue (similar to the existing `_startExecution` in `downloader.dart`).

### One reload at the end

After all extractions complete, call:
```dart
reloadModVariants(onlyVariants: installedVariants)
```

This uses the existing incremental path in `mod_variants.dart` that only re-scans the specified folders instead of the entire mods directory.

### URLs join the batch late

When a dropped URL finishes downloading, `DownloadManager` hands the local file to the active batch (if one exists) or creates a new batch-of-1. The entry starts in `scanning` status and flows through the same pipeline. The batch's overall progress counter updates ("23/50" becomes "23/52").

If no batch is active, it falls back to the existing single-install path (phase 1 scope).

## File Changes

| File | Change |
|------|--------|
| **New:** `lib/mod_manager/batch_installation/batch_installation.dart` | Data model classes |
| **New:** `lib/mod_manager/batch_installation/batch_installation_notifier.dart` | Riverpod notifier: orchestrates scan → confirm → extract → finalize |
| **New:** `lib/mod_manager/batch_installation/batch_pre_scanner.dart` | Pre-scan logic: list archives, extract mod_info, classify |
| **New:** `lib/mod_manager/batch_installation/batch_confirmation_dialog.dart` | The summary dialog UI |
| **New:** `lib/trios/activity_panel/batch_activity_tile.dart` | `BatchEntryTile` — per-entry in-progress tile for the activity panel |
| `lib/trios/activity_panel/activity_panel.dart` | Watch `batchInstallationProvider`, render one `BatchEntryTile` per active batch entry in "In Progress" section |
| `lib/widgets/add_new_mods_button.dart` | Replace for-loop with `batchInstallationNotifier.create(files)` |
| `lib/trios/drag_drop_handler.dart` | Route local files to batch; URLs still go through DownloadManager but join batch on completion |
| `lib/trios/settings/settings.dart` | Add `concurrentExtractions` field (int, default 2) |
| Settings page UI | Add slider for concurrent extractions (1-6) |
| `lib/mod_manager/mod_manager_logic.dart` | No changes to `installMod()`. `installModFromSourceWithDefaultUI()` stays for single-mod backward compat. |

## Activity Panel Integration

Batch entries render as individual tiles in the "In Progress" section, styled identically to the existing `Download` tiles — there is no separate "batch" UI. This keeps one consistent paradigm (one tile per mod) and aligns with the migration plan, where all installs eventually flow through the batch system.

The "In Progress" section renders one `BatchEntryTile` per *non-terminal* entry (queued, scanning, extracting), in original order, above any `Download` tiles. As each entry finishes it leaves "In Progress" and is written to `ActivityHistoryStore` as an `ActivityEntry`, appearing in "Recent".

```
In Progress
  ⟳ CoolShips v4.0        Installing...  ███████░░░  (extracting, has progress bar)
  ⟳ BigFleets v1.1        Installing...  ████░░░░░░
  ◦ NicePortraits v2.0    Queued
  ◦ ExtraPlanets v1.3     Queued
  ... (queued entries shown so the user can see nothing was dropped)

Recent
  ✓ SuperWeapons v2.1
  ✓ LazyLib 1.8
```

- **Queued/scanning entries are shown** (not hidden) so a large drop doesn't look like half the files were lost.
- **Concurrency** (the `concurrentExtractions` setting) caps how many entries show an active progress bar at once; the rest read "Queued".
- **On completion**, each `done`/`failed` entry is written to `ActivityHistoryStore` as an `ActivityEntry` (per-mod history). Skipped/cancelled entries are not recorded (mirrors single-install behavior).
- **No batch-level cancel** in phase 1. Per-entry queue editing can be added later if needed.
