## ADDED Requirements

### Requirement: VRAM Estimator produces a per-mod VRAM estimate

The VRAM estimator SHALL produce, for each mod passed in, a VRAM usage estimate expressed in bytes. The estimate SHALL be based on the dimensions (rounded up to the next power of two), channel count, and channel bit depth of image files associated with the mod.

#### Scenario: Standard texture contributes bytes based on POT-rounded dimensions and channels
- **WHEN** a mod contains a 100×100 RGBA 8-bit PNG that is referenced or counted by the active selector
- **THEN** the estimator SHALL round 100 up to 128 for both dimensions, multiply `128 * 128 * (32 / 8)` = 65536 bytes, apply the 4/3 mipmap multiplier for textures, and include the result in the mod's total

#### Scenario: Image of size 1 is treated as 1, not rounded up
- **WHEN** a mod contains an image with width or height of 1
- **THEN** that dimension SHALL be treated as 1 in the byte calculation (not rounded up to 2)

### Requirement: Background images are deduped against vanilla

The estimator SHALL count, per mod, at most one background image — the single largest background whose width exceeds vanilla's 2048-pixel background width — and SHALL subtract the vanilla background texture size (12,582,912 bytes) from that background's contribution. Backgrounds smaller than or equal to vanilla SHALL NOT contribute to the estimate.

#### Scenario: Only the largest oversized background counts
- **WHEN** a mod's `backgrounds/` folder contains three backgrounds of widths 2048, 4096, and 8192
- **THEN** the estimator SHALL include only the 8192-wide background (minus vanilla size) and SHALL skip the 2048 (not larger than vanilla) and the 4096 (not the largest)

#### Scenario: No oversized background
- **WHEN** a mod's only backgrounds are at or below 2048 wide
- **THEN** the estimator SHALL contribute zero bytes from backgrounds for that mod

### Requirement: VramAssetSelector decides which files count toward the estimate

The estimator SHALL delegate the decision of which image files a mod contributes to a pluggable `VramAssetSelector`. The selector SHALL return a list of selected assets, each carrying the file, an optional `MapType` tag (for GraphicsLib normal/material/surface maps), and a provenance marker of `referenced` or `unreferenced`. The downstream pipeline — header reading, background dedupe, aggregate totals, and display-time GraphicsLib filtering — SHALL be identical across all selectors.

#### Scenario: Selector output flows into VramMod unchanged
- **WHEN** a selector returns an asset with `graphicsLibType = MapType.Normal`
- **THEN** that file's row in the mod's `ModImageTable` SHALL carry `graphicsLibType = Normal`, and `ModImageView.isUsedBasedOnGraphicsLibConfig` SHALL gate its inclusion based on the current `GraphicsLibConfig` at read time

#### Scenario: Files not returned by the selector are not counted
- **WHEN** a file exists in the mod folder but the active selector does not include it in its output
- **THEN** that file SHALL NOT appear in the mod's `ModImageTable` or contribute bytes to any bucket

### Requirement: FolderScanSelector preserves the current folder-walk behavior

A `FolderScanSelector` SHALL be provided that returns every image file in the mod folder except those whose relative path contains one of the configured unused indicators (currently `CURRENTLY_UNUSED`, `DO_NOT_USE`). All returned assets SHALL have provenance `referenced`. The selector SHALL tag assets with `MapType` based on the mod's GraphicsLib CSV and the GraphicsLib-mod-specific `cache/` hardcode.

#### Scenario: Filename-marked unused files are excluded
- **WHEN** a mod contains `graphics/ships/foo_DO_NOT_USE.png`
- **THEN** `FolderScanSelector` SHALL omit that file from its output

#### Scenario: GraphicsLib CSV tags are preserved
- **WHEN** a mod's GraphicsLib CSV declares `graphics/ships/foo_normal.png` as a Normal map, and that file exists on disk
- **THEN** `FolderScanSelector` SHALL return that file with `graphicsLibType = MapType.Normal` and provenance `referenced`

#### Scenario: GraphicsLib mod's cache folder is tagged Normal
- **WHEN** the mod being processed is GraphicsLib itself and contains an image under a path segment `cache`
- **THEN** `FolderScanSelector` SHALL return that image with `graphicsLibType = MapType.Normal`

### Requirement: ReferencedAssetsSelector identifies referenced and unreferenced images

A `ReferencedAssetsSelector` SHALL be provided that parses a mod's static reference sources, builds a set of referenced image paths, and returns every on-disk image as either `referenced` (path matched a reference source) or `unreferenced` (path did not match any reference source). Reference sources v1 SHALL include:

