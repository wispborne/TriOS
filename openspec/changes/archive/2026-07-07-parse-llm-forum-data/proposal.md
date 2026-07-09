# Parse the LLM-extracted data in the forum bundle

## Problem

The forum data bundle (`forum-data-bundle.json`, fetched daily from QB's
scraper) gained a new `llm` block on most index entries: structured,
LLM-extracted data about each forum topic. 813 of 996 topics have it, covering
848 mods (a topic can contain several mods). TriOS parses none of it — the
`ForumModIndex` model silently drops the field.

The block contains, per mod:

- **name** and **role** (`main` / `addon` / `separate`)
- **downloads** — 1,070 structured links with label, kind (`trios` / `direct` /
  `mirror`), a resolved direct-download URL, source host, file name, confidence
  (`high` / `medium` / `low`), and whether the link needs a manual step
- **requires** — dependency mod names (98 mods)
- **extras** — version (703), a one-sentence + one-paragraph summary (840),
  changelog entries and/or a changelog link (597), license (92), and support
  links like Patreon/Ko-fi (96)

Two follow-up changes (`catalog-structured-downloads`,
`catalog-ai-summaries`) need this data. This change is the shared foundation:
models and parsing only, no UI.

## Solution

Add dart_mappable models for the `llm` block and parse it as part of the
existing forum index parse. The block lives inside the index entries the app
already decodes, and it is small next to the `details` HTML the parser already
skips, so the catalog hot path stays fast.

## Scope

- New models for the `llm` block and its children (mods, downloads, extras,
  summary, changelog, support links).
- A nullable `llm` field on `ForumModIndex`, parsed defensively so one
  malformed entry can't break the whole bundle.
- A convenience getter for "the main mod of this topic" (first `role: main`
  entry, else the first mod), which both follow-up changes need.
- A parsing test using real-shaped sample data.

## Non-goals

- Any UI. Nothing visible changes.
- The `isMod` flag — the scraper is removing it; we never model it.
- Parsing `assumedDownloads` (superseded by the richer `llm` downloads) or
  changing how `details` is handled.
