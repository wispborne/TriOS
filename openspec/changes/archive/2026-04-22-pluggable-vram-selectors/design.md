## Context

TriOS's VRAM estimator lives under `lib/vram_estimator/`. The core pipeline in `VramChecker.check()` (in `lib/vram_estimator/vram_checker_logic.dart`) processes each mod as follows:

1. Recursively list every file in the mod folder.
2. Parse any GraphicsLib CSV (`id,type,map,path` columns) to tag which paths are normal/material/surface maps.
3. For each image file, classify as `texture`, `background`, or `unused` (filename contains `CURRENTLY_UNUSED` or `DO_NOT_USE`), read its header, compute dimensions / channels / POT-rounded bytes.
4. Drop `unused` images; for `background` images, keep only the single largest one that exceeds vanilla's 2048-wide size.
5. Build a columnar `ModImageTable` and produce a `VramMod`.
6. `GraphicsLibConfig` is applied at read time via `ModImageView.isUsedBasedOnGraphicsLibConfig` and `VramMod.bytesNotIncludingGraphicsLib()` — the config is *not* baked into the stored table, so users can toggle GfxLib map types without rescanning.

The fundamental limitation: every image in the mod folder is counted (minus the filename heuristic). Mod authors routinely ship large unused assets — dev leftovers, alternate sprites, WIP art — which distorts the number. Without running the game, we can get meaningfully closer to ground truth by parsing the same data files the game reads.

Callers of `VramChecker` today include the VRAM estimator page (`lib/vram_estimator/vram_estimator_page.dart` via `vram_estimator_manager.dart`) and the chatbot intent (`lib/chatbot/intents/vram_estimate_intent.dart`). Both must continue to work unchanged by default.

## Goals / Non-Goals

