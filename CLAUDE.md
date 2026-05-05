# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# TriOS

All-in-one Starsector launcher, mod manager, and toolkit. Flutter desktop app — Windows, macOS, Linux only (no web/mobile). Dart SDK 3.10.7 / Flutter 3.38.6.

## Common Commands

Build the app for the current platform:

```
flutter build windows   # or macos / linux
```

Run in development:

```
flutter run -d windows  # or macos / linux
```

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

Regenerate FFI bindings for bit7z (Windows archive support):

```
dart run ffigen --config build_bit7z_bindings.yaml
```

The Linux build needs `libcurl4-openssl-dev` installed (for Sentry). Don't use the Snap version of Flutter on Linux — install manually so it picks up system libs. Windows builds need the InAppWebView Windows setup (see https://inappwebview.dev/docs/intro/#setup-windows).

## Architecture

- **State management**: Riverpod. Use `AsyncNotifier`/`Notifier` providers, `ref.watch()` for reactive UI. NOT Bloc, NOT Provider package.
- **Serialization**: dart_mappable (`@MappableClass`, `@MappableEnum`, `.mapper.dart` files). NOT freezed.
  - Custom hooks: `DirectoryHook()`, `VersionHook()`, `SafeDecodeHook()` in `lib/utils/dart_mappable_utils.dart`.
- **Navigation**: Enum-based tabs via `TriOSTools` (`lib/trios/navigation.dart`). `AppShell` (`lib/app_shell.dart`) maps tab indices to tools. `LazyIndexedStack` for efficient tab switching.
- **Organization**: Feature-folder structure under `lib/`. Each feature has its own directory (e.g., `mod_manager/`, `shipViewer/`, `weaponViewer/`, `vram_estimator/`, `chipper/`).
- **Platform-native bits**: `windows/`, `macos/`, `linux/` for native runners. Archive support via bit7z FFI bindings (`lib/bit7z/bit7z_bindings.dart` — generated, excluded from analyzer). Crash reporting via Sentry (initialized in `main.dart`).
- **Generated files** are excluded from analysis: `build/**`, `lib/**.freezed.dart`, `lib/**.g.dart`, `lib/libarchive/libarchive_bindings.dart`.

## UI Conventions

- Align widgets using an 8.0 dip grid.
- Use the new `spacing` parameter on `Row`/`Column` instead of `SizedBox` separators when spacing is even.
- Prefer Dart's dot shorthand where it reads cleanly — e.g. `.all(8.0)` over `EdgeInsets.all(8.0)`.

## Viewer Page Pattern

All viewer pages (ships, weapons, hullmods, portraits) follow this template:

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

Custom grid component in `lib/mod_manager/homebrew_grid/`. Used for all data grids. Supports grouped rows, sortable columns, state persistence, and multiple layout modes.

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
