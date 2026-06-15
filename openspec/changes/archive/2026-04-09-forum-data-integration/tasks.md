## 1. Models

- [x] 1.1 Create `ForumModIndex` model (`lib/catalog/models/forum_mod_index.dart`) with `@MappableClass`, all fields from spec, custom `DateFormat` hook for forum date strings (`"MMMM d, yyyy, hh:mm:ss a"`)
- [x] 1.2 Create `ForumDataBundle` model (`lib/catalog/models/forum_data_bundle.dart`) with `@MappableClass`, fields `updatedAt` (DateTime) and `index` (List<ForumModIndex>), ignoring `details`/`assumedDownloads`
- [x] 1.3 Add `ForumDataSource` to `ModRecordSource` (`lib/mod_records/mod_record_source.dart`) with discriminator `'forumData'`, all stat fields, and `applyOverridesFrom` method
- [x] 1.4 Add `forumData` typed accessor to `ModRecord` (`lib/mod_records/mod_record.dart`) and add `ForumDataSource` case to `resolvedSources` merge switch
- [x] 1.5 Run `dart run build_runner build --delete-conflicting-outputs` and fix any codegen issues

## 2. Fetching & Caching

- [x] 2.1 Add forum data bundle URL to `Constants` (`lib/trios/constants.dart`)
- [x] 2.2 Create `ForumDataManager` provider (`lib/catalog/forum_data_manager.dart`) following the `mod_browser_manager.dart` pattern: StreamProvider, 24h cache TTL, cache files `forum_data_bundle.json` + `forum_data_bundle.meta`, fallback to stale cache on fetch failure
- [x] 2.3 Build topic ID lookup map (`Map<int, ForumModIndex>`) in the manager for O(1) access, expose a `lookupByTopicId` helper or make the map accessible

## 3. ModRecordsStore Integration

- [x] 3.1 Add `ref.listen` for the forum data provider in `ModRecordsStore.build()`
- [x] 3.2 In `_autoPopulate()`, build a `forumByTopicId` index from the forum data, then for each record with a `forumThreadId`, create and attach a `ForumDataSource`

## 4. Catalog UI — Display

- [x] 4.1 In `ScrapedModCard`, look up forum data for the displayed mod (via `ModRecord.forumData` or direct topic ID lookup) and display view count + reply count with locale-aware formatting
- [x] 4.2 Add tooltips to the new stat displays explaining what they represent

## 5. Catalog UI — Sort & Filter

- [x] 5.1 Add "Most Viewed" and "Last Activity" sort options to the Catalog page sort dropdown
- [x] 5.2 Implement sort comparators that handle null forum data (sort nulls last)
- [x] 5.3 Add WIP and Archived three-state filter toggles to the Catalog filter panel
- [x] 5.4 Implement filter logic: WIP filter checks `ForumDataSource.isWip`, Archived filter checks `ForumDataSource.isArchived`

## 6. Debug Settings

- [x] 6.1 Add a "Forum Data" group to `SettingsDebugSection` (`lib/trios/settings/debug_section.dart`) with: a button to force-refresh the forum data cache (bypasses the 24h TTL), a button to clear the cached forum data files, and a label showing the current cache status (cached at timestamp, entry count, or "not cached")
- [x] 6.2 Add a "Show Forum Data" info button that opens a dialog displaying the raw forum data stats: bundle `updatedAt`, total index entries, number of entries matched to ModRecords, and a scrollable list of all entries (topicId, title, views, replies) — following the pattern of the existing "Show current app settings" and "Show version checker cache" dialog buttons
