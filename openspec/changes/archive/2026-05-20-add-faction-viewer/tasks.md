# Faction Viewer -- Tasks

## 1. Data Model

- [x] 1.1 Create `lib/faction_viewer/` feature directory
- [x] 1.2 Define `Faction` model (`@MappableClass`, implements `WispGridItem`) with all fields: id, displayName, color, logo, crest, showInIntelTab, doctrine, blueprint ID lists, blueprint tag lists, portraits, illegalCommodities, customFlags, music, sources, sectionAttributions
- [x] 1.3 Define `FactionDoctrine` model (`@MappableClass`) with warships, carriers, phaseShips, officerQuality, shipQuality, numShips, shipSize, aggression, combatFreighterProbability, autofitRandomizeProbability
- [x] 1.4 Define `FactionSource` and `SourceContribution` models
- [x] 1.4b Add `itemAttributions: Map<String, Map<String, String>>` field to `Faction` (maps sectionKey → {itemId → sourceName}, skipped during serialization)
- [x] 1.5 Run `dart run build_runner build --delete-conflicting-outputs`

## 2. Merge Logic

- [x] 2.1 Implement `mergeFactionData(base, overlay, sourceName)` -- arrays additive, scalars replace, objects recurse, handle `core_clearArray`, handle color/music replacement
- [x] 2.2 Implement per-section attribution tracking (snapshot array lengths before/after merge, record delta per source)
- [x] 2.3 Implement per-item attribution tracking (`itemAttributions: Map<String, Map<String, String>>`) -- tags each individual array item to its source during merge, handles `core_clearArray` by clearing item attributions before re-tagging
- [x] 2.4 Write unit tests for merge logic: additive arrays, scalar override, core_clearArray, recursive object merge, attribution counts

## 3. Data Layer (Manager + Provider)

- [x] 3.1 Create `FactionListNotifier` extending `CachedStreamListNotifier<Faction, FactionsCachePayload>`
- [x] 3.2 Implement `parseVanilla()` -- scan `{gameCoreFolder}/data/world/factions/*.faction`, parse JSON with comments, build base Faction objects
- [x] 3.3 Implement `parseVariant()` -- scan mod faction files, merge into existing factions or create new ones, track sources
- [x] 3.4 Define `FactionsCachePayload` for msgpack caching
- [x] 3.5 Create `factionListNotifierProvider`
- [x] 3.6 Run build_runner, verify `dart analyze` passes

## 4. Navigation

- [x] 4.1 Add `factions` to `TriOSTools` enum in `NavGroup.viewers`
- [x] 4.2 Wire up in `AppShell` tab routing

## 5. Controller + State

- [x] 5.1 Create `FactionViewerState` (ephemeral: search query, filtered list)
- [x] 5.2 Create `FactionViewerStatePersisted` (view mode, filter toggles, grid state, faction theming toggle) with `@MappableClass`
- [x] 5.3 Create `FactionViewerController` (`Notifier<FactionViewerState>`) with filtering and search logic
- [x] 5.4 Run build_runner

## 6. Gallery View

- [x] 6.1 Create `FactionViewerPage` (`ConsumerStatefulWidget` with `AutomaticKeepAliveClientMixin`)
- [x] 6.2 Add `ViewerToolbar` with count, search, and gallery/grid toggle
- [x] 6.3 Add filter sidebar with "Show hidden factions" and "Show mod factions" toggles
- [x] 6.4 Create `FactionCard` widget -- logo, name, color bar, key stats, source badge
- [x] 6.5 Implement gallery layout with `GridView.builder` using `FactionCard`

## 7. Grid View

- [x] 7.1 Define WispGrid columns: logo, name, color swatch, doctrine stats, blueprint counts, source (deferred — needs WispGrid integration study)
- [x] 7.2 Wire WispGrid into the page with grid state persistence (deferred — depends on 7.1)

## 8. Profile Dialog

- [x] 8.1 Create `FactionProfileDialog` scaffold -- header section with logo, crest, name, color swatch, ship prefix
- [x] 8.2 Add faction-colored theming using `ColorScheme.fromSeed` with faction color, wrapped in `Theme` widget
- [x] 8.3 Add overflow menu button to toggle faction theming on/off (persisted)
- [x] 8.4 Add doctrine section with visual bars (0-5 scale)
- [x] 8.5 Add fleet overview section -- expandable blueprint lists per category with inline thumbnails
- [x] 8.6 Add per-asset source grouping in blueprint lists -- when multiple sources contribute, items are grouped by source mod with subtle `labelSmall` headers; single-source sections remain flat
- [x] 8.7 Add cross-reference navigation -- tapping a ship/weapon/hullmod opens it in its viewer
- [x] 8.8 Add portraits section -- thumbnail grid loaded via Image.file
- [x] 8.9 Add behavior flags section -- Wrap of Chips for interesting custom flags
- [x] 8.10 Add source section -- list of contributing mods

## 9. Image Loading

- [x] 9.1 Implement faction logo/crest path resolution (modFolder or gameCoreFolder + relative path)
- [x] 9.2 Add fallback placeholder for missing images

## 10. Verification

- [ ] 10.1 Manual test: gallery shows vanilla factions with logos and stats
- [ ] 10.2 Manual test: grid view sorts by doctrine values and blueprint counts
- [ ] 10.3 Manual test: profile dialog opens with correct data and faction-colored theme
- [ ] 10.4 Manual test: toggling faction theming off falls back to app theme
- [ ] 10.5 Manual test: hidden factions filter works (Remnants, Omega hidden by default, visible when toggled)
- [ ] 10.6 Manual test: mod factions appear with correct source attribution
- [ ] 10.7 Manual test: merged faction shows items grouped by source mod (e.g. "Vanilla" header with vanilla ships, "ModName" header with mod ships)
- [ ] 10.8 Manual test: expanding blueprint list shows thumbnails, clicking navigates to viewer
- [ ] 10.9 Manual test: search filters factions by name
- [x] 10.10 `dart analyze` passes with zero errors
