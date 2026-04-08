## Why

The Catalog page currently displays scraped mods in a single-column `ListView` with fixed 200px item height. This wastes horizontal space on wider screens and provides a rigid layout. Switching to `WispAdaptiveGridView` will auto-fill columns based on available width, giving users a responsive grid that makes better use of screen real estate.

## What Changes

- Replace the `ListView.builder` in the Catalog page's mod list with `WispAdaptiveGridView<ScrapedMod>`.
- Remove the fixed `itemExtent: 200` constraint so cards size naturally.
- Configure `minItemWidth` to ensure cards remain readable at smaller widths.
- Add appropriate horizontal and vertical spacing between grid items.

## Capabilities

### New Capabilities
- `catalog-adaptive-grid`: Replace the single-column mod list with a responsive adaptive grid that adjusts column count based on available width.

### Modified Capabilities

(none)

## Impact

- `lib/catalog/mod_browser_page.dart` — layout change in the mod list builder section.
- `lib/catalog/scraped_mod_card.dart` — may need minor adjustments to sizing/constraints for grid-friendly layout.
- No new dependencies; `WispAdaptiveGridView` already exists in `lib/widgets/wisp_adaptive_grid_view.dart`.
