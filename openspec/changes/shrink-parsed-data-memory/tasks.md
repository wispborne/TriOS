# Tasks

Do the string pool first and measure it. It is the biggest single saving, it has no behaviour question attached, and it is the half most likely to disappoint if a call site is missed. Skipping blank cells comes second because it is smaller and touches what `fromMap` sees.

## Step 1 — record the starting point

- [x] Release build, 460 mods, visit every page, note Task Manager's figure. Everything after this is compared against it. (Recorded: ~800 MB, 2026-08-07.)
- [x] Take a DevTools heap snapshot with internal classes shown. Note `_OneByteString` count and size, `_Map`, and `_Uint32List`. These are the numbers that should move. (Recorded from `dart_devtools_2026-08-07_22_10_25.420.csv`: `_OneByteString` 3,431,844 / 211.8 MB; `_Map` 271,395 / 16.6 MB; `_Uint32List` 211,624 / 41.6 MB. Debug build — compare against another debug-build snapshot.)

## Step 2 — the string pool

- [x] Add the pool somewhere shared — `lib/utils/string_pool.dart`, one function (`sharedString`), no class. Strings of 64 characters or fewer are pooled; longer ones are returned as they are.
- [x] Comment on it: why 64, why it is never cleared, and that a parse moved to `AppWorker` gets its own pool per isolate rather than sharing across the boundary.
- [x] `lib/starsector_json/json_parser.dart` — pool both returns of `readString` (the common case and the backslash case). This covers every quoted string in all 33,750 side files. (Also done: bare tokens in `readValue` — unquoted values like `RENDER_LOADED_MISSILES` repeat across thousands of `.wpn` files and don't go through `readString`. Design updated.)
- [x] `lib/utils/csv_parse_utils.dart` — pool the string value in `rowToTypedMap`. Headers are already one object per file, so only values need it.
- [x] `lib/ship_viewer/ship_manager.dart` — same change to the inline copy of that loop.
- [x] `lib/weapon_viewer/weapons_manager.dart` — same change in `_typedRow`.
- [x] `lib/fighter_viewer/wings_manager.dart` — same change to the inline copy.
- [x] Check hullmods and factions for a row builder of their own. (Hullmods has one — a fifth copy of the loop, missed by the first survey because it names its variables differently. Same change applied. Factions builds no row maps: `factions_csv.dart` produces a key set, and `.faction` content goes through the JSON parser, so it is covered there. Design updated.)
- [x] `lib/viewer_cache/cached_stream_list_notifier.dart` — pool keys and string values in `normalizeForMapper`. **This is the one that matters on a normal launch**, because launches read msgpack rather than parsing files. (Verified all seven decode paths — ships, weapons, hullmods, ship systems, wings, factions, portraits, graphics index — route through `normalizeForMapper`.)
- [x] Do not consolidate the five duplicated row loops. Separate cleanup; mixing it in makes this change impossible to measure. (Not consolidated.)
- [x] Launch, then take a heap snapshot. `_OneByteString` should drop by roughly a million objects and 80–90 MB. **If it barely moves, a call site is missing — most likely the cache path. Find it before going on.** (Measured: **3,431,844 → 1,152,412 objects, 211.8 → 147.5 MB (−2.28M, −64 MB)**. No call site missing. The snapshot was taken mid-load and held several duplicate merged weapon lists, so the true steady-state saving is larger than −64 MB, not smaller.)

## Step 3 — stop storing blank cells

- [x] All row builders: skip the entry instead of writing null. `rowToTypedMap`, and the copies in ships, weapons, wings, and hullmods.
- [x] Bump `schemaVersion` for ships and weapons (both 4 → 5). Their payloads cache raw CSV rows, old caches hold rows with null entries, and fingerprint-skipped mods never rewrite their cache — without the bump the saving never reaches cached mods. (Found only when the first Task Manager reading came back unchanged. Hullmods, wings and ship systems need no bump: they cache model `toMap()` output, which is unchanged. Costs one full ships+weapons re-parse on the first launch after this ships.)
- [x] Comment on `rowToTypedMap` stating the invariant: a blank cell is absent, so readers must use `row['x']` and never `containsKey`, and a non-nullable mapped field with a default value will now get its default.
- [x] Comment at the places a raw row goes straight into `fromMap` — three, not two: ship systems, wings, and hullmods. Each model has one non-nullable field (`id`) and each loader already skips rows without it, which is the only reason this is safe. Said so in the comments, because it is safe by coincidence rather than by design. (Also checked `Ship` and `Weapon`, which build from CSV-derived maps: only non-nullable stored field is required `id`, blank-id rows dropped by the merge first. `blankUnusableNumbers` reads `data[field.key]`, absent reads as null. Design updated.)
- [ ] Check the Ship Systems and Fighters pages by hand against the current build. Every column that had a value before must still have it, and every blank must still be blank. *(Needs the app run — user.)*
- [ ] Check Ships, Weapons and Descriptions the same way. Sort by a column that is blank for most rows — that is where a mistake shows. *(Needs the app run — user.)*
- [x] Snapshot again. `_Map` and `_Uint32List` should both drop; those index arrays are 41.6 MB today. (`_Uint32List` **211,624 → 141,970 objects, 41.6 → 29.4 MB (−12.2 MB)**, and `_Record` −6.5 MB. `_Map` stayed flat, and the expectation in this task was simply wrong: skipping blank cells shrinks each row map's backing array, it does not reduce how many maps exist — and a `_Map`'s own row in the profile is the shallow object, with its backing array counted under `_List`. Nothing to fix.)

## Step 4 — measure and write it down

- [ ] Release build, 460 mods, every page visited, Task Manager. Compare against Step 1. Expected: about 800 MB down to about 660 MB. *(Needs the app run — user.)*
- [ ] Write the before and after numbers into this file. If the saving came in well under 140 MB, say where it went instead of quietly moving on.
- [ ] Confirm startup time did not regress. The pool adds a hash lookup per string; the measurement said this is free, but that was outside the app. *(Needs the app run — user.)*
- [x] `flutter test` — the merge and parse tests cover most of the risk in Step 3. (Full suite run after the change: all 814 tests pass.)
- [ ] Add a line to `changelog.md` in the user's voice: TriOS uses less memory with a large mod list, because repeated text in mod data is stored once instead of thousands of times and blank spreadsheet cells are no longer kept. *(Was marked done in error — `changelog.md` is unmodified in git, so no such line exists. Needs writing, and the wording needs sign-off before it goes in.)*
- [x] Add a note to `CLAUDE.md` under the game data merging section: a blank cell in a raw CSV row is absent, not null, so read rows with `row['x']` and never `containsKey`. (Also mentions `sharedString` so new parse paths pool too.)
- [x] Delete `scratchpad/measure_parse_cost.dart` or move it somewhere it will be found again. (Moved into this change folder: `measure_parse_cost.dart`.)

## Where verification stands

The mechanisms are confirmed live in the real app (numbers on the two tasks above). What is **not** settled:

- **No clean steady-state comparison yet.** Every snapshot taken so far was mid-load, and two of the exports were stale DevTools tables re-downloaded rather than fresh samples. The Profile Memory table does not refresh on its own: let the app fully load, press GC, press refresh **on the table**, then export.
- **Task Manager on a release build has not been re-checked** since the `schemaVersion` bump landed. The one reading taken before it (813 MB) could not have shown the blank-cell saving, because old caches still held their nulls.
- **An unexplained stall.** In one launch the TriOS data counts froze for 3.5 minutes with ships at 4,921 of ~6,892 and several complete duplicate `Weapon` lists alive (36,159 = ~4.4 copies). The changed code is **cleared** as the cause: the real pooled parser was run over all 57,183 `.ship`/`.skin`/`.wpn`/`.proj`/`.variant` files in the install — zero failures, zero hangs, 30 s total — and the CSV edits are a skip plus a map lookup. Needs a TriOS log from a launch that reaches the stuck state. May also have been an artifact of the stale exports.
- **Flutter UI memory grew 50 → 121 MB** versus the baseline snapshot, with `SemanticsConfiguration` at 2.5× (20,796 → 50,475 nodes). Unrelated to parsed data — it is this session's UI state — but 70 MB of UI growth would hide the data-side win in Task Manager. Worth its own look.

## Not in this change

Written down here so they are not lost:

- **The descriptions recompose** — its own change: `reuse-description-entries`.
- **Dropping the raw payloads after merging.** Around 300 MB, but enabling or disabling a mod goes from instant to a full re-read of 460 cache files. Its own change if 660 MB is still too much.
- **The codex index rebuilding 11 times during startup.** 233,000 wrapper objects each time. Debug-only page, so it is a startup-speed issue rather than a user-facing one.
- **`Float32List` for `Ship.bounds` and `ShipWeaponSlot.locations`/`position`**, about 10 MB.
- **The four `late final` fields on `ShipWeaponSlot`**, about 3 MB, but they are memoised for hot filter paths.
