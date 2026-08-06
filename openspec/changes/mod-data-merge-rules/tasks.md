# Tasks

Steps 2 and 4 change what weapons and ships look like in between, so the whole change ships as one release.

## Step 1 — build the shared file

- [x] Create `lib/utils/game_data_merge.dart`. One entry point per kind of data; the merge rules are private; loaders decide nothing.
- [x] Add `orderedSources` (R1): mods sorted by `sortString` falling back to display name, then vanilla last. Reuse `sortedByGameLoadOrder()` for the sort; the new part is that vanilla's position is decided here rather than by each loader.
- [x] Comment on `orderedSources`: ties between identical sort keys break by mod id here; the game keeps its enabled-mods order instead. Only shows when two mods have identical sort names.
- [x] Add the private first-wins rule (R2): sources in order, items per source, key function in; one resolved list out, every item tagged with its source. The CSV flavour builds its key by joining the key columns, the way the game does.
- [x] Add `mergeById` on top of it: first-wins keyed on id, for parsed objects. It is the only entry point with a rule in its name, so its doc comment states the rule.
- [x] In the first-wins rule, skip rows whose key columns are all blank, matching the game — never collapse them into one shared blank key. On a duplicate key inside one file keep the first and log a warning. The game treats that duplicate as fatal; a viewer must not drop a whole list over one bad row.
- [x] Add `mergeDescriptions`: rows in, resolved rows out, keyed on `id` and `type` internally.
- [x] Move the deep merge in from `lib/faction_viewer/faction_merge.dart` as the private R3 rule.
- [x] Replace its fixed colour key names with the game's rule (`LoadingUtils.java:384-390`): replace whole when the base list has exactly 4 entries and the key contains "color" or "button", matched in lower case — and also when the lower-cased key starts with `music_`, at any length. The 4-entry check gates the two words but not the `music_` clause. Otherwise lists append.
- [x] Match the game's `core_clearArray` check exactly (`LoadingUtils.java:376-382`): index 0 only, exact case-sensitive string.
- [x] On a value-shape mismatch (a mod supplies a list or object where the base holds a different shape), log a warning naming the key, skip it, and keep the base value. The game treats this as fatal; a viewer must not fail the whole file over one bad key.
- [x] Keep stripping the `core_clearArray` marker from the result before display, even though the game leaves it in — it would otherwise show up as a fleet entry. Note it in the code as a deliberate difference.
- [x] Put the merge direction in the deep merge's doc comment in plain words: vanilla is the base and is never applied on top, mods apply highest-priority first, so the alphabetically last mod wins. The two rules live in one file and are one word apart.
- [x] Drop the `music` special case in `faction_merge.dart` (~line 110), which replaces the whole `music` object instead of merging into it. The game's music rule is an array rule keyed on the `music_` prefix — a plain `music` key does not match it, so the object deep-merges like any other. TriOS does not display or use music anywhere. Delete its test in `test/faction_merge_test.dart` (~line 125) along with it.
- [x] Add `mergeFactions`: per-source faction files in, one merged file per path out, with attribution.
- [x] Add `mergeEngineStyles` and `mergeShipRoles`: single-file deep merges.
- [x] Add `mergeWeapons` and `mergeShips`: per-source CSV rows and side-file maps in; paired raw records out (winning row, merged side file, both source tags). One private recipe, two thin wrappers.
- [x] Add a comment saying this file never reads from disk and never imports a viewer model, and why: the managers own scanning, caching, and model building, and a utility every feature depends on must not depend on every feature.
- [x] Update `faction_manager.dart` and `ship_roles_manager.dart` to call `mergeFactions` / `mergeShipRoles`.
- [x] Delete `lib/faction_viewer/faction_merge.dart`.
- [x] Delete the duplicate constants in `faction_manager.dart`: `_isColorKey` (~line 470) and the second `core_clearArray` literal (~line 440).
- [x] Run `test/faction_merge_test.dart`, updated mechanically for the new entry point, and confirm the behaviour it checks is unchanged.
- [x] Add unit tests for each entry point on its own, since most have no caller until steps 2 to 4.

## Step 2 — loaders stop picking winners

- [x] Replace the hand-rolled dedup loop in `_flatten()` with `orderedSources` + `mergeById`, so the base class holds no rule of its own.
- [x] Leave the parse order in `build()` alone — vanilla still parses first, because ship skins need vanilla hulls available.
- [x] Fix `loadOrderKey` in `mod_info.dart:67` so an empty `sortString` falls back to the name, matching the game.
- [x] Add a test: vanilla and a mod both define the same weapon id, the mod's version wins.
- [x] Add a test: two mods with no `sortString` order by display name, and the order is unchanged from today.
- [ ] Check by hand in the app that a known rebalance mod's numbers now show instead of vanilla's.

## Step 3 — descriptions and engine styles

