# Catalog: one gathered model per mod

## The problem

A single mod on the Catalog page is described by five separate things: the
catalog entry, the forum index entry, the AI-written `llm` block inside it, the
cached forum post, and the installed mod on disk. Every screen that shows a mod
pulls those five together itself, and over time the screens have drifted apart.

The same work is repeated in several places, each slightly different:

- **Which AI entry applies to this card.** A forum thread can hold several mods,
  so there's a lookup that finds the right one. It exists twice —
  `_targetLlmMod` in `catalog_mod_card.dart` and `_resolveLlmMod` in
  `mod_summary_data.dart`, whose own comment admits it mirrors the other.
- **The author's text, best source first.** The card tries summary, then
  description, then the installed `mod_info.json`. The details dialog tries
  description, then summary, then `mod_info.json`. `ModSummaryData` tries
  summary, then description, and keeps `mod_info.json` in a separate field.
  Three orders, three answers.
- **The AI-summary setting.** The `AiSummaryMode` check is copied three times,
  in `catalog_mod_card.dart`, `mod_summary_widget.dart`, and
  `catalog_mod_details_dialog.dart`.

There's an actual bug from this drift: the details dialog body reads
`index?.llm?.mainMod` directly, skipping the thread lookup entirely. For a mod
that lives inside another mod's thread, that dialog shows a different mod's
AI text.

The filters have a related problem. A filter check reaches into a separate
provider while it runs — `ref.read(forumDataByTopicId)` inside
`_attributeValuesFor` — because the raw catalog entry doesn't carry the WIP and
Archived flags it needs.

## The solution

Split the work in two.

**One gathered model, no preferences.** A `GatheredCatalogMod` combines all five
sources into one object per mod. It holds every candidate value side by side —
the author's text, the `mod_info.json` text, the AI sentence, the AI paragraph,
the image and its fallback, the download links, the installed mod, the WIP and
Archived flags. It doesn't decide what to show. It only uses what's passed in,
so it can be tested without a widget.

**One small resolver at display time.** A handful of functions that take a
gathered mod plus the user's AI-summary setting and answer "what text goes
here". This is where preference logic lives, and it lives there once. Around
fifteen lines replacing three copies.

The reason preferences stay out of the model: the details dialog shows the
author's text *and* the AI paragraph together, and the card shows the AI
sentence in the body but the AI paragraph in its tooltip. A model that has
already picked one string can't serve either. Keeping preferences at display
time also means flipping the AI toggle doesn't rebuild the whole catalog.

`ModSummaryData` already does about 80% of the gathering job. It grows into the
new model rather than sitting beside it, so the app ends up with two models for
a catalog mod instead of three.

**And the names swap over.** Today's `CatalogMod` isn't really "a catalog mod" —
it's just the raw shape of one entry in `mod_repo.json`, parsed from the
downloaded file and never written back. It becomes `ModRepoEntry`, named after
where it comes from, matching the
`mod_repo.json` / `modRepoUrl` / `modRepoFetcher` wording already in the code.
The gathered model then takes the plain name `CatalogMod`, and the word
"gathered" disappears from the app entirely. That rename runs last, as a separate find-and-replace pass, once every place
that uses these types has already been pointed at the right one.

## In scope

- The `GatheredCatalogMod` model and the provider that builds one per catalog
  entry.
- The shared resolver for the AI-summary setting and the author-text order.
- Moving the card, the mod-summary widget, the catalog details dialog, and the
  forum post dialog to use the gathered model and the resolver.
- Moving the catalog filters and sorting to use the gathered model, so filters
  no longer reach into a separate provider.
- Fixing the details dialog so it uses the right mod's AI text.
- Renaming `CatalogMod` to `ModRepoEntry` and the gathered model to `CatalogMod`,
  as the final step.

## Out of scope

- Changing what the catalog data itself contains, or how it's fetched and
  cached. `mod_browser_manager.dart` and `forum_data_manager.dart` don't change.
- Changing how a catalog entry is matched to an installed mod. `catalog_links.dart`
  keeps that job and the gathered model reads its answer.
- New settings or new UI. The AI-summary setting and its picker stay as they are.
- Version-check results stay out of the gathered model — see the design for why.
- Other pages. This is the Catalog page only.

## What users will notice

Almost nothing, by design. Two deliberate exceptions:

- Add-on cards ("part of *thread*") show the correct mod's AI text in the
  details dialog instead of the thread's main mod's.
- Where the three author-text orders disagreed, each screen keeps the order it
  has today. The resolver takes that order as a setting rather than picking a
  winner, so nothing shifts under the user.
