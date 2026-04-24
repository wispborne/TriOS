# TriOS

All-in-one Starsector launcher, mod manager, and toolkit. Desktop-only (Windows, macOS, Linux).

## UI Conventions

- Align widgets using an 8.0 dip grid.
- Use the new `spacing` parameter in Rows and Columns instead of adding SizedBoxes, if you need to add even spacing.
- Make use of the new dot shorthands in Dart, when it makes sense. For example, `.all(8.0)` instead of `EdgeInsets.all(8.0)`.
- `.withOpacity` is deprecated.
- Make text selectable when it makes sense.

## Architecture

- **State management**: Riverpod. Use `AsyncNotifier`/`Notifier` providers, `ref.watch()` for reactive UI. NOT Bloc, NOT Provider package.
- **Serialization**: dart_mappable (`@MappableClass`, `@MappableEnum`, `.mapper.dart` files). NOT freezed.
  - Custom hooks: `DirectoryHook()`, `VersionHook()`, `SafeDecodeHook()` in `lib/utils/dart_mappable_utils.dart`.
- **Navigation**: Enum-based tabs via `TriOSTools` (`lib/trios/navigation.dart`). `AppShell` (`lib/app_shell.dart`) maps tab indices to tools. `LazyIndexedStack` for efficient tab switching.
  - Nav-icon order is user-customizable via right-click → "Rearrange icons". Order lives in `NavOrderController` (`lib/toolbar/nav_order_controller.dart`) and is persisted to `Settings.navIconOrder` as `List<NavOrderEntry>` (sealed dart_mappable model in `lib/toolbar/nav_order_entry.dart`, with `NavToolEntry` and `NavDividerEntry` variants). The sidebar and top-bar both read `navOrderProvider`. Pinned items (`Settings`, action buttons, launcher, `rules.csv`, layout toggle) are NOT in the reorderable list; `reorderableTools` in `navigation.dart` is the source of truth for what's reorderable.
- **Organization**: Feature-folder structure under `lib/`. Each feature has its own directory (e.g., `mod_manager/`, `ship_viewer/`, `weapon_viewer/`). All directory and file names use `snake_case`.

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

Two-level grouping: `GroupingSetting.secondaryGroupedByKey` is nullable; when set, each primary bucket is subdivided using that grouping. Secondary headers always render in `GroupHeaderStyle.small` regardless of the user's `headerStyle`. Drag-and-drop targets the level the user drops on (a drop on a secondary header fires that grouping's `onItemsDropped`); per-row drag targets remain wired to the primary grouping only. Collapse state is keyed per `(primary, secondary)` pair.

### Three-state filters

Filter values: `null` (indifferent), `true` (include), `false` (exclude). If any `true` values exist for a filter, items must match one; `false` values exclude regardless.

### Filter engine

All viewer filters use `lib/widgets/filter_engine/`. A sealed `FilterGroup<T>` has four variants:

- `ChipFilterGroup<T>` — tri-state multi-value chips (the former `GridFilter`)
- `BoolFilterGroup<T>` — standalone checkbox (no lock — persist via composite)
- `EnumFilterGroup<T, E>` — standalone dropdown (no lock — persist via composite)
- `CompositeFilterGroup<T>` — heterogeneous fields (`BoolField`, `EnumField`) under one lock

Each page owns a `FilterScopeController<T>(scope, groups, persistenceEnabled)`. Scope is `FilterScope(pageId, scopeId)`; single-scope pages use the default `scopeId = 'main'`. Portraits declares `main`, `left`, `right`.

The controller is a **toolkit**, not a framework: pages compose it into their own pipeline via `applyChipFilters(iter)`, `applyNonChipFilters(iter)`, `activeCount`, `clearAll`, `setChipSelections`, `loadPersisted`, `maybePersist`. The renderer `FilterGroupRenderer<T>` dispatches per-type; page filter panels iterate `controller.filterGroups` and wrap each in the renderer. Lock buttons appear on chip and composite groups only.

### Filter group persistence

Lock icon persists a group's state across sessions. Keyed by `(pageId, scopeId, groupId)`. `PersistedFilterGroup.selections: Map<String, Object?>` (schema v2) carries both chip tri-state maps and composite field values (bool / enum `.name`). Entries with non-v2 schema are silently dropped on load. Standalone bool/enum groups don't show a lock — wrap them in a `CompositeFilterGroup` to persist.

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