- `data/hulls/*.ship` files (JSON) and `data/hulls/ship_data.csv`
- `data/weapons/*.wpn` files (JSON), `data/weapons/proj/*.proj` files (JSON), and `data/weapons/weapon_data.csv`
- `data/world/factions/*.faction` files (JSON)
- `data/characters/portraits/portraits.csv`
- `data/config/settings.json` `graphics` block
- The mod's GraphicsLib CSV (treated as a first-class reference source; entries are referenced regardless of whether any other source also references them)
- String literals extracted from the constant pools of `.class` entries inside any `.jar` file located anywhere in the mod folder (not only under `jars/`)
- String literals extracted from any loose `.java` source files located anywhere in the mod folder

The selector SHALL tag assets with `MapType` from the GraphicsLib CSV, preserving the GraphicsLib-mod-specific `cache/` hardcode.

#### Scenario: Ship sprite referenced by ship_data.csv is marked referenced
- **WHEN** `ship_data.csv` contains a row whose `sprite name` column resolves to `graphics/ships/foo.png` and that file exists in the mod
- **THEN** `ReferencedAssetsSelector` SHALL return that file with provenance `referenced`

#### Scenario: Orphan image is marked unreferenced, not excluded
- **WHEN** a mod contains `graphics/unused_draft.png` and no reference source mentions it
- **THEN** `ReferencedAssetsSelector` SHALL return that file with provenance `unreferenced` (it SHALL NOT be omitted from the output)

#### Scenario: GraphicsLib map survives even without base-sprite reference
- **WHEN** a mod's GraphicsLib CSV declares `graphics/ships/foo_normal.png` as a Normal map, that file exists on disk, and no `.ship` or `.csv` in the mod references `graphics/ships/foo.png`
- **THEN** `ReferencedAssetsSelector` SHALL return `foo_normal.png` with provenance `referenced` and `graphicsLibType = MapType.Normal`

#### Scenario: JAR string literal path is treated as a reference
- **WHEN** a mod contains a `.jar` file at any path (for example `plugin.jar` at the mod root, or under a custom `bin/` folder) whose class constant pool includes the literal string `graphics/portraits/my_portrait.png`, and that file exists on disk
- **THEN** `ReferencedAssetsSelector` SHALL return `graphics/portraits/my_portrait.png` with provenance `referenced`

#### Scenario: Loose .java source literal path is treated as a reference
- **WHEN** a mod ships an unbuilt `.java` source file at any path that contains a double-quoted string literal `"graphics/hullmods/my_hullmod.png"`, and that file exists on disk
- **THEN** `ReferencedAssetsSelector` SHALL return `graphics/hullmods/my_hullmod.png` with provenance `referenced`

#### Scenario: Directory-prefix literal references every image in the directory
- **WHEN** a `.jar` constant pool or a `.java` source literal contains `graphics/portraits/` (a directory prefix ending in `/` that starts with a known resource root)
- **THEN** `ReferencedAssetsSelector` SHALL treat every image directly in `graphics/portraits/` as referenced

#### Scenario: Path case and extension mismatches still match
- **WHEN** a reference source declares `Graphics/Ships/Foo` (different case, no extension) and the mod contains `graphics/ships/foo.png`
- **THEN** `ReferencedAssetsSelector` SHALL treat the reference and the file as matching, because paths are compared lowercased with forward slashes and with an optional `.png` extension appended

### Requirement: VramMod reports referenced and unreferenced buckets

`VramMod` SHALL carry two image tables: `images` (the referenced bucket, which contributes to the headline total) and `unreferencedImages` (optional; populated only when the active selector produces unreferenced assets). The `unreferencedImages` field SHALL be `null` for results produced by `FolderScanSelector`.

#### Scenario: Folder-scan mode produces a null unreferenced bucket
- **WHEN** a scan runs with `FolderScanSelector`
- **THEN** every resulting `VramMod` SHALL have `unreferencedImages == null`

#### Scenario: Reference mode produces both buckets
- **WHEN** a scan runs with `ReferencedAssetsSelector` and a mod contains both referenced and unreferenced images
- **THEN** the resulting `VramMod` SHALL have referenced images in `images` and unreferenced images in `unreferencedImages`

#### Scenario: Existing cache entries decode under the new schema
- **WHEN** a previously persisted `VramMod` cache entry (written before this change) is read
- **THEN** it SHALL decode successfully with `unreferencedImages == null`

### Requirement: GraphicsLib configuration is applied at display time, not during selection

