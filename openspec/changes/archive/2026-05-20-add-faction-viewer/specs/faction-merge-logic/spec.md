# Faction Merge Logic

## Overview

Replicates Starsector's faction file merge behavior so the viewer shows the same data a player would see in-game.

## Requirements

### R1: Load order

- Vanilla faction files are loaded first from `{gameCoreFolder}/data/world/factions/`.
- Mod faction files are loaded in mod list order from `{modFolder}/data/world/factions/`.
- Each faction ID produces one merged `Faction` object.

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

## Acceptance criteria

- Given vanilla Hegemony with 32 known ships, and a mod adding 8 more, the merged faction has 40 known ships with attribution "Vanilla: 32, ModName: 8".
- Given two mods both setting `doctrine.aggression`, the second mod's value wins.
- Given a mod with `"core_clearArray"` in a knownShips array, the vanilla entries are wiped before the mod's entries are added.
- Factions defined only by a mod (no vanilla counterpart) appear with a single source.
- Given vanilla Hegemony with ships ["onslaught", "dominator"] and a mod adding ["custom_ship"], `itemAttributions["knownShips.hulls"]` maps onslaught/dominator → "Vanilla" and custom_ship → "ModName".
- Given `core_clearArray` in a mod's ship list, all previous item attributions for that field are cleared and only the mod's items remain attributed.
