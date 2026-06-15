## ADDED Requirements

### Requirement: Dialog displays mod header with identity info
The dialog SHALL display a header section containing: mod icon (if available), mod name, author(s), version, mod type badges (Utility/Total Conversion), and game version requirement.

#### Scenario: Installed mod with full metadata
- **WHEN** the dialog is opened for an installed mod with name, author, version, icon, and game version
- **THEN** all header fields are displayed with the mod icon at 64x64

#### Scenario: Catalog-only mod
- **WHEN** the dialog is opened for a catalog-only mod (not installed)
- **THEN** the header displays the catalog name, authors, version, and game version requirement from scraped data, with no icon

#### Scenario: Missing optional fields
- **WHEN** a mod has no author or no game version specified
- **THEN** those fields are omitted from the header without leaving blank space

### Requirement: Dialog displays external link buttons
The dialog SHALL display link buttons for all available external URLs: Forum, NexusMods, Discord, Changelog, and Direct Download.

#### Scenario: Mod with forum and nexus links
- **WHEN** the mod has both a forum thread ID and NexusMods ID
- **THEN** both Forum and NexusMods buttons are displayed and open their respective URLs

#### Scenario: Mod with no external links
- **WHEN** no URLs are available from any source
- **THEN** no link buttons section is displayed

### Requirement: Dialog displays image gallery from catalog data
The dialog SHALL display a horizontally scrolling gallery of images when catalog image data is available.

#### Scenario: Catalog mod with images
- **WHEN** the mod has catalog images in `ScrapedMod.images`
- **THEN** a horizontal scrolling gallery shows thumbnails at a fixed height, using `proxyUrl` with `url` as fallback

#### Scenario: No images available
- **WHEN** no catalog images exist for the mod
- **THEN** the gallery section is not rendered

#### Scenario: Image fails to load
- **WHEN** a catalog image URL returns an error
- **THEN** an error placeholder is shown in place of that image

### Requirement: Dialog displays mod description
The dialog SHALL display the full mod description in a `SelectionArea` for easy text copying.

#### Scenario: Description from installed mod
- **WHEN** the mod is installed and has a description in mod_info.json
- **THEN** the description is displayed with selectable text

#### Scenario: Description from catalog only
- **WHEN** the mod is catalog-only with a description in ScrapedMod
- **THEN** the catalog description is displayed

#### Scenario: Both sources available
- **WHEN** both installed mod_info and catalog descriptions exist
- **THEN** the installed mod's description is preferred

### Requirement: Dialog displays status and forum activity cards
The dialog SHALL display two side-by-side info cards: one for installation status and one for forum activity.

#### Scenario: Fully installed mod with forum data
- **WHEN** the mod is installed and has ForumModIndex data
- **THEN** Status card shows: installed state, enabled version, update availability, VRAM estimate (if known), categories, sources. Forum card shows: views, replies, last post date, created date, board, WIP status.

#### Scenario: No forum data
- **WHEN** no ForumModIndex data exists
- **THEN** the forum activity card is not rendered

#### Scenario: Catalog-only mod
- **WHEN** the mod is not installed
- **THEN** the status card shows "Not installed" and omits enabled/VRAM fields

### Requirement: Dialog displays dependencies and dependents
The dialog SHALL display dependency satisfaction status and which mods depend on this mod.

#### Scenario: Mod with satisfied dependencies
- **WHEN** the mod has dependencies and all are installed with compatible versions
- **THEN** each dependency is shown with a success indicator and installed version

#### Scenario: Mod with unsatisfied dependencies
- **WHEN** a dependency is missing or has incompatible version
- **THEN** the dependency is shown with an error indicator

#### Scenario: No dependencies
- **WHEN** the mod has no dependencies
- **THEN** the dependencies section is not rendered

#### Scenario: Mod has dependents
- **WHEN** other enabled mods depend on this mod
- **THEN** dependents are listed, separated by enabled/disabled status

### Requirement: Dialog displays installed versions
The dialog SHALL list all installed variants of the mod with their enabled/disabled state and folder access.

#### Scenario: Multiple versions installed
- **WHEN** two or more variants of the mod are installed
- **THEN** each is listed with version, enabled/disabled indicator, and an "Open Folder" action

#### Scenario: Not installed
- **WHEN** the mod is catalog-only
- **THEN** the installed versions section is not rendered

### Requirement: Dialog displays TriOS metadata
The dialog SHALL display TriOS tracking metadata: first seen date, last enabled date, update mute status.

#### Scenario: Metadata available
- **WHEN** TriOS metadata exists for the mod
- **THEN** first seen, last enabled, and mute status are displayed

#### Scenario: No metadata
- **WHEN** the mod is catalog-only with no TriOS metadata
- **THEN** the metadata section is not rendered

### Requirement: Dialog is themed from mod icon
The dialog SHALL use `PaletteGeneratorMixin` to generate a theme from the mod's icon file. Catalog images SHALL NOT be used for theming.

#### Scenario: Mod has icon
- **WHEN** the mod has an icon file on disk
- **THEN** the dialog's theme is derived from the icon's palette colors

#### Scenario: No icon available
- **WHEN** the mod has no icon (catalog-only or missing icon)
- **THEN** the dialog uses the default app theme

### Requirement: Dialog action bar provides mod operations
The dialog SHALL include a footer action bar with contextual mod operations.

#### Scenario: Installed and enabled mod
- **WHEN** the dialog shows an enabled mod
- **THEN** the action bar shows: Disable, Update (if available), Open Folder, VRAM Check, Delete

#### Scenario: Installed and disabled mod with multiple versions
- **WHEN** the dialog shows a disabled mod with multiple variants
- **THEN** the action bar shows an Enable split button with version picker, Open Folder, VRAM Check, Delete

#### Scenario: Catalog-only mod
- **WHEN** the dialog shows a mod not installed locally
- **THEN** the action bar shows only link buttons (no local actions)

#### Scenario: Game is running
- **WHEN** the game is currently running
- **THEN** Enable/Disable and Delete actions are disabled
