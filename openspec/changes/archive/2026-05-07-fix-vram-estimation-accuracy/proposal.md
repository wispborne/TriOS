## Why

The VRAM Estimator has three bugs that produce systematic errors when compared against actual GPU VRAM profiler output from a live game session (3,096 textures profiled). JPEGs are underestimated by 25% (~7.9 MB in vanilla+mods), large textures (>1024px in any dimension) are overestimated by 33%, and the POT rounding has a width/height swap that breaks background filtering logic. These errors compound across mod-heavy installations where JPEG backgrounds and large ship sprites are common.

## What Changes

- **Always use 32 bpp (4 bytes/pixel)**: The GPU stores every texture as GL_RGBA regardless of the source image's channel count. TriOS currently reads the actual channel count from file headers (e.g., 24 bpp for JPEGs, 8 bpp for palette PNGs), which underestimates non-RGBA formats by up to 75%. The `bitsInAllChannelsSum` field will be hardcoded to 32 in the VRAM formula.
- **Dimension-based mipmap decision**: The game generates mipmaps when BOTH texture dimensions are <= 1024px after POT rounding. TriOS currently uses an image-type check (background vs sprite). This overestimates large sprites by 33% and could underestimate small backgrounds. The multiplier will switch to checking `potWidth <= 1024 && potHeight <= 1024`.
- **Fix width/height swap in POT rounding**: `textureHeight` is computed from `image.width` and vice versa. While this doesn't affect VRAM totals (multiplication is commutative), it breaks the background width filter at line 464 which compares `textureWidth` against `_vanillaBackgroundWidth`.
- **Fix POT rounding for dimension=1**: TriOS keeps dimension=1 as 1, but the game's POT function starts at 2 and doubles (`byte var2 = 2; while(var2 < var1) var2 *= 2`). Minimum POT value should be 2. Negligible real-world impact but corrects the formula.
- **Compute exact mipmap chain sum**: Replace the `4/3` approximation with the exact geometric sum of mipmap levels (`sum of w*h*4 for each level, halving each dimension until 1x1`). The profiler confirmed exact-sum matches for all 3,096 textures with 0 mismatches, while the `4/3` approximation has up to 1.5% error on non-square textures.

## Capabilities

### New Capabilities

- `accurate-vram-formula`: Corrected VRAM estimation formula matching verified GPU behavior: always 32 bpp, dimension-based mipmaps, exact mipmap chain sums, correct POT rounding.

### Modified Capabilities

(none -- no existing openspec specs to modify)

## Impact

- **`lib/vram_estimator/models/vram_checker_models.dart`**: `ModImageView.bytesUsed` and `ModImageView.multiplier` — core formula changes.
- **`lib/vram_estimator/vram_scan_one_mod.dart`**: POT rounding logic (lines 428-432), width/height swap fix.
- **`lib/vram_estimator/image_reader/png_chatgpt.dart`**: `ImageHeader` class — the `numChannels` and `bitDepth` fields may become unused for VRAM calculation (still useful for display/diagnostics).
- **Cached scan results**: Existing caches store `bitsInAllChannelsSum` per image. The fix should compute VRAM at display time using the corrected formula rather than relying on the cached channel count. Alternatively, re-scan invalidates old caches.
- **No API or dependency changes**.
