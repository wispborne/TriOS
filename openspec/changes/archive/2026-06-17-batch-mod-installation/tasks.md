# Batch Mod Installation — Tasks

## Data model & settings

- [x] Create `lib/mod_manager/batch_installation/batch_installation.dart` with `BatchInstallation`, `BatchEntry`, `ScannedArchive`, and enums (`BatchStatus`, `BatchEntryStatus`, `ConflictPolicy`). Use `@MappableClass` for any types that need serialization.
- [x] Add `concurrentExtractions` field to `Settings` (int, default 2). Run `build_runner` to regenerate mapper.
- [x] Add slider to settings page for concurrent extractions (1-6 range).

## Pre-scanner

- [x] Create `lib/mod_manager/batch_installation/batch_pre_scanner.dart`. Given a list of archive `File`s, scan each in parallel: call `SevenZip.listFiles()`, extract only `mod_info.json` to a temp dir, parse it, check for existing installed variants, return `List<ScannedArchive>`. Clean up temp files.
- [x] Handle edge cases in pre-scanner: archives with no `mod_info.json`, archives with multiple mods, corrupt/unreadable archives, non-archive files. Each should produce a classifiable result, not throw.

## Confirmation dialog

- [x] Create `lib/mod_manager/batch_installation/batch_confirmation_dialog.dart`. Shows summary counts (ready / conflicts / invalid), scrollable list of entries with status icons, batch-level conflict policy dropdown (skip/replace), per-mod override dropdowns for conflicting entries, and Install/Cancel buttons. Returns user decisions (which mods to install, conflict policy, per-mod overrides).
- [x] Dialog should update the "Install N Mods" button count live as the user toggles entries.

## Batch orchestrator

- [x] Create `lib/mod_manager/batch_installation/batch_installation_notifier.dart` as a Riverpod `Notifier<BatchInstallation?>`. Implement `create(List<File> files)` method that kicks off the pipeline: pre-scan → show dialog (if needed) → extract → finalize.
- [x] Implement extraction phase: pull entries from queue, run N concurrent extractions via a semaphore/pool pattern. Call the existing `installMod()` from `mod_manager_logic.dart` for each. Update `BatchEntry.status` and `extractionProgress` as each progresses.
- [x] Implement finalize phase: single `reloadModVariants()` call. Record each completed (`done`) and `failed` mod as an `ActivityEntry` in `ActivityHistoryStore` so it appears in "Recent". Set batch status to `complete`.
  - ~~Batch-level cancellation~~ — dropped. With individual per-entry tiles there is no batch tile to host a "Cancel All" button; the `cancelled` flag and its checks were removed. Per-entry queue editing can be added later.

## Activity panel

- [x] Create `lib/trios/activity_panel/batch_activity_tile.dart` with `BatchEntryTile` — a per-entry in-progress tile styled like the existing download tiles (status icon + mod name + progress bar when extracting, else "Queued"/"Scanning...").
- [x] Update `activity_panel.dart` to watch the batch notifier. Render one `BatchEntryTile` per non-terminal entry (queued/scanning/extracting), in original order, in the "In Progress" section above the existing `InProgressActivityTile` download tiles. Completed entries flow to "Recent" via `ActivityHistoryStore`.

## Entry point wiring

- [x] Update `lib/widgets/add_new_mods_button.dart`: replace the for-loop with a call to `batchInstallationNotifier.create(files)`.
- [x] Update `lib/trios/drag_drop_handler.dart`: route local files (archives + folders) to `batchInstallationNotifier.create(files)`. Keep URL drops going through `DownloadManager` for now. When a URL download completes, add the resulting file to the active batch if one exists, otherwise create a batch-of-1 that skips the dialog.

## Testing

- [ ] Test pre-scanner with: valid archive, corrupt archive, archive with no mod_info, archive with multiple mods, non-archive file. *(Manual testing needed)*
- [ ] Test batch orchestrator with: normal batch, batch with conflicts (skip policy), batch with conflicts (replace policy), cancellation mid-batch, all-fail batch. *(Manual testing needed)*
- [ ] Test dialog-skip logic: batch of 1 with no problems skips dialog; batch of 1 with conflict shows dialog; batch of 2+ always shows dialog. *(Manual testing needed)*
