# Design

## Where things stand

`lib/viewer_cache/cached_stream_list_notifier.dart` holds the code that matters:

```dart
// _flatten(), around line 392
List<T> _flatten() {
  final seen = <String>{};
  final out = <T>[];
  for (final payload in _slices.values) {
    for (final item in itemsFromPayload(payload)) {
      if (seen.add(itemId(item))) out.add(item);
    }
  }
  return out;
}
```

`_slices` is filled vanilla first, then mods in load order. Combined with first-wins, that gives vanilla the win. Six loaders inherit this: weapons, ships, hullmods, ship systems, wings, and the faction file scan.

`lib/faction_viewer/faction_merge.dart` is the closest thing in the repo to the game's JSON merge, and it already gets used outside factions — `ship_roles_manager.dart:97` calls it for `default_ship_roles.json`. It has one real gap, covered in step 1.

## Step 1: build the shared file

**All merging happens in `lib/utils/game_data_merge.dart`.** No loader decides who wins, and no loader decides which rule applies to its data either. A loader hands over what it scanned per source and gets merged raw data back.

This mirrors how the game is put together. A game loader never merges anything either — it asks the settings layer for a path and receives merged data:

```java
// WeaponSpreadsheetLoader.java:33 — merged CSV, keyed on "id"
JSONArray var1 = LoadingUtils.Ó00000("id", "data/weapons/weapon_data.csv");

// WeaponSpecLoader.java:62 — merged JSON, per enumerated .wpn path
JSONObject var1 = LoadingUtils.Ó00000(var0);
```

The public entry points, one per kind of data:

- **`orderedSources(...)` — R1.** The source list in the game's order: mods sorted by `sortString` (falling back to display name, empty treated as absent), then vanilla last. Today this is split between `sortedByGameLoadOrder()` in `mod_variant.dart` and a separate decision about where vanilla goes, made independently by each loader — which is how vanilla ended up on the wrong end in six of them. Keep `sortedByGameLoadOrder()` as the sort; put the vanilla placement here so there is one answer. One deliberate difference, written as a comment on the function: TriOS breaks ties between identical sort keys by mod id; the game keeps its enabled-mods order for ties, which TriOS cannot reliably reproduce. It only shows when two mods have identical sort names.
- **`mergeById(...)` — R2.** Plain "first source wins, keyed on id" over already-parsed objects. This is everything hullmods, ship systems and fighter wings need, and it is what the loader base class calls when flattening. It is the only entry point with a rule in its name, so its doc comment states the rule.
- **`mergeDescriptions(...)` — R2.** Rows in, resolved rows out. The two-column key — `id` and `type` together — lives inside, so the caller never needs to know it.
- **`mergeWeapons(...)` / `mergeShips(...)` — R2 + R3 + R4.** Per-source CSV rows and per-source side-file maps in; finished raw records out: the winning row, the merged side file, and both source tags, already paired by id. Both are thin wrappers over one private recipe, since they are the same shape.
- **`mergeFactions(...)` — R3.** Per-source `.faction` files in; one merged file per path out, with attribution.
- **`mergeEngineStyles(...)` / `mergeShipRoles(...)` — R3.** Single-file deep merges for `engine_styles.json` and `default_ship_roles.json`.

Behind them, private, live the two actual rules:

- **First-wins by key** — the core of R2. The CSV flavour builds its key by joining the key columns, the same way the game does.
- **The deep merge** — R3, moved in from `faction_merge.dart`, with one fix. It currently decides "replace this list instead of appending" from a fixed list of colour key names. The game's rule is general (`LoadingUtils.java:384-390`): replace whole when the **base** list has exactly 4 entries **and** the key name contains "color" or "button", matched in lower case. The 4-entry condition gates both words — Java's `&&` binds tighter than `||`. The same line carries a third clause that is easy to miss: a key whose lower-cased name **starts with** `music_` also replaces whole, at any length. Adopt the game's rule and drop the name list, or `.wpn` and `.ship` colour settings the faction list never heard of merge wrong, silently.

Write the direction into the function's own doc comment, in these words: vanilla is the base and is never applied on top; mods are applied highest-priority first; therefore the alphabetically **last** mod wins a value, the opposite of the spreadsheet rule. It is stated this bluntly because "last wins" and "first wins" are one word apart and the two rules sit in the same file.

