import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/activity_panel/activity_item_tile.dart';
import 'package:trios/trios/activity_panel/activity_panel_controller.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloads = ref.watch(downloadManager).value ?? [];
    final history = ref.watch(activityHistoryStore).value?.entries ?? [];

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
    final hasInProgress = inProgress.isNotEmpty;
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
            padding: .fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Text('Activity', style: theme.textTheme.titleSmall),
                const Spacer(),
                if (hasHistory)
                  MovingTooltipWidget.text(
                    message: "Permanently clears history",
                    child: TextButton.icon(
                      onPressed: () => ref
                          .read(activityHistoryStore.notifier)
                          .clearHistory(),
                      label: const Text('Clear'),
                      icon: const Icon(Icons.clear_all),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
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
          const Divider(height: 1),
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
                        Padding(
                          padding: .symmetric(horizontal: 16, vertical: 4),
                          child: Text(
                            'In Progress',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        for (final download in inProgress)
                          InProgressActivityTile(download: download),
                        if (hasHistory) const Divider(height: 16),
                      ],
                      // Completed section.
                      if (hasHistory) ...[
                        Padding(
                          padding: .symmetric(horizontal: 16, vertical: 4),
                          child: Text(
                            'Recent',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        for (final entry in history)
                          CompletedActivityTile(entry: entry),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
