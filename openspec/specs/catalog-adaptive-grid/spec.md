### Requirement: Catalog displays mods in an adaptive grid
The Catalog page SHALL display scraped mods using `WispAdaptiveGridView` instead of a single-column `ListView`. The grid SHALL automatically calculate the number of columns based on available width and a configured minimum item width.

#### Scenario: Multiple columns on wide screen
- **WHEN** the Catalog page is displayed with sufficient width for two or more columns
- **THEN** mods are arranged in a multi-column grid with each column at least ~450px wide

#### Scenario: Single column on narrow screen
- **WHEN** the available width is less than twice the minimum item width
- **THEN** mods are displayed in a single column, matching the previous layout behavior

### Requirement: Grid uses 8px spacing
The grid SHALL use 8px horizontal spacing and 8px vertical spacing between items, consistent with the project's 8 dip grid convention.

#### Scenario: Spacing between grid items
- **WHEN** multiple mods are displayed in the grid
- **THEN** there is 8px of space between adjacent items both horizontally and vertically

### Requirement: Cards adapt to grid item width
Each `ScrapedModCard` SHALL fill the width assigned by the grid without overflow or minimum-width violations. The card layout SHALL remain readable at the minimum item width.

#### Scenario: Card renders correctly at minimum width
- **WHEN** a mod card is rendered at the minimum grid item width (~450px)
- **THEN** the image, title, summary, tags, and action icons are all visible and not clipped

### Requirement: Scroll and filtering behavior is preserved
Existing scroll position restoration, search filtering, and category filtering SHALL continue to work with the new grid layout.

#### Scenario: Filtering updates grid contents
- **WHEN** the user applies a search or category filter
- **THEN** the grid updates to show only matching mods
