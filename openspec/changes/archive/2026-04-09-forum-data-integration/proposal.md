## Why

A community modder maintains a daily-scraped bundle of the Starsector forum's mod index (`forum-data-bundle.json`), containing 872 mod entries with stats like view counts, reply counts, last activity dates, WIP/archived status, and forum categories. This data complements the existing `modrepo.json` catalog and would enrich the Mod Catalog with popularity metrics, activity signals, and better filtering — information that modrepo.json doesn't carry.

## What Changes

- New `ForumModData` model to represent lightweight index entries from the forum data bundle (not the heavy `details`/`contentHtml` section).
- New `ForumDataManager` provider to fetch, cache (24h TTL), and parse the bundle's `index` array.
- New `ForumDataSource` added to `ModRecordSource`, wired into `ModRecordsStore._autoPopulate()` matching by `topicId` (forum thread ID).
- Catalog UI (`ScrapedModCard`, `CatalogPage`) updated to display view/reply counts, last activity, and support sorting/filtering by these new fields.
- Forum stats surfaced in the Mod Manager for installed mods (last forum activity as a "maintenance" signal).

## Capabilities

### New Capabilities
- `forum-data-fetching`: Fetching, caching, and parsing the forum data bundle with a 24h cache TTL. Provides lookup by topic ID.
- `forum-data-catalog-integration`: Wiring forum data into `ModRecordsStore` via a new `ForumDataSource`, and surfacing forum stats (views, replies, last activity, WIP/archived status) in the Catalog UI with new sort/filter options.

### Modified Capabilities

## Impact

- **Models**: New `ForumModData` model + `ForumDataSource` in `mod_record_source.dart`. Requires `build_runner` for dart_mappable codegen.
- **Providers**: New `forumDataManagerProvider` in `lib/catalog/`. `ModRecordsStore` gains a new listener for forum data.
- **UI**: `ScrapedModCard` and `CatalogPage` gain new display elements and filter/sort options.
- **Network**: One additional HTTP request per 24h (~3MB compressed) to GitHub raw content.
- **Dependencies**: No new package dependencies expected (reuses existing HTTP and caching patterns).
