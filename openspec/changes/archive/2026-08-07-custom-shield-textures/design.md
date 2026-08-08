# Design

## Approach

Follow the existing shield-visuals pattern in `lib/ship_viewer/hull_styles_manager.dart`. That file already has two providers the blueprint view reads each build: `hullStyleShieldColorsProvider` (reads `data/config/hull_styles.json` from every mod and merges it) and `shieldSpritesProvider` (decodes the vanilla shield textures through the game file lookup). This change adds a third provider in the same file that reads `data/config/trios.json`, and a lookup in the blueprint view that swaps the fill image per ship.

## Data flow

1. **Read and merge.** New provider `shieldTextureOverridesProvider` in `hull_styles_manager.dart`. It first loads TriOS's own list from `assets/common/shield_textures.json` via `rootBundle` and puts it at the front of the source list, so `_deepMerge` applies it before any mod and every mod wins over it. A failure to read the asset is logged and skipped, leaving mod files to work on their own. Then the same loop as `hullStyleShieldColorsProvider`: walk `orderedSourcesProvider(false)` (every installed mod, enabled or not, plus the game core), read `data/config/trios.json` where it exists, parse with `parseJsonToMap()`, log and skip files that fail. Merge the `shields` sections across sources with the same JSON merge used for `hull_styles.json` (load order, later mod wins, vanilla loses). In practice two mods almost never define the same entry, so the fine points of field-level vs entry-level merging don't matter; reusing the existing merge means no new merge code.

2. **Resolve and decode.** For each entry in the merged `byHullmod` and `byHull` maps, resolve `textureInner` through `gameFileResolverProvider(false)` and decode with `loadDecodedImage()` (`lib/ship_viewer/utils/sprite_utils.dart`), which already caches by path. Entries whose path doesn't resolve or doesn't decode are dropped with a collapsed warning (`LogCollapser`).

   The provider's value is two maps of id to decoded image, wrapped in a small class so the blueprint view gets ready-to-draw `ui.Image`s and never awaits during paint:

   ```dart
   class ShieldTextureImages {
     final ShieldTextureOverridePaths paths;   // ids -> texture path
     final Map<String, ui.Image> fillsByPath;  // texture path -> image
   }
   ```

   Texture counts are tiny (Knights of Ludd: 5 distinct images), so decoding everything up front is fine.

3. **Look up per ship.** In `_shieldPositioned` in `lib/ship_viewer/widgets/ship_blueprint_view.dart`, before falling back to `sprites.fillForRadius(radius)`:
   - `byHull[ship.hullId]` if present,
   - else the first id in `ship.builtInMods` that has a `byHullmod` entry,
   - else the vanilla fill as today.

   This runs per `_ShieldRender`, so modules get their own lookup with their own hull id and built-in hullmods — a station module with its own shield style draws correctly.

The blueprint view already watches the two shield providers and stashes their values in fields on build (`_shieldColors`, `_shieldSprites`); the overrides follow the same pattern with a `_shieldTextureOverrides` field.

## Key decisions

- **Keyed by hullmod id first, hull id for exceptions.** Knights of Ludd assigns textures through built-in hullmods, and `.ship` files already list those in `builtInMods`, which TriOS already parses (`Ship.builtInMods`, `lib/ship_viewer/models/ship.dart`). Keying by hullmod means four entries instead of thirty-two. `byHull` covers the conformal-shield exception and any mod that sets textures from a ship script instead of a hullmod. `byHull` wins because it is the more specific statement.
- **No version field.** New keys can be added without one; readers ignore unknown keys. If a breaking change is ever needed, a version key can be introduced then, with its absence meaning version 1.
- **No ring key at all.** The game's shield renderer binds the ring texture from `setRadius` only inside `if (var8 == 2)`, in a loop bounded by `var8 < 2` (`G.java` lines 318-326). That line never runs. The ring is always `graphics/hud/line8x8.png`, bound once in the constructor, which is exactly what TriOS's `_paintRing` already does, down to the 3/4/5 thickness per hull size. The game's own `shields64ring.png`, `shields128ringc.png` and `shields256ringd.png` are unused leftovers. A ring key would be a value no renderer anywhere reads, so mod authors shouldn't be asked to write one.
- **Decode in the provider, not in paint.** The painter is synchronous; images must be ready before drawing. Pre-decoding a handful of images is cheap and reuses the existing path-keyed cache.
- **Generic filename (`trios.json`), sectioned.** One filename for mod authors to learn. Future mod-supplied data gets a new section in the same file.
- **TriOS's own list is written in the mod file format and merged as an ordinary source.** No second parser, no second code path, and the shipped list doubles as the worked example for mod authors. Making it the first source gets override, add and clear behaviour out of the existing merge with no new logic.
- **Per-hull entries where a mod picks textures by radius.** VIC's `vic_dynamicshields` and Neoteric's `highshield7s` choose between three textures at radius 256 and 128. Since the shipped list is generated rather than hand-maintained, listing their hulls one by one with each hull's own `shieldRadius` applied is exact and needs no format change. Cost is that a hull whose radius changes in a later mod version keeps the old texture until the list is regenerated — visually wrong at worst.
- **Only textures applied unconditionally at ship creation are listed.** Anything a mod swaps in when an ability fires describes a moment, not a ship. Verified per class by reading each mod's source where shipped, and the compiled class otherwise.

## Files that change

- `assets/common/shield_textures.json` — new. TriOS's built-in list. `assets/common/` is already declared in `pubspec.yaml`, so no build config change.
- `lib/ship_viewer/hull_styles_manager.dart` — add `ShieldTextureOverridePaths`, `ShieldTextureImages` and `shieldTextureOverridesProvider` (load asset, parse, merge, resolve, decode).
- `lib/ship_viewer/widgets/ship_blueprint_view.dart` — watch the new provider; per-ship lookup in `_shieldPositioned`; pass the override image as `fillImage`.
- `test/` — new test file for parse, merge, and lookup rules.
- `changelog.md` — user-facing entry.

No model or `.mapper.dart` changes: the merged JSON is read directly, same as the hull styles provider, so no codegen run is needed.

## Testing

- Unit tests on the parse/merge/lookup logic with hand-built JSON: entry wins by load order, `byHull` beats `byHullmod`, first matching built-in hullmod wins, unknown keys ignored, bad entries dropped.
- Tests over the shipped list itself, so a typo in it fails the build rather than silently breaking shields: it parses, every path looks like a game data path, and the Knights of Ludd and VIC entries are the expected ones.
- Tests over built-in versus mod file: a mod replaces, adds, and clears an entry.
- Every path in the shipped list checked against the real mod installs — all 28 resolve.
- Manual check in the app: Knights of Ludd, Tahlan and VIC hulls show their textures with no mod-side file present, and vanilla ships are unchanged.
