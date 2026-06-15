## Why

Context menus that grow taller than the available screen space currently overflow. The existing positioning logic in `calculateContextMenuBoundaries` only repositions the menu — when the menu itself is taller than the viewport, repositioning shifts the clipped region from bottom to top instead of preventing the clip. Users hit this on the WispGrid header context menu (Hide/Show Columns + sort + grouping = 20+ entries), where bottom entries are unreachable on small windows.

The scrolling primitive already exists (`ContextMenuWidget._buildMenuContent` wraps content in `FadedScrollable` + `SingleChildScrollView` when `maxHeight` is set) but is opt-in per callsite and effectively unused.

## What Changes

- Context menus default to a screen-relative max height — capped to fit between their spawn point and the screen bottom, with a small safety margin
- When the cap is engaged, the menu becomes scrollable using the existing `FadedScrollable` infrastructure
- Explicit `maxHeight` on `ContextMenu(...)` continues to override the default (existing API preserved)
- Submenus apply the same logic, computing their own cap from their own spawn position
- Fade indicators only render when content actually exceeds the cap (no fade noise on short menus that happen to spawn near the screen edge)

No callsite changes required. The fix is invisible when menus fit and seamless when they don't.

## Capabilities

### Modified Capabilities

- `context-menu-rendering`: The vendored `flutter_context_menu` rendering layer (`lib/thirdparty/flutter_context_menu/`). New requirement: menus auto-cap height to fit on screen and scroll when capped, while preserving the explicit `maxHeight` override.

## Impact

- **Modified**: `lib/thirdparty/flutter_context_menu/widgets/context_menu_widget.dart` — `_buildMenuContent` and `_buildMenuView` compute and apply the screen-fit cap
- **Possibly modified**: `lib/thirdparty/flutter_context_menu/core/utils/utils.dart` — `calculateContextMenuBoundaries` may need to expose available height alongside position, depending on chosen implementation path (see design.md)
- **Possibly modified**: `lib/thirdparty/faded_scrollable/faded_scrollable.dart` — only if it always renders fade gradients; needs verification
- **Unchanged**: every callsite of `ContextMenu(...)` across the app (mod manager, weapon viewer, grid headers, etc.)
- No new dependencies
- No persisted state or settings touched
