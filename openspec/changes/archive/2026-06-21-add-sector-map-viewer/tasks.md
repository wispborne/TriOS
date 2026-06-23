# Tasks: Sector Map Viewer (v1)

## 1. Spike — confirm the parse end to end ✅
- [x] Write a throwaway Dart test that streams `campaign.xml` (`parseEvents`) and prints:
      system count, a few `{name, hyperLocation, constellation}`, and per-system markets.
      (`test/sector_map_parse_spike_test.dart`)
- [x] Verify systems are fully covered + joins resolve. Result: **244/244** systems
      positioned on vanilla via the `UFHLOrbt` anchor approach (NOT the `system_anchor` tag —
      see design.md); markets join via `primaryEntity → cL → Sstm` with 0 orphans on vanilla;
      constellations resolve. Parse 9.8 MB in ~260 ms.
- [x] Verify across **all 44 saves** in the folder (incl. modded): every save positions
      ≥99.6% of systems and joins >99% of markets. Finding: modded saves may leave a few
      markets orphaned (deep-space/custom entities) — real parser must skip them gracefully.

## 2. Model
- [x] Add `lib/sector_map/models/` with `Sector`, `SectorSystem`, `SectorMarket`,
      `SectorConstellation` as `@MappableClass`. (`lib/sector_map/models/sector.dart`)
      Decision: store position as `double x,y` and star color as `List<int>` rgba (like
      `Faction.color`) — primitives, so no Offset/Color hooks needed; getters expose
      `Offset`/`Color` to the UI.
- [x] Run build_runner (regenerated `sector.mapper.dart` + `navigation.mapper.dart`).

## 3. Parser + manager ✅
- [x] `sector_map_parser.dart`: pure top-level `parseCampaignXml`, ported from the validated
      spike. Anchors via `UFHLOrbt`; markets via `primaryEntity → cL → Sstm`; star color from
      star-tagged `Plnt.j0.f2`; player marker from `<playerFleet ref>`.
- [x] `sector_map_manager.dart`: reads `campaign.xml`, parses on `Isolate.run`, exposes
      `sectorMapProvider` (family by save). Ignores unknown classes / missing fields; skips
      orphan markets; throws clearly on 0 systems (records `gameVersion`).
- [x] Faction color + name reuse: `factionColorsProvider` / `factionNamesProvider` from
      faction_viewer, with title-cased fallback for modded faction ids.
- [~] Disk cache deferred: parse is ~260 ms, so v1 uses the in-memory `family` provider
      (instant re-open within a session). Cross-session disk cache is a noted follow-on.

## 4. Page scaffold + navigation ✅
- [x] Added `sectorMap` to `TriOSTools`, all switches, nav order, and `AppShell` routing.
- [x] Tool icon (`Icons.scatter_plot`) with tooltip via the nav `.tooltip` (project rule).
- [x] `sector_map_page.dart` (`ConsumerStatefulWidget` + `AutomaticKeepAliveClientMixin`) +
      `sector_map_controller.dart` (`Notifier`). Save picker from `saveFileProvider`
      (auto-selects most recent).

## 5. Render — hyperspace overview ✅
- [x] `SectorMapPainter` + `SectorViewTransform` (world↔screen, y-flipped); fit-to-bounds on
      first layout and on save switch.
- [x] Star-color glyph per system (filled if inhabited, hollow if not).
- [x] Faction **pie ring** per inhabited system (slice angle ∝ market size, color via
      `factionColor`); single faction = solid ring.
- [x] Constellation convex hulls (faint) + name labels at centroid.
- [x] "You are here" player marker (chevron).

## 6. Interaction ✅
- [x] Pan (drag) + zoom (wheel toward cursor, pinch).
- [x] Hover → tooltip card (`TooltipFrame`): name, constellation, type, per-faction breakdown.
- [x] Click → hit-test nearest dot, select + highlight, open `SystemDetailPanel`. The
      `onSelect`/detail panel is the marked hook for the future system drill-in.
- [x] Search box → find + recenter on a system by name.
- [x] Faction filter (popup checklist) dimming non-matching inhabited systems. (Used a simple
      toggle-off model rather than the 3-state engine — lighter for a single-color-per-faction
      filter; can swap to the engine later.)

## 7. Polish & verify
- [x] Empty/error states: no save selected, loading spinner, parse-failure message.
- [x] `flutter analyze` clean (0 errors) + `custom_lint` clean for touched files.
- [x] Regression test against all local saves (`test/sector_map_parser_test.dart`, guarded/
      skips on CI).
- [ ] **User to verify in-app**: faction pie colors, constellation grouping, player marker,
      pan/zoom/hover/select/search across a vanilla and a modded save. (I don't run the app.)
