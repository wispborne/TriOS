import 'package:flutter/material.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation.dart';
import 'package:trios/widgets/download_progress_indicator.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Matches the padding used by InProgressActivityTile.
const _activityRowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 6);

/// Shows a single batch entry (queued, scanning, or extracting) as a row
/// in the activity panel.
class BatchEntryTile extends StatelessWidget {
  final BatchEntry entry;

  const BatchEntryTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExtracting = entry.status == BatchEntryStatus.extracting;
    final progress = entry.progressDisplay;

    final IconData statusIcon = switch (entry.status) {
      BatchEntryStatus.extracting => Icons.install_desktop,
      BatchEntryStatus.scanning => Icons.search,
      _ => Icons.schedule,
    };

    final String statusText = switch (entry.status) {
      BatchEntryStatus.scanning => 'Scanning...',
      BatchEntryStatus.extracting =>
        entry.extractionPhase != null
            ? '${entry.extractionPhase}...'
            : 'Installing...',
      _ => 'Queued',
    };

    return Padding(
      padding: _activityRowPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: 8,
            children: [
              MovingTooltipWidget.text(
                message: statusText,
                child: Icon(statusIcon, size: 20, color: theme.iconTheme.color),
              ),
              Expanded(
                child: Text(
                  entry.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // A progress bar only while actively installing; anything earlier
          // (queued, scanning) has nothing to show but its status line.
          if (isExtracting && progress != null)
            Padding(
              padding: .only(top: 6),
              child: TriOSDownloadProgressIndicator(value: progress),
            )
          else
            Padding(
              padding: .only(top: 4),
              child: Text(
                statusText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
