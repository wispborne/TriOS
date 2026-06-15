# Proposal: Prevent Duplicate Mod Update Downloads & Allow Cancellation

## Problem

Two related issues with mod update downloads:

1. **Duplicate downloads**: Users can click mod update buttons repeatedly, queuing multiple downloads of the same mod simultaneously. There are three trigger points: the "Update" button in the mod info dialog, the version check icon in the mods grid, and the version check icon in the dashboard mod list. The low-level `Downloader` cache doesn't prevent this because `TriOSDownloadManager.addDownload()` wraps each call in a new temp folder and UUID.

2. **No way to cancel**: Once a download starts, the user has no way to stop it. The Activity Panel shows in-progress downloads as read-only — no cancel button. The backend already has `cancelDownload(url)` and `cancelInstallation(download)` methods, but they're not exposed in the UI.

## Proposed Solution

**Duplicate prevention**: Track in-progress downloads by URL in `TriOSDownloadManager`. Early-return if a download with the same URL is already active. Disable update buttons in the UI during active downloads. Downloading different versions of the same mod is allowed (different URLs); only the exact same variant is blocked (same URL).

**Cancel button**: Add a cancel/stop button to in-progress download entries in the Activity Panel. This calls the existing `cancelDownload` on the downloader (for downloads) or `cancelInstallation` (for installs).

## Scope

- Add URL-level duplicate detection in `TriOSDownloadManager`
- Disable update buttons/icons during active downloads in all three UI locations
- Add cancel button to `InProgressActivityTile` in the Activity Panel
- Expose a `cancelDownload(Download)` method on `TriOSDownloadManager` that wires through to the downloader

## Non-goals

- Changing the download queue or concurrency model
- Adding a general-purpose download deduplication layer
- Changing behavior when a previous download has completed or failed (re-downloading should still work)
- Pause/resume functionality
