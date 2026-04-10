## ADDED Requirements

### Requirement: Context menu entry to open mod info dialog
The mod context menu SHALL include a "View Mod Details..." item that opens the `ModInfoDialog` for the selected mod.

#### Scenario: Single mod selected
- **WHEN** the user right-clicks a mod in the mod manager and selects "View Mod Details..."
- **THEN** the `ModInfoDialog` opens with all available data for that mod

#### Scenario: Menu item placement
- **WHEN** the context menu is built
- **THEN** "View Mod Details..." appears near the top of the menu, before the "Change to..." item

### Requirement: Catalog card entry point to open mod info dialog
The catalog mod browser cards SHALL support opening the `ModInfoDialog`.

#### Scenario: Opening from catalog card
- **WHEN** the user triggers a detail action on a catalog card (e.g., double-click or detail button)
- **THEN** the `ModInfoDialog` opens with catalog data and any matched installed mod data

### Requirement: Data resolution for dialog
The caller SHALL resolve and pass all available data sources when opening the dialog: installed `Mod`, `ScrapedMod`, `ForumModIndex`, and `VersionCheckComparison`.

#### Scenario: Installed mod with catalog match
- **WHEN** an installed mod has a matching catalog entry
- **THEN** the dialog receives both the `Mod` and `ScrapedMod` data

#### Scenario: Catalog-only mod
- **WHEN** a catalog mod has no installed match
- **THEN** the dialog receives only `ScrapedMod` and optionally `ForumModIndex`

#### Scenario: Installed mod with no catalog match
- **WHEN** an installed mod has no catalog entry
- **THEN** the dialog receives only the `Mod` and `VersionCheckComparison` data
