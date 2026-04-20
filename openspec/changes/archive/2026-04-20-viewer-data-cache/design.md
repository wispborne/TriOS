## Context

Three viewer managers (`ShipListNotifier`, `WeaponListNotifier`, `HullmodListNotifier`) are `StreamNotifier`s that walk enabled mod variants, parse on-disk data per variant, and yield progressively every 500ms. They only build when first watched, staying resident thereafter; `ref.invalidate` re-runs `build()`. A fourth viewer is expected.

Key properties of the existing flow that must be preserved:

- **Lazy**: nothing parses at app startup; first watch triggers `build()`.
- **Progressive**: the user sees a partial list populate over time rather than a single blocking wait.
- **Stale-token pattern** (ships): `_buildToken` aborts superseded builds to prevent cascading rebuilds.
- **Side-channels** (ships): `moduleVariantsProvider` and `variantHullIdMapProvider` are filled after the main yield via a separate `.variant` parse pass.
- **Cross-variant dependency** (ships skins): `.skin` files in a later mod may reference base hulls from an earlier mod or vanilla; current code threads an `allShipsSoFar` accumulator and resolves skins at parse time.

The cache sits beneath this as a transparent acceleration layer.

## Goals / Non-Goals

**Goals:**

- First-open latency on warm cache: tens of milliseconds, independent of parse complexity.
- Zero impact on correctness: the cache is a shortcut to what a fresh parse would produce. Every `build()` still completes a fresh parse and reconciles.
- Truly generic: adding a fourth viewer requires only (a) a domain name, (b) a per-variant parse function, (c) a payload type with dart_mappable mapper. Everything else comes from the base.
- Self-healing: schema mismatches, corrupted files, renamed mods, uninstalled mods all converge to "cache eventually reflects fresh parse" without intervention.

**Non-Goals:**

- Not a query engine. The cache returns the *full* per-variant payload — no partial/filtered reads, no indexes.
- Not cross-process-safe. Only TriOS writes to this directory; concurrent TriOS instances are out of scope.
- Not time-bounded or mtime-checked. Every `build()` does a fresh parse; the cache never "expires" separately.
- Not a replacement for `ref.invalidate` / refresh button. Those still work and run the same flow.
- Not introducing isolates. Msgpack encode/decode is fast enough on the main isolate for the data sizes involved.

## Decisions

### Per-variant files, not a single aggregate

```
{configDataFolderPath}/cache/viewer/
  ships/{smolId}.mp
  ships/_vanilla.mp
  weapons/{smolId}.mp
  weapons/_vanilla.mp
  hullmods/{smolId}.mp
  hullmods/_vanilla.mp
```

**Why per-variant:**
- Parallel reads during load (Phase 1). A dozen small file reads finish faster than one large one on any modern OS, and msgpack decoding costs distribute over reads.
- Incremental writes during the fresh scan (Phase 2). Each variant's fresh parse produces exactly one atomic file write; a single aggregate file would require full rewrites or complex in-place mutation.
- Prune is trivially `File.delete` for each abandoned smolId. No rewrite ever.
- Partial failure tolerance: a corrupt file invalidates only its own variant, not the whole cache.

**Alternative considered — a single aggregate msgpack per domain.** Rejected on incremental-write grounds alone. A 30 MB rewrite after every scan is far worse than 200 × 150 KB writes scattered across minutes.

**Alternative considered — SQLite / Hive / Isar.** Rejected as over-capability. We don't need queries, transactions, or indexes. msgpack_dart is already a dependency; plain files keep the design auditable (human can `ls` the cache dir and reason about it).

### Envelope format

```
{
  v: <int>,           // schema version, per-domain, incremented manually on breaking changes
  smolId: <string>,
  payload: <msgpack>  // domain-specific — opaque to the cache layer
}
```

Version mismatch → silent cache miss → fresh parse that variant. Decode throws → silent cache miss. This is the only tolerated-failure path; unexpected errors still log but don't crash the load.

Schema bumps are manual. `build_runner` doesn't hash model shapes, so automatic invalidation on field rename is out of reach; and because every `build()` runs a fresh parse anyway, a stale cache from an additive change (new nullable field) is self-healing on the next scan. Breaking changes (removed required field) need a version bump to skip the broken cache once.

### Atomic writes via tmp + rename

Every write goes to `{smolId}.mp.tmp`, then `rename`s over the final path. `rename` is atomic on all supported platforms (NTFS, APFS, ext4). If the process dies mid-write, the old file remains; worst case the file never existed and the next load sees a miss.

### Progressive replacement (Option C from discovery)

The notifier state is conceptually `Map<SmolId, List<T>>` — per-variant slices. Yields flatten to `List<T>` for the provider's public type.

Phase 1 output: `Map` populated with whatever cache reads succeeded. Missing entries → empty lists. Yield the flattened union.

Phase 2: iterate variants in the same order the fresh parse produces (`ref.read(AppState.mods)`). For each variant:

1. Run the per-variant parse function.
2. Replace `map[smolId]` with the fresh list.
3. Yield flattened `map.values` (throttled — 500ms like today).
4. Fire-and-forget cache write for this variant (not awaited).

```
  time ──────────────────────────────────────▶

  t=0     cached yield:   [A₀ B₀ C₀ D₀]      (all 4 from cache)
  t=1     fresh A:        [A₁ B₀ C₀ D₀]      (A replaced; B/C/D still cached)
  t=2     fresh B:        [A₁ B₁ C₀ D₀]
  …
  t=N     all fresh:      [A₁ B₁ C₁ D₁]      + prune stale cache files
```

