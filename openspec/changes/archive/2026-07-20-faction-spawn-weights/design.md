# Design — Faction Spawn Weights

## How the game computes a ship's spawn weight (traced from decompiled code)

The final weight of one ship loadout, for one faction, in one role list:

1. **Start with the role list entry.** If the faction's `.faction` file has its own `shipRoles` block for that role, use it (merging in the shared defaults when it sets `includeDefault: true`). Otherwise use the merged `default_ship_roles.json`.
2. **Drop it if the faction doesn't know the hull.** `knownShips` lists hulls directly and also by tag (any hull whose `ship_data.csv` tags contain the listed tag counts as known). A `.skin` file's own `tags` array *replaces* the base hull's tags rather than adding to them — `ship_manager.dart` already does this (`skin.tags ?? baseHull.tags`), so `Ship.tags` can be trusted here.
3. **Apply variant overrides.** If the faction's `variantOverrides` names *any* loadout of that hull, then only the named loadouts survive, and the named number *replaces* the weight from step 1.
4. **Multiply by hull frequency.** `hullFrequency` gives per-hull and per-tag multipliers. **These compound.** At load time the game folds each tag multiplier into the per-hull map (`existing (default 1.0) × tagMult`), so a hull with both a per-hull entry and a matching tag entry gets both, and a hull matching several tags gets all of them multiplied together. The result multiplies on top of a `variantOverrides` weight too.

Entries with a final weight of 0 are never picked — the guard is in `WeightedRandomPicker.add()` (weights `<= 0` never enter the picker), not in `pick()`. This is how vanilla itself hides faction-specific loadouts.

Reference: `FleetFactoryV3.addCombatFleetPoints` → `addShips` → `addToFleet` → `Market.pickShipsForRole` → `Faction.pickShip` → `Faction.getAllValidEntries` in the decompiled game code. A Python prototype of this pipeline (validated against a ~200-mod install) lives in the conversation history behind this change; its numbers matched expectations.

Steps the game does that we deliberately skip: a `restrictToVariants` filter, combat-freighter merge-in, and fleet-point-cap pruning. See Known limitations.

### Role fallbacks

A role list can name another role as its `fallback` (and `fallback2`). The game uses the fallback **only when the primary list is empty after all filtering** — it is never blended into a non-empty list. So a faction that knows no small hulls has an empty `combatSmall` and silently picks from its fallback role instead.

We do not follow the chain. But an empty role must not be displayed as "spawns nothing", because that is exactly when the game is spawning something else. When a role resolves to zero entries, the UI says so and names the fallback role: *"This role is empty. The game falls back to `combatMedium`."*

### How mods combine (the merge rules)

When several mods ship the same file path, the game merges them in mod load order: JSON objects merge deeply, arrays append, plain values are last-write-wins. A `"core_clearArray"` first element resets an array. Two exceptions to the append rule: four-element arrays whose key contains `color` or `button`, and keys prefixed `music_`, are replaced wholesale.

A mod can also opt a path out of merging entirely by listing it under **`"replace"`** in its own `mod_info.json`; that mod's copy then replaces everything loaded before it. (`fullOverrides` is only the game's internal name for this list — the JSON key is `replace`.)

Load order is by the optional `sortString` field in `mod_info.json`, falling back to the mod's **display name** when absent, compared with a case-sensitive `String.compareTo` (so uppercase sorts before lowercase).

**What TriOS actually has today.** `lib/faction_viewer/faction_merge.dart` implements the merge *semantics* correctly (deep merge, array append, `core_clearArray`, colour/music replacement). It does **not** give us three things this change needs:

- **Correct ordering.** `resolveEnabledVariants()` returns mods in mods-folder listing order, not load order — nothing in the chain from `AppState.modVariants` down sorts by anything. Harmless for the array-append fields the faction viewer shows today; wrong for spawn weights, where every value is a last-write-wins number and the "which mod did this" attribution depends on who wrote last. Must be fixed first.
- **Scalar attribution.** `_tagItems` only records attribution for *string items inside arrays*. The scalar path is last-write-wins with **no attribution recorded at all**. Role lists, `hullFrequency`, and `variantOverrides` are all maps of `id → number` — plain scalars. Scalar attribution has to be added.
- **`replace` support.** `ModInfo` has no `replace` field, so TriOS cannot see that a mod meant to override rather than merge.

