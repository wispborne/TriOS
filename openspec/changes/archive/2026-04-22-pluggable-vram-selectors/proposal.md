## Why

The VRAM estimator today walks every image file on disk and counts it against a mod's total. Mod folders commonly contain large unused images — dev leftovers, alternate sprites, WIP art, deprecated assets — which inflate estimates and make the tool's numbers misleading for large content mods. Without running the game, we cannot know what's actually loaded, but we can get much closer to the truth by reading the same data files the game reads.

## What Changes

- Introduce a `VramAssetSelector` strategy that decides which image files a mod contributes to its VRAM estimate. The existing logic is preserved unchanged as one selector; a new reference-based selector is added alongside it.
- Add `FolderScanSelector` wrapping today's behavior (every image minus `UNUSED_INDICATOR` filename markers, with GraphicsLib CSV tagging and `backgrounds/` dedupe handled downstream).
- Add `ReferencedAssetsSelector` that parses mod data files to build a referenced path set, then intersects with image files on disk. Reference sources in v1:
  - `data/hulls/*.ship`, `data/hulls/ship_data.csv`
  - `data/weapons/*.wpn`, `data/weapons/proj/*.proj`, `data/weapons/weapon_data.csv`
  - `data/world/factions/*.faction`
  - `data/characters/portraits/portraits.csv`
  - `data/config/settings.json` (`graphics` block)
  - The mod's GraphicsLib CSV (as a first-class reference source, preserving `MapType` tags)
  - String literals extracted from any `.jar` anywhere in the mod folder (not just `jars/` — mods can place jars wherever, and the path is pointed to from `mod_info.json`)
  - String literals extracted from any loose `.java` source files anywhere in the mod folder (some mods ship unbuilt sources instead of compiled jars)
- Structure `ReferencedAssetsSelector` around a uniform `ReferenceParser` interface composed from a single `_allParsers` list, so adding a new reference source later is one new file plus one list entry.
- Expose a `ReferencedAssetsSelectorConfig` (persisted in `Settings`) that makes the reference pipeline introspectable for debugging:
  - **Per-parser enable/disable** (`enabledParserIds: Set<String>`) — bisect which parser is responsible for a false positive or missed file.
  - **`suppressUnreferenced` flag** — when true, the selector emits only the referenced bucket and `VramMod.unreferencedImages` is null. Enables clean "trust mode" comparisons against folder-scan totals.
  - **`trackAttribution` flag** — when true, each `SelectedAsset` records which parser ids flagged it; the UI exposes this per row so users can answer "why was this included?" or "why wasn't this included?"
- Surface the config as a collapsible "Reference scan debug" panel on the VRAM estimator page (visible in reference mode only).
- Route VRAM-scan performance profiling through `Fimber.d` (guarded by the existing `showPerformance` flag on `VramChecker`, which already acts as the "enable profiling" toggle). When the flag is off, no profiling is logged. Adds selector-level timing: reference-parser collection time per source, intersection time, JAR/Java-scan time.
- Show the two buckets separately in the UI — **referenced** (authoritative total) and **unreferenced** (advisory, "on disk but nothing points to it"). Folder-scan mode keeps the single number it shows today.
- Persist a global `vramEstimatorSelectorId` in `Settings`; surface it as a dropdown on the VRAM estimator toolbar. Switching triggers a re-run; results are cached per selector so flipping between them is instant after the first scan.
- GraphicsLib handling is unchanged at the display layer. `GraphicsLibConfig` is still applied at read time via `ModImageView.isUsedBasedOnGraphicsLibConfig`, so toggling GfxLib map types in settings does not require a rescan in either selector mode.
- Update `VramMod` to optionally carry an `unreferencedImages: ModImageTable?` sibling to `images`. Null in folder-scan mode.
- Update the "About VRAM Estimator" explanation dialog to describe the two selectors and the unreferenced bucket.

## Capabilities

### New Capabilities
- `vram-estimator`: Core capability for estimating a mod's VRAM usage from image assets on disk — including the file-selection strategy, GraphicsLib map tagging, background dedupe against vanilla, and the two-bucket (referenced vs unreferenced) output shape.

### Modified Capabilities
<!-- No existing vram-estimator spec exists; this is greenfield. -->

## Impact

- **Affected code**
  - `lib/vram_estimator/vram_checker_logic.dart` — extract per-file inclusion logic into selectors; keep header reading, background dedupe, and aggregate computation shared.
  - `lib/vram_estimator/models/vram_checker_models.dart` — add optional `unreferencedImages` on `VramMod`; cache schema gets an additive optional field.
  - `lib/vram_estimator/vram_estimator_manager.dart` — hold the active selector, cache per-selector results, expose swap.
  - `lib/vram_estimator/vram_estimator_page.dart` — add selector dropdown to the toolbar; render two-bucket totals when unreferenced is populated.
  - `lib/vram_estimator/vram_checker_explanation.dart` — document the two selectors.
  - `lib/trios/settings/settings.dart` — add `vramEstimatorSelectorId` field and a nested `ReferencedAssetsSelectorConfig` field for the debug toggles.
  - New files under `lib/vram_estimator/selectors/` for `VramAssetSelector`, `FolderScanSelector`, `ReferencedAssetsSelector`, reference parsers (`.ship`, `.wpn`, `.proj`, `.faction`, CSV, settings.json, JAR strings, loose `.java` sources).
- **APIs / contracts**
  - `VramChecker` gains an optional `selector` parameter (defaults to `FolderScanSelector` for callers like `lib/chatbot/intents/vram_estimate_intent.dart`).
  - Persisted cache format gains an optional field; reads of old caches remain valid (they implicitly have `unreferencedImages == null`).
- **Dependencies**
  - No new packages required. Reference parsers use existing `csv`, JSON decoding, and `path` utilities. JAR reading uses `dart:io` + a small custom class-file constant-pool reader (JARs are zip archives; `package:archive` is already a transitive dep — to be confirmed during implementation).
- **Risk / known imprecision**
  - Mods that construct asset paths dynamically in Java may under-count in reference mode; the "unreferenced" bucket makes this legible rather than invisible.
  - Obfuscated jars may defeat string extraction. Documented as a known limitation.
  - GraphicsLib normal/material/surface maps are kept whenever their CSV entry exists, independent of whether the base sprite is gameplay-referenced. Matches today's behavior exactly; a tighter "gate maps on base-sprite reference" model is a potential v2 refinement.
