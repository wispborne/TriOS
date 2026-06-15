### Requirement: CatalogCardClickAction preference enum

The system SHALL define a `CatalogCardClickAction` enum with exactly three values: `forumDialog`, `embeddedBrowser`, and `systemBrowser`. The enum SHALL be a `@MappableEnum` suitable for persistence via dart_mappable, and SHALL provide human-readable `label` and `IconData icon` extension getters for UI rendering.

#### Scenario: Enum covers the three click targets
- **WHEN** inspecting `CatalogCardClickAction.values`
- **THEN** the list contains exactly `forumDialog`, `embeddedBrowser`, and `systemBrowser`

#### Scenario: Each value has a display label and icon
- **WHEN** rendering a menu item for a `CatalogCardClickAction` value
- **THEN** the value provides a non-empty `label` and a non-null `icon`

### Requirement: Click-action preference is persisted in app settings

The chosen `CatalogCardClickAction` SHALL be stored on `Settings` as `catalogCardClickAction: CatalogCardClickAction` with a default of `forumDialog`, and SHALL survive app restarts.

#### Scenario: First-run default
- **WHEN** the user has never chosen a click action
- **THEN** `catalogCardClickAction` is `forumDialog`

#### Scenario: Chosen preference survives restart
- **WHEN** the user selects `embeddedBrowser` from the overflow menu and restarts the app
- **THEN** `catalogCardClickAction` is still `embeddedBrowser` on reload

### Requirement: Click-action preference is exposed in the Catalog overflow menu

The Catalog page's overflow menu SHALL include a group, preceded by a `PopupMenuDivider` and a disabled group header `"Card click opens"`, containing one `CheckedPopupMenuItem` per `CatalogCardClickAction` value. The item corresponding to the current preference SHALL display as checked. Selecting any item SHALL update `Settings.catalogCardClickAction` and persist it.

#### Scenario: Current preference is checked
- **WHEN** the user opens the Catalog overflow menu with `catalogCardClickAction` = `embeddedBrowser`
- **THEN** the "Embedded browser" item is rendered checked and the other two items are rendered unchecked

#### Scenario: Selecting an item updates the preference
- **WHEN** the user selects the "System browser" item from the overflow menu
- **THEN** `catalogCardClickAction` is updated to `systemBrowser`
- **AND** the next time the menu is opened, "System browser" is rendered checked

#### Scenario: Group header is disabled
- **WHEN** the user attempts to tap the "Card click opens" header
- **THEN** no action occurs (the header is a disabled `PopupMenuItem`)

### Requirement: Forum-dialog action opens dialog or falls back to system browser

When `catalogCardClickAction` is `forumDialog` and a mod card body is clicked, the system SHALL open `forum_post_dialog` if cached detail HTML is available for that mod, otherwise it SHALL open the mod's best website URL in the operating system's default browser.

#### Scenario: Cached HTML opens dialog
- **WHEN** the preference is `forumDialog` and the clicked mod has cached forum detail HTML
- **THEN** `forum_post_dialog` is shown as an overlay
- **AND** the browser panel state is not modified

#### Scenario: No cached HTML falls back to system browser
- **WHEN** the preference is `forumDialog`, the clicked mod has no cached detail HTML, and a best website URL is available
- **THEN** the URL is opened in the operating system's default browser
- **AND** the browser panel state is not modified

### Requirement: Embedded-browser action loads URL in panel and auto-opens if closed

When `catalogCardClickAction` is `embeddedBrowser` and a mod card body is clicked with a best website URL available, the system SHALL load the URL in the embedded `InAppWebView` inside the Browser panel. If the panel is currently closed, the system SHALL open the panel and persist the new open state before (or as part of) loading the URL.

#### Scenario: Panel already open
- **WHEN** the preference is `embeddedBrowser`, the Browser panel is open, and the user clicks a mod card with a URL
- **THEN** the URL is loaded in the embedded webview
- **AND** the panel remains open

#### Scenario: Panel closed auto-opens
- **WHEN** the preference is `embeddedBrowser`, the Browser panel is closed, and the user clicks a mod card with a URL
- **THEN** the Browser panel opens
- **AND** the URL is loaded in the embedded webview
- **AND** `catalogBrowserPanelOpen` is persisted as `true`

### Requirement: System-browser action opens URL in OS default browser

When `catalogCardClickAction` is `systemBrowser` and a mod card body is clicked with a best website URL available, the system SHALL open the URL in the operating system's default browser regardless of panel state.

#### Scenario: System browser opens regardless of panel state
- **WHEN** the preference is `systemBrowser` and the user clicks a mod card with a URL
- **THEN** the URL is opened via `openAsUriInBrowser()` (or equivalent system-browser helper)
- **AND** the browser panel state is not modified

### Requirement: Discord URLs are excluded from the best-website picker

`getBestWebsiteUrl()` on `ScrapedMod` SHALL NOT return a Discord URL. When forum and NexusMods URLs are both absent, the function SHALL return `null` even if a Discord URL is present.

#### Scenario: Discord-only mod returns null
- **WHEN** a mod has only a Discord URL among its sources
- **THEN** `getBestWebsiteUrl()` returns `null`

#### Scenario: Discord URL is skipped when forum URL also present
- **WHEN** a mod has both a forum URL and a Discord URL
- **THEN** `getBestWebsiteUrl()` returns the forum URL and does not consider the Discord URL

### Requirement: Discord-only mods render as non-clickable cards

Because `getBestWebsiteUrl()` returns null for Discord-only mods and those mods typically have no cached detail HTML or direct-download URL, the existing `hasClickableLink` computation on `ScrapedModCard` SHALL evaluate to `false` for such mods, causing the card body to render without hover state, cursor pointer, or click handler. The Discord icon button on the card SHALL remain clickable.

#### Scenario: Card body has no hover or click for Discord-only mods
- **WHEN** rendering a card for a Discord-only mod with no cached HTML and no direct-download URL
- **THEN** the card body is not wrapped in an `InkWell`
- **AND** hovering the card body produces no visual change
- **AND** the Discord icon button in the card's icon column is still clickable and functional

### Requirement: Catalog overflow menu uses shared OverflowMenuButton

The Catalog page's overflow button (previously `buildCatalogOverflowButton` implemented with `PopupStyleMenuAnchor` and `MenuItemButton`) SHALL be replaced with the shared `OverflowMenuButton` widget from `lib/widgets/overflow_menu_button.dart`, matching the pattern used by other viewer pages (ships, weapons, hullmods, portraits). The existing "Data sources…" entry SHALL migrate to an `OverflowMenuItem.toEntry(...)` without behavior change.

#### Scenario: Overflow menu is constructed via OverflowMenuButton
- **WHEN** inspecting `mod_browser_page.dart` after the change
- **THEN** the overflow button is built using `OverflowMenuButton(menuItems: ...)` and no `PopupStyleMenuAnchor` remains in that file

#### Scenario: Data sources entry still works
- **WHEN** the user opens the overflow menu and selects "Data sources…"
- **THEN** `showCatalogDataSourcesDialog(context)` is invoked as before
