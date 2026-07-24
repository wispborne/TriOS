# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# TriOS

All-in-one Starsector launcher, mod manager, and toolkit. Flutter desktop app — Windows, macOS, Linux only (no web/mobile).

## Claude Directive

- Do not use jargon.
- Do not use Opus 4.7. If you are using Opus 4.7, switch to Opus 4.6 instead.
- Use the `idea` connector when available.
- Avoid Powershell when possible. Allow the user to verify changes manually; don't run the app yourself.

## Common Commands

Note: I use `fvm` (Flutter pinned to the version in `.fvmrc`). Prefix commands with it first — `fvm flutter test`, `fvm dart run ...` — and fall back to plain `flutter`/`dart` if `fvm` isn't available.

Run all tests:

```
flutter test
```

Run a single test file or test by name:

```
flutter test test/version_sorting_test.dart
flutter test --plain-name "specific test name"
```

Static analysis (uses `flutter_lints` + `custom_lint` plugin configured in `analysis_options.yaml`):

```
flutter analyze
dart run custom_lint   # for the custom_lint plugin specifically
```

Code generation — required after editing any `@MappableClass`/`@MappableEnum` model, or any class with `.mapper.dart` / `.g.dart` siblings:

```
dart run build_runner build --delete-conflicting-outputs
# or, for continuous rebuild during development:
dart run build_runner watch --delete-conflicting-outputs
```

The Linux build needs `libcurl4-openssl-dev` installed (for Sentry). Don't use the Snap version of Flutter on Linux — install manually so it picks up system libs. Windows builds need the InAppWebView Windows setup (see https://inappwebview.dev/docs/intro/#setup-windows).

## OpenSpec Workflow

Feature work is planned with OpenSpec, under `openspec/`:

- `openspec/specs/<capability>/spec.md` — docs for completed, shipped capabilities.
- `openspec/changes/<change-id>/` — in-flight changes, each with `proposal.md`, `design.md`, and `tasks.md`. Finished changes move to `openspec/changes/archive/`.
- Use the `/opsx:*` skills (propose, apply, archive, explore) to work with changes. Check the relevant change folder before implementing a feature that already has one.

## Architecture

- **State management**: Riverpod. Use `AsyncNotifier`/`Notifier` providers, `ref.watch()` for reactive UI. NOT Bloc, NOT Provider package.
- **Serialization**: dart_mappable (`@MappableClass`, `@MappableEnum`, `.mapper.dart` files). NOT freezed.
  - Custom hooks: `DirectoryHook()`, `VersionHook()`, `SafeDecodeHook()` in `lib/utils/dart_mappable_utils.dart`.
