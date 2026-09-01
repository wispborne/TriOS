# Design

This design replaces the earlier one-time modpack installer proposal. A
modpack is now a saved, editable, versioned definition that TriOS can compare
with local mods and with a hosted definition.

## Modpacks and profiles

A modpack and a mod profile solve different problems.

- A modpack records which mods to obtain and where to obtain them. It resolves
  each member through a Version Checker file or a fixed download.
- A mod profile records the exact installed variants that should be enabled on
  one computer.

The first release supports creating a modpack from a profile. It does not
create a profile from a modpack. The profile-to-pack action discovers a source
for each profile member and leaves unresolved members flagged in the editor.

The existing shared-profile text importer and exporter remain compatible. The
profile card promotes Create modpack and moves legacy copying to its overflow
menu.

## Shared definition

Every shareable definition has this shape:

```json
{
  "id": "35e06ef0-bd72-4c4c-a175-40cfed42383d",
  "name": "Wisp's QoL Pack",
  "version": 3,
  "author": "Wisp",
  "description": "The mods I always install.",
  "gameVersion": "0.98a-RC8",
  "homepageUrl": "https://fractalsoftworks.com/forum/index.php?topic=12345.0",
  "updateUrl": "https://example.com/wisps-qol-pack.trios-modpack",
  "mods": [
    {
      "id": "mod_id",
      "name": "Mod Name",
      "version": "1.4.0",
      "note": "Enable the optional LunaLib integration after installing.",
      "url": "https://example.com/Mod.version",
      "sourceType": "versionFile",
      "catalog": {
        "name": "Mod Name",
        "forumTopicId": "12345",
        "nexusModsId": "6789"
      }
    }
  ]
}
```

Required pack fields are `id`, `name`, `version`, and `mods`.

- `id` is a UUID created once and retained by later versions.
- `version` is a positive integer created and managed by TriOS. New packs
  start at 1. Saving a meaningful definition change increments it once.
- `author`, `description`, `gameVersion`, `homepageUrl`, and `updateUrl` are
  optional. `gameVersion` is a label only and never controls compatibility or
  installation behavior.
- Member order is retained for presentation. It does not control installation.

Required member fields are `id`, `url`, and `sourceType`.

- `id` is the mod's `mod_info.json` ID. A definition contains at most one
  member for a given ID.
- `sourceType` is `versionFile` or `directDownload`. It is explicit because a
  Version Checker endpoint does not always end in `.version`.
- `name` and `version` are optional display snapshots. The member version does
  not freeze installation to that release.
- `note` is optional plain text written by the creator for that member. It may
  contain line breaks and is limited to 2,000 characters.
- `catalog` is an optional set of recovery clues. Its fields are the catalog
  entry name, forum topic ID, and Nexus ID when TriOS knows them.

All link fields accept only HTTP or HTTPS URLs. The existing URL normalisation
continues to turn supported GitHub and Dropbox page links into their raw or
downloadable forms.

Preserve unknown optional fields as opaque data. Include them in exact and
content comparisons and write them back unchanged so an older TriOS does not
strip fields added by a newer version. `dart_mappable` drops unknown keys by
default, so every extensible shared model must capture its raw unknown keys
during decoding and merge them back during encoding from the start. Do not
build plain generated models and retrofit this after the format work.

## Drafts and saved definitions

The editor keeps one local draft per pack ID so closing the page, switching
packs, or restarting TriOS does not lose work. Allocate a UUID as soon as a new
pack enters the editor, and allow several unfinished new packs to coexist.
Draft members may temporarily lack an ID, URL, or source type. The editor shows
those problems and allows the draft to be saved locally. Copying a share link,
exporting a shareable file, or publishing an update is blocked until the
definition is complete and every member source passes validation.

Save changes commits the draft to the library. Compare user-editable shared
content without treating the existing ID or version as an edit. Increment the
integer version only when that content changed. Draft editing does not change
the version by itself. Saving a changed member order, note, Starsector-version
label, source, member list, or metadata does. A no-op save does not.

