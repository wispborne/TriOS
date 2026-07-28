## ADDED Requirements

### Requirement: One gathered model per catalog mod

A `GatheredCatalogMod` SHALL hold everything the app knows about one catalog
mod, combined from the catalog entry, the forum index entry, the AI-written
`llm` block, and the installed mod. It SHALL hold every candidate value side by
side and SHALL NOT decide which one to show.

Building it SHALL be a function that only uses what's passed in — no reads from
providers and no widget context — so it can be tested on its own.

#### Scenario: Every candidate text is kept

- **WHEN** a catalog entry has both a `summary` and a `description`, the user has
  the mod installed with a `mod_info.json` description, and the forum entry has
  an AI sentence and paragraph
- **THEN** the gathered mod SHALL expose all five texts separately

#### Scenario: No preference reads

- **WHEN** the gathered model is built
- **THEN** it SHALL NOT read `Settings.enableAiFeatures`, `catalogAiSummaryMode`,
  or any Riverpod provider

### Requirement: The right AI entry is picked once

A forum thread can describe several mods. The gathered model SHALL pick the AI
entry that matches the mod it represents, using one shared rule.

For a mod that lives inside another mod's thread (`isPartOfThread`), it SHALL
pick the `llm` entry whose name matches the mod's name, ignoring case and
surrounding spaces, and fall back to the thread's main mod when no name
matches. Otherwise it SHALL pick the thread's main mod.

#### Scenario: Add-on mod gets its own AI text

- **WHEN** a made-up "part of *thread*" card for "Nexerelin Extras" is gathered,
  and the thread's `llm` block lists both "Nexerelin" (main) and
  "Nexerelin Extras" (addon)
- **THEN** the gathered mod's AI text SHALL come from the "Nexerelin Extras"
  entry

#### Scenario: Add-on with no matching AI entry

- **WHEN** a "part of *thread*" card's name matches no entry in the thread's
  `llm` block
- **THEN** the gathered mod SHALL fall back to the thread's main mod

#### Scenario: The details dialog agrees with the card

- **WHEN** the catalog details dialog is opened from an add-on card
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
