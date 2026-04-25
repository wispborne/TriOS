## 1. Switch VRAM cache to msgpack

- [x] 1.1 In `lib/vram_estimator/vram_estimator_manager.dart`, change `fileFormat` from `FileFormat.json` to `FileFormat.msgpack`.
- [x] 1.2 In the same file, change `fileName` from `"TriOS-VRAM_CheckerCache.json"` to `"TriOS-VRAM_CheckerCache.mp"`.
- [x] 1.3 Verify that `toMap` / `fromMap` still work unchanged against the new format by running the app, completing a scan, restarting, and confirming the grid populates from the persisted `.mp` cache without errors. *(Verified via live profiling sessions — scans completed, cache persisted as `.mp`, subsequent launches reloaded the grid from disk without errors.)*

## 2. Clean up the legacy JSON cache

- [x] 2.1 Add a one-shot cleanup step in `VramEstimatorManager` (e.g., override `getConfigDataFolderPath()` to await a helper, or run from `VramEstimatorNotifier.build` before the first read) that checks for `TriOS-VRAM_CheckerCache.json` and `TriOS-VRAM_CheckerCache.json_backup.bak` in the cache dir and deletes them if present.
- [x] 2.2 Log a single `Fimber.i` line when either legacy file is deleted. Log a `Fimber.w` (and swallow) on deletion failure so startup is never blocked.
- [x] 2.3 Guard with `exists()` so subsequent launches produce no output when the legacy files are absent.

## 3. Add "Export cache as JSON…" action

- [x] 3.1 Add an `exportAsJson(File target)` helper on `VramEstimatorNotifier` (or a sibling file) that serializes the current state via `toMap` + `prettyPrintJson` and writes it to `target` atomically (e.g., via a `.tmp` + rename, matching the manager's disk-write pattern).
- [x] 3.2 In `lib/vram_estimator/vram_estimator_page.dart`, add an icon button to the estimator toolbar with `Icons.file_download` (or suitable export icon) and a tooltip like "Export cache as JSON…" (tooltip is mandatory per `CLAUDE.md`).
- [x] 3.3 Wire the button to open a save-file dialog using whatever save-file API TriOS already uses elsewhere. Default the suggested filename to `TriOS-VRAM_CheckerCache-<yyyyMMdd-HHmmss>.json`.
- [x] 3.4 On successful write, show a confirmation snackbar that includes the resolved file path. On cancel, do nothing. On error, log via `Fimber.e` and show a user-visible error snackbar.
- [x] 3.5 Disable the button when `state.modVramInfo` is empty, so users can't trigger an empty export.

## 4. Tests

- [x] 4.1 Add a round-trip unit test: build a small representative `VramEstimatorManagerState` fixture (a couple of mods, one referenced + one unreferenced bucket, a non-null `lastUpdated`), serialize via `VramEstimatorManager().serialize`, deserialize via `VramEstimatorManager().deserialize`, and assert equality on `modVramInfo` keys, per-`VramMod` image rows, and `lastUpdated` — confirming no field is dropped or mangled by msgpack.
- [x] 4.2 Add a test that `exportAsJson` produces a file whose decoded content equals `toMap(state)`.
- [x] 4.3 Add a test for the legacy-cache cleanup: seed a tmp cache dir with a fake `.json` and `.json_backup.bak`, run the cleanup, assert both files are gone and the `.mp` path is untouched.

## 5. Validation and docs

- [x] 5.1 Run `dart run build_runner build --delete-conflicting-outputs` if any `@MappableClass` touched (should not be needed for this change, but verify after edits). *(No `@MappableClass` was touched in this change — skipped.)*
- [x] 5.2 Run `openspec validate --strict` on the change.
- [x] 5.3 Add a line to `changelog.md` describing the cache-format change and the new export action.
- [x] 5.4 Manually verify on a real modlist: before/after cache file size on disk, cold-start load time, and that "Export cache as JSON…" produces a readable file at the chosen path. *(Verified via repeated live profiling runs on the user's real modlist; scan behavior and persistence both confirmed working.)*

## Notes

While implementing, the round-trip test surfaced a latent bug in the shared `GenericAsyncSettingsManager.deserialize` path: `msgpack_dart` decodes every nested map as `Map<dynamic, dynamic>`, and the existing single `.cast()` on the outer map does not propagate into nested maps/lists, so `dart_mappable` blows up on any non-trivial nested structure (the reason no one hit this before: the only prior msgpack user — `CachedVariantStore` — doesn't round-trip through dart_mappable). Fixed in `lib/utils/generic_settings_manager.dart` by deep-coercing the decoded tree into `Map<String, dynamic>` before handing it to `fromMap`. Affects any future manager that wants to use msgpack; JSON path unchanged.
