# Notification Grouping Implementation Plan

## Problem Statement
When users install or update many mods simultaneously, each mod triggers its own toast notification, causing notification spam. This creates a poor UX with dozens of toasts appearing on screen.

## Solution Overview
Implement notification grouping that combines similar notifications (same type/operation) into a single grouped toast that displays aggregate information and individual progress.

---

## Current System Analysis

### Toast Types to Group
1. **Mod Download Toasts** (`ModDownloadToast`) - Most critical for grouping
   - Triggered when mods are downloaded/installed
   - Shows progress, status, and actions per mod

2. **Mod Added Toasts** (`ModAddedToast`) - Secondary priority
   - Triggered when mod variants are added to mods folder
   - Shows mod info and enable actions

3. **Self-Update/Post-Update** - No grouping needed (single events)

### Key Files
- `lib/trios/toasts/toast_manager.dart` - Toast orchestration
- `lib/trios/toasts/widgets/mod_download_toast.dart` - Individual download toast
- `lib/trios/toasts/widgets/mod_added_toast.dart` - Individual added toast
- `lib/trios/download_manager/download_manager.dart` - Download state management

---

## Design Decisions

### Grouping Strategy
**Active group-based grouping**: Keep adding new notifications to an active group as long as any items in that group are still in progress (downloading, queued, etc.)

