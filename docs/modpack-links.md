# Modpack links and files

This document defines how a modpack travels between TriLink, TriOS, and an
optional online definition. Product behavior and implementation planning live
in `openspec/changes/modpack-links/`. The player-facing overview is in
[Modpacks](modpacks.md).

## Link forms

A shared browser link points at TriLink:

```text
https://trilink.wispborne.com/open.html#name=Wisps-QoL-Pack&version=3&modpack=1.<payload>
```

TriLink launches TriOS with:

```text
starsector-mod://install?modpack=1.<payload>
```

The browser link stores the pack in the URL fragment. Fragments are not sent
to the web server, so GitHub Pages never receives the long value. The scheme
URL uses a normal query parameter because it does not involve a server.

`name` and `version` are readable decoration. TriLink and TriOS read the
payload as the authority. Editing the decorative values does not change the
pack.

A link carries one install kind. Existing single-mod links use `mod` and
`dep`; modpack links use `modpack`. A link containing both is malformed.

## Payload

The payload is produced in four steps:

1. Serialize the strict shared definition as JSON.
2. Compress it with zlib deflate.
3. Encode it as base64url without padding.
4. Prefix it with `1.`, the payload format number.

Decoding reverses those steps. TriOS refuses unknown format numbers and tells
the person to update TriOS. This transport number describes the compressed
encoding. It is separate from the shared definition's `formatVersion` and the
pack's own integer `version`.

## Shared definition

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

Pack requirements:

- `formatVersion`: shared-definition format, currently `1`.
- `id`: 16 random bytes encoded as exactly 22 unpadded base64url characters,
  retained by every later version of the same pack.
- `name`: non-empty display name.
- `version`: positive JavaScript-safe integer managed by TriOS.
- `items`: non-empty ordered item list with no duplicate case-sensitive mod IDs.

Optional pack fields are `author`, `description`, `gameVersion`, `homepageUrl`,
and `updateUrl`. `gameVersion` is a display label only. It never changes how
TriOS checks compatibility or installs items.

Item requirements:

- `id`: the mod's `mod_info.json` ID.
- `url`: HTTP or HTTPS Version Checker or fixed-download address.
- `sourceType`: `versionFile` or `directDownload`.

Optional item fields are the display `name`, observed mod `version`, a plain-
text creator `note` of at most 2,000 characters, an informational `status`, and
the catalog recovery clues. Status has no default. Required, Recommended, and
Optional are standard labels, and a creator may use a custom single-line label
up to 40 characters. Status never controls installation or validation. Item
order is retained for presentation but has no installation
meaning. Older readers preserve unknown optional fields when comparing,
editing, and exporting a definition. The typed models retain raw unknown keys
alongside known fields instead of letting serialization discard them.

Unknown optional fields in format 1 are ignored safely and preserved. An
unknown `formatVersion` blocks editing, installation, and resharing and asks the
person to update TriOS. Encoding uses fixed known-field order, sorted unknown
object keys, and preserved item order.

## Integer versions

New packs and copies begin at version 1. TriOS increments the integer once when
Save changes commits a meaningful definition change. Editing a draft does not
increment it by itself. Saving a changed item order, status, note,
Starsector-version label, source, item list, or other shared field does. A no-op
save does not. Copy link, Export, and Publish do not change the version.

Versions only move forward. Publishing older contents as a rollback requires
a new, higher integer.

When an update URL is reachable:

- Higher online version: offer the online update.
- Equal version and equal contents: no update.
- Equal version and different contents: show the comparison and offer Replace
  existing, Add as a copy, or Cancel.
- Lower online version: keep the newer saved or embedded definition.
- Different pack ID: treat the hosted definition as a broken update and allow
  adding it only as a separate pack.

The online definition never silently replaces a different pack ID.

## Update address

The optional `updateUrl` points at a readable JSON or Hjson definition hosted
by the creator. TriOS checks it with a cooldown and allows a manual refresh.
TriLink never fetches it; the browser preview always reflects the embedded
snapshot.

The update address does not need to resolve before sharing or export. A creator
must be able to export the first definition before uploading it to that address.
Later update checks report an unavailable or invalid hosted definition without
making the embedded or saved pack unusable.

