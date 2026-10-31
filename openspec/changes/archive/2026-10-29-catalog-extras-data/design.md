# Design

## The file

The scraper's site build step writes `mod-catalog-extras.json` next to the other two files in `wispborne/StarsectorModRepo` on `main`. The shape is below.

Checked on 2026-10-29 against the scraper change `mod-catalog-extras-file` (archived as `2026-10-29-mod-catalog-extras-file`, models in `lib/site/models/catalog_extras.dart`) and against a real file it built (1,290 mods).

```json
{
  "schemaVersion": 1,
  "generatedAt": "2026-10-29T03:01:44.127205Z",
  "mods": {
    "ed-shipyard": {
      "displayName": "...",
      "categories": ["Ships and weapons"],
      "rawCategories": ["Ship Pack"],
      "otherAuthorNames": { "Nick XR": ["nick", "nick7884"] },
      "addedOn": "2022-07-24",
      "editedOn": "2026-09-13",
      "lastReleaseDate": "2026-09-15T00:00:00.000Z",
      "releases": [ { "modId": "ed-shipyard", "modName": "ED Shipyard", "seenOn": "2026-09-15", "oldVersion": "2.7.2", "newVersion": "2.7.3", "gameVersion": "0.98a", "changelogNotes": "...", "updateCompatibilityText": "...", "canUpdate": "yes" } ],
      "needs": [ { "name": "LazyLib", "id": "lazylib" } ],
      "optionalNeeds": [ { "name": "Nexerelin", "id": "nexerelin" } ],
      "isTool": false,
      "saveCompatible": true,
      "canAdd": "yes", "canUpdate": "yes", "canRemove": "no",
      "saveCompatibilityText": "...", "updateCompatibilityText": "...", "removalCompatibilityText": "...",
      "aiUse": { "usesAi": true, "uses": [ { "area": "portraits", "how": "generated", "extent": "all", "optional": true } ], "tools": ["..."], "quote": "..." },
      "sameNameMods": [ { "title": "...", "url": "...", "id": "...", "authors": ["..."], "gameVersion": "...", "modVersion": "...", "threadLastPostOn": "..." } ],
      "gallery": [ { "url": "...", "caption": "...", "aiCaption": "...", "aiKind": "logo", "aiFit": "good", "aiUnreadable": true, "small": true, "source": "discord" } ],
      "discordPostHtml": "<p>...</p>"
    }
  }
}
```

- The keys of `mods` are catalog ids, the same `id` that `mod-catalog.json` gives each item. The scraper may list ids the catalog doesn't have. TriOS ignores them.
- Nulls, empty lists and empty maps are left out of each record. The one exception is `aiUse`, which is `{}` when the AI read the post and found nothing about AI use.
- `displayName` is only there when the site's name differs from the catalog's name.
- `addedOn`, `editedOn`, `seenOn` and `threadLastPostOn` are `YYYY-MM-DD` text. `lastReleaseDate` and `generatedAt` are full date-times.
- `releases` is newest first. Each release repeats the mod's id and name.
- `id` in `needs`, `optionalNeeds` and `sameNameMods` is a catalog id, or missing when the scraper found no match. A same-name mod with no id has a forum `url` instead.
- `aiUse.uses[].area` is one of `portraits`, `illustrations`, `sprites`, `icons`, `music`, `voice`, `writing`, `translation`, `code`, `other`. `how` is `generated`, `edited` or `assisted`. `extent` is `all`, `most` or `some`.
- Gallery `aiKind` is one of `screenshot`, `logo`, `banner`, `art`, `button`, `badge`, `divider`, `missing`, `other`. `aiFit` is `good`, `okay` or `poor`. `source` is `forum`, `discord` or `nexus`.
- `canAdd`, `canUpdate` and `canRemove` are `yes`, `no` or `depends`, matching `extras.canAdd` in the details file today.

## Decisions

### A separate fetcher and provider

The file gets its own `CachedJsonFetcher` in a new `lib/catalog/catalog_extras_manager.dart`:

- cache file `mod_catalog_extras.json`, meta file `mod_catalog_extras.meta`
- URL `Constants.modCatalogExtrasUrl`
- kept for 6 hours, like the catalog

`catalogExtrasProvider` is a `StreamProvider<CatalogExtrasFile>`, written the same way as `browseModsNotifierProvider`. A failed download or a parse error logs a warning and emits nothing, so the catalog keeps working without it. `isLoadingCatalogExtras` tracks loading for the Data Sources dialog.

`catalogExtrasByIdProvider` gives a `Map<String, CatalogExtras>`. It is empty when the file is not available.

### A failed HTTP response is not saved

`CachedJsonFetcher.fetch` saves and returns any response body, whatever the status code. The extras file won't exist until the scraper publishes it, so GitHub answers `404: Not Found`. Today, TriOS would save that text as the file, keep it for 6 hours, and fail to parse it on every launch.

`fetch` will treat any status other than 200 as a failed fetch. It then falls back to the saved copy, as it already does on a network error. This also protects the other two catalog files.

When there is no saved copy, `fetch` throws the download error. Before, it threw the "file not found" error from reading the missing cache file, which hid the real cause in the log.

### Bad records are dropped one at a time

`mods` is decoded one record at a time. A record that fails to decode is dropped and counted, and `LogCollapser` logs one line with the count. This copies how the forum `llm` block drops bad mods (`ForumLlmDataHook`). One broken record must not hide the extras for every mod.

Enums (`canAdd`, gallery `source`, `aiKind`, `aiFit`) each get an `unknown` default. `mod-catalog-v2` did the same, because an unknown enum value once crashed an older TriOS.

### Schema version