The old code also replaces the whole `music` object rather than merging into it (`faction_merge.dart:110`). That is an object rule, and the game's music rule is an array rule keyed on the `music_` prefix — a key named plain `music` does not match it (the underscore is part of the prefix), so a `music` object deep-merges like any other object. The object rule goes, along with its test — TriOS does not display or use music anywhere, so nothing observable changes.

Then delete the duplicate constants inside `faction_manager.dart` — `_isColorKey` at line 470 and the second `core_clearArray` literal at line 440 both restate what the merge file already has.

### What stays out of this file

**File reading.** The managers scan per mod and cache parsed payloads to disk, streaming partial results as they go — that is the whole viewer-cache design. If this file did its own I/O it would either duplicate that machinery or swallow it. So it merges what it is handed and never touches the filesystem.

That is a real difference from the game, where the settings layer both reads and merges. Worth writing down here so nobody later tries to "finish the job" by moving file reading in.

**Model building.** Turning a merged record into a `Weapon` or a `Faction` is parsing, and it is genuinely per-type. It stays in the managers — and so this file never imports a viewer model. If it did, a utility every feature depends on would itself depend on every feature.

The pairing of a stats row with its side file, though, moves *in* — pairing is part of deciding who wins, and it lives inside `mergeWeapons` / `mergeShips`.

No behaviour change from step 1 itself. `test/faction_merge_test.dart` keeps passing, updated mechanically for the new entry point. The other entry points arrive unused and get wired up in steps 2 to 4.

## Step 2: loaders stop picking winners

Two separate orderings are involved, and only one of them changes.

**Parse order stays vanilla first.** Ship skin resolution reads `allItemsSoFar` to find base hulls, so vanilla hulls have to be parsed before mod skins reference them. Leave `build()` alone.

**Flatten stops holding a rule.** `_flatten()` drops its hand-rolled `seen` set. It orders its slices with `orderedSources` and merges them with `mergeById`. The base class no longer owns any copy of the rule — it delegates. Six loaders inherit the vanilla fix at once.

For loaders whose `itemId` is source-qualified (factions today; weapons and ships after step 4), every key is unique, so `mergeById` finds nothing to merge during flatten — on purpose. Those loaders do their real merging in a provider afterwards, on raw data. So there are two shapes, and both call the shared file: simple types merge at flatten, side-file types merge in their provider.

Also fix `loadOrderKey` in `lib/models/mod_info.dart:67`. It reads `sortString ?? nameOrId`, but the game treats an empty `sortString` as absent too. Make it fall back when the string is empty as well — `orderedSources` relies on it.

No cache change here. The stored data is per mod and does not change shape — only the order they are read in.

One thing to expect: this will change numbers users have been looking at. Any install with a rebalance mod will suddenly show different weapon and ship stats. That is the point, but it is worth a line in the changelog so it does not read as a regression.

**Steps 2 and 4 land in the same release.** After step 2 alone, a stats-only rebalance mod of vanilla content wins the whole finished weapon — right numbers, missing sprite. Today users get wrong numbers with an intact sprite. The in-between state looks worse than the bug, so it never ships on its own.

## Step 3: descriptions and engine styles

Both are small, independent of steps 2 and 4, and have no cache to invalidate.

**Descriptions** (`lib/descriptions/descriptions_manager.dart`). Today:

```dart
// _composeDescriptions, around line 118 — currently last-wins
final result = <(String, String), DescriptionEntry>{};
if (vanillaEntries != null) result.addAll(vanillaEntries);
for (final variant in variants) { ... result.addAll(entries); }
```

`descriptions.csv` is a CSV, so the game's rule is first-wins. Delete `_composeDescriptions` and call `mergeDescriptions` with sources from `orderedSources`. That fixes the direction and the missing load-order sort in one go — the variant list around line 51 is built straight from `AppState.mods` today, and since the fold is last-wins, that order is what picks the winner.

**Engine styles** (`lib/ship_viewer/engine_styles_manager.dart`). `engine_styles.json` is a config file, so the deep merge applies: vanilla base, last mod wins. The direction is already right and the comment at the top says so. What is wrong is that it replaces each style whole:

