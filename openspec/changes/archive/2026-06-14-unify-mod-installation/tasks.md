# Tasks

## 1. Let the batch installer install from a folder

- [x] In `batch_installation.dart`, change `BatchEntry.archiveFile` (`File`) to
      `source` (`FileSystemEntity`); add `bool get isDirectory`. Update
      `displayName` and any `archiveFile.path` / `archiveFile.uri` reads.
- [x] In `batch_pre_scanner.dart`, make scanning source-aware: for a folder use
      `DirectoryModInstallSource` + `listFilePaths()` (skip the archive-extension
      check); for an archive keep the current path. Read `mod_info.json` via the
      source's `getActualFiles()` in both cases.
- [x] In `batch_installation_notifier.dart`, update `create()` and
      `addLateEntry()` to accept `FileSystemEntity` instead of `File`. Update
      call sites within the notifier that reference `entry.archiveFile`
      (e.g. `sourceLabel` in the dialog, `sourceDetail` in history entries).
- [x] Verify `_extractSingleEntry` in the notifier works unchanged for a folder
      source (it already uses the generic `entry.installSource`).

## 2. Link a Download to a batch entry and drive it

- [x] Add `Download? download` to `BatchEntry`.
- [x] Change `create()` signature to `create(List<FileSystemEntity> sources,
      {Download? download})` and `addLateEntry()` to
      `addLateEntry(FileSystemEntity source, {Download? download})`.
- [x] In `_extractSingleEntry`, when `entry.download != null`: forward
      `onProgress` / `onPhaseChanged` to `download.installProgress`.
- [x] Still in `_extractSingleEntry`, after a Download-bearing entry succeeds:
      - Set `download.installProgress` to indeterminate / "Finalizing..." (so
        the notification doesn't freeze at 100% during the reload).
      - Trigger a mod-list reload (`reloadModVariants()`).
      - Look up the variant by `smolId` and set `download.installedVariant`.
      - Set `download.installComplete = true`.
      - Mark the entry as already reloaded (e.g. `entry.alreadyReloaded = true`)
        so `_finalize()` can skip re-reloading it.
- [x] In `_finalize()`, skip the reload for mods already covered by a
      Download-bearing entry's reload. If every installed entry was
      Download-bearing, skip the reload entirely.
- [x] When the selection dialog is cancelled for a `Download`-bearing entry, set
      **both** `download.installCancelled = true` **and**
      `download.installComplete = true` (matches `cancelInstallation()`).

## 3. Move mod-records write into the batch installer

- [x] In `_finalize()`, for each successfully installed mod, write the
      `InstalledSource` record and run the catalog-placeholder merge
      (`mergeSyntheticIntoReal`) — ported from the single-mod installer
      (`mod_manager_logic.dart` ~lines 142–186).
- [x] Confirm this now also covers plain archive batch installs (closes the
      existing gap).

## 4. Move the error dialog into the batch installer

- [x] When the pipeline ends with failed entries that have install errors, call
      `ModInstallationErrorDialog.show()` with those errors.

## 5. Avoid double history recording

- [x] In `_finalize()`, skip writing an `ActivityEntry` for entries that carry a
      `Download` (those are recorded by `ToastDisplayer`). Keep recording entries
      with no `Download`.

## 6. Repoint the callers

- [x] `add_new_mods_button.dart`: route `mod_info.json` picks to the batch
      installer with the parent folder as source and the `addInstallation`
      `Download` attached. Remove the `installModFromSourceWithDefaultUI` call.
- [x] `drag_drop_handler.dart`: route the directory branch to the batch
      installer (folder source + `addInstallation` `Download`). Remove the
      `installModFromSourceWithDefaultUI` call.
- [x] `download_manager.dart` (`downloadAndInstallMod`): after the download
      completes, call `addLateEntry(file, download: value)` instead of
      `installModFromSourceWithDefaultUI`. Keep the download-history record, the
      temp-folder cleanup, and the `installComplete` safety-net.

## 7. Delete the retired installer

- [x] Confirm nothing references `installModFromSourceWithDefaultUI` or
      `installModFromDisk` (grep).
- [x] Delete both from `mod_manager_logic.dart`.
- [x] Remove imports left unused only by the deletion (verify each before
      removing).

## 8. Verify

- [x] `flutter analyze` clean.
- [x] Run existing `test/mod_manager/batch_installation_test.dart`; extend it for
      a folder source if practical.
- [ ] Manual, per the design's verification focus:
      - Pick/drop a single-mod **archive** → installs, no dialog, history once.
      - Pick a `mod_info.json` / drop a **folder** with one mod → installs, no
        dialog, notification progresses, history once.
      - Drop a **folder with several mods** → selection dialog appears.
      - **Download** a mod (catalog link or Update button) → notification shows
        download then install progress, finished result, history once (not
        twice).
      - Force a failing install → error dialog appears.
