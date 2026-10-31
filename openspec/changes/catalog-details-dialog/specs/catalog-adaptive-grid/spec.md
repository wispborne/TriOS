## MODIFIED Requirements

### Requirement: Catalog displays mods in an adaptive grid
The Catalog page SHALL display catalog mods using `WispAdaptiveGridView`. The grid SHALL work out the number of columns from the available width and the "Grid item min. size" setting.

#### Scenario: Multiple columns on wide screen
- **WHEN** the Catalog page has room for two or more columns at the chosen minimum size
- **THEN** mods are arranged in a multi-column grid, each column at least that wide

#### Scenario: Single column on narrow screen
- **WHEN** the available width is less than twice the chosen minimum size
- **THEN** mods are displayed in a single column

### Requirement: Cards adapt to grid item width
Each `CatalogModCard` SHALL fill the width assigned by the grid without overflow. The card layout SHALL stay readable at the smallest allowed minimum size.

#### Scenario: Card renders correctly at minimum width
- **WHEN** a mod card is rendered at the smallest allowed minimum size (300 px)
- **THEN** the image, title, summary, tags and buttons are all visible and not clipped

## ADDED Requirements

### Requirement: Grid size and spacing follow the user's settings
The Catalog overflow menu SHALL offer a "Grid item min. size" slider from 300 to 600 px, default 390, and a "Space between cards" slider from 0 to 24 px in steps of 4, default 4. Both SHALL be saved between sessions. The grid SHALL use the chosen spacing both across and down.

#### Scenario: Changing the spacing
- **WHEN** the user sets "Space between cards" to 12
- **THEN** the grid shows 12 px between adjacent cards, across and down
- **AND** the value is still 12 after a restart

## REMOVED Requirements

### Requirement: Grid uses 8px spacing
**Reason**: Spacing is now a user setting, 0 to 24 px, default 4.
**Migration**: None. Users who want 8 px can pick it from the overflow menu.