```dart
// around line 39
result[entry.key] = EngineStyleSpec.fromJson(value);
```

A mod setting one field of `HIGH_TECH` wipes the rest. Call `mergeEngineStyles` on the raw maps and build `EngineStyleSpec` once at the end. The folder list around line 23 comes from `orderedSources`.

Keep the per-style try/catch that stops one malformed style from dropping the others — move it to where the specs get built.

`ship_roles_manager.dart` swaps its direct deep-merge call for `mergeShipRoles`.

## Step 4: split scanning from merging

This is the real work, and it applies to weapons and ships only. Hullmods, ship systems and wings have no side file, so step 2 finishes them.

Copy the shape the faction loader already uses. It defeats the base class dedup on purpose so nothing is thrown away during the scan:

```dart
// faction_manager.dart:55
String itemId(FactionFileData item) =>
    '${item.sourceSmolId ?? _vanillaSourceKey}|${item.mergeKey}';
```

Then merges afterwards in `mergedFactionListProvider`.

For weapons that means:

- The cached payload holds raw CSV rows and raw `.wpn` maps, each tagged with its source, rather than finished `Weapon` objects.
- `itemId` becomes source-qualified so every mod's copy survives the scan.
- A new provider hands the raw data to `mergeWeapons` and builds `Weapon` objects from the paired records it gets back. The provider decides nothing itself.
- `weaponListNotifierProvider` keeps its current shape — a list of `Weapon` — so nothing downstream changes. Only its insides move.

Ships are the same, plus: stop dropping a CSV row when no `.ship` file exists (`ship_manager.dart:396-402`). Keep the ship with empty geometry and log a warning — the same thing weapons already do for a missing `.wpn`. The game logs a warning ("not found in store") and drops the row, so this is a written-down difference from the game: a viewer should show the broken row, not hide it, and the warning tells the user the ship will be missing in their game too.

Three details decided up front:

- **Side files key on path, not id.** The game enumerates `data/weapons/*.wpn` and merges by relative path, so `homing_laser.wpn` from two mods merge together regardless of what `id` they declare. Keying on id would be subtly different. Match the game.
- **Two paths, same id.** Two different side files can declare the same item id after merging. The game keeps the **first** one it reads and silently ignores the second — its spec store is guarded by a "does this id exist already" check (`WeaponSpecLoader.java:61-64`, `ShipHullSpecLoader.java:430-433`). Its walk visits sources in load order, so between mods the winner is deterministic: the higher-priority mod's file. Only inside one folder is the listing unsorted and the winner chance. Match the game: resolve by source order first, then alphabetical path within one source, and log a warning naming both paths. Only the within-one-source tie-break is TriOS's own, and it is written down in R7.
- **Attribution needs two fields, not one.** A weapon can have its stats from one mod and its sprite from another. `Weapon.modVariant` currently means both. Add a second field for the side file's source and leave `modVariant` meaning the CSV row's source, which is what the game reports and what the Codex groups by.

The payload shape changes, so `schemaVersion` on both notifiers gets bumped. That wipes the cached weapon and ship data and forces a one-time rescan.

## Files