- **Navigation**: Enum-based tabs via `TriOSTools` (`lib/trios/navigation.dart`). `AppShell` (`lib/app_shell.dart`) maps tab indices to tools. `LazyIndexedStack` for efficient tab switching. Some tools are debug-only (`debugOnlyTools` in `navigation.dart` — currently Sector Map and Codex).
- **Game data merging**: `lib/utils/game_data_merge.dart` merges CSV/JSON data from vanilla + enabled mods the same way the game does (load order, `core_clearArray`, vanilla always loses conflicts). `lib/utils/game_file_resolver.dart` resolves file paths written in data files the way the game does: each enabled mod is asked in load order, then the game core; first source with the file wins. All viewers route through these — don't hand-roll merge logic.
- **AI features**: `Settings.enableAiFeatures` (default true) is the master switch for all AI-written content. When off, TriOS shows no AI text anywhere. Display code must gate on it — for catalog AI summaries, watch `effectiveCatalogAiSummaryModeProvider` (`lib/trios/settings/app_settings_logic.dart`), which returns `AiSummaryMode.never` when the switch is off without disturbing the user's saved `catalogAiSummaryMode`. Any new AI feature should read `enableAiFeatures` the same way. The switch lives in the "AI Features" group on the settings page.
- **Viewer data cache** (`lib/viewer_cache/`): viewers load from a msgpack disk cache first, then re-parse in the background. `CachedStreamListNotifier<T, P>` is the base class (one cache file per mod variant per domain, schema-versioned via `CacheEnvelope`, stored by `CachedVariantStore`). Ships, weapons, hullmods, ship systems, wings, and the graphics-path index (`GraphicsIndexManager`) all use it.
- **Organization**: Feature-folder structure under `lib/`. Each feature has its own directory (e.g., `mod_manager/`, `ship_viewer/`, `weapon_viewer/`, `hullmod_viewer/`, `faction_viewer/`, `fighter_viewer/`, `ship_systems_manager/`, `codex/`, `sector_map/`, `portraits/`, `catalog/`, `dashboard/`, `vram_estimator/`, `chipper/`). Notable smaller ones:
  - `chatbot/` — in-app assistant answering questions about the user's mods/RAM/logs. No LLM — keyword/regex intent matching (`ChatbotEngine`, `ChatIntent` subclasses) against local app state.
  - `codex/` — unified searchable reference browser cross-linking ships, weapons, hullmods, ship systems, and wings. Debug-only for now.
  - `sector_map/` — renders a saved game's star sector as an interactive map, with a system finder. WIP, debug-only.
  - `toolbar/` — top bar: nav tab buttons and reordering, launch/game-folder action buttons, chatbot button.
  - `trios/activity_panel/` — side panel showing live and historical download/install activity.
  - `mod_records/` — persistent per-mod records of where a mod came from (catalog, version checker, forum).
  - `mod_tag_manager/` — user-defined mod categories/tags with icons and colors.
  - `mod_profiles/` — save/load named sets of enabled mods; can read enabled-mod lists from game saves.
  - `descriptions/` — loads and merges `descriptions.csv` across vanilla + mods for viewer/codex flavor text.
  - `changelogs/` — fetches and caches per-mod changelogs via version-checker URLs.
  - `launcher/`, `vmparams/` — game launch with pre-launch checks; `vmparams` RAM editing.
  - `companion_mod/` — deploys/updates TriOS's bundled companion Starsector mod.
  - `rules_autofresh/` — watches `rules.csv` and triggers the game's rules hot-reload.
  - `onboarding/`, `tips/`, `about/` — first-run carousel, loading-screen tips viewer, About page.
- **Platform-native bits**: `windows/`, `macos/`, `linux/` for native runners. Archive support via 7-Zip CLI wrapper (`lib/compression/`). Crash reporting via Sentry (initialized in `main.dart`).
- **Generated files** are excluded from analysis: `build/**`, `lib/**.freezed.dart`, `lib/**.g.dart`, `lib/libarchive/libarchive_bindings.dart`.

## UI Conventions

- Align widgets using an 8.0 dip grid.
- Use the new `spacing` parameter on `Row`/`Column` instead of `SizedBox` separators when spacing is even.
- Prefer Dart's dot shorthand — e.g. `.all(8.0)` over `EdgeInsets.all(8.0)`.
- Instead of using `tooltip`, use `MovingTooltipWidget.text`.

## Common Widgets

Reusable widgets in `lib/widgets/` and shared components. Use these before building new UI.

### Tooltips & Overlays

- `MovingTooltipWidget` (`lib/widgets/moving_tooltip.dart`) — Mouse-tracking tooltip. Static factories: `.text()`, `.framed()`, `.starsector()`, `.image()`. Prefer `.text()` over Flutter's `tooltip`.
- `TooltipFrame` (`lib/widgets/tooltip_frame.dart`) — Styled frame for tooltip content with optional rainbow border.
- `ingame_tooltip_shared.dart` (`lib/widgets/ingame_tooltip_shared.dart`) — Shared helpers for game-style tooltips: `tooltipTitle()`, `tooltipTitleWithDesignType()`, `tooltipSectionHeader()`, `tooltipStatsGrid()`, `tooltipHairline()`, and the `TooltipStatEntry` model.
- `ModTooltipFancyTitleHeader` (`lib/widgets/fancy_mod_tooltip_header.dart`) — Tooltip header tinted with colors pulled from the mod's icon.
- `UnderConstructionOverlay` (`lib/widgets/under_construction_overlay.dart`) — "Under construction" tape overlay for WIP features.

### Text

- `TextTriOS` (`lib/widgets/text_trios.dart`) — Text that auto-shows tooltip when it overflows. Supports intrinsic dimensions.
- `TextWithIcon` (`lib/widgets/text_with_icon.dart`) — Row of icon + text with flexible padding.
- `StrokeText` (`lib/widgets/stroke_text.dart`) — Text with outline/stroke effect.
- `DescriptionWithSubstitutions` (`lib/widgets/description_with_substitutions.dart`) — Game description text with `%s` substitutions highlighted.
- `Code` (`lib/widgets/code.dart`) — Monospace text for code/JSON display.

