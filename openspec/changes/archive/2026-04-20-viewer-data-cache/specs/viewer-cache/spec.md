## ADDED Requirements

### Requirement: Per-variant cache files with schema-versioned envelope

The cache SHALL store one file per `(domain, smolId)` pair under `{configDataFolderPath}/cache/viewer/{domain}/{smolId}.mp`, plus a single `_vanilla.mp` per domain for vanilla data. Each file SHALL begin with a msgpack-encoded envelope containing at minimum:

- `schemaVersion: int` — per-domain, incremented manually on breaking payload changes.
- `smolId: String` — the variant identity, or `"_vanilla"` for vanilla.
- `payload: bytes` — opaque msgpack-encoded domain payload.

An envelope whose `schemaVersion` does not match the current domain version MUST be treated as a cache miss. A decode error of any kind (malformed msgpack, corrupt file, missing required field) MUST be treated as a cache miss for that variant only, not as an error for the scan.

#### Scenario: Schema version mismatch is a silent miss

- **GIVEN** a domain with current `schemaVersion = 2`
- **AND** a cache file on disk whose envelope reports `schemaVersion = 1`
- **WHEN** the cache is loaded during `build()`
- **THEN** the file is treated as a cache miss for that variant
- **AND** Phase 2 fresh-parses the variant and overwrites the file with a `schemaVersion = 2` envelope

#### Scenario: Corrupted file affects only its own variant

- **GIVEN** a cache file has been truncated to zero bytes
- **WHEN** `readAll` attempts to decode every cached variant in parallel
- **THEN** the truncated file is reported as a miss
- **AND** every other variant's cache is still served
- **AND** an info-level log entry is emitted summarizing miss count

### Requirement: Atomic writes

A cache write MUST be atomic with respect to crashes: a partial write MUST NOT leave a corrupt final file. Implementations SHALL write to a sibling `.tmp` path and `rename` over the final path on completion.

#### Scenario: Process dies mid-write

- **GIVEN** a cache write is in progress to `ships/abc-1.2-x.mp.tmp`
- **WHEN** the process is killed before `rename` completes
- **THEN** any previously-existing `ships/abc-1.2-x.mp` is unchanged
- **AND** the next `build()` serves that variant from the previous file

### Requirement: Cache-first, fresh-second build protocol

A cached viewer notifier's `build()` SHALL execute in three phases, in order:

1. **Phase 1 (load):** Read every cache file for the current set of enabled variant smolIds (plus vanilla) in parallel. Yield the flattened and dedup'd list derived from every successful cache read. Missing, stale, or corrupt files produce an empty per-variant slice.
2. **Phase 2 (fresh):** Iterate variants in mod order. For each variant, parse its source files from disk, replace that variant's slice in the in-memory state, yield the updated flattened list (subject to throttling), and queue a background write of the fresh payload to the cache.
3. **Phase 3 (prune):** Only if Phase 2 completed without being aborted, delete cache files whose filename is not in the set of smolIds produced by the fresh scan.

Yields during Phase 2 SHALL be throttled to at most once per 500ms, with a guaranteed final yield after the last variant completes.

#### Scenario: Warm cache load precedes fresh parse

- **GIVEN** cache files exist for every enabled variant
- **WHEN** the user opens a viewer for the first time after app launch
- **THEN** the first yield is derived entirely from cache reads and arrives before any disk parsing has begun
- **AND** Phase 2 begins after the first yield, not before

#### Scenario: Cold cache degrades to today's behavior

- **GIVEN** the cache directory is empty
- **WHEN** the user opens a viewer
- **THEN** Phase 1 yields an empty list immediately (no cache hits)
- **AND** Phase 2 progressively populates the list one variant at a time
- **AND** each completed variant writes to cache
- **AND** the user experience matches the pre-cache behavior for the cold case

#### Scenario: Prune runs after a full successful scan

- **GIVEN** a previous session cached variants `{A, B, C}`
- **AND** the user has since disabled variant `B`
- **WHEN** `build()` completes Phase 2 successfully producing items from `{A, C}`
- **THEN** `ships/{smolIdB}.mp` is deleted
- **AND** cache files for `A` and `C` are unchanged or freshly rewritten

#### Scenario: Prune does not run if the build was aborted

- **GIVEN** Phase 2 is iterating variants
- **WHEN** the build token is invalidated (e.g. `ref.invalidate` or a new `build()` supersedes the current one) before the last variant completes
- **THEN** Phase 3 (prune) does not execute
- **AND** no cache files are deleted during this build

