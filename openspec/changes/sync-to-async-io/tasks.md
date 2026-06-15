# Tasks: Convert Synchronous I/O to Async

## Tier 1 — High Impact

- [x] **app_settings_logic.dart**: OUT OF SCOPE — `loadSync`/`writeSync` feed the synchronous `AppSettingNotifier.build()` (watched app-wide). Converting forces an `AsyncNotifier` migration. Leave sync. (Async settings I/O belongs in the already-async `GenericSettingsManager` path instead.)
- [x] **main.dart**: Convert lock-file operations (`existsSync`, `writeAsStringSync`, `deleteSync`, `renameSync` in `main()` and `onWindowClose()`) and the startup cache-file migration loop to async. Do NOT convert the startup settings load — it feeds the sync settings Notifier.
- [x] **seven_zip.dart**: Convert only the `existsSync`/`deleteSync` cleanup calls that are already inside async methods. OUT OF SCOPE: the constructor's `Process.runSync` (`uname`/`chmod` — constructors can't be async) and the `_describeArchiveError` static `openSync`/`readSync`/`closeSync` reader (static error-path, ~512 bytes).
- [x] **mod_manager_logic.dart**: Convert `listSync` → `await list().toList()` (keep `.toList()` — do not use a lazy stream on the move loop, see Concurrency note), `existsSync` checks, `readAsStringSyncAllowingMalformed` → async (this call site is in an async method), `createSync` → `create`.

## Tier 2 — Medium Impact

- [ ] **extensions.dart**: Add async variants of `renameSafelySync`, `copyDirectory`, `swapDirectoryWith` and migrate callers (`renameSafelySync` has 3 callers, all already async). KEEP `readAsStringSyncAllowingMalformed` — `ModVariant`'s constructor and sync `iconFilePath` getter need it. `readAsStringUtf8OrLatin1` is already async (6 callers already await it) — no work. Document `swapDirectoryWith`/`copyDirectory` async forms as non-atomic (no cross-`await` rollback). Remove a sync variant only when it has zero callers.
- [ ] **cached_json_fetcher.dart**: Convert all `readAsStringSync`, `writeAsStringSync`, `createSync`, `deleteSync` calls to async.
- [ ] **self_updater.dart**: Convert `createTempSync`, `listSync`, `deleteSync`, `createSync`, `existsSync`, `Process.runSync` to async.
- [ ] **download_manager.dart**: Convert `createTempSync`, `existsSync`, `deleteSync` to async.
- [ ] **enabled_mods.dart**: Convert `writeAsStringSync`, `createSync` to async.
- [ ] **vmparams_manager.dart**: Convert `existsSync`, `readAsStringSync` to async.
- [ ] **logging.dart**: Convert `existsSync`, `createSync`, `listSync`, `readAsStringSync`, `writeAsStringSync` to async.
- [ ] **mod_variants.dart**: Convert `listSync` to async `list()`.
- [ ] **mod_profiles_manager.dart**: Convert `readAsStringSync` to async.
- [ ] **mod_file_utils.dart**: Convert `existsSync`, `readAsStringSync` to async.

## Tier 3 — Low Impact

> Each item below is a mechanical conversion *only if* its call site is already async. Re-verify the enclosing context (not a constructor / getter / `late final` / sync override) before converting each one.


- [ ] **launcher.dart**: Convert `readAsStringSync`, `PlistParser().parseFileSync`, `FileSystemEntity.typeSync` to async.
- [ ] **ship_manager.dart**: Convert `listSync` calls to async.
- [ ] **weapon_viewer/weapons_manager.dart**: Convert `listSync` to async.
- [ ] **viewer_cache/cached_variant_store.dart**: Convert `listSync`, `deleteSync` to async.
- [ ] **util.dart**: Convert `existsSync`, `listSync`, `readAsBytesSync`, `deleteSync`, `lastModifiedSync` to async.
- [ ] **platform_specific.dart**: Convert `deleteSync`, `Process.runSync` to async.
- [ ] **portraits_page.dart**: Convert `existsSync`, `lengthSync` to async.
- [ ] **chipper_app.dart**: Convert `readAsBytesSync` to async.
- [ ] **tips_notifier.dart**: Convert `existsSync`, `readAsStringSync` to async.
- [ ] **graphics_lib_config_provider.dart**: Convert `existsSync`, `readAsStringSync` to async.
- [ ] **_mod_variant_core.dart**: Convert `renameSync` to async `rename`.
- [ ] **mod_install_source.dart**: Convert `listSync` to async.
- [ ] **catalog_data_sources_dialog.dart**: Convert `statSync` to async.
- [ ] **faction_viewer files**: Convert `existsSync` calls to async.
- [ ] **script_generator.dart**: Convert `existsSync`, `createSync`, `listSync` to async.
- [ ] **game_paths_controller.dart**: Convert `existsSync` calls to async.
- [ ] **generic_settings_notifier.dart**: Convert `existsSync`, `lastModifiedSync` to async.
- [ ] **gpu_info.dart**: Convert `Process.runSync` to `Process.run`.
- [ ] **win32_process_detector.dart**: Convert `existsSync`, `resolveSymbolicLinksSync` to async.
- [ ] **thirdparty/dartx/io/directory.dart**: Convert `identicalSync`, `listSync` to async.

## Verification

- [ ] Run `flutter analyze` — no new warnings.
- [ ] Run `flutter test` — all tests pass.
- [ ] Grep for remaining `Sync(` calls — confirm only intentional ones remain: the documented sync-only blockers (settings Notifier `loadSync`/`writeSync`, `SevenZip` constructor `Process.runSync`, `_describeArchiveError` reader, `ModVariant` icon path), plus constructors, `late final` initializers, and third-party code.
