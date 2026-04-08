## 1. Replace ListView with WispAdaptiveGridView

- [x] 1.1 In `mod_browser_page.dart`, replace the `ListView.builder` (with `itemExtent: 200`) that renders `ScrapedModCard` items with a `WispAdaptiveGridView<ScrapedMod>`.
- [x] 1.2 Configure `minItemWidth: 450`, `horizontalSpacing: 8`, `verticalSpacing: 8`.
- [x] 1.3 Pass the existing `ScrollController` (if any) and padding to the new grid widget.

## 2. Adjust ScrapedModCard for grid layout

- [x] 2.1 Verify `ScrapedModCard` renders correctly at ~450px width — check that image, title, summary, tags, and icons are visible and not clipped.
- [x] 2.2 Fix any overflow or minimum-width issues found during verification.

## 3. Verify existing behavior

- [x] 3.1 Confirm search filtering still updates the grid contents correctly.
- [x] 3.2 Confirm category/source filtering works with the grid layout.
- [x] 3.3 Test at various window widths to verify column count adjusts responsively.
