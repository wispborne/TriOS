class NotificationGroupConfig {
  final String groupId;
  final Duration initialGroupingWindow;
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