**Why not swap wholesale at end (Option A):** no "I can see it's working" feedback; a slow mod at the end of the list means the user stares at stale data for seconds before anything moves.

**Why not the today-shape progressive yield (Option B):** during the fresh scan, only re-parsed variants would be in the list — user watches the list shrink and refill. Confusing regression.

Option C costs ~10 lines of per-variant indexing (a `Map<SmolId, List<T>>` vs today's flat `List<T>`). Worth it.

### Dedup across variants

Today's code does `allShips.distinctBy((e) => e.id).toList()` to handle the case where two variants define the same ship id (first occurrence wins). With per-variant slices, dedup moves to the flatten step:

```dart
List<T> _flatten() {
  final seen = <String>{};
  final out = <T>[];
  for (final smolId in _variantOrder) {          // insertion order
    for (final item in _slices[smolId] ?? const []) {
      if (seen.add(itemId(item))) out.add(item);
    }
  }
  return out;
}
```

`itemId` is supplied by the concrete domain (ship id, weapon id, etc.). The base class owns the flatten; domains own the key function.

### Vanilla handling

Vanilla isn't a `ModVariant`, so it has no `smolId`. Use the fixed pseudo-key `_vanilla` for the cache file name, scoped by game version via the envelope: when loading, if `envelope.gameVersion != currentGameVersion`, treat as miss. Game version is already tracked for other purposes; the cache only needs to read it once per build.

(Alternative — key vanilla by `_vanilla-{gameVersion}` in the filename. Rejected: creates cruft files on every game update that prune doesn't clean up, because prune only deletes smolIds not in the *current* enabled set and vanilla is always present.)

### Ship-specific concerns

Ships have two parse passes (ship/skin data, then `.variant` module data). Both are per-folder, so both fold naturally into the per-variant cache payload:

```
ShipsPayload {
  ships: List<Ship>,
  moduleVariants: Map<String, ShipVariant>,  // only the ones with modules
  hullIdMap: Map<String, String>,            // variantId → hullId for this folder
}
```

The manager reassembles global maps (`moduleVariantsProvider`, `variantHullIdMapProvider`) from per-variant payloads on every yield. This is a small merge — not a full re-parse.

Skin resolution threads `allShipsSoFar`. On cache-first load, the `allShipsSoFar` accumulator is populated from cache *before* the first fresh parse runs, so skin resolution at fresh-parse time sees the same cross-variant context it does today.

### Fire-and-forget writes with build-token guarding

Cache writes don't block the yield. They're queued via `unawaited(cache.writeAsync(...))`. The build-token pattern (already present in `ShipListNotifier`) extends to the write: if `_buildToken != myToken` at write time, drop the write. Prevents a superseded build's stale payload from overwriting a newer one.

Writes across the whole scan run serialized per-notifier via a `Future` chain — a fresh write waits for the prior one — to bound concurrent file handles.

After the final yield, `build()` awaits `store.flushPendingWrites()` before signaling completion. The yields themselves remain non-blocking; this drain only runs once the user-visible stream has already emitted the fresh list. Without it, a hot restart in the seconds between "scan finished" and "write chain drained" would lose the queued writes and re-parse from scratch on next launch.

### Prune after success, not before

Prune runs at the end of Phase 2, only if every variant completed successfully (no mid-scan error aborted the build). Prune reads the cache directory, builds a set of on-disk smolIds, and deletes any not in the fresh result's smolId set.

**Why after success:** if the scan aborts halfway (user navigated away, token invalidated, mod folder failed to read), pruning at that point might delete cache for a variant that was about to be re-parsed. Keeping stale entries through an aborted scan is strictly safer — the next full scan reconciles.

### File identity: File/Directory fields inside models

Several domain models (`Ship.csvFile`, `Ship.dataFile`, `Ship.spriteFile`, `Weapon.wpnFile`, `Hullmod.csvFile`) hold `File` references. These are paths, not streams, so they round-trip as strings via the existing `DirectoryHook` / `SafeDecodeHook` in `dart_mappable_utils.dart`. If any model is missing a hook for `File`, adding one is local to the model and covered by task 6.

### Directory placement

`lib/viewer_cache/` as a top-level feature module. Not under `lib/widgets/` (no widgets); not under `lib/utils/` (too substantial). Mirrors the feature-folder convention already used by `lib/ship_viewer/`, `lib/weapon_viewer/`, etc.

## Risks / Trade-offs

- **Silent schema mismatches.** A payload field renamed without a version bump could silently drop data from cached reads for one scan, then self-heal. Low-impact (fresh parse replaces anyway), but surprising. Mitigation: checklist note in model files that mention "used by viewer cache."
- **Disk churn on highly active modlists.** Every `build()` writes every variant's cache. For a 200-mod list that's ~200 files/scan. Measured write rate is bounded by disk and typical-case parse speed; not expected to be pathological, but worth watching.
- **Fire-and-forget write failures.** Disk full, permission denied, antivirus locking. The code logs and moves on — the next scan will retry. Acceptable given cache is a performance layer.
- **Simultaneous TriOS instances.** Two instances writing the same variant file could race. Not supported today; the atomic rename limits corruption to "one of the two wins."
