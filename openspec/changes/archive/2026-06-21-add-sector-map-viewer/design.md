# Design: Sector Map Viewer (v1)

## Data source: `campaign.xml`

A save folder (`saves/save_*/`) holds a small `descriptor.xml` (already parsed by
`save_reader.dart`) and a large `campaign.xml` (~10 MB, plain ASCII, **not** gzipped). The
latter is a Java **XStream** serialization of the live `CampaignEngine` object graph.

Key facts that drive parsing:

- **Reference graph, not a tree.** `z="N"` defines an object's identity; `ref="N"` is a
  pointer to it. `cl="..."` is the (aliased) class. XStream system attributes are aliased:
  `z`=id, `ref`=reference, `cl`=class.
- **Names are aliased, not raw obfuscation.** The full alias table (844 entries) lives in
  `starsector-core/decompiled_obf/com/fs/starfarer/campaign/save/CampaignGameManager.java`.
  Relevant aliases:
  | Alias | Meaning |
  |---|---|
  | `Sstm` | `StarSystem` (`dN`=displayName, `bN`=baseName, `ty`=type, `mRIH`=maxRadiusInHyperspace) |
  | `Plnt` | `CampaignPlanet` |
  | `COrbt` | `CircularOrbit` (`e`=entity, `f`=focus, `r`=radius, `op`=orbitalPeriod, `ca`=currAngle) |
  | `UFHLOrbt` | `UpdateFromHyperspaceLocation` (`s`=starSystem, `a`=anchorPointInHyperspace) |
  | `Market` | `Market` (children: `<factionId>`, `<size>`, `<surveyLevel>`, `<primaryEntity>`) |
  | `<con>` | `StarSystem.constellation` (child element when non-null) |
  | `loc` / `vel` | 2D vector serialized as `"x|y"` (pipe-separated) |
- **Some payloads are packed JSON.** A planet's `<j0>` holds `{"f0":name,"f2":[r,g,b,a],"f4":spriteId}`.

### What the overview needs (confirmed against a real save)

A system "dot" is assembled from:

- **Position** — anchor on the `UFHLOrbt` (`UpdateFromHyperspaceLocation`) element, which is
  what positions a system in hyperspace. It has `s`=starSystem (ref to a `Sstm`) and
  `a`=anchorPointInHyperspace (a `LocationToken`). The token carries the hyperspace `loc`.
  Resolve `UFHLOrbt.a` → token → `loc` via a `tokenId → loc` map built in the same pass.
  **This is the validated approach** (spike: 244/244 systems positioned on vanilla, ~100% on
  44 vanilla+modded saves). It is topology-agnostic: it works whether the anchor is reached
  via a jump-point `systemPoint` (`<sP cl="LocationToken">`) or the system's own orbit (where
  `s` and `a` are siblings). The earlier "find the `system_anchor`-tagged token" idea was
  abandoned — the tag-based flag under-counts because tokens are reached via field-aliased
  element names (`<sP>`, `<a>`), not a literal `<LocationToken>` tag.
- **Name / type** — from the referenced `Sstm` (`dN`, `bN`, `ty`).
- **Constellation** — `Sstm`'s `<con>` element. A `<con z=N>` defines a constellation with
  `namePick → spec → <name>` and a `<systems>` list; later systems use `<con ref=N>`.
  Note: **procgen systems are defined inside their constellation's `<systems>` list**, while
  core systems are defined directly in `hyperspace/saved` — another reason to anchor on the
  token, not on where the `Sstm` node appears.
- **Star color** — the system's star `Plnt` `<j0>` `f2` RGBA.
- **Ownership (pie slices)** — markets live in a central economy list (`<economy> → <econ>
  → <markets>`), **not** inside the system subtree. Each `Market` carries `{factionId, size}`
  and a `primaryEntity`; join market → system via `primaryEntity → containingLocation
  (<cL cl="Sstm" ref>) → Sstm`, using an `entityId → systemId` index built in the pass.
  Color via `factionColor`; slice angle ∝ `size`. No markets → uninhabited (neutral glyph,
  no ring). **Note (from spike):** vanilla joins 100%, but modded saves can have a few markets
  on deep-space/custom entities with no `cL→Sstm` link — skip these orphans from system pies,
  don't fail the parse.
- **Player marker** — the player fleet's containing location → "you are here".

## Parse strategy: streaming, in an isolate

`XmlDocument.parse` on 10 MB builds a huge DOM and would jank the UI thread. Instead:

- Run on a **background isolate** (`compute`/`Isolate.run`); the file read + parse never
  touch the UI thread.
