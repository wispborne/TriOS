# Design

## New files

Two new pieces:

```
lib/catalog/models/gathered_catalog_mod.dart   the model, the build function,
                                               and the provider that builds one per entry
lib/catalog/summary_resolver.dart              the preference resolver
```

`lib/catalog/widgets/mod_summary/mod_summary_data.dart` goes away. The gathered build function is based on its two builder methods, and
`ModSummaryWidget` takes a `GatheredCatalogMod` instead.

## Names

Today's `CatalogMod` isn't really "a catalog mod" — it's just the raw shape of
one entry in `mod_repo.json`, parsed from the downloaded file and never written
back. The plain name belongs on the model the rest of the app actually wants.

So the last step of this change is a find-and-replace rename:

| Today | After |
| --- | --- |
| `CatalogMod` | `ModRepoEntry` |
| `CatalogModsRepo` | `ModRepoFile` |
| `CatalogModImage` | `ModRepoImage` |
| `catalog_mod.dart` | `mod_repo_entry.dart` |
| `catalogEntriesProvider` | `modRepoEntriesProvider` |
| `GatheredCatalogMod` | `CatalogMod` |
| `gathered_catalog_mod.dart` | `catalog_mod.dart` |
| `gatheredCatalogModsProvider` | `catalogModsProvider` |

`gatherCatalogMod()` keeps its name — the verb still describes what it does, and
it now returns a `CatalogMod`. The word "gathered" otherwise disappears.

Nothing saved to disk depends on these names. `CatalogMod` is read-only from
the downloaded file via `CatalogModsRepoMapper.fromJson`, and dart_mappable
uses field names for serialization, not class names. Field names don't change.

**The rename happens last, on purpose.** Doing it up front would be risky: the
moment `CatalogMod` means `ModRepoEntry`, all 117 existing references would
point at the raw type, and most of them should have become the gathered one. The
compiler catches most mismatches, but a field that exists on both types compiles
fine with the wrong one. Renaming after every use site has already been moved to
the right type removes that risk — by then it's just find-and-replace.

Outside the catalog folder, `mod_records_store.dart`, `mod_search.dart`,
`mod_context_menu.dart`, `mod_info_dialog.dart`, and `download_manager.dart` all
keep using `ModRepoEntry`. They only need name, authors, and URLs — pulling in
forum data there would be wrong. Both types earn their keep.

The three small helpers at the top of that file — `modInfoDescription`,
`trimmedOrNull`, `firstNonBlank` — move to `gathered_catalog_mod.dart`. They're
used outside the catalog too, so they keep their names.

## The model

`GatheredCatalogMod` is a plain Dart class (not `@MappableClass` — it's never
saved or sent, just rebuilt from its sources each time).

It holds, roughly:

- **Identity**: the raw `CatalogMod`, the title, the authors, the thread it's
  part of.
- **Every candidate text, listed separately**: `summaryText`, `descriptionText`,
  `modInfoText`, `aiSentence`, `aiParagraph`. No fallback has been applied yet.
- **The AI entry for this mod**: the matched `ForumLlmMod`, plus the pieces
  read from it — changelog, support links, save compatibility.
- **Pictures**: the catalog image and the AI block's fallback image URL.
- **Forum facts**: category, post date, last edit, views, replies, topic URL,
  and the `isWip` / `isArchivedModIndex` flags the filters need.
- **Attribute keys**: the list the Attributes filter chips match on, calculated
  once when the model is built.
- **Install state**: the linked installed `Mod`, or null.
- **Downloads**: the available download links.

It doesn't pick between texts. That's the resolver's job.

### The build function

```dart
GatheredCatalogMod gatherCatalogMod({
  required CatalogMod mod,
  ForumModIndex? forumIndex,
  ForumModDetails? forumDetails,
  Mod? installedMod,
});
```

Takes data in, returns a model out. No `ref`, no `BuildContext`, no settings.
That's what makes it testable.

The two existing builders (`fromCatalog`, `fromDetails`) fold into this one
function, with `forumDetails` optional. When the forum post has richer values
than the index — author title, avatar, post count — those win, and the index
fills in the rest.

The thread-lookup rule (`_targetLlmMod` / `_resolveLlmMod`) lives here, once.

## The resolver

Three small functions in `summary_resolver.dart`. All self-contained — the
caller watches `effectiveCatalogAiSummaryModeProvider` and passes the mode in.

