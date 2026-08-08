# Draft note for mod authors

Not sent. Needs the user's sign-off on wording first.

Written for the Knights of Ludd author, but the middle section applies to any of
the 16 mods in TriOS's list.

---

TriOS's ship viewer now draws custom shield textures — the ones set from Java
with `ShieldAPI.setRadius`, which don't appear anywhere in a mod's files.

**Knights of Ludd already works, you don't need to do anything.** TriOS ships a
list of the mods it knows about, and yours is in it: `kol_shields`,
`zea_dawn_shield_style`, `zea_dusk_shield_style` and `zea_edf_shield_style`,
plus the two hulls where `ElysianShieldStyle` swaps to the conformal texture
(`zea_edf_kiyohime` and `zea_edf_ryujin`).

That list is only as current as the version I read, so if you'd rather own it
than have me guess at it, you can. Drop a file at `data/config/trios.json` in
your mod. The game never reads it. It's applied over TriOS's list, so it wins.

```json
{
	"shields": {
		"byHullmod": {
			"kol_shields": {
				"textureInner": "graphics/kol/fx/kol_shield_fx.png",
			},
			"zea_dawn_shield_style": {
				"textureInner": "graphics/zea/fx/zea_shield_dawn.png",
			},
			"zea_dusk_shield_style": {
				"textureInner": "graphics/zea/fx/zea_shield_dusk.png",
			},
			"zea_edf_shield_style": {
				"textureInner": "graphics/zea/fx/zea_shield_elysia.png",
			},
		},
		"byHull": {
			"zea_edf_kiyohime": {
				"textureInner": "graphics/zea/fx/zea_shield_elysia_2.png",
			},
			"zea_edf_ryujin": {
				"textureInner": "graphics/zea/fx/zea_shield_elysia_2.png",
			},
		},
	},
}
```

How the rules work:

- `byHullmod` keys are hullmod ids. An entry applies to every ship with that
  hullmod in its `builtInMods`, so you don't list hulls one by one.
- `byHull` keys are hull ids, including skins. Use these for exceptions. A hull
  entry beats a hullmod entry.
- Your file beats TriOS's list, so you can correct an entry, add hullmods TriOS
  doesn't know about, or write `"textureInner": ""` to remove one and put that
  ship back to the vanilla shield.
- Paths are written the same way as in any game data file. TriOS looks them up
  the way the game does, so you can point at another mod's or the game's file.
- Comments and trailing commas are fine, same as the game's own JSON files.
- Keys TriOS doesn't know are ignored, so the format can grow later without
  breaking your file.

Two things that came up while working this out, which you may not know:

- **The game ignores the ring texture you pass it.** In
  `setRadius(radius, inner, ring)` the ring texture is stored, but the renderer
  only binds it inside `if (var8 == 2)` in a loop that runs `var8` as 0 and 1,
  so that line never executes. The ring is always drawn with
  `graphics/hud/line8x8.png`, loaded once when the shield is created. The game's
  own `shields64ring.png` / `shields128ringc.png` / `shields256ringd.png` look
  like leftovers from before that. So passing your texture as both arguments
  does the same thing as passing it as the first one only, and there's no ring
  key in this format. You're not the only mod doing this — a few others pass
  ring textures that never show up either.
- **Textures swapped mid-combat aren't covered.** The file describes a ship
  sitting still. A texture your code applies when an ability fires can't be
  described here.

Shield colors and rotation rates aren't in the format yet, and neither is naming
three textures picked by shield radius the way VIC does. Say the word if you
want either.

If the file is missing, malformed, or names a texture that isn't there, TriOS
logs it and draws the normal shield. Nothing breaks.
