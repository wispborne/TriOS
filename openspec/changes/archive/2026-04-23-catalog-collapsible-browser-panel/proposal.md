## Why

The Catalog page currently uses an always-on horizontal split: the scraped-mod grid on the left, the embedded forum browser on the right. Both panes compete for screen width, and at common laptop resolutions (1366px) neither view has room to breathe. Users who never use the embedded browser lose half the page permanently; users who do want it squint at forum pages rendered in ~700px. The existing `splitPane` toggle is binary and hides the browser entirely, giving up discoverability.

Clicking a mod card also has ambiguous semantics — some mods have a cached forum HTML detail, some have only a forum URL, some are Discord-only with no usable browser target. The current logic picks a single path that may not match what the user wants.

## What Changes

### Collapsible browser panel (right-side rail)

- Replace the always-on `MultiSplitView` split layout in `CatalogPage` with an IDE-style right-side rail.
- The rail is a thin (~32px) vertical strip that is always visible, showing a "Browser" tab label.
- Clicking the rail tab expands a resizable tool panel on the right containing the existing embedded webview (with its current toolbar: back/forward/reload/URL/home). Clicking again collapses it.
- First-run default: panel is **closed** (grid gets full page width).
- Persist both the open/closed state and the panel width across sessions.
- Enforce a minimum panel width of 400px; dragging the divider below that snap-collapses the panel. The grid refuses to shrink below ~390px (one card column).
- **BREAKING** (internal): Remove the existing `splitPane` bool and its toggle UI from `CatalogPage`. The rail tab replaces it.
- Ship with a single "Browser" panel, but structure the rail's API around a `List<SideRailPanel>` so future panels (e.g., `forum_post_dialog` as a persistent panel) can be added without refactoring. One panel open at a time.

### Card-click-action user preference

- Add a `CatalogCardClickAction` enum with three values: `forumDialog` (default), `embeddedBrowser`, `systemBrowser`. Persist the choice in app settings.
- Expose the preference in the Catalog page's overflow menu as three `CheckedPopupMenuItem`s under a disabled "Card click opens" group header.
- Card click behavior:
  - **`forumDialog`** — open `forum_post_dialog` when cached detail HTML is available; otherwise fall back to opening the URL in the system browser.
  - **`embeddedBrowser`** — load the URL in the embedded webview panel. Auto-open the panel (and persist its open state) if it's currently closed.
  - **`systemBrowser`** — open the URL in the operating system's default browser.
- The card's existing priority dispatch (forum-post-dialog for cached HTML, then `linkLoader` for URL, then direct-download dialog) is preserved. Only `linkLoader`'s destination becomes preference-driven. When `forumDialog` is active, the card's existing "cached HTML → dialog" branch already satisfies that choice.

### Discord-only mods become non-clickable

- Exclude Discord URLs from `getBestWebsiteUrl()`. With no forum/nexus URL and no cached detail, the card's existing `hasClickableLink` gate fails and the body is not wrapped in an `InkWell` — no hover, no cursor, no click. The Discord icon button on the card remains the sole (and correct) path to a Discord-only mod.

### Overflow menu cleanup

- Convert `buildCatalogOverflowButton` from its custom `PopupStyleMenuAnchor` + `MenuItemButton` implementation to use the shared `OverflowMenuButton` widget, matching the pattern used by the other viewer pages (ships, weapons, hullmods, portraits). Existing "Data sources…" item migrates to an `OverflowMenuItem`.

## Capabilities

### New Capabilities
- `catalog-browser-rail`: Right-side collapsible tool-panel rail on the Catalog page — its visual behavior (collapsed/expanded states, persistence, minimum widths, snap-collapse) and its pluggable `SideRailPanel` API scoped to the Catalog page.
- `catalog-card-click-action`: User-selectable action taken when a mod card body is clicked — the preference enum, its persistence, its exposure in the Catalog overflow menu, and its routing rules including Discord exclusion and auto-open-panel behavior.

### Modified Capabilities
<!-- None. No existing spec captures the always-split browser layout or the card-click dispatch; both are described in the new capabilities above. The overflow-menu conversion is cosmetic consistency, captured inside catalog-card-click-action. -->

## Impact

- **Affected code**:
  - `lib/catalog/mod_browser_page.dart` — remove `splitPane` bool, restructure the `MultiSplitView` wiring through the new rail, update the `linkLoader` callback to dispatch on `catalogCardClickAction`, convert `buildCatalogOverflowButton` to `OverflowMenuButton`, add click-action menu items.
  - `lib/catalog/scraped_mod_card.dart` — no behavior changes required. Existing click dispatch is preserved.
  - `lib/catalog/models/scraped_mod.dart` (or wherever `getBestWebsiteUrl()` is defined) — exclude Discord URLs from the returned value.
  - New files under `lib/catalog/side_rail/`: `side_rail.dart`, `side_rail_panel.dart`. Built on the existing `multi_split_view` package.
  - New file `lib/catalog/models/catalog_card_click_action.dart` — `@MappableEnum` with label/icon extension getters.
  - `lib/trios/settings/settings.dart` — add three new `@MappableClass` fields: `catalogBrowserPanelOpen: bool` (default `false`), `catalogBrowserPanelWidth: double?` (default `null`, falls back to 500), `catalogCardClickAction: CatalogCardClickAction` (default `forumDialog`).
- **Code generation**: Run `dart run build_runner build --delete-conflicting-outputs` after adding the enum and settings fields to regenerate `*.mapper.dart` files.
- **Dependencies**: No new packages. Reuses `multi_split_view` and the existing `OverflowMenuButton` widget.
- **Out of scope**: Making the rail a shared, app-wide widget; keyboard shortcuts / accessibility; adding a second panel (forum post dialog as a panel) in this change — the API is designed for future extension but v1 ships one panel only. Discord routing logic beyond "excluded from best-URL picker."
