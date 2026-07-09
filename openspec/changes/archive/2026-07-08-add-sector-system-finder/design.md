# Design — Sector System Finder

References: [proposal.md](proposal.md). Builds on the shipped Sector Map viewer in
`lib/sector_map/` (archived change `2026-06-21-add-sector-map-viewer`).

## Overview

Three layers, each extending what already exists:

```
  campaign.xml ──▶ parser (extended) ──▶ Sector model (extended)
                                              │
                                              ▼
                              matching + scoring engine (new)
                                              │
                  ┌───────────────────────────┴───────────────────┐
                  ▼                                                ▼
         Phase 1: live COUNT                          Phase 2: escalating HINT
         (knob panel + presets)                       (constellation → system ladder)
```

The atlas render that exists today is unchanged as a renderer; it just stops being the
default and becomes the final rung of the hint ladder / an overflow item.

## 1. Data model changes (`lib/sector_map/models/sector.dart`)

Add per-planet condition data and landmarks. Keep it minimal — only what matching needs.

- `SectorSystem` gains:
  - `List<SectorPlanet> planets` — each planet's condition list, type, and computed hazard.
  - Derived helpers: `bool get hasHabitable`, `int get stableLocationCount`,
    `int get planetCount`. (Stable locations are entities in the system, not planets —
    counted during parse.)
- New `SectorPlanet`:
  - `String type` (e.g. `lava`, `terran`), `List<String> conditionIds` (the raw `<st>`
    tokens), `double hazardRating` (computed at parse time, see §2).
- New `SectorLandmark`:
  - `String typeId` (e.g. `derelict_cryosleeper`, `inactive_gate`, `coronal_tap`),
    `String name`, `String systemId`. Position comes from the system it sits in (we already
    position systems), so "nearby" is system-to-system distance.
- `Sector` gains `List<SectorLandmark> landmarks`.

All `@MappableClass`, regenerate `sector.mapper.dart` via `build_runner`. The viewer cache
on disk is just wiped if the shape changes (no versioning needed — rebuilds in seconds).

## 2. Parser changes (`lib/sector_map/sector_map_parser.dart`)

The parser already walks every element and joins entities to systems via
`cL cl="Sstm"`. Extend the existing single streaming pass — do **not** add a second pass.

- **Conditions** (TWO formats — confirmed against a real save, both must be read):
  - `PCMarket` (uninhabited planets): a `<cond>` child holding a flat list of `<st>`
    condition-id tokens.
  - Full `Market` (inhabited planets): a `<conditions>` child holding `<MCon i="…">`
    objects — the id is the `i=` attribute, not text.
  The current code collects markets only when `marketFactionId != null`; extend it to read
  whichever condition form is present on any market. Attach to the market's `primaryEntity`,
  which already resolves to a system via `entityToSystem`. Group captured planets by system
  into `SectorPlanet`s. (Confirmed: conditions are present even when `surveyLevel` is NONE or
  absent — 721 condition blocks vs 169 survey tags in the sample save — so the finder sees
  unsurveyed planets.)
  - A planet's `<type>` is a direct child of the `Plnt` frame (seen in real saves alongside
    `<radius>`, `<angle>`).
- **Stable locations**: count entities whose type id / tag marks them as a stable location,
  keyed by their containing system. (Confirm the exact marker against a real save —
  `stable_location` appears 1200+ times; verify whether it is an entity `customEntityId`
  or a tag.)
- **Landmarks**: entities (`CCEnt`) whose `j0.f3` type id is one of the landmark ids
  (`derelict_cryosleeper`, `inactive_gate`, `coronal_tap`, …). Read `j0.f0` for the name and
  the existing `cL cl="Sstm"` link for the system. Reuse `_colorFromJ0`-style blob parsing.
- **Hazard**: no stored number is in the save, and (confirmed) **`planets.json` has no
  hazard field** — planet type does not add hazard directly. Hazard is `1.0` base plus the
  sum of each present condition's delta from `condition_gen_data.csv`, no minimum clamp.
  Compute `hazardRating` from `conditionIds` alone, using the exact constant table in
  [hazard-reference.md](hazard-reference.md), encoded as a `const Map<String, double>` in a
  new `lib/sector_map/finder/hazard.dart`. Conditions not in the map contribute 0 (correct
  best-effort for modded conditions, per non-goals). Resources contribute 0.

Keep graceful degradation: unknown classes/conditions are ignored, never fatal.

## 3. Matching + scoring engine (`lib/sector_map/finder/`)

Pure Dart, no Flutter — testable in isolation, runnable off the UI thread if needed.

- `FinderCriteria` (`@MappableClass`, persisted): the full knob state —
  - `Map<String, ResourceCriterion> resources` where `ResourceCriterion` =
    `{ TierFloor? floor, double weight }` (floor optional/hard, weight 0..1 soft).
  - hard toggles: `bool? mustBeHabitable`, `bool? mustHaveGasGiant`,
    `int? minStableLocations`, plus a `Map<String, bool> landmarkNearby` keyed by landmark
    type id with `double nearbyRangeLy` (default ≈ 10).
  - `DistanceFromCore` preference (slider; neutral allowed).
  - `Map<String, bool> otherConditionToggles` — the raw modded-condition escape hatch.
