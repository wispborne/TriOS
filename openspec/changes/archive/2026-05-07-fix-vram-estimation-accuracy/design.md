## Context

The VRAM Estimator scans mod image files, reads their headers to get dimensions and channel info, applies power-of-two rounding, and computes estimated GPU memory usage. An in-game GPU profiler (3,096 textures) confirmed three systematic errors:

1. **Bytes per pixel**: TriOS reads actual file channels (3 for JPEG, 1 for palette PNG). GPU always stores GL_RGBA = 4 bytes/pixel. JPEGs underestimated by 25%.
2. **Mipmap decision**: TriOS uses image type (background vs sprite). Game uses dimension check (both POT dims <= 1024). Large sprites overestimated by 33%.
3. **POT swap**: `textureHeight` computed from `image.width` and vice versa. Doesn't affect totals but breaks background width filter.

The estimation formula lives in two places:
- `vram_scan_one_mod.dart` lines 426-439: reads image headers, does POT rounding, stores `bitsInAllChannelsSum`
- `vram_checker_models.dart` lines 237-253: `ModImageView.bytesUsed` and `.multiplier` compute final bytes from stored fields

Cached results (`VramMod` serialized via dart_mappable) store `bitsInAllChannelsSum` per image row. Existing caches on disk will have incorrect channel counts for JPEGs and palette PNGs.

## Goals / Non-Goals

**Goals:**
- Match GPU-profiled VRAM values exactly for all texture types and dimensions
- Fix background width filtering to use the correct dimension
- Handle cache migration so old scan results don't produce wrong numbers

**Non-Goals:**
- Changing the image header readers themselves (they're correct for what they do)
- Modifying how textures are discovered or selected (selector logic is unrelated)
- Handling compressed GPU formats (the game doesn't use them)
- Modifying GraphicsLib integration (separate concern)

## Decisions

### 1. Hardcode 32 bpp in the formula, keep `bitsInAllChannelsSum` in the data model

**Choice**: Ignore `bitsInAllChannelsSum` in `bytesUsed` and always multiply by 4 bytes/pixel.

**Why not remove `bitsInAllChannelsSum`**: It's still useful diagnostic data (knowing a file is a 3-channel JPEG vs 4-channel PNG). It also avoids a breaking schema change to `ModImageTable`'s columnar format. The field stays in the serialized cache but the formula stops using it.

**Alternative considered**: Change image readers to always report 4 channels. Rejected because the readers are correct about the file format — it's the GPU that expands to RGBA, not the file.

### 2. Compute exact mipmap chain sum instead of `4/3` approximation

**Choice**: When both POT dimensions are <= 1024, sum the geometric series: `level0 + level0/4 + level0/16 + ...` down to 1x1.

**Why**: The profiler confirmed exact-sum matching for all 3,096 textures. The `4/3` approximation has up to 1.5% error on highly non-square textures (e.g., 8x64) because the mipmap chain terminates at different rates per dimension. For most textures the difference is negligible, but exactness is free and eliminates a class of discrepancy.

**Implementation**: A simple loop halving each dimension until both reach 1, accumulating `w * h * 4` per level.

### 3. Fix POT rounding to start at 2

**Choice**: Change the POT function to return `2` for dimensions <= 2 (matching the game's `byte var2 = 2; while(var2 < var1) var2 *= 2`).

**Why**: The game's decompiled code starts at 2. TriOS currently keeps 1 as 1. No real textures are 1px, but the formula should match.

### 4. Cache invalidation via version bump

**Choice**: Bump the cache format version so old caches are discarded on first run after update. Scans will re-run for all mods.

**Why**: Old caches store `bitsInAllChannelsSum` values that are wrong for JPEGs. While the new formula ignores this field, re-scanning also fixes the POT swap bug in stored `textureHeight`/`textureWidth`. A clean re-scan is simpler than migration logic and only costs one scan cycle.

**Alternative considered**: Migrate in place by overriding `bitsInAllChannelsSum` to 32 and swapping height/width on load. Rejected — more code for a one-time event.

## Risks / Trade-offs

- **[One-time re-scan cost]** Users will see a full re-scan on first launch after update. Mitigation: scans are fast (seconds per mod with header-only reading). Acceptable UX since it happens once.
- **[Existing comparison data]** Users who tracked VRAM numbers over time will see different values. Mitigation: numbers will be more accurate, which is the whole point. Could mention "improved accuracy" in release notes.
- **[`4/3` approximation was close enough]** The exact mipmap sum is slightly more compute. Mitigation: it's a trivial loop that runs once per image during scan, not on every UI rebuild.
