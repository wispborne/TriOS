import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/themes/theme.dart';
import 'package:trios/trios/activity_panel/activity_panel_controller.dart';
import 'package:trios/trios/constants_theme.dart' show TriOSThemeConstants;
import 'package:trios/trios/download_manager/download_manager.dart';
import 'package:trios/trios/download_manager/download_status.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/rainbow/themed_progress_indicator.dart';

/// Toolbar icon that toggles the Activity Panel.
///
/// Shows a circular progress ring when downloads/installs are in progress,
/// and an Edge-style badge count of unseen completions.
class ActivityIconButton extends ConsumerWidget {
  const ActivityIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadManager).value ?? [];
    final unseenCount = ref.watch(activityUnseenCount);
    final isOpen = ref.watch(appSettings.select((s) => s.isActivityPanelOpen));

    final inProgress = downloads.where((d) {
      final status = d.task.status.value;
      if (status == DownloadStatus.failed ||
          status == DownloadStatus.canceled) {
        return false;
      }
      return !status.isCompleted ||
          (!d.installComplete.value && !d.installCancelled.value);
    }).toList();

    return MovingTooltipWidget.text(
      message: 'Activity',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (inProgress.isNotEmpty || unseenCount > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _AggregateProgressRing(
                downloads: inProgress,
                allComplete: inProgress.isEmpty && unseenCount > 0,
              ),
            ),
          IconButton(
            icon: Icon(Icons.file_download, size: 18),
            onPressed: () => toggleActivityPanel(ref),
            style: IconButton.styleFrom(
              minimumSize: const Size(20, 20),
              shape: RoundedRectangleBorder(
                borderRadius: .circular(TriOSThemeConstants.cornerRadius),
              ),
              padding: .all(4),
              backgroundColor: isOpen
                  ? Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.08)
                  : null,
            ),
          ),
          // Badge count (unseen completions).
          if (unseenCount > 0)
            Positioned(right: -2, top: -2, child: _Badge(count: unseenCount)),
        ],
      ),
    );
  }
}

class _AggregateProgressRing extends StatefulWidget {
  final List<Download> downloads;
  final bool allComplete;

  const _AggregateProgressRing({
    required this.downloads,
    this.allComplete = false,
  });

  @override
  State<_AggregateProgressRing> createState() => _AggregateProgressRingState();
}

class _AggregateProgressRingState extends State<_AggregateProgressRing> {
  @override
  void initState() {
    super.initState();
    _addListeners(widget.downloads);
  }

  @override
  void didUpdateWidget(_AggregateProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _removeListeners(oldWidget.downloads);
    _addListeners(widget.downloads);
  }

  @override
  void dispose() {
    _removeListeners(widget.downloads);
    super.dispose();
  }

  void _addListeners(List<Download> downloads) {
    for (final d in downloads) {
      d.task.downloaded.addListener(_onProgress);
      d.installProgress.addListener(_onProgress);
    }
  }

  void _removeListeners(List<Download> downloads) {
    for (final d in downloads) {
      d.task.downloaded.removeListener(_onProgress);
      d.installProgress.removeListener(_onProgress);
    }
  }

  void _onProgress() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final double? value;

    if (widget.allComplete) {
      value = 1.0;
    } else {
      int totalReceived = 0;
      int totalBytes = 0;

      for (final d in widget.downloads) {
        final status = d.task.status.value;
        if (!status.isCompleted) {
          final dl = d.task.downloaded.value;
          totalReceived += dl.bytesReceived;
          totalBytes += dl.totalBytes;
        } else {
          final ip = d.installProgress.value;
          if (ip != null && !ip.isIndeterminate) {
            totalReceived += ip.bytesReceived;
            totalBytes += ip.bytesTotal;
          }
        }
      }

      value = totalBytes > 0 ? totalReceived / totalBytes : null;
    }

    return SizedBox(
      height: 4,
      child: ThemedLinearProgressIndicator(value: value, alpha: 200),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: .symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
