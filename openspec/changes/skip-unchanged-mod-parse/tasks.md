# Tasks

Build the mechanism, prove it on ships, measure, then do the rest. Ships is where the payoff is, so if it does not show up there, stop and rethink before touching six more domains.

## Step 1 — the fingerprint and where it's stored

- [x] Add `CacheFingerprint` to `lib/viewer_cache/` — two maps: directory path to sorted entry names, file path to last-modified in milliseconds. Both keyed on paths relative to the source folder, forward slashes. (Each directory also stores whether its listing was recursive, so the check can repeat the same kind of listing — comparing a flat listing against a recursive re-list would always mismatch.)
- [x] Give it msgpack encode and decode. Decode returns null on anything malformed, matching how `CacheEnvelope.tryDecode` already handles bad data.
- [x] Add an optional `fingerprint` field to `CacheEnvelope`. Write it only when present.
- [x] Confirm `CacheEnvelope.tryDecode` still accepts an envelope with no `fingerprint`, and that a fingerprint-carrying envelope decodes when the field is ignored. Both directions matter — users move between TriOS versions.
- [x] Do not bump any `schemaVersion`. Add a comment on the field saying why: it changes nothing about how the payload is read.
- [x] Add `CachedEntry` (payload plus optional fingerprint) and change `CachedVariantStore.readAll` to return `Map<SmolId, CachedEntry>`. Same for `readVanilla`.
- [x] Take a fingerprint argument on `CachedVariantStore.write` and `writeVanilla`.
- [x] Unit test the envelope round-trip: with a fingerprint, without one, and with a corrupt fingerprint that must not take the payload down with it.

## Step 2 — the recorder

