## 1. Cache foundation

- [x] 1.1 Create `lib/viewer_cache/` directory and wire its barrel file.
- [x] 1.2 Add `CacheEnvelope` class carrying `schemaVersion`, `smolId`, optional `gameVersion`, and opaque `payload` bytes. Provide msgpack encode/decode using `msgpack_dart`. Decode returns `null` (not throws) on malformed input.
- [x] 1.3 Add `CachedVariantStore` with constructor `(String domain, Directory root)`.
- [x] 1.4 Implement `CachedVariantStore.readAll(Set<SmolId>, int currentSchemaVersion)` → `Future<Map<SmolId, Uint8List>>`. Reads files in parallel via `Future.wait`. Skips files whose envelope version mismatches. Returns only successful reads.
- [x] 1.5 Implement `CachedVariantStore.write(SmolId, Uint8List payload, int schemaVersion)` using write-to-`.tmp` + `rename`. Creates domain directory on first write. Logs and swallows I/O errors.
- [x] 1.6 Implement `CachedVariantStore.pruneExcept(Set<SmolId> keep)` that lists the domain directory and deletes files whose basename is not in `keep`. Skips `_vanilla.mp` (vanilla has its own path).
- [x] 1.7 Implement `CachedVariantStore.readVanilla(String gameVersion, int currentSchemaVersion)` / `writeVanilla(...)` using the `_vanilla.mp` path. Envelope's `gameVersion` field is compared against the current value; mismatch → treat as miss.
- [x] 1.8 Serialize writes per-store via an internal `Future` chain so only one write is in flight at a time for a given store. Keeps file-handle usage bounded on large modlists.

## 2. Generic cached notifier base

- [x] 2.1 Add abstract class `CachedStreamListNotifier<T, P>` extending `StreamNotifier<List<T>>`.
- [x] 2.2 Expose abstract members a concrete manager must provide:
  - `String get domain`
  - `int get schemaVersion`
  - `CachedVariantStore get store`
  - `String itemId(T item)` — for cross-variant dedup.
  - `P decodePayload(Uint8List bytes)` — msgpack → domain payload (typically via dart_mappable `.fromMap`).
  - `Uint8List encodePayload(P payload)` — domain payload → msgpack.
  - `List<T> itemsFromPayload(P payload)` — extract items for the flattened list.
  - `List<ModVariant> resolveEnabledVariants()` — called once per build.
  - `String? get currentGameVersion` — nullable; `null` skips vanilla caching.
  - `Future<P> parseVanilla(Directory gameCore, List<T> allItemsSoFar)`
  - `Future<P> parseVariant(ModVariant variant, List<T> allItemsSoFar)`
  - `void onFullScanComplete(Map<SmolId, P> allPayloads)` — hook for side-channel reassembly (used by ships for `moduleVariants` / `hullIdMap`).
