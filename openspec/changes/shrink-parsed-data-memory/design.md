# Design

## How the measurement was taken

Two heap snapshots from DevTools on a debug build, 460 mods installed, every page visited. The first was filtered to app classes only (32.2 MB, 919 classes); the second is the same moment unfiltered (755 MB, 2,454 classes, 9,166,424 objects). Every TriOS count matches between the two, which is how we know it is one heap state and not two.

The savings numbers come from a separate script, kept at `scratchpad/measure_parse_cost.dart`, which reads the real install and holds everything at once. It covered all 95,275 CSV rows and 30,546 of 33,750 side files — the remaining 9% are malformed past what a throwaway parser recovers. `ProcessInfo.currentRss` minus a 188 MB empty-process baseline.

Two caveats on those figures. RSS includes allocator fragmentation, so treat 140 MB as roughly ±20%. And the script parses 9% fewer side files than the app does while holding slightly more CSV rows, and string sharing helps side files more than CSV — so if the 90 MB figure is wrong, it is low.

## Part 1 — Share repeated strings

### Where the pool goes

One pool, used in five places. Four of them create strings during a fresh parse; the fifth is the one that runs on a normal launch.

```
fresh parse                                   normal launch
───────────                                   ─────────────
json_parser.dart   _readString()               cached_stream_list_notifier.dart
  → every key and value in .ship, .skin,         normalizeForMapper()
    .wpn, .proj, .faction                        → every key and value coming
                                                   back out of msgpack
csv_parse_utils.dart  rowToTypedMap()
ship_manager.dart     inline row loop
weapons_manager.dart  _typedRow()
wings_manager.dart    inline row loop
```

`lib/starsector_json/json_parser.dart` is the cheapest of these to change. Every quoted string the parser produces comes out of one method, `readString`, through `text.substring(start, i)` for the common case and through `_readStringWithEscapes` for strings containing a backslash. Both returns are pooled. Found during implementation: bare tokens are a third path — unquoted values like `RENDER_LOADED_MISSILES` repeat across thousands of `.wpn` files and come out of `readValue` via `stringToValue`, so string results there are pooled too.

The CSV side has the same loop written out five times, one more than the survey first found — `rowToTypedMap` at `lib/utils/csv_parse_utils.dart:31`, plus hand-rolled copies in `ship_manager.dart`, `weapons_manager.dart` (`_typedRow`), `wings_manager.dart`, and `hullmods_manager.dart` (missed at first because it names its variables differently). This change does not consolidate them; that is a separate cleanup and mixing it in would make this one hard to measure. All five get the same one-line change. Factions has no row builder — `factions_csv.dart` produces a key set, and `.faction` file content goes through the JSON parser, so it is covered there.

`normalizeForMapper` at `lib/viewer_cache/cached_stream_list_notifier.dart:548` already walks every node of every decoded payload to turn msgpack's `Map<dynamic, dynamic>` into `Map<String, dynamic>`. It is the only place the cache path creates strings, and it is the path that matters: a normal launch reads msgpack, it does not re-parse files.

### What gets pooled

Strings of 64 characters or fewer. Above that they are overwhelmingly unique — sprite paths, description prose, tag lists — so pooling them would grow the pool without collapsing anything.

Numbers are already handled: all four CSV builders run `num.tryParse` first, so numeric cells never become strings. Integer cells cost nothing at all, because small integers are stored inline rather than as objects.

### The pool stays for the session

85,474 entries at roughly 50 bytes each is about 4 MB, held to save 90 MB. Keep it.

Clearing it after the scan was the alternative and it is worse. The interned strings themselves survive through the data referencing them, but a later parse — a mod installed mid-session, a refresh — would start a fresh pool and its strings would not be shared with anything already in memory. Paying 4 MB to avoid that is the right trade.

### Isolates

Parses run on the UI isolate today. If any of them later move to `AppWorker`, a top-level pool becomes one pool per isolate, which still works — each isolate shares within itself — it just does not share across the boundary. Worth a comment on the pool saying so, because it will look like a bug to whoever moves the parse.

## Part 2 — Stop storing blank cells

All four row builders currently write an entry for every header column, using null for a blank cell. The change is to skip the entry instead.

### Why this is safe

Every reader goes through `row['column']`, which returns null for an absent key exactly as it does for a null value. Checked:

- `_csvKey` at `lib/utils/game_data_merge.dart:136` reads `row[column]?.toString()`.
- CSV merging is whole-row and first-source-wins, so a row's blank columns never override anything in the first place.
- Nothing anywhere iterates a raw row's `keys`, `entries`, or calls `forEach` on one. Searched.

### The one real hazard

Three loaders feed raw row maps straight into dart_mappable (the survey first found two; hullmods is the third):

- `ShipSystemMapper.fromMap(data)` — `ship_systems_manager.dart`
- `WingMapper.fromMap(data)` — `wings_manager.dart`
- `HullmodMapper.fromMap(...)` — `hullmods_manager.dart`

dart_mappable does not treat an absent key and an explicit null the same way. For a nullable field both give null, so nothing changes. For a **non-nullable field with a default value**, an absent key uses the default and an explicit null does not.

All three models have exactly one non-nullable field, `id`, and all three loaders skip the row when `id` is missing or blank before calling `fromMap`. So this is safe today, and it is safe for the wrong reason — it holds because of the shape of three models, not because of anything enforcing it.

That gets a comment at all three call sites and a note on `rowToTypedMap`: a blank cell is absent, so a non-nullable mapped field with a default will now take its default. Anyone adding such a field needs to know.

Ships and weapons also build models from CSV-derived maps (`ShipMapper.fromMap`, `WeaponMapper.fromMap`), checked the same way: their only non-nullable stored field is a required `id`, and blank-id rows are dropped by the merge before building. `blankUnusableNumbers` reads `data[field.key]`, which treats absent as null, so it is unaffected.

### Old caches keep their nulls — so the schema version bumps

Found during verification, not in the original design. Ships and weapons cache raw CSV rows in their msgpack payloads. Caches written before this change hold rows with null entries, and a fingerprint-skipped mod never rewrites its cache — so without a `schemaVersion` bump, the blank-cell saving would never reach cached mods, which is nearly all of them. Both domains bump 4 → 5. The cost is one full ships-and-weapons re-parse on the first launch after this ships.

Hullmods, wings and ship systems do not bump: their payloads hold model `toMap()` output, which this change does not alter — their row maps only exist transiently during a fresh parse.

## Risks

**The pool is global mutable state.** In tests it accumulates across cases in one process. It only ever maps a string to an equal string, so it cannot produce a wrong result, but a test asserting on memory or pool size needs to account for it.

**Interning is only useful where it is applied.** Miss `normalizeForMapper` and the change does nothing on a normal launch, because launches read the msgpack cache instead of parsing files. This is the easiest way to get a disappointing result, so measure the cache path specifically.

**Skipping blank cells is the riskier half.** It is 50 MB of the 140 and it changes what `fromMap` sees for two models. If anything looks shaky during the work, ship the string pool on its own — it is 90 MB with no behaviour question at all.

**RSS is coarse.** Two release builds measured the same way, same mods, same pages visited, is the only comparison worth making.

## How to tell it worked

Task Manager on a release build, 460 mods, every page visited, compared before and after. Expect roughly 800 MB down to roughly 660 MB.

In a heap snapshot, `_OneByteString` should drop by roughly a million objects and 80–90 MB after Part 1, and `_Map` plus `_Uint32List` should both drop after Part 2.