- [x] Delete `_composeDescriptions` in `descriptions_manager.dart` and call `mergeDescriptions` with sources from `orderedSources`, which fixes both the direction and the missing load-order sort (~line 51) at once.
- [x] Use `orderedSources` for the folder list in `engine_styles_manager.dart` (~line 23), replacing the raw `AppState.mods` order.
- [x] In `engine_styles_manager.dart`, merge the raw style maps with `mergeEngineStyles` and build `EngineStyleSpec` once at the end, instead of replacing each style whole.
- [x] Keep the per-style try/catch that stops one bad style dropping the others — move it to where the specs get built.
- [x] Add a test: a mod setting one field of a vanilla engine style keeps the style's other fields.
- [x] Add a test: two mods define the same description id, the alphabetically first one wins.

## Step 4 — split scanning from merging (weapons)

- [x] Change `WeaponsCachePayload` to hold raw CSV rows and raw `.wpn` maps tagged with their source, instead of finished `Weapon` objects.
- [x] Make `WeaponListNotifier.itemId` source-qualified so no mod's copy is dropped during the scan, following `faction_manager.dart:55`.
- [x] Bump `schemaVersion` on `WeaponListNotifier`.
- [x] Add a provider that hands the raw data to `mergeWeapons` and builds `Weapon` objects from the paired records. The provider decides nothing itself.
- [x] Keep a CSV row that has no `.wpn` anywhere — produce the weapon with empty sprite fields and log a warning.
- [x] Add a second attribution field to `Weapon` for the side file's source; leave `modVariant` meaning the CSV row's source.
- [x] Run `dart run build_runner build --delete-conflicting-outputs` after the model changes.
- [x] Confirm `weaponListNotifierProvider` still yields `List<Weapon>` and nothing downstream needed changing.

## Step 4 — split scanning from merging (ships)

- [x] Apply the same payload and resolver changes to `ShipListNotifier`, via `mergeShips`.
- [x] Bump `schemaVersion` on `ShipListNotifier`.
- [x] Stop dropping a CSV row when no `.ship` file exists (`ship_manager.dart:396-402`); keep the ship with empty geometry and log a warning, matching what weapons already do. The warning should note the ship will be missing in the game too — the game logs a warning and drops such rows.
- [x] `.variant` parsing is unchanged. `.skin` resolution had to move: it reads finished ships to find base hulls, which no longer exist during the scan, so it now runs on merged data in the new provider. Its logic is unchanged; only its inputs and timing are. This is a deviation from the design, agreed with the user, and it also means a skin can now sit on a base hull from a different mod.
- [ ] Re-run the ship viewer by hand and confirm skins still resolve.

## Tests

- [x] CSV first-wins: two mods define the same id, the alphabetically first one wins.
- [x] Side file lowest-priority-wins: two mods ship the same `.wpn` path, the alphabetically **last** mod's values win — the opposite of the CSV test above. Write both tests next to each other so the reversal is visible.
- [x] Partial side file keeps fields it does not mention.
- [x] List rules: plain lists append; `core_clearArray` wipes first and the marker does not survive into the result; a 4-entry "color"/"button" list replaces whole; a 3-entry "color" list still appends, since the count gates the rule; a `music_`-keyed list replaces whole at any length.
- [x] Two side files in different mods claim the same id: the higher-priority mod's file wins regardless of path names. Two side files in one mod: the alphabetically first path wins. A warning names both files in both cases.
- [x] Blank-key CSV rows are skipped, matching the game — and never collapsed into one surviving row.
- [x] CSV row with no side file anywhere still produces an item.
- [x] Side file whose id has no CSV row anywhere produces no item and logs a warning, matching the game.
- [x] Split sources: stats from one mod, sprite from another, both attributed correctly.
- [x] The Blackrock case end to end — the add-on's CSV row wins and Blackrock Drive Yards' sprite survives.

## Wrap up

- [x] Update `openspec/specs/viewer-cache/spec.md`, which currently records first-occurrence-wins with vanilla first as correct.
- [x] Add a changelog line saying weapon and ship numbers will change on installs with rebalance mods, so it does not look like a regression.
- [x] Run `flutter analyze` and `flutter test`.
- [x] Search the codebase for any remaining hand-rolled version of these rules — a `seen` set doing first-wins, an `addAll` fold across mod folders, or a mod list built without `orderedSources`. Anything left is either a bug or needs a comment saying why it is different.
- [x] Confirm every deliberate difference from the game listed in R7 is actually implemented and carries a comment where it happens.
- [x] Note the follow-up work left out of this change: portrait metadata parses `.faction` files a second time and non-recursively, so it should read the faction loader's data instead; the copy-pasted boilerplate across the six loaders; and `mod_info.json`'s `replace` list, which the game uses to skip merging a path entirely and hand it to one mod — it overrides both rules in this change, so it belongs inside the shared file as a check that runs before either.

## Left for later

- **Portrait metadata** parses `.faction` files a second time, and
  non-recursively, so it disagrees with the faction loader about which files
  exist. The fix is to read the faction loader's data instead of parsing twice.
- **Copy-pasted boilerplate across the six loaders** — the vanilla key defined
  in several places, the typed-CSV row helper inlined four times. Tidy-up, not
  correctness.
- **`mod_info.json`'s `replace` list.** When a mod claims a file path, the game
  skips merging that file entirely and uses that mod's copy alone. It overrides
  both rules in this change, so it belongs inside `game_data_merge.dart` as a
  check that runs before either.
