# Design

## The new files

Both files sit next to the old ones in `wispborne/StarsectorModRepo` on `main`.

`mod-catalog.json` has the same shape as `ModRepo.json`, with more fields:

```json
{
  "items": [ {
    "id": "3d-sector-2",
    "name": "3D Sector V0.3.5",
    "...": "every field ModRepo.json had",
    "sourcePosts": [
      { "kind": "forum",   "id": "36154",               "llmModName": "3D Sector", "foundBy": "rulesAndLlm" },
      { "kind": "discord", "id": "1559645440188874795", "llmModName": "3D Sector", "foundBy": "rulesAndLlm" }
    ]
  } ],
  "collections": [ ... ],
  "movedIds": { ... },
  "totalCount": 1272,
  "lastUpdated": "..."
}
```

- `kind` is `forum`, `discord` or `nexus`.
- `id` is the forum topic id or the Discord thread id, as a string.
- `llmModName` is the name of this mod inside that post's AI answer. It is absent when the AI found nothing for the post.
- `foundBy` is `rules`, `llm` or `rulesAndLlm`. A forum post found only by the AI (`llm`) is always a topic shared with other catalog entries. In the current data, all 88 such posts are on shared topics.

The `ModSource` and `ModUrlType` values are the same as before.

`mod-catalog-details.json` is the old forum bundle with one more top-level list:

```json
"discordThreads": [ {
  "threadId": "1203053249377079297",
  "url": "https://discord.com/channels/...",
  "name": "Example Mod 1.0.0",
  "mods": [ { "name": "Example Mod", "role": "main", "downloads": [ ... ], "image": "ext:...", "extras": { ... } } ]
} ]
```

Each item in `mods` has the same shape as a mod in a forum topic's `llm.mods`.

## Decisions

### Keep the existing model classes and add fields

`ModRepoEntry` gains `id` and `sourcePosts`. Renaming it to match the new file name would touch about 30 files for no change in behavior.

`sourcePosts` uses a new `CatalogSourcePost` class with `kind`, `id`, `llmModName` and `foundBy`. Its two enums each get an `unknown` default. An old TriOS crashed on an unknown enum value in the catalog, and this stops the same thing happening when the scraper adds a new kind.

`ModRepoFile` stays as it is. dart_mappable skips JSON keys the class does not declare, so `collections`, `movedIds` and `totalCount` are ignored.

### New cache file names

The fetchers cache to `mod_catalog.json` and `mod_catalog_details.json`. A cached `mod_repo.json` from an older TriOS has the old format and must not be read as the new one. The old cache files are left on disk.

### Find the AI answer through the source posts

A new pure function, `llmModForEntry`, takes the entry, the forum topic's index entry and the entry's Discord thread answers. It:

1. Looks at the entry's forum source post. If it has an `llmModName`, it returns the mod with exactly that name from the forum topic's `llm.mods`.
2. Otherwise, it does the same for each Discord source post, using that thread's `mods`.
3. Otherwise, it returns null.

This replaces `_resolveLlmMod`. That function fell back to the thread's main mod, which could attach another mod's answer to an entry. The scraper has already decided which answer belongs to which entry, so TriOS no longer guesses.

A rules-only entry (no `llmModName`) gets no AI answer. That matches what the scraper decided: the AI found no main mod in that post that it could check against the post.

### Discord answers load with the forum index

`forumDataProvider` already parses `updatedAt` and `index` and skips the heavy `details`. It now also parses `discordThreads`. A new provider, `discordThreadsById`, maps thread id to `DiscordThreadAnswer`, like `forumDataByTopicId` does for topics.

`gatherCatalogMod` takes a new `discordThreads` list. `catalogModsProvider` and the card's rebuild with forum details both pass it.

### "Part of a thread" comes from `foundBy`

`ModRepoEntry.partOfThreadTitle` was set at runtime by `withSynthesizedAddonEntries`. It goes away.

