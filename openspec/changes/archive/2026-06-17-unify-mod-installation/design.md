# Design

## Where the two paths meet today

Both paths already call the same low-level extractor, `installMod()` in
`lib/mod_manager/mod_manager_logic.dart`, which calls
`ModInstallSource.createFilesAtDestination()`. That stays untouched. Everything
above it is what differs.

The single-mod installer wraps `installMod()` with four things the batch
installer lacks. The whole change is moving those four things into the batch
installer, repointing callers, and deleting the wrapper.

## The key complication: who owns progress and history

This is the part to get right, because the two paths report progress and record
history through different machinery.

- A **download or a folder install** creates a `Download` object (via
  `addDownload` or `addInstallation` in
  `lib/trios/download_manager/download_manager.dart`). The floating
  notification (`ModDownloadToast`) is built per `Download` and reads five
  notifiers on it: `task.status`, `installProgress`, `installComplete`,
  `installedVariant`, `installCancelled`. Separately, `ToastDisplayer`
  (`lib/trios/toasts/toast_manager.dart`) watches the list of `Download`s and
  writes one `ActivityEntry` to the history when each finishes — keyed by
  `download.id` so it records each one once.

- A **batch archive install** has no `Download`. The batch installer's
  `_finalize()` writes the `ActivityEntry` itself.

So if a downloaded archive starts flowing through the batch installer while
still carrying its `Download`, two things must hold:

1. The batch installer must drive that `Download`'s notifiers, or the
   notification freezes.
2. Exactly one place must record the history entry, or it shows up twice.

**Decision:** a batch entry may carry an optional `Download`. Entries that
carry one are recorded by `ToastDisplayer` (unchanged); `_finalize()` skips
history for them. Entries with no `Download` (plain archive picks/drops) are
recorded by `_finalize()` exactly as today.

## Changes to the batch model

`lib/mod_manager/batch_installation/batch_installation.dart`

- Generalize the entry's source. `BatchEntry.archiveFile` (a `File`) becomes a
  `FileSystemEntity source` that is either a `File` (archive) or a `Directory`
  (folder). Add `bool get isDirectory => source is Directory`. Update
  `displayName` and the activity `sourceDetail` to read `source.path`.
- Add `Download? download` to `BatchEntry` (null for plain archive picks/drops;
  set for folder installs and downloads).

## Changes to the scanner

`lib/mod_manager/batch_installation/batch_pre_scanner.dart`

`scanArchive()` becomes source-aware (rename to `scanEntry()`):

- If the source is a folder, build a `DirectoryModInstallSource` and list files
  with its `listFilePaths()` instead of `archive.listFiles()`; skip the
  archive-extension check. Read the `mod_info.json` file(s) with the source's
  `getActualFiles()`. The rest — parsing, conflict check, building
  `ScannedArchive` — is identical.
- If the source is an archive, behave exactly as now.

`ScannedArchive.archiveFileList` already feeds extraction; for a folder it holds
the folder's file listing, which `installMod()` consumes the same way.

## Changes to the installer

`lib/mod_manager/batch_installation/batch_installation_notifier.dart`

