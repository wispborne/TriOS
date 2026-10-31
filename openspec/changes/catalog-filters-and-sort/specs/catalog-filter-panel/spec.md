## MODIFIED Requirements

### Requirement: Collapsible filter panel on the Catalog page

The Catalog page SHALL host a collapsible left-side filter panel built on the shared filter engine (`FilterScopeController<CatalogMod>`). The panel SHALL be toggleable via a `CollapsedFilterButton` when collapsed and SHALL display an active-filter count badge. The panel SHALL contain these groups, in this order: Status, Attributes, Game Version, Category, Dependencies, AI use, Posted, Last edited, Last release.

#### Scenario: User expands the filter panel
- **WHEN** the user taps the `CollapsedFilterButton` on the Catalog page
- **THEN** the filter panel expands and renders the groups in the order above using `FilterGroupRenderer<CatalogMod>`

#### Scenario: Filter panel coexists with the browser side rail
- **WHEN** the user opens the Browser side panel and the filter panel is expanded
- **THEN** both panels remain visible with the mod grid between them

### Requirement: Category chip group replaces the Category dropdown

The Category group SHALL be a `ChipFilterGroup<CatalogMod>` whose values come from `CatalogMod.categories`. That getter returns the extras file's cleaned categories when the mod has an extras record, and the catalog's raw categories otherwise. Chips SHALL be sorted alphabetically. Empty values SHALL NOT appear as chips.

#### Scenario: Cleaned categories when the extras file is loaded
- **GIVEN** a mod whose raw categories are "Ship Pack" and "Weapon/Fighter Pack", and whose extras record lists "Ships and weapons"
- **WHEN** the Category group renders
- **THEN** it shows one "Ships and weapons" chip for that mod, not the two raw names

#### Scenario: Raw categories without the extras file
- **GIVEN** the extras file did not load
- **WHEN** the Category group renders
- **THEN** it shows the raw category names, as before this change

## ADDED Requirements

### Requirement: Dependencies chip group

The Catalog SHALL have a Dependencies group: a `ChipFilterGroup<CatalogMod>`, collapsed by default, with one chip per required mod and one "Standalone" chip.

- A mod's values SHALL be one key per entry in `CatalogMod.requiredMods`. The key is the entry's catalog id when it has one. Otherwise it is the entry's name, lowercased, with spaces and punctuation removed. So "LazyLib" and "Lazy Lib" share a chip even with no id.
- A mod SHALL get the "Standalone" value when it has an AI answer or an extras record, and its required-mods list is empty. A mod with neither has no Requires value.
- A chip's label SHALL be the required mod's catalog name when its id matches a catalog entry. Otherwise it is the most common spelling of the name.
- "Standalone" SHALL come first. The other chips SHALL be sorted by how many mods need them, most first, then by label.

#### Scenario: Hide mods that need a library
- **WHEN** the user excludes the "Nexerelin" chip
- **THEN** every mod whose required mods include Nexerelin is hidden, and every other mod stays

#### Scenario: Only standalone mods
- **WHEN** the user includes "Standalone"
- **THEN** only mods with an answer that lists no required mods are shown

#### Scenario: Spelling variants share a chip
- **GIVEN** one mod requires "LazyLib" and another requires "Lazy Lib", neither with an id
- **WHEN** the Dependencies group renders
- **THEN** there is one chip for both, counting 2

### Requirement: Safe to add mid-game and Tool chips

The Attributes group SHALL gain two chips, placed after "Has Source Code":

- **Safe to add mid-game.** Included: keep mods whose `canAddToSaveAnswer` is "yes". Excluded: keep only mods whose `canAddToSaveAnswer` is "no". Mods with no answer, or "depends", are dropped while this chip is set either way.
- **Tool.** Included: keep mods marked as a tool. Excluded: hide them. The value comes from the extras record's `isTool`, falling back to the AI answer's `isTool`.

#### Scenario: Excluding Safe to add means the author said no
- **GIVEN** mod A says "yes", mod B says "no", and mod C says nothing
- **WHEN** the user excludes "Safe to add mid-game"
- **THEN** only mod B is shown

### Requirement: Date sliders

The Catalog SHALL have three date range groups, each a `RangeFilterGroup<CatalogMod>` with its own lock, that show dates, not numbers: Posted, Last edited and Last release.

- **Posted** SHALL use the extras record's `addedOn`, falling back to `CatalogMod.postDate`.
- **Last edited** SHALL use the extras record's `editedOn`. When that is empty, it SHALL use the Posted date.
- **Last release** SHALL use the extras record's `lastReleaseDate`, with no fallback. A mod with no release seen SHALL be hidden while this slider is moved. The slider SHALL have a tooltip saying that releases can be missed.
- The Last release slider SHALL be hidden when `catalogExtrasAvailableProvider` is false.
- A handle at the far right SHALL mean "and later", so newly posted mods are not cut off.

#### Scenario: Last release hides mods with no seen release
- **GIVEN** mod A has a release seen on 2026-09-01 and mod B has none
- **WHEN** the user moves the Last release slider's left handle to 2026-08-01
- **THEN** mod A is shown and mod B is hidden

#### Scenario: Never-edited mod uses its posted date
- **GIVEN** a mod posted 2025-01-10 that was never edited
- **WHEN** the user sets Last edited to start at 2025-01-01
- **THEN** the mod is shown

### Requirement: AI use filter

The Catalog SHALL have an AI use group. It reads only the author's own statement (`CatalogMod.aiUse`). It SHALL work exactly like Starmodder's `site/ai_filter.js`:

- Presets: Show everything (default), No AI, Absolutely no AI, No AI images, No vibecoded mods, Custom.
- Custom adds:
  - a mode: "Don't show AI-gen…" or "Only show AI-gen…"
  - the parts: Art (Portraits, Illustrations, Sprites, Icons), Sound (Music, Voice), Text (Writing, Translation), Code, Other
  - a level: all of the work, some but edited by a human, or anything at all
  - an "Ignore if AI content is optional" switch
- "Don't show" SHALL never hide a mod whose author says nothing about AI.
- "Absolutely no AI" SHALL keep only mods whose author says no AI was used.
- The group SHALL be shown whether or not `Settings.enableAiFeatures` is on.
- The whole group SHALL persist under one lock.

#### Scenario: Silent mods are kept by No AI
- **GIVEN** mod A says AI made its portraits, and mod B says nothing about AI
- **WHEN** the user picks "No AI"
- **THEN** mod A is hidden and mod B is shown

#### Scenario: AI features off
- **GIVEN** the user has turned AI features off in Settings
- **WHEN** the filter panel renders
- **THEN** the AI use group is still there and still filters

### Requirement: Live counts on chips

Every chip group in the Catalog panel SHALL show a count on each chip. A chip's count SHALL be the number of mods that would match that chip, given the search and every *other* group's current settings. The chip list itself SHALL still come from all mods, so a chip with a count of 0 stays visible.

#### Scenario: Count follows other filters
- **GIVEN** 40 mods require LazyLib, 25 of them for the selected game version
- **WHEN** the Game Version filter is set and the Dependencies group is open
- **THEN** the LazyLib chip shows 25