```dart
/// Which of the author's own texts to try first.
enum AuthorTextOrder { shortFirst, longFirst }

/// Which length of AI text to use.
enum AiTextLength { sentence, paragraph }

/// A resolved block of text and where it came from.
typedef ResolvedText = ({String text, ModSummarySource source});

/// The one block of text to show, and where it came from.
ResolvedText? resolveSummaryText(
  GatheredCatalogMod mod, {
  required AiSummaryMode aiMode,
  required AiTextLength aiLength,
  required AuthorTextOrder authorOrder,
});

/// The author's own text on its own, for screens that show both blocks.
ResolvedText? resolveAuthorText(
  GatheredCatalogMod mod, {
  required AuthorTextOrder authorOrder,
});

/// Whether the AI paragraph should be shown beside the author's own text.
bool shouldShowAiWithAuthorText(
  GatheredCatalogMod mod, {
  required AiSummaryMode aiMode,
  required bool hasAuthorText,
});
```

`AuthorTextOrder` is why nothing shifts under the user: each caller asks for the
order it uses today. Card and mod-summary widget ask for `shortFirst`, the
details dialog body asks for `longFirst`.

`ModSummarySource` already exists in `mod_summary_widget.dart` and moves to the
resolver, since the resolver is what returns it.

## The provider

```dart
final gatheredCatalogModsProvider = Provider<List<GatheredCatalogMod>>(...);
```

It watches `catalogEntriesProvider`, `forumDataByTopicId`, and
`catalogLinksProvider`, and builds one gathered mod per entry. It does not watch
forum *details* — those are only fetched when someone opens a specific mod, so
dialogs gather their own with `forumDetails` filled in.

`CatalogPageController.build()` switches from `catalogEntriesProvider` to this
one.
`CatalogPageState.allMods` and `displayedMods` become
`List<GatheredCatalogMod>`, and the filters become
`FilterGroup<GatheredCatalogMod>`.

`_attributeValuesFor` shrinks to reading `mod.attributeKeys`. The
`ref.read(forumDataByTopicId)` inside it goes away.

`mod_browser_page.dart`'s `itemBuilder` also gets simpler: the topic-id lookup
it does per card is already done inside the gathered mod.

### Two decisions about cost

**Version-check results stay out.** They stream in continuously while the app
starts up. If the gathered mod held update status, the whole catalog would
rebuild every time a check came back. So the rule is: the gathered mod holds
what the mod *is*, and update status stays where it is today — the controller's
`_versionCheckState` and `statusForModName`. The "Has Update" filter and the
`updatesCount` pill keep reading it from there.

**Gathering happens once per data change, not per keystroke.** The provider
rebuilds only when the catalog, the forum data, the installed mods, or the mod
records change. `_processAllFilters` works on the already-built list, so typing
in the search box costs a filtering step and nothing more.

This is the risk worth watching: gathering loops through roughly a thousand
entries with a map lookup per entry, on top of the loop
`catalogLinksProvider` already does. It should be a few milliseconds, but it
runs on the UI thread, so task 17 measures it before we call this done.

## Which files change

| File | What happens |
| --- | --- |
| `catalog/models/gathered_catalog_mod.dart` | new — model, build function, provider |
| `catalog/summary_resolver.dart` | new — the preference resolver |
| `catalog/models/catalog_mod.dart` | renamed to `mod_repo_entry.dart` in the last step |
| `catalog/widgets/mod_summary/mod_summary_data.dart` | deleted; its logic moves into the new model |
| `catalog/widgets/mod_summary/mod_summary_widget.dart` | takes a gathered mod; `_resolveSummary` deleted; `ModSummarySource` moves out |
| `catalog/catalog_mod_card.dart` | takes a gathered mod; `_targetLlmMod` and the AI switch deleted |
| `catalog/forum_post_dialog/catalog_mod_details_dialog.dart` | body uses the resolver; the wrong-mod AI bug is fixed |
| `catalog/forum_post_dialog/forum_post_dialog.dart` | gathers with `forumDetails` filled in |
| `catalog/mod_browser_page_controller.dart` | filters and sort work on gathered mods |
| `catalog/mod_browser_page.dart` | grid holds gathered mods; per-card lookups removed |
| `test/gathered_catalog_mod_test.dart` | new |
| `test/summary_resolver_test.dart` | new |

## What could go wrong

**The forum-details path.** `forum_post_dialog.dart` builds from a cached forum
post, which has fields the index doesn't. The merge order (details first, index
as filler) has to match what `ModSummaryData.fromDetails` does today, or the
post dialog quietly loses its author avatar and post count. Task 4 copies that
builder's logic field by field rather than rewriting it.

**Sorting.** `sortCatalogMods` in `catalog_search.dart` takes a `forumLookup`
map so it can sort by views and dates. Once those live on the gathered mod, the
map argument is dead weight — but `searchCatalogMods` and `extractVersionGroups`
in the same file also take raw entries. Task 9 moves all three together so the
file stays consistent.

**The catalog details dialog's AI text will change** for add-on cards. That's
the bug fix, and it's the one visible difference users may notice.