### Buttons & Controls

- `DenseButton` (`lib/widgets/dense_button.dart`) — Compact button theme wrapper. `density` param: `DenseButtonStyle.compact` or `.extraCompact`.
- `CheckboxWithLabel` (`lib/widgets/checkbox_with_label.dart`) — Checkbox with label, supports tristate.
- `TriOSToolbarCheckboxButton` / `TriOSToolbarItem` (`lib/widgets/toolbar_checkbox_button.dart`) — Checkbox styled for toolbars; generic toolbar item container.
- `TriOSDropdownButton<T>` (`lib/widgets/trios_dropdown_button.dart`) — Themed dropdown button.
- `TriOSDropdownMenu<T>` (`lib/widgets/trios_dropdown_menu.dart`) — Material 3 dropdown menu with TriOS defaults.
- `TriOSRadioTile<T>` (`lib/widgets/trios_radio_tile.dart`) — Radio button as a list tile.
- `TristateIconButton` (`lib/widgets/tristate_icon_button.dart`) — Icon button cycling through true/false/null.
- `OverflowMenuButton` (`lib/widgets/overflow_menu_button.dart`) — Three-dot popup menu.
- `PopupStyleMenuAnchor` (`lib/widgets/popup_style_menu_anchor.dart`) — MenuAnchor styled like PopupMenuButton.
- `AnimatedPopupMenuButton<T>` (`lib/widgets/dropdown_with_icon.dart`) — Animated dropdown menu with icon.
- `TextLinkButton` (`lib/widgets/text_link_button.dart`) — Text styled as clickable link.
- `SpinningRefreshButton` (`lib/widgets/spinning_refresh_button.dart`) — Refresh button with spinning animation.
- `AddNewModsButton` (`lib/widgets/add_new_mods_button.dart`) — Button to add new mods (file picker).
- `RefreshModsButton` (`lib/widgets/refresh_mods_button.dart`) — Button to refresh mod list.
- `ModeSwitcher<T>` (`lib/widgets/mode_switcher.dart`) — Generic segmented-button mode/tab switcher.
- `GraphTypeSelector` (`lib/widgets/graph_radio_selector.dart`) — Segmented-button selector for graph types.

### Layout & Structure

- `ConditionalWrap` (`lib/widgets/conditional_wrap.dart`) — Conditionally wraps child in a wrapper widget.
- `LazyIndexedStack` (`lib/widgets/lazy_indexed_stack.dart`) — IndexedStack that builds children lazily on first display.
- `ViewerSplitPane` (`lib/widgets/viewer_split_pane.dart`) — Split-pane layout for side-by-side comparison.
- `CenteredWidgetWithItemAfter` (`lib/widgets/centered_widget_with_item_after.dart`) — Centers a widget with another positioned after it.
- `ExpandingConstrainedAlignedWidget` (`lib/widgets/expanding_constrained_aligned_widget.dart`) — Expands to fill space with optional alignment.
- `SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight` (`lib/widgets/fixed_height_grid_item.dart`) — Grid delegate with fixed row height.
- `WispAdaptiveGridView<T>` (`lib/widgets/wisp_adaptive_grid_view.dart`) — Responsive grid with auto row height.
- `SideRail` / `SideRailPanel` (`lib/catalog/side_rail/side_rail.dart`) — IDE-style collapsible right-side panel rail.
- `CompactListTile` (`lib/widgets/compact_list_tile.dart`) — Minimal-padding list tile.
- `SimpleDataRow` (`lib/widgets/simple_data_row.dart`) — Label + bold value display row.
- `SettingsGroup` (`lib/widgets/settings_group.dart`) — Section header with divider for settings pages. Static factory: `.subsection()`.
- `MultiSplitViewMixin` (`lib/widgets/multi_split_mixin_view.dart`) — State mixin that wires up a `MultiSplitViewController` for resizable split layouts.

### State & Interaction

