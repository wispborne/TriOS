# Modpacks

TriOS modpacks let you share a complete set of Starsector mods using **a
single link**.

## Create a modpack

Modpacks are **created entirely within TriOS**. Start with an empty pack, mods
selected in the Mod Manager, or a mod profile. The editor shows installed mods
and pack members side by side. Drag mods between the lists, or use checkboxes
to add and remove several at once.

Give the pack a name and optionally add an author, description, homepage,
Starsector version, and update address. Each member may also have a note from
the pack creator. TriOS finds download sources automatically and identifies any
members that still need attention. Unfinished packs can be saved as drafts,
but **every shared member needs a mod ID and a source that TriOS successfully
validates**.

Version Checker sources track a mod's current release. Fixed downloads keep
using the supplied file until the pack creator publishes a newer pack version.
TriOS can also identify required dependencies and add them after confirmation.

## Use a modpack

To use a modpack link, **open it in your browser**. You can review the pack
before it launches TriOS. Dropping a modpack file anywhere in TriOS opens the
same kind of preview.

TriOS always asks whether to **add the pack to your library or install from
it**. Installing also saves the pack. You can choose which missing members to
install and may ask TriOS to enable installed members after installation. One
failed download does not undo the others. When a source no longer works, TriOS
looks for a safe alternative in the Catalog when possible.

Installing a pack **does not enable its mods by default**. You can opt into
enabling installed members during confirmation, enable them yourself, or use
the separate Enable installed members action later. Enabling uses the normal
mod-manager behavior, including its dependency checks.

## Keep packs up to date

The Modpacks library shows how many members are installed, which are missing,
and whether the creator has published a newer pack version. Updates show a
comparison before replacing the saved definition. Newly added members are
installed only when you choose them, and removed members are never
automatically disabled or uninstalled.

Creators can give a pack an update address and publish later versions without
changing the original share link. TriOS begins checking that address as soon as
it opens the pack and keeps the embedded definition usable if the check fails.

## Limits

A modpack can contain **well over a thousand typical mods**. Modpacks contain
download information rather than the mod files themselves, so included mods
must remain available from their linked sources.