- Use the `xml` package's **event/streaming** API (`parseEvents`) and a small state machine
  that tracks the current enclosing system. Harvest only: `system_anchor` tokens (position +
  `Sstm` ref), `Sstm` attributes, `<con>` defs/refs, `Market` `{factionId,size}` per system,
  and star `<j0>` color. **Skip** fleets, commodities, officers, conditions, memory — ~95% of
  the bytes, none of it spatial.
- Resolve the handful of refs we keep (anchor→`Sstm`, `con` ref→`con` def) with an id→record
  index built during the same pass; observed map-relevant refs point backward to
  already-seen objects.
- **Degrade gracefully:** unknown `cl` values are ignored, not fatal. A system missing a
  market list is simply uninhabited. Wrap per-system extraction so one bad node can't abort
  the whole parse.

Output: a compact `Sector` model serialized with **dart_mappable** and cached under
`viewer_cache/` keyed by save id + `campaign.xml` mtime, so re-opening is instant. The cache
follows the existing "wipe if invalid, rebuild" convention (rebuild is cheap).

## Model

```
@MappableClass Sector {
  List<SectorSystem> systems;
  List<SectorConstellation> constellations;
  Offset? playerLocation;          // hyperspace coords, for "you are here"
  String gameVersion;              // from descriptor, to detect alias drift
}

@MappableClass SectorSystem {
  String id, name, baseName;
  String? constellationId;
  String type;                     // SINGLE, TRINARY_1CLOSE_1FAR, ...
  Offset hyperLocation;            // from system_anchor token loc
  Color? starColor;                // from j0.f2
  List<SectorMarket> markets;      // pie slices; empty => uninhabited
  bool isKnownToPlayer;            // surveyLevel / fog-of-war styling
}

@MappableClass SectorMarket { String factionId; int size; String name; }
@MappableClass SectorConstellation { String id, name; }   // hull computed from member systems
```

Uses the existing `ColorHook` / vector parsing helpers in `dart_mappable_utils.dart` and
`extensions.dart`.

## Rendering & interaction

Follows the **viewer-page pattern** (page + controller + manager + models). The canvas is a
`CustomPainter`, not a widget tree — ~244 dots + ~25 hulls is trivial to paint.

- **Transform** — pan/zoom via a transformation matrix (manual or `InteractiveViewer`).
  World→screen to draw; screen→world to hit-test. Fit-to-bounds on first load.
- **Dots** — star-color glyph at center; ownership drawn as a pie ring, one slice per market,
  angle ∝ size, color = `factionColor`. Single faction → solid ring. Uninhabited → glyph only.
- **Constellations** — convex hull over member anchor points, faint fill/stroke, name at
  centroid.
- **Player marker** — distinct "you are here" glyph at `playerLocation`.
- **Hover** — `MovingTooltipWidget` card: system name, constellation, type, and the exact
  per-faction market breakdown (the dot only approximates at map scale).
- **Select** — click hit-tests nearest dot, highlights it, opens a side panel
  (`SideRail`/`SideRailPanel`). This click handler is the **hook for the future system
  drill-in**.
- **Search** — `ViewerSearchBox`/`SmartSearchBar` to find and pan-to a system by name.
- **Filter** — by faction, reusing the three-state filter engine.

## Integration points

- `TriOSTools` (`lib/trios/navigation.dart`) — add a `sectorMap` entry; `AppShell` routes it.
- New feature folder `lib/sector_map/` — `sector_map_page.dart`, `sector_map_controller.dart`,
  `sector_map_manager.dart` (isolate parse + cache), `models/`, `widgets/` (painter, tooltip,
  side panel).
- Reuse: `saveFileProvider` (save list), `Faction.factionColor` (faction_viewer),
  `viewer_cache/`, shared viewer widgets, `MovingTooltipWidget`.
- New icon needs a tooltip (project rule: all new icons get tooltips).

## Risks

- **Save-format drift across game versions** — the alias table is version-specific (this is
  0.98a-RC5/RC8). Record `gameVersion`; if parsing yields zero systems or an unexpected shape,
  fail loudly with a clear message rather than render a wrong map.
- **Memory on parse** — must use streaming, not DOM, and stay on the isolate.
- **Modded sectors** (e.g. Nexerelin) — extra/custom systems and entity classes. Anchoring on
  `system_anchor` tokens + ignoring unknown classes should handle these; verify with a modded
  save before calling v1 done.
- **Contested-system color** — resolved: multi-slice pie weighted by market size; full
  breakdown on hover.