- `Disable` (`lib/widgets/disable.dart`) — Disables child with opacity reduction and pointer absorption.
- `DisableIfCannotWriteMods` (`lib/widgets/disable_if_cannot_write_mods.dart`) — Disables when mods folder not writable.
- `DisableIfCannotWriteGameFolder` (`lib/widgets/disable_if_cannot_write_game_folder.dart`) — Disables when game folder not writable.
- `HoverableWidget` / `HoverData` (`lib/widgets/hoverable_widget.dart`) — Detects hover state, provides `HoverData` to descendants.
- `HoverableRow` (`lib/widgets/hoverable_row.dart`) — Row with hover highlighting.
- `Highlightable` (`lib/widgets/highlightable.dart`) — Programmatic highlight with glow animation, auto-scrolls into view.
- `InlineEditText` (`lib/widgets/inline_edit_text.dart`) — In-place text editing (display to edit mode).
- `RestartableApp` (`lib/widgets/restartable_app.dart`) — Wrapper that can soft-restart the widget tree: `RestartableApp.softRestartApp(context)`.

### Progress & Feedback

- `ThemedCircularProgressIndicator` / `ThemedLinearProgressIndicator` (`lib/widgets/rainbow/themed_progress_indicator.dart`) — Progress indicators with optional rainbow gradient.
- `ThemedAccentBar` (`lib/widgets/rainbow/themed_accent_bar.dart`) — Animated rainbow accent bar.
- `TriOSDownloadProgressIndicator` (`lib/widgets/download_progress_indicator.dart`) — Download progress with state tracking.
- `showSnackBar()` (`lib/widgets/snackbar.dart`) — Themed snackbar function. Types: `SnackBarType.info`, `.warn`, `.error`.

### Chips, Badges & Tags

- `DisplayChip` (`lib/widgets/display_chip.dart`) — Non-interactive read-only chip (avatar + label).
- `FilterPill` (`lib/widgets/filter_pill.dart`) — Removable filter indicator badge.
- `CollapsedFilterButton` (`lib/widgets/collapsed_filter_button.dart`) — Filter toggle button with count badge.

### Icons & Images

- `SvgImageIcon` (`lib/widgets/svg_image_icon.dart`) — SVG asset as icon with IconTheme integration.
- `ModIcon` (`lib/widgets/mod_icon.dart`) — Mod icon from file path. Static factories: `.fromMod()`, `.fromVariant()`.
- `ModTypeIcon` (`lib/widgets/mod_type_icon.dart`) — Icon indicating mod type (total conversion, utility, etc.).
- `TriOSAppIcon` (`lib/widgets/trios_app_icon.dart`) — Animated app icon with optional rainbow gradient.
- `BrokenShipImageWidget` (`lib/widgets/broken_ship_image_widget.dart`) — Banana placeholder for missing/undecodable *ship* sprites (use as `Image.file` `errorBuilder`). Other missing images use a plain broken-image icon.
- `PaletteGeneratorMixin` (`lib/widgets/palette_generator_mixin.dart`) — State mixin that extracts a color palette from an image (cached per path).

### Borders & Visual Effects

- `RainbowBorder` (`lib/widgets/rainbow_accent_bar.dart`) — Rainbow gradient border wrapper, used when `theme.rainbowAccent == true`.
- `DottedBorder` (`lib/widgets/dotted_border.dart`) — Dotted/dashed border (Circle, RRect, Rect, Oval).
- `AnimatedGradientBorder` (`lib/widgets/animated_gradient_border.dart`) — Animated gradient border effect.
- `Blur` (`lib/widgets/blur.dart`) — Blur effect on child widget.
- `GlitterBackground` (`lib/widgets/glitter_background.dart`) — Animated background-effect host. Effects live in `lib/widgets/background_effects/` (aurora, circuitry, constellation, embers, motes, nebula, radar, rain, starfield), each extending `BackgroundEffect`.

### Expansion

- `TriOSExpansionTile` (`lib/widgets/trios_expansion_tile.dart`) — Themed expansion tile.

### Filter Engine (`lib/widgets/filter_engine/`)

- `FilterScope` — Identity key for a filter scope (`pageId` + `scopeId`).
- `FilterGroup<T>` (sealed) — Base class. Subtypes: `ChipFilterGroup<T>`, `BoolFilterGroup<T>`, `EnumFilterGroup<T, E>`, `CompositeFilterGroup<T>`.
- `FilterField<T>` (sealed) — Field inside a `CompositeFilterGroup`. Subtypes: `BoolField<T>`, `StringChoiceField<T>`, `EnumField<T, E>`.
- `FilterScopeController<T>` — Controller for managing filter groups and applying matches.
- `FilterGroupRenderer<T>` — Renders a `FilterGroup` as interactive UI.
- `GridFilterWidget<T>` / `FiltersPanel` (`lib/widgets/filter_widget.dart`) — Chip filter UI and collapsible filter panel.