`ModRepoEntry.isPartOfThread` becomes true when the entry's forum source post has `foundBy: llm`. The catalog matcher keeps using it to stop shared-topic entries from matching an installed mod by forum thread id.

`gatherCatalogMod` sets `CatalogMod.partOfThreadTitle` to the forum topic's title when `isPartOfThread` is true. The card's "part of" label reads it as before. If the forum index has no entry for the topic, the label is not shown, but the matcher rule still applies.

`modRepoEntriesProvider` becomes the catalog's items with nothing added.

### Save the catalog id in mod records

`CatalogSource` gains `catalogId`. `_buildCatalogSource` fills it in, and `applyOverridesFrom` carries it.

`matchCatalogToInstalled` reads saved links in this order:

1. A record whose `catalogId` equals the entry's `id`.
2. A record with no `catalogId` whose `name` equals the entry's name (today's rule). Records saved before this change only have a name. A record with an id never links by name, because two entries can share a name.
3. The existing clues: forum thread id, Nexus id, exact name, close name.

The rule that a match to another entry's own name wins still applies to both saved-link steps.

`CatalogLinks` indexes entries by `id` when they have one, and by name otherwise. Two catalog entries can share a name (topic 10555 has two "Bushi" entries), and keying by name alone would make one hide the other. `linkForName` stays for callers that only have a name.

The mod context menu finds a record's catalog entry by `catalogId` first, then by name.

`ModRecordsStore` passes the catalog items straight to the matcher. It still reads `forumDataByTopicId`, because it copies forum stats into each record.

## Files

| File | Change |
|---|---|
| `lib/trios/constants.dart` | `modCatalogUrl` and `modCatalogDetailsUrl` replace the two old URLs |
| `lib/catalog/catalog_manager.dart` | Fetch `mod-catalog.json`, new cache name |
| `lib/catalog/forum_data_manager.dart` | Fetch `mod-catalog-details.json`, new cache name, parse `discordThreads`, add `discordThreadsById` |
| `lib/catalog/models/mod_repo_entry.dart` | `id`, `sourcePosts`, `CatalogSourcePost`, its enums; remove `partOfThreadTitle`; new `isPartOfThread` |
| `lib/catalog/models/forum_data_bundle.dart` | `discordThreads`, `DiscordThreadAnswer` |
| `lib/catalog/catalog_links.dart` | Remove the extra-card code; id-first saved links; `CatalogLinks` keyed by id |
| `lib/catalog/models/catalog_mod.dart` | `llmModForEntry`, `discordThreads` parameter, `partOfThreadTitle` from the forum index |
| `lib/catalog/catalog_mod_card.dart` | Pass Discord answers when rebuilding with forum details |
| `lib/catalog/catalog_data_sources_dialog.dart` | New file names in text |
| `lib/mod_records/mod_record_source.dart` | `CatalogSource.catalogId` |
| `lib/mod_records/mod_records_store.dart` | Save `catalogId`; match against the plain catalog items |
| `lib/trios/download_manager/download_manager.dart` | `DownloadSourceHint.catalogId`, so an install saves the id |
| `lib/mod_manager/mod_context_menu.dart` | Find the catalog entry by `catalogId` first |
| Generated `.mapper.dart` files | Regenerate |
| `test/catalog/catalog_links_test.dart`, `test/gathered_catalog_mod_test.dart` | Update for the removed code; add tests below |

## Tests

- Parse a real `mod-catalog.json` entry with two source posts, and a real `discordThreads` item.
- An unknown `kind` or `foundBy` value parses as `unknown` instead of failing.
- `llmModForEntry`: picks the forum mod by `llmModName` on a topic with several mods; falls back to Discord when the forum has no answer; returns null for a rules-only entry even when the topic has a main mod.
- An entry whose forum post has `foundBy: llm` does not match by forum thread id, and gets the topic title as its "part of" label.
- A saved `catalogId` links the right entry after the entry's name changes.
- Two entries with the same name and different ids each keep their own link.
