# Design

This design replaces the earlier one-time modpack installer proposal. A
modpack is now a saved, editable, versioned definition that TriOS can compare
with local mods and with a hosted definition.

## Main parts

Keep the feature under `lib/modpacks/` and reuse the existing TriOS services
for installed mods, mod records, downloads, archive inspection, installation,
dependency checks, settings storage, and navigation.

Use three saved-data models with separate jobs:

- `ModpackDefinition` is the complete shared data that links, files, and update
  URLs contain.
- `ModpackDraft` is an autosaved working copy. It may be empty or invalid.
- `ModpackLibraryEntry` holds one saved definition plus local-only update,
  export, and install-failure data.

Do not add a saved modpack-status model. Build card and page display data from
the saved pack, its draft, installed mods, update information, and any current
installation.

One `ModpackStore` owns all saved packs and drafts. It is the only code allowed
to assign IDs and versions or to commit, copy, replace, and delete packs. Store
everything in one `modpacks.json` file through the existing
`GenericAsyncSettingsManager` and Riverpod notifier pattern. If that file is
corrupt, keep the backup and ask whether to restore it or start empty.

Installations are managed in memory outside dialogs and pages. A dialog and
the Modpacks page observe the same installation by pack ID. Installations do
not survive an app restart; starting again recalculates what remains.

## Modpacks and profiles

A modpack and a mod profile solve different problems.

- A modpack records which mods to obtain and where to obtain them. It resolves
  each item through a Version Checker file or a fixed download.
- A mod profile records the exact installed variants that should be enabled on
  one computer.

The first release supports creating a modpack from a profile. It does not
create a profile from a modpack. The profile-to-pack action discovers a source
for each profile mod and leaves unresolved items flagged in the editor.

The existing shared-profile text importer and exporter remain compatible. The
profile card promotes Create modpack and moves legacy copying to its overflow
menu.

## Shared definition

Every shareable definition has this shape:

```json
{
  "formatVersion": 1,
  "id": "N3qGd6c8R2mVx1ZaYkW0_A",
  "name": "Wisp's QoL Pack",
  "version": 3,
  "author": "Wisp",
  "description": "The mods I always install.",
  "gameVersion": "0.98a-RC8",
  "homepageUrl": "https://fractalsoftworks.com/forum/index.php?topic=12345.0",
  "updateUrl": "https://example.com/wisps-qol-pack.trios-modpack",
  "items": [
    {
      "id": "mod_id",
      "name": "Mod Name",
      "version": "1.4.0",
      "status": "Recommended",
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

Required pack fields are `formatVersion`, `id`, `name`, `version`, and
`items`. A committed definition contains at least one item; an unsaved draft
may be empty.

- `formatVersion` is `1` for this definition shape. It is separate from the
  transport prefix used by compressed links.
- `id` is 16 random bytes encoded as exactly 22 unpadded base64url characters.
  It is opaque, case-sensitive, and retained by later versions.
- `version` is a positive integer created and managed by TriOS. New packs
  start at 1. Saving a meaningful definition change increments it once.
- `author`, `description`, `gameVersion`, `homepageUrl`, and `updateUrl` are
  optional. `gameVersion` is a label only and never controls compatibility or
  installation behavior.
- Item order is retained for presentation. It does not control installation.

Required item fields are `id`, `url`, and `sourceType`.

- `id` is the mod's `mod_info.json` ID. A definition contains at most one
  item for a given case-sensitive ID.
- `sourceType` is `versionFile` or `directDownload`. It is explicit because a
  Version Checker endpoint does not always end in `.version`.
- `name` and `version` are optional display snapshots. The item version does
  not freeze installation to that release.
- `status` is an optional single-line label of at most 40 characters. Required,
  Recommended, and Optional are standard labels; custom labels are allowed.
  It is informational only and does not change selection, installation,
  dependency, validation, or enabling behavior. There is no default status.
- `note` is optional plain text written by the creator for that item. It may
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
build plain generated models and retrofit this after the format work. Ignore
unknown optional fields in a known format safely. Reject an unknown
`formatVersion` with an Update TriOS message and do not allow editing,
installation, or resharing.

The codec uses UTF-8 and fixed output ordering. Sort preserved unknown object
keys while retaining item order. Enforce JavaScript-safe integer versions,
bounded strings and nesting, a 4 MiB expanded limit, and a 5,000-item limit.

## Drafts and saved definitions

The editor keeps one local draft per pack ID so closing the page, switching
packs, or restarting TriOS does not lose work. Allocate an ID as soon as a new
pack enters the editor, and allow several unfinished new packs to coexist.
Draft items may temporarily lack an ID, URL, or source type. The editor shows
those problems and allows the draft to be saved locally. Copying a share link,
exporting a shareable file, or publishing an update is blocked until the
definition is complete and every item source passes validation.

Save changes commits the draft to the library. Compare user-editable shared
content without treating the existing ID or version as an edit. Increment the
integer version only when that content changed. Draft editing does not change
the version by itself. Saving a changed item order, note, status,
Starsector-version label, source, item list, or metadata does. A no-op save does
not. Copy link, Export, and Publish never change the version.

Use a separate exact-definition comparison for duplicate imports and online
updates. It includes the ID, version, item order, known fields, and preserved
unknown fields. Add as a copy and Save as a new modpack create a new ID and
reset the new definition to version 1.

Pack IDs are identity, not proof of authorship. TriOS has no account or key
that survives a new computer. Any library pack can therefore be opened in the
editor. Saving a changed pack with an update URL asks whether to:

- Save as a new modpack. This creates a new ID and removes the old update URL.
- Update this modpack. This retains the ID and update URL.
- Cancel.

A pack without an update URL saves normally because it has no online
definition to conflict with.

The editor toolbar has Save changes and Discard changes. Back leaves the
autosaved draft in place without prompting. Save is disabled while the draft is
invalid and shows the next version when committing would increment it.

## Library storage and calculated state

Local-only fields include drafts keyed by pack ID, the complete last successful
online definition and its timestamp, quiet check error details, the last export
location, and per-item install failures. These fields never enter a shared link
or exported definition. Key a failure by item ID and source fingerprint; clear
it after a successful install or source change. Stopped and unstarted items are
not failures.

Keep store state immutable so Riverpod updates remain predictable.

Do not persist pack-level installed or created states. For every display,
compare item IDs with `AppState.mods` and calculate:

- Number of items installed.
- Missing items.
- Items whose saved source is incomplete or invalid.
- Items with a failed install attempt.
- Whether a higher online pack version is available.

Any installed variant satisfies an item. Enabled state and exact
variant do not affect the installed count.

## Modpacks page

Add a first-class Modpacks tool to navigation. Build it like the modern viewer
pages: a keep-alive `ConsumerStatefulWidget`, a Riverpod page controller,
separate current and persisted page state, `ViewerToolbar`, `SmartSearchBar`,
the shared filter engine, and `WispAdaptiveGridView` cards. Keep Modpacks in the
main tool group rather than grouping it with game-data viewers. Do not add a
navigation update count in this change.

Use the current TriOS theme and shared widgets. Do not create a separate light
or feature-specific color scheme for Modpacks.

Mix saved packs and draft-only packs in one card list. A card shows name,
author, pack version, game version, installed/total count, and applicable Draft,
Unsaved changes, Update available, Failed, and Installing labels. Its hover
details include the description, homepage, update URL, and installed/missing
counts, but not source problems, failed installs, last-update-check time, or an
item-status summary. Clicking a saved card opens its full page; clicking a
draft-only card opens its editor. Other actions use the overflow menu except
that a running installation exposes progress and Stop.

The toolbar shows the pack count, update refresh, New, Import, sorting, and
smart search. Name ascending is the default sort; also offer Author, Pack
version, Game version, and Installed count. A running installation is placed
first until it finishes or stops. Filters cover Draft, Unsaved changes,
Installing, Update available, Missing mods, and Needs sources. Persist the same
sort, display, filter visibility, locked-filter, and search-history choices as
other viewer pages, but not the current search, open pack, or editor.

An empty library shows a short explanation with New modpack and Import modpack.
When search or filters hide every card, show Clear search and Clear filters
instead.

View and Edit replace the main Modpacks page area. The full-page actions are
Back, Edit, Copy link, Export, Install, and overflow, in that order. Delete and
Duplicate are in the overflow menu. Show all pack information in one compact
read-only block above the item grid.

The full-page item grid defaults to icon, name, author, status, installed state,
one combined version column, and dependency warnings. If installed and recorded
pack versions differ, show `<installed> (modpack: <recorded>)`; otherwise show
one version. Other normal mod columns are available but hidden by default. The
read-only grid may be sorted and starts in manual pack order. Items can expand
to show their full details, several may be open, and Expand all and Collapse all
act on the currently visible rows.

Expanded read-only details show the full download address, source type, note,
status, recorded and installed versions, dependency warnings, and catalog
recovery information.

Deleting a library entry removes only the saved pack and draft. The
confirmation states that no mods will be disabled or uninstalled.

## Editor

Use one editor for every creation path. It has installed mods on the left and
pack items on the right. Keep this two-pane layout at every window size because
it is a power-user operation.

- Drag from the installed side to add an item.
- Drag from the item side to remove an item.
- Checkboxes select several rows for Add selected or Remove selected.
- Create from selection pre-populates items chosen in the Mod Manager.
- Create from profile pre-populates the profile's exact mods, then resolves
  their shareable sources.
- For a new pack, prefill the optional Starsector-version label from the current
  installation when known. Keep it freely editable.
- Edit the optional creator note and status for each item. Show notes on demand
  in compact lists.

Pack fields sit above the lists. Editable fields use compact Settings-style
text boxes; the collapsed form uses compact read-only values. New or invalid
packs start expanded, while an existing valid pack starts collapsed. This
expanded state lasts only for the current session.

The left side shows one row per mod ID, preferring the active variant and then
the highest installed version. Extract the Mod Manager's column definitions so
both grids support the normal mod columns with different defaults and separate
saved column state. Each side has its own search box.

The right side is manual pack order only and cannot be sorted. It supports drag
handles, checkbox selection, Remove selected, and Set status. A collapsed row
shows checkbox, icon, name, author, status, source type, source host, and issue
indicators. An expanded row shows editable status, source type, full URL, note,
validation and repair controls, and Remove. Several rows may be expanded, with
Expand all and Collapse all for currently visible rows. WispGrid needs reusable
controlled selection and cross-grid drag support, without modpack-specific code
inside the shared grid.

The status control offers None, Required, Recommended, Optional, custom values
already used by the pack, and entry of a new custom value. Trim values, reject
blank or control-character custom values, recognize standard values without
case sensitivity, and preserve custom capitalization. Do not add a separate
status-management screen.

The two lists live on the same page. Do not require dragging across navigation
tabs. The current WispGrid drag payload is private and restricted to one grid,
so cross-list dragging needs a shared payload or a small editor-specific drag
model.

When several variants of one mod are installed, prefer the active variant's
source, then the highest version. The item remains one mod ID regardless of
the number of local variants.

## Source selection and repair

Reuse the source the person previously selected for sharing when one exists.
Otherwise choose the initial item source in this order:

1. A user Version Checker override.
2. A user catalog direct-download override.
3. A user download-history override.
4. The mod's Version Checker master file.
5. A linked catalog source that resolves to a download.
6. The last successful direct-download URL.

Show the chosen source and source type. Let the creator replace both. Commit a
selected source to the mod's persistent record only when the draft is committed;
draft edits alone do not change global records. The pack keeps its own copy and
does not change when that global record changes later. A successful catalog
recovery during installation updates the normal mod record immediately.

Label Version Checker items Tracks latest release. Label direct-download items
Fixed download and explain that the creator must publish a new pack
version when that URL changes.

A URL-less item may remain in a local draft. Sharing remains blocked until
it has a stable source.

Before Copy share link, Export, or Publish update, validate every item source.
A Version Checker source must download, parse, and resolve to a usable
download. A direct-download source must connect and begin returning a
downloadable file; stop before downloading the complete archive. Show progress
in a new section on the pack page rather than a dialog, and block the sharing
action when any item fails. Keep a session-local cache
of each successful result for 60 minutes, keyed by its exact URL and source
type. Reuse that result while the source is unchanged, invalidate it when either
value changes, and retry failures on the next sharing attempt. Local draft
saving never requires validation.

The section lists each item and its current result, exposes repair for failures,
and allows the person to cancel the check. When every item passes, finish the
original Copy link or Export action automatically.

## Dependencies

Check each selected installed variant's declared required dependencies. Show
required mods that are not items and offer Add required dependencies. Follow
required dependencies transitively and de-duplicate by mod ID. Do not add them
without confirmation.

Removing an item that another item requires shows a warning but remains
allowed. Installation confirmation reports unresolved requirements. Do not
guess a catalog mod and silently add it to the definition.

Recompute dependencies before installation. Cycles, conflicts, and missing
dependencies remain warnings and do not invalidate the pack.

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
fail near 32,000 characters. A measured 400-item pack is about 7,000
characters, and a typical pack can hold well over a thousand items.

If an outgoing link is too long, say that the pack is too large for a link.
Suggest shortening its description or item notes, removing items, or
exporting a `.trios-modpack` file instead. Do not describe the problem only as
too many mods.

Reject incoming links longer than 30,000 characters. Stop zlib decoding and
reject a definition if the expanded data exceeds 4 MiB or the definition has
more than 5,000 items.

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
uses the same compact pack-information block and item table as the full page.
It offers Add to library, Install, Check for update, and Cancel. Closing the
preview does not save the pack. Installing saves it automatically. Show the
Starsector-version label, item statuses, and item notes in the preview and
installation review.

Treat update and item addresses from incoming packs as untrusted. Block
loopback, private, and link-local targets, revalidate every redirect, and apply
response-size and timeout limits.

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
- Different ID: Treat the hosted definition as a broken update and do not allow
  it to replace the saved pack. Offer to add it as another modpack or cancel.

Show a link or file's embedded definition immediately. Do not contact its
update address until the person asks to check it, adds the pack, or starts
installation. Keep the embedded definition selected while a check runs; a late
result must not change an add or installation already in progress. If a newer
online definition is found before an action starts, offer it without silently
replacing the embedded definition. A failed check leaves the embedded
definition available with a warning.

Accept an online update as one complete definition. Do not merge selected
fields or items. Review saved-pack updates in a dialog over the full pack page.
Use the same comparison dialog for incoming conflicts. Show pack field changes,
then Added, Removed, and Changed item sections; changed items call out status,
source, note, and recorded-version changes. Use one change list rather than
side-by-side tables, with old values struck out and new values beside them when
that makes the change easier to read.
If the update changes its own update address, require explicit confirmation
before accepting the whole definition. After acceptance, offer to install
missing items through the normal checkbox flow. Items removed by the new
definition stay installed and enabled as they were.

A rollback republishes older contents with a new, higher integer version.
There is no revision history in TriOS.

Failed background checks leave the saved pack usable. Show quiet error details
only in update details or after a manual refresh. Retain the complete last
successful online definition and its timestamp.

Do not accept an update while a draft exists. The person must first commit the
draft, save it as a new pack, or discard it. Do not merge or rebase drafts.

## Publishing updates

Save and Publish update are separate actions. Saving changes increments the
local integer version. Publish update exports the current readable definition
for the creator to upload to the configured update URL. TriOS cannot upload to
an arbitrary host.

An update address does not need to resolve before Copy share link, Export, or
Publish update. The creator must be able to export the first definition before
uploading it to that address. Item source validation still blocks sharing.
Later update checks report unavailable, invalid, older, or different-ID hosted
definitions through the normal update flow without invalidating the saved or
embedded pack.

Remember the last export location locally. Ask before overwriting the existing
file. If the reachable online version is lower than the saved version, show
Local version is newer rather than treating the online copy as an update.

## Installation

Installation always shows a confirmation dialog. The setting that skips
ordinary deep-link confirmation does not apply to modpacks. Installing first
saves, replaces, or copies the pack into the library; the installer accepts a
`ModpackLibraryEntry`, not an untrusted incoming definition.

Separate preparation from execution: prepare a saved entry into a selectable
plan, then start the confirmed selection as an observable run registered by
pack ID in the in-memory installation manager.

Resolve all items before the dialog when practical. Show a checkable table in
pack order with icon, name, status, source, note indicator, installed state,
version, and dependency warnings. Default-select missing, installable items.
Already installed items remain visible but are not selected. People may uncheck
any item, including one labelled Required, and install only part of the pack.
Add an unchecked Enable installed items after installation option.

After installation starts, the dialog becomes live progress with Close and
Stop. Closing it leaves the installation running. The Modpacks page shows the
same progress, and the person can continue using TriOS. Multiple packs may
install concurrently, but the same pack cannot start twice; opening progress
for it reuses the current installation.

All pack installations share global limits of two downloads and the existing
configurable extraction/install limit of one through six. Schedule work fairly
between packs. Extend the existing downloader to return an awaitable shared
handle with the final normalized address, and move archive inspection plus
selected-ID extraction out of the current batch dialog so both callers use the
same code. An archive must contain the declared mod ID. Install only selected,
declared IDs; ignore and report extra mods. A missing or wrong ID fails that
item and may offer catalog recovery.

Stop means finish active download or install operations safely but start no new
ones. Keep completed installs, do not enable anything automatically, and
discard the in-memory attempt after active work settles. The next Install action
creates a fresh attempt from the pack and current mod list. Installations and
their queues are not restored after restarting TriOS.

Use the normal download and batch-installation path with
`activateVariantOnComplete: false`. The download path itself does not enable
items or rewrite a profile. The confirmation option runs the normal bulk-
enable behavior after the batch finishes.

Keep successful installs when another item fails. A saved pack naturally
continues to show skipped or failed items as missing.

When the installation option is selected, enable every item installed after
the batch, including items that were already installed and items that
succeeded before another download failed. Keep Enable installed items as a
separate confirmed library action as well. Both use normal mod-manager behavior
and dependency checks. If a profile is tracked, the current loadout becomes
Modified under the `explicit-profile-saving` behavior; the profile itself does
not change.

The full pack page shows overall and per-item progress above and within the
item grid and replaces Install with Stop while running. Keep the existing
Activity Panel layout and behavior unchanged.

## Catalog recovery

When an item's source cannot resolve or install, try to find alternatives in
the catalog in this order:

1. The item's saved catalog name, forum topic ID, or Nexus ID.
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
- Extract reusable Mod Manager column definitions and extend WispGrid with
  controlled selection, cross-grid drag data, and variable-height row support.
- Add a shared compact Settings-style labelled text field for editable pack
  metadata.
