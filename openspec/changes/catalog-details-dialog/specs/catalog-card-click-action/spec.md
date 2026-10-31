## ADDED Requirements

### Requirement: Clicking a card always opens the details dialog
Clicking the body of any catalog card SHALL open the catalog details dialog. There SHALL be no setting that changes what a card click does.

#### Scenario: Card with a forum post
- **WHEN** the user clicks a card whose mod has a cached forum post
- **THEN** the catalog details dialog opens

#### Scenario: Discord-only card
- **WHEN** the user clicks the card of a Discord-only mod
- **THEN** the catalog details dialog opens
- **AND** the card shows the usual hover state and pointer

## REMOVED Requirements

### Requirement: CatalogCardClickAction preference enum
**Reason**: The card click setting was deprecated and is no longer read. Cards always open the details dialog.
**Migration**: None. The saved `catalogCardClickAction` value is ignored.

### Requirement: Click-action preference is persisted in app settings
**Reason**: The setting is deprecated and no longer read.
**Migration**: None.

### Requirement: Click-action preference is exposed in the Catalog overflow menu
**Reason**: The overflow menu no longer offers the setting.
**Migration**: None.

### Requirement: Forum-dialog action opens dialog or falls back to system browser
**Reason**: Replaced by "Clicking a card always opens the details dialog". Mods with no forum post open the same dialog.
**Migration**: None.

### Requirement: Embedded-browser action loads URL in panel and auto-opens if closed
**Reason**: Cards no longer open the built-in browser on click. The dialog's "Open in built-in browser" button does this.
**Migration**: Use the dialog's header button or the card's right-click menu.

### Requirement: System-browser action opens URL in OS default browser
**Reason**: Cards no longer open the system browser on click. The dialog's "Open in web browser" button does this.
**Migration**: Use the dialog's header button or the card's right-click menu.

### Requirement: Discord-only mods render as non-clickable cards
**Reason**: Every card now opens the details dialog, Discord-only mods included.
**Migration**: None.
