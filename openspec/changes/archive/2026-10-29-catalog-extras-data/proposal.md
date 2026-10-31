# Read the mod catalog extras file

Status: ready-for-agent

Blocked until the scraper publishes `mod-catalog-extras.json` (its change `mod-catalog-extras-file`). The field names below must be checked against that change before building.

## Why

Starmodder shows facts that TriOS can't get from its two current files:

- release history
- mods that share a name
- gallery pictures with AI captions
- the 13 cleaned-up categories
- requirements matched to a catalog mod id
- the Discord post text
- the dates Starmodder uses for "posted", "last edited" and "last release"

The scraper works these out while it builds Starmodder's files. Some of them depend on files the scraper saves between runs, so TriOS can't work them out itself. The scraper will publish them in a new file, `mod-catalog-extras.json`, with one record per catalog mod id.

This change only loads that file and joins it to each catalog mod. The changes that show the data are `catalog-filters-and-sort` and `catalog-details-dialog`.

## What changes

- Download `mod-catalog-extras.json` from the same place as `mod-catalog.json`. Keep it for 6 hours, the same as the catalog.
- Add models for the file and a provider other catalog code can watch.
- Give each `CatalogMod` its extras record, found by catalog id.
- Add fallbacks for when the file is missing, failed to load, or is too new to read:
  - categories come from the catalog's raw categories
  - requirement names come from the AI answer's `extras.needs` and `extras.optionalNeeds`
  - the "add to a running game" answer comes from the AI answer's `extras.canAdd`
- Say whether the extras are available, for the whole file and for each mod. Changes 4 and 5 use this to hide release history, the Last release filter, AI gallery captions, the same-name panel and the Discord post.
- Stop the shared file downloader from saving error pages. Today a `404 Not Found` reply would be saved as the file. That is exactly what TriOS gets before the scraper publishes the extras file.
- Add a third card to the Data Sources dialog for the new file.
- Fix the old names in the Data Sources dialog. The second card still says "QB's Forum Bundle" and links to QB's GitHub. Both files now come from `wispborne/StarsectorModRepo`.
- Update the `catalog-mod-model` and `catalog-data-sources-dialog` specs. Both still describe how things worked before `mod-catalog-v2`.

## Out of scope

- Showing any of the new data. That is in `catalog-filters-and-sort` and `catalog-details-dialog`.
- Switching the Category filter to the cleaned categories. That is in `catalog-filters-and-sort`.
- The Forum Data section on the debug settings page. It is about the details file only, and the Data Sources dialog already refreshes and clears every catalog file.
- The `statSync` call in the Data Sources dialog. That is a task in `sync-to-async-io`.