Use a separate exact-definition comparison for duplicate imports and online
updates. It includes the ID, version, member order, known fields, and preserved
unknown fields. Add as a copy and Save as a new modpack create a new UUID and
reset the new definition to version 1.

Pack IDs are identity, not proof of authorship. TriOS has no account or key
that survives a new computer. Any library pack can therefore be opened in the
editor. Saving a changed pack with an update URL asks whether to:

- Save as a new modpack. This creates a new ID and removes the old update URL.
- Update this modpack. This retains the ID and update URL.
- Cancel.

A pack without an update URL saves normally because it has no online
definition to conflict with.

## Library storage and calculated state

Store saved packs and drafts through the existing generic settings manager and
notifier pattern. Local-only fields include the drafts keyed by pack ID, last
successful update check, last check attempt, quiet check error details, and the
last export location. These fields never enter a shared link or exported
definition.

Do not persist pack-level installed or created states. For every display,
compare member IDs with `AppState.mods` and calculate:

- Number of members installed.
- Missing members.
- Members whose saved source is incomplete or invalid.
- Members with a failed install attempt.
- Whether a higher online pack version is available.

Any installed variant satisfies pack membership. Enabled state and exact
variant do not affect the installed count.

## Modpacks page

Add a first-class Modpacks tool to navigation. The library shows pack name,
author, integer version, Starsector-version label, description, installed-
member count, source problems, last successful online check, and update
availability.

Provide search and filters for Updates available, Missing mods, and Needs
sources. Do not add Created, Installed, or Added categories. Those labels
would imply pack-level history that TriOS does not track.

Contextual primary actions are View, Edit, Install missing, Retry failed,
Review update, and Enable installed members. Show a passive update count on the
navigation item. Background checks do not open dialogs or toasts.

Deleting a library entry removes only the saved pack and draft. The
confirmation states that no mods will be disabled or uninstalled.

## Editor

Use one editor for every creation path. It has installed mods on the left and
pack members on the right.

- Drag from the installed side to add a member.
- Drag from the member side to remove a member.
- Checkboxes select several rows for Add selected or Remove selected.
- Create from selection pre-populates members chosen in the Mod Manager.
- Create from profile pre-populates the profile's exact members, then resolves
  their shareable sources.
- For a new pack, prefill the optional Starsector-version label from the current
  installation when known. Keep it freely editable.
- Edit the optional creator note for each member. Show member notes on demand
  in compact lists.

The two lists live on the same page. Do not require dragging across navigation
tabs. The current WispGrid drag payload is private and restricted to one grid,
so cross-list dragging needs a shared payload or a small editor-specific drag
model.

When several variants of one mod are installed, prefer the active variant's
source, then the highest version. The member remains one mod ID regardless of
the number of local variants.

## Source selection and repair

Reuse the source the person previously selected for sharing when one exists.
Otherwise choose the initial member source in this order:

1. A user Version Checker override.
2. A user catalog direct-download override.
3. A user download-history override.
4. The mod's Version Checker master file.
5. A linked catalog source that resolves to a download.
6. The last successful direct-download URL.

Show the chosen source and source type. Let the creator replace both. A source
entered or selected in the editor becomes the preferred share source in the
mod's persistent record, so later packs can reuse the choice. The pack keeps
its own copy and does not change when that global record changes later.

Label Version Checker members Tracks latest release. Label direct-download
members Fixed download and explain that the creator must publish a new pack
version when that URL changes.

A URL-less member may remain in a local draft. Sharing remains blocked until
it has a stable source.

Before Copy share link, Export, or Publish update, validate every member
source. A Version Checker source must download, parse, and resolve to a usable
download. A direct-download source must connect and begin returning a
downloadable file; stop before downloading the complete archive. Show progress
and block the sharing action when any member fails. Keep a session-local cache
of each successful result for 60 minutes, keyed by its exact URL and source
type. Reuse that result while the source is unchanged, invalidate it when either
value changes, and retry failures on the next sharing attempt. Local draft
saving never requires validation.