**How it works:**
- When first download starts → create a group (but don't show yet, wait for more)
- Any new downloads within initial window (e.g., 2 seconds) → add to group
- Once 2+ items in group → show the grouped toast
- Group stays "active" as long as ANY download in the group is not completed
- New downloads while group is active → automatically join the active group
- Group "closes" only when ALL items have completed (success or failure)
- After group closes, new downloads start a fresh group

**Why this approach:**
- Handles batch downloads that start simultaneously
- Also handles "add a few more while downloading" scenario naturally
- User sees one continuous group for their download session
- Intuitive: the group represents "current download operation"
- Simple to implement: just check if any items are still active

### Group Configuration
Groups will be **code-configurable** with these properties:

```dart
class NotificationGroupConfig {
  final String groupId;                    // Unique identifier (e.g., "mod_downloads")
  final Duration initialGroupingWindow;    // Initial window to wait for more items before showing group
  final int minItemsToGroup;               // Minimum items before grouping (e.g., 2)
  final int maxItemsToShow;                // Max individual items to display before summarizing
  final bool autoExpand;                   // Whether to start expanded or collapsed
  final Duration? autoCollapseAfter;       // Auto-collapse after all complete
  // Note: No "max window" - group stays active as long as any item is in progress
}
```

### Groupable Notification Types
```dart
enum NotificationGroupType {
  modDownloads,      // Group mod downloads/installations
  modAdded,          // Group mod added notifications
  // Future: modUpdates, modErrors, etc.
}
```

---

## Implementation Plan

### Phase 1: Core Infrastructure

#### 1.1 Create Group Configuration System
**File:** `lib/trios/toasts/notification_group_config.dart`

```dart
class NotificationGroupConfig {
  final String groupId;
  final Duration initialGroupingWindow;  // Initial wait period for batch items
  final int minItemsToGroup;
  final int maxItemsToShow;
  final bool autoExpand;
  final Duration? autoCollapseAfter;

  const NotificationGroupConfig({
    required this.groupId,
    this.initialGroupingWindow = const Duration(seconds: 2),
    this.minItemsToGroup = 2,
    this.maxItemsToShow = 5,
    this.autoExpand = false,
    this.autoCollapseAfter,
  });
}

enum NotificationGroupType {
  modDownloads,
  modAdded,
}

// Default configurations
class NotificationGroupConfigs {
  static const modDownloads = NotificationGroupConfig(
    groupId: 'mod_downloads',
    initialGroupingWindow: Duration(seconds: 2),
    minItemsToGroup: 2,
    maxItemsToShow: 5,
    autoExpand: true,
    autoCollapseAfter: Duration(seconds: 3),
  );

  static const modAdded = NotificationGroupConfig(
    groupId: 'mod_added',
    initialGroupingWindow: Duration(seconds: 3),
    minItemsToGroup: 2,
    maxItemsToShow: 5,
    autoExpand: false,
    autoCollapseAfter: Duration(seconds: 5),
  );
}
```

#### 1.2 Create Group State Management
**File:** `lib/trios/toasts/notification_group_manager.dart`

```dart
class NotificationGroup<T> {
  final String id;                          // UUID for this group instance
  final NotificationGroupType type;
  final NotificationGroupConfig config;
  final List<T> items;                      // Generic to support Download, ModVariant, etc.
  final DateTime createdAt;
  DateTime lastAddedAt;
  bool isExpanded;

  NotificationGroup({
    required this.id,
    required this.type,
    required this.config,
    required this.items,
  }) : createdAt = DateTime.now(),
       lastAddedAt = DateTime.now(),
       isExpanded = config.autoExpand;

  bool isActive() {
    // Group is active if any item is still in progress
    // Override this based on item type (e.g., check download status)
    return !allItemsCompleted();
  }

  void addItem(T item) {
    items.add(item);
    lastAddedAt = DateTime.now();
  }

  bool shouldGroup() {
    return items.length >= config.minItemsToGroup;
  }

  bool allItemsCompleted() {
    // To be implemented based on item type
    // For downloads: check if all have completed/failed/canceled status
    return false;
  }
}

class NotificationGroupManager {
  final Map<NotificationGroupType, NotificationGroup?> _activeGroups = {};
  final Map<String, String> _itemToGroupMap = {};  // Track which items belong to which group

  /// Attempts to add item to existing group or creates new group
  /// Returns group ID if item was added to group, null if should wait/show individually
  String? tryGroupItem<T>(
    NotificationGroupType type,
    NotificationGroupConfig config,
    T item,
    String itemId,
  ) {
    final activeGroup = _activeGroups[type];

    // If there's an active group (still has items in progress), add to it
    if (activeGroup != null && activeGroup.isActive()) {
      activeGroup.addItem(item);
      _itemToGroupMap[itemId] = activeGroup.id;
      return activeGroup.id;
    }

    // No active group - start a new one
    // Previous group was completed and closed, or this is the first item
    final newGroup = NotificationGroup<T>(
      id: const Uuid().v4(),
      type: type,
      config: config,
      items: [item],
    );
    _activeGroups[type] = newGroup;
    _itemToGroupMap[itemId] = newGroup.id;

    // Return null to indicate "wait for initial grouping window"
    // The toast manager will wait before showing to see if more items arrive
    return null;
  }

  NotificationGroup? getGroup(NotificationGroupType type) {
    return _activeGroups[type];
  }

  void closeGroup(NotificationGroupType type) {
    _activeGroups.remove(type);
  }

  bool isItemGrouped(String itemId) {
    return _itemToGroupMap.containsKey(itemId);
  }

  String? getGroupIdForItem(String itemId) {
    return _itemToGroupMap[itemId];
  }
}
```

### Phase 2: Group UI Components

#### 2.1 Create Grouped Download Toast Widget
**File:** `lib/trios/toasts/widgets/mod_download_group_toast.dart`

**Features:**
- Header showing "Downloading X mods" with aggregate progress (e.g., "3/5 complete")
- Expand/collapse button
- When expanded: List of individual mod download items (reuse ModDownloadToast internals)
- When collapsed: Show overall progress bar or summary
- Action buttons: "Open Folder" (opens mods folder)
- Auto-collapse after all downloads complete (configurable delay)

**Design System Integration:**
- Use existing `Card` with `Container` padding pattern (same as ModDownloadToast)
- Use `ThemeManager.cornerRadius` (6.0) for border radius
- Apply same box shadow: `BoxShadow(color: Colors.black26, blurRadius: 4.0, offset: Offset(0, 2))`
- Use `Theme.of(context).colorScheme.surface` for background
- Use `palette.createPaletteTheme(context)` for dynamic theming (generate from first mod icon)
- Match padding: outer `EdgeInsets.only(top: 4, right: 32)`, inner `EdgeInsets.all(16.0)` for header
- Use same icon size (40px) and status icons as ModDownloadToast
- Reuse `TriOSDownloadProgressIndicator` for individual progress bars
- Use same close button: `CircularProgressIndicator` + `IconButton` stack pattern
- Text styles: `theme.textTheme.bodyMedium` for titles, `theme.textTheme.labelMedium` for details
- Use `ThemeManager.vanillaErrorColor` for errors
- Use `theme.colorScheme.secondary` for success states
- Button style: `ElevatedButton.icon` matching existing toasts

**UI Structure:**
```
┌─────────────────────────────────────────────────┐
│ 📦 Downloading 5 mods (3 complete)         [▼]  │
├─────────────────────────────────────────────────┤
│ [=============================>      ] 62%      │
├─────────────────────────────────────────────────┤
│ [Expanded view - shown when ▼ clicked]          │
│                                                  │
│  ├─ LazyLib v2.7                                │
│  │  [==================>    ] 76% Downloading   │
│  │  [Open] [Enable]                             │
│  │                                              │
│  ├─ GraphicsLib v1.6.0                          │
│  │  [====================] ✓ Completed          │
│  │  [Open] [Enable]                             │
│  │                                              │
│  ├─ MagicLib v1.0.0                             │
│  │  [====================] ✓ Completed          │
│  │  ...                                         │
│                                                  │
│  [+2 more]  (if maxItemsToShow exceeded)        │
└─────────────────────────────────────────────────┘
```

**Key Implementation Notes:**
- Reuse existing `ModDownloadToast` internals for individual items
- Use `ValueListenableBuilder` to watch all downloads' status changes
- Calculate aggregate progress: `completed / total`
- Use `ListView` or `Column` for expanded items list
- Implement smooth expand/collapse animation

#### 2.2 Create Grouped Mod Added Toast Widget
**File:** `lib/trios/toasts/widgets/mod_added_group_toast.dart`

**Features:**
- Header showing "X new mods added"
- Expand/collapse button
- When expanded: List of added mods with enable buttons
- When collapsed: Just show count
- Auto-dismiss after configurable delay

**Design System Integration:**
- Match all styling from ModAddedToast and mod_download_group_toast
- Use mod icons (40x40) if available, fallback to `TriOSAppIcon()`
- Generate palette from first mod icon with `palette.createPaletteTheme(context)`
- Same Card/Container/padding structure
- Same text styles and button patterns
- Show "Currently enabled" version info when applicable

**UI Structure:**
```
┌─────────────────────────────────────────────────┐
│ ✨ 3 new mods added                        [▼]  │
├─────────────────────────────────────────────────┤
│ [Expanded view]                                  │
│                                                  │
│  • Console Commands v2023.12.04                 │
│    [Open] [Enable]                               │
│                                                  │
│  • SpeedUp v2.3.2                               │
│    [Open] [Enable]                               │
│                                                  │
│  • Starship Legends v2.0.1                      │
│    [Open] [Enable]                               │
└─────────────────────────────────────────────────┘
```

### Phase 3: Integration with Toast Manager

#### 3.1 Modify ToastDisplayer
**File:** `lib/trios/toasts/toast_manager.dart`

**Changes needed:**

1. Add `NotificationGroupManager` instance
2. Modify download toast creation logic:
   ```dart
   // OLD: Create individual toast for each download
   downloads
       .whereNot((item) => _downloadToastIdsCreated.contains(item.id))
       .forEach((download) { ... });

   // NEW: Check grouping logic first
   final ungroupedDownloads = downloads
       .whereNot((item) => _downloadToastIdsCreated.contains(item.id))
       .whereNot((item) => _groupManager.isItemGrouped(item.id))
       .toList();

   // Try to group new downloads
   for (final download in ungroupedDownloads) {
     final groupId = _groupManager.tryGroupItem(
       NotificationGroupType.modDownloads,
       NotificationGroupConfigs.modDownloads,
       download,
       download.id,
     );

     if (groupId != null) {
       // Item was grouped, mark as created to prevent individual toast
       _downloadToastIdsCreated.add(download.id);
     }
   }

   // Show group toast if group should be displayed
   final group = _groupManager.getGroup(NotificationGroupType.modDownloads);
   if (group != null && group.shouldGroup() && !_groupToastIdsCreated.contains(group.id)) {
     _showGroupedDownloadToast(group);
     _groupToastIdsCreated.add(group.id);
   }

   // Show individual toasts for ungrouped items
   final stillUngrouped = ungroupedDownloads
       .whereNot((item) => _groupManager.isItemGrouped(item.id));
   for (final download in stillUngrouped) {
     _showIndividualDownloadToast(download);
   }
   ```

3. Similar changes for mod added notifications

4. Add tracking set for group toast IDs:
   ```dart
   final _groupToastIdsCreated = <String>{};  // Track shown group toasts
   ```

5. Add timer logic to check if grouping window has passed:
   ```dart
   Timer? _groupCheckTimer;

   void _scheduleGroupCheck(Duration delay) {
     _groupCheckTimer?.cancel();
     _groupCheckTimer = Timer(delay, () {
       // Check if any groups are ready to be shown
       _checkAndShowPendingGroups();
     });
   }
   ```

### Phase 4: Polish & Configuration

#### 4.1 Settings Integration (Optional)
If we want user-configurable grouping:

**File:** `lib/models/prefs.dart`

```dart
// Add settings:
bool get enableNotificationGrouping => /* default true */;
int get notificationGroupingWindowSeconds => /* default 2 */;
int get notificationMinItemsToGroup => /* default 2 */;
```

#### 4.2 Testing Scenarios
1. **Single download** - Should show individual toast after initial window expires (no grouping)
2. **Multiple rapid downloads** - Should group into single toast
3. **Staggered downloads during active session** - User downloads 5 mods, then 30 seconds later downloads 3 more while first batch is still downloading - all 8 should be in same group
4. **New downloads after group completes** - All downloads complete, then user downloads more - should start a new group
5. **Group expansion** - Expand/collapse works smoothly
6. **Progress tracking** - All downloads update in real-time within group
7. **Completion handling** - Group auto-collapses or dismisses after all complete
8. **Action buttons** - "Enable" and "Open" work for items in group
9. **Very large groups** - Handles 10+ mods gracefully (show summary, scrolling, etc.)
10. **Late arrivals** - Group is shown with 3 items, user adds 2 more - they join the existing visible group

---

## Implementation Order

### Iteration 1: Foundation (Most Important)
1. Create `NotificationGroupConfig` class with default configs
2. Create `NotificationGroup` and `NotificationGroupManager` classes
3. Basic unit tests for grouping logic

### Iteration 2: UI (Most Visible)
1. Create `ModDownloadGroupToast` widget
2. Implement expand/collapse functionality
3. Display aggregate progress
4. Reuse individual download display logic

### Iteration 3: Integration (Connect Everything)
1. Modify `ToastDisplayer` to use `NotificationGroupManager`
2. Add grouping logic for downloads
3. Add timer-based group finalization
4. Test with multiple simultaneous downloads

### Iteration 4: Mod Added Grouping (Secondary Priority)
1. Create `ModAddedGroupToast` widget
2. Add grouping logic for mod added notifications
3. Test with multiple mod additions

### Iteration 5: Polish (Nice to Have)
1. Add animations (expand/collapse, progress updates)
2. Add optional user settings
3. Performance optimization for large groups
4. Accessibility improvements

---

## Edge Cases to Handle

1. **Single item initially, more arrive later within initial window**
   - Solution: Use timer to wait for initial grouping window before showing toast. If only 1 item after window, show individual toast.

2. **Single item, more arrive later AFTER group is shown**
   - Solution: If group is active (still downloading), new items join the visible group. UI updates to show new count.

3. **Downloads complete at different times**
   - Solution: Keep group toast visible until all complete, then auto-dismiss

4. **User manually closes group toast while downloads ongoing**
   - Solution: Mark group as dismissed, don't show individual toasts for those items

5. **Download fails in a group**
   - Solution: Show error state in group, highlight failed item. Failure counts as "completed" for group closing logic.

6. **Very slow download + fast downloads**
   - Solution: Group should stay open as long as any download is active

7. **User clicks "Enable" on grouped item**
   - Solution: Action applies to that specific item, update UI state

8. **Group with 100+ mods**
   - Solution: Implement virtual scrolling or pagination, show "X more items"

---

## Success Metrics

1. **User Experience**
   - Reduce screen clutter when downloading multiple mods
   - Maintain visibility of download progress
   - Quick access to individual mod actions

2. **Performance**
   - No noticeable lag when grouping 50+ downloads
   - Smooth animations
   - Minimal memory overhead

3. **Flexibility**
   - Easy to add new notification types to grouping system
   - Configurable grouping behavior per notification type
   - Optional user settings for power users

---

## Future Enhancements

1. **Smart Grouping**
   - Group by mod author/source
   - Group by operation type (install vs update)

2. **Bulk Actions**
   - "Enable all" button for grouped mods
   - "Cancel all" for grouped downloads

3. **Persistent Groups**
   - Save group state across app restarts
   - Show download history in groups

4. **Notification Center**
   - Permanent list of all notifications/groups
   - Searchable history

5. **Priority System**
   - Important notifications bypass grouping
   - User-prioritized mods show individually

---

## Technical Considerations

### Performance
- Use `ValueListenableBuilder` for efficient updates (already in use)
- Lazy-load individual items in large groups
- Debounce group checks to avoid excessive rebuilds

### State Management
- Group state should be local to `ToastDisplayer` (no need for Riverpod provider)
- Individual download state already managed by `DownloadManager`

### Animation
- Use Flutter's built-in `AnimatedSize` or `AnimatedContainer`
- Smooth expand/collapse with curve (e.g., `Curves.easeInOut`)
- Stagger animations for individual items appearing

### Accessibility
- Announce group creation to screen readers
- Individual items should be focusable when expanded
- Keyboard navigation for expand/collapse

---

## Open Questions

1. **Should grouping be always-on or optional?**
   - Recommendation: Always-on with configurable threshold (default: 2+ items)

2. **Should groups auto-expand or start collapsed?**
   - Recommendation: Configurable per group type
   - Mod downloads: Auto-expand (users want to see progress)
   - Mod added: Start collapsed (less critical)

3. **How long should group toast stay after all complete?**
   - Recommendation: Configurable, default 3-5 seconds

4. **Should we show group toast immediately or wait for grouping window?**
   - Recommendation: Wait for window (better UX, prevents "flashing" single toast then group)

5. **Maximum items to display in expanded group?**
   - Recommendation: Show first 5-10, then "Show X more" button or scrolling

---

## Summary

This plan implements a flexible, code-configurable notification grouping system that:
- **Prevents spam** by combining similar notifications
- **Maintains visibility** with expandable groups showing progress
- **Preserves functionality** by keeping individual mod actions accessible
- **Scales gracefully** from 2 to 100+ grouped items
- **Extends easily** to new notification types in the future
- **Groups intelligently** - keeps the group active as long as any downloads are in progress, allowing late additions to join naturally

**Key behavior:**
- Initial grouping window (2 seconds) determines if items should be grouped
- Once a group exists and is active (has ongoing downloads), ALL new downloads join that group automatically
- Group only closes when ALL items have completed (success/failure/canceled)
- After group closes, new downloads start a fresh group

The implementation prioritizes mod download grouping (highest impact) while building infrastructure that supports all notification types.