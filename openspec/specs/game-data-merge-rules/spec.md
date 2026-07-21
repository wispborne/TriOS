# Game Data Merge Rules

## Overview

One shared place that decides which mod's data wins, matching what Starsector does at load time. Replaces the five separate answers scattered across the loaders today.

Verified against decompiled Starsector 0.98a-RC8. Key sources: `StarfarerLauncher.java` (load-order sort and mod registration), `LoadingUtils.java` (the CSV and JSON merges, the list rules), `WeaponSpreadsheetLoader.java` / `WeaponSpecLoader.java` (weapons consuming both paths independently), `ShipHullSpecLoader.java` (the duplicate-id guard), `ShipHullSpreadsheetLoader.java` (a CSV row with no side file is warned about and dropped, not a crash), `SpecStore.java` (description keys, source attribution), `com.fs.util.C` from `fs.common_obf.jar` (the resource stack and the folder walk).

The gap that used to be here is closed: the class that holds the per-path source list and walks folders lives in `fs.common_obf.jar`, which has since been decompiled and read (`com.fs.util.C`). Both former inferences are now confirmed by code. The stack order: the launcher registers mods in reverse sorted order onto the *front* of the stack, so the first-sorted mod is consulted first and vanilla last. The folder walk: sources are visited in stack order, and each source's folder is read with an unsorted directory listing — so the order *between* sources is deterministic, and only the order *within* one folder is not. R4 relies on both halves.

## Requirements

### R1: Source order

- Sources are ordered mods first, vanilla last.
- Mods are sorted by `sortString`, falling back to the mod's display name, using plain string comparison. Alphabetically first means highest priority.
- An empty `sortString` counts as absent, the same as null.
- Ties between identical sort keys break by mod id. This is a small, deliberate difference: the game keeps its enabled-mods order for ties, which TriOS cannot reliably reproduce. It only shows when two mods have identical sort names.
- This is the game's order, and it is the opposite of TriOS's current arrangement, where vanilla is placed first.

#### Scenario: Vanilla loses to a mod

- **GIVEN** vanilla defines weapon `lightmg` in `weapon_data.csv`
- **AND** a mod also defines `lightmg` with different damage
- **WHEN** the weapon list is built
- **THEN** the mod's damage is shown, not vanilla's

#### Scenario: Mod ordering is unchanged

- **GIVEN** two mods named `Blackrock 0.97 Unofficial Add-on` and `Blackrock Drive Yards`, neither setting `sortString`
- **WHEN** sources are ordered
- **THEN** the add-on comes first, because `0` sorts before `D`
- **AND** this matches the order TriOS already produces today

### R2: CSV rows — first source wins

- Rows from `weapon_data.csv`, `ship_data.csv`, `hull_mods.csv`, `ship_systems.csv`, `wing_data.csv` and `descriptions.csv` are merged row by row, keyed on the `id` column.
- The key is a list of columns, not a single one. Most files key on `id` alone; `descriptions.csv` keys on `id` and `type` together. The game's own merge takes a list for this reason.
- The first source in R1 order to supply a given key wins that row outright.
- Every later copy of that key is dropped, including vanilla's.
- Replacement is whole-row. There is no per-column merging.
- A row whose key columns are all blank is skipped entirely. The game's merge drops such rows before they reach the result (they are spacer rows in the vanilla files), and TriOS SHALL drop them the same way. In particular they must not be treated as sharing one blank key and collapsed into a single surviving row.
- The game treats two rows with the same key *inside one file* as a fatal error. TriOS is a viewer and MUST NOT fail the whole list for this; it keeps the first and logs a warning naming the file and key.

#### Scenario: Add-on mod's rebalanced row wins

- **GIVEN** `Blackrock Drive Yards` defines `homing_laser` with 250 damage
- **AND** `Blackrock 0.97 Unofficial Add-on` defines `homing_laser` with different values
- **AND** the add-on sorts first
- **THEN** the add-on's row is used and Blackrock's row is dropped

### R3: JSON side files — lowest-priority mod wins