TriOS knows schema version 1. A file with a higher `schemaVersion` is treated as not available, and the fallbacks apply. The scraper bumps the number only when an old reader would get a field wrong. Adding a field does not bump it, because dart_mappable skips keys a class doesn't declare. The scraper change has to state the same rule.

### The extras record lives on `CatalogMod`

`gatherCatalogMod` gets a `CatalogExtras? extras` parameter, and `CatalogMod` gets an `extras` field. `catalogModsProvider` looks up each entry's record by `entry.id` and passes it in. It stays a plain function with no provider reads, as the `catalog-mod-model` spec asks.

`catalogModsProvider` now also watches `catalogExtrasByIdProvider`. That adds one more rebuild of the gathered mods when the file arrives. It does not add a rebuild while the user types or while version checks arrive.

### Fallbacks live in getters on `CatalogMod`

Code that shows the data reads these getters, not `extras` directly. Each one uses the extras when they are there and falls back otherwise:

| Getter | From the extras | Fallback |
|---|---|---|
| `categories` | `extras.categories` | `entry.categories` |
| `requiredMods` | `extras.needs` | AI answer `extras.needs`, as names with no id |
| `optionalMods` | `extras.optionalNeeds` | AI answer `extras.optionalNeeds`, as names with no id |
| `canAddToSaveAnswer` | `extras.canAdd` | AI answer `extras.canAdd` |

When a mod has an extras record, the record wins for every getter, even when the field is empty. A record with no categories means the site gives the mod none. For example, the site drops the "Discord Only" category on purpose.

`catalog-search` already added `canAddToSave`, which returns true or false for the search's `addable` flag. It now returns true when `canAddToSaveAnswer` is `yes`. `canAddToSaveAnswer` returns `yes`, `no` or `depends` (as `CatalogSaveAnswer`) for the screens that show the answer.

`catalog-search` added `canAdd` to `ForumLlmExtras`. This change adds `needs`, `optionalNeeds`, `canRemove`, `removalCompatibility` and `updateNotes`. In the details file, `needs` and `optionalNeeds` are lists of names, and `canAdd` and `canRemove` are `yes`, `no` or `depends`.

Release history, `sameNameMods`, `gallery` and `discordPostHtml` have no fallback. Code reads them straight from `extras`, and shows nothing when `extras` is null.

### Is the extras file available?

- `catalogExtrasAvailableProvider` is true when the file loaded, its schema version is known, and it holds at least one record. Change 4 uses this to hide the Last release filter.
- `CatalogMod.extras != null` says whether one mod has a record. A mod added to the catalog after the extras file was built has none.

### Data Sources dialog

The dialog shows three cards. Each one uses the existing `_DataSourceCard`, and all three link to `https://github.com/wispborne/StarsectorModRepo`.

The user signed off this text on 2026-10-29:

| File | Title | Subtitle | Counted as |
|---|---|---|---|
| `mod-catalog.json` | Mod Catalog | mods from the forum index, the modding subforum and Discord | mods |
| `mod-catalog-details.json` | Mod Details | forum posts, forum stats, and other stuff from posts | threads |
| `mod-catalog-extras.json` | Mod Extras | release history, pictures, categories and requirements | mods |

### The debug Forum Data section stays as it is

`lib/trios/settings/debug_section.dart` has refresh and clear buttons for the details file only. The Data Sources dialog already has them for every catalog file, so the debug section doesn't get a copy for the new file.

## Files that change

- `lib/trios/constants.dart`: add `modCatalogExtrasUrl`.
- `lib/utils/cached_json_fetcher.dart`: a status other than 200 counts as a failed fetch. An optional `client` lets tests fake the server.
- `lib/catalog/catalog_extras_manager.dart` (new): fetcher and providers.
- `lib/catalog/models/catalog_extras.dart`: `catalog-search` creates it with `CatalogAiUse` and `CatalogAiUseEntry`. This change adds `CatalogExtrasFile`, `CatalogExtras`, `CatalogRelease`, `CatalogNeed`, `CatalogSameNameMod`, `CatalogGalleryPicture`, and their enums. `otherAuthorNames` is a `Map<String, List<String>>`, credited name to other names. `CatalogRelease` leaves out each release's `modId` and `modName`, because they repeat the record's own. `CatalogExtrasFile` is a plain class read by `parseCatalogExtrasFile`, not a mapper. Generated `.mapper.dart`.
- `lib/catalog/models/forum_llm_data.dart`: add `needs`, `optionalNeeds`, `canRemove`, `removalCompatibility` and `updateNotes` (as `ForumLlmUpdateNote`) to `ForumLlmExtras`.
- `lib/catalog/models/catalog_mod.dart`: the `extras` field and parameter, the fallback getters, and the lookup in `catalogModsProvider`.
- `lib/catalog/catalog_mod_card.dart` and `lib/catalog/forum_post_dialog/forum_post_dialog.dart`: these call `gatherCatalogMod` again to add forum post details. They now pass the extras record too.
- `lib/catalog/catalog_data_sources_dialog.dart`: the third card, and new titles and links.
- `openspec/specs/catalog-mod-model/spec.md` and `openspec/specs/catalog-data-sources-dialog/spec.md`: through the spec changes in this folder.

## Tests

- `CachedJsonFetcher`: a 404 response is not saved, and the saved copy is returned instead.
- Decoding a sample file: every field reads, unknown keys are skipped, a bad record is dropped while the rest load, and an unknown enum value becomes `unknown`.
- A file with a higher `schemaVersion` gives an empty map.
- `gatherCatalogMod` with and without an extras record: each fallback getter returns the extras value when there is one, and the fallback value when there isn't.
- `ForumLlmExtras` reads `needs`, `optionalNeeds` and `canAdd` from a real details-file sample.
