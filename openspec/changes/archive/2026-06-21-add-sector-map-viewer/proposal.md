# Add Sector Map Viewer (v1: hyperspace overview)

## Problem

A Starsector save's entire sector — every star system, its constellation, who owns
it — is serialized in `campaign.xml`, but there is no way to see it without launching
the game and loading the save. Players want a quick, out-of-game overview of their
sector (inspired by the community tool at https://nav.birdframe.com/), and TriOS is the
natural home for it: it already lists saves and parses faction data.

## Solution

Add a new **Sector Map** tool that reads `campaign.xml` for a selected save and renders
an **interactive hyperspace overview** — every star system plotted at its hyperspace
position, colored by faction ownership, grouped by constellation.

The save file is a 10 MB Java XStream object graph with aliased tag/field names and
back-references (`z=` defines identity, `ref=` points to it). The full alias table is
available in the bundled decompiled game code
(`starsector-core/decompiled_obf/.../save/CampaignGameManager.java`), so field meanings
are read off rather than guessed. We parse it in a single streaming pass on a background
isolate, extracting only map-relevant data (~tens of KB out of 10 MB) into a small model.

Each system renders as a **pie-chart dot**: one slice per market in the system, weighted
by market size, colored using the existing `Faction.factionColor`. Uninhabited systems
(no markets — the majority) render as a neutral star glyph with no ring. Constellations
draw as faint convex hulls with a name label.

## Scope (v1)

- Read `campaign.xml` for a selected save; parse in an isolate into a sector model.
- New `SectorMap` tool/page registered in `TriOSTools`, following the viewer-page pattern.
- Hyperspace overview render: pan, zoom, faction pie-dots, star-color glyphs,
  constellation hulls + labels, "you are here" player marker.
- Interactivity: hover tooltip (system name, constellation, per-faction market breakdown),
  click-to-select with a side panel, search/jump-to-system, filter by faction.
- Reuse `factionColor` (faction_viewer) for dot colors; cache the parsed model
  (`viewer_cache/`) so re-opening a save is instant.
- Graceful degradation: render what is understood, skip unknown/modded entity classes.

## Non-goals (explicit follow-ons)

- **Drill into a single system** (star + planets + orbits + jump points). The click
  handler is the hook for this, but the in-system view is out of scope for v1.
- **Sprite-accurate rendering.** v1 is schematic (colored dots/glyphs). Real sprites are
  reserved for representing **resources and modifiers** in a later change.
- Live/animated positions — the map is a snapshot at save time.
- Editing the save, fleets, trade/economy detail, intel, or anything non-spatial.
- Modded-save guarantees beyond "don't crash; show what we can."
