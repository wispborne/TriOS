# Tasks — Sector System Finder

Ordered by dependency. See [design.md](design.md).

## Verify game-data assumptions (do first)

> **Findings (verified against real 0.98a-RC5 saves, 2026-06-23):**
> - **No `PCMarket` / `<cond>/<st>` format exists.** ALL conditions are `<MCon i="id">`
>   elements inside a `<market cl="Market">` that is **nested inside the owning `Plnt`**.
>   Planet `<type>` is a direct child of `Plnt`. So the parser attaches conditions + type
>   to the nearest enclosing `Plnt` — single format, no second pass. (Design's two-format
>   assumption was outdated; simplified accordingly.)
> - **Stable locations & landmarks are both `CCEnt`** identified by their `j0.f3` type id
>   (`stable_location`, `derelict_cryosleeper`, `inactive_gate`, `coronal_tap`). `j0.f0` is the
>   display name; system join is the existing `<cL cl="Sstm">`.
> - **`unitsPerLightYear` = 2000** (settings.json). Cryosleeper "nearby" default = **10 LY**
>   (well-known vanilla growth-bonus radius; exact constant not in decompiled_obf — best-effort,
>   widenable per design).

- [x] Confirm the in-XML marker for **stable locations** — `CCEnt` with `j0.f3 == "stable_location"`.
- [x] Confirm the **landmark type ids** — `derelict_cryosleeper`, `inactive_gate`, `coronal_tap`; `j0.f0`=name, `j0.f3`=type id.
- [x] ~~Transcribe the hazard base + per-condition delta table~~ — done; see [hazard-reference.md](hazard-reference.md) (base 1.0 + sum of `condition_gen_data.csv` deltas; planet type adds none).
- [x] Confirm the game's **cryosleeper / coronal-tap benefit radius** — `unitsPerLightYear`=2000; nearby default 10 LY.
- [x] Enumerate the curated **condition vocabulary** — resource tiers (ore/rare_ore 1–5, organics/volatiles/farmland 1–4) + colony conditions from `condition_gen_data.csv`.

## Data model

- [x] Add `SectorPlanet { type, conditionIds, hazardRating }` to `models/sector.dart`.
- [x] Add `SectorLandmark { typeId, name, systemId }`.
- [x] Extend `SectorSystem` with `planets` and derived helpers (`hasHabitable`, `stableLocationCount`, `planetCount`); extend `Sector` with `landmarks`.
- [x] Run `build_runner` to regenerate `sector.mapper.dart`.

## Parser

- [x] Capture each market's conditions — **only the `<conditions><MCon i="id"/></conditions>` format exists** in real 0.98a saves (no `PCMarket`); the market is nested inside the `Plnt`, so conditions attach to the nearest enclosing `Plnt` → system, grouped into `SectorPlanet`s.
- [x] Capture planet `<type>` for each planet frame.
- [x] Count stable-location entities per system (`CCEnt` with `j0.f3 == "stable_location"`).
- [x] Capture landmark entities (`CCEnt` with matching `j0.f3`) → `SectorLandmark` with name + system.
- [x] Add `lib/sector_map/finder/hazard.dart` (const map from [hazard-reference.md](hazard-reference.md)) and compute `hazardRating` per planet as `1.0 + Σ condition deltas` during assembly.
- [x] Update/extend `test/sector_map_parser_test.dart` to assert conditions, planets, hazard, stable-location counts, and landmarks parse from a fixture save.

## Matching + scoring engine (`lib/sector_map/finder/`)

- [x] Add the tier vocabulary table (condition id → family + tier index) and curated catalog in `finder_catalog.dart`.
- [x] Add `FinderCriteria` model (`@MappableClass`, persistable): resource floor+weight rows, hard toggles, landmark-nearby map + range, distance-from-core, other-condition toggles.
- [x] Implement `FinderEngine.filter()` — hard floors/toggles (best-of), landmark proximity (system-to-system distance), then best-of weighted scoring → `ScoredSystem` list sorted by score.
- [x] Implement `FinderEngine.matchCount()`.
- [x] Implement `FinderEngine.bottleneck()` for the zero-match helper.
- [x] Unit-test the engine: floors, toggles, best-of across planets, landmark range, scoring order, and bottleneck output.

## Presets & mod escape hatch

- [x] Define preset `FinderCriteria` literals (Colony Hunter, Resource Baron, Cryosleeper Nearby, Self-Sufficient, …).
- [x] At load, derive the "other conditions" list = condition ids present in the `Sector` but absent from the curated catalog.

## UI — finder mode

- [x] Add `SectorMapMode { finder, atlas }` to the page controller/state, defaulting to `finder`; persist criteria + mode with page state (`Settings.sectorMapPageState`, debounced). Reveal level/match index stay ephemeral per session by design.
- [x] Build `finder_panel.dart`: preset row; resource rows (`label + min-tier dropdown + weight slider`, both always shown); toggles section; landmark-proximity section; soft-preference sliders (low hazard, close to core); collapsible "Other conditions" section. 8dp grid, `spacing:`, `MovingTooltipWidget.text` on icons/controls.
- [x] Build the live **count bar** — shown in the hint card ("N systems fit"); engine memoized per sector via `finderEngineProvider` so re-filtering on each knob change is cheap. Bottleneck hints shown when count is 0.

## UI — reveal / hint ladder

- [x] Build `hint_ladder.dart`: a **Hint** button with `revealLevel` 0→max stepping constellations-set → narrower → single constellation → exact system → atlas-centered-on-match.
- [x] Reuse constellation hull rendering (`SectorMapPainter.convexHull`) to light only the revealed set; progressively un-blur via `ImageFiltered` on each click.
- [x] Add "Show a different match" to step to the next-best `ScoredSystem` and reset reveal level.
- [x] Add overflow-menu item "Show everything (spoiler)" → `SectorMapMode.atlas`.

## Wire-up & polish

- [x] Route the page so finder is the default and the atlas render is reachable via the ladder's final step and the overflow item (plus a "Finder" button back from atlas).
- [x] Wipe/ignore stale viewer cache on the new model shape — **N/A**: the sector is re-parsed on each load (no on-disk cache exists), so a shape change can't go stale.
- [x] `flutter analyze` + `dart run custom_lint` clean (no issues in changed files); `flutter test` green (368 passing).
- [ ] Manual check against a real save (let the user verify in-app per project convention — cannot run the app here).
