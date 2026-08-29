# Surface mod sources

Status: ready-for-agent

From [GitHub issue #263](https://github.com/wispborne/TriOS/issues/263), item 5: let the user link a mod to its forum thread or Discord message by hand, independent of version checking, so they can track where their mods came from.

## Problem

Almost everything needed already exists. Every mod has a persistent record of its sources (version checker, catalog, download history), a source-override layer where user-typed values win, and a "Mod Sources" dialog that edits most of the link fields. Three gaps keep it from doing what the reporter wants:

1. The "Downloaded from" address (recorded automatically when TriOS installs a mod) has no editor. A mod installed by hand — say, dragged in from a Discord attachment — has nothing recorded, and the user can't fill it in.
2. Overrides are invisible outside the dialog. The mod details dialog builds its Forum/Discord/Download link buttons straight from version-checker and catalog data, so a hand-entered link never shows up anywhere.
3. The dialog is buried under right-click → Troubleshoot… → "Mod Sources", where nobody looking to edit links would think to look.

## Solution

No new data, no new store.

- Make the mod-level "Downloaded from" address editable in the Mod Sources dialog, through the existing override mechanism.
- Make the mod details dialog's link buttons read from the resolved mod record (automatic values plus overrides), and add a "Downloaded from" link button there.
- Move "Mod Sources…" out of the Troubleshoot submenu to the top level of the mod right-click menu.

## In scope

- The three items above. Editability is scoped to fields that record where a mod comes from; forum and Discord fields are already editable.

## Out of scope

- A new free-form link field or note field. The existing forum, Discord, and downloaded-from fields cover the request.
- Editing the per-version download address (stays automatic; Redownload uses it).
- Editing the Installed section (it mirrors what's on disk) or the scraped forum statistics.
- Multiple labeled links per mod.
