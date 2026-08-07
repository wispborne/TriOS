# Design

## Where things stand

`lib/viewer_cache/cached_stream_list_notifier.dart` runs three phases. Phase 1 reads every cached payload and yields a list. Phase 2 parses every source fresh and replaces the slices. Phase 3 prunes.

The relevant part of Phase 2 is around line 343:

```dart
for (final variant in variants) {
  if (_buildToken != myToken) return;
  final payload = await parseVariant(variant, wantsContext ? _flatten() : const []);
  // ...
  final bytes = _tryEncode(payload);
  final unchanged = bytes != null &&
      seededFromCache.contains(variant.smolId) &&
      _sameBytes(bytes, cachedBytes[variant.smolId]);
  if (unchanged) continue;
```

The `unchanged` check is right, and it stays. It just comes after the expensive part. This change adds a second, cheaper check that runs before `parseVariant` instead of after.

## What the fingerprint is made of

Two maps, both keyed on paths relative to the source folder, with forward slashes:

```
directories:  "data/hulls"        → ["ship_data.csv", "atlas.ship", "skins", ...]
              "data/hulls/skins"  → ["atlas_pirate.skin", "lowtech/atlas_lp.skin", ...]
              "data/variants"     → ["atlas_Standard.variant", ...]

files:        "data/hulls/ship_data.csv"  → 1754500000000
              "data/hulls/atlas.ship"     → 1754499000000
```

Directories catch files being added, removed or renamed. Files catch edits. Both are needed — neither alone is enough.

A directory listed recursively (skins, variants) stores every entry from the whole walk under the listed root, nested paths included, as the `lowtech/atlas_lp.skin` entry above shows. Storing only the top-level names would miss a file added inside an existing subfolder.

Directory entries are stored unfiltered, exactly as the listing returned them. Filtering by extension would mean storing the filter too, and getting it wrong means missing a change. An unfiltered name list costs a few hundred bytes and cannot be wrong.

Paths are relative so that moving a mod folder does not invalidate its own cache. The smolId already changes when the mod's version changes.

### Why last-modified time and not a hash

Hashing means reading every file, which is most of what the parse costs. That defeats the point.

Measured on a 448-mod install:

| | Cost per file |
| --- | --- |
| `listSync` (no metadata) | ~8 µs |
| `lastModifiedSync` | ~43 µs |
| `lengthSync` | ~39 µs |
| `statSync` (both, plus more) | ~86 µs |

`statSync` costs twice `lastModifiedSync` and adds nothing useful. Any edit changes the modified time; size alone does not catch a same-length edit. So: modified time only, via `lastModifiedSync`.

The files being checked were just written by the same parse the last time round, and on a re-check they are the ones the OS is most likely to have cached, so the real cost should sit below the 43 µs measured cold.

### Why not just walk the whole mod folder

Measured, same install:

| | Files | Time |
| --- | --- | --- |
| Whole mod folders, listing + stat | 288,113 | 26.5 s |
| `data/` only, listing + stat | 77,937 | 7.1 s |
| `data/` only, listing without stat | 77,937 | 0.66 s |

Walking everything costs more than the parse it would save. Checking only the files a domain actually reads is what makes this cheap: ships reads about 140 files per mod on average, so about 19,000 files across the 130 mods that have ship data — roughly one second.

## How a parse says what it read

The base class hands a recorder to `parseVanilla` and `parseVariant`. The parse calls it when it lists a folder and when it reads a file.

```dart
/// Collects what a parse touched, so the next launch can tell whether parsing
/// again would find anything new.
class ParseRecorder {
  ParseRecorder(this.sourceFolder);

  final Directory sourceFolder;

  /// Call right after listing [dir]. Pass the entries the listing returned,
  /// before any filtering. For a recursive listing, pass everything the whole
  /// walk returned — the names are stored under [dir], so a file added in a
  /// nested subfolder still changes the fingerprint. A folder that does not
  /// exist is recorded with an empty list, so creating it later counts as a
  /// change.
  void directory(Directory dir, Iterable<FileSystemEntity> entries);

  /// Call when a file is read. Reads its last-modified time.
  void file(File file);

  CacheFingerprint build();
}
```

The alternative was to have each domain declare its folders and extensions up front, which is a much smaller change — one method per domain, nothing threaded through the parse helpers. It was rejected because a declaration drifts. If someone later adds a file type to a parse and forgets the declaration, the viewer shows stale data with nothing to explain it. The recorder cannot drift, because it records what the parse did rather than what someone said it does.

The recorder still has one way to go wrong, and it is covered separately: it describes what the parse read *last time*. When a parse changes to read new files, the stored fingerprints are out of date, so that change has to bump the domain's `schemaVersion` — which is already the rule for any change to what a payload holds.

## Where the fingerprint is stored

A new optional `fingerprint` field in `CacheEnvelope`, next to `schemaVersion`, `smolId` and `payload`.

`CacheEnvelope.tryDecode` already requires only `v`, `smolId` and `payload`, and ignores anything else. So an old cache file decodes fine and simply has no fingerprint, and a new cache file decodes fine in an older TriOS build. No `schemaVersion` bump.

