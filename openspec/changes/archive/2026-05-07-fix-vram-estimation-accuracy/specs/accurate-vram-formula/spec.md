## ADDED Requirements

### Requirement: Always use 32 bits per pixel for VRAM calculation

The VRAM formula SHALL use 32 bits per pixel (4 bytes) for all textures regardless of the source image format's channel count. The GPU stores all textures as GL_RGBA.

#### Scenario: JPEG image (3-channel source)
- **WHEN** a JPEG image is scanned with dimensions 256x256
- **THEN** level0 bytes SHALL be 256 * 256 * 4 = 262,144 bytes (not 256 * 256 * 3 = 196,608)

#### Scenario: Palette PNG (1-channel source)
- **WHEN** a palette PNG (color type 3) is scanned with dimensions 128x128
- **THEN** level0 bytes SHALL be 128 * 128 * 4 = 65,536 bytes (not 128 * 128 * 1 = 16,384)

#### Scenario: RGBA PNG (4-channel source)
- **WHEN** an RGBA PNG is scanned with dimensions 512x512
- **THEN** level0 bytes SHALL be 512 * 512 * 4 = 1,048,576 bytes (unchanged from current behavior)

### Requirement: Dimension-based mipmap decision

The VRAM formula SHALL apply mipmap overhead when BOTH power-of-two-rounded dimensions are <= 1024 pixels. The image type (background vs sprite) SHALL NOT determine mipmap application.

#### Scenario: Small texture gets mipmaps
- **WHEN** a texture has POT dimensions 512x512
- **THEN** the VRAM calculation SHALL include mipmap overhead

#### Scenario: Large texture has no mipmaps
- **WHEN** a texture has POT dimensions 2048x512
- **THEN** the VRAM calculation SHALL NOT include mipmap overhead, and totalBytes SHALL equal level0Bytes

#### Scenario: Texture at exact threshold
- **WHEN** a texture has POT dimensions 1024x1024
- **THEN** the VRAM calculation SHALL include mipmap overhead (both dims <= 1024)

#### Scenario: One dimension exceeds threshold
- **WHEN** a texture has POT dimensions 2048x256
- **THEN** the VRAM calculation SHALL NOT include mipmap overhead

### Requirement: Exact mipmap chain sum

When mipmaps are applied, the total bytes SHALL be computed as the exact sum of all mipmap levels, not the 4/3 approximation. Each level halves both dimensions (minimum 1), and the sum continues until both dimensions reach 1.

#### Scenario: Square texture mipmap sum
- **WHEN** a 128x128 texture has mipmaps
- **THEN** totalBytes = (128*128 + 64*64 + 32*32 + 16*16 + 8*8 + 4*4 + 2*2 + 1*1) * 4 = 87,380 bytes

#### Scenario: Non-square texture mipmap sum
- **WHEN** a 256x128 texture has mipmaps
- **THEN** totalBytes = (256*128 + 128*64 + 64*32 + 32*16 + 16*8 + 8*4 + 4*2 + 2*1 + 1*1) * 4 = 174,764 bytes

#### Scenario: Highly non-square texture
- **WHEN** a 512x64 texture has mipmaps
- **THEN** the sum SHALL iterate until both dimensions reach 1, with the larger dimension continuing to halve after the smaller reaches 1

### Requirement: Correct power-of-two rounding

The POT rounding function SHALL match the game's algorithm: start at 2, double until >= input dimension. The minimum POT value SHALL be 2 (not 1).

#### Scenario: Dimension of 1
- **WHEN** an image dimension is 1
- **THEN** the POT-rounded value SHALL be 2

#### Scenario: Exact power of two
- **WHEN** an image dimension is exactly 256
- **THEN** the POT-rounded value SHALL be 256

#### Scenario: Non-power of two
- **WHEN** an image dimension is 300
- **THEN** the POT-rounded value SHALL be 512

### Requirement: Correct width/height assignment in POT rounding

The POT rounding SHALL assign `textureWidth` from the image's width and `textureHeight` from the image's height (not swapped).

#### Scenario: Non-square image
- **WHEN** an image has width=400 and height=100
- **THEN** textureWidth SHALL be 512 (POT of 400) and textureHeight SHALL be 128 (POT of 100)

#### Scenario: Background width filtering
- **WHEN** a background image has actual width=4096 and height=2048
- **THEN** textureWidth SHALL be 4096 and the background filter SHALL compare textureWidth (not textureHeight) against the vanilla background width threshold
