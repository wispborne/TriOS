# BiOS Theme

## Problem

TriOS ships a Pride theme and two Trans themes, but nothing in bi colors. There is also no easy way to add one that renames the app, because the only app name a theme can currently pick is set per theme in `assets/themes.json` and the only pre-set alternative anywhere in the app is "HegOS".

## Proposed Solution

Add a theme called **BiOS** — a pun on TriOS, in the bi pride flag colors (magenta, purple, blue). Selecting it does three things:

1. Recolors the app in the flag colors.
2. Renames the app to "BiOS" everywhere the name is shown (sidebar, About dialog).
3. Draws the app icon (the Telos crest) with a still magenta-to-purple-to-blue gradient. Not animated.

The Hegemony theme already does the first two, so most of this is an entry in `assets/themes.json`. The gradient icon is new — themes can currently pick an image file for the icon, but not a gradient.

Also add "BiOS" to the app-name dropdown in Settings → Theme Modifiers, and "Bi" to the app-icon dropdown next to it, so either can be forced on regardless of which theme is active. That matches how HegOS and the Hegemony crest already work.

## Scope

- New "BiOS" entry in `assets/themes.json`, dark, with the app name override set.
- New optional theme field for a gradient icon, read from `themes.json` and passed through to the widget that draws the app icon.
- Still (non-animated) bi gradient in `TriOSAppIcon`.
- New values in the `AppIconOverride` and `AppNameOverride` enums, plus their two dropdown entries in the settings page.

## Non-goals

- No light variant.
- No new image asset — the gradient is applied to the existing Telos crest.
- No animation. The rainbow icon rotates its gradient; this one does not.
- No changes to the launch button, the rainbow accent bar, or the animated backgrounds.
- No general "pick any gradient" theme feature. Only the bi gradient is added.
