### Requirement: Overflow menu on the catalog page

The catalog page SHALL display an overflow button (`Icons.more_vert`) in its filter toolbar, positioned adjacent to the search box. The button SHALL open a menu using the same `PopupStyleMenuAnchor` pattern as the Mod Manager page overflow menu. The menu SHALL be structured to support additional items being added in future changes.

#### Scenario: User opens the overflow menu
- **WHEN** the user clicks the overflow button on the catalog page
- **THEN** a popup menu opens, containing at minimum a "Data sources…" item with a leading storage icon

#### Scenario: Overflow button has a tooltip
- **WHEN** the user hovers the overflow button
- **THEN** a "More options" tooltip is shown

### Requirement: Catalog Data Sources dialog

The system SHALL provide a dialog titled "Catalog Data Sources" that shows three stacked cards, one per catalog file:

- `mod-catalog.json`, cached as `mod_catalog.json`
- `mod-catalog-details.json`, cached as `mod_catalog_details.json`
- `mod-catalog-extras.json`, cached as `mod_catalog_extras.json`

Every card SHALL link to `https://github.com/wispborne/StarsectorModRepo`. No card SHALL name QB or link to QB's repository. The card titles and subtitles are the signed-off text in this change's `design.md`.

Each card SHALL display:
- load status with a colored status dot
- parsed item count
- cached-at timestamp with age and how long the file is kept
- file size on disk
- source URL, with a copy-to-clipboard button
- local cache path
- a "Refresh now" action and a "Clear cache" action

The dialog SHALL provide an "Open cache folder" footer action and a "Close" button.

#### Scenario: Dialog opens with every file cached
- **WHEN** all three cache files are present and their providers have emitted
- **THEN** each card shows "Loaded", the parsed item count, the cached-at timestamp with age, the file size, source URL, local path, and enabled refresh/clear buttons

#### Scenario: Dialog opens with no cache
- **WHEN** no cache file exists
- **THEN** each card shows "Not cached", size "—", the clear button is disabled, and the refresh button is enabled

#### Scenario: User force-refreshes a data source
- **WHEN** the user clicks "Refresh now" on a card
- **THEN** the system fetches that file again, skipping the cache age, and invalidates its provider. The refresh button is disabled until the fetch completes

#### Scenario: User clears a cached data source
- **WHEN** the user clicks "Clear cache" on a card
- **THEN** that file's `.json` and `.meta` files are deleted from the cache directory, and its provider is invalidated so the next read fetches again

#### Scenario: Clear cache with missing files does not crash
- **WHEN** the user clicks "Clear cache" on a card whose files are already absent
- **THEN** the operation completes without throwing and the card state reflects "Not cached"

#### Scenario: Destructive buttons use neutral coloring
- **WHEN** the "Clear cache" and "Refresh now" buttons are rendered on a card
- **THEN** their foreground color is drawn from `colorScheme.onSurfaceVariant` (or `onSurface`), NOT from `colorScheme.error`

#### Scenario: Every new icon has a tooltip
- **WHEN** the user hovers any icon-only button in the dialog (copy URL, refresh, clear, open folder)
- **THEN** a tooltip explains the button's purpose

### Requirement: Parity API on `catalog_manager`

Each catalog file SHALL be loaded through one shared `CachedJsonFetcher` (`lib/utils/cached_json_fetcher.dart`). The Data Sources dialog SHALL use that fetcher's `fetch(bypassCache: true)`, `clearCache()`, `getCacheTimestamp()` and `cacheFilePath`, rather than separate helper functions per file.

When a fetch fails and a cached copy exists, whatever its age, the fetcher SHALL return the cached copy and log a warning rather than throw.

#### Scenario: Refresh bypasses a fresh cache
- **WHEN** `fetch(bypassCache: true)` is called while the cached file is newer than its keep time
- **THEN** the fetcher makes a network request and overwrites both cache files

#### Scenario: Clear with missing files
- **WHEN** `clearCache()` is called and neither cache file exists
- **THEN** the call completes without throwing

#### Scenario: Timestamp with missing meta
- **WHEN** the `.meta` file does not exist or is corrupt
- **THEN** `getCacheTimestamp()` returns null without throwing

#### Scenario: Fetch failure falls back to stale cache
- **WHEN** a fetch fails (network error) but a cached copy exists
- **THEN** the fetcher returns the cached copy and logs a warning