**Goals:**
- Let the VRAM estimator swap between the current folder-scan approach and a new reference-based approach at runtime, via a single user-facing dropdown.
- Preserve the current behavior exactly when the folder-scan selector is active (no regressions in today's numbers).
- In reference mode, parse the primary static reference sources (`.ship`, `.wpn`, `.proj`, `ship_data.csv`, `weapon_data.csv`, `.faction`, `portraits.csv`, `settings.json` graphics block, GraphicsLib CSV) and string literals from both compiled `.jar` files and loose `.java` source files located anywhere in the mod folder.
- Keep GraphicsLib map tagging and config-time filtering identical in both modes — GfxLib config changes must not require rescans.
- Show unreferenced files as a separate advisory number so the selector's imperfection is visible rather than silently undercounting.
- Cache results per selector so flipping the dropdown after both have run is instant.

**Non-Goals:**
- Running the game or parsing `starsector.log` for ground truth (possible future selector; out of scope here).
- Gating GraphicsLib maps on their base sprite being referenced (v2 refinement; v1 treats each GfxLib CSV row as an independent reference, matching today's behavior).
- Decompiling Java bytecode. JAR analysis is limited to constant-pool string extraction; `.java` source analysis is limited to regex extraction of double-quoted string literals.
- Per-mod selector overrides. The setting is global.
- Re-architecting the existing `ModImageTable` columnar storage — we add a sibling table, not a new column.

## Decisions

### Selector as the one narrow seam

**Decision:** Introduce a `VramAssetSelector` abstraction whose only job is to return the files a mod should contribute, together with any `MapType` tag each file carries. Header reading, POT math, background dedupe, aggregate totals, and GfxLib-config-based filtering all stay shared.

**Why:** Two pipelines differ only in "which files to count". Duplicating the downstream pipeline would introduce drift; sharing it means both selectors benefit from bug fixes and performance work. It also makes the reference-based selector strictly faster — rejected files never pay the header-read cost.

**Alternative considered:** A whole-pipeline `VramEstimationStrategy`. Rejected because it encourages duplication of logic that is fundamentally the same (image header interpretation, vanilla background dedupe).

### Selector interface shape

```dart
sealed class VramAssetSelector {
  String get id;              // persisted key, e.g. "folder-scan", "referenced"
  String get displayName;     // dropdown label
  String get description;     // explanation dialog copy

  Future<List<SelectedAsset>> select(
    VramCheckerMod mod,
    List<_FileData> allFiles,     // pre-enumerated once, shared
    VramCheckerContext ctx,       // progress/verbose sinks, cancellation
  );
}

class SelectedAsset {
  final _FileData file;
  final MapType? graphicsLibType;    // preserved, not re-derived downstream
  final AssetProvenance provenance;  // referenced | unreferenced
  final List<String>? referencedBy;  // parser ids; non-null only when trackAttribution is on
}

enum AssetProvenance { referenced, unreferenced }
```

`FolderScanSelector`: returns every image file minus `UNUSED_INDICATOR` filename matches, with `MapType` populated from the GraphicsLib CSV (and GraphicsLib mod's `cache/` hardcode). Every returned asset has `provenance = referenced` — folder-scan has no unreferenced concept.

`ReferencedAssetsSelector`: builds a referenced-path set from all v1 sources, intersects with image files on disk, and additionally emits the remaining on-disk images as `provenance = unreferenced`.

### GraphicsLib: a reference source, not a special case

**Decision:** The mod's GraphicsLib CSV is treated as a first-class reference source. Any path declared in the CSV survives the selector regardless of whether a `.ship` or `.faction` references it. GraphicsLib's own mod retains its `cache/` hardcode (everything in `cache/` is a referenced Normal map).

**Why:** `GraphicsLibConfig` is applied at display time (see `ModImageView.isUsedBasedOnGraphicsLibConfig`). The selector cannot know if the user has Normal maps enabled right now, and we want GfxLib toggles to work without rescanning. So the selector must keep every CSV-declared map, tagged, and let the display layer decide.

**Alternative considered:** Gate maps on base-sprite references ("only include `foo_normal.png` if `foo.ship` is referenced"). Rejected for v1 because it requires convention-based path matching (fragile) and a bug there silently undercounts. Noted as a v2 candidate.

### Two-bucket output

**Decision:** `VramMod` gains an optional `unreferencedImages: ModImageTable?` sibling field. Null in folder-scan mode; populated in reference mode with the images the selector flagged as unreferenced.

```dart
@MappableClass()
class VramMod with VramModMappable {
  final VramCheckerMod info;
  final bool isEnabled;
  @MappableField(hook: ModImageTableHook())
  final ModImageTable images;                 // referenced
  @MappableField(hook: ModImageTableHook())
  final ModImageTable? unreferencedImages;    // v1-new; null in folder-scan
  final List<GraphicsLibInfo>? graphicsLibEntries;
}
```

UI displays:
- Folder-scan mode: single number (unchanged).
- Reference mode: `Referenced: X MB · Unreferenced: Y MB` with unreferenced styled as secondary/advisory.

**Why optional sibling, not a new column:** The existing `ModImageTable` represents "images that count toward the total". Pushing unreferenced rows into the same table and filtering everywhere would touch every consumer (`getBytesUsedByDedupedImages`, `bytesNotIncludingGraphicsLib`, CSV export). An optional sibling table keeps existing consumers untouched and makes the bucket explicit.

**Cache compatibility:** dart_mappable handles missing optional fields on decode. Old cache entries deserialize with `unreferencedImages == null`, which is exactly right for data produced under folder-scan.

### Extensibility via uniform `ReferenceParser` interface

**Decision:** Every reference source implements one shape:

```dart
abstract class ReferenceParser {
  String get id;             // stable key used in config + profiling logs
  String get displayName;    // human-readable label for debug UI
  Future<Set<String>> collect(VramCheckerMod mod, List<_FileData> allFiles);
}
```

`ReferencedAssetsSelector` composes them from a single list declared at the top of its file, preceded by an explicit comment marker:

```dart
// ADD NEW REFERENCE PARSERS BELOW. Each must normalize its paths via PathNormalizer.
const List<ReferenceParser> _allParsers = <ReferenceParser>[
  ShipReferences(),
  WeaponReferences(),
  FactionReferences(),
  PortraitReferences(),
  SettingsGraphicsReferences(),
  GraphicsLibReferences(),
  JarStringReferences(),
  JavaSourceReferences(),
];
```

**Why a flat const list, not a registry:** Cheap to add to by hand. No DI, no service locator, no plugin API. The comment marker and the uniform interface are the whole contract. Future-you adds a file under `references/`, adds one line here, and it picks up all existing plumbing (enable/disable, attribution, profiling).

**Discipline:** every parser MUST call `PathNormalizer.normalize` on outputs. Enforced by convention — there's no compile-time check. Unit tests per parser should assert this.

### Debug configurability: `ReferencedAssetsSelectorConfig`

**Decision:** `ReferencedAssetsSelector` takes a config object on construction, persisted in `Settings` and swappable at runtime:

```dart
@MappableClass()
class ReferencedAssetsSelectorConfig with ReferencedAssetsSelectorConfigMappable {
  /// Parser ids currently enabled. Default: every registered parser's id.
  final Set<String> enabledParserIds;

  /// When true, the selector returns only referenced assets and VramMod.unreferencedImages is null.
  /// Intended for clean comparison against FolderScanSelector totals ("trust mode").
  final bool suppressUnreferenced;

  /// When true, each SelectedAsset records which parser ids flagged it.
  /// Small memory cost per row. Off by default.
  final bool trackAttribution;

  const ReferencedAssetsSelectorConfig({
    required this.enabledParserIds,
    this.suppressUnreferenced = false,
    this.trackAttribution = false,
  });
}
```

Behavior:

- **`enabledParserIds`**: `ReferencedAssetsSelector` only runs parsers whose id is in the set. An empty set is legal (produces zero references — every image becomes unreferenced, or nothing is returned if `suppressUnreferenced` is also true). Unknown ids in the set are ignored silently; the settings layer does not need to prune on schema changes.
- **`suppressUnreferenced`**: when true, skip the "emit unreferenced for everything else" pass entirely — don't even allocate. `VramMod.unreferencedImages` is set to null, so UI and aggregates treat the result just like folder-scan output (single total).
- **`trackAttribution`**: threaded through `collect()` internally — the selector keeps a `Map<String, List<String>> pathToParserIds` while unioning, then attaches `referencedBy` to each emitted `SelectedAsset`. When false, the map is never allocated and `referencedBy` is null.

**Why persisted in Settings, not just a constructor arg:** The user's debugging workflow is iterative ("flip off the JAR parser, rescan, check the diff"). Persisting through `Settings` means UI toggles work without any caller-side plumbing, and the cache key for per-selector results can include a hash of the config so changing config invalidates only that selector's cache.

**Cache keying:** The manager's per-selector result cache key becomes `(selectorId, configHash)` in reference mode. Folder-scan is unaffected. Flipping a parser off and on without other changes reuses the original cached result.

**Default config:** all parsers enabled, `suppressUnreferenced = false`, `trackAttribution = false`. Matches the headline user-facing behavior; debug features are opt-in.

### Debug UI

A collapsible **"Reference scan debug"** panel on the VRAM estimator page, visible only when the active selector is `ReferencedAssetsSelector`:

- A checkbox per parser (`displayName`), bound to `enabledParserIds`.
- A toggle for `suppressUnreferenced` with a one-line explainer ("Hide the unreferenced bucket. Useful for comparing against folder-scan totals.").
- A toggle for `trackAttribution`.
- When `trackAttribution` is on, each per-file row in the detail view shows a `referencedBy: [parser ids]` hint (e.g., tooltip on hover, or a dedicated column in the debug view). Per user memory: new icons get tooltips; extending to a new debug column, tooltip-style labeling is expected.

### Reference parsing, module layout

New files under `lib/vram_estimator/selectors/`:

```
selectors/
  vram_asset_selector.dart           # sealed interface + SelectedAsset + provenance
  folder_scan_selector.dart
  referenced_assets_selector.dart    # orchestrates the parsers below
  references/
    ship_references.dart             # data/hulls/*.ship + ship_data.csv
    weapon_references.dart           # data/weapons/*.wpn + weapon_data.csv + proj/*.proj
    faction_references.dart          # data/world/factions/*.faction
    portrait_references.dart         # data/characters/portraits/portraits.csv
    settings_graphics_references.dart# data/config/settings.json (graphics block)
    graphicslib_references.dart      # extracted from existing _getGraphicsLibSettingsForMod
    jar_string_references.dart       # constant-pool string extraction from .jar (any location)
    java_source_references.dart      # regex string-literal extraction from loose .java (any location)
  path_normalizer.dart               # one canonical form for set comparison
```

Each parser exposes `Future<Set<String>> collect(VramCheckerMod mod, List<_FileData> allFiles)`. `ReferencedAssetsSelector` unions them, normalizes, intersects with image files, and returns `SelectedAsset`s.

### Path normalization

**Decision:** All reference paths and all on-disk paths are normalized to:
- Forward slashes.
- Lowercased (Starsector's resource loader is case-insensitive on Windows and authors frequently mismatch case).
- No leading `/`.
- Extension preserved if present; when a reference omits the extension (some SS conventions auto-append `.png`), the parser emits the path both with and without `.png` appended so the intersection catches either form.

Implemented in `path_normalizer.dart` and applied uniformly on both sides of the set intersection.

### Scripting-source string extraction (JAR + loose .java)

Mods embed asset path strings in two places, both of which must be scanned:

- **Compiled `.jar` files** — typically under `jars/` but free to live anywhere in the mod; the path is declared in `mod_info.json`. Parse the constant pool of each `.class` entry and extract `CONSTANT_Utf8` entries. Implemented via `package:archive` (zip reader) plus a small custom class-file reader (header + constant pool only, no bytecode walking).
- **Loose `.java` source files** — some mods ship unbuilt sources instead of (or alongside) compiled jars. Extract double-quoted string literals via regex. This is simpler than constant-pool parsing — Java source is plain UTF-8 text.

**Decision:** Scan the **entire mod folder** for `*.jar` and `*.java`, not just `jars/`. Both scanners feed their raw string sets into the same filtering pipeline:

- Retain strings that look like asset paths: contain `/`, end in an image extension (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`), or start with a known mod resource root (`graphics/`, `data/`, `sounds/`).
- For strings that look like a directory prefix (end with `/` and start with a resource root), treat every image directly in that directory as referenced. Handles the common `"graphics/portraits/" + id + ".png"` pattern without needing dataflow analysis.

**Why scan loose `.java`:** Some scripting-heavy mods never produce a `.jar` during development or deliberately ship source for community patching. Without this, those mods would show a large misleading unreferenced bucket. Source scanning is cheap — a regex pass per file.

**Why scan jars anywhere:** `mod_info.json` declares jar locations freely. Hardcoding `jars/*.jar` would miss correctly-declared mods that use alternate layouts. The cost of walking the tree for `.jar` is negligible since we already list all files.

**Alternative considered:** Skip scripting scanning in v1. Rejected — mods with heavy scripting (e.g. Nexerelin, SWP) would show a large misleading unreferenced bucket on day one.

**Known limitations:** Obfuscated or packed jars may defeat constant-pool extraction. Heavy runtime string concatenation in either source form can produce paths that don't appear as literals. Documented in the explanation dialog.

### Performance profiling through Fimber

**Decision:** Reuse the existing `showPerformance` flag on `VramChecker` as the profiling toggle. When `showPerformance == true`, route new selector-level timing output through `Fimber.d` in addition to the existing `progressText` writes. When the flag is off, emit nothing.

**Profiling points added:**

- Total time per selector, per mod.
- Per reference-parser collection time (ship, weapon, faction, portraits, settings.json, GraphicsLib CSV, JAR, Java) in reference mode.
- JAR scan: total jars scanned, total classes parsed, total retained strings.
- Java-source scan: total files, total retained strings.
- Path-set intersection time and final set size.
- Total referenced vs. unreferenced counts per mod (for quickly sanity-checking the split on real mods).

**Why Fimber:** The rest of the codebase uses Fimber for structured logging (see `lib/main.dart`, `lib/mod_manager/homebrew_grid/wisp_grid.dart`, etc.). The existing `progressText` sink is a dev-facing text buffer surfaced in the VRAM page's verbose/debug panes; it remains useful but is not a general logging channel. Routing profiling to `Fimber.d` means it appears in the normal log stream, survives after the dialog closes, and can be filtered/searched with existing tooling.

**Alternative considered:** Add a separate `profileScans` flag distinct from `showPerformance`. Rejected — `showPerformance` already semantically means "tell me how long things took", and adding a second flag fragments the settings surface. If `showPerformance` is ever repurposed, a dedicated flag can be split out then.

**Guard discipline:** Every new profiling call site is wrapped `if (showPerformance) Fimber.d(...)`. No stopwatch is allocated when the flag is off (using a local `DateTime.timestamp().millisecondsSinceEpoch` captured only inside the guarded branch, same pattern as the existing code).

### Selector setting and caching

- `Settings.vramEstimatorSelectorId: String` persisted via existing dart_mappable settings model.
- `VramEstimatorManager` holds a `Map<String, List<VramMod>>` keyed by selector id. On selector change, if cached, reuse; otherwise trigger rescan.
- Scan invalidation follows the existing rules (mod list change, refresh click). The cache is per-session unless the existing cache already persists to disk — we piggyback on whatever is there today and do not introduce a new disk cache.
- Toolbar dropdown component is a standard Material `DropdownMenu`, placed adjacent to the existing refresh/config controls. Per CLAUDE.md: 8dp alignment; new icon (if any) gets a tooltip.

### Migration / backward compatibility

- `VramChecker` constructor gains `VramAssetSelector? selector`, defaulting to `FolderScanSelector()`. All existing call sites remain valid with no changes.
- The existing `UNUSED_INDICATOR` list and `_getGraphicsLibSettingsForMod` move into `FolderScanSelector` (or a shared helper) — behavior is byte-identical.
- Run `dart run build_runner build --delete-conflicting-outputs` after editing `@MappableClass` on `VramMod`.

## Risks / Trade-offs

- **[Risk]** Reference parser misses a valid path → legitimate image bumped to "unreferenced", total under-counts.
  - **Mitigation:** Show the unreferenced number prominently so users see the full picture. Explanation dialog calls out the known imprecision. Folder-scan remains one click away.

- **[Risk]** GraphicsLib maps accidentally excluded by the selector when the base sprite is unreferenced.
  - **Mitigation:** Selector treats GfxLib CSV rows as independent references; maps are kept whenever their CSV entry exists. Matches today's semantics exactly.

- **[Risk]** Dynamic path construction in Java code defeats reference detection.
  - **Mitigation:** Directory-prefix heuristic (treat `graphics/foo/` literal as referencing everything in that dir) catches the dominant pattern. Unreferenced bucket makes any residual misses visible.

- **[Risk]** Path case / extension mismatches between references and on-disk files cause spurious misses.
  - **Mitigation:** Shared path normalizer with lowercase + forward-slash + optional-extension expansion, applied uniformly on both sides.

- **[Risk]** JAR scanning is slow for mods with many large jars.
  - **Mitigation:** Constant-pool extraction is cheap (no bytecode walk). Throttled by the same `maxFileHandles` gate the rest of the checker uses. If it proves a bottleneck, add a file-size or jar-count cap as a follow-up. Profiling (via `showPerformance` → `Fimber.d`) surfaces per-source timing so hotspots are visible rather than mysterious.

- **[Risk]** Loose `.java` regex scanning false-positives on string constants that happen to look like paths (e.g., log messages, URLs).
  - **Mitigation:** The same filtering rules apply as for JAR strings — a literal only becomes a reference if it survives the "looks like an asset path" filter and intersects with an actual on-disk image. Spurious survivors simply don't match any file and drop out.

- **[Trade-off]** Selector choice is global, not per-mod. Simpler UX, cache story, and settings surface. Mods with dynamic loaders (e.g., Illustrated Entities) can still be accommodated via the existing `maxImages` hardcode; a future refinement could layer per-mod overrides if a real need emerges.

- **[Trade-off]** Unreferenced bucket is shown but not auto-subtracted. Some users will want a single smaller number; they can switch to folder-scan or read the referenced number and ignore the advisory. The explanation dialog will frame this clearly.

## Migration Plan

1. Extract `FolderScanSelector` from the current `check()` body without changing behavior; `VramChecker` defaults to it. Verify existing callers produce identical results (spot-check totals for a few mods).
2. Add the optional `unreferencedImages` field to `VramMod`, regenerate mappers, confirm cache reads for existing data still deserialize.
3. Build reference parsers one source at a time, each behind a unit-testable `collect()` function.
4. Wire `ReferencedAssetsSelector`, add the toolbar dropdown, plumb the setting, add the two-bucket UI.
5. Update the explanation dialog.
6. Manual validation across a small mod set (small vanilla-style mod, large content mod, GraphicsLib, a mod with heavy jar scripting) — compare folder-scan totals vs reference totals and sanity-check the unreferenced bucket.

**Rollback:** Selector defaults to folder-scan; if the new selector misbehaves for any user, switching the dropdown back restores today's numbers. No data migration to unwind.

## Open Questions

- Does `package:archive` (or another already-present package) support reading zip entries as streams? If not, we either add it or load JARs into memory (fine for typical sizes — SS mod jars rarely exceed a few MB).
- Should the selector dropdown be a prominent toolbar dropdown or tucked into the existing config/settings menu for the VRAM page? Preference here affects how visible the feature is on first launch.
- Does the existing on-disk cache (if any) need a version bump given the new optional field, or does dart_mappable's forward-compat handle it transparently? Confirm during implementation.
