# Tasks: Convert Synchronous I/O to Async

## Tier 1 — High Impact

- [ ] **app_settings_logic.dart**: Convert `loadSync`/`writeSync` to async. Replace `protectSync` with async `protect`. Convert all `readAsStringSync`, `writeAsStringSync`, `existsSync`, `copySync`, `createSync` calls.
- [ ] **main.dart**: Convert startup settings load (`loadSync` → async), lock file operations (`existsSync`, `writeAsStringSync`, `deleteSync`, `renameSync`), and shutdown cleanup to async.
- [ ] **seven_zip.dart**: Convert `Process.runSync` → `Process.run`, `openSync`/`readSync`/`closeSync` → async file access, and `existsSync`/`deleteSync` cleanup calls.
- [ ] **mod_manager_logic.dart**: Convert `listSync` → async `list()`, `existsSync` checks, `readAsStringSyncAllowingMalformed` → async, `createSync` → `create`.

## Tier 2 — Medium Impact

- [ ] **extensions.dart**: Add async variants of `renameSafelySync`, `copyDirectory`, `swapDirectoryWith`, `readAsStringSyncAllowingMalformed`. Migrate callers. Rename sync variants with `Sync` suffix where they don't already have one.
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
- [ ] Grep for remaining `Sync(` calls — confirm only intentional ones remain (constructors, `late final`, third-party code).