### Filter Persistence (`lib/widgets/filter_group_persistence/`)

- `PersistedFilterGroup` — Serializable filter group state (`@MappableClass`).
- `FilterGroupPersistence` — Riverpod-backed reader/writer for persisted filter state.
- `FilterGridPersistButton` — Lock-icon toggle to persist a filter group across sessions.

### Smart Search (`lib/widgets/smart_search/`)

- `SmartSearchBar` — Advanced search bar with DSL, autocomplete suggestions, and history.
- `SearchField<T>` / `SearchFieldMeta` — Typed field definition for DSL search.
- DSL parser (`search_dsl_parser.dart`) — Parses queries like `type:weapon damage:>100`.

### Game Paths (`lib/widgets/game_paths_widget/`)

- `GamePathsWidget` — Game paths configuration UI.
- `CustomPathField` — Path input with file picker and checkbox toggle.

### Viewer Widgets

See [Shared viewer widgets](#shared-viewer-widgets) and [WispGrid](#wispgrid) under Viewer Page Pattern.

### Dialogs & Functions

- `showExportOrCopyDialog()` (`lib/widgets/export_to_csv_dialog.dart`) — Dialog for exporting data as CSV or copying to clipboard.
- `DragDropInstallModOverlay` (`lib/widgets/file_card.dart`) — Drag-drop overlay for mod installation.
- `TriOSChangelogViewer` (`lib/widgets/changelog_viewer.dart`) — Formatted changelog display.
- `mergeModSourcesView()` (`lib/widgets/merge_mod_sources_view.dart`) — Mod-attribution lines for ship/weapon details dialogs ("Mod: X", or split Stats/file lines with hover breakdowns when mods overlap).

## Common Utilities

Reusable functions and extensions in `lib/utils/`. Use these before writing new helpers.

### JSON & Data Parsing

- `String.parseJsonToMap()` (`lib/utils/extensions.dart`) — Parse Starsector JSON-ish files (handles trailing commas, `//` comments, unquoted keys). 3-tier fallback: raw → fixups → YAML.
- `String.parseJsonToMapAsync()` (`lib/utils/extensions.dart`) — Async version of `parseJsonToMap()`.
- `Map.removeNullValues()` (`lib/utils/extensions.dart`) — Recursively strip null entries from a JSON map.
- `Map.prettyPrintJson()` (`lib/utils/extensions.dart`) — Pretty-print a map as indented JSON.
- `CsvJsonParsingUtils` (`lib/utils/csv_parse_utils.dart`) — CSV/JSON comment removal, safe CSV parsing, row-to-typed-map conversion.

### Timestamps & Formatting

- `DateTime.relativeTimestamp()` (`lib/utils/relative_timestamp.dart`) — Human-readable relative time, e.g. "5 hours ago", "in 3 days".
- `DateTime.ageCompact()` (`lib/utils/relative_timestamp.dart`) — Compact age: "5s", "3m", "2h", "4d".
- `Duration.toCompactString()` (`lib/utils/relative_timestamp.dart`) — Compact duration: "5s", "3m", "2h", "4d".
- `num?.asCredits()` (`lib/utils/extensions.dart`) — Format number as Starsector credits with `¢` suffix and thousands separators.
- `int.bytesAsReadable()` (`lib/utils/extensions.dart`) — Human-readable byte count: auto-selects B/KB/MB.

### String Extensions (`lib/utils/extensions.dart`)

- `String.toDirectory()` / `.toFile()` — Convert path string to `Directory`/`File`.
- `String.take(n)` / `.takeLast(n)` — First/last N characters.
- `String.compareRecognizingNumbers()` — Natural sort comparison ("item2" < "item10").
- `String.fixFilenameForFileSystem()` — Strip illegal filename characters.
- `String.toTitleCase()` — Convert to title case, treating underscores as word separators.
- `String.containsAny()` / `.containsAnyIgnoreCase()` — Check if string contains any of the given substrings.

### File & Directory Extensions (`lib/utils/extensions.dart`)

- `File.relativePath(baseFolder)` — Relative path from a base directory.
- `File.moveTo(destDir)` — Move file to a directory with optional overwrite.
- `File.readAsStringUtf8OrLatin1()` — Read as UTF-8, falling back to Latin-1 (for Starsector CSVs with non-UTF-8 bytes).
- `File.showInExplorer()` — Reveal file in OS file manager (Windows Explorer, Finder, xdg-open).
- `Directory.copyDirectory(destDir)` — Recursive directory copy.
- `Directory.swapDirectoryWith()` — Atomic directory swap with rollback on failure.

### Collection Extensions (`lib/utils/extensions.dart`)

- `Iterable.mapNotNull()` — Map + filter nulls in one pass.
- `Iterable.flatMap()` — Map each element to an iterable, then flatten.
- `Iterable.sortedByButBetter()` — Sort by selector with null handling (`nullsLast` option).
- `Iterable.maxByOrNull()` / `.minByOrNull()` — Max/min by selector, null-safe.
- `Iterable.zipWithNext()` — Pair each element with its successor.
- `Iterable.filter()` — Alias for `where()`.
- `List<Future>.awaitAll()` — Alias for `Future.wait()`.
- `List<Future>.awaitPooled(poolSize)` — Concurrent future execution with pool limit.

### Kotlin-style Scoping (`lib/utils/extensions.dart`)

- `T.also(block)` — Run a side-effect block on a value, return the value.
- `T.let(block)` — Transform a value through a block, return the result.

### Color (`lib/utils/extensions.dart`)

- `HexColorExt.fromHex(hexString)` — Parse hex string ("aabbcc" or "#ffaabbcc") to `Color`.
- `Color.toHex()` — Convert `Color` to hex string.

### Game Data Merging & File Resolution

- `game_data_merge.dart` (`lib/utils/game_data_merge.dart`) — Shared merge rules for vanilla + mod data (CSV rows, JSON maps, `.wpn`/`.ship` pairing). `MergeSource` identifies a source (mod variant or `kVanillaSourceKey`); `ItemModSources` tracks which mod supplied what. No disk I/O — raw data in, merged data out.
- `GameFileResolver` (`lib/utils/game_file_resolver.dart`) — Resolves a path written in a data file the way the game does: every enabled mod in load order, then the game core; first source with the file wins. Case-insensitive lookups.

### Search

- `updateSearchIndices()` (`lib/utils/search_index.dart`) — Incrementally update a search index cache (remove gone items, add new ones).
- `mod_search.dart` (`lib/utils/mod_search.dart`) — Search index/tags for installed mods (`createSearchIndex()`, `createSearchTags()`).
- `catalog_search.dart` (`lib/utils/catalog_search.dart`) — Catalog mod search plus lenient version comparison for scraped version strings.

### Background Work

- `AppWorker` (`lib/utils/app_worker.dart`) — Runs functions on a long-lived background isolate. Riverpod provider: `appWorkerProvider`.

### Debouncing

- `Debouncer` (`lib/utils/debouncer.dart`) — Debounce async operations. First call executes immediately; subsequent calls within the window are coalesced.

### Logging

- `Fimber` (`lib/utils/logging.dart`) — Static logging facade. Levels: `.v()` (verbose), `.d()` (debug), `.i()` (info), `.w()` (warning), `.e()` (error). Logs to console, file, and Sentry.
- `LogCollapser` (`lib/utils/log_collapser.dart`) — Collapses repeated warnings into one line with `(xN)` counts; stays quiet if the same summary was logged recently. Used by merge code that re-runs often.

### HTTP & Caching

- `TriOSHttpClient` (`lib/utils/http_client.dart`) — HTTP client with concurrency queue, retry logic, and progress callbacks. Riverpod provider: `triOSHttpClient`.
- `CachedJsonFetcher` (`lib/utils/cached_json_fetcher.dart`) — Fetch JSON from a URL with on-disk TTL cache and stale-cache fallback on network error.

### Settings Persistence

- `GenericAsyncSettingsManager<T>` (`lib/utils/generic_settings_manager.dart`) — Abstract settings file manager with debounced writes, file-lock retry, and backup support.
- `GenericSettingsAsyncNotifier<T>` (`lib/utils/generic_settings_notifier.dart`) — Riverpod `AsyncNotifier` base class that auto-persists state via a settings manager.

### Platform & Misc

- `platform_paths.dart` (`lib/utils/platform_paths.dart`) — Per-platform game paths: JRE folder, Java executable, etc.
- `platform_specific.dart` (`lib/utils/platform_specific.dart`) — OS-specific operations, e.g. `FileSystemEntity.moveToTrash()` (Recycle Bin / Trash per platform).
- `NetworkUtils` (`lib/utils/network_util.dart`) — Fetch GitHub releases (used for TriOS self-update).
- `MapDiff` / `MapComparer` (`lib/utils/map_diff.dart`) — Compare two maps; returns added/removed/modified entries.
- `dialogs.dart` (`lib/utils/dialogs.dart`) — Shared app dialogs (alerts, confirmations, etc.).

### Serialization Hooks (`lib/utils/dart_mappable_utils.dart`)

Custom dart_mappable hooks for common types: `VersionHook`, `DirectoryHook`, `FileHook`, `BoolHook`, `ColorHook`, `StringArrayHook` ("a,b,c" ↔ list), `SafeDecodeHook<T>` (catch errors, return default), `SkipSerializationHook`.

## Viewer Page Pattern

All viewer pages (ships, weapons, hullmods, portraits, factions) follow this template:

- **Page** (`xxx_page.dart`): `ConsumerStatefulWidget` with `AutomaticKeepAliveClientMixin`. Builds toolbar, filter panel, and grid.
- **Controller** (`xxx_page_controller.dart`): `Notifier<XxxPageState>`. Manages filters, search, UI toggles.
- **State**: Split into `XxxPageState` (ephemeral) and `XxxPageStatePersisted` (saved to app settings). Both use `@MappableClass`.
- **Manager** (`xxx_manager.dart`): Loads and provides data (CSV parsing, file I/O). Newer managers (ships, weapons, hullmods, ship systems, wings) extend `CachedStreamListNotifier` (`lib/viewer_cache/`) — cache-first load, then background re-parse — and merge per-mod data through `lib/utils/game_data_merge.dart`.
- **Models** (`models/` subdirectory): Data classes with `@MappableClass`, CSV field mapping via `@MappableField(key: 'csv-column-name')`.

### Shared viewer widgets

- `ViewerToolbar` — count, search, refresh, split-pane toggle
- `ViewerSearchBox` — search input
- `ViewerSplitPane` — split view comparison
- `CollapsedFilterButton` / `FiltersPanel` — filter UI

### WispGrid

Custom grid component in `lib/mod_manager/homebrew_grid/`. Used for viewer page grids and the mod manager grid. Supports grouped rows, sortable columns, state persistence, and multiple layout modes.

### Three-state filters

Filter values: `null` (indifferent), `true` (include), `false` (exclude). If any `true` values exist for a filter, items must match one; `false` values exclude regardless.

## Key Entry Points

- `lib/main.dart` — App bootstrap, window setup, crash detection, Sentry init
- `lib/app_shell.dart` — Main navigation shell, tab routing, sidebar
- `lib/trios/app_state.dart` — Central Riverpod providers (mods, settings, themes, etc.)
- `lib/trios/navigation.dart` — `TriOSTools` enum (all navigable tools)
- `lib/trios/settings/settings.dart` — Settings model
- `lib/trios/constants.dart` — App-wide constants
- `lib/models/` — Core domain models (Mod, ModVariant, ModInfo, Version)
- `lib/mod_manager/mod_manager_logic.dart` — Core mod enable/disable/install logic
- `lib/mod_manager/homebrew_grid/wisp_grid.dart` — WispGrid implementation
- `lib/utils/game_data_merge.dart` — Merge rules for vanilla + mod game data
- `lib/viewer_cache/` — Cache-first loading base classes for viewers
- `lib/widgets/` — Shared reusable widgets
- `lib/utils/` — Utility functions and extensions

## Key Concepts

- **Mod** — groups all variants of a mod by ID
- **ModVariant** — a specific version/installation of a mod
- **SmolId** — compact identifier for mod variants based on the mod id + mod version: `{id6chars}-{version9chars}-{hash}`
- **TriOSTools** — enum of all app tools/pages (dashboard, modManager, ships, weapons, etc.)

## Starsector Game Code

- Copied to `starsector-core` for convenient reference. Not added to git.
- Critical: read only! Do not modify the game code.
- Game obfuscated code is decompiled in `starsector-core/decompiled_obf`.