- [x] Add `ParseRecorder`, holding the source folder, with `directory(dir, entries)`, `file(file)` and `build()`. (`build()` returns null when nothing was recorded — a domain that doesn't call the recorder must not get a fingerprint, because an empty one would match every launch and that domain would never re-parse.)
- [x] `directory` stores the entry names sorted, unfiltered, exactly as the listing returned them. A recursive listing passes everything the whole walk returned, nested paths included — top-level names alone would miss a file added inside an existing subfolder. A folder that does not exist records an empty list.
- [x] `file` reads `lastModifiedSync()`. A file that has vanished between read and record is skipped rather than throwing.
- [x] Comment on the class: it records what the parse read *last time*, so a parse that changes which files it reads must bump its domain's `schemaVersion` in the same change. Say it here, because whoever breaks this will be reading the parse code.
- [x] Add `parseRecorder` as a third argument to the abstract `parseVanilla` and `parseVariant` in `CachedStreamListNotifier`.
- [x] Unit test `ParseRecorder` against a temporary folder: relative paths, forward slashes, sorted names, absent folder recorded empty.

## Step 3 — the check

- [x] Add the comparison: given a fingerprint and a source folder, re-list every recorded directory and compare name sets, then compare every recorded file's modified time. Any mismatch, missing file, or error returns "changed".
- [x] In Phase 2, before `parseVariant` and `parseVanilla`, skip the parse when a cached entry exists, carries a fingerprint, and the comparison says nothing changed.
- [x] On a skip: no parse, no encode, no byte comparison, no cache write, no yield, and leave `anySliceChanged` alone. (One addition on the parse path: when a parse ran and its bytes match the cache, the write is no longer skipped if there's a fingerprint to store — otherwise the fingerprint would never land on disk and that source would parse fresh every launch forever.)
- [x] Count skips and add them to the end-of-scan log line, separate from the refreshed count.
- [x] Check that Phase 3 pruning is unaffected — it works off `variantsToScan()`, not parse results.
- [x] Check that `onFullScanComplete` still receives a slice for every source, including skipped ones.
- [x] Unit test the comparison: unchanged, edited file, added file, removed file, renamed file, deleted recorded file, missing folder, newly created folder.

## Step 4 — refresh forces a full parse

- [x] Add the static `_forceFullParse` set and `requestFullParse(domain)` to `CachedStreamListNotifier`. Comment on why it is not a provider and not an instance field: refresh replaces the notifier instance. (`requestFullParse()` is an instance method that adds its own `domain` to the static set, so call sites don't repeat the domain string.)
- [x] At the start of `build()`, read whether the domain is in the set — but only remove it when the forced build finishes its full scan. A forced build that gets superseded partway must leave the request in place for the build that replaces it, or the user's refresh silently does nothing.
- [x] When set, skip every fingerprint check and parse everything.
- [x] Call `requestFullParse` from each viewer's `onRefresh`: `ships_page.dart:149`, `weapons_page.dart:155`, `hullmods_page.dart:155`, `faction_viewer_page.dart:87`, and the debug refresh at `debug_section.dart:572` (both the "Read weapons" and "Read ships" buttons). The callbacks differ per viewer, so each gets its own line.
- [x] Check the remaining viewers (wings, ship systems, graphics index) for a refresh path and wire any that exist. (None of the three has one — nothing invalidates their providers from UI.)

## Step 5 — ships, then measure

- [x] Thread the recorder through `_parseOneFolder`, `_scanShipsFolder` and `_parseVariants` in `ship_manager.dart`.
- [x] Record `data/hulls`, `data/hulls/skins` and `data/variants` at each listing, including when a folder is absent. Skins and variants are listed recursively — record their full walks, not just the top-level names.
- [x] Record every `.ship`, `.skin`, `.variant` and `ship_data.csv` as it is read.
- [x] Launch twice with no mod changes in between. Confirm the second launch reports nearly every ship source skipped. (Second launch: `skipped 130 unchanged, refreshed 0 variants` — every source including vanilla.)
- [x] Write down the before and after numbers from the log line. Expected: 10–17 s down to about 1 s. (Measured: 10–17 s down to 3496 ms. Above the ~1 s prediction, but the other five domains and the descriptions parse were all still parsing in full at the same time on the same thread during that launch — the ships check was competing with them. Re-measure after Step 6 removes that contention.)
- [ ] Check by hand that editing one `.ship` file makes exactly that one mod re-parse and the rest stay skipped.
- [ ] **Stop here if the saving does not show up.** Work out why before doing the other six.

## Step 6 — the remaining data domains

Same shape each time: thread the recorder through, record each listing, record each file read, verify a second launch skips.

- [x] weapons — `data/weapons` and `data/shipsystems/wpn` flat (that is how the parse lists them for `.wpn` files), `data/weapons` and `data/shipsystems/proj` recursive for `.proj` files, plus every `.wpn`, `.proj` and `weapon_data.csv` read. `data/weapons` is listed twice — flat for `.wpn`, recursive for `.proj` — so the recorder keeps the recursive record when a folder is recorded both ways.
- [x] hullmods — `data/hullmods` listing plus `hull_mods.csv`. The listing stands in for the CSV existence check, so a mod without the file still gets a fingerprint and skips.
- [x] ship_systems — `data/shipsystems` listing plus `ship_systems.csv`, same pattern as hullmods. Icon paths resolved through *other* mods' folders are not recorded: a skipped mod keeps its cached icon paths until its own files change or the user refreshes. Noted in a comment at the parse.
- [x] wings — `data/hulls` listing, `wing_data.csv`, and the recursive `data/variants` walk with every `.variant` read (only walked when the CSV exists, matching the parse).
- [x] factions — `data/world/factions` recursive, plus `factions.csv` and every `.faction` read.
- [ ] After each, confirm a second launch skips that domain and that editing one of its files re-parses only that mod.

Portraits is not in this list: it does not use `CachedStreamListNotifier`, and it already skips variants it has seen.

## Step 7 — graphics index, measured and droppable

- [x] Left out, on the structural argument rather than an in-app measurement: the graphics scan reads no files at all — it *is* a recursive listing of `graphics/`, and the payload *is* the name list. The fingerprint check would re-do that identical walk and could save only the msgpack encode and byte compare, while storing a near-copy of the payload in every cache file and paying the walk twice whenever something changed. The check cannot be clearly cheaper than the scan, so graphics index keeps its current behavior: full scan every launch, byte-compare suppressing downstream rebuilds.

## Step 8 — write it down

- [ ] Update `openspec/specs/viewer-cache/spec.md` with the added requirements once this ships. (Happens when the change is archived — the delta spec in this change folder is ready to merge.)
- [x] Add a line to `changelog.md` in the user's voice — mods that haven't changed are no longer re-read on every launch, so viewers finish loading much sooner.
- [x] Note in `CLAUDE.md` under the viewer cache section that a change to which files a parse reads must bump that domain's `schemaVersion`.
