## 1. Backend parity for `mod_browser_manager`

- [x] 1.1 Hoist `mod_repo.json` and `mod_repo.meta` into private top-level constants (`_cacheFileName`, `_metaFileName`) at the top of `lib/catalog/mod_browser_manager.dart`, matching `forum_data_manager.dart`'s layout
- [x] 1.2 Refactor `_fetchModRepoWithCache()` to accept an optional `bool bypassCache = false` parameter; when true, skip the cache-read branch but still write fresh results back to cache
- [x] 1.3 Add a fallback to stale cache on fetch failure, matching `forum_data_manager.dart`'s behavior (currently `mod_browser_manager.dart` rethrows)
- [x] 1.4 Add public top-level `Future<String> forceRefreshModRepo()` that calls `_fetchModRepoWithCache(bypassCache: true)`
- [x] 1.5 Add public top-level `void clearModRepoCache()` that deletes `mod_repo.json` and `mod_repo.meta` from the cache dir, swallowing missing-file errors
- [x] 1.6 Add public top-level `DateTime? getModRepoCacheTimestamp()` that reads `mod_repo.meta` and returns the `cachedAt` timestamp, or null if missing/corrupt
- [x] 1.7 Verify `dart analyze` is clean in `lib/catalog/mod_browser_manager.dart`

## 2. Overflow menu on the catalog page

- [x] 2.1 Import `PopupStyleMenuAnchor` and `MovingTooltipWidget` in `lib/catalog/mod_browser_page.dart` if not already imported
- [x] 2.2 Add a `buildCatalogOverflowButton()` method on `_CatalogPageState` following the `mods_grid_page.dart:1185` `buildOverflowButton` shape: `MovingTooltipWidget.text(message: "More options") → PopupStyleMenuAnchor → IconButton(Icons.more_vert)`
- [x] 2.3 Wire the first menu entry to open the dialog: a `MenuItemButton` with `leadingIcon: PopupStyleMenuAnchor.paddedIcon(Icon(Icons.storage))` and label "Data sources…"
- [x] 2.4 Insert the overflow button into the top row of the filter card (see `mod_browser_page.dart` ~line 406), positioned after the search box, respecting the 8.0 dip alignment grid
- [x] 2.5 Add a trailing `Divider()` after the Data sources item to leave room for future menu items, matching the Mods page layout

## 3. Catalog Data Sources dialog

- [x] 3.1 Create `lib/catalog/catalog_data_sources_dialog.dart` with a `CatalogDataSourcesDialog` widget (`ConsumerStatefulWidget`) and a `showCatalogDataSourcesDialog(BuildContext)` helper that wraps `showDialog`
- [x] 3.2 Dialog chrome: `AlertDialog` (or `Dialog` + custom title) with title "Catalog Data Sources", a vertically scrolling body, and a footer with "Open cache folder" and "Close" buttons
- [x] 3.3 Body: a `Column` with two `_DataSourceCard` widgets stacked, using `spacing: 8.0`
- [x] 3.4 Build `_DataSourceCard(title, subtitle, statusState, itemCount, cachedAt, ttl, sizeBytes, sourceUrl, localPath, onRefresh, onClear, isLoading, isCleared)` — a private widget in the same file
- [x] 3.5 Card header row: title + subtitle (small caption-style) on the left, status dot + status label on the right
- [x] 3.6 Card body row: `"N items • Cached Xm ago (TTL Yh) • Z.Z MB"` using the 8.0 dip grid
- [x] 3.7 Source URL row: `SelectableText` with a trailing copy-to-clipboard `IconButton` with tooltip "Copy URL"
- [x] 3.8 Local path row: `SelectableText`, wrappable/truncatable
- [x] 3.9 Action row, right-aligned: `TextButton.icon` "Refresh now" (icon `Icons.refresh`) and `TextButton.icon` "Clear cache" (icon `Icons.delete_outline`). Both foregrounds drawn from `colorScheme.onSurfaceVariant`; NEVER `colorScheme.error`
- [x] 3.10 Refresh button's `onPressed` is null while the corresponding `isLoading` is true; tooltip mentions "disabled while loading" in that state
- [x] 3.11 Status dot: 10×10 dot `Container` with `BoxDecoration(shape: BoxShape.circle)`, color by state — grey (no cache), `colorScheme.primary` (loading), success color (loaded), `colorScheme.error` (error). Error color is allowed HERE because the dot is a small directional indicator, not a destructive action.
- [x] 3.12 Wire the Wisp's Mod Repo card to `browseModsNotifierProvider`, `isLoadingCatalog`, `getModRepoCacheTimestamp()`, `forceRefreshModRepo()`, `clearModRepoCache()`, and `Constants.modRepoUrl`. After refresh or clear, call `ref.invalidate(browseModsNotifierProvider)`
- [x] 3.13 Wire the QB's Forum Bundle card to `forumDataProvider`, `isLoadingForumData`, `getForumDataCacheTimestamp()`, `forceRefreshForumData()`, `clearForumDataCache()`, and `Constants.forumDataBundleUrl`. After refresh or clear, call `ref.invalidate(forumDataProvider)`
- [x] 3.14 File size helper: `int? _fileSize(String path)` returning `File(path).statSync().size` or null. Format with the existing TriOS byte-formatting utility if one is present under `lib/utils/`; otherwise inline a `_formatBytes(int bytes)` helper
- [x] 3.15 Item count: read from the `AsyncValue.value` of the corresponding provider — `items.length` for mod repo, `index.length` for forum bundle. Display "—" if `null`
- [x] 3.16 Footer "Open cache folder" button opens `Constants.cacheDirPath` using the existing file-explorer-opening utility (grep for existing usages to find the helper)
- [x] 3.17 Every new icon has a tooltip: copy-URL, refresh, clear, open-folder (per project convention)

## 4. Polish & verification

- [ ] 4.1 Verify the overflow button sits on the 8.0 dip grid and doesn't shift the search box
- [ ] 4.2 Verify the dialog renders correctly at narrow widths — cards wrap gracefully, paths don't overflow
- [ ] 4.3 Cold-start test: delete both cache files, open dialog, confirm "Not cached" state + size "—" + disabled clear buttons
- [ ] 4.4 Cached test: populate both files, open dialog, confirm timestamps/sizes/counts are correct
- [ ] 4.5 Refresh test: click Refresh on each card, confirm button disables during fetch, re-enables after, and timestamps update
- [ ] 4.6 Clear test: click Clear on each card, confirm files are removed from disk and the card state updates to "Not cached"
- [ ] 4.7 Error test: break the URL (temporarily), confirm error state surfaces on the dot and the card still renders
- [x] 4.8 `dart analyze lib/catalog/` is clean (only pre-existing warnings remain; no new issues introduced)