## Dependencies

Check each selected installed variant's declared required dependencies. Show
required mods that are not members and offer Add required dependencies. Follow
required dependencies transitively and de-duplicate by mod ID. Do not add them
without confirmation.

Removing a member that another member requires shows a warning but remains
allowed. Installation confirmation reports unresolved requirements. Do not
guess a catalog mod and silently add it to the definition.

## Link format

A shared link points at TriLink:

```text
https://trilink.wispborne.com/open.html#name=Wisps-QoL-Pack&version=3&modpack=1.<payload>
```

TriLink turns it into the registered scheme URL:

```text
starsector-mod://install?modpack=1.<payload>
```

The payload is the complete shared definition:

1. Encode the definition as JSON.
2. Compress it with zlib deflate.
3. Encode it as unpadded base64url.
4. Prefix it with `1.` as the payload format number.

The readable `name` and `version` fragment fields are display-only. TriOS and
TriLink trust only the payload. The fragment is not sent to the web server, so
GitHub Pages does not reject the long request.

TriOS refuses to create a link longer than 30,000 characters. Windows and Edge
fail near 32,000 characters. A measured 400-member pack is about 7,000
characters, and a typical pack can hold well over a thousand members.

If an outgoing link is too long, say that the pack is too large for a link.
Suggest shortening its description or member notes, removing members, or
exporting a `.trios-modpack` file instead. Do not describe the problem only as
too many mods.

Reject incoming links longer than 30,000 characters. Stop zlib decoding and
reject a definition if the expanded data exceeds 4 MiB or the definition has
more than 5,000 members.

A payload with an unknown format number is refused with a message asking the
person to update TriOS. The parser continues to tolerate Windows rewriting
`install?` as `install/?`.

A link contains either the existing `mod` and `dep` parameters or `modpack`.
It never contains both. A mixed link is malformed.

## Modpack files and drag-and-drop

A readable modpack file uses the `.trios-modpack` extension and contains the
same shared definition as Hjson or JSON. TriOS writes pretty-printed JSON and
generates the filename from a slug of the pack name. Dropping one anywhere in
TriOS is intercepted before game-running, folder-write, log, and mod-archive
guards. Preview and Add to library do not require the game to be closed or the
mods folder to be writable. Opening one through the operating system follows
the same path on warm and cold starts.

A file drop or open always shows a preview with Add to library and Install.
It never installs or saves solely because it was dropped. If the same pack ID
already exists, use the duplicate handling described below.

## Receiving and duplicate handling

The TriOS preview shows the definition that would be saved or installed. It
always offers Add to library and Install. Closing the preview does not save the
pack. Installing saves it automatically. Show the Starsector-version label and
member notes in the preview and installation review.

When an incoming pack has the same ID as a library pack:

- Identical definitions open the existing entry.
- Different definitions show a comparison and offer Replace existing, Add as
  a copy, or Cancel.
- Add as a copy creates a new ID.

Check drafts as well as committed library definitions. An identical incoming
definition opens its existing draft. A different definition with the same ID
offers Discard draft and replace, Add incoming as a copy, or Cancel. Never
overwrite unsaved draft work without that explicit choice.

The integer version informs the comparison but never removes the person's
choice when a link or file is imported directly.

## Online version checks

Use the same broad behavior as mod update checking: automatic checks with a
cooldown, cached results, and a manual refresh that bypasses the cooldown.
Check saved packs with update URLs without blocking the page.

Compare definitions using their pack ID, integer version, and contents:

- Same ID, online version greater: Online update available.
- Same ID, equal version and equal contents: No update.
- Same ID, equal version and different contents: Show the comparison and offer
  Replace existing, Add as a copy, or Cancel.
- Same ID, online version lower: Keep the newer saved or embedded definition
  and report that the online copy is behind.
