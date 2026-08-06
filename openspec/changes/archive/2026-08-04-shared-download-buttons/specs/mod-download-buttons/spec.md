# Mod download buttons

How every button in TriOS that starts a mod download behaves.

## What it does

### Knowing what a button is about

A download button says what it is about with a **download target**. A target
holds one or more of:

- the mod's id (known for updates of an installed mod)
- the download URL (normalised the same way the download manager normalises it)
- the catalog entry name (known for catalog and forum installs)
- a display name (last resort)

A target matches a running download when **any** of its clues matches that
download's clues, checked in that order. A download's clues are: the mod id
(once the mod is installed or was known up front), the URL it is fetching, the
catalog name recorded on it, and its display name. Name matching ignores case
and surrounding spaces.

**Done when:** starting an update from the dashboard makes the catalog card for
the same mod show progress too, and the other way round.

### The states a button can be in

| State | When | What the user sees |
| --- | --- | --- |
| Idle | nothing running for this target | the normal button |
| Starting | the button was just clicked, no download registered yet | spinner, no percentage |
| Downloading | bytes are moving and the total size is known | spinner filled to the percentage |
| Downloading, size unknown | bytes are moving, no total size | spinner, no percentage |
| Installing | the file is downloaded, unpacking hasn't finished | spinner, no percentage |

While in any state other than Idle the button ignores clicks, and its tooltip
says what is happening ("Downloading…", "Installing…").

**Done when:** clicking Install twice in a row starts one download, not two.

### Showing busy straight away

Clicking a download button puts its target into a "just clicked" state right
away, before the download manager knows anything about it.

That state clears when any of these happens:

- a download matching the target appears (the real progress takes over)
- the deep-link install flow finishes its work (the user confirmed or cancelled)
- 10 seconds pass with no download appearing (safety net, so nothing spins
  forever)

**Done when:** clicking Install on a TriOS deep link in the forum post dialog
shows a spinner immediately, and the spinner keeps running into the real
download rather than blinking off in between.

### Where the states appear

Every download button in the app uses the shared behaviour above:

- catalog card Install / Update button
- catalog details dialog download rows
- forum post dialog download rows
- dashboard mod list update icon
- mods grid update icon
- mod info dialog Update button
- missing-dependency Install / Update buttons in the mods grid

Buttons with a label show the spinner in place of their icon and keep their
label. Buttons that are just an icon swap the icon for a progress ring the same
size.

**Done when:** all seven show progress, and no file outside the shared code
reads a download task's status, byte count or install progress directly.

### Redrawing

Byte-level progress only redraws the button it belongs to. It does not redraw
the grid row, card, or dialog around it.

**Done when:** a download running in the background doesn't cause the mod list
or catalog grid to rebuild on every progress update.
