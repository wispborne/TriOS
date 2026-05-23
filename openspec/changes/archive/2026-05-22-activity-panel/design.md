# Activity Panel — Design

## Data Model

### ActivityEntry (new, persisted)

A lightweight snapshot created when a download or install completes (or fails).

```
ActivityEntry (@MappableClass, persisted to disk)
├── id: String (UUID)
├── modName: String
├── modVersion: String?
├── sourceType: ActivitySourceType (download | archive)
├── sourceDetail: String? (URL or file path)
├── timestamp: DateTime
├── status: ActivityStatus (completed | failed)
├── errorMessage: String? (if failed)
└── modIconPath: String? (for display)
```

`ActivitySourceType` and `ActivityStatus` are `@MappableEnum`s.

Persisted as JSON list in the app config data folder. FIFO eviction at 100 entries.

### ActivityPanelController (new Riverpod Notifier)

Manages panel state and the history list.

```
ActivityPanelController (Notifier<ActivityPanelState>)

State:
├── isOpen: bool
├── unseenCount: int (completions since last open)
└── history: List<ActivityEntry> (persisted)

Methods:
├── toggle() — opens/closes panel, clears unseenCount on open
├── recordCompletion(ActivityEntry) — adds to history, increments unseenCount if panel closed
├── clearHistory() — removes only completed/failed entries from history
└── load() / save() — disk persistence
```

This controller does NOT own in-progress items. Those come from the existing `TriOSDownloadManager` provider, which already tracks live `Download` objects with progress via `ValueNotifier`.

## Panel Layout

```
┌─────────────────────────────────────────────────────────────┐
│ Top Toolbar                                     [📥•] [...] │
├──────────────────────────────────────────┬──────────────────┤
│                                          │ Activity Panel   │
│ Content area (Expanded)                  │ (fixed ~320px)   │
│                                          │                  │
│ LazyIndexedStack                         │ ┌──────────────┐ │
│ (pages)                                  │ │ In-Progress  │ │
│                                          │ │  Mod X ██░   │ │
│                                          │ │  Mod Y ███░  │ │
│                                          │ ├──────────────┤ │
│                                          │ │ Completed    │ │
│                                          │ │  ✓ Mod Z     │ │
│                                          │ │  ✓ Mod W     │ │
│                                          │ │  ✗ Mod Q     │ │
│                                          │ ├──────────────┤ │
│                                          │ │ [Clear]      │ │
│                                          │ └──────────────┘ │
└──────────────────────────────────────────┴──────────────────┘
```

The panel slots into `_buildBody` in `AppShell`. The existing `DragDropHandler > Column > Expanded > Stack` structure becomes a `Row` at the `Expanded` level:

```dart
Expanded(
  child: Row(
    children: [
      Expanded(
        child: Stack(
          children: [
            LazyIndexedStack(...),
            // Toasts stay here, but only for self-update / companion mod
          ],
        ),
      ),
      if (activityPanelOpen)
        ActivityPanel(width: 320),
    ],
  ),
)
```

Both sidebar-layout and top-toolbar-layout share `_buildBody`, so the panel works identically in both.

## Toolbar Icon

New widget: `ActivityIconButton`. Placed in `CompactTopBar` and `FullTopBar` alongside existing action buttons.

Visual states:
- **Idle**: plain download icon
- **In-progress**: circular progress indicator wrapping the icon, showing aggregate progress of all active downloads/installs
- **Unseen completions**: badge count (number overlaid on icon, Edge-style)
- **Both**: progress ring + badge

The icon watches:
- `TriOSDownloadManager` for in-progress items and aggregate progress
- `ActivityPanelController` for `unseenCount` and `isOpen`

## Toast Migration

### What moves to the panel
- `ModDownloadToast` — individual download progress/completion
- `ModDownloadGroupToast` — grouped downloads
- Archive install progress (currently shown via `addInstallation()` path)

### What stays as toasts
- `SelfUpdateToast` — app self-update notification
- `CompanionModUpdateToast` — companion mod version warning

### Changes to ToastDisplayer
- Remove the download-listening logic (the `ref.listen(downloadManager, ...)` block and grouping logic)
- Keep the `ref.listen(AppState.modVariants, ...)` for "mod added" detection, but instead of showing a toast, call `ActivityPanelController.recordCompletion()`
- Keep companion mod toast logic

## Key Decisions

1. **Panel in `_buildBody`, not per-layout** — avoids duplicating panel logic across sidebar and top-toolbar layouts.
2. **History is separate from live downloads** — `ActivityEntry` is a lightweight data class; `Download` objects are heavyweight with streams and notifiers. The panel merges both for display but they have different lifecycles.
3. **Unseen count clears on open** — matches Edge behavior. Opening the panel = "I've seen everything."
4. **No animation on panel open/close** — keep it simple. Can add `AnimatedContainer` later if desired.

## New Files

| File | Purpose |
|------|---------|
| `lib/trios/activity_panel/activity_entry.dart` | `ActivityEntry`, `ActivitySourceType`, `ActivityStatus` models |
| `lib/trios/activity_panel/activity_panel_controller.dart` | Riverpod notifier for panel state + history |
| `lib/trios/activity_panel/activity_panel.dart` | Panel widget |
| `lib/trios/activity_panel/activity_item_tile.dart` | Individual item row (both in-progress and completed) |
| `lib/toolbar/activity_icon_button.dart` | Toolbar icon with progress ring and badge |

## Modified Files

| File | Change |
|------|--------|
| `lib/app_shell.dart` | Add `ActivityPanel` to `_buildBody` row |
| `lib/toolbar/compact_top_bar.dart` | Add `ActivityIconButton` |
| `lib/toolbar/full_top_bar.dart` | Add `ActivityIconButton` |
| `lib/trios/toasts/toast_manager.dart` | Remove download toast logic, route completions to `ActivityPanelController` |
| `lib/trios/settings/settings.dart` | Add `isActivityPanelOpen` to persisted settings |
