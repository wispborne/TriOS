# Design: Zip up the backup files TriOS makes

## Approach

Both backup paths already copy the live file to a plain `.bak`. Keep that step. Add a step after it: compress the `.bak` into a `.7z` beside it, then delete the `.bak`.

Compressing the copy — not the live file — matters. On the "settings file won't load" path, TriOS overwrites the live file with defaults right after making the backup. If 7-Zip were reading the live file at that moment, it could archive the fresh defaults instead of the broken file we're trying to save. Compressing the copy removes that race entirely, and it means the fallback needs no extra code: if compression fails, the `.bak` is already sitting there.

The tradeoff is the name inside the archive. `trios_settings-v1.json_backup.7z` will contain a file called `trios_settings-v1.json_backup.bak`, so restoring means unzipping *and* renaming. That's acceptable for a manual safety net, and it buys a much simpler, safer implementation.

## Key decisions

**One helper, two callers.** New file `lib/utils/backup_compression.dart`:

```dart
/// Compresses [plainBackup] into a .7z beside it and deletes the plain file.
/// If anything goes wrong, the plain file is left alone.
Future<void> compressBackupFile(File plainBackup) async
```

The archive path is the backup path with `.bak` swapped for `.7z`. Delete any existing archive at that path first — `7z a` adds to an existing archive rather than replacing it. On success, delete the plain file. On any error, log a warning and return; the plain file stays.

**One shared `SevenZip` instance, created on first use.** Its constructor runs `chmod` on macOS and Linux, so don't build a new one per backup. Backups are rare, so a simple lazily-created value in the helper file is enough.

**The async path awaits; the sync path doesn't.**

- `GenericAsyncSettingsManager.createBackup()` is already async, so it can `await compressBackupFile(...)`.
- `SettingsFileManager._createBackupSync()` runs inside a synchronous lock during startup. It kicks off compression without awaiting. Nothing waits on the result, and the work only touches the backup file, so it can't hold up loading or collide with the lock.

**Freshness check moves off the file path.** `GenericSettingsAsyncNotifier.build()` currently calls `settingsManager.getBackupFile().existsSync()` and `.lastModifiedSync()` to decide whether the last backup is older than 30 minutes. Once backups become `.7z`, that path stops existing and TriOS would back up on every launch.

Add `DateTime? lastBackupTime()` to `GenericAsyncSettingsManager`: the newer timestamp of the `.7z` and the `.bak`, or `null` if neither is there. The notifier asks that instead of poking at paths. This also fixes a small existing oddity — `File.copy` carries the source's timestamp across on Windows, so the old check was really reading the settings file's write time. A freshly written archive is stamped with the time it was made.

**Numbered backups need to count both kinds.** `_createBackupSync()` picks the next free number by looping while `<name>_backup_N.bak` exists. Once older backups are `.7z`, that loop would reuse numbers and overwrite them. Change the loop to skip a number if either `_backup_N.bak` or `_backup_N.7z` exists.

## Files changed

| File | Change |
| --- | --- |
| `lib/utils/backup_compression.dart` | New. The `compressBackupFile` helper and the shared `SevenZip` instance. |
| `lib/utils/generic_settings_manager.dart` | `createBackup()` compresses after copying. Add `getBackupArchiveFile()` and `lastBackupTime()`. |
| `lib/utils/generic_settings_notifier.dart` | The 30-minute check uses `lastBackupTime()`. |
| `lib/trios/settings/app_settings_logic.dart` | `_createBackupSync()` starts compression without awaiting; the numbering loop checks both extensions. |
| `test/backup_compression_test.dart` | New. Round-trip test against the bundled 7-Zip binary. |

## Testing

`test/7zip_test.dart` shows the pattern: tag the test `local-only` and build the handler with `SevenZip.fromPath` pointing at `assets/windows/7zip/7z.exe`, since the normal constructor needs a packaged app to find its assets.

The test writes a temp `.bak`, compresses it, and checks that the `.7z` exists, the `.bak` is gone, and extracting gives back the original bytes.

The failure path (no 7-Zip, plain file survives) is easiest to confirm by hand rather than by building an abstraction just to inject a broken binary — see the manual checks in `tasks.md`.