| File | Change |
| --- | --- |
| `lib/utils/game_data_merge.dart` | New. Every merge in the app: `orderedSources`, `mergeById`, `mergeDescriptions`, `mergeWeapons`, `mergeShips`, `mergeFactions`, `mergeEngineStyles`, `mergeShipRoles`. The two rules behind them are private. Never reads from disk, never imports a viewer model. |
| `lib/faction_viewer/faction_merge.dart` | Deleted; its deep merge moves in, with the game's list-replacement rule instead of the fixed name lists. |
| `lib/faction_viewer/faction_manager.dart` | Merge provider calls `mergeFactions`; drop the duplicate colour-key and `core_clearArray` constants. |
| `lib/faction_viewer/spawn_weights/ship_roles_manager.dart` | Calls `mergeShipRoles`. |
| `lib/viewer_cache/cached_stream_list_notifier.dart` | `_flatten()` calls `orderedSources` + `mergeById` instead of its own dedup loop. |
| `lib/models/mod_info.dart` | `loadOrderKey` treats an empty `sortString` as absent. |
| `lib/descriptions/descriptions_manager.dart` | `_composeDescriptions` replaced by `mergeDescriptions`. |
| `lib/ship_viewer/engine_styles_manager.dart` | `mergeEngineStyles` per style instead of whole replace; folder list from `orderedSources`. |
| `lib/weapon_viewer/weapons_manager.dart` | Split scan from merge; resolve via `mergeWeapons`. |
| `lib/weapon_viewer/models/weapons_cache_payload.dart` | Raw rows and side files instead of finished objects. |
| `lib/weapon_viewer/models/weapon.dart` | Second attribution field. |
| `lib/ship_viewer/ship_manager.dart` | Same split via `mergeShips`; stop dropping CSV rows with no `.ship`. |
| `lib/ship_viewer/models/ships_cache_payload.dart` | Same payload change. |
| `openspec/specs/viewer-cache/spec.md` | Its dedup requirement writes down the old behaviour as correct. Update it. |

## Risks

- **Step 4 touches the two biggest loaders.** Ships in particular also carries `.skin` and `.variant` handling, which this change is not meant to disturb. Keep those code paths as they are and only change where their input comes from.
- **Cache wipe on upgrade.** The schema bumps force a full rescan of weapons and ships on the first launch after updating.
- **Widely visible numbers change.** Worth calling out in release notes rather than letting users find it.
- **Steps 2 and 4 are one release.** Shipping step 2 alone breaks sprites for stats-only rebalance mods; the release plan has to treat them as a unit.

## Testing

The Blackrock case that prompted this is the best single test: `Blackrock 0.97 Unofficial Add-on` ships a full `weapon_data.csv` and no `.wpn` files at all, and sorts ahead of `Blackrock Drive Yards`. Under the current code its weapons lose their sprites. Under R4 they keep them.

Unit tests should cover each rule on its own rather than relying on a real mod folder: vanilla losing to a mod, mod ordering staying put, CSV first-wins, side file last-wins, a partial side file keeping unmentioned fields, the list rules (plain lists append, `core_clearArray` wipes first, a 4-entry "color"/"button" list replaces whole, `music_` keys replace whole at any length), two side files claiming the same id (higher-priority mod wins across mods; alphabetically first path wins inside one mod; warning logged either way), a CSV row with no side file anywhere still producing an item, and split attribution (stats from one mod, sprite from another, both named).

## Sources checked

Verified against the decompiled 0.98a-RC8 code: `StarfarerLauncher.java:212-226` (the load-order sort and its empty-`sortString` fallback) and `:240-242` (mods registered into the resource stack in reverse), `LoadingUtils.java:201-284` (CSV merge — first-wins, whole-row, key built from a column list) and `:290-357` (JSON deep merge, with the base picked at `:316-325` by asking which source is *not* a mod) with the list rules at `:365-394`, `WeaponSpreadsheetLoader.java:33` and `WeaponSpecLoader.java:62` (weapons consuming the two paths independently), `WeaponSpecLoader.java:61-64` and `ShipHullSpecLoader.java:430-433` (the duplicate-id guards), `SpecStore.java:1674-1676` (descriptions keyed on `id` + `type`) and `:2208-2220` (source attribution from the winning CSV row).

The class holding the source list and walking folders lives in `fs.common_obf.jar`, which has since been decompiled and read as well (`com.fs.util.C`). It confirms both former inferences. Stack order: mods are pushed onto the *front* of the stack in reverse sorted order, so the first-sorted mod is consulted first and vanilla last. Folder enumeration: sources are visited in stack order and each folder is read with an unsorted directory listing — deterministic between sources, undefined within one folder — which is what the two-paths-same-id rule above now encodes.

Three earlier claims were corrected against the code on a second pass. The game does **not** crash on a CSV row with no side file — `ShipHullSpreadsheetLoader` and `WeaponSpreadsheetLoader` log "not found in store" and skip the row, and the reverse case (a spec with no CSV row) is removed with an error log. Blank-key CSV rows are skipped by the game's merge, not kept. And the JSON list-replacement line has a third clause: keys starting with `music_` replace whole at any length.
