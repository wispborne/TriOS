# Read the new mod catalog files

Status: ready-for-agent

## Why

The scraper no longer updates `ModRepo.json` or `forum-data-bundle.json`. It now publishes two new files to the same repo:

- `mod-catalog.json` lists every mod. Each mod has a permanent `id` and a `sourcePosts` list naming the forum topic and Discord thread it came from.
- `mod-catalog-details.json` is the old forum bundle plus a `discordThreads` list holding the AI answers for Discord threads.

Both are live at `raw.githubusercontent.com/wispborne/StarsectorModRepo/refs/heads/main/`. Until TriOS reads them, its catalog stays frozen at the day the old files stopped changing.

The new catalog also does work TriOS used to do itself. A forum topic that holds several mods now gives one catalog entry per mod. So TriOS no longer needs `withSynthesizedAddonEntries` to make extra cards for those mods, or `_isTheCatalogEntry` to guess which AI answer belongs to which entry. Each entry's `sourcePosts` names the exact AI answer by its `llmModName`.

This is task 11.6 of the scraper's `unify-mod-catalog` change.

## What changes

- Download `mod-catalog.json` and `mod-catalog-details.json` instead of the old two files. Cache them under new file names so an old cached file is never read as the new format.
- Read each entry's `id` and `sourcePosts`.
- Read `discordThreads` from the details file.
- Find a mod's AI answer through its source posts: the forum topic's answer with the matching `llmModName` first, then the Discord thread's answer. No name guessing.
- Mods known only from Discord now get their AI summary, downloads and extras on the catalog card.
- Remove `withSynthesizedAddonEntries`, `_isTheCatalogEntry`, `_resolveLlmMod` and `catalogAddonEntryMatchKey`.
- Keep the "part of <thread>" label. An entry gets it when the AI found it inside a shared forum topic (its forum source post has `foundBy: llm`).
- Save the catalog `id` in a mod's record. When linking catalog entries to installed mods, a saved id is tried first, then the saved name, then the existing clues.

## Out of scope

- Collections (`collections` in the catalog). They exist so old website addresses keep working. TriOS has no use for them.
- `movedIds`. TriOS has no saved ids yet, so there is nothing to move.
- Combining forum and Discord AI answers field by field. TriOS uses the whole forum answer when there is one, else the whole Discord answer.
- The forum post dialog and its download list. They still read the forum topic's whole AI answer by topic id, as today.
- Renaming `ModRepoEntry` and the other "mod repo" names in the code.