The estimator SHALL NOT consult `GraphicsLibConfig` inside any `VramAssetSelector`. All GraphicsLib-tagged images SHALL be stored in the resulting `ModImageTable` regardless of which GraphicsLib map types are enabled. The display and aggregate-byte-calculation layers SHALL call `ModImageView.isUsedBasedOnGraphicsLibConfig` and `VramMod.bytesNotIncludingGraphicsLib` to filter based on the user's current configuration.

#### Scenario: Toggling GraphicsLib map types does not require a rescan
- **WHEN** the user changes `areGfxLibNormalMapsEnabled`, `areGfxLibMaterialMapsEnabled`, or `areGfxLibSurfaceMapsEnabled` in their GraphicsLib configuration
- **THEN** the VRAM estimator SHALL recompute displayed totals from existing `VramMod` data without re-running any selector or re-reading any image headers

### Requirement: Selector choice is a global, persisted setting

The active `VramAssetSelector` SHALL be chosen via a single global setting `Settings.vramEstimatorSelectorId`, persisted across sessions. The setting SHALL apply to all mods in a given scan (no per-mod overrides).

#### Scenario: Selector setting persists across app restarts
- **WHEN** the user selects a non-default selector and restarts the app
- **THEN** the VRAM estimator SHALL use the previously selected selector on its next run

#### Scenario: Unknown persisted selector id falls back to the default
- **WHEN** `Settings.vramEstimatorSelectorId` holds a value that does not correspond to any registered selector (e.g., from a removed experimental selector)
- **THEN** the estimator SHALL fall back to `FolderScanSelector` and not crash

### Requirement: Per-selector result caching avoids redundant scans

The VRAM estimator SHALL cache the most recent scan result per selector id within the running session. Switching the active selector to one with a cached result SHALL display that cached result immediately without re-running the scan.

#### Scenario: Switching to a cached selector is instant
- **WHEN** the user has already run scans under both `FolderScanSelector` and `ReferencedAssetsSelector` and switches between them
- **THEN** the estimator SHALL display each cached result without initiating a new scan

#### Scenario: Explicit refresh invalidates all cached selector results
- **WHEN** the user triggers a refresh from the VRAM estimator toolbar
- **THEN** the estimator SHALL invalidate cached results for every selector and rerun under the currently active one

### Requirement: VRAM estimator UI surfaces both buckets in reference mode

The VRAM estimator page SHALL display a selector dropdown on its toolbar and SHALL render per-mod totals according to the active selector's output shape: a single total in folder-scan mode, and separate `Referenced` and `Unreferenced` totals in reference mode. The unreferenced figure SHALL be styled as advisory (secondary emphasis) so users understand it is an imprecision envelope, not an authoritative count.

#### Scenario: Dropdown lists the registered selectors
- **WHEN** the VRAM estimator page renders
- **THEN** its toolbar SHALL include a dropdown whose options are the registered selectors' display names, with the active selector visually indicated

#### Scenario: Reference mode shows both numbers
- **WHEN** the active selector is `ReferencedAssetsSelector` and a scan has completed
- **THEN** each mod row SHALL display its referenced total prominently and its unreferenced total as a secondary figure

