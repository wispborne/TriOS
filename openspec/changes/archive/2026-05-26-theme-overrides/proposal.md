# Theme Overrides

## Problem

Some visual options are locked to specific themes. A user who likes the Starsector default colors but also wants the rainbow app icon has to pick one or the other — they can't mix and match.

## Proposed Solution

Add a **theme overrides** system: a set of user settings that sit on top of the active theme and selectively replace specific visual properties. Unlike themes (which are pre-defined JSON bundles), overrides are individual toggles the user controls.

### Initial overrides

1. **Rainbow app icon** — Apply the animated rainbow gradient to the TriOS app icon (telos crest), regardless of which theme is active.
2. **Rainbow launcher icon** — Apply the rainbow border and styling to the Starsector "S" launch button, regardless of which theme is active.

## Scope

- Two new boolean settings in `Settings`.
- Modify `TriOSAppIcon` and `StarsectorIcon` to check override settings in addition to the theme's `rainbowAccent` flag.
- Add UI controls in the settings page (likely near the theme picker).
- No changes to the theme file format or theme loading logic.

## Non-goals

- Not changing the Windows/macOS/Linux executable icon (that's baked at build time).
- Not creating a general-purpose "theme editor" — just targeted override toggles.
- Not adding override options beyond the two listed above (more can come later).
