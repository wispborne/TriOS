# Tasks

## Build the model

- [x] 1. Add `lib/catalog/models/gathered_catalog_mod.dart` with the
      `GatheredCatalogMod` class: the raw entry, each candidate text kept apart,
      the resolved AI entry, images, forum facts, the WIP and Archived flags,
      attribute keys, install state, and downloads. Move `modInfoDescription`,
      `trimmedOrNull`, and `firstNonBlank` into it from `mod_summary_data.dart`,
      keeping their names.

- [x] 2. Write `gatherCatalogMod()` in the same file, covering the catalog entry
      and forum index. Fold in what `ModSummaryData.fromCatalog` does today, plus
      the thread lookup from `_resolveLlmMod` / `_targetLlmMod`, the attribute
      keys from `_attributeValuesFor`, and the download candidates. No `ref`, no
      settings, no `BuildContext`.

- [x] 3. Add `test/gathered_catalog_mod_test.dart`: an add-on card gets its own
      AI entry, an add-on with no name match falls back to the thread's main mod,
      a normal entry gets the main mod, all five texts survive, and the WIP and
      Archived flags come through.

- [x] 4. Add the forum-details path to `gatherCatalogMod()`. Port
      `ModSummaryData.fromDetails` field by field rather than rewriting it —
      author title, avatar path, and post count only exist there, and the merge
      order is details first, index as filler. Cover it in the test file.

## Build the resolver

- [x] 5. Add `lib/catalog/summary_resolver.dart` with
      `AuthorTextOrder`, `AiTextLength`, `resolveSummaryText()`,
      `resolveAuthorText()`, and `shouldShowAiWithAuthorText()`. Move `ModSummarySource`
      here from `mod_summary_widget.dart`.

- [x] 6. Add `test/summary_resolver_test.dart`: each of the three AI modes, both
      author-text orders, the reported source is right when AI text is used, and
      `never` returns nothing rather than AI text when there's no human-written
      text.

## Wire it up

- [x] 7. Add `gatheredCatalogModsProvider` in the same file, watching
      `catalogEntriesProvider`, `forumDataByTopicId`, and `catalogLinksProvider`.
      It must not watch version-check results.

- [x] 8. Move `ModSummaryWidget` onto `GatheredCatalogMod` and the resolver.
      Delete its `_resolveSummary`. It keeps asking for `shortFirst` and
      `paragraph`, so what it shows doesn't change.

- [x] 9. Move `searchCatalogMods`, `sortCatalogMods`, and `extractVersionGroups`
      in `lib/utils/catalog_search.dart` onto gathered mods, all three together.
      Drop `sortCatalogMods`'s `forumLookup` argument — views and dates are on
      the model now.

- [x] 10. Move `CatalogPageController` across: `allMods` and `displayedMods`
      become `List<GatheredCatalogMod>`, the filter groups become
      `FilterGroup<GatheredCatalogMod>`, and `_attributeValuesFor` shrinks to
      reading `mod.attributeKeys`. The `ref.read(forumDataByTopicId)` inside the
      filter test must be gone. Leave `statusForModName` and `updatesCount`
      alone — update status stays where it is.

- [x] 11. Move `mod_browser_page.dart` and `CatalogModCard` across. The grid holds
      gathered mods, the per-card topic-id lookup in `itemBuilder` goes, and the
      card's `_targetLlmMod` and its copy of the AI switch go. The card keeps
      asking for `shortFirst` and `sentence` in the body and the AI paragraph in
      its tooltip.

- [x] 12. Move `catalog_mod_details_dialog.dart` and `forum_post_dialog.dart`
      across. The details dialog body uses `resolveAuthorText()` with `longFirst`
      and `shouldShowAiWithAuthorText()`, which fixes the add-on card showing the wrong
      mod's AI text. The post dialog gathers with `forumDetails` filled in.

## Clean up

- [x] 13. Delete `lib/catalog/widgets/mod_summary/mod_summary_data.dart` and any
      imports your changes left unused. Run `fvm flutter analyze` and
      `fvm flutter test`. Everything must be green before the rename below.

## Rename, as one mechanical pass

Only start this once task 13 is green. Renaming earlier is what makes it
risky — see the design doc for why.

- [x] 14. Rename the raw type: `CatalogMod` to `ModRepoEntry`, `CatalogModsRepo`
      to `ModRepoFile`, `CatalogModImage` to `ModRepoImage`, and the file
      `catalog_mod.dart` to `mod_repo_entry.dart`. Rename
      `catalogEntriesProvider` to `modRepoEntriesProvider`. Field names stay
      exactly as they are — the JSON on disk depends on those. Re-run
      `dart run build_runner build --delete-conflicting-outputs`.

- [x] 15. Rename the gathered type: `GatheredCatalogMod` to `CatalogMod`,
      `gathered_catalog_mod.dart` to `catalog_mod.dart`, and
      `gatheredCatalogModsProvider` to `catalogModsProvider`. `gatherCatalogMod()`
      keeps its name. Grep for "gathered" and "Gathered" afterwards — nothing
      should be left.

- [x] 16. Run `fvm flutter analyze` and `fvm flutter test` again. Start the app
      and open the Catalog page once, to confirm `mod_repo.json` still parses.

## Finish

- [x] 17. Time how long `catalogModsProvider` takes to build the full
      catalog, and log it the way `mod_browser_manager.dart` already logs its
      parse time. If it's slow enough to show up as a hitch on the UI thread,
      say so before this is called done.

- [x] 18. Check by hand on the Catalog page: cards, tooltips, the details dialog,
      and the post dialog all still read right; the Attributes, Status, Game
      Version, and Category filters still work; sorting by views and date still
      works; and an add-on card's details dialog now shows its own AI text.
      Flipping the AI-summary setting and the master AI switch should change the
      text without the grid flickering or reloading.
