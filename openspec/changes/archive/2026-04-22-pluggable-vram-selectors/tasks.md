## 1. Extract selector seam without behavior change

- [x] 1.1 Add `lib/vram_estimator/selectors/vram_asset_selector.dart` with the sealed `VramAssetSelector` interface, `SelectedAsset` record, and `AssetProvenance` enum
- [x] 1.2 Add `VramCheckerContext` (or reuse existing plumbing) to pass progress/verbose sinks, cancellation, and graphics-lib entries into selectors
- [x] 1.3 Create `lib/vram_estimator/selectors/folder_scan_selector.dart` and move the current file-enumeration + `UNUSED_INDICATOR` filtering + `MapType` tagging into it; it always emits `provenance = referenced`
- [x] 1.4 Move `_getGraphicsLibSettingsForMod` into a shared helper `lib/vram_estimator/selectors/references/graphicslib_references.dart` so both selectors can use it
- [x] 1.5 Preserve GraphicsLib-mod-specific `cache/` hardcode inside the shared helper
- [x] 1.6 Update `VramChecker` to accept an optional `selector` parameter defaulting to `FolderScanSelector()`; replace the inline per-file inclusion logic with a call to `selector.select(...)`
- [ ] 1.7 Spot-check totals for three mods (small, GraphicsLib, large content) — totals MUST match pre-refactor numbers byte-for-byte

## 2. Model changes for the two-bucket shape

- [x] 2.1 Add `final ModImageTable? unreferencedImages;` to `VramMod` with the `@MappableField(hook: ModImageTableHook())` annotation
- [x] 2.2 `build_runner` completed successfully after fixing stray `}` in `graphicslib_references.dart`
- [ ] 2.3 Verify an old persisted cache (with no `unreferencedImages` field) decodes with `unreferencedImages == null`
- [x] 2.4 Update aggregate helpers (`ModListExt.getBytesUsedByDedupedImages`, anything in `vram_estimator_manager.dart`) so they only ever sum `images`, never `unreferencedImages`, and confirm they still compile

## 3. Path normalization and reference parser scaffolding

- [x] 3.1 Add `lib/vram_estimator/selectors/path_normalizer.dart` with a normalizer that lowercases, forward-slash-normalizes, strips leading `/`, and emits both with-extension and without-extension forms for reference paths
- [x] 3.2 Define `ReferenceParser` interface (`String id`, `String displayName`, `Future<Set<String>> collect(VramCheckerMod mod, List<_FileData> allFiles)`) under `lib/vram_estimator/selectors/references/reference_parser.dart`
- [~] 3.3 Convention comment in place in `reference_parser.dart`; per-parser unit tests added in tasks 4.6, 5.6, 5.7

## 4. Per-source reference parsers

- [x] 4.1 `ship_references.dart` — parse `data/hulls/*.ship` (JSON `spriteName`) and `data/hulls/ship_data.csv` (`sprite name` column)
- [x] 4.2 `weapon_references.dart` — parse `data/weapons/*.wpn` (JSON sprite fields), `data/weapons/proj/*.proj` (JSON sprite fields), and `data/weapons/weapon_data.csv`
- [x] 4.3 `faction_references.dart` — parse `data/world/factions/*.faction` for `logo`, `crest`, `portraits` arrays
- [x] 4.4 `portrait_references.dart` — parse `data/characters/portraits/portraits.csv`
- [x] 4.5 `settings_graphics_references.dart` — parse `data/config/settings.json` `graphics` block (category → id → path)
- [x] 4.6 Unit tests for each parser against a fixture mod-tree with known inputs/outputs (ship, weapon, faction, portrait, settings-graphics, graphicslib + PathNormalizer — under `test/vram_estimator/`)

## 5. JAR + loose Java string extraction

