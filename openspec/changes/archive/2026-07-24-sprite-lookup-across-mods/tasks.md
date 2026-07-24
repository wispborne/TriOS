# Tasks

- [x] Write `GameFileResolver` in `lib/utils/game_file_resolver.dart`: ordered sources with per-source file maps in, first source that has the path wins; direct disk-check fallback for paths outside `graphics/`.
- [x] Unit-test the resolver: load-order wins, core as fallback, missing everywhere → null, outside-`graphics/` fallback.
- [x] Write the shared image index: `lib/viewer_cache/graphics_index_manager.dart`, cache domain `graphics_index`, one payload per source listing its `graphics/` image files, plus a provider that hands out a built `GameFileResolver`.
- [x] Weapons: store the eight sprite fields relative in the payload; bump the weapons cache `schemaVersion` to 3.
- [x] Weapons: resolve the merged sprite fields through the resolver in `_buildWeapons`.
- [x] Weapons: move the `.proj` missile index into the payload (relative sprite paths), look projectile ids up across all sources in load order at build time, and resolve the missile sprite through the resolver.
- [x] Ships: store `spriteName` only (no precomputed `spriteFile`) for `.ship` and `.skin` files; bump the ships cache `schemaVersion` to 3.
- [x] Ships: resolve `spriteName` → `Ship.spriteFile` through the resolver in `_buildShips` and `_resolveSkins`.
- [x] Fix the ship dialog's "Open Folder" button to use the resolved `spriteFile`'s folder instead of joining `spriteName` to the stats-winner's mod folder.
- [x] Weapon dialog: remove the existence-check machinery (`_getWeaponImagePath`, `_weaponImagePathCache`, the per-sprite `FutureBuilder`) — resolved paths are guaranteed to exist.
- [x] Hullmods: keep the `sprite` column relative in the cache and bump the hullmods cache `schemaVersion` to 2; resolve the path at the two icon widgets (grid column, codex card).
- [x] Add a merge-level test for the Autopulse shape: a mod wins the `.wpn` but only vanilla has the image, and the image still resolves.
- [x] Add a test for a graphics-only mod: no data files, ships only art, and its art wins for a vanilla ship.
- [x] Update existing ships/weapons merge tests that assert absolute sprite paths.
- [x] Run `flutter analyze` and the full test suite.
- [x] Add a changelog entry under Fixed.
- [ ] Manual check by the user: Autopulse Laser shows its image with Emergent Threats enabled; a Blackrock ship and a hullmod icon still show correctly after the rescan; toggling a mod re-merges without stutter.
