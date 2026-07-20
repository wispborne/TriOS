import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/activity_panel/activity_entry.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';

const int _maxHistoryEntries = 100;

/// Persisted activity history (completed/failed installs and downloads).
final activityHistoryStore =
    AsyncNotifierProvider<ActivityHistoryStore, ActivityHistory>(
      ActivityHistoryStore.new,
    );

class ActivityHistoryStore
    extends GenericSettingsAsyncNotifier<ActivityHistory> {
  @override
  GenericAsyncSettingsManager<ActivityHistory> createSettingsManager() =>
      _ActivityHistoryManager();

  @override
  ActivityHistory createDefaultState() => const ActivityHistory();

  /// Adds an entry to the history, evicting the oldest if over the cap.
  Future<void> recordCompletion(ActivityEntry entry) async {
    await updateState((current) {
      final updated = List<ActivityEntry>.of(current.entries)..insert(0, entry);
      // FIFO eviction.
      if (updated.length > _maxHistoryEntries) {
        updated.removeRange(_maxHistoryEntries, updated.length);
      }
      return ActivityHistory(entries: updated);
    });

    // When a mod finishes installing while the panel is closed, surface it in a
    // transient popup below the activity button so the user can Enable it
    // without opening the panel.
    if (entry.status == ActivityStatus.completed) {
      final isOpen = ref.read(appSettings.select((s) => s.isActivityPanelOpen));
      if (!isOpen) {
        ref.read(recentInstallPopupProvider.notifier).add(entry);
      }
    }
  }

  /// Removes a single entry by id.
  Future<void> removeEntry(String id) async {
    await updateState((current) {
      final updated = current.entries.where((e) => e.id != id).toList();
      return ActivityHistory(entries: updated);
    });
  }

  /// Removes all completed/failed entries from history.
  Future<void> clearHistory() async {
    await updateState((_) => const ActivityHistory());
  }
}

class _ActivityHistoryManager
    extends GenericAsyncSettingsManager<ActivityHistory> {
  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => 'trios_activity_history-v1.${fileFormat.name}';

  @override
  ActivityHistory Function(Map<String, dynamic> map) get fromMap =>
      (json) => ActivityHistoryMapper.fromMap(json);

  @override
  Map<String, dynamic> Function(ActivityHistory) get toMap =>
      (state) => state.toMap();
}

/// Ephemeral count of completions the user hasn't seen yet.
/// Clears when the panel is opened.
final activityUnseenCount =
    NotifierProvider<ActivityUnseenCountNotifier, int>(
      ActivityUnseenCountNotifier.new,
    );

class ActivityUnseenCountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state = state + 1;

  /// Called when the user opens the panel.
  void clearUnseen() => state = 0;
}

/// Mods that finished installing while the Activity Panel was closed.
/// Surfaced in a transient popup below the activity button so the user can
/// Enable them without opening the panel. Cleared when the popup times out or
/// the panel is opened.
final recentInstallPopupProvider =
    NotifierProvider<RecentInstallPopupNotifier, List<ActivityEntry>>(
      RecentInstallPopupNotifier.new,
    );

class RecentInstallPopupNotifier extends Notifier<List<ActivityEntry>> {
  @override
  List<ActivityEntry> build() => const [];

  void add(ActivityEntry entry) => state = [...state, entry];

  void remove(ActivityEntry entry) =>
      state = state.where((e) => e.id != entry.id).toList();

  void clear() => state = const [];
}

/// Counts downloads and installs that started while the Activity Panel was
/// closed. Any value above zero makes the popup below the activity button
/// appear so the user knows something began in the background. Each new one
/// bumps the count, which restarts the popup's countdown. Cleared when the
/// popup times out or the panel is opened.
final activityStartedPopupProvider =
    NotifierProvider<ActivityStartedPopupNotifier, int>(
      ActivityStartedPopupNotifier.new,
    );

class ActivityStartedPopupNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void notifyStarted() => state = state + 1;

  void clear() => state = 0;
}

/// Convenience: toggle panel open state (persisted in Settings).
void toggleActivityPanel(WidgetRef ref) {
  final wasOpen = ref.read(
    appSettings.select((s) => s.isActivityPanelOpen),
  );
  ref
      .read(appSettings.notifier)
      .update((s) => s.copyWith(isActivityPanelOpen: !wasOpen));
  if (!wasOpen) {
    // Opening the panel clears unseen count and dismisses the install popup.
    ref.read(activityUnseenCount.notifier).clearUnseen();
    ref.read(recentInstallPopupProvider.notifier).clear();
    ref.read(activityStartedPopupProvider.notifier).clear();
  }
}
