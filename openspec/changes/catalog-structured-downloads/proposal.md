# Structured downloads on the catalog page

**Depends on:** `parse-llm-forum-data`

## Problem

The catalog card's download button only knows two tricks: a single direct
download URL from the scraped catalog, or "open the website." The forum bundle
now supplies 1,070 structured download links across 848 mods, and the button
uses none of them. Three things are left on the table:

1. **"Install With TriOS" deep links.** 10 links are `trilink.wispborne.com`
   URLs — TriOS's own install links, carrying the mod's version-file URL *and
   its dependencies*. Clicking one today would pointlessly round-trip through
   a web page designed to launch the app the user is already in.
2. **More one-click downloads.** Many mods that today only open a website have
   a usable direct link in the new data, complete with a pre-resolved download
   URL and a confidence rating.
3. **Multiple links per mod.** 130 mods have two or more links, and picking
   automatically is genuinely unsafe — e.g. one mod's two "high confidence"
   links are the full download and a *patch* archive. The user needs a way to
   see and choose.

## Solution

Build a prioritized list of download candidates per mod and use it everywhere
a download starts on the catalog page:

- **Priority order (kind first, confidence second):**
  1. `trios` deep links — always top, regardless of confidence. Handled
     in-app: translated to the existing `starsector-mod://` deep link flow
     (dependency install, version checks, already-installed detection — all
     already built).
  2. The scraped catalog's existing direct download URL (today's behavior,
     unchanged in rank so existing mods keep working identically).
  3. `direct` links from the forum data, high → medium → low confidence.
  4. `mirror` links, same confidence ordering.
  5. Website link (today's fallback).
- **The card's download button** runs the best candidate. When several
  candidates tie at the winning tier, clicking shows a small menu to pick
  from instead of guessing.
- **The card's right-click menu** gains a "Downloads" list showing *all*
  links with their labels (e.g. "Patch (0.3.1 → 0.3.1b)"), source host, and
  kind.
- **The forum post dialog** gains a Downloads section listing every link,
  grouped per mod when a topic contains several.
- Links flagged `requiresManualStep` are never one-click downloaded; they
  open in the browser.

## Scope

- Candidate resolution logic (pure function over scraped mod + forum LLM data).
- Trilink → `starsector-mod://` translation and a public entry point on the
  existing deep link handler.
- Card download button: best candidate + tie menu.
- Card context menu: full downloads list.
- Forum post dialog: downloads section.

## Non-goals

- Changing how the download itself works (the existing download manager and
  confirmation flow are reused as-is).
- Using the `requires` dependency names from the forum data (separate,
  later change — trios links carry their own dependency info).
- Surfacing downloads for `addon`/`separate` mods on the *card* (the card
  represents the main mod; addons appear in the dialog's grouped list).
- Any change outside the catalog page (e.g. the Mods page dependency buttons).
