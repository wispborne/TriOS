# Find images the way the game does

## The problem

The Autopulse Laser shows no image in the Weapons viewer when Emergent Threats is enabled, even though it looks fine in the game.

The cause: when a mod's `.wpn` file names an image, TriOS looks for that image **only inside that mod's folder**. Emergent Threats overrides `autopulse.wpn` just to change a sound, but the copied file still names four image paths — and the mod ships no images. The images exist only in the game core, where TriOS never looks.

The game doesn't work this way. When it needs a file like `graphics/weapons/autopulse_laser_turret_base.png`, it checks **every enabled mod in load order, then the game core**, and uses the first copy that exists. A path in a data file is a request, not a location.

This same wrong assumption ("the mod that named the file also has the file") is baked into several loaders, not just weapons.

### Everywhere it happens

| Data | Where | Broken today when… |
|---|---|---|
| Weapon images (8 layers) | `weapons_manager.dart` | any mod overrides a `.wpn` without shipping the art (the Autopulse bug) |
| Ship images | `ship_manager.dart` (`.ship` files) | any mod overrides a `.ship` without shipping the art |
| Ship skin images | `ship_manager.dart` (`.skin` files) | same, for skins |
| Hullmod icons | `hullmods_manager.dart` | a mod overrides a hullmod row without shipping the icon |
| Loaded-missile sprites | `weapons_manager.dart` (`.proj` files) | a launcher's projectile is defined in another mod (already noted as unhandled in a comment) |

A second effect of the same bug: a **graphics-only mod** (one that ships replacement art but no data files) changes what you see in the game, but TriOS can never show its art, because TriOS only ever looks in the folder of the mod that shipped the data file.

### Already correct or unaffected

- **Faction logos and crests** — `Faction.resolveImageFile` already searches several folders for a file that exists. (Its search order isn't exactly the game's, but it's close and out of scope here.)
- **Fighter wings** — they show their ship hull's image, so fixing ships fixes them.
- **Engine glow sprites** — loaded from fixed game-core paths that always exist.
- **Sounds** — TriOS doesn't load sounds at all.

## The fix

Store image paths the way the data files write them — relative, like `graphics/weapons/autopulse_laser_turret_base.png` — and resolve them to a real file only when building the display models: check each enabled mod in game load order, then the game core, and use the first file that exists. One shared helper does this for every viewer.

## In scope

- A shared "find this game file" helper that searches mods in load order, then the game core, with cached existence checks.
- Weapons, ships, ship skins, hullmod icons, and loaded-missile sprites use it.
- Cache format bumps for ships, weapons, and hullmods (paths stored relative now), causing a one-time rescan.

## Out of scope

- Faction logo/crest resolution (works today; unifying it onto the shared helper can come later).
- Sounds, music, or any non-image file references.
- Showing *which mod* supplied the art in the UI (the "Weapon file:"/"Ship file:" lines keep meaning the data-file winner).
