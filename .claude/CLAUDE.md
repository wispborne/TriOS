# TriOS

All-in-one Starsector launcher, mod manager, and toolkit. Desktop-only (Windows, macOS, Linux).

## UI Conventions

- Align widgets using an 8.0 dip grid.
- Use the new `spacing` parameter in Rows and Columns instead of adding SizedBoxes, if you need to add even spacing.
- Make use of the new dot shorthands in Dart, when it makes sense.

## Architecture

- **State management**: Riverpod. Use `AsyncNotifier`/`Notifier` providers, `ref.watch()` for reactive UI. NOT Bloc, NOT Provider package.
- **Serialization**: dart_mappable (`@MappableClass`, `@MappableEnum`, `.mapper.dart` files). NOT freezed.
  - Custom hooks: `DirectoryHook()`, `VersionHook()`, `SafeDecodeHook()` in `lib/utils/dart_mappable_utils.dart`.
- **Navigation**: Enum-based tabs via `TriOSTools` (`lib/trios/navigation.dart`). `AppShell` (`lib/app_shell.dart`) maps tab indices to tools. `LazyIndexedStack` for efficient tab switching.
- **Organization**: Feature-folder structure under `lib/`. Each feature has its own directory (e.g., `mod_manager/`, `shipViewer/`, `weaponViewer/`).

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

## Code Generation

After changing any `@MappableClass` or `@MappableEnum` model:

```
dart run build_runner build --delete-conflicting-outputs
```

Or for continuous rebuilds during development:

```
dart run build_runner watch --delete-conflicting-outputs
```

## Key Concepts

- **Mod** — groups all variants of a mod by ID
- **ModVariant** — a specific version/installation of a mod
- **SmolId** — compact identifier for mod variants: `{id6chars}-{version9chars}-{hash}`
- **TriOSTools** — enum of all app tools/pages (dashboard, modManager, ships, weapons, etc.)