- Files looked up by path (`.wpn`, `.ship`, `.variant`, `.faction`, `default_ship_roles.json`, and config files under `data/config` such as `engine_styles.json`) are deep merged rather than taken whole.
- Vanilla is the base and is never layered on top of anything. The game finds it by asking which source is *not* a mod, pulls it out of the list, and starts from its copy.
- The mods are then applied on top in R1 order — highest priority first. So for any single value, the **last mod applied wins**, and the last mod applied is the **lowest-priority** one: alphabetically last.
- This is the exact reverse of R2. Given the same two mods, the alphabetically *first* one wins a spreadsheet row and the alphabetically *last* one wins a side-file value. That is the game's behaviour, not an error, and it is the single easiest thing to implement backwards.
- Do not describe this rule as "the last source in R1 order wins". The last source in R1 order is vanilla, and vanilla is the base that everything overwrites.
- Lists append rather than replace.
- A list whose **first** entry is exactly `core_clearArray` (case-sensitive) clears the base list first, then appends the incoming entries. Only index 0 is checked. The game leaves the marker itself in the merged list; TriOS strips it before display, which is a deliberate difference — see R7.
- A list replaces whole instead of appending when the **base** list (after any clear) has exactly 4 entries **and** its key name contains `color` or `button`, matched case-insensitively. The 4-entry condition gates both words. This is the game's general rule — there is no fixed list of key names.
- A list whose key name **starts with** `music_`, matched case-insensitively, also replaces whole instead of appending — at any length; the 4-entry condition does not apply to it. This is the same line of game code as the colour rule, and it is easy to drop because the name check is a prefix, not a contains. (A key named plain `music` does not match — the underscore is part of the prefix.)
- When a mod's copy holds a list or an object where the base holds a different shape, the game stops with a fatal "must be a JSON array / object" error. TriOS logs a warning naming the key, skips that key, and keeps the base value — see R7.
- Nested objects recurse with the same rules.

#### Scenario: The alphabetically last mod wins a side-file value

- **GIVEN** mods `A-mod` and `Z-mod`, neither setting `sortString`
- **AND** both ship a `homing_laser.wpn` setting `fireSoundTwo` to different values
- **WHEN** the file is resolved
- **THEN** `Z-mod`'s value is used, because it is applied last
- **AND** if those same two mods both defined `homing_laser` in `weapon_data.csv`, `A-mod` would win that row instead

#### Scenario: Partial side file keeps the fields it does not mention

- **GIVEN** mod A ships a full `homing_laser.wpn`
- **AND** mod B ships a `homing_laser.wpn` setting only `fireSoundTwo`
- **WHEN** the file is resolved
- **THEN** the result has B's sound and every other field from A

#### Scenario: Partial config entry keeps the rest of its fields

- **GIVEN** vanilla's `engine_styles.json` defines `HIGH_TECH` with several fields
- **AND** a mod's `engine_styles.json` sets only that style's glow colour
- **WHEN** engine styles are resolved
- **THEN** `HIGH_TECH` has the mod's glow colour and vanilla's other fields

#### Scenario: A colour list replaces instead of growing

- **GIVEN** vanilla's copy of a file has a 4-entry list under a key containing `color`
- **AND** a mod's copy sets that key to a different 4-entry list
- **WHEN** the file is resolved
- **THEN** the result is the mod's 4 entries alone, not 8

### R4: CSV rows and side files resolve independently

- The winner of a CSV row (R2) and the source of a side file (R3) are decided separately.
- A CSV row from one mod MUST be able to pair with a side file from a different mod.
- A CSV row whose side file is missing from every source MUST still produce an item, with the side file's fields left empty. It MUST NOT be dropped.
- Keeping that row is a deliberate difference from the game, which logs a warning and drops the row — the item silently never exists in game. A viewer should show the broken row and warn, not hide it — and the warning doubles as notice that the item will be missing in the game too. (Weapons already behave this way in TriOS today; ships currently drop the row, which happens to match the game.)
- The reverse case matches the game: a side file whose id never appears in the CSV produces no item. The game logs an error and removes such specs from its store; TriOS logs a warning and skips them.
- Side files merge by relative path. When two merged files declare the same item id, the **first** file wins and the second is skipped — the game guards its spec store with a "does this id already exist" check and silently ignores the loser.
- Which file is "first" is only partly luck. The game's walk visits sources in R1 order, so a clashing file in a higher-priority mod always loads before one in a lower-priority mod — that half is deterministic. Only *within* one folder is the listing unsorted, so two clashing files inside the same source resolve by chance.
- TriOS SHALL resolve clashes the same way: by source order first, matching the game exactly. Only when both files come from the same source — where the game's own answer is luck — does TriOS pick the alphabetically first path, so the result is at least the same every run. A warning names both files either way.

#### Scenario: CSV-only add-on keeps the parent mod's sprite

- **GIVEN** mod A ships both a `foo` CSV row and `foo.wpn` with a sprite
- **AND** mod B sorts first and ships only a tweaked `foo` CSV row, with no `.wpn`
- **WHEN** the weapon list is built
- **THEN** the weapon has B's stats and A's sprite

#### Scenario: Ship with no matching .ship file is still listed

- **GIVEN** a mod ships a `ship_data.csv` row for `bar` and no `bar.ship` anywhere
- **THEN** `bar` appears in the ship list with its CSV stats and no hull geometry
- **AND** a warning is logged naming the mod and the id

