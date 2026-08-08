# Custom Shield Textures

## Problem

Some mods replace the game's shield textures from Java code. The game's `ShieldAPI.setRadius(radius, textureInner, textureRing)` swaps the shield fill and ring images at runtime. Nothing on disk records which ship gets which texture, so TriOS draws those ships with the vanilla shield textures.

Knights of Ludd is the concrete case. It has four hullmods that each set a custom shield texture (`kol_shields`, `zea_dawn_shield_style`, `zea_dusk_shield_style`, `zea_edf_shield_style`), covering 32 hulls. One of them (`ElysianShieldStyle`) picks a different texture when the ship also has the `zea_conformal_shield` hullmod. The author is willing to ship a mapping file with the mod so TriOS can show the right textures.

## Solution

Two halves that use the same format.

TriOS ships its own list, `assets/common/shield_textures.json`, covering the mods already installed and checked. That means shield textures work out of the box with no cooperation from mod authors.

A mod can also ship `data/config/trios.json` in the same format. The game never reads it. It is applied over TriOS's list, so a mod can correct a stale entry, add hullmods TriOS doesn't know, or clear an entry by writing an empty `textureInner`.

Both go through one parser and one merge. TriOS's list is just the lowest-priority source.

A search of all 452 installed mod folders — source where shipped, compiled classes in all 411 jars otherwise — found 17 mods that set shield textures this way. 16 are in the shipped list; the exclusions are explained below.

## In scope

- TriOS's own shield texture list, shipped as an asset, applied before any mod's file.
- Read and merge `data/config/trios.json` from every mod folder.
- The `shields` section: `byHullmod` and `byHull` maps, each entry naming a `textureInner` path.
- Drawing the mapped inner (fill) texture in the ship viewer's shield overlay, for the parent hull and for modules.
- Falling back to the current drawing on any missing or bad entry, with a logged warning.
- A short format note the user can send to the Knights of Ludd author.

## Out of scope

- The ring texture, entirely. `ShieldAPI.setRadius` takes one, but the game never draws it: the shield renderer binds the ring texture only inside `if (var8 == 2)` in a loop bounded by `var8 < 2`, so that line never runs (`com/fs/starfarer/combat/systems/G.java`, lines 318-326). The ring is always `graphics/hud/line8x8.png`, loaded once in the shield's constructor. TriOS already draws the ring the same way, with the same 3/4/5 thickness for fighter/frigate/everything else, so its ring already matches the game. The mapping file has no ring key, because a mod's ring texture changes nothing in the game either.
- Shield colors and rotation rates in the mapping file. Knights of Ludd doesn't set them. Unknown keys are ignored, so they can be added later without breaking published files.
- Any other section in `trios.json`. The file is named generically so future mod-supplied data can live in it, but only `shields` is defined here.
- Per-radius texture sets. VIC and Rumours of Neoteric Designs pick one of three textures from the shield's radius. Rather than add a second shape for `textureInner`, their hulls are listed one by one in the shipped list with the texture their own radius selects. If a mod author asks for it later, a radius-keyed form can be added without breaking files written today.
- Textures a mod swaps in mid-combat. Diable Avionics (Fortress Shield), VIC's Adaptive Assault and Gensoukyou Manufacture all change the texture when an ability fires. The file describes a ship sitting still, so those are left out. Gensoukyou's resting texture is vanilla `shields256.png` anyway.
- Hullmods players install themselves. `vic_shieldsChanger` and `vic_deathProtocol` are on no hull's `builtInMods`, so they are not part of any hull as the viewer shows it.
- Xhan Empire. Its `XHAN_PsyShield` class sets a texture but is named by no `hull_mods.csv` row, so there is no way to tie it to hulls.
- `sb_KnightRefitPhase` from zz Tahlan Additions. Its jar carries Tahlan's `KnightRefit` class but the csv names a different script, and it covers one hull, so it was left out rather than guessed at.
