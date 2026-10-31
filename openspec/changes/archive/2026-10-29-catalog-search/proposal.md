# Better Catalog search

Status: ready-for-agent

## The problem

The Catalog search box finds too little, and what it finds comes back in no useful order.

- Each comma-separated term is matched as one piece of text. "graphics lib" finds nothing, because no single search term holds both words.
- There is no ranking. Results follow the chosen sort, so typing a mod's exact name can leave it on page three behind "Popular" mods that mention the word.
- No typo tolerance. "nexerlin" finds nothing.
- Shorthand only works for full initials. "sawp" works, but "indevo" (Industrial Evolution) and "kol" (Knights of Ludd) do not.
- Nicknames the scraper found ("ssp", "brdy") are downloaded but not searched.
- There is no way to ask about one field, such as only the author.
- The box gives no hints about what it understands.

Starmodder's search already solves all of this. Its rules are in `Mod_Repo_Scraper/site/search.js`.

## The solution

Port Starmodder's search rules to Dart and use them for the Catalog.

- Spaces mean every word must match. Commas mean OR. `"quotes"` match a phrase. A minus in front leaves matches out.
- Results are ranked by how well they match. A new "Best match" sort uses that rank.
- Close spellings, word-start shorthand, words split at capitals, initials, nicknames and author aliases all count.
- `field:value` asks about one field, such as `author:wisp` or `category:weapons`.
- `has:` and `is:` ask yes-or-no questions, such as `has:source` or `-is:wip`.

TriOS keeps searching two things Starmodder does not: the full description and every link. They rank below everything else.

The Catalog switches from its plain search bar to `SmartSearchBar`, the search box the Mods page and the viewers use. It suggests field names and values as you type. It does not suggest mod names, because the grid already filters as you type. A help panel explains the search rules.

"Best match" is picked for you when you start typing. When you clear the search, your earlier sort comes back. A sort you pick by hand while typing is kept.

## In scope

- The Dart search engine for Catalog mods, with tests ported from Starmodder's behavior.
- The "Best match" sort and its switching rules.
- `SmartSearchBar` on the Catalog page, with field suggestions and a search help panel.
- Two new options on `SmartSearchBar`, used only by the Catalog: keeping fields as typed text instead of pills, and a custom help panel. Every other page keeps today's behavior.
- Reading the few facts the `has:` / `is:` flags need from the details file TriOS already downloads: nicknames, the Tool flag, "can add to a save" and "uses AI".

## Out of scope

- Mod-name suggestions under the search box.
- Search history and remembering the search text between sessions.
- The remembered sort itself. That is part of `catalog-filters-and-sort`. This change only makes sure "Best match" is never the sort that gets remembered.
- Reading the new `mod-catalog-extras.json` file. That is `catalog-extras-data`. Once it lands, cleaned names, cleaned categories and other author names from it are searched too, through the same facts.
- The search on the Mods page and the viewer pages.
