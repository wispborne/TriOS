# VRAM Estimator: Deduplicate Vanilla-Replaced Assets

## Problem

The VRAM Estimator double-counts textures that mods replace from vanilla Starsector.

Vanilla VRAM is represented by a hardcoded constant (~600MB). When a mod replaces a vanilla texture at the same relative path (e.g., `graphics/ships/onslaught_body.png`), the estimator counts both:
- The 600MB vanilla constant (which includes the original texture)
- The mod's replacement texture in full

At runtime, the GPU only loads one copy — the mod's version replaces vanilla. The net VRAM impact of a same-size replacement is zero, but TriOS reports it as additional usage.

This also affects cross-mod scenarios: if two mods both replace the same vanilla asset, both are counted because the dedup key is `(modFolder, absolutePath)`, which is always unique per mod.

### Impact

Mods that replace many vanilla assets (total conversions, texture replacements) appear to use significantly more VRAM than they actually add. This can mislead users into thinking they're near their VRAM limit when they aren't.

## Proposed Solution

Scan vanilla (`starsector-core`) to build a lookup of its asset paths and sizes, then subtract replaced vanilla assets from mod totals.

- When a mod image matches a vanilla relative path with the same dimensions: count 0 (no net change)
- When a mod image matches a vanilla relative path with different dimensions: count only the delta (mod size − vanilla size), floored at 0
- Replace the hardcoded `VANILLA_GAME_VRAM_USAGE_IN_BYTES` constant with an actually-scanned vanilla value

## Scope

- VRAM scanner logic (`vram_checker_logic.dart`, `vram_scan_one_mod.dart`)
- Deduplication function (`getBytesUsedByDedupedImages`)
- Vanilla constant removal
- UI: surface vanilla-replacement info in mod breakdowns (optional, low priority)

## Non-goals

- Content-hash-based dedup (file hashing is slow and unnecessary — path matching is how Starsector resolves overrides)
- Cross-mod dedup beyond vanilla (if two mods both provide the same non-vanilla path, that's a mod conflict, not a dedup issue)
- Changing the background-specific dedup logic (already works correctly)