#### Scenario: Two files in different mods claim the same id

- **GIVEN** `A-mod` ships `z_laser.wpn` and `Z-mod` ships `a_laser.wpn`, both declaring id `laser`
- **WHEN** side files are paired with CSV rows
- **THEN** `z_laser.wpn` supplies the data, because `A-mod` is the higher-priority source — path names do not enter into it
- **AND** a warning names both files

#### Scenario: Two files in one mod claim the same id

- **GIVEN** one mod ships both `a_laser.wpn` and `b_laser.wpn` declaring id `laser`
- **WHEN** side files are paired with CSV rows
- **THEN** `a_laser.wpn` supplies the data, because its path sorts first — the game's own answer here is filesystem luck
- **AND** a warning names both files

### R5: Attribution

- Each item records which source supplied its CSV row and which source supplied its side file, so the UI can say where a value came from when the two differ.
- The game attributes a weapon to whoever won the CSV row. TriOS SHALL match that for the "Mod" grouping and column, and expose the side file's source separately.

#### Scenario: Split sources are both visible

- **GIVEN** the CSV-only add-on case in R4
- **WHEN** the user opens the weapon's details
- **THEN** the mod shown is B, and the sprite's source is listed as A

### R6: One place decides who wins

- All merging lives in `lib/utils/game_data_merge.dart`. No loader decides who wins, and no loader decides which rule applies to its data either.
- The file exposes one entry point per kind of data: `mergeWeapons` and `mergeShips` (CSV rows plus side files, paired by id), `mergeShipSkins`, `mergeFactions`, `mergeDescriptions`, `mergeEngineStyles`, `mergeShipRoles`, and `mergeById` for the types with no side files (hullmods, ship systems, fighter wings). `orderedSources` (R1) supplies the source order to all of them.
- `.skin` files get their own entry point rather than going through `mergeShips`, because a skin produces a ship on its own instead of pairing with a spreadsheet row.
- The two rules behind them — R2's first-wins and R3's deep merge — are private. A caller cannot pick the wrong rule, because it never picks a rule at all.
- Entry points take raw scanned data and return merged raw data. The file MUST NOT read from disk and MUST NOT import viewer models (`Weapon`, `Faction`, …) — a utility every feature depends on must not depend on every feature. Loaders own scanning, caching, and model building.
- Pairing a CSV row with its side file (R4) happens inside `mergeWeapons` / `mergeShips`, not in the loaders.

#### Scenario: Skins resolve after the merge, not during the scan

- **GIVEN** a mod ships a `.skin` file whose base hull comes from a different mod
- **WHEN** ships are built
- **THEN** the skin resolves, because skin resolution runs on merged data rather than mid-scan
- **AND** a skin whose base hull is itself a skin resolves too, whatever order the files arrive in

#### Scenario: Scanning throws nothing away

- **GIVEN** two sources both supply an item with the same id
- **WHEN** the scan completes
- **THEN** both copies exist, each tagged with its source
- **AND** the winner is decided only by the shared entry point

### R7: Where TriOS deliberately differs from the game

Every difference below is a choice, not a gap. Each exists because TriOS is a viewer and the game is a game. Anything not listed here is meant to match the game exactly.

- **A missing side file does not remove the item.** The game logs a warning and drops a `ship_data.csv` row that has no `.ship` file anywhere — the ship silently never exists. TriOS shows the row with no hull geometry and warns, so the user can see the broken setup instead of guessing why the item is missing in game (R4).
- **The `core_clearArray` marker is hidden.** The game leaves the literal string in the merged list, so consumers see it as an entry. TriOS strips it before display, because showing a ship called `core_clearArray` in a faction's fleet is nonsense.
- **Clashing ids inside one mod resolve the same way every run.** Between mods the game is already deterministic — the higher-priority source's file wins — and TriOS matches it (R4). Only within a single folder is the game's walk unsorted; there TriOS picks the alphabetically first path instead of leaving it to filesystem luck.
- **Identical sort names tie-break by mod id.** The game keeps its enabled-mods order for ties, which TriOS cannot reliably reproduce (R1).
- **Duplicate keys inside one file are a warning, not a crash** (R2).
- **A wrong value shape is a warning, not a crash.** When a mod's JSON supplies a list or object where the base holds a different shape, the game stops with a fatal error. TriOS logs a warning, skips that key, and keeps the base value (R3).
- **Row order is not reproduced.** The game moves vanilla's surviving rows to the front of some spreadsheets, which matters for order-sensitive data it reads at runtime. TriOS sorts its own lists for display and does not attempt to reproduce this. It affects nothing TriOS shows.
