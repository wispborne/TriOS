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
the person to update TriOS. The format number describes the encoding and
schema, not the pack's own integer version.

## Shared definition

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

Pack requirements:

- `id`: UUID retained by every later version of the same pack.
- `name`: non-empty display name.
- `version`: positive integer managed by TriOS.
- `mods`: ordered member list with no duplicate mod IDs.

Optional pack fields are `author`, `description`, `gameVersion`, `homepageUrl`,
and `updateUrl`. `gameVersion` is a display label only. It never changes how
TriOS checks compatibility or installs members.

Member requirements:

- `id`: the mod's `mod_info.json` ID.
- `url`: HTTP or HTTPS Version Checker or fixed-download address.
- `sourceType`: `versionFile` or `directDownload`.

Optional member fields are the display `name`, observed mod `version`, a plain-
text creator `note` of at most 2,000 characters, and the catalog recovery
clues. Member order is retained for presentation but has no installation
meaning. Older readers preserve unknown optional fields when comparing,
editing, and exporting a definition. The typed models retain raw unknown keys
alongside known fields instead of letting serialization discard them.

## Integer versions

New packs and copies begin at version 1. TriOS increments the integer once when
Save changes commits a meaningful definition change. Editing a draft does not
increment it by itself. Saving a changed member order, note, Starsector-version
label, source, member list, or other shared field does. A no-op save does not.

Versions only move forward. Publishing older contents as a rollback requires
a new, higher integer.

When an update URL is reachable:

- Higher online version: offer the online update.
- Equal version and equal contents: no update.
- Equal version and different contents: show the comparison and offer Replace
  existing, Add as a copy, or Cancel.
- Lower online version: keep the newer saved or embedded definition.
- Different pack ID: compare and ask whether to replace, add separately, or
  cancel.

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
merge selected fields. The comparison groups changed member sources separately.
Changing the update address requires explicit confirmation before the whole
update is accepted. Added members remain uninstalled until chosen. Removed
members remain on disk and keep their current enabled state.

TriOS exports the current readable definition for the creator to upload. It
does not upload to arbitrary hosts itself.

## Modpack files

A modpack file uses the `.trios-modpack` extension and contains the same strict
definition as readable JSON or Hjson. TriOS writes pretty-printed JSON and
generates the filename from a slug of the pack name. It is not a mod archive.
Dropping or opening one shows a preview with Add to library and Install.
Receipt alone never saves or installs it.

Incomplete drafts are local TriOS data, not valid shareable files. Each pack ID
has its own persisted draft, including new packs that receive an ID as soon as
editing begins. A draft can be saved with unresolved members, but export and
sharing remain blocked.

## Receiving and installing

TriOS shows the embedded definition immediately and starts checking its update
address. A higher online version is identified clearly when the check finishes.
Conflicts and ID changes require a choice. A failed check leaves the embedded
definition available with a warning.

Installation confirmation cannot be disabled for packs. Missing, installable
members are selected by default. People may install only part of the pack.
Successful members remain installed when another fails.

Pack installation uses the normal download and batch-installation services.
Its confirmation includes an unchecked Enable installed members after
installation option. When selected, TriOS enables every member installed after
the batch, including members that were already present, even when another
download failed. The same confirmed action remains available later.

Before Copy share link, Export, or Publish update, TriOS checks every member
source. Version Checker files must parse and resolve to a usable download.
Direct-download sources must begin returning a downloadable file, but TriOS
does not download the complete archive just to validate it. Any failure blocks
the sharing action without blocking local draft saving. A successful check is
reused for 60 minutes when the member's URL and source type have not changed.
Changing either value invalidates the saved result. Failed checks are retried
on the next sharing attempt.

When a source fails, TriOS tries saved catalog clues and exact catalog names.
Likely fuzzy matches are shown for manual selection and are never installed
automatically. Catalog recovery updates the normal mod record but does not
change the pack definition.

## Size limit

TriOS refuses to create or accept a link longer than 30,000 characters. Windows
and Edge fail near 32,000 characters when launching the registered scheme, so
the smaller limit leaves a safety margin. Decoding also stops and rejects the
payload if the definition expands beyond 4 MiB or contains more than 5,000
members. When an outgoing link is too long, the message suggests shortening
the pack description or member notes, removing members, or exporting a
`.trios-modpack` file instead.

A realistic 400-member definition compresses to about 7,000 characters. A
typical pack can hold well over a thousand members.

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
  Starsector-version label and member notes.
- Launches TriOS with the same payload.
- Does not store packs or fetch update addresses.
- Resolves fallback member links only when the person expands that section,
  avoiding hundreds of requests on a large pack preview.
