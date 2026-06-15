## ADDED Requirements

### Requirement: Rail is always visible on the Catalog page

The Catalog page SHALL render a vertical rail strip (~32px wide) on the right edge of its content area at all times. The rail displays a tab for each registered `SideRailPanel` (v1 ships with a single "Browser" panel).

#### Scenario: Rail is visible on first load
- **WHEN** the user navigates to the Catalog page for the first time
- **THEN** a thin vertical rail is visible on the right edge
- **AND** a "Browser" tab with an icon and rotated label is shown on the rail

#### Scenario: Rail is visible when panel is closed
- **WHEN** no panel is open
- **THEN** the rail remains visible and the grid occupies the full remaining page width

#### Scenario: Rail is visible when panel is open
- **WHEN** the Browser panel is open
- **THEN** the rail remains visible to the right of the panel, and clicking the active tab collapses the panel

### Requirement: Panel toggles open and closed via rail tab clicks

Clicking a rail tab SHALL toggle the corresponding panel's open state. Only one panel MAY be open at a time.

#### Scenario: Opening a closed panel
- **WHEN** the panel is closed and the user clicks the "Browser" tab
- **THEN** the panel expands on the right side of the page between the grid and the rail
- **AND** the panel width matches the persisted `catalogBrowserPanelWidth` value, or 500 logical pixels if unset

#### Scenario: Closing an open panel
- **WHEN** the panel is open and the user clicks the active tab
- **THEN** the panel collapses and the grid expands to fill the reclaimed space

### Requirement: First-run default is panel closed

When a user has never opened the Catalog page before (no persisted value), the panel SHALL default to closed so the grid receives the full page width.

#### Scenario: First-ever catalog visit
- **WHEN** `catalogBrowserPanelOpen` has no persisted value
- **THEN** the panel is rendered closed on page load

### Requirement: Open/closed state persists across sessions

The panel's open/closed state SHALL be persisted to app settings as `catalogBrowserPanelOpen: bool` and restored on subsequent visits to the Catalog page.

#### Scenario: Panel state survives app restart
- **WHEN** the user opens the panel, closes the app, and reopens it
- **THEN** the Catalog page loads with the panel open

#### Scenario: Closed state survives app restart
- **WHEN** the user explicitly closes the panel, closes the app, and reopens it
- **THEN** the Catalog page loads with the panel closed

### Requirement: Panel width is resizable and persisted

The divider between the grid and the panel SHALL be draggable. The resulting panel width SHALL be persisted as `catalogBrowserPanelWidth: double?` and used as the initial width the next time the panel opens.

#### Scenario: Resizing the panel
- **WHEN** the user drags the divider to a new position
- **THEN** the panel width updates live and the new width is persisted

#### Scenario: Width is restored on reopen
- **WHEN** the user closes and reopens the panel
- **THEN** the panel reopens at its last persisted width

### Requirement: Minimum panel width with snap-collapse

The panel SHALL enforce a minimum width of 400 logical pixels. If the user drags the divider such that the resulting panel width would be below 400px, the panel SHALL snap-collapse (close) rather than render at the sub-minimum width. The persisted `catalogBrowserPanelWidth` SHALL NOT be overwritten with the sub-minimum drag value.

#### Scenario: Dragging below threshold snap-collapses
- **WHEN** the user drags the divider such that the panel width would be < 400px
- **THEN** the panel closes, the grid reclaims the full width, and the closed state is persisted
- **AND** the next time the panel opens, it opens at the last valid persisted width (not the sub-minimum value)

#### Scenario: Persisted width below threshold is clamped on open
- **WHEN** the panel opens with a persisted width < 400px (e.g., corrupted settings)
- **THEN** the panel opens at 400px instead

### Requirement: Minimum grid width

The grid SHALL refuse to shrink below 390 logical pixels (one `WispAdaptiveGridView` column at the current `minItemWidth`). The panel divider drag SHALL clamp such that the grid remains at or above 390px.

#### Scenario: Dragging panel wider clamps at grid minimum
- **WHEN** the user drags the divider to the left such that the grid would drop below 390px
- **THEN** the divider stops at the position where the grid is exactly 390px

### Requirement: SideRailPanel API supports multiple future panels

The rail widget SHALL accept a `List<SideRailPanel>` config, where each `SideRailPanel` declares an `id`, `label`, `icon`, and `builder`. Adding a new panel in the future SHALL NOT require changes to the rail widget itself.

#### Scenario: Rail renders one tab per registered panel
- **WHEN** the rail is configured with N panels
- **THEN** N tabs are rendered on the rail, in the order provided

#### Scenario: Only one panel open at a time
- **WHEN** panel A is open and the user clicks the tab for panel B
- **THEN** panel A closes and panel B opens in the same area

### Requirement: Embedded webview toolbar stays inside the panel

When the Browser panel is open, the existing webview toolbar (back, forward, reload, open-in-browser, home, URL input, dark-mode tip) SHALL be rendered inside the panel above the `InAppWebView`, with the same behavior and controls as the pre-change layout.

#### Scenario: Toolbar controls remain functional inside the panel
- **WHEN** the Browser panel is open
- **THEN** the webview toolbar is visible at the top of the panel
- **AND** all toolbar buttons (back/forward/reload/open-in-browser/home, URL field) work as before

### Requirement: Removal of legacy splitPane toggle

The pre-change `splitPane` boolean in `_CatalogPageState` and any user-facing toggle that controlled it SHALL be removed. The rail tab is the sole mechanism for showing or hiding the embedded browser.

#### Scenario: No residual toggle in the filter bar
- **WHEN** the user inspects the Catalog page UI after the change
- **THEN** no split-pane toggle button exists outside the rail
