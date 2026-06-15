## Why

The VRAM estimator's `ReferencedAssetsSelector` reads `data/config/settings.json`'s `graphics` block but ignores the rest of `data/config/`. Starsector mods routinely place sprite references in other config JSONs — `custom_entities.json` (icons, interaction images, sprites), `planets.json` (textures, halos, atmosphere sprites, map icons), `engine_styles.json` (glow/flame sprites), `hull_styles.json` (damage decal sheets), and mod-specific files under `data/config/**/`. Without a parser for these, the reference selector misses many legitimately-used images and they fall into the "unreferenced" bucket, undermining the selector's accuracy for large content mods like Random Assortment of Things.

## What Changes

- Add a new `DataConfigJsonReferences` parser that walks every `.json` file under `data/config/**/` (including nested subdirectories like `exerelinFactionConfig/`, `paintjobs/`, `modFiles/`) except the already-handled `data/config/settings.json`, and extracts every string value that looks like an image path.
- Register the parser in `referenced_assets_selector.dart`'s `_allParsers` list and in `ReferencedAssetsSelectorConfig.allEnabled` so it is on by default.
- Use a tolerant two-phase extractor:
  1. Strip `//`, `/* */`, and `#` comments, then attempt `json.decode`. Walk the tree and collect every string node.
  2. On parse failure (Starsector's permissive JSON format sometimes breaks strict parsers — trailing commas, unquoted keys in a subset of files), fall back to a quoted-string regex extractor that harvests every `"…"` literal from the comment-stripped text.
- Filter collected strings to those that look like asset paths: the value has a known image extension (`.png/.jpg/.jpeg/.gif/.webp`) **or** starts with `graphics/`. This keeps precision high and avoids treating arbitrary ids, faction tags, or plugin class names as paths.
- Add a new opt-in parameter to `_json_utils.stripJsonComments` (e.g. `stripHashLineComments`, default `false`) so `#` line comments can be stripped without changing behavior for any existing caller. Only the new `DataConfigJsonReferences` parser passes `true`; every other parser keeps today's exact call and output.
- Add a unit test fixture directory with trimmed copies of representative config files (custom entities, planets, engine styles, hull styles) that asserts the parser extracts the expected paths and ignores non-path strings.

## Capabilities

### New Capabilities
<!-- None — this extends an in-flight capability. -->

### Modified Capabilities
- `vram-estimator`: Adds a new reference parser source that covers `data/config/**/*.json` beyond `settings.json`. Builds on the `pluggable-vram-selectors` change (which introduces the `vram-estimator` spec); if that change has not yet been archived when this one is applied, the two should land together.

## Impact

- **Affected code**
  - New file: `lib/vram_estimator/selectors/references/data_config_json_references.dart` — parser implementation.
  - `lib/vram_estimator/selectors/references/_json_utils.dart` — extend `stripJsonComments` to handle `#` line comments.
  - `lib/vram_estimator/selectors/referenced_assets_selector.dart` — register the new parser in `_allParsers`.
  - `lib/vram_estimator/selectors/referenced_assets_selector_config.dart` — add the new parser id to `allEnabled`.
  - `test/vram_estimator/` — new test file and fixtures for the parser and the updated comment-stripper.
- **APIs / contracts**
  - No public API changes. Settings continue to round-trip: existing persisted configs that omit the new parser id will enable it on load via the `allEnabled` default.
- **Dependencies**
  - None. Uses existing `dart:convert`, `dart:io`, and `PathNormalizer`.
- **Risk / known imprecision**
  - Strings that happen to match the `graphics/` prefix or an image extension but are not real asset paths (e.g., a log message, a documentation string) will be included. Because the result is intersected with on-disk image files, harmless strings that don't correspond to a real file are dropped at the intersection step — the only user-visible effect would be an over-attribution if a real image happened to be named by an unrelated string.
  - The regex fallback can over-extract from files with unusual formatting (e.g., commented-out code blocks the stripper missed). The `graphics/`-or-image-extension filter contains the blast radius; same intersection argument applies.
  - Performance: config files are small and few per mod (dozens at most). Parser cost is negligible relative to JAR/Java scanning.
