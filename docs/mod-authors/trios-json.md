# TriOS settings for mods

A mod can include `data/config/trios.json` to give TriOS information that is
not available in normal Starsector data files. Starsector does not read this
file. It has no effect on the game or on players who do not use TriOS.

TriOS currently uses this file for custom shield textures. Mods often set
these textures from Java with `ShieldAPI.setRadius()`. TriOS cannot find that
texture choice by reading the mod's normal data files.

## File format

Create this file inside your mod:

```text
your-mod/
  data/
    config/
      trios.json
```

The file uses the same relaxed JSON format as Starsector data files. You can
use `#` comments, `//` comments, and trailing commas.

This example assigns one texture by built-in hullmod and another texture to a
specific hull:

```json
{
  "shields": {
    "byHullmod": {
      "example_shield_style": {
        "textureInner": "graphics/example/fx/example_shield.png"
      }
    },
    "byHull": {
      "example_special_hull": {
        "textureInner": "graphics/example/fx/example_special_shield.png"
      }
    }
  }
}
```

Both `byHullmod` and `byHull` are optional.

## Shield settings

The keys under `byHullmod` are hullmod IDs. The texture applies to every ship
whose `.ship` file lists that hullmod in `builtInMods`. Use this when several
ships use the same shield code.

The keys under `byHull` are hull IDs. The texture applies only to that hull.
Skins have their own hull IDs, so you can give a skin its own entry. A
`byHull` entry takes priority over a `byHullmod` entry on the same ship.

Each entry supports one setting:

- `textureInner` is the path to the shield fill image. Write it like a path in
  a Starsector data file. Use forward slashes and make the path relative to a
  mod folder or the Starsector folder.

If a ship has more than one matching built-in hullmod, the first matching ID
in its `builtInMods` list is used. Ship modules use their own hull ID and
built-in hullmods.

TriOS resolves texture paths in mod load order and then checks the Starsector
core files. This matches the game's file lookup. A path can point to a file
provided by another mod, but that mod must be installed for the texture to
load.

## Replacing TriOS defaults

TriOS includes shield settings for several existing mods. A mod's own
`trios.json` takes priority over TriOS's included settings. You can add a new
entry or correct an existing one.

Set `textureInner` to an empty string to remove an included setting:

```json
{
  "shields": {
    "byHullmod": {
      "example_shield_style": {
        "textureInner": "",
      },
    },
  },
}
```

The affected ships will use TriOS's normal shield texture.

TriOS reads this file from every installed mod, including disabled mods. If
more than one mod defines the same entry, the later mod in load order takes
priority.

## Limits

This setting describes the shield texture used while viewing a ship. It cannot
describe a texture that changes during combat or in response to an ability.

There is no setting for the shield ring texture. Starsector accepts a ring
texture in `ShieldAPI.setRadius()`, but the game does not draw that texture.

Shield colors and rotation rates are not supported by `trios.json`.

TriOS ignores sections and settings it does not know. This lets future TriOS
versions add settings without breaking older files.

If the file cannot be parsed, TriOS logs the error and ignores that file. If a
texture is missing or cannot be read, TriOS logs the problem and uses its
normal shield texture. A bad setting does not prevent the ship from being
shown.
