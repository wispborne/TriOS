## MODIFIED Requirements

### Requirement: One gathered model per catalog mod

A `CatalogMod` SHALL hold everything the app knows about one catalog mod. It combines the catalog entry, the forum index entry, the AI answer, the extras record from `mod-catalog-extras.json`, and the installed mod. It SHALL hold every candidate value side by side and SHALL NOT decide which one to show.

It SHALL be built by `gatherCatalogMod`, a function that only uses what's passed in. It reads no providers and no widget context, so it can be tested on its own.

#### Scenario: Every candidate text is kept

- **WHEN** a catalog entry has both a `summary` and a `description`, the user has the mod installed with a `mod_info.json` description, and the AI answer has a sentence and a paragraph
- **THEN** the gathered mod SHALL expose all five texts separately

#### Scenario: No preference reads

- **WHEN** the gathered model is built
- **THEN** it SHALL NOT read `Settings.enableAiFeatures`, `catalogAiSummaryMode`, or any Riverpod provider

#### Scenario: The extras record is passed in

- **WHEN** `catalogModsProvider` builds a gathered mod
- **THEN** it SHALL look up the extras record by the entry's catalog `id` and pass it to `gatherCatalogMod`

### Requirement: The right AI entry is picked once

A forum thread or Discord thread can describe several mods. The gathered model SHALL pick the AI answer that belongs to the mod it represents, using one shared rule (`llmModForEntry`). The rule SHALL use the entry's `sourcePosts` and SHALL NOT guess from names.

It SHALL pick the mod in the forum topic's AI answer whose name equals the forum source post's `llmModName`. When there is none, it SHALL try each Discord source post the same way, in order. When nothing matches, the mod SHALL have no AI answer.

#### Scenario: Add-on mod gets its own AI text

- **WHEN** a catalog entry's forum source post has `llmModName: "Nexerelin Extras"`, and the topic's AI answer lists both "Nexerelin" (main) and "Nexerelin Extras" (addon)
- **THEN** the gathered mod's AI text SHALL come from the "Nexerelin Extras" entry

#### Scenario: Discord answer when the forum has none

- **WHEN** an entry has no forum source post, and its Discord source post names a mod in that thread's AI answer
- **THEN** the gathered mod's AI answer SHALL be that Discord mod

#### Scenario: No matching AI entry

- **WHEN** no source post names a mod found in its AI answer
- **THEN** the gathered mod SHALL have no AI answer, and SHALL NOT fall back to the thread's main mod

#### Scenario: The details dialog agrees with the card

- **WHEN** the details dialog is opened from a card
- **THEN** the AI text it shows SHALL be the same text the card showed
