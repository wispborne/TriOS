# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# TriOS

All-in-one Starsector launcher, mod manager, and toolkit. Flutter desktop app — Windows, macOS, Linux only (no web/mobile).

## Claude Directive

- Do not use jargon.
- Do not use Opus 4.7. If you are using Opus 4.7, switch to Opus 4.6 instead.
- Use the `idea` connector when available.
- Avoid Powershell when possible. Allow the user to verify changes manully; don't run the app yourself.

## Common Commands

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

## Architecture

- **State management**: Riverpod. Use `AsyncNotifier`/`Notifier` providers, `ref.watch()` for reactive UI. NOT Bloc, NOT Provider package.
- **Serialization**: dart_mappable (`@MappableClass`, `@MappableEnum`, `.mapper.dart` files). NOT freezed.
  - Custom hooks: `DirectoryHook()`, `VersionHook()`, `SafeDecodeHook()` in `lib/utils/dart_mappable_utils.dart`.
- **Navigation**: Enum-based tabs via `TriOSTools` (`lib/trios/navigation.dart`). `AppShell` (`lib/app_shell.dart`) maps tab indices to tools. `LazyIndexedStack` for efficient tab switching.
- **Organization**: Feature-folder structure under `lib/`. Each feature has its own directory (e.g., `mod_manager/`, `ship_viewer/`, `weapon_viewer/`, `hullmod_viewer/`, `faction_viewer/`, `portraits/`, `catalog/`, `dashboard/`, `vram_estimator/`, `chipper/`).
- **Platform-native bits**: `windows/`, `macos/`, `linux/` for native runners. Archive support via 7-Zip CLI wrapper (`lib/compression/`). Crash reporting via Sentry (initialized in `main.dart`).
- **Generated files** are excluded from analysis: `build/**`, `lib/**.freezed.dart`, `lib/**.g.dart`, `lib/libarchive/libarchive_bindings.dart`.

## UI Conventions

- Align widgets using an 8.0 dip grid.
- Use the new `spacing` parameter on `Row`/`Column` instead of `SizedBox` separators when spacing is even.
- Prefer Dart's dot shorthand where it reads cleanly — e.g. `.all(8.0)` over `EdgeInsets.all(8.0)`.
- Instead of using `tooltip`, use `MovingTooltipWidget.text`.

## Common Widgets

Reusable widgets in `lib/widgets/` and shared components. Use these before building new UI.

### Tooltips & Overlays

- `MovingTooltipWidget` (`lib/widgets/moving_tooltip.dart`) — Mouse-tracking tooltip. Static factories: `.text()`, `.framed()`, `.starsector()`, `.image()`. Prefer `.text()` over Flutter's `tooltip`.
- `TooltipFrame` (`lib/widgets/tooltip_frame.dart`) — Styled frame for tooltip content with optional rainbow border.
- `ingame_tooltip_shared.dart` (`lib/widgets/ingame_tooltip_shared.dart`) — Shared helpers for game-style tooltips: `tooltipTitle()`, `tooltipTitleWithDesignType()`, `tooltipSectionHeader()`, `tooltipStatsGrid()`, `tooltipHairline()`, and the `TooltipStatEntry` model.

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

### State & Interaction

- `Disable` (`lib/widgets/disable.dart`) — Disables child with opacity reduction and pointer absorption.
- `DisableIfCannotWriteMods` (`lib/widgets/disable_if_cannot_write_mods.dart`) — Disables when mods folder not writable.
- `DisableIfCannotWriteGameFolder` (`lib/widgets/disable_if_cannot_write_game_folder.dart`) — Disables when game folder not writable.
- `HoverableWidget` / `HoverData` (`lib/widgets/hoverable_widget.dart`) — Detects hover state, provides `HoverData` to descendants.
- `HoverableRow` (`lib/widgets/hoverable_row.dart`) — Row with hover highlighting.
- `Highlightable` (`lib/widgets/highlightable.dart`) — Programmatic highlight with glow animation, auto-scrolls into view.
- `InlineEditText` (`lib/widgets/inline_edit_text.dart`) — In-place text editing (display to edit mode).

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

### Borders & Visual Effects

- `RainbowBorder` (`lib/widgets/rainbow_accent_bar.dart`) — Rainbow gradient border wrapper, used when Pride theme is active.
- `DottedBorder` (`lib/widgets/dotted_border.dart`) — Dotted/dashed border (Circle, RRect, Rect, Oval).
- `AnimatedGradientBorder` (`lib/widgets/animated_gradient_border.dart`) — Animated gradient border effect.
- `Blur` (`lib/widgets/blur.dart`) — Blur effect on child widget.

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

## Viewer Page Pattern

All viewer pages (ships, weapons, hullmods, portraits, factions) follow this template:

- **Page** (`xxx_page.dart`): `ConsumerStatefulWidget` with `AutomaticKeepAliveClientMixin`. Builds toolbar, filter panel, and grid.
- **Controller** (`xxx_page_controller.dart`): `Notifier<XxxPageState>`. Manages filters, search, UI toggles.
- **State**: Split into `XxxPageState` (ephemeral) and `XxxPageStatePersisted` (saved to app settings). Both use `@MappableClass`.
- **Manager** (`xxx_manager.dart`): Loads and provides data (CSV parsing, file I/O).
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
- `lib/widgets/` — Shared reusable widgets
- `lib/utils/` — Utility functions and extensions

## Key Concepts

- **Mod** — groups all variants of a mod by ID
- **ModVariant** — a specific version/installation of a mod
- **SmolId** — compact identifier for mod variants: `{id6chars}-{version9chars}-{hash}`
- **TriOSTools** — enum of all app tools/pages (dashboard, modManager, ships, weapons, etc.)

## Starsector Game Code

- Copied to `starsector-core` for convenient reference. Not added to git.
- Critical: read only! Do not modify the game code.
- Game obfuscated code is decompiled in `starsector-core/decompiled_obf`.