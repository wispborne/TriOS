# Mod Shield Texture Mapping

The file format mod authors use to tell TriOS which shield textures their ships use, and how TriOS resolves it. This is the part outside mod authors depend on, so it is spelled out fully.

## The file

- Location: `data/config/trios.json` inside a mod folder.
- Parsed with TriOS's lenient game-JSON parser, so `#` and `//` comments and trailing commas are fine.
- The game never reads this file. It exists only for TriOS.
- Top level is a map of sections. Only `shields` is defined. Unknown sections and unknown keys inside entries are ignored, so the format can grow without breaking older TriOS versions or older files.
- There is no version field. New abilities get new keys; old readers skip keys they don't know.

## The `shields` section

```json
{
  "shields": {
    "byHullmod": {
      "kol_shields": {"textureInner": "graphics/kol/fx/kol_shield_fx.png"}
    },
    "byHull": {
      "zea_edf_kiyohime": {
        "textureInner": "graphics/zea/fx/zea_shield_elysia_2.png"
      }
    }
  }
}
```

- `byHullmod` — keys are hullmod ids. An entry applies to any ship whose `.ship` file lists that hullmod in `builtInMods`.
- `byHull` — keys are hull ids. An entry applies to that hull only. Skins have their own hull ids, so a skin can get its own entry.
- Both maps are optional. An empty or missing `shields` section is valid.

## Entries

- `textureInner` — path to the shield fill image, written the way paths appear in game data files (relative to a mod or game folder, forward slashes). Drawn in place of the vanilla `shields64/128c/256.png` fill.
- That is the only key. There is no ring key: the game accepts a ring texture through `ShieldAPI.setRadius` but never draws it, so naming one would change nothing anywhere.
- An entry with no `textureInner` is skipped, the same as no entry at all.
- Paths resolve through the game's file lookup: each mod in load order, then the game core, first hit wins, case-insensitive. A mod can therefore point at another mod's or the game's texture.

## Which entry wins for a ship

1. `byHull` entry for the ship's hull id, if any.
2. Otherwise the first hullmod in the ship's `builtInMods` list that has a `byHullmod` entry.
3. Otherwise no override.

Module ships are looked up the same way, using the module's own hull id and built-in hullmods.

## Merging

Sources are applied in this order, later winning:

1. TriOS's own list, `assets/common/shield_textures.json`, in this exact format.
2. Each mod's `data/config/trios.json`, in load order.

Mod files come from every installed mod, enabled or not, matching how the other shield visuals load. Within the mods, later in load order wins, the same rule as other game data.

So a mod always beats TriOS's list. Three things a mod can do with that:

- **Correct** an entry TriOS ships, by naming the same hullmod or hull with a different texture.
- **Add** hullmods or hulls TriOS doesn't list.
- **Clear** an entry, by writing `"textureInner": ""`. The empty value overwrites TriOS's, then the entry is skipped for being empty, and the ship falls back to the vanilla shield.

## Failure behavior

- A file that fails to parse: warn in the log, ignore that mod's file, keep the others.
- An entry whose texture path resolves to no file, or to a file that won't decode as an image: warn in the log (collapsed, so it doesn't spam), draw the vanilla shield for affected ships.
- A bad file must never blank a shield or break the shield overlay. The overlay always has the current drawing to fall back to.

## Done when

- A Knights of Ludd install with the six-entry mapping file shows the four custom fill textures on the right ships in the ship viewer's shield overlay, including the `zea_shield_elysia_2` texture on `zea_edf_kiyohime` and `zea_edf_ryujin`.
- Ships with no mapping draw exactly as before.
- Deleting or corrupting the file changes nothing except log lines and shields going back to vanilla.