A cached payload with no fingerprint means "parse this one". The parse then writes a fingerprint, so the first launch after this ships is a normal full scan and every launch after it is fast.

`CachedVariantStore.readAll` currently returns `Map<SmolId, Uint8List>`. It needs to return the fingerprint too, so it returns a small class instead:

```dart
/// One source's cached payload, with the fingerprint recorded when it was
/// written. [fingerprint] is null for files written before fingerprints existed.
class CachedEntry {
  final Uint8List payload;
  final CacheFingerprint? fingerprint;
}
```

Size cost: ships records about 140 file paths, 140 timestamps and three directory listings per mod, so roughly 12 KB on top of a mod's cache file. Across 130 mods that is under 2 MB on a 19 MB cache.

## Where the check runs

At the top of the Phase 2 loop, before `parseVariant`:

```
for each variant:
    cached = the entry loaded in Phase 1
    if cached exists
       and cached.fingerprint != null
       and nothing it records has changed:
         skip — the Phase 1 slice is already correct
         continue

    parse as today
```

Skipping means: no parse, no encode, no byte comparison, no cache write, no yield, and `anySliceChanged` is left alone. The slice loaded in Phase 1 stays exactly as it is.

Nothing else in the build needs changing:

- **Phase 3 prune** works off `variantsToScan()`, not off parse results, so skipping parses does not affect what gets pruned.
- **`onFullScanComplete`** receives `_slices`, which holds the Phase 1 slice for every skipped source. Ships' module-variant reassembly still sees everything.
- **`rehydratePayload`** already ran in Phase 1 for those slices.

The end-of-scan log line should report skips separately, so it stays honest:

```
Loaded 130 from cache in 1281ms; skipped 128 unchanged, refreshed 2 variants in 412ms (ships).
```

## Forcing a full parse

The refresh button has to bypass fingerprints. Otherwise a user who suspects the viewer is stale has no way to make TriOS look again, which is the one thing refresh is for.

Refresh currently invalidates the notifier's provider, and Riverpod builds a new notifier instance. So a flag on the instance would be thrown away. The signal lives on the base class instead:

```dart
/// Domains the user has asked to read everything again. Set by the refresh
/// button, cleared when the forced build finishes its full scan. Not a
/// provider and not an instance field: nothing watches it, and refresh
/// replaces the notifier instance, so an instance field would not survive.
static final Set<String> _forceFullParse = {};

static void requestFullParse(String domain) => _forceFullParse.add(domain);
```

The domain stays in the set until a forced build completes its full scan. Builds get superseded partway all the time — the mod list changes, another invalidation lands — and a superseded build that had already removed the flag would leave the next build running on fingerprints, silently ignoring the user's refresh. So the forced build reads the flag at the start and clears it only at the end, when `fullScanCompleted` is true.

Each viewer's `onRefresh` calls `requestFullParse` before invalidating. The call sites name different providers — ships and weapons call theirs `shipSourcesProvider` and `weaponSourcesProvider`, hullmods and factions invalidate `...ListNotifierProvider` — but every one of them is the notifier's own provider, so each gets the same one extra line.

## Per-domain notes

Every domain needs the same two things: thread the recorder through its parse helpers, and call it at each listing and each read.

- **ships** — `_scanShipsFolder` lists `data/hulls` flat and `data/hulls/skins` recursively; `_parseVariants` lists `data/variants` recursively. Three listings — two of them recursive, so their full walks get recorded — plus every `.ship`, `.skin`, `.variant` and CSV it reads. The biggest payoff of the seven.
- **weapons** — `data/weapons`, `data/shipsystems/wpn` and `data/shipsystems/proj`, recursively, plus `.wpn`, `.proj` and the CSV. Second biggest.
- **hullmods**, **ship_systems**, **wings**, **factions** — small file counts, straightforward.
- **graphics_index** — walks `graphics/` recursively and records every directory in it. The check is a listing and so is the scan, so the saving is the map building and the msgpack encode, not the walk. Build this one last and measure it. If the check is not clearly cheaper than the scan, leave graphics index alone and say so.

## Risks

**Modified times can lie.** FAT32 stores them to the nearest two seconds, so two edits inside one second could look like one. Copying a folder can preserve times. Both need deliberate action, and a real mod update changes the version and therefore the smolId, which is a cache miss anyway. Refresh is the escape hatch.

**A parse that quietly starts reading more files.** Covered by the `schemaVersion` rule in the spec. Worth a comment on the recorder saying so, since the person who breaks it will be reading the parse code, not the spec.

**Slow filesystems.** The check is a directory listing plus one metadata read per file. The scan it replaces does the same listing and then reads every file in full. So the check cannot be much worse than what happens today, on any filesystem.

**The check runs on the UI isolate**, like the parse it replaces. About one second of blocking instead of ten to seventeen is an improvement, so this change does not need to fix that. Moving cache work to `AppWorker` is worth doing separately.

## How to tell it worked

Compare the `Loaded ... refreshed ...` log line across two launches with no mod changes in between. Ships should drop from 10–17 seconds to about one, and report 128 or so skipped. If it does not, the fingerprint is failing somewhere and the log should say which source it retried.
