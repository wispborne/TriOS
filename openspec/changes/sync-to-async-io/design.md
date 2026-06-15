# Design: Convert Synchronous I/O to Async

## Approach

Replace `*Sync()` dart:io calls with their async equivalents. Work file-by-file, converting call sites to `async`/`await` where needed.

### Conversion patterns

| Sync call | Async replacement |
|---|---|
| `file.readAsStringSync()` | `await file.readAsString()` |
| `file.writeAsStringSync(s)` | `await file.writeAsString(s)` |
| `file.existsSync()` | `await file.exists()` |
| `file.deleteSync()` | `await file.delete()` |
| `file.copySync(p)` | `await file.copy(p)` |
| `file.renameSync(p)` | `await file.rename(p)` |
| `file.statSync()` | `await file.stat()` |
| `file.lengthSync()` | `await file.length()` |
| `file.readAsBytesSync()` | `await file.readAsBytes()` |
| `dir.listSync()` | `await dir.list().toList()` |
| `dir.createSync()` | `await dir.create()` |
| `dir.deleteSync()` | `await dir.delete()` |
| `Process.runSync(cmd, args)` | `await Process.run(cmd, args)` |
| `FileSystemEntity.typeSync(p)` | `await FileSystemEntity.type(p)` |
| `FileSystemEntity.isDirectorySync(p)` | `await FileSystemEntity.isDirectory(p)` |

### Tiers (by impact)

**Tier 1 — High impact (blocks UI or startup)**
- `main.dart`: Convert lock-file operations (`existsSync`/`writeAsStringSync`/`deleteSync` in `main()` and `onWindowClose()`) and the startup cache-file migration loop. The synchronous settings load stays sync (it feeds the sync settings Notifier — see Blocked).
- `seven_zip.dart`: Convert the `existsSync`/`deleteSync` cleanup calls that already sit inside async methods. The constructor's `Process.runSync` and the `_describeArchiveError` static reader are sync-only — see Blocked.
- `mod_manager_logic.dart`: Convert directory listings and file reads during mod operations (all in async methods). Keep `.toList()` materialization on the move loop — see Concurrency note.

(`app_settings_logic.dart` is intentionally absent — see Blocked / out of scope.)

**Tier 2 — Medium impact (occasional jank)**
- `cached_json_fetcher.dart`: Async cache reads/writes.
- `self_updater.dart`: Async directory operations during update flow.
- `download_manager.dart`: Async temp directory creation/cleanup.
- `enabled_mods.dart`: Async writes to enabled mods file.
- `vmparams_manager.dart`: Async reads of VM parameter files.
- `logging.dart`: Async log folder creation and file listing.
- `extensions.dart`: Convert utility methods (`renameSafelySync`, `copyDirectory`, `swapDirectoryWith`, `readAsStringSyncAllowingMalformed`).

**Tier 3 — Low impact (infrequent or fast)**
- `existsSync()` guard checks that are single-file and fast.
- `statSync()` for display purposes.
- Platform-specific utilities.
- Third-party extensions.

## Key decisions

1. **Skip trivial `existsSync` checks** — A lone `file.existsSync()` before reading a file is fast and converting it adds `await` noise. Convert only when it's part of a chain of sync operations.

2. **Settings lock** — `app_settings_logic.dart` does *not* use the `synchronized` package; it uses a hand-rolled `SyncLock` class (a non-queuing mutex that throws `StateError` if already locked). The project's async lock is the `mutex` package (`Mutex`), used in `generic_settings_manager.dart`, `enabled_mods.dart`, `mod_variants.dart`, etc. Settings I/O stays synchronous in this change (see Blocked). *If* it is ever made async in a separate effort: swap `SyncLock` → `Mutex`, keep the entire read→serialize→write inside a single `mutex.protect()` so the lock is held across awaits, and make the debounce `Timer` callback in `_scheduleWriteSettings` `async` so it awaits the write *before* completing its `Completer` (otherwise the returned future resolves before bytes hit disk).

3. **Extension methods** — Methods like `renameSafelySync` in `extensions.dart` are called from both sync and async contexts. Add async variants alongside and migrate callers incrementally. Remove a sync variant *only* when it has zero remaining callers. Note: `readAsStringSyncAllowingMalformed` must be **kept** — `ModVariant`'s constructor and its synchronous `iconFilePath` getter call it and cannot be made async (see Blocked). `readAsStringUtf8OrLatin1` is already async; its 6 callers already await it, so no work is needed there.

