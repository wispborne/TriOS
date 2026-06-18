# Batch Mod Installation

## Problem

When a user installs many mods at once (common when setting up a new mod list), TriOS processes each archive sequentially with a full mod-list reload after every single one. 100 mods means ~100 full disk scans, potential dialog popups per archive, and 100 individual activity panel tiles. The experience is slow, noisy, and hard to monitor.

## Proposed Solution

Introduce a `BatchInstallation` system that groups multiple archives into a single operation with:

1. **Pre-scan phase** — Quickly list and parse `mod_info.json` from all archives in parallel before extracting anything. Catches corrupt/invalid archives early.
2. **Confirmation dialog** — One dialog for the whole batch showing what will be installed, what conflicts exist, and what's invalid. Batch-level conflict policy (skip/replace) with per-mod overrides.
3. **Parallel extraction** — Extract N archives concurrently (default 2, configurable 1-6 in settings).
4. **Single mod-list reload** — One incremental `reloadModVariants()` call at the end instead of one per mod.
5. **Batch activity tile** — One collapsible tile in the activity panel showing overall progress, individual mod statuses, and a "Cancel Remaining" button.

## Dialog rules

| Batch size | Problems? | Show dialog? |
|------------|-----------|-------------|
| 1 | No | No |
| 1 | Yes (conflict, multi-mod archive) | Yes |
| 2+ | Any | Always |

## Entry points

Both the file picker (`AddNewModsButton`) and drag-and-drop (`DragDropHandler`) feed into the same batch system. Dropped URLs download first via `DownloadManager`, then join the batch as local files when ready.

## Migration plan

This change introduces `BatchInstallation` as a new provider alongside the existing `DownloadManager`. Phase 1 (this work) handles multi-mod local installs. The long-term goal is to migrate all installations (single local, URL-based) through the batch system, leaving `DownloadManager` responsible only for HTTP downloads.

| Phase | Scope |
|-------|-------|
| 1 (this work) | Multi-mod local installs use batch. Single local + URL installs keep old path. |
| 2 (future) | Single local installs route through batch-of-1 (dialog skipped). |
| 3 (future) | URL download completions feed into batch. |
| 4 (future) | Strip installation-tracking from `Download`. One system. |

## Non-goals

- Changing how URL downloads work (phase 3+).
- Mod dependency resolution or load-order management.
- Changing the extraction engine (7z) itself.
- Parallel extraction within a single archive (7z already handles that internally).