#### Scenario: Folder-scan mode shows one number
- **WHEN** the active selector is `FolderScanSelector`
- **THEN** each mod row SHALL display a single total (matching today's UI)

### Requirement: Reference sources are composed from a uniform parser interface

Each reference source inside `ReferencedAssetsSelector` SHALL implement a common `ReferenceParser` interface exposing a stable `id`, a `displayName`, and a `Future<Set<String>> collect(...)` method that returns a set of normalized path strings. `ReferencedAssetsSelector` SHALL compose its parsers from a single list declared at the top of its source file. Adding a new reference source SHALL NOT require changes outside (a) adding a new parser file and (b) adding one entry to that list.

#### Scenario: New parser picks up existing plumbing
- **WHEN** a developer adds a new `ReferenceParser` implementation and lists it alongside the existing parsers
- **THEN** the selector SHALL union its output with other parsers, respect its id in `enabledParserIds`, include it in attribution when `trackAttribution` is on, and emit profiling for it when `showPerformance` is on — with no further code changes

### Requirement: ReferencedAssetsSelectorConfig exposes debug toggles

`ReferencedAssetsSelector` SHALL accept a `ReferencedAssetsSelectorConfig` object persisted in `Settings`. The config SHALL expose:

- `enabledParserIds: Set<String>` — the parser ids that the selector runs during a scan.
- `suppressUnreferenced: bool` — when true, the selector emits only referenced assets and the resulting `VramMod.unreferencedImages` is null.
- `trackAttribution: bool` — when true, each `SelectedAsset` carries a `referencedBy` list of parser ids that flagged the path.

Unknown parser ids in `enabledParserIds` SHALL be ignored silently. When `enabledParserIds` is empty, the selector SHALL produce zero references (every on-disk image is unreferenced unless `suppressUnreferenced` is also true).

#### Scenario: Disabling a parser removes its contributions
- **WHEN** `enabledParserIds` does not include `"jar-strings"`
- **THEN** `ReferencedAssetsSelector` SHALL NOT run the JAR string extractor for that scan, and paths referenced only by the JAR extractor SHALL be reported as `unreferenced` (or omitted, per `suppressUnreferenced`)

#### Scenario: suppressUnreferenced produces folder-scan-shaped output
- **WHEN** `suppressUnreferenced == true` and a scan runs under `ReferencedAssetsSelector`
- **THEN** every resulting `VramMod` SHALL have `unreferencedImages == null`, matching the output shape of `FolderScanSelector`, so UI and aggregate helpers treat the result as a single-bucket total

#### Scenario: Attribution is populated only when tracking is on
- **WHEN** a scan runs with `trackAttribution == true` and the path `graphics/foo.png` is flagged by both `ship-data-csv` and `jar-strings`
- **THEN** the corresponding `SelectedAsset` SHALL have `referencedBy` containing both parser ids (order unspecified)

#### Scenario: Attribution is null when tracking is off
- **WHEN** a scan runs with `trackAttribution == false`
- **THEN** every `SelectedAsset.referencedBy` SHALL be null, and the selector SHALL NOT allocate attribution bookkeeping data structures

#### Scenario: Config changes invalidate only the selector's cache
- **WHEN** the user changes any field of `ReferencedAssetsSelectorConfig`
- **THEN** cached reference-mode results SHALL be invalidated for that configuration, while cached folder-scan results SHALL be unaffected

### Requirement: Debug UI exposes the reference-mode configuration

The VRAM estimator page SHALL render a collapsible "Reference scan debug" panel visible only when the active selector is `ReferencedAssetsSelector`. The panel SHALL include a checkbox per registered parser (labeled with the parser's `displayName`), a toggle for `suppressUnreferenced`, and a toggle for `trackAttribution`. Toggling any control SHALL update `Settings` and trigger a fresh scan (or cached result if the new configuration has been scanned before in the session).

#### Scenario: Debug panel hidden in folder-scan mode
- **WHEN** the active selector is `FolderScanSelector`
- **THEN** the "Reference scan debug" panel SHALL NOT be rendered

#### Scenario: Attribution surfaces in the UI when tracking is on
- **WHEN** `trackAttribution == true` and the user hovers or otherwise inspects a per-file row in the detail view
- **THEN** the UI SHALL display the `referencedBy` parser ids for that file

### Requirement: Performance profiling is flag-gated and routed to Fimber

When the `showPerformance` flag is set on `VramChecker`, the estimator SHALL emit structured per-selector and per-reference-parser timing via `Fimber.d` in addition to any existing text-buffer output. When the flag is not set, no profiling output SHALL be emitted and no profiling-only work (timing captures, aggregate tallies produced solely for logging) SHALL be performed.

#### Scenario: Flag off produces no profiling output
- **WHEN** a scan runs with `showPerformance == false`
- **THEN** no `Fimber.d` profiling lines SHALL be emitted by the VRAM estimator and no stopwatches SHALL be allocated solely for profiling

#### Scenario: Flag on emits per-source timing
- **WHEN** a scan runs with `showPerformance == true` under `ReferencedAssetsSelector`
- **THEN** the estimator SHALL emit `Fimber.d` lines covering, at minimum: total time per selector per mod; per reference-parser collection time (ship, weapon, faction, portraits, settings.json, GraphicsLib CSV, JAR, Java); JAR scan counts (jars, classes, retained strings); Java-source scan counts (files, retained strings); intersection time and final set size; referenced vs. unreferenced counts per mod

### Requirement: Explanation dialog documents selector behavior

The "About VRAM Estimator" explanation dialog SHALL describe the available selectors, explain the meaning of the unreferenced bucket, and call out known imprecisions (dynamic path construction in Java, obfuscated jars, GraphicsLib maps retained regardless of base-sprite references).

#### Scenario: User opens the explanation dialog
- **WHEN** the user opens the "About VRAM Estimator" dialog
- **THEN** the dialog content SHALL include sections describing `FolderScanSelector`, `ReferencedAssetsSelector`, the unreferenced bucket's advisory nature, and the known limitations listed above
