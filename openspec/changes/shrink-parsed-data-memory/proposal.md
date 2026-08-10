# Proposal: Cut the memory the parsed mod data uses

## Problem

With 460 mods installed and every page visited, TriOS sits at about 800 MB in Task Manager on a release build. Most people find that hard to accept from a launcher.

A heap snapshot says where it goes. Of 755 MB in the Dart heap:

| area | size | share |
| --- | --- | --- |
| `dart:` strings, lists and maps | 587 MB | 78% |
| VM runtime metadata (debug build only) | 85 MB | 11% |
| Flutter widget, render and semantics trees | 50 MB | 7% |
| TriOS model classes | 31.5 MB | 4% |

The 587 MB is mod data held as parsed Dart objects. TriOS parses about 88 MB of text across those 460 mods — `.ship` files are 40 MB of it, `.wpn` another 14 MB, `descriptions.csv` 13 MB — and keeps all of it for the whole session, for every installed mod rather than only the enabled ones.

Two things make that far more expensive than the 88 MB it starts as:

1. **No string is shared.** There are 3,431,844 one-byte strings on the heap, 211.8 MB worth. `BALLISTIC`, `SMALL`, `DESTROYER`, and every JSON key in all 33,750 side files exists as a separate object each time it appears. Pooling collapsed the whole install to 85,474 distinct short strings.

2. **Every blank cell is stored.** `rowToTypedMap` writes `row[column] = null` for each empty cell. `ship_data.csv` has about 80 columns and most mods fill a fraction of them, so most of each row map is null entries — and each one still takes a slot in the map's backing array and its `Uint32List` index. Those index arrays alone are 41.6 MB.

## Measured savings

A standalone script parsed the real 460-mod install five ways, one process per layout, baseline subtracted:

| layout | held data | saved |
| --- | --- | --- |
| what TriOS does today | 339 MB | — |
| skip empty cells | 289 MB | 50 MB (15%) |
| share repeated strings | 249 MB | 90 MB (27%) |
| **both** | **199 MB** | **140 MB (41%)** |
| both, plus rows as value lists over a shared header | 194 MB | 145 MB (43%) |

Parse time was 6.0–7.1 s in every layout, so sharing strings costs nothing measurable. Re-running the first layout twice gave 527 and 528 MB, so this is repeatable to about 2 MB.

## Proposed solution

Two changes, in this order:

1. **Share repeated strings.** One pool, applied where strings are created: the Starsector JSON parser, the four CSV row builders, and the cache decode path. This goes first and gets measured on its own — it is 90 MB of the 140, and it has no behaviour question attached: a pooled string is equal to the one it replaces in every way.

2. **Stop storing blank cells.** A missing key and a null value both read back as null through `row['x']`, so nothing that reads a row can tell the difference. This is the other 50 MB, and it is second because it does carry one behaviour question — dart_mappable sees an absent key where it used to see a null — which the design addresses.

The row-as-value-list layout from the measurement table is rejected: 5 MB better than skipping blank cells, at the cost of a custom `Map` implementation.

Neither change alters what any page shows. Expected result: about 660 MB in Task Manager instead of 800 MB. A 17% cut, not a fix.

## Scope

- `lib/starsector_json/json_parser.dart` — where every `.ship`/`.skin`/`.wpn`/`.proj`/`.faction` string is created
- `lib/utils/csv_parse_utils.dart` and the three managers with their own copy of the same loop (ships, weapons, wings)
- `lib/viewer_cache/cached_stream_list_notifier.dart` — the cache decode path, which is what runs on a normal launch

## Non-goals

- **Dropping the raw payloads after merging.** It would save around 300 MB, but the cost lands on enabling or disabling a mod, which would go from instant to a full re-read of 460 cache files. Worth its own change if 660 MB is still too much.
- **The descriptions recompose rebuilding all entries every 500 ms.** A real waste, but a startup-churn problem rather than a steady-state memory one — the extra copies are garbage waiting for collection, not held data. Split into its own change: `reuse-description-entries`.
- **Fixing the codex index rebuilding 11 times during startup.** Same shape of problem as the descriptions one, and reduced by fixing it. Follow-up.
- **Dropping page state when the user navigates away.** Keeping every page in memory is deliberate.
- **`Float32List` for bounds and slot positions**, and trimming the four `late final` fields on `ShipWeaponSlot`. Together about 13 MB, and both cost either a refactor or CPU in hot filter paths.

## Why there is no spec delta

Nothing observable changes. Same data on every page, same merge rules, same file formats. One internal invariant does get tightened, and it is written down as a code comment and a `CLAUDE.md` note rather than a requirement: a blank cell in a raw row is now absent rather than null, so readers must use `row['x']` and never `containsKey`.