- `FinderEngine`:
  - `filter(Sector, FinderCriteria) → List<ScoredSystem>` — applies hard floors/toggles
    (best-of across planets: a resource floor passes if any planet meets the tier; a
    condition toggle passes if any planet has it), landmark proximity (min system-to-system
    distance ≤ range), then scores survivors:
    `score = Σ slider.weight × bestPlanetValue(criterion)` normalized to 0..1.
  - `matchCount(Sector, FinderCriteria) → int` — count of survivors (drives Phase 1).
  - `bottleneck(Sector, FinderCriteria) → List<{toggle, countIfRemoved}>` — for the
    zero-match helper: re-run filter with each single hard constraint relaxed, report which
    relaxations unlock matches.
- **Tier vocabulary**: a constant table mapping condition ids to `(family, tier index)`,
  e.g. `ore_sparse→(ore,1) … ore_ultrarich→(ore,5)`. Drives both floors and best-of value.

## 4. Knob vocabulary & presets (`lib/sector_map/finder/finder_catalog.dart`)

- **Curated vanilla knobs**: the resource families above, the known colony-relevant
  conditions (habitable, hot/cold ladders, tectonic, atmosphere, gravity, …), and the
  landmark ids — each with a nice label and, for resources, tier ordering. This is the
  hard-coded "polished" half of mod-option **C**.
- **Other conditions (option C escape hatch)**: at load, collect every distinct condition
  `<st>` id present in the loaded `Sector` that is **not** in the curated catalog. Render
  these as plain on/off toggles in a separate "Other conditions" section, labeled by their
  raw id. Robust to any mod with zero per-mod work.
- **Presets**: a small list of named `FinderCriteria` literals (Colony Hunter, Resource
  Baron, Cryosleeper Nearby, Self-Sufficient, …). A preset button just replaces the current
  criteria; the player then tweaks freely.

## 5. UI

Page state lives in the existing controller pattern
(`sector_map_controller.dart` → a `Notifier`/persisted-state pair). Add a mode enum:
`SectorMapMode { finder, atlas }`, defaulting to `finder`.

- **Knob panel** (`lib/sector_map/finder/widgets/finder_panel.dart`): preset buttons row;
  a resource section where each row is `[label] [min-tier dropdown] [weight slider]` (both
  always shown, per the decision); a toggles section; a landmark-proximity section; the
  distance-from-core slider; and a collapsible "Other conditions" section. Follow the 8dp
  grid, `spacing:` on Row/Column, `MovingTooltipWidget.text` for every new icon.
- **Count bar**: a prominent live "N systems fit" readout, debounced (reuse `Debouncer`)
  as knobs change. When N = 0, show the bottleneck hints inline.
- **Reveal / Hint ladder** (`lib/sector_map/finder/widgets/hint_ladder.dart`): a single
  **Hint** button. Internal `revealLevel` 0→max. Each click advances:
  `0` none → `1` "somewhere in these K constellations" (K from a reveal-breadth setting,
  default 3–5) → narrowing K → single constellation → exact system → (final) hand off to the
  **atlas render centered on that system**. A "Show a different match" action steps to the
  next-best `ScoredSystem` and resets `revealLevel`.
  - The constellation blur reuses the existing constellation hull rendering, lit for the
    revealed set only; lower rungs progressively un-blur.
- **Atlas access**: overflow menu item "Show everything (spoiler)" jumps straight to
  `SectorMapMode.atlas` (the current full render). This is the same destination as clicking
  Hint to the bottom.

## Key decisions

- **Two phases enforced by the UI, not the engine.** The engine can always compute exact
  matches; Phase 1 simply never renders positions. This keeps the spoiler from leaking by
  accident and keeps the engine simple/testable.
- **Best-of, system as unit.** Matching always reduces planet-level data to a per-system
  yes/value via "any planet" (toggles/floors) or "best planet" (scoring). Simpler than
  per-planet match sets and matches how players think about a system.
- **Hazard computed, not read.** Accepted because the formula is known and the save lacks a
  stored value; modded conditions are best-effort (non-goal).
- **Mod robustness via the raw section, not per-mod config.** Option C: curated where we
  can, raw passthrough everywhere else. No mod-specific code paths.
- **Reveal order = soft-slider score.** The sliders' only job in Phase 2 is to decide which
  match is "best" and therefore revealed first.

## Risks / unknowns to resolve during apply

- Exact in-XML marker for **stable locations** (entity id vs tag) — verify against a real
  save before wiring the count.
- ~~The hazard delta table~~ — **resolved**: exact base, formula, and per-condition values
  captured in [hazard-reference.md](hazard-reference.md) from the 0.98a-RC8 game data.
- **Landmark benefit radius** default — the LY **unit conversion is confirmed**: distance
  in LY = `saveUnits / unitsPerLightYear`, default **2000** units/LY (`Misc.getDistanceLY`,
  `Settings.getUnitsPerLightYear`). The same conversion serves distance-from-core. Still to
  confirm: the exact cryosleeper/coronal-tap *range number* (in `Cryorevival`) used as the
  "nearby" default, rather than 10 LY from memory.
- Performance of re-filtering on every knob drag for large modded sectors — debounce, and
  if needed precompute per-system condition sets once per loaded `Sector`.
