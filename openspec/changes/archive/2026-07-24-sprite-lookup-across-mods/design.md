# Design

## The rule being copied

From the game's source stack (`com.fs.util.C`, `StarfarerLauncher`): a file path in a data file is resolved against every source — enabled mods first, in load order (alphabetically first mod asked first), the game core last — and the first source that actually has the file wins.

TriOS already applies this order for *data* (`orderedSources` in `game_data_merge.dart`). This change applies the same order to *files on disk*.

The key split, which is exactly the game's: the **path string** comes from the merged data file (the last-applied mod wins the field), but the **file bytes** come from whichever source actually has that path. Two different mods can legitimately win those two questions.

## New piece: `GameFileResolver`, fed by a shared image index

Checking the disk for each path at build time was considered and rejected: the build step blocks the UI thread and re-runs on every mod toggle, and the number of disk checks grows with the number of enabled mods — visible, repeated stutter on big mod lists.

Instead a **new scan of its own** records, per source, **which image files that source ships**:

- `lib/viewer_cache/graphics_index_manager.dart`, cache domain `graphics_index`, built on the same `CachedStreamListNotifier` machinery as ships and weapons, so it is async, cached to disk per mod, and pruned the same way.
- Only files under `graphics/`, only image extensions (`.png`, `.jpg`, `.jpeg`) — skips fonts, sounds and stray files.
- Stored as a flat list of forward-slash relative paths **as written on disk**. Each payload builds a lowercased-path → on-disk-path map on first use, so lookups can ignore case without breaking case-sensitive file systems.
- Size: vanilla a few hundred KB, a typical mod tens of KB — a few MB at most even with 100+ mods, and small next to the parsed `.ship`/`.wpn` JSON the viewer caches already hold.

Its own scan rather than riding along inside the ships and weapons payloads (the first sketch): that would walk every mod's `graphics/` folder twice and store two identical copies, and hullmods — which have no side-file scan of their own — would have had to reach into the weapons scan to borrow one. One scan, one copy, and every viewer (plus faction logos later) reads the same thing.

`GameFileResolver` (`lib/utils/game_file_resolver.dart`) then just looks things up:

- Built from the sources in `orderedSources` order (mods first, game core last), each paired with its file map and folder.
- `String? resolve(String? relativePath)` — the first source whose map holds the path wins; returns the absolute path under that source's folder, or null when no source has it. Answers are memoised per resolver.
- Fallback: a path outside `graphics/` (rare, but legal) is checked directly on disk per source instead. A handful per build at most.
- One resolver per build pass. **The build never reads the disk** apart from that fallback — re-merges on mod toggles stay instant.

It does **not** go in `game_data_merge.dart` — that file's contract says it never reads from disk, and the fallback probe does.

### Graphics-only mods now count

A mod that ships only replacement art (no rows, no data files) changes what the game shows, and with the index TriOS can finally show it too. A separate index scan gets this for free: such a mod produces a `graphics_index` payload even though the ships and weapons scans rightly discard it.

## What changes where

### Scan time: store paths as written

- **Weapons** (`weapons_manager.dart`): `_resolveSpritePath` stops joining to the mod folder; the eight sprite fields keep their raw relative values in the payload.
- **Ships** (`ship_manager.dart`): stop precomputing `spriteFile` from `spriteName` for `.ship` files; same for `.skin` files' `_spriteFile`.
- **Hullmods** (`hullmods_manager.dart`): the `sprite` column keeps its raw relative value in the cached model. Hullmods have no merge/build step to hook — the notifier's list is the finished list — so the two places that draw an icon resolve the path themselves.
- **Missile specs** (`weapons_manager.dart`): the `.proj` index (id → sprite/size/center) moves into the payload per source, with the sprite kept relative.

### Build time: resolve through the stack

Each manager builds one `GameFileResolver` from the same source list it merges with, then resolves every image field after the merge:

- **Weapons**: the eight sprite layers of the merged `.wpn`, plus the loaded-missile sprite. The missile's projectile id is now looked up across every source's `.proj` index in load order, not just the declaring mod's — fixing the cross-mod case the old comment declared unhandled.
- **Ships**: the merged `.ship`'s `spriteName` → `Ship.spriteFile`; same for skins.
- **Hullmods**: resolved at the two icon widgets (the grid column and the codex card).

Runtime model shapes don't change — `Ship.spriteFile`, the `Weapon` sprite fields, and `Hullmod.sprite` still hold absolute paths (or null) at runtime, so no UI code changes.

A path that exists nowhere resolves to null, which every viewer already treats as "no image."

### UI cleanups the index pays for

- The ship dialog's "Open Folder" button (`_getPathForSpriteName` in `ship_details_dialog.dart`) joins `spriteName` to the stats-winner's mod folder — the same wrong assumption. It should open the resolved `spriteFile`'s folder instead.
- The weapon dialog's existence-check machinery (`_getWeaponImagePath`, `_weaponImagePathCache`, the per-sprite `FutureBuilder`) exists because stored paths might not exist. Resolved paths are guaranteed to exist, so this collapses into a plain `Image.file`.
- Optional follow-up: `Faction.resolveImageFile` does `existsSync` per source at display time, inside widget builds. Pointing it at the same index removes that I/O and makes its search order game-accurate. Fine to defer.

## Cache bumps

Payloads stored before this change hold absolute paths, so they're unreadable in the new scheme:

- ships: `schemaVersion` 2 → 3
- weapons: `schemaVersion` 2 → 3
- hullmods: `schemaVersion` 1 → 2
- graphics index: new domain, starts at 1

Each causes a one-time rescan (seconds).

## Testing

- Unit tests for `GameFileResolver` against in-memory file sets: mod-beats-core order, first-mod-wins order, missing-everywhere → null, outside-`graphics/` fallback (this one with temp folders).
- The Autopulse shape as a merge-level test: mod wins the `.wpn`, only vanilla has the image → image resolves to vanilla's copy.
- Existing ships/weapons merge tests updated where they assert pre-joined absolute sprite paths.
