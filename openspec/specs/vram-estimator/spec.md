# VRAM Estimator Specification

## Purpose

The VRAM estimator analyzes each mod's image assets and produces a byte-count estimate of the GPU texture memory that mod will consume when loaded by Starsector. It models the game's power-of-two texture rounding, channel layout, and mipmap overhead, and delegates the "which files count?" decision to a pluggable `VramAssetSelector` so the same pipeline can support both a full-folder scan and a static-reference-tracing scan that distinguishes referenced versus unreferenced images. GraphicsLib map-type filtering is applied at display time rather than during selection, so the user can toggle normal/material/surface maps without a rescan.
## Requirements
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

### Requirement: ReferencedAssetsSelector parses image references in data/config JSON files

`ReferencedAssetsSelector` SHALL include a reference parser that walks every JSON file under `data/config/` in the mod (at any depth, including nested subdirectories) EXCEPT `data/config/settings.json`, and emits every string value that looks like an image path. A string SHALL be considered path-shaped if, after normalization via `PathNormalizer`, it either (a) ends in a known image extension (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`), or (b) starts with `graphics/`. Non-path-shaped strings (ids, plugin class names, tag lists, descriptive text) SHALL NOT be emitted.

The parser SHALL tolerate Starsector's permissive JSON dialect: `#` line comments (in addition to the already-supported `//` and `/* */`) SHALL be stripped before parsing via an opt-in flag on the shared `stripJsonComments` utility, and when strict `json.decode` fails the parser SHALL fall back to extracting quoted string literals from the comment-stripped text via regex. The path-shape filter SHALL apply uniformly to both strict-parse and fallback outputs.

#### Scenario: Icon path in a nested custom-entities JSON is referenced
- **WHEN** a mod contains `data/config/custom_entities.json` with an entry whose `"icon"` value is `"graphics/icons/warning_beacon.png"`, and that file exists on disk
- **THEN** `ReferencedAssetsSelector` SHALL return `graphics/icons/warning_beacon.png` with provenance `referenced` and attribution including the `data-config-json` parser id

#### Scenario: Planet texture in planets.json is referenced
- **WHEN** a mod contains `data/config/planets.json` with a planet definition whose `"texture"` value is `"graphics/planets/star_white.jpg"`, and that file exists on disk
- **THEN** `ReferencedAssetsSelector` SHALL return `graphics/planets/star_white.jpg` with provenance `referenced`

#### Scenario: Nested subdirectory JSON is parsed
- **WHEN** a mod contains `data/config/exerelinFactionConfig/rat_exotech.json` whose content references `"graphics/factions/exotech_logo.png"` under any key, and that file exists on disk
- **THEN** `ReferencedAssetsSelector` SHALL return `graphics/factions/exotech_logo.png` with provenance `referenced`

#### Scenario: Non-path strings are not emitted
- **WHEN** a `data/config/*.json` file contains string values such as `"TERRAIN_7"`, `"assortment_of_things.abyss.entities.hyper.AbyssalFracture"`, `"has_interaction_dialog"`, or `"Fracture"`
- **THEN** `ReferencedAssetsSelector` SHALL NOT treat any of those strings as an image reference

#### Scenario: settings.json is not parsed by this parser
- **WHEN** the mod contains `data/config/settings.json`
- **THEN** the `data-config-json` parser SHALL skip it (leaving `SettingsGraphicsReferences` as the sole owner); a path referenced only by `settings.json` SHALL be attributed to `settings-graphics` and not to `data-config-json`

#### Scenario: Files with # comments are parsed successfully
- **WHEN** a `data/config/*.json` file uses `#` line comments (a common Starsector convention) and is otherwise valid JSON
- **THEN** the parser SHALL strip `#` comments before decoding and SHALL collect path-shaped strings from the result

#### Scenario: Malformed JSON falls back to regex extraction
- **WHEN** a `data/config/*.json` file fails strict `json.decode` after comment stripping (for example, a trailing comma or an unquoted key)
- **THEN** the parser SHALL fall back to a regex-based quoted-string extractor over the comment-stripped text and apply the same path-shape filter to its output

#### Scenario: File read or parse failures are non-fatal
- **WHEN** a `data/config/*.json` file cannot be read from disk or both strict and fallback extraction fail
- **THEN** the parser SHALL log the failure via the selector context's verbose output and SHALL continue processing remaining files, yielding whatever references it collected from the other files

#### Scenario: Parser participates in the common parser plumbing
- **WHEN** a scan runs under `ReferencedAssetsSelector`
- **THEN** the `data-config-json` parser SHALL be registered in the selector's parser list, SHALL be enabled by default via `ReferencedAssetsSelectorConfig.allEnabled`, SHALL honor `enabledParserIds`, SHALL contribute to attribution under the id `data-config-json`, and SHALL emit per-parser timing via `Fimber.d` when `showPerformance` is on

### Requirement: stripJsonComments gains an opt-in flag for # line comments

The shared `stripJsonComments` utility SHALL accept a new optional parameter that enables `#` line-comment stripping. The parameter SHALL default to a value that preserves today's behavior exactly, so existing callers that do not pass the flag SHALL receive byte-for-byte identical output to the pre-change implementation. When the flag is enabled, the utility SHALL strip `#` through the next newline when the `#` appears outside a string literal. String literal contents SHALL be preserved unchanged in both modes. The existing handling of `//` and `/* */` comments SHALL remain unchanged.

#### Scenario: Default behavior is unchanged for existing callers
- **WHEN** `stripJsonComments` is called without the `#`-stripping flag, on input `{ "key": "value" # trailing\n}`
- **THEN** the output SHALL be identical to the pre-change output for the same input (the `#` and the text after it SHALL pass through unmodified)

#### Scenario: Opt-in flag strips # comments outside strings
- **WHEN** `stripJsonComments` is called with the `#`-stripping flag enabled, on input `{ "key": "value" # trailing comment\n}`
- **THEN** the output SHALL have the `#` and everything up to the newline removed, yielding `{ "key": "value" \n}`

#### Scenario: # inside a string literal is preserved in both modes
- **WHEN** `stripJsonComments` is called on input `{ "key": "prefix#suffix" }` with the flag either enabled or disabled
- **THEN** the output SHALL contain the literal `prefix#suffix` unchanged

#### Scenario: Only the new parser opts in
- **WHEN** the VRAM reference parsers run
- **THEN** only `DataConfigJsonReferences` SHALL pass the `#`-stripping flag to `stripJsonComments`; `SettingsGraphicsReferences`, `FactionReferences`, `ShipReferences`, `WeaponReferences`, and any other existing caller SHALL continue to call `stripJsonComments` without the flag

### Requirement: VRAM cache is persisted in msgpack format

The VRAM estimator SHALL persist its scan-result cache (the full `VramEstimatorManagerState`) to disk in msgpack format under the filename `TriOS-VRAM_CheckerCache.mp`, located in the TriOS cache directory. The serialized payload SHALL be produced by the same `toMap` function used for JSON serialization, so switching the on-disk format SHALL NOT change the logical cache shape or which fields round-trip.

#### Scenario: Cache is written as msgpack on scan completion
- **WHEN** a VRAM scan completes and the estimator schedules a cache write
- **THEN** the file `TriOS-VRAM_CheckerCache.mp` SHALL be created (or overwritten) in the TriOS cache directory with a msgpack-encoded payload, and no `TriOS-VRAM_CheckerCache.json` SHALL be created or modified

#### Scenario: Cache round-trips losslessly
- **WHEN** a `VramEstimatorManagerState` is serialized to msgpack and then deserialized via the manager's `fromMap`
- **THEN** the resulting state SHALL have the same `modVramInfo` keys, the same per-`VramMod` referenced and unreferenced image rows, and the same `lastUpdated` timestamp as the original, subject only to the reset of transient scan fields (`isScanning`, `isCancelled`, `currentlyScanningModName`, `totalModsToScan`, `modsScannedThisRun`) that already occurs in `fromMap`

#### Scenario: Reading an absent msgpack cache produces the initial empty state
- **WHEN** TriOS launches and no `TriOS-VRAM_CheckerCache.mp` exists in the cache directory
- **THEN** the estimator SHALL initialize with `VramEstimatorManagerState.initial()` (empty `modVramInfo`, null `lastUpdated`), matching the pre-change behavior for a missing cache

### Requirement: Legacy JSON cache is deleted on first launch after upgrade

On the first TriOS launch after upgrading past this change, the VRAM estimator SHALL delete any `TriOS-VRAM_CheckerCache.json` file and its `TriOS-VRAM_CheckerCache.json_backup.bak` sibling present in the TriOS cache directory. No attempt SHALL be made to convert the JSON contents to msgpack; the user's next scan regenerates the cache. Subsequent launches SHALL be silent no-ops when the legacy files are not present.

#### Scenario: Legacy JSON cache is removed when present
- **WHEN** TriOS launches and both `TriOS-VRAM_CheckerCache.json` and (optionally) `TriOS-VRAM_CheckerCache.json_backup.bak` exist in the TriOS cache directory
- **THEN** the estimator SHALL delete those files before performing its first read, and SHALL log a single informational line indicating the legacy cache was removed

#### Scenario: No-op when legacy files are absent
- **WHEN** TriOS launches and no `TriOS-VRAM_CheckerCache.json` or `_backup.bak` file exists in the TriOS cache directory
- **THEN** the estimator SHALL NOT attempt any deletion and SHALL NOT emit an informational line about legacy-cache removal

#### Scenario: Deletion failure does not block startup
- **WHEN** the legacy JSON file exists but cannot be deleted (for example, held open by another process)
- **THEN** the estimator SHALL log a warning, SHALL NOT rethrow, and SHALL continue with normal startup so the `.mp` cache path still works

### Requirement: User can export the VRAM cache as JSON on demand

The VRAM estimator page SHALL expose a user-triggered action that exports the current in-memory `VramEstimatorManagerState` as a pretty-printed JSON file to a user-chosen location. The action SHALL be available from the estimator's toolbar as an icon button with a tooltip that identifies its purpose. The export SHALL use the same `toMap` output that drives msgpack persistence, so the exported JSON SHALL be a faithful textual representation of what is stored in the `.mp` cache.

#### Scenario: Toolbar exposes the export action
- **WHEN** the VRAM estimator page renders
- **THEN** its toolbar SHALL include an icon button for "Export cache as JSON" with a tooltip describing the action

#### Scenario: Export writes pretty-printed JSON to the chosen path
- **WHEN** the user activates the export action, the current `modVramInfo` is non-empty, and the user selects a destination file in the save-file dialog
- **THEN** the estimator SHALL write a pretty-printed JSON document at that path whose decoded structure equals `toMap(currentState)`, and SHALL surface a confirmation (snackbar or equivalent) citing the resolved path

#### Scenario: Export matches msgpack cache semantically
- **WHEN** the user exports the cache as JSON immediately after a scan completes and the `.mp` cache has been persisted
- **THEN** decoding the exported JSON into a `Map<String, dynamic>` and decoding the `.mp` file into a `Map<String, dynamic>` via msgpack SHALL yield the same `modVramInfo` keys and the same per-`VramMod` image rows (modulo representation of scalar types, e.g., the same logical `DateTime` value in each)

#### Scenario: Export is a no-op when the cache is empty
- **WHEN** the user activates the export action and `modVramInfo` is empty (no scan has ever produced results this session, and no persisted cache was loaded)
- **THEN** the export action SHALL be disabled, OR if activated SHALL surface a brief message indicating there is nothing to export; in neither case SHALL a file be written

#### Scenario: Cancelled save dialog does not write a file
- **WHEN** the user activates the export action and cancels the save-file dialog
- **THEN** no file SHALL be written, no confirmation SHALL be shown, and no error SHALL be logged

#### Scenario: Export does not mutate the persisted cache
- **WHEN** the user exports the cache as JSON
- **THEN** the `.mp` cache file on disk SHALL NOT be created, modified, renamed, or deleted as a side effect of the export

### Requirement: VRAM scan can run across an isolate pool via async_task

The VRAM estimator SHALL accept an opt-in flag `Settings.vramEstimatorMultithreaded` that, when `true`, executes the per-mod scan body across an `async_task` `AsyncExecutor` isolate pool instead of the current single-isolate sequential `asyncMap` loop. When the flag is `false` (the default), the estimator SHALL use the pre-existing single-isolate code path with no executor, no isolate spawn, and no dependency on `async_task` at runtime.

The flag SHALL be persisted in `Settings`, default to `false` for new installs and for existing installs loading pre-change settings files, and SHALL be changeable at runtime without restarting the app. Changing the flag SHALL NOT invalidate cached scan results.

The multithreaded path SHALL use a worker pool sized at `min(Platform.numberOfProcessors - 1, 4)` with a floor of 1.

#### Scenario: Default behavior is unchanged when the flag is off
- **WHEN** `Settings.vramEstimatorMultithreaded` is `false` and a VRAM scan is started
- **THEN** the estimator SHALL execute every mod on the main isolate using the pre-change sequential `asyncMap` pipeline, and SHALL NOT instantiate any `AsyncExecutor` or spawn worker isolates for the scan

#### Scenario: Flag enables the pooled execution path
- **WHEN** `Settings.vramEstimatorMultithreaded` is `true` and a scan runs on a mod list with 2 or more variants
- **THEN** the estimator SHALL instantiate an `AsyncExecutor` with `parallelism = min(numberOfProcessors - 1, 4)` (minimum 1), SHALL dispatch per-mod scan tasks to it, and SHALL close the executor before `check()` returns or throws

#### Scenario: Single-variant scan bypasses the executor even when the flag is on
- **WHEN** `Settings.vramEstimatorMultithreaded` is `true` and `variantsToCheck.length < 2`
- **THEN** the estimator SHALL run the scan on the main isolate without instantiating an `AsyncExecutor`, because isolate spawn cost exceeds any benefit for a single mod

#### Scenario: Flag persists across app restarts
- **WHEN** the user enables multithreading, closes the app, and relaunches
- **THEN** `Settings.vramEstimatorMultithreaded` SHALL read back as `true` and the next scan SHALL use the pooled path

#### Scenario: Missing field in older settings files defaults to false
- **WHEN** a settings file written before this change is loaded (with no `vramEstimatorMultithreaded` key)
- **THEN** the estimator SHALL treat the flag as `false` and SHALL NOT fail to load the settings

### Requirement: Multithreaded and single-threaded scans produce the same logical result

For the same inputs (mod list, selector id, selector config, `GraphicsLibConfig`, flag states), a scan run with `vramEstimatorMultithreaded == false` and a scan run with `vramEstimatorMultithreaded == true` SHALL produce the same `VramEstimatorManagerState.modVramInfo` map: the same set of mod-id keys, and for each key a `VramMod` with the same referenced image rows (as sets) and the same unreferenced image rows (as sets, or both `null`). Iteration order of rows within a table and ordering of log lines across mods are not part of this parity guarantee.

#### Scenario: Output parity for folder-scan mode
- **WHEN** a fixed mod list is scanned once with `vramEstimatorMultithreaded == false` and once with `vramEstimatorMultithreaded == true`, both with `FolderScanSelector`
- **THEN** the two resulting `modVramInfo` maps SHALL have the same keys, and for each key the `images` table rows SHALL be equal as sets and `unreferencedImages` SHALL be `null` in both

#### Scenario: Output parity for reference mode
- **WHEN** a fixed mod list is scanned twice under `ReferencedAssetsSelector` with identical `ReferencedAssetsSelectorConfig`, once with the flag off and once with the flag on
- **THEN** the two resulting `modVramInfo` maps SHALL have the same keys, and for each key both `images` and `unreferencedImages` SHALL be equal as sets

### Requirement: Per-mod scan logic is reconstructable inside an isolate

The per-mod scan body SHALL be encapsulated in a pure, top-level function that takes a serializable parameter object (`VramCheckScanParams`) and is callable both on the main isolate (single-threaded mode) and inside an `async_task` worker (multithreaded mode). The single-threaded mode SHALL call this same function; both modes SHALL NOT duplicate scan logic.

Selectors SHALL be reconstructable inside a worker from a `(selectorId, selectorConfig)` pair via a `VramAssetSelector.fromId` registry. Every selector registered today (`FolderScanSelector`, `ReferencedAssetsSelector`) SHALL be reachable through this registry, and adding a new selector SHALL require registering it there.

#### Scenario: Registry reconstructs FolderScanSelector
- **WHEN** `VramAssetSelector.fromId('folder-scan', null)` is called
- **THEN** it SHALL return a `FolderScanSelector` instance functionally equivalent to one constructed directly

#### Scenario: Registry reconstructs ReferencedAssetsSelector with config
- **WHEN** `VramAssetSelector.fromId('referenced-assets', config)` is called with a valid `ReferencedAssetsSelectorConfig`
- **THEN** it SHALL return a `ReferencedAssetsSelector` whose behavior is identical to one constructed with that config directly

#### Scenario: Both modes share one scan body
- **WHEN** code coverage is examined for the per-mod scan body after both a single-threaded and a multithreaded run
- **THEN** both runs SHALL have entered the same top-level scan function; the single-threaded path SHALL NOT carry its own duplicate copy of the per-mod logic

### Requirement: Progress and cancellation flow correctly through isolate boundaries

In multithreaded mode, the estimator SHALL deliver `onModStart`, `onFileProgress`, and `modProgressOut` callbacks to the main isolate with the same shape and cardinality as the single-threaded path: `onModStart` fires exactly once per mod, `onFileProgress` fires at least once with `(0, total, null)` at the start of each mod and once per completed asset thereafter, and `modProgressOut` fires exactly once per mod with the final `VramMod` result. Per-asset progress SHALL be delivered via `AsyncTaskChannel`. The main isolate SHALL invoke the callbacks on itself, preserving the existing Riverpod buffering and flushing behavior.

The `isCancelled()` predicate SHALL be honored at two points: (a) before each task is dispatched to the executor (no further tasks submitted after cancel), and (b) inside the worker via a channel cancel-message poll at the same phase boundaries the single-threaded path already checks (`isCancelled()` between enumeration, GraphicsLib parse, selector invocation, and header reads).

#### Scenario: Cancellation before dispatch stops the scan
- **WHEN** the user cancels while earlier mods are still scanning in multithreaded mode
- **THEN** the estimator SHALL NOT submit any additional mod tasks to the executor after the cancel is observed

#### Scenario: In-flight tasks observe cancellation
- **WHEN** the user cancels while a task is actively scanning a mod in multithreaded mode
- **THEN** that worker SHALL, at its next `isCancelled` poll point, abort with the same `"Cancelled"` exception the single-threaded path throws; the main isolate SHALL discard that task's result

#### Scenario: Progress callbacks fire on the main isolate
- **WHEN** a mod scan completes in multithreaded mode
- **THEN** `modProgressOut(mod)` SHALL be invoked on the main isolate (so Riverpod state updates work without cross-isolate synchronization) exactly once for that mod

### Requirement: Multithreaded mode exposes a debug-panel toggle

The VRAM estimator page SHALL render a toggle for `Settings.vramEstimatorMultithreaded` in its debug panel. The toggle SHALL have a tooltip that briefly describes the trade-off (faster scans vs. higher CPU and file-handle pressure). Changing the toggle SHALL update `Settings` immediately; the new value SHALL take effect on the next scan.

#### Scenario: Toggle is visible in the debug panel
- **WHEN** the VRAM estimator page's debug panel is rendered
- **THEN** the panel SHALL include a labeled control for "Multithreaded scanning" (or equivalent) with a tooltip

#### Scenario: Toggle writes through to settings
- **WHEN** the user flips the toggle
- **THEN** `Settings.vramEstimatorMultithreaded` SHALL be updated and persisted, and the next invocation of `startEstimating` SHALL read the new value

#### Scenario: Toggle does not invalidate cached scan results
- **WHEN** the user flips the toggle between scans
- **THEN** the estimator SHALL NOT clear any cached `VramMod` results; cached results SHALL remain displayed until the user triggers a new scan

### Requirement: Worker errors propagate with usable diagnostics

When a worker task throws or the executor fails, the estimator SHALL surface the error on the main isolate with a message that identifies the failing mod and includes the worker-side stack (or a textual capture thereof). A single failing mod SHALL NOT abort the entire scan; the estimator SHALL record the failure, continue processing remaining mods, and leave the failed mod out of the resulting `modVramInfo` map, matching the robustness the single-threaded path already provides for per-mod exceptions.

#### Scenario: Worker exception does not abort the scan
- **WHEN** a task for mod `X` throws inside a worker during a multi-mod scan
- **THEN** the estimator SHALL log the error with mod `X`'s id and stack, SHALL continue processing remaining mods, and the final `modVramInfo` SHALL contain entries for every mod whose task succeeded

#### Scenario: Executor teardown on cancellation or completion
- **WHEN** a multithreaded scan completes (successfully, via cancellation, or via executor-level failure)
- **THEN** the `AsyncExecutor` instance created for that scan SHALL be shut down before `check()` returns control, so worker isolates do not leak

