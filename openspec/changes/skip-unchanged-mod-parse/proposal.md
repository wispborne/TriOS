# Skip re-parsing a mod whose files haven't changed

## The problem

Every launch, TriOS reads its viewer cache, shows the result, then re-reads and re-parses every mod's data files from scratch — even when not a single file has changed.

From a real log on a 130-mod install:

| Domain | Cache read | Fresh re-parse |
| --- | --- | --- |
| ships | 1281 ms | 17349 ms |
| weapons | 2003 ms | 12465 ms |
| graphics_index | 1277 ms | 3751 ms |
| ship_systems | 1280 ms | 2547 ms |
| hullmods | 1671 ms | 2318 ms |

The cache works. The viewer fills in about a second. The seventeen seconds after that are spent proving nothing changed. (That launch was the slowest in the log — across launches the ships parse ranges from about 10 to 17 seconds.)

TriOS already notices that nothing changed, but too late to help. `cached_stream_list_notifier.dart:353` compares the freshly encoded bytes against the cached bytes and skips the rebuild when they match. That saves the merge and the model rebuild downstream, which is worth keeping. It does not save the parse, because the parse already ran to produce those bytes.

So the sequence today is: read every `.ship`, `.skin`, `.variant` and CSV in 130 mod folders, parse each one, encode the result, compare it to what was already on disk, throw it away.

## The solution

Record which files a mod's parse read, and when each was last modified. Store that alongside the payload in the cache file. On the next launch, check those files. If none changed, and none were added or removed, keep the cached data and skip the parse entirely.

Measured on the same install:

- Listing a directory costs about 8 µs per file.
- Reading one file's modified time costs about 43 µs per file (`lastModified`, which is half the cost of a full `stat`).
- Ships reads about 140 files per mod on average, so about 19,000 files across the 130 mods that have ship data.
- Checking all of them takes roughly one second.

About one second instead of ten to seventeen.

## Expected payoff per domain

The saving is large where parsing dominates and small where the parse is mostly a directory walk already.

| Domain | Today | Expected after | Why |
| --- | --- | --- | --- |
| ships | 10–17 s | about 1 s | Parsing hundreds of JSON files per mod is the cost |
| weapons | 6–12.5 s | under 1 s | Same |
| ship_systems | 1.6–2.7 s | under 0.5 s | Same, smaller |
| hullmods | 1.2–3 s | under 0.5 s | Same, smaller |
| factions | 1.0 s | under 0.3 s | Same, smaller |
| wings | — | under 0.3 s | Same, smaller |
| graphics_index | 2.3–4.4 s | 1–2 s | The scan is itself a directory walk, so the check costs nearly as much |

The "Today" ranges are from repeated launches in the same log; the single-launch table above shows the slowest.

Graphics index is included for consistency, not because the payoff is good. It should be built last and dropped if it measures worse than the scan it replaces.

## In scope

- A fingerprint recorded during parsing and stored in the cache envelope.
- A check in `CachedStreamListNotifier` that skips `parseVariant` and `parseVanilla` when the fingerprint still matches.
- All seven domains built on `CachedStreamListNotifier`: ships, weapons, hullmods, ship systems, wings, factions, graphics index.
- The viewer refresh button forcing a full re-parse that ignores fingerprints.

## Out of scope

- Portraits. It does not use `CachedStreamListNotifier` — it is its own `AsyncNotifier` with its own cache handling, and it already skips variants it has seen, scanning only new ones.
- Changing how the cache is stored. Still one msgpack file per mod variant per domain.
- SQLite, or any other storage swap. Being considered separately.
- The caches that aren't per-variant: VRAM estimates, forum data, the mod repo, version checks.
- Moving cache decoding off the UI isolate. A real problem, a different change.
- Watching the mods folder for changes while the app is running.
