# Pride Luminance Theme

## Problem

The existing "Pride" theme uses a simple flowing rainbow gradient bar and magenta primary color. Apple's 2025 Pride Luminance wallpaper introduced a distinctive visual language: glowing vertical ribbons of color with luminous bloom effects against a deep black background. There's no theme in TriOS that captures this aesthetic.

## Proposed Solution

Add a new "Pride Luminance" theme with:

1. **Theme colors**: Deep black background with a vivid pink/magenta primary, tuned to evoke the luminance aesthetic.
2. **Luminance accent bar**: A new accent bar variant that renders glowing vertical color ribbons instead of the existing flowing horizontal gradient. Each ribbon has a soft glow/bloom effect, and the ribbons slowly animate with a breathing/shimmer pulse.
3. **Luminance color palette**: A more vivid, neon-shifted version of the pride colors to match the luminance feel.

## Scope

- New theme entry in `themes.json`
- New `luminanceAccent` boolean on `TriOSTheme` and `TriOSThemeExtension`
- New `LuminanceAccentBar` widget with custom painter for glowing vertical ribbons
- `ThemedAccentBar` delegates to the luminance variant when the flag is set
- Existing `rainbowAccent` behaviors (scrollbar colors, progress indicators, app icon) also activate for this theme

## Non-goals

- Changing how existing themes look or behave.
- Adding user-customizable color palettes (like Apple's 12-color picker).
- Dynamic motion/tilt effects (Apple's wallpaper reacts to device motion -- not applicable to desktop).
- Changing the watch face / lock screen paradigm -- this is just a theme with an accent bar.
