## Why

The mod summary sidebar panel is constrained by its narrow width, showing only basic mod info (name, version, author, description, dependencies). Meanwhile, TriOS aggregates rich data from multiple sources — catalog metadata, forum stats, version checker, images, mod records — that users can't easily see in one place. A spacious modal dialog accessible from the context menu (and catalog cards) would give users a comprehensive "mod profile" view.

## What Changes

- Add a new `ModInfoDialog` modal that presents all available mod data in a rich, spacious layout
- Add "View Mod Details..." entry to the mod context menu (single and bulk menus)
- Support opening the dialog for both installed mods and catalog-only mods
- Display image gallery from catalog data when available
- Include action buttons (enable/disable, update, open folder, VRAM check, delete) in the dialog footer
- Theme the dialog using `PaletteGeneratorMixin` from the mod's icon (not catalog images)

## Capabilities

### New Capabilities
- `mod-info-dialog`: The modal dialog widget that aggregates and displays all mod information from all sources, with image gallery and action bar
- `mod-info-dialog-integration`: Context menu entry, catalog card entry point, and data wiring to open the dialog

### Modified Capabilities

## Impact

- `lib/mod_manager/mod_context_menu.dart` — new menu item
- `lib/catalog/scraped_mod_card.dart` — new entry point from catalog
- New widget files under `lib/mod_manager/` for the dialog
- Uses existing `PaletteGeneratorMixin`, `ModSummaryPanel` patterns, and all existing data providers
