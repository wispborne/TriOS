## Why

Opening any viewer page (ships, weapons, hullmods) triggers a fresh walk of every enabled mod — reading CSV files, parsing JSON-ish `.ship`/`.skin`/`.variant`/`.wpn` data, and constructing hundreds to thousands of typed models. For a heavy modlist this is multi-second latency that happens *every single time the user clicks the tab* after an app launch. The managers already yield progressively to keep the UI responsive, but the user still stares at a half-empty grid for seconds.

None of this work is conceptually new after the first time — the parsed output is deterministic from the on-disk data. A generic per-variant disk cache lets a viewer paint its grid in tens of milliseconds on open, then transparently refreshes from disk in the background.

A future-proof design matters here: a fourth viewer (and more) is likely, and each new one should plug into the same cache layer with zero reinvention.

## What Changes

- Add `lib/viewer_cache/` module: a `ViewerCache<T>` generic over per-domain payload, a `CachedVariantStore` that manages per-variant msgpack files on disk, and a `CachedStreamListNotifier<T, P>` base class for viewer managers.
- Cache layout: `{configDataFolderPath}/cache/viewer/{domain}/{smolId}.mp` — one msgpack file per `(domain, modVariant)` pair, plus `_vanilla.mp` for vanilla data keyed by game version.
- Cache envelope: `{schemaVersion, smolId, payload}`. Decode failure (schema mismatch, corrupted file, model shape change) is a silent cache miss that falls through to fresh parse.
- Load protocol on each `build()`:
  1. Read all cache files for currently-enabled smolIds in parallel; yield the merged list immediately.
  2. Iterate variants: re-parse each from disk, replace *that variant's slice* of the in-memory state with fresh results, yield, then fire-and-forget a cache write for that variant.
  3. After every variant has been re-parsed successfully, delete cache files for any smolId not present in the fresh result (prune).
- **Progressive-replacement UX**: per-variant slices are swapped in place during the fresh scan. The visible list never shrinks mid-scan; each mod transitions from "cached" to "fresh" individually.
- Migrate `ShipListNotifier`, `WeaponListNotifier`, `HullmodListNotifier` onto the new base. Ship module side-channels (`moduleVariantsProvider`, `variantHullIdMapProvider`) fold into the ships cache payload and reassemble on load.
- Add `Refresh` semantics to the cached notifiers that mirror today's behavior: `ref.invalidate` re-runs the full cache-then-fresh flow.

## Capabilities

### New Capabilities

- `viewer-cache`: a reusable per-variant disk cache that backs viewer managers. Exposes cache read/write/prune primitives, a cache-first streaming notifier base class, and a well-defined schema-versioned envelope format.

## Impact

- **Code** — new module `lib/viewer_cache/` (~400 lines). Net reduction across the three existing manager files as each gives up its hand-rolled parse-and-yield loop in favor of calling into the base (~100 lines removed per manager, but much of the parsing logic stays — it's just invoked per-variant now).
- **Performance** — first-open latency on a warm cache drops from multi-second (proportional to mod count) to tens of milliseconds (proportional to total serialized size, read in parallel). Cold-cache first-open is unchanged.
- **Disk** — roughly 10–100 KB per mod variant per domain under `{configDataFolderPath}/cache/viewer/`. A heavy modlist with 200 mods × 3 domains ≈ 6–60 MB total. Self-pruning; never grows beyond the current enabled set.
- **RAM** — unchanged on startup (nothing preloaded). Cached payloads are deserialized only when the user opens a viewer.
- **Settings schema** — no changes. The cache lives in its own directory tree and is orthogonal to `appSettings`.
- **Dependencies** — none added. `msgpack_dart` is already present.
- **User-visible behavior** — viewers open effectively instantly on second-and-later launches; fresh-parse still runs in the background so any on-disk edit since the last scan is reflected. No new settings or toggles.
