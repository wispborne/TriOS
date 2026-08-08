# Tasks

- [x] Add `ShieldTextureOverrides` and `shieldTextureOverridesProvider` to `lib/ship_viewer/hull_styles_manager.dart`: read `data/config/trios.json` from every source via `orderedSourcesProvider(false)`, parse leniently, merge the `shields` sections by load order.
- [x] In the same provider, resolve each entry's `textureInner` through `gameFileResolverProvider(false)` and decode with `loadDecodedImage()`; drop bad entries with a collapsed warning.
- [x] Watch the provider in `lib/ship_viewer/widgets/ship_blueprint_view.dart` and stash its value on build, same as `_shieldColors` and `_shieldSprites`.
- [x] In `_shieldPositioned`, pick the fill image per ship: `byHull` by hull id, else first `builtInMods` match in `byHullmod`, else `sprites.fillForRadius(radius)` as today. Applies to modules too, since each `_ShieldRender` carries its own ship.
- [x] Unit tests for merge and lookup: later mod wins, `byHull` beats `byHullmod`, first matching built-in hullmod wins, unknown keys ignored, missing/bad entries fall back cleanly.
- [x] Search every installed mod for shield textures set from code: 3-argument `setRadius` in shipped source, and in the compiled classes of all 411 jars. Filter to hullmods actually built into hulls, and to textures applied at ship creation rather than mid-combat.
- [x] Build TriOS's own list at `assets/common/shield_textures.json`, in the mod file format, covering 16 mods. Verify all 28 texture paths resolve against the real installs.
- [x] Load the built-in list in the provider as the first source, so mods override, add to, and clear it.
- [x] Tests for the shipped list and for built-in versus mod file precedence.
- [ ] Manual check in the app: Knights of Ludd, Tahlan Shipworks and VIC hulls show their shield textures with no mod-side file present; vanilla ships unchanged.
- [ ] Draft the format note for mod authors: that TriOS already ships support, how to override it with `data/config/trios.json`, and the finding that the game ignores the ring texture passed to `setRadius`. Get the user's sign-off on the wording before sending.
  - Drafted in `format-note.md`. Waiting on sign-off.
- [x] Add a `changelog.md` entry.
- [x] Check how the game draws the ring texture before honoring `textureRing`. It never draws it: the renderer binds it only in unreachable code, and always uses `line8x8.png`, which is what TriOS already does. Dropped the ring key from the format and the code.