Accepting an update replaces the saved definition as a whole. TriOS does not
merge selected fields. The comparison groups pack information plus added,
removed, and changed items and calls out source, status, note, and recorded
version changes.
Changing the update address requires explicit confirmation before the whole
update is accepted. Added items remain uninstalled until chosen. Removed items
remain on disk and keep their current enabled state. A draft must be committed,
copied, or discarded before accepting an update.

TriOS exports the current readable definition for the creator to upload. It
does not upload to arbitrary hosts itself.

## Modpack files

A modpack file uses the `.trios-modpack` extension and contains the same strict
definition as readable JSON or Hjson. TriOS writes pretty-printed JSON and
generates the filename from a slug of the pack name. It is not a mod archive.
Dropping or opening one shows a preview with Add to library and Install.
Receipt alone never saves or installs it.

Incomplete drafts are local TriOS data, not valid shareable files. Each pack ID
has its own autosaved draft, including new packs that receive an ID as soon as
editing begins. A draft can be empty or contain unresolved items, but commit,
export, and sharing remain blocked until it is valid.

## Receiving and installing

TriOS shows the embedded definition immediately without contacting its update
address. It checks only after the person asks, adds or accepts the pack, or
starts installation. The embedded definition remains selected while a check
runs, and a late result cannot change an add or installation already in
progress. Conflicts require a choice. A failed check leaves the embedded
definition available with a warning.

Installation confirmation cannot be disabled for packs. Missing, installable
items are selected by default. People may install only part of the pack,
including skipping an item labelled Required. Successful items remain installed
when another fails.

Pack installation uses the normal download and batch-installation services and
runs outside the dialog. Closing the dialog leaves it running and keeps TriOS
usable. Progress remains on the Modpacks page. More than one pack may install at
once, but the same pack cannot start twice.

Stop lets active work finish safely but starts nothing new. It keeps completed
installs, skips automatic enabling, and discards the in-memory attempt after it
settles. Jobs do not survive restart; choosing Install again builds a fresh plan
from the saved pack and current mods.

All pack installations share a fair limit of two downloads and the configured
one-through-six extraction/install limit. An archive must contain its declared
mod ID. TriOS installs only selected declared IDs, ignores and reports extras,
and fails an item whose ID is absent or wrong.

Confirmation includes an unchecked Enable installed items after installation
option. When selected, TriOS enables every pack item installed after the batch,
including items that were already present, even when another download failed.
The same confirmed action remains available later.

Before Copy share link, Export, or Publish update, TriOS checks every item
source. Version Checker files must parse and resolve to a usable download.
Direct-download sources must begin returning a downloadable file, but TriOS
does not download the complete archive just to validate it. Any failure blocks
the sharing action without blocking local draft saving. A successful check is
reused for 60 minutes when the item's URL and source type have not changed.
Changing either value invalidates the saved result. Failed checks are retried
on the next sharing attempt.

Source-check progress appears in a new section on the pack page, not a dialog.
It lists each result, allows cancellation and repair, and finishes the requested
Copy or Export automatically when all sources pass.

When a source fails, TriOS tries saved catalog clues and exact catalog names.
Likely fuzzy matches are shown for manual selection and are never installed
automatically. Catalog recovery updates the normal mod record but does not
change the pack definition.

## Size limit

TriOS refuses to create or accept a link longer than 30,000 characters. Windows
and Edge fail near 32,000 characters when launching the registered scheme, so
the smaller limit leaves a safety margin. Decoding also stops and rejects the
payload if the definition expands beyond 4 MiB or contains more than 5,000
items. When an outgoing link is too long, the message suggests shortening
the pack description or item notes, removing items, or exporting a
`.trios-modpack` file instead.

A realistic 400-item definition compresses to about 7,000 characters. A
typical pack can hold well over a thousand items.

Windows may rewrite `install?` as `install/?` while launching TriOS. The scheme
parser accepts both forms.

## Responsibilities

TriOS:

- Creates, edits, saves, compares, exports, and installs packs.
- Generates the browser link and registered-scheme payload.
- Checks update addresses and performs catalog recovery.
- Always confirms pack installation.

TriLink:

- Decodes and previews the embedded definition in the browser, including its
  Starsector-version label, item statuses, and item notes.
- Launches TriOS with the same payload.
- Does not store packs or fetch update addresses.
- Resolves fallback item links only when the person expands that section,
  avoiding hundreds of requests on a large pack preview.