- **Entry points accept a `Download` and folders.** `create()` becomes
  `create(List<FileSystemEntity> sources, {Download? download})` and
  `addLateEntry()` becomes `addLateEntry(FileSystemEntity source, {Download?
  download})`. Both accept a `File` (archive) or a `Directory` (folder). Folder
  installs and downloads go through the normal pipeline so they still get the
  selection dialog when the source holds multiple mods or conflicts (matching
  the single-mod installer's current behavior). `addLateEntry`'s "join a batch
  already extracting" shortcut keeps installing all mods without a dialog, as it
  does now.

- **Drive the `Download` during and after extraction.** The notification must
  reflect each download's state immediately — not wait for an entire batch to
  finish. So Download-bearing entries do their own mini-reload right after
  extraction, while plain batch entries still share the single reload in
  `_finalize()`.

  In `_extractSingleEntry()`, when `entry.download != null`:
  - `onProgress` / `onPhaseChanged` also update `entry.download.installProgress`
    (using `TriOSDownloadProgress`, same shape the single-mod installer used).
  - After extraction succeeds, set `installProgress` to indeterminate /
    "Finalizing..." (prevents the notification from freezing at 100%), trigger a
    mod-list reload, look up the freshly installed variant by `smolId`, set
    `download.installedVariant`, and set `download.installComplete = true`.

  In `_finalize()`, skip the reload for mods that were already reloaded by a
  Download-bearing entry (track with a flag on the entry, e.g.
  `alreadyReloaded`). If *only* Download-bearing entries were installed,
  `_finalize()` can skip its own reload entirely.

  On cancellation (user dismisses the selection dialog for a Download-bearing
  entry): set **both** `download.installCancelled = true` **and**
  `download.installComplete = true` — the notification waits for
  `installComplete` before it reacts, so both are required. (This matches
  `cancelInstallation()` in download_manager.dart.)

- **Write mod records.** Move the `InstalledSource` write and the
  catalog-placeholder merge (`mergeSyntheticIntoReal`) out of the single-mod
  installer and into `_finalize()`, applied to every successfully installed mod.
  This also fixes the existing gap where batch-installed archives never got an
  `InstalledSource` record.

- **Show the error dialog.** When the pipeline finishes with any failed entry
  that has install errors, call `ModInstallationErrorDialog.show()` with those
  errors, matching the single-mod installer. The inline batch UI still shows its
  own per-entry state; this adds the modal that downloads/folder installs show
  today.

## Changes to the callers

1. **`lib/widgets/add_new_mods_button.dart`** — the loop over picked
   `mod_info.json` files calls the batch installer with the parent folder as the
   source (and the `addInstallation` `Download` attached), instead of
   `installModFromSourceWithDefaultUI`.

2. **`lib/trios/drag_drop_handler.dart`** — `_handleDroppedModFilesAndFolders`
   already sends archives to the batch installer. The directory branch now does
   the same (folder as source, `addInstallation` `Download` attached) instead of
   calling `installModFromSourceWithDefaultUI`.

3. **`lib/trios/download_manager/download_manager.dart`** — in
   `downloadAndInstallMod`, after the download completes, hand the downloaded
   file to the batch installer via `addLateEntry(file, download: value)` instead
   of `installModFromSourceWithDefaultUI`. Keep the surrounding logic: the
   download-history mod record (separate from `InstalledSource`), the temp-folder
   cleanup, and the `installComplete` safety-net in `finally`. The batch
   installer now drives `installProgress` / `installedVariant`, so the toast
   behaves as before.

## Removal

Once nothing calls them, delete from `lib/mod_manager/mod_manager_logic.dart`:

- `installModFromSourceWithDefaultUI`
- `installModFromDisk`

Keep (the batch installer already uses these): `installMod`,
`setUpNewHighestModVersionFolder`, `cleanUpModVariantsBasedOnRetainSetting`,
`cleanUpAllModVariantsBasedOnRetainSetting`, `changeActiveModVariant`, and the
record/variant helpers. Remove any imports in `mod_manager_logic.dart` left
unused only by the deletion (e.g. the install selection/ error dialog imports if
no longer referenced there — verify before removing).

## Behavior differences to accept (small, intentional)

- **Re-downloading the exact same version.** The single-mod installer asks
  "replace?" when the identical version is already installed; the batch
  installer's join-a-batch path replaces silently. A normal update is a new
  version (new `smolId`), so it is not a conflict and is unaffected. Only the
  rare "install the very same version again" case changes, and silent replace is
  the reasonable outcome for an explicit download. Standalone downloads (no
  active batch) still run the full pipeline and still get the dialog.
- **Batch archives now get an `InstalledSource` record** and an error dialog on
  failure. These are gaps being closed, not regressions.

## What could go wrong / verification focus

- Double history entries — confirm `_finalize()` skips `Download`-bearing
  entries and `ToastDisplayer` still records them once.
- Frozen notification — confirm progress, finished result, and cancel all reach
  the `Download` for both a folder install and a downloaded archive.
- Folder scan — confirm a dropped folder with one mod installs with no dialog,
  and a folder with several mods shows the picker.
