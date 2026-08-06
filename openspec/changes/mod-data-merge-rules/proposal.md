# Match the game's rules for which mod's data wins

## The problem

When two mods define the same weapon, ship, or hullmod, TriOS has to pick which one to show. It currently picks wrong in two ways.

**Vanilla beats every mod.** The viewer loaders put vanilla's data first and then keep the first version of each id they see. So vanilla always wins. The game does the opposite — vanilla is checked last, after every mod. This means any mod that rebalances a vanilla weapon or ship is silently thrown away. TriOS shows vanilla's numbers; the game shows the mod's. This affects weapons, ships, hullmods, ship systems, and fighter wings.

**A mod's CSV row drags its missing files along with it.** The game looks up two things separately: the stats row in `weapon_data.csv`, and the sprite and spec in `homing_laser.wpn`. Mod B can win the stats row while mod A still supplies the sprite. TriOS pairs the CSV row with the `.wpn` file inside a single mod folder, then picks one folder's finished object whole. So an add-on mod that ships a tweaked CSV and no `.wpn` takes the stats *and* wipes out the sprite. Ships are worse: a CSV row with no matching `.ship` file in the same folder is dropped entirely, so the ship vanishes.

This is common. Balance add-ons for big mods often ship nothing but an edited `weapon_data.csv`.

There is a third problem underneath both: the rules are written five different times in five places, and they disagree with each other. Factions and ship roles merge properly. The six viewer loaders don't merge at all. Descriptions and engine styles merge in the opposite direction. Portrait metadata parses `.faction` files a second time, and disagrees with the faction loader about which files exist.

## What the game actually does

Read from the decompiled 0.98a-RC8 code. Load order is plain alphabetical on `sortString`, falling back to the mod's display name; an empty `sortString` counts as absent. Alphabetically first means highest priority. Vanilla sits below every mod.

There are three rules, and they don't all run the same direction:

| File type | Rule |
| --- | --- |
| CSV rows (`weapon_data.csv`, `ship_data.csv`, …) | Merged row by row, keyed on `id`. The **first** source to claim an id wins. Later copies are dropped, including vanilla's. |
| `.wpn`, `.ship`, `.variant`, `.faction` | Deep merged. Vanilla is the base and is never layered on. Mods go on top highest-priority first, so the **lowest-priority** mod — alphabetically last — wins any single value. Lists append instead of replacing. `core_clearArray` wipes the list first. A 4-entry list whose name contains "color" or "button" replaces whole instead of appending, and so does any list whose name starts with `music_`, at any length. |
| Sprites, sounds, plain text | First source wins, whole file. |

The two directions are the thing to keep hold of, and they are genuinely opposite. Take two mods, A and Z. If both define a weapon in `weapon_data.csv`, **A** wins. If both ship a `homing_laser.wpn`, **Z** wins. Same two mods, different winner, depending only on which file the value came from. Vanilla loses either way.

Two more findings worth writing down. A `ship_data.csv` row with no `.ship` file anywhere is quietly dropped by the game — a log warning and the ship never exists. And when two different side files claim the same id, the game keeps whichever it reads first; its walk visits mods in load order, so between mods the winner is deterministic — only when both files sit inside one folder does it come down to chance, because the folder listing itself is unsorted.

## The solution

Four steps, shipped together as one release.

**1. Put every merge in one file.** `lib/utils/game_data_merge.dart` becomes the only place that decides who wins. It has one entry point per kind of data — `mergeWeapons`, `mergeShips`, `mergeFactions`, `mergeDescriptions`, `mergeEngineStyles`, `mergeShipRoles`, and a plain `mergeById` for the types with no side files. A loader hands over the raw data it scanned, per mod, and gets merged raw data back. It never picks a rule, so it can't pick the wrong one. The two rules above stay private inside the file.

This is how the game is arranged too — a game loader never merges anything, it asks the settings layer for a path and gets merged data back.

The deep merge mostly exists already, in `lib/faction_viewer/faction_merge.dart` — `ship_roles_manager.dart` already calls it for a non-faction file. It moves into the new file with one fix. It currently decides "replace this list instead of appending" from a fixed list of faction colour key names. The game has no such list; its rule is general — a 4-entry list whose name contains "color" or "button" replaces whole. The move adopts the game's rule, so weapon and ship files with colour settings the faction list never heard of merge correctly too.