## Data layer

### 1. Keep the spawn-weight sections of `.faction` files

`lib/faction_viewer/faction_manager.dart` already parses and merges every `.faction` file but discards the sections we need. Add to the `Faction` model (`lib/faction_viewer/models/faction.dart`):

- `shipRoles` — `Map<String, dynamic>` (role name → entries, kept raw; small)
- `hullFrequency` — hulls map and tags map
- `variantOverrides` — `Map<String, double>`

Regenerate mappers; bump the faction cache `schemaVersion` (2 → 3) so stale caches rebuild.

### 2. Merge `default_ship_roles.json` across mods

New: `lib/faction_viewer/spawn_weights/ship_roles_manager.dart`. Loads `data/world/factions/default_ship_roles.json` from the game core and every enabled mod, merges with the same rules and mod ordering the faction manager uses, and records, for each role entry, which source last wrote its weight (that source is the "added by" attribution — for a map of plain values the last writer wins, so the last writer owns the entry).

Skip: `fallback` / `fallback2` keys (role chaining — surfaced in the UI when a role is empty, see above) and `includeDefault` (handled at weight-calculation time).

### 2b. Fix `1f` float literals in the JSON parser

These files are lenient JSON with `#` comments and Java-style float literals (`1f`, e.g. vanilla `hegemony.faction:247`). `#` comments are already handled (`removeJsonComments()`). `1f` is **not**, and fails silently:

`jsonDecode` rejects it → `_applyJsonFixups()` leaves it alone → the YAML fallback rescues the file but parses the value as the **string** `"1f"` → `double.tryParse("1f")` returns null → the weight quietly becomes nothing.

Fix in `_applyJsonFixups()` (`lib/utils/extensions.dart`): strip a trailing `f`/`F`/`d`/`D` from a number sitting in a value position — directly after `:`, `[`, or `,`. Anchoring on the delimiter means quoted values (`"version":"1f"`) and text containing `1f` are untouched, because the next character is a quote, not a digit.

Blast radius: `parseJsonToMap()` is shared by every JSON-ish parser in the app, but the fixup pass only runs on files that already failed strict parsing. Files that reach YAML for other reasons are unaffected; files that reach YAML *because of* `1f` now parse correctly and faster. Needs a unit test.

### 3. Weight calculator

New: `lib/faction_viewer/spawn_weights/spawn_weight_calculator.dart`. Pure functions, no I/O:

```
input:  Faction (with new fields), merged role lists + attribution,
        variantId → hullId map, hullId → (tags, name, size) map
output: per role: list of (variantId, hullId, shipName, weight, sourceModName)
```

Implements steps 1–4 above. Needs two lookups that already exist in the app: loadout → hull (`ShipVariant.hullId`, ship viewer) and hull → tags/name/size (`Ship`, ship viewer). Exposed as a Riverpod provider family keyed by faction id, derived from the faction list, ship list, and merged role lists; computed lazily and cached in memory (a few hundred entries per faction — cheap).

**Headline number** ("% vanilla"): sum weights over the eleven combat role lists (`combatSmall/Medium/Large/Capital`, `carrierSmall/Medium/Large`, `phaseSmall/Medium/Large/Capital`), vanilla-attributed weight ÷ total. A hull in several role lists counts once per list; the UI labels the number as "share of spawn weight," not "share of ships."

Entries whose loadout can't be resolved to a hull (mod not installed, code-generated variant) are skipped and counted, so the UI can say "N entries not shown."

## UI layer

Three surfaces, glance → detail:

### Faction card and grid column

