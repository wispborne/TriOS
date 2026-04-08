## Context

`ModRecord` currently stores `names` (`Set<String>`) and `authors` (`Set<String>`) as top-level fields, aggregated during auto-population from installed mods and catalog entries. This is inconsistent with the source-sub-entry architecture: all other mod information lives within typed `ModRecordSource` sub-entries, but names/authors are hoisted to the top. The data also exists implicitly in the sources already (catalog has `catalogName`, installed source has the mod folder which implies mod_info.json), making the top-level fields redundant.

## Goals / Non-Goals

**Goals:**
- Move name and author storage into the source sub-entries where the data originates
- Provide computed getters on `ModRecord` for convenient aggregation across sources
- Maintain backward compatibility with existing JSON files (graceful degradation)

**Non-Goals:**
- Changing the `userOverrides` architecture (it continues to work the same way)
- Modifying `VersionCheckerSource` or `DownloadHistorySource` (they don't carry name/author data)
- Changing how catalog matching works (still uses names for fuzzy matching — reads from source-level fields instead)

## Source Field Inventory (after this change)

**`InstalledSource`** — data from mod_info.json on disk
- `name` (`String?`) — mod display name ← **NEW**
- `author` (`String?`) — mod author ← **NEW**
- `installPath` (`String?`) — absolute path to mod folder
- `version` (`String?`) — mod version string
- `lastSeen` (`DateTime?`) — inherited from `ModRecordSource`

**`VersionCheckerSource`** — data from .version files
- `forumThreadId` (`String?`) — Fractal Softworks forum topic ID
- `nexusModsId` (`String?`) — NexusMods mod ID
- `directDownloadUrl` (`String?`) — direct download link
- `changelogUrl` (`String?`) — changelog link
- `masterVersionFileUrl` (`String?`) — remote .version file URL
- `lastSeen` (`DateTime?`)

**`CatalogSource`** — data from ModRepo.json
- `name` (`String?`) — mod display name ← **RENAMED** from `catalogName`
- `authors` (`List<String>?`) — mod authors ← **NEW**
- `forumUrl` (`String?`) — full forum thread URL
- `nexusUrl` (`String?`) — full NexusMods page URL
- `discordUrl` (`String?`) — Discord invite/channel URL
- `directDownloadUrl` (`String?`) — direct download link
- `downloadPageUrl` (`String?`) — download page URL
- `forumThreadId` (`String?`) — extracted forum topic ID
- `nexusModsId` (`String?`) — extracted NexusMods mod ID
- `categories` (`List<String>?`) — mod categories from catalog
- `lastSeen` (`DateTime?`)

**`DownloadHistorySource`** — captured when user downloads a mod
- `lastDownloadedFrom` (`String?`) — URL downloaded from
- `lastDownloadedAt` (`DateTime?`) — download timestamp
- `lastSeen` (`DateTime?`)

**`ModRecord`** (top-level) — after this change
- `recordKey` (`String`) — primary key (mod ID or `catalog:{name}`)
- `modId` (`String?`) — canonical mod ID from mod_info.json
- `firstSeen` (`DateTime?`) — when first encountered
- `sources` (`Map<String, ModRecordSource>`) — auto-populated data
- `userOverrides` (`Map<String, ModRecordSource>`) — user-edited overrides
- ~~`names`~~ — **REMOVED**, replaced by computed `allNames`
- ~~`authors`~~ — **REMOVED**, replaced by computed `allAuthors`

## Decisions

### 1. Add `name`/`author` to `InstalledSource`, `name`/`authors` to `CatalogSource`
**Choice**: `InstalledSource` gets `String? name` and `String? author` (singular, matching mod_info.json which has one author string). `CatalogSource` already has `catalogName` — rename to `name` for consistency, and add `List<String>? authors` (list, because catalog separates multiple authors).
**Rationale**: Each source carries the data it natively provides. mod_info.json has a single `author` field; the catalog has a structured author list.
**Alternative**: Keep `catalogName` and add `name` separately — rejected as redundant.

### 2. Computed getters replace stored fields
**Choice**: `ModRecord.allNames` returns the union of `name` fields from all resolved sources. `ModRecord.allAuthors` returns the union of author data. Both are computed from `resolvedSources`, so user overrides are respected.
**Rationale**: No stored state to get out of sync. The getters traverse the (small) resolved sources map on each access, which is negligible cost.

### 3. `merge()` no longer unions names/authors
**Choice**: `ModRecord.merge()` drops the `names`/`authors` union logic. Source merging already handles combining data from multiple records — the computed getters derive names/authors from the merged sources.
**Rationale**: With names/authors living in sources, the source-level merge is sufficient.

### 4. Rename `CatalogSource.catalogName` to `name`
**Choice**: Rename for consistency with `InstalledSource.name`.
**Rationale**: Reduces confusion. The field always held the mod's display name from the catalog. `catalogName` was only needed when `name` was a top-level field.

## Risks / Trade-offs

- **Existing JSON files** — Records saved with top-level `names`/`authors` will have those fields ignored on read (dart_mappable ignores unknown fields by default). The data is re-derived from sources on the next auto-populate cycle. → No data loss, just a one-time re-derivation.
- **`catalogName` rename** — Any code referencing `catalogName` must be updated. → Small scope: only `mod_records_store.dart` and `mod_record_sources_dialog.dart` reference it.
- **Computed getter performance** — `allNames`/`allAuthors` iterate resolved sources on every call. → Negligible: at most 4 source entries per record.