Two limits worth stating up front: the new file never reads from disk, and it never sees a viewer model like `Weapon` or `Faction`. Raw data in, merged raw data out. The loaders own scanning, caching, and turning merged data into models.

**2. Loaders stop picking winners.** The shared loader base class currently keeps the first copy of each id it sees, with vanilla placed first — which is the vanilla bug. It stops holding any rule of its own and instead orders its sources and merges through the shared file, vanilla last. Small change, fixes the first bug, and removes the base class's own copy of the rule.

Worth being careful here: the ordering *among mods* is already correct. Only vanilla is on the wrong end. Do not change the mod ordering.

**3. Move the two stray loaders onto the shared rules.** Descriptions and engine styles each merge their own way today, and both are wrong:

- `descriptions.csv` is a CSV, so the game's rule is first-wins. TriOS folds it last-wins, and does not sort mods into load order at all — so the winner is decided by whatever order the mods folder happened to list.
- `engine_styles.json` gets the direction right but also skips the load-order sort, and it replaces each style whole rather than merging its fields. A mod tweaking one value of `HIGH_TECH` wipes the rest.

They become calls to `mergeDescriptions` and `mergeEngineStyles`.

**4. Split scanning from merging for weapons and ships.** Keep each mod's raw CSV rows and raw `.wpn`/`.ship` files separately, then hand both to `mergeWeapons` / `mergeShips`, which resolve the rows, resolve the side files, and pair them up by id — all inside the shared file. A stats row from one mod can now pair with a sprite from another. The faction loader already works this way and is the model to copy.

Ships also adopt the behaviour weapons already have: a CSV row with no `.ship` file anywhere is kept, shown with no hull shape, and logged as a warning — instead of being dropped. The game drops that row with only a log warning, so this is a deliberate difference: a viewer should show the broken row and warn about it, not hide it the way the game does. The warning doubles as a heads-up that the item will be missing in the game too.

Steps 2 and 4 must land in the same release. Step 2 alone would make a stats-only rebalance mod win the whole weapon — right numbers, missing sprite — which looks like a regression until step 4 pairs the sprite back in.

## In scope

- A shared merge utility with one entry point per kind of data, and the two merge rules private inside it.
- The loader base class no longer holds a dedup rule of its own; vanilla moves to last.
- Descriptions and engine styles moved onto the shared entry points.
- Weapons and ships restructured so a CSV row from one mod can pair with a side file from another, with the pairing done inside the shared utility.
- The list-replacement rule fixed to match the game (4-entry "color"/"button" lists and `music_` keys) instead of a fixed list of names.
- Updating the `viewer-cache` spec, which currently writes down the old behaviour as correct.
- Tests covering the cases above, including the Blackrock add-on case that started this.

## Out of scope

- **Portraits.** The loader keys its results per mod and never resolves ids across mods, so there is nothing for the shared rules to decide.
- **Portrait metadata.** Its problem is not the merge rule. It parses `.faction` files a second time, and non-recursively, so it disagrees with the faction loader about which files exist. The fix is to stop parsing them twice and read the faction loader's data instead. Pointing it at the shared utility would only make two disagreeing parsers agree on their merge rule. Worth its own change.
- `.skin` resolution in `ship_manager.dart`. It is a separate hand-written algorithm, roughly 180 lines, and it is not obviously wrong. Leave it alone.
- The `replace` / full-override list in `mod_info.json`, which lets a mod claim a file path outright. TriOS ignores it today. Verification showed this is stronger than it sounds: when a mod claims a path, the game skips merging that file entirely and uses that mod's copy alone. So it overrides everything in this change, for both spreadsheets and side files. Still its own piece of work — but when it happens, it belongs inside the shared merge file, as a check that runs before either rule.
- Deduplicating the copy-pasted boilerplate across the six loaders (`__vanilla__` defined four times, the typed-CSV helper inlined four times, and so on). Tidy-up, not correctness.
