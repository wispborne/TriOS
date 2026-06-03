# Tasks: Prevent Duplicate Mod Update Downloads & Allow Cancellation

## Download Manager

- [x] Add `isDownloadInProgress(String url)` to `TriOSDownloadManager` — returns true if any `Download` with that URL has an incomplete download or install
- [x] Add `cancelDownload(Download download)` to `TriOSDownloadManager` — cancels download via `Downloader.cancelDownload(url)` or install via `cancelInstallation()`, then removes from list
- [x] Guard `downloadAndInstallMod()` — early-return if `isDownloadInProgress` is true for the given URL
- [x] Guard `downloadUpdateViaBrowser()` — early-return if in progress for the given URL

## Activity Panel: Cancel Button

- [x] Add a cancel icon button to `InProgressActivityTile` — shown on the trailing side of the name row, calls `cancelDownload()` on the download manager
- [x] Convert `InProgressActivityTile` to `ConsumerWidget` (or pass an `onCancel` callback) so it can access the download manager provider

## UI: Disable Buttons During Active Downloads

- [x] `mod_info_dialog.dart` — disable the "Update" `FilledButton.tonalIcon` when a download is in progress for that URL
- [x] `mods_grid_page.dart` — disable the version check `InkWell` when a download is in progress for that URL
- [x] `mod_list_basic_entry.dart` — disable the version check `InkWell` when a download is in progress for that URL
