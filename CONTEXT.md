# TriOS

An all-in-one Starsector launcher, mod manager, and toolkit. This glossary fixes the words the project uses for its own concepts, so the code, the UI, and conversations about them agree.

## Appearance

**Theme**:
A named set of colours someone picks to change how TriOS looks. It covers colours, the font, and the app name, but not the app icon.
_Avoid_: Skin, palette, colour scheme

**Built-in theme**:
A theme that ships inside TriOS. Replaced wholesale whenever TriOS updates.
_Avoid_: Default theme, stock theme

**User theme**:
A theme someone wrote themselves. Kept outside the install folder so a TriOS update never removes it.
_Avoid_: Custom theme, personal theme

**Theme id**:
What TriOS remembers when someone picks a theme. Separate from the theme's display name, so renaming a theme doesn't lose the selection.
_Avoid_: Theme key, theme name

**Theme modifiers**:
Settings that change TriOS's appearance regardless of which theme is active — the app icon, the app name, and the animated background.
_Avoid_: Theme overrides, appearance settings

## Mod updates

**Muted mod**:
A mod the user has told TriOS to stop mentioning. No version check runs for it at all, so no update ever appears for it anywhere — the Mods page, the Dashboard, or the Catalog. Stays that way until the user unmutes it.
_Avoid_: Ignored mod, silenced mod, hidden mod

**Muted update**:
One version of one mod that the user has told TriOS to stop mentioning. Version checks keep running, and the mod speaks up again by itself as soon as it advertises a different version. For skipping one broken release, as opposed to going quiet on the mod. Not the same as a muted mod.
_Avoid_: Skipped version, ignored update, dismissed update
