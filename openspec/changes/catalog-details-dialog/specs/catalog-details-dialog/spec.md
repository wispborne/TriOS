## ADDED Requirements

### Requirement: One details dialog for every catalog mod
Clicking any catalog card SHALL open the catalog details dialog. The same dialog SHALL be used whether or not TriOS has the mod's forum post.

#### Scenario: Mod with a forum post
- **WHEN** the user clicks the card of a mod whose forum post is cached
- **THEN** the details dialog opens with the forum post in the Description tab

#### Scenario: Discord-only mod
- **WHEN** the user clicks the card of a mod found only on Discord
- **THEN** the same details dialog opens
- **AND** its Get it panel offers the same downloads as the card's button, including AI-found ones

### Requirement: Tabs hold the long content
The dialog SHALL show tabs for Description, Gallery, Updates and Add-ons. A tab with nothing to show SHALL be hidden. With only one tab left, the tab bar SHALL be hidden.

#### Scenario: Mod with no pictures
- **WHEN** a mod has no gallery pictures
- **THEN** the Gallery tab is not shown

#### Scenario: Description tab contents
- **WHEN** the Description tab is shown
- **THEN** it shows the AI summary when the AI summary setting allows it, then the forum post, then the Discord post, each only when present

### Requirement: Side column holds the short facts
The dialog SHALL show a side column with these panels, in order: Get it, Links, Compatibility, Details, More by author, Similar mods. A panel with nothing to show SHALL be hidden.

#### Scenario: Details panel
- **WHEN** a mod has a mod version, categories and dates
- **THEN** the Details panel shows the mod version, the categories, Added, Last edited, Last release, Thread last posted, and AI use, each only when known

#### Scenario: Original categories
- **WHEN** the mod's original categories differ from its cleaned ones
- **THEN** the Details panel offers a way to show the original categories

### Requirement: Get it uses TriOS's install flow
The Get it panel SHALL use TriOS's existing download button, ranking and "Other download options" menu. For an installed mod it SHALL also show the installed state, Enable or Disable, and Mute updates.

#### Scenario: Installed mod with an update
- **WHEN** the mod is installed and an unmuted update is available
- **THEN** the main button reads Update and runs the same download as the card's Update button

#### Scenario: Installed mod controls
- **WHEN** the mod is installed
- **THEN** the panel offers Enable or Disable, matching the card's right-click menu, and the mute toggle

### Requirement: Compatibility panel
The Compatibility panel SHALL show the required game version, required mods, optional mods, and the add, update and remove mid-game answers with the author's words.

#### Scenario: Required mod is installed
- **WHEN** a required mod is installed
- **THEN** its chip shows a check mark

#### Scenario: Required mod is in the catalog
- **WHEN** the user clicks a required mod's chip and that mod is in the catalog
- **THEN** the dialog shows that mod, with a Back button

#### Scenario: Required mod is not in the catalog
- **WHEN** a required mod has no catalog entry
- **THEN** its chip is shown greyed out and does nothing when clicked

### Requirement: AI-written text follows the AI switch
AI summaries and AI picture captions SHALL be hidden when `Settings.enableAiFeatures` is off. The AI-use statement, downloads, requirements and save answers SHALL stay visible, because they are facts taken from the author's post.

#### Scenario: AI features off
- **WHEN** AI features are turned off
- **THEN** the dialog shows no AI summary and no AI picture captions
- **AND** the Details panel still shows the AI-use row

### Requirement: Gallery and picture viewer
The Gallery tab SHALL show the mod's pictures. Pictures marked small SHALL be hidden behind a "Show N small pictures" button. Clicking a picture, in the gallery or inside the forum or Discord post, SHALL open a full-screen picture viewer.

#### Scenario: Viewer controls
- **WHEN** the picture viewer is open
- **THEN** the mouse wheel zooms, dragging pans, the left and right arrow keys move between pictures, and Escape closes the viewer

#### Scenario: Arrow keys inside the viewer
- **WHEN** the picture viewer is open and the user presses an arrow key
- **THEN** the viewer moves to the next picture
- **AND** the dialog behind it does not move to another mod

### Requirement: Moving between mods inside the dialog
Clicking a mod in More by author, Similar mods, the same-name panel, or a required-mod chip SHALL show that mod in the same dialog, with a Back button. Previous and Next SHALL step through the grid's current list, as other TriOS details dialogs do.

#### Scenario: Back after following a link
- **WHEN** the user follows a Similar mods link and then clicks Back
- **THEN** the dialog shows the mod it showed before

#### Scenario: Next after following a link
- **WHEN** the user has followed one or more links and then clicks Next
- **THEN** the dialog shows the grid mod after the one the dialog was opened on (or last paged to)
- **AND** the Back history is cleared

### Requirement: More by author and Similar mods
More by author SHALL list up to five other catalog mods that share an author, newest release first. Similar mods SHALL list up to five catalog mods by other authors, the ones sharing the most categories first.

#### Scenario: Similar mods skip the same author
- **WHEN** another mod shares categories and an author with this mod
- **THEN** it appears in More by author, not in Similar mods

### Requirement: Works before the extras file is available
When `mod-catalog-extras.json` is missing, the dialog SHALL still open and show everything that doesn't need it. Release history, the Last release date, AI picture captions, the same-name panel and the Discord post SHALL be hidden. Categories, required mods and save answers SHALL fall back to the data TriOS already has.

#### Scenario: No extras file
- **WHEN** the extras file has not loaded
- **THEN** the dialog shows the forum post, downloads, changelog, links, and the required mods from the AI answer
- **AND** it shows no Updates entries from release history