- Different ID: Show a full comparison and offer Replace existing, Add as
  another modpack, or Cancel. Never replace automatically.

Show a link or file's embedded definition immediately and start checking its
update address at once. Display Checking for updates while the request runs.
When the embedded definition is older than the reachable online definition,
update the preview and say which versions were found. Do not first save the
older snapshot. If the embedded definition is newer, keep it. Equal versions
with different contents require the conflict flow. A failed check leaves the
embedded definition available with a warning.

Accept an online update as one complete definition. Do not merge selected
fields or members. Group changed member sources separately in the comparison.
If the update changes its own update address, require explicit confirmation
before accepting the whole definition. After acceptance, offer to install
missing members through the normal checkbox flow. Members removed by the new
definition stay installed and enabled as they were.

A rollback republishes older contents with a new, higher integer version.
There is no revision history in TriOS.

Failed background checks leave the saved pack usable. Show quiet error details
only in update details or after a manual refresh. Retain the last successful
check time.

## Publishing updates

Save and Publish update are separate actions. Saving changes increments the
local integer version. Publish update exports the current readable definition
for the creator to upload to the configured update URL. TriOS cannot upload to
an arbitrary host.

An update address does not need to resolve before Copy share link, Export, or
Publish update. The creator must be able to export the first definition before
uploading it to that address. Member source validation still blocks sharing.
Later update checks report unavailable, invalid, older, or different-ID hosted
definitions through the normal update flow without invalidating the saved or
embedded pack.

Remember the last export location locally. Ask before overwriting the existing
file. If the reachable online version is lower than the saved version, show
Local version is newer rather than treating the online copy as an update.

## Installation

Installation always shows a confirmation dialog. The setting that skips
ordinary deep-link confirmation does not apply to modpacks.

Resolve all members before the dialog when practical. Default-select missing,
installable members. Already installed members remain visible but are not
selected. People may uncheck any member and install only part of the pack. Add
an unchecked Enable installed members after installation option.

Use the normal download and batch-installation path with
`activateVariantOnComplete: false`. The download path itself does not enable
members or rewrite a profile. The confirmation option runs the normal bulk-
enable behavior after the batch finishes.

Keep successful installs when another member fails. Save per-member failures
for the library view and offer Retry failed. A saved pack naturally continues
to show skipped or failed members as missing.

When the installation option is selected, enable every member installed after
the batch, including members that were already installed and members that
succeeded before another download failed. Keep Enable installed members as a
separate confirmed library action as well. Both use normal mod-manager behavior
and dependency checks. If a profile is tracked, the current loadout becomes
Modified under the `explicit-profile-saving` behavior; the profile itself does
not change.

## Catalog recovery

When a member's source cannot resolve or install, try to find alternatives in
the catalog in this order:

1. The member's saved catalog name, forum topic ID, or Nexus ID.
2. An exact catalog-name match.
3. Likely name matches shown for the person to choose.

Never automatically install a fuzzy match. A safe candidate is presented as
Original source failed - install from Catalog instead and still requires
confirmation.

A successful recovery writes the normal catalog association and download
history to the mod record. It does not edit the shared pack definition or
increment its version. A creator may later replace the broken source in the
editor and publish a new version.

## Likely code areas

- Add a feature folder under `lib/modpacks/` for models, persistence, editor,
  library, update checking, file handling, and installation coordination.
- Add the Modpacks tool in `lib/trios/navigation.dart` and `lib/app_shell.dart`.
- Extend `lib/trios/deep_link/` for `modpack` payloads and pack confirmation.
- Route pack files through `lib/trios/drag_drop_handler.dart` before generic
  file handling.
- Reuse source data from `lib/mod_records/` and download candidates from
  `lib/catalog/catalog_download_resolver.dart`.
- Add Create modpack to `lib/mod_profiles/` while preserving legacy sharing.
- Reuse the download manager and batch installer rather than adding another
  installation system.