- Gallery card: a thin two-segment bar (vanilla vs. mods) with the percentage, under the existing card content.
- Grid view: new sortable column "Vanilla spawn %" in `_buildColumns` (`faction_viewer_page.dart`). Sorting it surfaces the worst-affected faction — the feature's main "spot the problem" move.
- Factions with no combat roles at all (`neutral`, `sleeper`, …) show "—".

### Faction dialog section

In `faction_profile_dialog.dart`, after the Fleet section: the split bar, then the top contributing mods with their share, then a "See all ships" button that opens the detail view for this faction. Reuses the dialog's existing section-title styling.

### Detail view (third view mode)

`FactionViewMode` gains a third value, `spawnWeights`; the toolbar toggle becomes a `ModeSwitcher` (existing widget). The mode shows:

- Faction picker (dropdown) + role picker (segmented or dropdown; default `combatMedium`).
- A table of the chosen list: ship name, size, weight, share %, source mod. Rows group by hull, expandable to the individual loadout entries (users think in ships; the file stores loadouts).
- Row context menu / trailing icon: **"Open file that set this weight"** — resolves the source mod's `default_ship_roles.json` (or the `.faction` file for `shipRoles`/`variantOverrides` entries) and opens it, same helpers the dialog's "Open .faction file" already uses.
- The page's search box filters the table by ship name in this mode.
- A footer note listing known blind spots: ships added by mod code at runtime, combat-freighter mixing, role fallbacks.

## Known limitations (shown to users where relevant)

- Weight share approximates spawn share; the game also filters by remaining fleet points, so expensive ships appear slightly less often than raw weight suggests.
- Mods that add ships via code (`ModPlugin.addKnownShip` etc.) are invisible to file analysis.
- Nexerelin rewrites doctrines at runtime; numbers reflect files on disk.
- The game also applies a `restrictToVariants` filter and mixes in combat freighters; neither is modelled.
- A mod can list a file under `"replace"` in its `mod_info.json` to override rather than merge. TriOS does not read that field yet, so such a mod's file will be shown as merged. Rare, but it would produce wrong numbers silently.

## Files touched

| File | Change |
|---|---|
| `lib/viewer_cache/cached_stream_list_notifier.dart` | sort enabled variants into game load order (see below) |
| `lib/utils/extensions.dart` | `_applyJsonFixups`: handle `1f` float literals |
| `lib/faction_viewer/faction_merge.dart` | record attribution for scalar (last-write-wins) values |
| `lib/faction_viewer/models/faction.dart` (+ mapper) | add `shipRoles`, `hullFrequency`, `variantOverrides` |
| `lib/faction_viewer/faction_manager.dart` | keep new sections; bump `schemaVersion` |
| `lib/faction_viewer/spawn_weights/ship_roles_manager.dart` | new — merge `default_ship_roles.json` + attribution |
| `lib/faction_viewer/spawn_weights/spawn_weight_calculator.dart` | new — weight pipeline + providers |
| `lib/faction_viewer/spawn_weights/spawn_weights_view.dart` | new — detail view |
| `lib/faction_viewer/faction_viewer_controller.dart` (+ mapper) | third `FactionViewMode` |
| `lib/faction_viewer/faction_viewer_page.dart` | mode switcher, grid column, mode body |
| `lib/faction_viewer/widgets/faction_card.dart` | vanilla-share bar |
| `lib/faction_viewer/widgets/faction_profile_dialog.dart` | spawn-weights section |
| `test/spawn_weight_calculator_test.dart` | new — fixture-based tests |

### Note on the load-order fix

`resolveEnabledVariants()` is copy-pasted identically into six managers (ships, weapons, hullmods, fighters, ship systems, factions). The clean fix is a single sorted implementation on the `CachedStreamListNotifier` base class rather than six copies.

Be aware of the blast radius: the base class uses this order to pick the dedup winner when two mods define the same id ("first occurrence wins"). Sorting it will change which mod's ship/weapon/hullmod the other viewers display in that case. That is a bug fix — they currently follow mods-folder listing order, which matches nothing — but it is a visible change beyond factions. If that is unwanted here, scope the sort to the faction manager alone and file the rest separately.
