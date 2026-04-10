## Context

TriOS already aggregates mod data from multiple sources (installed mods, version checker `.version` files, ModRepo.json catalog) into a unified `ModRecord` via `ModRecordsStore`. Records are cross-referenced primarily by forum thread ID, then Nexus ID, then name matching. The forum data bundle at `https://raw.githubusercontent.com/theRoastSuckling/QBForumModData/refs/heads/main/forum-data-bundle.json` provides a daily scrape of 872 forum mod entries with stats (views, replies, activity dates, WIP/archived flags) that complement the existing catalog.

The bundle is ~3MB compressed / ~16MB uncompressed. The `index` array (~872 lightweight entries) is valuable; the `details` object (full HTML of first posts) is heavy and should be deferred.

## Goals / Non-Goals

**Goals:**
- Fetch and cache the forum data bundle with a 24-hour TTL, parsing only the `index` array eagerly.
- Add a `ForumDataSource` to the `ModRecordSource` hierarchy so forum stats attach to existing `ModRecord` entries.
- Wire forum data into `ModRecordsStore._autoPopulate()` using `topicId` matching against existing `forumThreadId` fields.
- Surface view count, reply count, last post date, WIP status, and archived status in the Catalog UI with sort and filter support.
- Provide a lookup-by-topic-ID method on the manager for direct access.

**Non-Goals:**
- Parsing or displaying `details.contentHtml` (16MB of HTML) — defer to a future change.
- Integrating `assumedDownloads` data (only 2 entries, not useful yet).
- Replacing ModRepo.json — this is supplemental data, not a replacement.
- Displaying forum data in the Mod Manager grid (future enhancement; this change focuses on the Catalog).

## Decisions

### 1. Parse only `index`, not `details`

The `index` array contains all the stats needed for catalog enrichment (~872 small objects). The `details` object holds full HTML content and is the bulk of the 16MB. Parsing it eagerly would waste memory and CPU for data we don't yet display.

**Alternative considered:** Parse everything and hold in memory. Rejected due to memory cost for unused data.

**Alternative considered:** Stream-parse the JSON to skip `details`. Rejected as over-engineered for a 3MB compressed download; simply decoding `index` from the parsed top-level map is sufficient.

### 2. Add `ForumDataSource` as a new `ModRecordSource` subtype

This follows the existing pattern (`InstalledSource`, `VersionCheckerSource`, `CatalogSource`, `DownloadHistorySource`). The new source stores forum-specific stats that don't belong in `CatalogSource` (which represents ModRepo.json data).

**Alternative considered:** Extend `CatalogSource` with optional forum fields. Rejected because it conflates two distinct data sources with different refresh cadences and provenance.

### 3. Use the existing `_fetchWithCache` pattern from `mod_browser_manager.dart`

The caching approach (JSON file + meta file with `cachedAt` timestamp) is proven and simple. We'll replicate it with a 24-hour TTL instead of 1-hour.

**Alternative considered:** Shared generic cache utility. Would be cleaner but is a separate refactor — out of scope.

### 4. Match forum data to records by `topicId` ↔ `forumThreadId`

`ModRecordsStore` already indexes records by `forumThreadId`. The forum bundle uses `topicId` as its primary key. These are the same value (the numeric SMF topic ID). Matching is straightforward.

For catalog-only records (no installed mod), the `CatalogSource.forumThreadId` field provides the link. For installed mods, `VersionCheckerSource.forumThreadId` or `CatalogSource.forumThreadId` provides it.

Records without a `forumThreadId` won't get forum data — this is acceptable since there's no reliable way to match them.

### 5. Custom date parsing for forum date strings

Forum dates use the format `"November 17, 2022, 07:14:08 AM"`. Dart's `DateTime.parse()` won't handle this. We'll use `DateFormat` from the `intl` package (already a dependency) with pattern `"MMMM d, yyyy, hh:mm:ss a"`.

### 6. `sourceBoard` as `int?`

The data shows `sourceBoard` as both `int` and previously reported as `String | null`. We'll model it as `int?` and handle JSON deserialization flexibly (accept both string and int).

## Risks / Trade-offs

- **[Data freshness]** The bundle is scraped daily by a third party. If the source goes offline or changes format, forum data silently becomes unavailable. → Mitigation: Graceful degradation — the catalog works fine without it, just without forum stats. Log warnings on fetch/parse failure.
- **[Download size]** ~3MB compressed per fetch. → Mitigation: 24h cache TTL means at most one download per day. Consider `If-Modified-Since` or ETag headers in the future if the source supports them.
- **[Unmatched mods]** Mods without a `forumThreadId` in their ModRecord won't get forum stats. → Mitigation: Acceptable gap. Could add name-based fuzzy matching later, but thread ID matching covers the majority of cases.
- **[Schema changes]** The third-party bundle format could change without notice. → Mitigation: Use `@MappableField` with explicit keys and nullable fields so missing/added fields don't break parsing.