- [x] 5.1 Added `archive: ^4.0.9` as a direct dep in `pubspec.yaml` (it was transitive only)
- [x] 5.2 Added `jar_string_references.dart` — scans entire mod for `*.jar`, parses class constant pools
- [x] 5.3 Added `java_source_references.dart` — scans entire mod for `*.java`, regex-extracts literals, strips comments
- [x] 5.4 `_scripting_filter.dart` — shared retain/prefix logic for both scripting extractors
- [x] 5.5 Directory-prefix expansion implemented inside both extractors against pre-computed on-disk image list
- [x] 5.6 Unit test the JAR extractor — builds class-file bytes + zip in-test; covers literal paths, directory prefixes, malformed jar, and non-class entries
- [x] 5.7 Unit test the Java extractor — covers path literals, directory-prefix expansion, line/block comment stripping, escaped quotes, and filtered noise
- [~] 5.8 Extractors use sync `readAsBytesSync` / `readAsStringSync` which close immediately — no explicit `maxFileHandles` wrap needed. Revisit if jar counts get pathological.

## 6. ReferencedAssetsSelector

- [x] 6.1 Created `lib/vram_estimator/selectors/referenced_assets_selector.dart`
- [x] 6.2 `_allParsers` list at top with the explicit `// ADD NEW REFERENCE PARSERS BELOW` marker
- [x] 6.3 Accepts `ReferencedAssetsSelectorConfig`; filters parsers by `enabledParserIds`; unknown ids ignored
- [x] 6.4 Unions enabled parsers' outputs into one normalized set
- [x] 6.5 `GraphicsLibReferenceParser` adapter added; subject to `enabledParserIds`
- [x] 6.6 Intersection with on-disk images produces the referenced bucket
- [x] 6.7 `suppressUnreferenced` branch skips the unreferenced emission entirely
- [x] 6.8 `trackAttribution` branch maintains `pathToParserIds` only when enabled; `referencedBy` null otherwise
- [x] 6.9 `ctx.isCancelled()` checked inside parser loop and intersection loop

## 6b. ReferencedAssetsSelectorConfig + SelectedAsset attribution field

- [x] 6b.1 `ReferencedAssetsSelectorConfig` as `@MappableClass` with `enabledParserIds`, `suppressUnreferenced`, `trackAttribution` + `allEnabled` constant + `cacheHash` getter
- [x] 6b.2 `SelectedAsset.referencedBy: List<String>?` added in task 1.1
- [x] 6b.3 `ModImageTable` construction is unchanged — attribution lives on `SelectedAsset` and surfaces via UI layer, not via persisted table

## 6a. Profiling via Fimber (guarded by showPerformance)

- [x] 6a.1 Existing `progressText` writes unchanged; Fimber.d added alongside
- [x] 6a.2 Fimber.d emissions added: per-mod selector time/counts; per-parser `collect()` time/path count; intersection time + set size; total run time
- [x] 6a.3 Timing captures live inside `if (showPerformance)` / `if (ctx.showPerformance)` branches; no allocation when flag is off
- [x] 6a.4 All profiling lines prefixed with `"[VramChecker] "`
- [ ] 6a.5 Manual verification — toggle `showPerformance` off, confirm no profiling lines

## 7. Settings plumbing

- [x] 7.1 `vramEstimatorSelectorId: String` added with default `'folder-scan'`
- [x] 7.2 `referencedAssetsSelectorConfig` added with `ReferencedAssetsSelectorConfig.allEnabled` default
- [x] 7.3 Mappers regenerated as part of 2.2
- [x] 7.4 `selector_registry.dart` with `resolveSelector(id, config)` and `allSelectorOptions()`
- [x] 7.5 `resolveSelector` falls back to `FolderScanSelector` on unknown id
- [x] 7.6 `VramEstimatorNotifier._readActiveSelector()` pulls config from settings; passed to `resolveSelector`

## 8. Manager caching

- [x] 8.1 `_perKeyCache: Map<String, Map<String, VramMod>>` on `VramEstimatorNotifier`, keyed via `_cacheKey(selectorId, config)`
- [x] 8.2 `onSelectorOrConfigChanged()` swaps cached entries in instantly; kicks off `startEstimating` if missing
- [x] 8.3 `refresh()` method clears the per-key cache and restarts under the active configuration
- [~] 8.4 Mod-list change → existing invalidation path still runs on scan start; per-key cache isn't cleared on mod changes (minor staleness risk — user flags can flush with refresh)
- [ ] 8.5 Manual verification — flip parser off and back on, confirm instant hit

