## Context

The VRAM estimator persists its last scan result via `GenericAsyncSettingsManager` (`lib/utils/generic_settings_manager.dart`) so that results survive app restarts and the grid renders instantly on launch instead of waiting for a rescan. Today, `VramEstimatorManager` declares `fileFormat => FileFormat.json` and `fileName => "TriOS-VRAM_CheckerCache.json"` (`lib/vram_estimator/vram_estimator_manager.dart:54-57`), producing a pretty-printed JSON file.

The payload is the full `VramEstimatorManagerState`, which wraps `Map<String, VramMod>` keyed by smolId. Each `VramMod` contains referenced and (optionally) unreferenced `ModImageTable`s, which in turn hold one row per image asset. For a large modlist, this serializes to a very large JSON document — tens of MB is plausible, read and written every time the cache is loaded or a scan finishes.

`GenericAsyncSettingsManager` already supports `FileFormat.msgpack` via `msgpack_dart` and is used as such elsewhere. `lib/viewer_cache/cached_variant_store.dart:25` establishes the project convention for the binary extension: `.mp`. Switching the VRAM cache to msgpack is a one-line change in `fileFormat` and a filename change, with identical `toMap` / `fromMap` contracts on either side.

The only user-visible downside of binary is that developers and power users can no longer open the cache file and read it. The project has precedent (per CLAUDE.md, `.withOpacity` deprecated, tooltips required on new icons) for small, explicit toolbar affordances. An "Export as JSON…" button satisfies the debugging use case without compromising the on-disk win.

## Goals / Non-Goals

**Goals:**
- Shrink the on-disk VRAM cache and make load/save faster by switching to msgpack.
- Keep the persisted payload semantically identical (same `toMap` output, same `fromMap` behavior).
- Preserve the ability to inspect the cache contents when debugging, via an explicit user-initiated export.
- Clean up the old `.json` cache file on first launch after upgrade so users aren't left with an orphaned multi-MB file.

**Non-Goals:**
- No in-place conversion of old JSON caches to msgpack. The cache is regenerable by re-running the scan; a migration path is not worth the complexity.
- No change to `VramEstimatorManagerState`, `VramMod`, or any of their `@MappableClass` shapes. The serialized *bytes* change; the *map* does not.
- No new export formats (YAML, TOML, CSV). JSON is the one escape hatch.
- No auto-export on every scan. Export is only on explicit user action.
- No change to other managers that use `FileFormat.json` (mod records, tips, profiles, etc.). This change is scoped to the VRAM cache.

## Decisions

### Decision: Use msgpack (`.mp`) rather than another binary format

`GenericAsyncSettingsManager` already has `FileFormat.msgpack` wired through `serialize`/`deserialize` (`lib/utils/generic_settings_manager.dart:171,183`), and `CachedVariantStore` already writes `.mp` files under the config dir. Adopting msgpack requires zero new dependencies and follows a pattern the codebase has already validated.

Alternatives considered:
- **gzip-compressed JSON** — readable with `gunzip`, but requires a custom `serialize`/`deserialize` override since the shared manager doesn't support it today. More code, less uniform with the viewer cache.
- **Protobuf / FlatBuffers** — overkill; requires schema files and code generation; the payload shape is driven by dart_mappable, not an IDL.
- **SQLite** — wrong shape; the cache is a snapshot replaced wholesale, not a row-queryable store.

### Decision: Delete the legacy JSON cache on first launch post-upgrade rather than migrating it

`GenericAsyncSettingsManager.read()` looks up the file by `fileName`. When `fileName` changes from `.json` to `.mp`, the old file is simply never consulted — it sits orphaned until the user clears their cache dir manually. That's a bad user experience (tens of MB of dead data) and, if a future developer renames the file back, they'd inadvertently load a stale cache.

The chosen approach: `VramEstimatorManager` overrides `getConfigDataFolderPath()` already; we extend it (or add a one-shot init hook on the notifier) to delete `TriOS-VRAM_CheckerCache.json` and `TriOS-VRAM_CheckerCache.json_backup.bak` if they exist, the first time the manager resolves its directory.

Alternatives considered:
- **Read the old JSON, decode it, write it as msgpack, delete the JSON.** Strictly-better UX (no data loss), but the payload is not precious (the user can regenerate it with a single button press, which is what a "refresh" already does) and the migration code would need to outlive the one release it's useful in.
- **Do nothing; let the old file sit.** Rejected — leaves multi-MB orphans on disk.