4. **7-Zip file reading** — The `openSync`/`readSync`/`closeSync` loop lives in the `static` method `_describeArchiveError`, which reads ~512 diagnostic bytes only on an error path. It is *not* in an already-async function. Converting it would require making it an async instance method for negligible benefit, so it is out of scope (see Blocked). The convertible 7-Zip work is the `existsSync`/`deleteSync` cleanup that already sits inside async methods.

## Blocked / out of scope (sync-only contexts)

These cannot be converted without a refactor larger than this change allows. Leave them sync and do not treat them as mechanical swaps:

- **Settings Notifier I/O** — `SettingsFileManager.loadSync`/`writeSync` feed `AppSettingNotifier.build()`, a synchronous Riverpod `Notifier.build()` watched app-wide. Making them async forces an `AsyncNotifier` migration (out of scope per proposal Non-Goals).
- **`SevenZip()` constructor `Process.runSync`** (`uname`, `chmod` on Linux/macOS) — constructors cannot be async; would need a factory + async-init refactor.
- **`SevenZip._describeArchiveError`** static `openSync`/`readSync`/`closeSync` reader — static error-path method, tiny read, not worth converting (see decision #4).
- **`ModVariant` icon path** — `_calculateIconPath` (using `readAsStringSyncAllowingMalformed`/`existsSync`) is called from the `ModVariant` constructor and the synchronous `iconFilePath` getter. Both are sync-only, so the sync `readAsStringSyncAllowingMalformed` extension must be kept.

## Concurrency note

Each sync→async swap inserts an `await` suspension point, so code that today runs without yielding the event loop will now interleave with other tasks. Two consequences to respect:

- **Multi-step "atomic" helpers** — `swapDirectoryWith` and `copyDirectory` in `extensions.dart` have no cross-`await` rollback guarantee; their async forms must be documented as non-atomic. (Both currently have zero callers, so immediate risk is low.)
- **Do not convert the `mod_manager_logic.dart` move loop to a lazy stream.** It iterates a directory listing while renaming files into other folders; `listSync()` and `await list().toList()` both materialize a snapshot (safe), but switching to a lazy `list()` stream would introduce a concurrent-modification bug.

## Files changed

Primary (Tier 1 + 2):
- `lib/main.dart`
- `lib/compression/seven_zip/seven_zip.dart`
- `lib/mod_manager/mod_manager_logic.dart`
- `lib/utils/cached_json_fetcher.dart`
- `lib/trios/self_updater/self_updater.dart`
- `lib/trios/download_manager/download_manager.dart`
- `lib/trios/data_cache/enabled_mods.dart`
- `lib/vmparams/vmparams_manager.dart`
- `lib/utils/logging.dart`
- `lib/utils/extensions.dart`
- `lib/trios/mod_variants.dart`
- `lib/mod_profiles/mod_profiles_manager.dart`
- `lib/mod_manager/utils/mod_file_utils.dart`

Secondary (Tier 3, as time allows):
- `lib/launcher/launcher.dart`
- `lib/ship_viewer/ship_manager.dart`
- `lib/weapon_viewer/weapons_manager.dart`
- `lib/viewer_cache/cached_variant_store.dart`
- `lib/portraits/portraits_page.dart`
- `lib/chipper/chipper_app.dart`
- `lib/utils/util.dart`
- `lib/utils/platform_specific.dart`
- `lib/utils/platform_paths.dart`
- `lib/tips/tips_notifier.dart`
- `lib/vram_estimator/graphics_lib_config_provider.dart`
- `lib/mod_manager/services/_mod_variant_core.dart`
- `lib/mod_manager/mod_install_source.dart`
- `lib/catalog/catalog_data_sources_dialog.dart`
- `lib/faction_viewer/faction_viewer_page.dart`
- `lib/faction_viewer/widgets/faction_profile_dialog.dart`
- `lib/trios/self_updater/script_generator.dart`
- `lib/widgets/game_paths_widget/game_paths_controller.dart`
- `lib/utils/generic_settings_notifier.dart`
