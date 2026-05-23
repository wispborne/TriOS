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
- `app_settings_logic.dart`: Convert `loadSync`/`writeSync` and the `protectSync` lock to async variants.
- `main.dart`: Convert startup settings load and lock file operations.
- `seven_zip.dart`: Convert `openSync`/`readSync`/`closeSync` file access and `Process.runSync` calls.
- `mod_manager_logic.dart`: Convert directory listings and file reads during mod operations.

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

2. **Settings lock** — `app_settings_logic.dart` has a `protectSync` method using `synchronized` package. Replace with async `protect()` from the same package (it supports both).

3. **Extension methods** — Methods like `renameSafelySync` in `extensions.dart` are called from both sync and async contexts. Add async variants alongside and migrate callers incrementally. Remove sync variants once all callers are converted.

4. **7-Zip file reading** — The `openSync`/`readSync` loop reads archive bytes in chunks. Convert to `await file.open()` and `await raf.read()`. The surrounding function is already async.

## Files changed

Primary (Tier 1 + 2):
- `lib/trios/settings/app_settings_logic.dart`
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
