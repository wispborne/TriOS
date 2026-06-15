## 1. Fix POT Rounding

- [x] 1.1 Fix width/height swap in `_processAssets` (`vram_scan_one_mod.dart` lines 428-432): assign `textureHeight` from `image.height` and `textureWidth` from `image.width`
- [x] 1.2 Change POT rounding for dimension=1 to return 2 instead of 1 (match game's `byte var2 = 2; while(var2 < var1) var2 *= 2`)

## 2. Fix Bytes-Per-Pixel Formula

- [x] 2.1 In `ModImageView.bytesUsed` (`vram_checker_models.dart`), replace `bitsInAllChannelsSum / 8` with hardcoded `4` (bytes per pixel) since the GPU always stores GL_RGBA

## 3. Fix Mipmap Decision Logic

- [x] 3.1 In `ModImageView.multiplier`, replace the image-type check (`imageType == ImageType.background ? 1.0 : 4/3`) with a dimension check (`textureWidth <= 1024 && textureHeight <= 1024`)
- [x] 3.2 Replace the `4/3` approximation with an exact mipmap chain sum function: loop halving both dimensions (min 1) until both reach 1, accumulating `w * h * 4` per level

## 4. Cache Invalidation

- [x] 4.1 Bump the VRAM cache format version so old caches are discarded and a fresh scan runs on first launch after update

## 5. Tests

- [x] 5.1 Add unit tests for the corrected POT rounding function (inputs: 1->2, 2->2, 3->4, 256->256, 300->512, 1024->1024, 1025->2048)
- [x] 5.2 Add unit tests for the exact mipmap chain sum (128x128->87380, 256x128->174764, 2048x512->4194304 with no mipmaps)
- [x] 5.3 Add unit tests for `bytesUsed` with JPEG-like inputs (3-channel source should still produce 32bpp GPU bytes)
- [x] 5.4 Add a regression test verifying the dimension-based mipmap threshold: 1024x1024 gets mipmaps, 2048x512 does not