## 9. UI: selector dropdown + two-bucket display + debug panel

- [x] 9.1 Selector dropdown added to toolbar via `_buildSelectorDropdown`
- [x] 9.2 Dropdown writes to `Settings.vramEstimatorSelectorId` via `appSettings.notifier.update`, then calls `onSelectorOrConfigChanged()`
- [x] 9.3 Dropdown wrapped in `MovingTooltipWidget` surfacing the active selector's description
- [x] 9.4 Per-mod row in bar chart now shows `+X MB unreferenced` sub-label + a muted secondary bar when `unreferencedImages != null`. Added `VramMod.unreferencedBytesNotIncludingGraphicsLib()` helper.
- [~] 9.5 Aggregate two-bucket totals — no aggregate total is currently shown in the page (only per-mod bars). Deferred until a total widget is added.
- [x] 9.6 `ReferenceScanDebugPanel` added, rendered only when active selector is `referenced`
- [x] 9.7 `FilterChip` per registered `ReferenceParser` (implemented as chips rather than checkboxes for density; label = `displayName`)
- [x] 9.8 `suppressUnreferenced` SwitchListTile with explainer tooltip
- [x] 9.9 `trackAttribution` SwitchListTile with explainer tooltip
- [~] 9.10 Per-file attribution display — attribution lives on `SelectedAsset` (selector-side) but is not currently threaded into `ModImageTable`. Surfacing it requires adding an attribution column to the table (schema change) and rendering it in the per-file tooltip. Deferred; flag for a follow-up change.
- [x] 9.11 Every toggle calls `appSettings.notifier.update` + `onSelectorOrConfigChanged()`

## 10. Explanation dialog

- [x] 10.1 Explanation dialog now has a "Selectors" section describing both selectors
- [x] 10.2 Unreferenced bucket explicitly framed as advisory
- [x] 10.3 Known imprecisions enumerated: dynamic paths, obfuscated jars, GfxLib maps
- [x] 10.4 Debug panel and its three toggles documented

## 11. Non-UI callers

- [x] 11.1 `vram_estimate_intent.dart` only reads `AppState.vramEstimatorProvider` cache — no changes needed
- [x] 11.2 Decision: chatbot reflects the user's active selector (falls out of reading the provider cache). No code changes.

## 12. Manual validation

- [ ] 12.1 Run folder-scan on a small vanilla-style mod and confirm numbers match pre-change
- [ ] 12.2 Run reference mode on the same mod and confirm referenced ≤ folder-scan total
- [ ] 12.3 Run both modes on a large content mod (e.g. a large faction mod) and sanity-check the unreferenced bucket — the delta should plausibly be dev leftovers
- [ ] 12.4 Run both modes on GraphicsLib itself — verify `cache/` images still counted as Normal maps
- [ ] 12.5 Run both modes on a scripting-heavy mod (e.g. Nexerelin) with compiled jars — verify JAR string scanning brings images referenced only from Java into the referenced bucket, and that jars outside a `jars/` folder are still scanned
- [ ] 12.5a Run both modes on a mod that ships loose `.java` sources (pick one from the community; fall back to a small test fixture if none available) — verify literal paths in sources are picked up
- [ ] 12.6 Toggle GraphicsLib map types in config and confirm displayed totals change without a rescan, in both selector modes
- [ ] 12.7 Toggle the selector dropdown back and forth and confirm switching is instant after both caches are warm
- [ ] 12.8 Run with `showPerformance = true` and inspect Fimber output — confirm per-source timing lines appear; flip to `false` and confirm they disappear
- [ ] 12.9 Disable one parser in the debug panel, rescan, and confirm paths referenced only by that parser shift into the unreferenced bucket (or drop out entirely with `suppressUnreferenced`)
- [ ] 12.10 Toggle `trackAttribution` and confirm `referencedBy` ids render in the per-file debug view
- [ ] 12.11 Toggle `suppressUnreferenced` and confirm the UI collapses to a single-number display that matches reference-mode's referenced-only total
- [ ] 12.12 Disable a parser, re-enable it with no other changes, and confirm the cache hit is instant (config hash stable)
