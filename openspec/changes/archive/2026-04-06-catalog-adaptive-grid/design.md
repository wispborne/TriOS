## Context

The Catalog page (`lib/catalog/mod_browser_page.dart`) displays scraped mods using a `ListView.builder` with `itemExtent: 200`. Each item is a `ScrapedModCard` — a horizontal card with image, details, and action icons. The app already has `WispAdaptiveGridView` (`lib/widgets/wisp_adaptive_grid_view.dart`), a responsive grid that auto-calculates column count from available width and a `minItemWidth` parameter.

## Goals / Non-Goals

**Goals:**
- Replace the single-column `ListView.builder` with `WispAdaptiveGridView` so the Catalog page fills horizontal space with multiple columns on wider screens.
- Preserve existing scroll position restoration, filtering, and search behavior.

**Non-Goals:**
- Redesigning the `ScrapedModCard` layout (only minor constraint adjustments if needed).
- Adding new user-facing settings for column count or card size.
- Changing the data-loading or filtering logic.

## Decisions

**1. Use `WispAdaptiveGridView` directly**
The widget already exists in the codebase and handles responsive column calculation. No need to introduce a new dependency or custom grid.

**2. `minItemWidth` of ~450 pixels**
The `ScrapedModCard` has a fixed 80px image area, ~16px content padding on each side, and needs enough text width to show mod names and summaries. A `minItemWidth` of ~450 ensures cards remain readable. This gives ~2 columns on a typical 1080p window and ~3 on ultrawide.

**3. Remove `itemExtent: 200` fixed height**
`WispAdaptiveGridView` rows size to the tallest item in each row. Cards will vary slightly in height based on content (tag count, summary length), which is acceptable.

**4. Spacing: 8px horizontal, 8px vertical**
Aligns with the project's 8 dip grid convention.

## Risks / Trade-offs

- **Row height variance**: Cards in the same row will match the tallest card's height, potentially adding whitespace for shorter cards. → Acceptable; this is standard grid behavior and visually consistent.
- **Scroll position**: Switching from `ListView` to `WispAdaptiveGridView` (which also uses `ListView.builder` internally) should preserve lazy loading. The existing `ScrollController` can be passed through. → Low risk.
- **Card width flexibility**: `ScrapedModCard` currently stretches to fill available width. In a multi-column grid, cards will be narrower. → The card's layout uses `Expanded` for the center section, so it should adapt naturally. Verify no minimum width issues.