- [x] 2.3 Implement the `build()` Stream protocol:
  1. Increment internal `_buildToken`; capture `myToken`.
  2. Resolve enabled variants and game core path. Abort if unavailable.
  3. **Phase 1 — cache load:** read all cached envelopes (vanilla + enabled smolIds) in parallel; decode each into `P` and store in an ordered `Map<SmolIdOrVanilla, P>` (`_slices`). Yield the flattened items.
  4. **Phase 2 — fresh scan:** iterate vanilla then each enabled variant in mod order. For each:
     - Abort if `_buildToken != myToken`.
     - Call `parseVanilla` or `parseVariant` with the current flattened items as `allItemsSoFar` (for skin-like cross-variant dependencies).
     - Replace `_slices[key]` with the fresh payload.
     - Yield the flattened items (throttled — 500ms).
     - Queue a background cache write (fire-and-forget through the store's serialized chain), guarded by `_buildToken != myToken` at write time.
  5. After the final variant: final yield with complete fresh data.
  6. Call `onFullScanComplete(_slices)` for side-channels.
  7. **Phase 3 — prune:** call `store.pruneExcept(freshSmolIds)`.
- [x] 2.4 Implement `_flatten()` dedup: iterate `_slices` in insertion order; for each payload call `itemsFromPayload`; track a `Set<String>` of seen `itemId`s; first occurrence wins (matches today's `distinctBy`).
- [x] 2.5 Throttle yields in Phase 2 to at most one per 500ms, but always emit a final yield after the last variant regardless of the throttle window.
- [x] 2.6 Log `'Loaded {N} from cache in {X}ms; refreshed {M} variants in {Y}ms'` at info level when the build completes.

## 3. Constants and paths

- [x] 3.1 Add `Constants.viewerCacheDirPath` returning `Directory(p.join(configDataFolderPath.path, 'cache', 'viewer'))`.
- [x] 3.2 Ensure the directory is created lazily on first write by `CachedVariantStore`, not at app startup (keep startup RAM/IO untouched).

## 4. Ships migration

- [x] 4.1 Define `ShipsCachePayload` (@MappableClass) with `List<Ship> ships`, `Map<String, ShipVariant> moduleVariants`, `Map<String, String> hullIdMap`.
- [x] 4.2 Run `dart run build_runner build --delete-conflicting-outputs`.
- [x] 4.3 Refactor `ShipListNotifier` to extend `CachedStreamListNotifier<Ship, ShipsCachePayload>`:
  - `domain` → `'ships'`; `schemaVersion` → `1`.
  - `parseVariant` wraps today's `_parseShips` + `_parseVariants` for a single mod folder, returning a `ShipsCachePayload` with both ship and variant results.
  - `parseVanilla` does the same for `gameCorePath`.
  - `onFullScanComplete` merges all payloads' `moduleVariants` / `hullIdMap` and writes to the existing providers.
- [x] 4.4 Delete the existing `_buildToken`-based `build()` body; it's now in the base.
- [x] 4.5 Keep `allShipsAsCsv` working off `state.value` (unchanged).
- [x] 4.6 Verify `moduleVariantsProvider` and `variantHullIdMapProvider` are populated correctly at `onFullScanComplete` time (not before — downstream code assumes they may be empty during phase 1/2).
- [x] 4.7 Verify skin resolution still works: `.skin` in a mod referencing a base hull from an earlier mod resolves to the same output as today.
- [x] 4.8 Confirm `DirectoryHook` / `SafeDecodeHook` coverage: add hooks for any `File` field in `Ship`, `ShipVariant`, or `ShipWeaponSlot` that is missing one. Regenerate mappers.

## 5. Weapons migration

- [x] 5.1 Define `WeaponsCachePayload` (@MappableClass) with `List<Weapon> weapons`.
- [x] 5.2 Run build_runner.
- [x] 5.3 Refactor `WeaponListNotifier` to extend the cached base with `domain` = `'weapons'`, `schemaVersion` = `1`. `parseVariant` wraps `_parseWeaponsCsv` for one folder.
- [x] 5.4 Drop the existing `build()` loop in favor of the base's.
- [x] 5.5 Keep `allWeaponsAsCsv` working off `state.value`.
- [x] 5.6 Verify `File`/`Directory` hook coverage on `Weapon`.

## 6. Hullmods migration

- [x] 6.1 Define `HullmodsCachePayload` (@MappableClass) with `List<Hullmod> hullmods`.
- [x] 6.2 Run build_runner.
- [x] 6.3 Refactor `HullmodListNotifier` to extend the cached base with `domain` = `'hullmods'`, `schemaVersion` = `1`. `parseVariant` wraps `_parseHullmodsCsv`.
- [x] 6.4 Drop the existing `build()` loop.
- [x] 6.5 Keep `allHullmodsAsCsv` working off `state.value`.
- [x] 6.6 Verify hook coverage on `Hullmod`.

## 7. Dirty-state providers

- [x] 7.1 Leave `isShipsListDirty` / `isWeaponsListDirty` / `isHullmodsListDirty` wired as today (set by `AppState.smolIds` listeners). The cache layer does not interact with these — they still drive the "refresh" affordance in the viewer toolbars.
- [x] 7.2 Confirm that `ref.invalidate(xxxListNotifierProvider)` from the refresh button still produces the full cache-then-fresh flow (no special handling needed — it's just `build()` running again).

## 8. Error handling

- [x] 8.1 A corrupt individual cache file → treat as a miss for that variant only. Log at info level (not warning — this is a routine self-heal).
- [x] 8.2 A schema-version mismatch → same as corrupt. Log once per scan summarizing count.
- [x] 8.3 A write failure (disk full, permission) → log at warning level, continue the scan. Do not abort yields.
- [x] 8.4 A parse failure for one variant → behave as today (log to `allErrors`, skip that variant's items). Crucially: do not write its payload to cache (nothing to serialize) and do not delete its existing cache file during prune. This way a transient parse failure doesn't nuke the last good cache for that variant.

## 9. Manual verification

- [ ] 9.1 Cold cache: delete `{configDataFolderPath}/cache/viewer/`; launch app; open each viewer in turn. Expect today's behavior (multi-second progressive populate).
- [ ] 9.2 Warm cache: restart app; open each viewer. Expect instant population (< 100ms to first render), then the progressive-replacement transition as each variant re-parses.
- [ ] 9.3 Mod disabled: disable a mod in the mod manager; click refresh in the viewer. Expect the removed mod's items to disappear; after full scan, that mod's cache file is deleted from disk.
- [ ] 9.4 Mod re-enabled: re-enable; refresh. Expect instant re-appearance from the on-disk scan's rewrite.
- [ ] 9.5 File edit: with viewer open, edit a ship's base value in `ship_data.csv`; click refresh. Expect the edit to appear after Phase 2 (may briefly show cached old value — intended progressive-replacement behavior).
- [ ] 9.6 Schema bump: manually increment `schemaVersion` in one notifier; relaunch. Expect a full cold-cache load that turn, then warm-cache behavior thereafter.
- [ ] 9.7 Corruption: manually truncate one `.mp` file. Launch app, open that viewer. Expect that variant to miss cache and re-parse; other variants load from cache as normal.
- [ ] 9.8 Disk space: no explicit test; watch cache dir size after opening all three viewers with a representative modlist. Note figure in PR description for reference.
- [ ] 9.9 Tab switching doesn't re-fetch: open ships viewer, switch to weapons, switch back. No second build() / no fresh parse on the return trip.
- [ ] 9.10 Rapid refresh: click refresh twice in quick succession. Only the second scan's writes land (thanks to build-token guarding); no corruption of the on-disk cache.
