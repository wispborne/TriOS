# Design: Deduplicate Vanilla-Replaced Assets

## Current behavior

1. Vanilla VRAM is a hardcoded constant: `VANILLA_GAME_VRAM_USAGE_IN_BYTES = 600000000.0` (~572MB)
2. Each mod is scanned independently; every image in its folder is counted at full cost
3. `getBytesUsedByDedupedImages()` deduplicates using `(modFolder, absolutePath)` as key — only prevents intra-mod double-counting
4. Total displayed = vanilla constant + sum of all mod images
5. Backgrounds have a special case: vanilla-sized backgrounds are excluded, only the largest oversized one counts

## Problem

When a mod replaces a vanilla texture at the same relative path, the mod's copy is counted in full AND the vanilla constant still includes the original. This double-counts.

## Approach

**Scan vanilla's images to build a lookup table, then subtract replacement costs from mod totals.**

### Step 1: Scan ALL starsector-core images

Before scanning mods, recursively enumerate **all** image files in `starsector-core` (accessible via `AppState.gameCoreFolder`) — a full folder scan, not a reference-based scan. This is important because we need the complete set of vanilla assets to catch every possible mod replacement, and because the vanilla total should reflect everything on disk, not just what we can trace through data files.

For each image, read its header and compute `bytesUsed` the same way mod images are computed.

Build a lookup: `Map<String, int>` where:
- Key: normalized relative path from starsector-core root (using `PathNormalizer.normalize`)
- Value: computed `bytesUsed`

Also compute `vanillaTotal`: sum of all values. This replaces the hardcoded constant.

**Performance:** starsector-core has ~2000 images. Reading headers only (no full file reads) takes ~1-2 seconds. This runs once per scan, not per mod. The result can be stored in the `VramChecker` instance.

### Step 2: Pass vanilla lookup into mod scanning

Add `vanillaAssets` (the map from Step 1) to `VramCheckScanParams`. Each mod's `scanOneMod` call receives it.

### Step 3: Mark vanilla replacements during per-mod scan

In `scanOneMod`, after building the image list but before constructing the final `VramMod`:

For each image in the mod's result:
1. Compute its normalized relative path from the mod folder
2. Look up that path in `vanillaAssets`
3. If found: mark the image as a vanilla replacement

Store this per-image flag in `ModImageTable` as a new column (e.g., `vanillaReplacementCosts: List<int>` — the vanilla bytes at that path, or 0 if not a replacement).

### Step 4: Adjust `getBytesUsedByDedupedImages`

Change the aggregation to subtract vanilla replacement costs:

```dart
// For each image:
final effectiveCost = view.bytesUsed - view.vanillaReplacementCost;
// effectiveCost can go negative if mod shrinks the texture —
// clamp to 0 (the mod is saving VRAM, but can't reduce below vanilla's base)
sum += max(0, effectiveCost);
```

### Step 5: Replace the hardcoded vanilla constant

Change `VANILLA_GAME_VRAM_USAGE_IN_BYTES` from a `const` to the actual scanned value. Pass it through to `scan_progress_panel.dart` which displays the vanilla portion.

Keep the old constant as a fallback if `gameCoreFolder` is unavailable (e.g., game path not configured).

### Step 6: Background dedup interaction

The existing `_filterBackgroundsAgainstVanilla` already subtracts `vanillaBackgroundTextSizeInBytes` from background `bytesUsed`. The new general dedup should NOT double-subtract for backgrounds.

Solution: skip vanilla replacement marking for images with `imageType == ImageType.background`, since they already have their own dedup logic.

## Key files changed

| File | Change |
|------|--------|
| `vram_checker_logic.dart` | Add vanilla scanning step; pass vanilla map; replace constant |
| `vram_check_scan_params.dart` | Add `vanillaAssets` field |
| `vram_scan_one_mod.dart` | Mark vanilla replacements per image |
| `vram_checker_models.dart` | Add `vanillaReplacementCosts` column to `ModImageTable` |
| `scan_progress_panel.dart` | Accept scanned vanilla total instead of constant |
| `vram_estimator_manager.dart` | Provide `gameCoreFolder` to `VramChecker` |

## Data flow

```
gameCoreFolder
  → scan vanilla images (header-only)
  → Map<String, int> vanillaAssets + int vanillaTotal
  → passed to each scanOneMod via VramCheckScanParams
  → per-image: compare relativePath against vanillaAssets
  → store vanillaReplacementCost in ModImageTable
  → getBytesUsedByDedupedImages subtracts replacement costs
  → total = vanillaTotal + adjustedModTotal
```

## Cache considerations

The vanilla scan result should be cached alongside mod results. When the game version changes (or the game path changes), invalidate the vanilla cache. The existing cache invalidation for mod scans can be extended to cover this.

## Edge cases

- **Game path not configured**: Fall back to the existing hardcoded constant. The dedup just won't apply.
- **Mod adds a file that doesn't exist in vanilla**: No replacement, counted at full cost (correct).
- **Mod replaces with a larger texture**: `bytesUsed - vanillaBytes` > 0, so only the excess counts (correct).
- **Mod replaces with a smaller texture**: `bytesUsed - vanillaBytes` < 0, clamped to 0 (the mod actually frees VRAM, but we don't credit that since vanilla's total already includes the original).
