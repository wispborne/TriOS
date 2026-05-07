# Tasks: Deduplicate Vanilla-Replaced Assets

## Vanilla scanning

- [ ] Add a `scanVanillaAssets` function that recursively enumerates ALL image files in the starsector-core directory (full folder scan, not reference-based), reads headers, computes `bytesUsed`, and returns `Map<String, int>` (normalized relative path → bytes) plus the total
- [ ] Call `scanVanillaAssets` in `VramChecker.check()` before scanning mods, using the game core directory
- [ ] Add `gameCoreDir` parameter to `VramChecker` constructor; wire it from `VramEstimatorManager` via `AppState.gameCoreFolder`

## Plumbing the vanilla map

- [ ] Add `vanillaAssets` field (nullable `Map<String, int>`) to `VramCheckScanParams`
- [ ] Pass the scanned vanilla map through `_buildParams` into each mod's scan params

## Per-mod replacement marking

- [ ] In `scanOneMod`, after building `referencedViews` but before constructing the final `ModImageTable`: for each image, compute normalized relative path from mod folder and look up in `vanillaAssets`
- [ ] Add `vanillaReplacementCosts` column to `ModImageTable` (list of `int`, 0 for non-replacements)
- [ ] Expose `vanillaReplacementCost` getter on `ModImageView`
- [ ] Skip vanilla replacement marking for `ImageType.background` images (they already have their own dedup)

## Adjusted aggregation

- [ ] Update `getBytesUsedByDedupedImages` to subtract `vanillaReplacementCost` from each image's `bytesUsed` (clamped to 0)
- [ ] Replace usage of `VANILLA_GAME_VRAM_USAGE_IN_BYTES` constant with the scanned vanilla total in summary output and progress panel
- [ ] Keep the constant as a fallback when `gameCoreDir` is null

## Serialization & cache

- [ ] Update `ModImageTable.toColumnar` / `fromColumnar` and `fromRows` to include the new column
- [ ] Ensure old caches without the column still load (default to 0)

## Testing

- [ ] Verify a mod that replaces a vanilla texture at the same size shows 0 additional VRAM for that image
- [ ] Verify a mod that replaces a vanilla texture at a larger size shows only the delta
- [ ] Verify a mod with only new (non-vanilla) assets is unaffected
- [ ] Verify the total (vanilla + mods) is lower than before for modlists with many replacements
