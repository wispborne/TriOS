## ADDED Requirements

### Requirement: Mod version, WIP and Tool badges on the card

A Catalog card SHALL show small badges on its name line, after the name:

- the mod version, from the catalog entry's `modVersion`, when there is one
- "WIP", when the forum index marks the mod as a work in progress
- "Tool", when the mod is marked as a tool

Each badge SHALL have a tooltip. The name SHALL shrink with an ellipsis before any badge is cut. The card's height SHALL not change.

#### Scenario: A work-in-progress tool
- **GIVEN** a mod at version 0.4.1 that is marked both WIP and Tool
- **WHEN** its card renders
- **THEN** the name line reads the name, then "0.4.1", "WIP" and "Tool" badges

#### Scenario: Long name
- **GIVEN** a mod with a name too long for the card
- **WHEN** its card renders
- **THEN** the name is cut with an ellipsis and all its badges stay whole

### Requirement: Tags line uses the cleaned categories

The card's tags line SHALL list `CatalogMod.categories`, then the source names as today. When the extras file is loaded these are the 13 cleaned categories. Otherwise they are the raw ones.

#### Scenario: Cleaned categories on the card
- **GIVEN** a mod whose extras record lists "Ships and weapons"
- **WHEN** its card renders
- **THEN** the tags line starts with "Ships and weapons", not the raw names