### Requirement: Progressive per-variant replacement

During Phase 2, the notifier's state SHALL maintain per-variant slices (conceptually `Map<SmolId, List<Item>>`). A fresh parse of a single variant MUST replace only that variant's slice. Yields SHALL always reflect the complete union of current slices — cached for not-yet-re-parsed variants and fresh for variants already processed.

The visible list MUST NOT shrink during Phase 2: at no point should the user observe fewer items than the union of (fresh-so-far ∪ still-cached).

#### Scenario: List never shrinks during the fresh scan

- **GIVEN** four variants A, B, C, D each contributing 100 items from cache
- **WHEN** Phase 2 re-parses A first, then B, then C, then D
- **THEN** after A re-parses, the list still contains items from all four variants (A's from fresh parse, B/C/D from cache)
- **AND** the total count remains ≈ 400 throughout the scan (modulo any net additions or deletions in fresh data)

#### Scenario: Cross-variant dedup is preserved

- **GIVEN** two variants both define an item with the same `id`
- **AND** the first-occurrence-wins rule applied today
- **WHEN** the notifier flattens its per-variant slices for a yield
- **THEN** the same first-occurrence-wins dedup holds across cached and fresh slices alike

### Requirement: Fire-and-forget writes guarded by build token

Cache writes during Phase 2 SHALL NOT block yields. A write MUST be queued asynchronously and the scan must proceed immediately. Each queued write MUST verify the current build token at the moment of actually performing the write; if the token has been invalidated, the write MUST be skipped to prevent a superseded scan from overwriting a newer cache.

All writes to a given `CachedVariantStore` SHALL be serialized on a single `Future` chain to bound concurrent file handles.

#### Scenario: Superseded scan's writes are dropped

- **GIVEN** Phase 2 has queued a pending write for variant `A`
- **WHEN** a new `build()` runs and increments the build token before the pending write executes
- **THEN** the pending write detects the token mismatch and does not touch the cache file

#### Scenario: Yields are not blocked by disk writes

- **GIVEN** a slow disk (or antivirus scan) delays a cache write by multiple seconds
- **WHEN** the next variant finishes parsing and is ready to yield
- **THEN** the yield occurs without waiting for the prior write to complete

### Requirement: Vanilla caching by game version

Vanilla game data SHALL be cached at a fixed path `{domain}/_vanilla.mp`. The envelope for vanilla MUST include the current game version; on load, a game-version mismatch MUST be treated as a cache miss and trigger a fresh vanilla parse.

#### Scenario: Game update invalidates vanilla cache

- **GIVEN** `_vanilla.mp` was written with `gameVersion = "0.97a"`
- **AND** the user has since updated to `gameVersion = "0.98a"`
- **WHEN** the viewer loads
- **THEN** the vanilla cache is treated as a miss
- **AND** Phase 2 reparses vanilla and rewrites `_vanilla.mp` with the new game version in its envelope

### Requirement: Generic cache layer reusable across domains

The cache implementation SHALL be generic over a per-domain payload type `P`. Adding a new viewer (a fourth or later domain) SHALL require only:

1. A unique `domain` string.
2. A payload type with `@MappableClass` mapper for msgpack round-trip.
3. A per-variant parse function producing a payload from a mod folder.
4. An item-ID function for cross-variant dedup.
5. A list-extraction function from payload to public item list.

The cache SHALL NOT require modification to support new domains.

#### Scenario: New viewer adoption is purely additive

- **GIVEN** a hypothetical "factions" viewer is being added
- **WHEN** the implementer defines `FactionsCachePayload`, a parse function, and a concrete `CachedStreamListNotifier<Faction, FactionsCachePayload>` subclass
- **THEN** no code in `lib/viewer_cache/` needs to change
- **AND** the new viewer inherits cache-first load, progressive replacement, pruning, and atomic writes with zero additional implementation

### Requirement: Cache does not affect refresh semantics

The cache layer MUST be transparent to the refresh button and `ref.invalidate(...)`. Invalidation SHALL cause `build()` to re-run the full three-phase flow, starting with a cache read, then a fresh scan, then prune.

#### Scenario: Refresh button behaves identically to first open

- **GIVEN** the viewer has been open for a while and is showing fresh data
- **WHEN** the user clicks the refresh button (invalidating the provider)
- **THEN** `build()` re-runs Phase 1, yielding cached data (which is now effectively the last-fresh data written at the end of the prior scan)
- **AND** Phase 2 re-parses from disk, replacing slices as each variant completes
- **AND** Phase 3 prunes at the end
