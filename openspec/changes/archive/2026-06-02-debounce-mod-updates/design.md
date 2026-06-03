# Design: Prevent Duplicate Mod Update Downloads & Allow Cancellation

## Approach

Three parts: duplicate prevention in the download manager, disabled buttons in the UI, and a cancel button in the Activity Panel.

### 1. Download Manager — `isDownloadInProgress(String url)`

Add a method to `TriOSDownloadManager` that checks whether any in-progress `Download` with the same URL exists.

A download is "in progress" if:
- Its `DownloadTask.status` is not `completed`, `failed`, or `canceled`, OR
- Its `installComplete.value` is `false` (download finished but install is still running)

Both `downloadUpdateViaBrowser()` and `downloadAndInstallMod()` will early-return if this check is true.

URL is always available on every download and naturally maps to variant identity — same mod version = same download URL, different versions = different URLs. No new fields needed on `Download`.

### 2. Download Manager — `cancelDownload(Download)`

Add a method that:
- If the download task status is not yet completed: calls `Downloader.cancelDownload(url)` to cancel the HTTP request and remove it from the queue
- If the download is in the install phase: calls the existing `cancelInstallation(download)`
- Either way, removes the download from `_downloads` and invalidates state

The low-level `Downloader.cancelDownload(url)` already exists and sets status to `canceled` + removes from queue.

### 3. UI — Disable update buttons during active downloads

Each of the three update trigger sites will watch the download manager state and disable the button/icon when a download with the same URL is already active. The URL is available from `remoteVersion.directDownloadURL` at each call site.

The download manager already calls `ref.invalidateSelf()` on status changes, so any widget doing `ref.watch(downloadManager)` will rebuild automatically when a download starts or finishes.

### 4. UI — Cancel button on `InProgressActivityTile`

Add a close/cancel icon button to the top-right of each in-progress download entry in the Activity Panel. On tap, call `ref.read(downloadManager.notifier).cancelDownload(download)`.

The tile is currently a `StatelessWidget` — it will need to become a `ConsumerWidget` (or accept a callback) to access the provider.

### Key Decision: Keying by URL

Downloads are keyed by URL. Each mod version has a distinct download URL, so this naturally deduplicates at the variant level — same variant = same URL, different versions = different URLs. No extra fields needed on `Download` since the URL is already on `DownloadTask.request.url`.

### Files Changed

| File | Change |
|------|--------|
| `lib/trios/download_manager/download_manager.dart` | Add `isDownloadInProgress(String url)` and `cancelDownload(Download)`. Guard `downloadAndInstallMod` and `downloadUpdateViaBrowser`. |
| `lib/trios/activity_panel/activity_item_tile.dart` | Add cancel button to `InProgressActivityTile`. Convert to `ConsumerWidget` or pass cancel callback. |
| `lib/mod_manager/mod_info_dialog.dart` | Watch download state, disable "Update" button when download is active for that mod. |
| `lib/mod_manager/mods_grid_page.dart` | Watch download state, disable version check icon when download is active. |
| `lib/dashboard/mod_list_basic_entry.dart` | Watch download state, disable version check icon when download is active. |
