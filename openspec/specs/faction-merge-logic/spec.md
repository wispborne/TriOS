# Faction Merge Logic

## Overview

Replicates Starsector's faction file merge behavior so the viewer shows the same data a player would see in-game.

## Requirements

### R1: Load order

- Vanilla faction files are loaded first from `{gameCoreFolder}/data/world/factions/`.
- Mod faction files are loaded in mod list order from `{modFolder}/data/world/factions/`.
- Each faction ID produces one merged `Faction` object.
- Files are scanned and cached raw, one entry per file per source. Merging happens afterwards, on demand, so the same scan can produce different merges (see R6).

### R2: Merge rules

Match the game's merge semantics (from `LoadingUtils`):

| Data type | Rule |
|---|---|
| Arrays (knownShips.hulls, knownWeapons.weapons, portraits.standard_male, etc.) | Additive -- append mod entries to existing array |
| Arrays prefixed with `"core_clearArray"` | Clear the array, then add remaining entries |
| Color arrays, music values | Replace entirely (not additive) |
| Scalar values (displayName, color, doctrine numbers, flags) | Last-write-wins -- mod value replaces base |
| Nested objects (factionDoctrine, custom, hullFrequency) | Recursive merge -- descend and apply array/scalar rules per field |

### R3: Per-section attribution

For each array field that participates in merging, track the count of items contributed by each source:

```
SectionAttribution {
  field: String           // e.g. "knownShips.hulls"
  contributions: [
    { source: "Vanilla", count: 32 },
    { source: "Nexerelin", count: 8 },
  ]
}
```

Scalar overrides are attributed to the last source that set them.

### R4: Per-item attribution

For each array field, track exactly which source added each individual item:

```
ItemAttribution {
  field: String           // e.g. "knownShips.hulls"
  items: {
    "onslaught": "Vanilla",
    "atlas": "Vanilla",
    "custom_ship": "ModName",
  }
}
```

When `core_clearArray` is present, all previous item attributions for that field are cleared before tagging the new items. If the same item ID appears from multiple sources, the last source wins.

### R5: Source tracking

Each `Faction` object tracks its list of contributing sources (vanilla and/or mod names), ordered by load sequence.

### R6: Only enabled mods

The merge takes an "only enabled mods" flag. When it is on:

- Files from mods without an enabled variant are left out before merging, so their ships, weapons, doctrine numbers, and spawn weights never reach the result.
- Vanilla files are always included.
- A faction disappears if the only sources listing it in `factions.csv` were left out — a faction added by a disabled mod isn't in the game either.
- A faction file that *no* source lists in `factions.csv` is kept, since its owner is unknown rather than known to be disabled.

The same rule applies to `default_ship_roles.json`, which feeds spawn weights.

When the flag is off, the result is identical to merging every installed mod.

## Acceptance criteria

- Given vanilla Hegemony with 32 known ships, and a mod adding 8 more, the merged faction has 40 known ships with attribution "Vanilla: 32, ModName: 8".
- Given two mods both setting `doctrine.aggression`, the second mod's value wins.
- Given a mod with `"core_clearArray"` in a knownShips array, the vanilla entries are wiped before the mod's entries are added.
- Factions defined only by a mod (no vanilla counterpart) appear with a single source.
- Given vanilla Hegemony with ships ["onslaught", "dominator"] and a mod adding ["custom_ship"], `itemAttributions["knownShips.hulls"]` maps onslaught/dominator → "Vanilla" and custom_ship → "ModName".
- Given `core_clearArray` in a mod's ship list, all previous item attributions for that field are cleared and only the mod's items remain attributed.
- Given vanilla Hegemony with `doctrine.aggression: 3` and a *disabled* mod setting it to 5, the merged faction has aggression 5 with the flag off and 3 with the flag on.
- Given a faction added only by a disabled mod, it is listed with the flag off and absent with the flag on.
