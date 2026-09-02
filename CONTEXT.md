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

## Mod sources

**Mod source**:
A record of where TriOS learned about a mod — the version checker, the catalog, a forum thread, or a download. Collected automatically as TriOS encounters the mod.
_Avoid_: Mod origin, mod link, mod record (that's the container holding all of a mod's sources)

**Source override**:
A value the user typed in to replace what a mod source collected automatically. Wins over the automatic value, field by field, and survives automatic re-collection.
_Avoid_: Manual link, user link, custom source

## Mod profiles

**Mod profile**:
A named local snapshot of the exact installed mod variants that should be enabled together.
_Avoid_: Modpack, shared mod list

**Current loadout**:
The exact mod variants enabled right now. It may differ from the tracked profile without changing that profile.
_Avoid_: Active profile, current modpack

**Tracked profile**:
The saved profile TriOS is comparing with the current loadout. Tracking continues until the user stops it or chooses another profile.
_Avoid_: Active profile, enabled profile

**Modified loadout**:
A current loadout that differs from the tracked profile. The profile itself remains unchanged until the user saves.
_Avoid_: Modified profile, dirty profile

## Modpacks

**Modpack**:
A named, versioned definition of mods and their download sources that can be saved, shared, and installed through TriOS.
_Avoid_: Mod list, collection, bundle

**Modpack item**:
One mod named by a modpack, identified by its mod ID and a Version Checker or fixed-download address that must yield that ID. Any installed variant with that ID satisfies membership; exact versions and complete dependency closure are not promised.
_Avoid_: Member, entry, dependency, locked mod

**Modpack item download source**:
The public HTTP or HTTPS address used to obtain a modpack item. It must yield the item's mod ID but does not promise an exact version or file.
_Avoid_: Member source, mod source

**Modpack item note**:
Optional instructions or context written by the modpack creator for one item. The note travels with the modpack.
_Avoid_: Personal note, local annotation

**Modpack item status**:
A creator-set, optional label describing how important an item is to the modpack. It has no default. The standard labels are Required, Recommended, and Optional; creators may use a custom single-line label up to 40 characters. The label is informational only and never changes installation, dependency, or validation behavior.
_Avoid_: Install rule, dependency type, pack status

**Modpacks library**:
The modpack definitions saved in TriOS. It does not record a pack-level installed or created status.
_Avoid_: Installed packs, pack history

**Modpack library entry**:
A modpack saved in the local Modpacks library together with facts that belong only to that saved copy. Current item coverage is calculated rather than part of the entry.
_Avoid_: Installed modpack, modpack status

**Modpack draft**:
An autosaved local working copy of a modpack definition, kept separately from its saved library entry. It may contain unresolved items but cannot be committed or shared until every item is valid.
_Avoid_: Broken pack, unpublished pack

**Modpack version**:
A positive integer that TriOS increases whenever a saved modpack definition changes.
_Avoid_: Mod version, payload version, format version

**Modpack update URL**:
An optional address containing the current online definition of the same modpack ID. A definition with another ID is a separate pack, not an update.
_Avoid_: Homepage, source URL

**Starsector version**:
An optional label saying which version of Starsector a modpack was made for. It informs people but never controls installation or compatibility behavior.
_Avoid_: Required game version, compatibility rule

**Modpack installation**:
A background attempt to install selected items from one saved modpack. It can outlive its dialog; stopping it keeps finished work, and a later attempt recalculates what remains.
_Avoid_: Installation dialog, installed modpack

## Grids

**Frozen column**:
A column the user has told a grid to keep in view while the other columns scroll sideways. Frozen columns always sit leftmost, keeping their order relative to each other. Named after Excel's "freeze panes".
_Avoid_: Pinned column (pinning is the grids' word for rows held at the top), sticky column, locked column
