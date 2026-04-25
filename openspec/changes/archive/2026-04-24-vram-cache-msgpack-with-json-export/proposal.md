## Why

The VRAM checker scan result is persisted to `TriOS-VRAM_CheckerCache.json` via `GenericAsyncSettingsManager` with `FileFormat.json`. For users with large modlists, that cache grows into many megabytes of pretty-printed JSON — slow to read/write and wasteful on disk. A binary msgpack format (already available in `GenericAsyncSettingsManager` and already used by the viewer cache with a `.mp` extension) is dramatically smaller and faster, while keeping the same map-shaped payload. We still want humans to be able to inspect the cache for debugging, so we need an on-demand "export as JSON" escape hatch.

## What Changes

- **BREAKING (cache file only, not spec requirements)**: `VramEstimatorManager` switches from JSON to msgpack. The persisted file is renamed `TriOS-VRAM_CheckerCache.mp`; the old `TriOS-VRAM_CheckerCache.json` is no longer read or written.
- On startup, a one-shot migration deletes any pre-existing `TriOS-VRAM_CheckerCache.json` (and its `_backup.bak` sibling) so stale JSON caches don't linger on disk. There is no attempt to convert old JSON into msgpack — the VRAM scan is re-runnable, and a cold scan is cheaper than supporting a migration path.
- Add a user-facing "Export cache as JSON…" action in the VRAM estimator toolbar (icon with tooltip, per the project's tooltip rule) that serializes the current in-memory `VramEstimatorManagerState` to pretty-printed JSON and writes it to a user-chosen path via a standard save-file dialog. This action does not change what's persisted on disk; it only produces an ad-hoc artifact for inspection.
- The export action is available whenever the cache is non-empty (after a scan has run, or after a cached msgpack cache has loaded). While a scan is in progress, the button remains enabled and exports whatever has been persisted most recently.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `vram-estimator`: The estimator's persistence-format behavior and the toolbar's set of user-triggered actions both change. Today's spec is silent on persistence format and does not describe an export action; both become explicit requirements.

## Impact

- **Code**:
  - `lib/vram_estimator/vram_estimator_manager.dart` — change `fileFormat` to `FileFormat.msgpack`, change `fileName` to `.mp`, add one-shot deletion of any legacy `.json` cache + `.json_backup.bak`.
  - `lib/vram_estimator/vram_estimator_page.dart` — add an "Export cache as JSON…" icon button to the toolbar with a tooltip, wired to a new export method on `VramEstimatorNotifier` (or a small helper).
  - `lib/vram_estimator/vram_estimator_manager.dart` (or a sibling file) — add an `exportAsJson(File target)` method that serializes `toMap(state)` via `jsonEncode` with pretty printing, using the existing `prettyPrintJson` extension already used for JSON persistence.
- **Dependencies**: None added. `msgpack_dart` is already a direct dependency and is already used by `GenericAsyncSettingsManager` and `CachedVariantStore`. `file_selector` / `file_picker` or whatever the project already uses for save dialogs is reused; no new dep.
- **On-disk artifacts**: After this change, `{cacheDir}/TriOS-VRAM_CheckerCache.mp` replaces `{cacheDir}/TriOS-VRAM_CheckerCache.json`. Binary, not human-readable; export is the escape hatch.
- **User impact**: First launch after upgrade loses the previous JSON cache (old file is deleted, new `.mp` is absent) — next scan rebuilds it. No data is lost that the user can't reproduce by pressing "refresh".
