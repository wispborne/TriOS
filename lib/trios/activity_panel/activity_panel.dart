import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation_notifier.dart';
import 'package:trios/trios/activity_panel/activity_entry.dart';
import 'package:trios/trios/activity_panel/activity_item_tile.dart';
import 'package:trios/trios/activity_panel/activity_panel_controller.dart';
import 'package:trios/trios/activity_panel/batch_activity_tile.dart';
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/download_status.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/widgets/moving_tooltip.dart';

const double defaultActivityPanelWidth = 320;
const double minActivityPanelWidth = 230;
const double maxActivityPanelWidth = 400;

/// Persistent side panel showing mod download/install activity.
class ActivityPanel extends ConsumerStatefulWidget {
  const ActivityPanel({super.key});

  @override
  ConsumerState<ActivityPanel> createState() => _ActivityPanelState();
}

class _ActivityPanelState extends ConsumerState<ActivityPanel> {
  /// Refreshes relative timestamps ("5 seconds ago" → "1 minute ago").
  Timer? _timestampTimer;

  /// Which date groups are currently collapsed.
  final Set<String> _collapsedGroups = {};

  @override
  void initState() {
    super.initState();
    _timestampTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timestampTimer?.cancel();
    super.dispose();
  }

  /// Section label with a hairline rule beneath it.
  Widget _sectionHeader(String label, ThemeData theme) {
    return Padding(
      padding: .fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Groups history entries by date label, preserving insertion order.
  List<(String label, List<ActivityEntry> entries)> _groupByDate(
    List<ActivityEntry> entries,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final dateFormat = DateFormat.MMMd();

    String labelFor(DateTime ts) {
      final date = DateTime(ts.year, ts.month, ts.day);
      if (date == today) return 'Today';
      if (date == yesterday) return 'Yesterday';
      if (date.year != today.year) return DateFormat.yMMMd().format(ts);
      return dateFormat.format(ts);
    }

    return groupBy(entries, (e) => labelFor(e.timestamp))
        .entries
        .map((e) => (e.key, e.value))
        .toList();
  }

  Widget _dateGroupHeader(String label, bool isCollapsed, ThemeData theme) {
    return InkWell(
      onTap: () => setState(() {
        isCollapsed
            ? _collapsedGroups.remove(label)
            : _collapsedGroups.add(label);
      }),
      child: Padding(
        padding: .fromLTRB(8, 4, 16, 0),
        child: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Icon(
                isCollapsed
                    ? Icons.keyboard_arrow_right
                    : Icons.keyboard_arrow_down,
                size: 14,
              ),
            ),
            Padding(
              padding: .only(left: 2, right: 8),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: theme.colorScheme.outlineVariant,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Asks for confirmation before permanently clearing activity history.
  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Activity?'),
        content: const Text(
          'This permanently clears the installation activity history. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            label: const Text('Clear All'),
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(activityHistoryStore.notifier).clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloads = ref.watch(downloadManager).value ?? [];
    final history = ref.watch(activityHistoryStore).value?.entries ?? [];
    final batch = ref.watch(batchInstallationProvider);

    // Batch entries that are still in flight (queued, scanning, or extracting),
    // in their original order. Completed/failed/skipped entries move to the
    // "Recent" history instead. Entries with a Download are already shown as
    // a download tile, so exclude them to avoid a duplicate row.
    final activeBatchEntries =
        batch?.entries
            .where(
              (e) =>
                  e.download == null &&
                  (e.status == BatchEntryStatus.queued ||
                  e.status == BatchEntryStatus.scanning ||
                  e.status == BatchEntryStatus.scanned ||
                  e.status == BatchEntryStatus.extracting),
            )
            .toList() ??
        const [];

    // Split downloads into in-progress vs done.
    // A download is "done" if:
    //  - it failed or was canceled (install never starts), OR
    //  - install completed or was cancelled by the user.
    final inProgress = downloads.where((d) {
      final status = d.task.status.value;
      if (status == DownloadStatus.failed ||
          status == DownloadStatus.canceled) {
        return false;
      }
      final installDone = d.installComplete.value || d.installCancelled.value;
      return !status.isCompleted || !installDone;
    }).toList();

    final hasHistory = history.isNotEmpty;
    final hasInProgress = inProgress.isNotEmpty || activeBatchEntries.isNotEmpty;
    final isPinned =
        ref.watch(appSettings.select((s) => s.activityPanelMode)) ==
        ActivityPanelMode.pinned;

    return Container(
      width: ref.watch(appSettings.select((s) => s.activityPanelWidth)),
      clipBehavior: isPinned ? Clip.none : Clip.antiAlias,
      decoration: BoxDecoration(
        border: isPinned
            ? Border(
                left: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                ),
              )
            : Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
        borderRadius: isPinned ? null : BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: Column(
        children: [
          // Header.
          Padding(
            padding: .fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Text(
                  'Installation Activity',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                MovingTooltipWidget.text(
                  message: isPinned ? 'Unpin (overlay)' : 'Pin (side panel)',
                  child: IconButton(
                    icon: Icon(
                      isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 18,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      ref
                          .read(appSettings.notifier)
                          .update(
                            (s) => s.copyWith(
                              activityPanelMode: isPinned
                                  ? ActivityPanelMode.overlay
                                  : ActivityPanelMode.pinned,
                            ),
                          );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Body.
          Expanded(
            child: (!hasInProgress && !hasHistory)
                ? Center(
                    child: Text(
                      'No activity yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView(
                    padding: .symmetric(vertical: 8),
                    children: [
                      // In-progress section.
                      if (hasInProgress) ...[
                        _sectionHeader('In Progress', theme),
                        for (final (i, entry)
                            in activeBatchEntries.indexed) ...[
                          if (i > 0) const SizedBox(height: 8),
                          BatchEntryTile(
                            key: ValueKey(entry.id),
                            entry: entry,
                          ),
                        ],
                        if (activeBatchEntries.isNotEmpty &&
                            inProgress.isNotEmpty)
                          const SizedBox(height: 8),
                        for (final (i, download) in inProgress.indexed) ...[
                          if (i > 0) const SizedBox(height: 8),
                          InProgressActivityTile(
                            download: download,
                            onCancel: () => ref
                                .read(downloadManager.notifier)
                                .cancelDownload(download),
                          ),
                        ],
                        if (hasHistory) const SizedBox(height: 8),
                      ],
                      // Completed section, grouped by date.
                      if (hasHistory)
                        for (final (label, groupEntries)
                            in _groupByDate(history)) ...[
                          _dateGroupHeader(
                            label,
                            _collapsedGroups.contains(label),
                            theme,
                          ),
                          if (!_collapsedGroups.contains(label))
                            for (final (i, entry) in groupEntries.indexed) ...[
                              if (i > 0) const SizedBox(height: 8),
                              CompletedActivityTile(entry: entry),
                            ],
                        ],
                    ],
                  ),
          ),
          // Bottom action strip.
          if (hasHistory)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Padding(
                padding: .symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    const Spacer(),
                    MovingTooltipWidget.text(
                      message: "Permanently clears history",
                      child: TextButton.icon(
                        onPressed: () => _confirmClearHistory(context),
                        label: const Text('Clear All'),
                        icon: const Icon(Icons.clear_all),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
