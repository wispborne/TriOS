import 'package:uuid/uuid.dart';

import '../download_manager/download_manager.dart';
import '../download_manager/download_status.dart';
import 'notification_group_config.dart';

class NotificationGroup<T> {
  final String id;
  final NotificationGroupType type;
  final NotificationGroupConfig config;
  final List<T> items;
  final DateTime createdAt;
  DateTime lastAddedAt;
  bool isExpanded;

  NotificationGroup({
    required this.id,
    required this.type,
    required this.config,
    required this.items,
  })  : createdAt = DateTime.now(),
        lastAddedAt = DateTime.now(),
        isExpanded = config.autoExpand;

  bool isActive() {
    // Group is active if any item is still in progress
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
    // Check based on item type
    if (items.isEmpty) return true;

    // For Download items
    if (items.first is Download) {
      return (items as List<Download>).every((download) {
        final status = download.task.status.value;
        return status == DownloadStatus.completed ||
            status == DownloadStatus.failed ||
            status == DownloadStatus.canceled;
      });
    }

    // For other types, assume completed
    return false;
  }

  int get completedCount {
    if (items.isEmpty) return 0;

    // For Download items
    if (items.first is Download) {
      return (items as List<Download>).where((download) {
        final status = download.task.status.value;
        return status == DownloadStatus.completed ||
            status == DownloadStatus.failed ||
            status == DownloadStatus.canceled;
      }).length;
    }

    return 0;
  }

  int get failedCount {
    if (items.isEmpty) return 0;

    // For Download items
    if (items.first is Download) {
      return (items as List<Download>).where((download) {
        return download.task.status.value == DownloadStatus.failed;
      }).length;
    }

    return 0;
  }
}

class NotificationGroupManager {
  final Map<NotificationGroupType, NotificationGroup?> _activeGroups = {};
  final Map<String, String> _itemToGroupMap = {};

  /// Attempts to add item to existing group or creates new group
  /// Returns group ID if item was added to active group, null if starting new group
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

  void clear() {
    _activeGroups.clear();
    _itemToGroupMap.clear();
  }
}
