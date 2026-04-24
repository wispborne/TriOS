## Why

The navigation order in both the sidebar and the top-bar is hard-coded. Users who rely on specific tools (e.g. Ships + Weapons as their daily drivers, or Catalog right next to Mods) must scan past icons they rarely use. Letting them rearrange the 11 main navigation icons — including moving them across the core/viewers divider — makes the launcher feel personal and shaves clicks off every session.

## What Changes

- Add a persisted per-user custom ordering for the 11 main navigation items: `dashboard`, `modManager`, `modProfiles`, `catalog`, `chipper`, `vramEstimator`, `ships`, `weapons`, `hullmods`, `portraits`, `tips`.
- The two sections (core / viewers) keep their divider, but the divider becomes a draggable item in the order. Icons can flow freely across it, and users can reposition the divider itself.
- A single shared order drives both the sidebar (`AppSidebar`) and the top-bar (`FullTopBar`). Changing the order in one layout updates the other.
- Reordering is gated behind a new **drag mode** entered via a right-click context menu on the toolbar/sidebar background. While drag mode is active:
  - A visible "Done" affordance appears.
  - Icons show drag affordances (grab cursor, subtle shake/outline).
  - Clicking an icon does NOT navigate — it only selects for drag.
- The right-click context menu contains two actions: **Rearrange icons** (toggle drag mode) and **Reset to default order**.
- Non-reorderable items stay pinned at their existing positions: the collapse/menu toggle, launcher button, April-Fools chatbot button, `rules.csv` hot-reload, layout toggle, `Settings`, Open-Game-Folder / Log-File / Bug-Report / Debug / Changelog / About / Donate / Permission-Shield action buttons, and the rainbow accent bar.
- Custom order is persisted to `appSettings` via dart_mappable so it survives restarts.

## Capabilities

### New Capabilities
- `nav-icon-reordering`: Drag-and-drop reordering of the 11 main navigation icons in both sidebar and top-bar layouts, gated by a right-click drag-mode toggle, with a shared persisted order and a reset-to-default action.

### Modified Capabilities
<!-- None — the sidebar and top-bar are not currently covered by existing specs. -->

## Impact

- **Code — UI**:
  - `lib/toolbar/app_sidebar.dart`: replace the two hard-coded `Column` blocks of `_SidebarNavItem` with a reorderable list driven by the custom order; add right-click menu to the sidebar background.
  - `lib/toolbar/full_top_bar.dart`: replace the hard-coded `_coreTabButton` / `_viewerIconButton` calls with a reorderable row driven by the same order; add right-click menu to the toolbar background.
  - New `lib/toolbar/nav_order_controller.dart` (Riverpod `Notifier`) that owns the active order, default order, drag-mode flag, and persistence wiring.
  - New `lib/toolbar/nav_reorder_menu.dart` with the right-click context menu entries.
- **Code — settings**:
  - `lib/trios/settings/settings.dart`: add a `navIconOrder: List<NavOrderEntry>?` field (nullable so missing/old settings fall back to the default).
  - New `lib/toolbar/nav_order_entry.dart`: `@MappableClass` sealed model representing either a `TriOSTools` entry or the section divider.
  - Run `dart run build_runner build --delete-conflicting-outputs` after mapper changes.
- **Code — navigation domain**:
  - `lib/trios/navigation.dart`: add a `defaultNavOrder` constant representing the current hard-coded order (dashboard → chipper, divider, ships → tips). `Settings`, `catalog`, and action buttons remain outside this list.
- **UX**:
  - Right-click anywhere on the sidebar or top-bar background (outside of action buttons) opens the context menu.
  - Drag mode is visually distinct and exits on "Done", re-toggle, or Esc.
- **Dependencies**: none added. Uses existing `flutter_context_menu` (already imported in `app_shell.dart`), `flutter_riverpod`, and `dart_mappable`.
- **Tooltips / Memory**: all new icons introduced (drag handle, done button, reset menu entry) must carry tooltips per project convention.
- **Migration**: users with no stored `navIconOrder` get the default. If a future tool is added to `TriOSTools` but not present in a stored order, it is appended at the end of its original section and logged.