### Decision: Export to a user-chosen file path via a save-file dialog, not a fixed location

The export artifact is only useful for a specific debugging session; writing to a well-known path inside the config dir would either clobber on every export or pile up. A save dialog lets the user drop the file wherever they're investigating (Downloads, a scratch dir, an issue-report folder) and name it descriptively.

Default filename: `TriOS-VRAM_CheckerCache-YYYYMMDD-HHMMSS.json`, so users can export multiple times without clobbering.

### Decision: Export serializes the in-memory state, not re-read from disk

The in-memory `VramEstimatorManagerState` is authoritative while a scan is in progress and immediately after it completes (before debounced write lands). Exporting the in-memory state gives the user the result they can *see* in the UI. Re-reading from disk could produce a stale export (from before the current scan completed).

Since `toMap` already produces the exact structure that gets msgpack-encoded, JSON export uses the same `toMap` output passed through `prettyPrintJson` — guaranteeing parity between what's on disk (binary) and what's in the export (text).

### Decision: Export button lives on the VRAM estimator toolbar

The toolbar already holds refresh and selector controls. Adding one more icon button (with a required tooltip per project convention) keeps discovery local to the feature. The button is placed adjacent to the refresh button and uses `Icons.file_download` (or a suitable export icon). It is disabled when `state.modVramInfo` is empty.

## Risks / Trade-offs

- **[Risk: Users lose mental model that they can grep the cache file.]** → Mitigation: Export-as-JSON is explicit and discoverable via the toolbar tooltip. Documentation in the explanation dialog or tooltip text can mention "use Export as JSON… to inspect the cache in text form."

- **[Risk: msgpack serialization subtly drops fields that `jsonEncode` would keep, e.g., keys with non-string types.]** → Mitigation: `toMap` is the same in both paths; the `GenericAsyncSettingsManager.serialize` path already casts the msgpack output via `(m2.deserialize(contents) as Map<dynamic, dynamic>).cast()` on the way back in, which `VramChecker` has precedent for. We add a round-trip test (write msgpack, read back, compare to source state) at minimum for a small representative `VramEstimatorManagerState` fixture.

- **[Risk: DateTime or similar scalar types round-trip differently in msgpack vs. JSON.]** → Mitigation: `VramEstimatorManagerState.lastUpdated` is a `DateTime?` handled by dart_mappable. Inspect the encoded form manually when implementing, and if msgpack drops to an epoch-millis number where JSON serialized to ISO-string, either (a) rely on dart_mappable hooks to standardize, or (b) override `toMap`/`fromMap` locally. This is the single concrete spot we'll verify in unit tests.

- **[Risk: Export silently produces a file the user can't find because the save-dialog API varies across platforms.]** → Mitigation: Use whatever save-file dialog utility already exists in TriOS (search for existing usages of `file_selector`, `file_picker`, or a project-specific wrapper). On success, show a snackbar with the resolved path; on cancel, no-op quietly.

- **[Risk: One-shot JSON deletion runs every launch and noisily logs even after the file is gone.]** → Mitigation: Only log at `Fimber.i` level *on the launch where deletion actually happens*; use `.exists()` as the gate so subsequent launches are silent no-ops.

- **[Trade-off: The cache file is no longer human-diffable in git/commits (though it wasn't checked in anyway) or by tailing on disk.]** → Accepted. Export covers the 1% of times this matters.

## Migration Plan

No user migration is required beyond what happens automatically on launch:

1. User installs the new TriOS build.
2. On first launch, `VramEstimatorManager` resolves its config dir and deletes `TriOS-VRAM_CheckerCache.json` + `TriOS-VRAM_CheckerCache.json_backup.bak` if present. A single `Fimber.i` line logs the deletion.
3. `GenericAsyncSettingsManager.read()` looks for `TriOS-VRAM_CheckerCache.mp`, doesn't find it, writes the fallback (empty initial state).
4. User clicks "Refresh" (or the cache is populated on next scan). From now on, `.mp` is the on-disk cache.

Rollback: reverting the TriOS version restores the old JSON behavior. The old-version TriOS will not find a `.json` cache (it was deleted) and will regenerate one on the next scan. No data loss that isn't cheaply regenerable.
