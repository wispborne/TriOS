## ADDED Requirements

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

### Requirement: Preferences are applied by one shared resolver

A single resolver SHALL apply the user's AI-summary setting. The card, the
mod-summary widget, and the catalog details dialog SHALL all call it rather than
checking `AiSummaryMode` themselves.

The resolver SHALL accept the AI text length (sentence or paragraph) and the
author-text order as arguments, so each screen keeps the behavior it has today
without duplicating the logic.

#### Scenario: AI text is never shown when the setting is Never

- **WHEN** `AiSummaryMode.never` applies, whether set directly or because the
  master AI switch is off
- **THEN** the resolver SHALL return only text a human wrote, and SHALL return
  nothing rather than AI text when no human-written text exists

#### Scenario: AI text wins when the setting is Always

- **WHEN** `AiSummaryMode.always` applies and AI text exists
- **THEN** the resolver SHALL return the AI text and SHALL report its source as
  AI, so the "written by AI" note can be shown

#### Scenario: AI text fills a gap when the setting is Only if missing

- **WHEN** `AiSummaryMode.whenNoAuthorText` applies and the mod has no text a
  human wrote
- **THEN** the resolver SHALL return the AI text
- **AND WHEN** the mod does have text a human wrote
- **THEN** the resolver SHALL return that text instead

#### Scenario: Author-text order is chosen by the caller

- **WHEN** the card asks for the short-first order
- **THEN** the resolver SHALL try `summary`, then `description`, then the
  installed `mod_info.json` description
- **AND WHEN** the details dialog body asks for the long-first order
- **THEN** the resolver SHALL try `description`, then `summary`, then the
  installed `mod_info.json` description

#### Scenario: Showing both texts together

- **WHEN** the details dialog body shows the author's own text and asks whether
  to also show the AI paragraph beside it
- **THEN** the resolver SHALL say yes when the setting is Always, yes when the
  setting is Only if missing and there is no author text, and no when the
  setting is Never

### Requirement: Filters and sorting read the gathered model

The Catalog page's filters and sorting SHALL work on gathered mods. A filter
check SHALL NOT read from a provider while it runs; every value a filter needs
SHALL already be on the gathered mod.

#### Scenario: WIP and Archived flags come from the model

- **WHEN** the Attributes filter checks whether a mod is WIP or Archived
- **THEN** it SHALL read flags carried on the gathered mod, and SHALL NOT call
  `ref.read(forumDataByTopicId)`

#### Scenario: Gathered mods are not rebuilt while typing

- **WHEN** the user types in the catalog search box
- **THEN** the existing gathered mods SHALL be filtered and sorted, and no
  gathered mod SHALL be rebuilt

#### Scenario: Update status stays out of the model

- **WHEN** version-check results arrive for installed mods
- **THEN** the gathered mods SHALL NOT be rebuilt, and the "Has Update" filter
  SHALL read the update status from where it lives today
