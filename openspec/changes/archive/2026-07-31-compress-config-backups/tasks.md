# Tasks: Zip up the backup files TriOS makes

## The helper

- [x] Add `lib/utils/backup_compression.dart` with `Future<void> compressBackupFile(File plainBackup)`.
- [x] Work out the archive path by swapping `.bak` for `.7z`, and delete any existing archive at that path first (`7z a` adds to an archive instead of replacing it).
- [x] Compress with `SevenZip.createArchive`, then delete the plain `.bak` only if the archive was written.
- [x] Wrap the whole thing in a try/catch: log a warning with `Fimber.w` and leave the plain `.bak` in place on any failure.
- [x] Hold one lazily-created `SevenZip` in the helper file rather than building a new one per call.

## Settings managers built on `GenericAsyncSettingsManager`

- [x] Add `File getBackupArchiveFile()` returning `<fileName>_backup.7z`.
- [x] Add `DateTime? lastBackupTime()` returning the newer timestamp of the archive and the plain `.bak`, or `null` if neither exists. (Made it async — the one caller is already async, and the `sync-to-async-io` change wants that call site off sync I/O anyway.)
- [x] Have `createBackup()` await `compressBackupFile(getBackupFile())` after the copy.
- [x] Point the 30-minute freshness check in `GenericSettingsAsyncNotifier.build()` at `lastBackupTime()` instead of `getBackupFile().existsSync()` / `.lastModifiedSync()`.

## Main settings file (`SettingsFileManager`)

- [x] Change the numbering loop in `_createBackupSync()` to skip a number if either `_backup_N.bak` or `_backup_N.7z` exists.
- [x] Start compression after the copy without awaiting it, so a failed load isn't held up.

## Tests

- [x] Add `test/backup_compression_test.dart`, tagged `local-only`, using `SevenZip.fromPath` with the bundled binary the way `test/7zip_test.dart` does.
- [x] Test the round trip: compress a temp `.bak`, then check the `.7z` exists, the `.bak` is gone, and the extracted bytes match the original.
- [x] Run `flutter analyze` and `flutter test`. (613 tests pass; the two analyzer warnings in `app_settings_logic.dart` were already there.)

## Checks by hand

- [x] Start TriOS, wait for a backup to be made, and confirm the config folder has a `.7z` and no leftover `.bak`.
- [x] Restart within 30 minutes and confirm no second backup is made (the freshness check reads the archive).
- [x] Corrupt `trios_settings-v1.json` on purpose, start TriOS, and confirm a numbered `.7z` appears with the broken file inside — not the replacement defaults.
- [x] Rename the bundled 7-Zip binary, make a backup, and confirm the plain `.bak` survives and a warning is logged.
