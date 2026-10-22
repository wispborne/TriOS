# Tasks

## 1. Models

- [x] Add `CatalogSourcePost` (`kind`, `id`, `llmModName`, `foundBy`) and its two enums, each with an `unknown` default, in `mod_repo_entry.dart`.
- [x] Add `id` and `sourcePosts` to `ModRepoEntry`, with `forumPost` and `discordPosts` getters.
- [x] Remove `partOfThreadTitle` from `ModRepoEntry`. Make `isPartOfThread` true when the forum source post has `foundBy: llm`.
- [x] Add `DiscordThreadAnswer` (`threadId`, `url`, `name`, `mods`) and `discordThreads` to `ForumDataBundle`. Bad mod entries are dropped the same way the forum `llm` block drops them.
- [x] Add `catalogId` to `CatalogSource`, including `applyOverridesFrom`.
- [x] Regenerate the mappers.

## 2. Loading

- [x] Replace `modRepoUrl` and `forumDataBundleUrl` with `modCatalogUrl` and `modCatalogDetailsUrl`.
- [x] Point both fetchers at the new URLs and new cache file names.
- [x] Parse `discordThreads` in `forumDataProvider`. Add `discordThreadsById`.
- [x] Update the file names in the data sources dialog.

## 3. Catalog entries and AI answers

- [x] Remove `withSynthesizedAddonEntries`, `_isTheCatalogEntry` and `catalogAddonEntryMatchKey`. `modRepoEntriesProvider` returns the catalog items.
- [x] Add `llmModForEntry`. Remove `_resolveLlmMod`.
- [x] Give `gatherCatalogMod` a `discordThreads` parameter. Set `partOfThreadTitle` from the forum topic title when the entry is part of a thread.
- [x] Pass the entry's Discord answers from `catalogModsProvider` and from the card's rebuild with forum details.

## 4. Links and records

- [x] In `matchCatalogToInstalled`, try a saved `catalogId` before a saved name.
- [x] Key `CatalogLinks` by entry id when there is one.
- [x] Save `catalogId` in `_buildCatalogSource`.
- [x] Pass the plain catalog items to the matcher in `ModRecordsStore`.
- [x] Carry `catalogId` in `DownloadSourceHint` and save it when an install links a record.
- [x] Find the catalog entry by `catalogId` first in the mod context menu.

## 5. Tests and checks

- [x] Update `catalog_links_test.dart` and `gathered_catalog_mod_test.dart` for the removed code.
- [x] Add the tests listed in `design.md`.
- [x] Run `flutter analyze` and `flutter test`.
