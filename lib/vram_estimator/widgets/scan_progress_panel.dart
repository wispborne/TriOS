import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/relative_timestamp.dart';
import 'package:trios/vram_estimator/vram_estimator_manager.dart';
import 'package:trios/widgets/disable.dart';

/// Inline panel shown above the VRAM chart. While a scan is running it
/// displays live progress; when idle it collapses to a single-line
/// summary of the last scan's results.
class ScanProgressPanel extends ConsumerWidget {
  const ScanProgressPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vramStateProvider = ref.watch(AppState.vramEstimatorProvider);
    if (vramStateProvider.isLoading) return const SizedBox.shrink();
    final state = vramStateProvider.requireValue;
    if (!state.isScanning) return _IdleSummary(state: state);

    final done = state.modsScannedThisRun;
    final total = state.totalModsToScan;
    final current = state.currentlyScanningModName;
    final theme = Theme.of(context);
    final hasTotal = total > 0;
    final fraction = hasTotal ? (done / total).clamp(0.0, 1.0) : null;
    final percentText = fraction != null
        ? '${(fraction * 100).toStringAsFixed(0)}%'
        : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Disable(
                  isEnabled: !state.isCancelled,
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(AppState.vramEstimatorProvider.notifier)
                        .cancelEstimation(),
                    icon: const Icon(Icons.stop, size: 16),
                    label: Text(state.isCancelled ? 'Cancelling…' : 'Cancel'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
            // Primary line: current mod
            Row(
              children: [
                Text(
                  'Currently scanning: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Expanded(
                  child: Text(
                    (current == null || current.isEmpty)
                        ? 'preparing…'
                        : current,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Secondary line: overall progress count
            Row(
              children: [
                Text(
                  'Overall: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  hasTotal
                      ? '$done of $total mods  ($percentText)'
                      : '$done mods',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleSummary extends StatelessWidget {
  const _IdleSummary({required this.state});

  final VramEstimatorManagerState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    final mods = state.modVramInfo.values;
    final modCount = mods.length;
    final totalBytes = mods.fold<int>(
      0,
      (sum, mod) => sum + mod.bytesNotIncludingGraphicsLib(),
    );
    final lastUpdated = state.lastUpdated;

    final children = <Widget>[
      Icon(
        Icons.history,
        size: 16,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      Text('Last scan:', style: mutedStyle),
    ];

    if (lastUpdated == null || modCount == 0) {
      children.add(Text('never', style: valueStyle));
    } else {
      children.addAll([
        Text(lastUpdated.relativeTimestamp(), style: valueStyle),
        Text('•', style: mutedStyle),
        Text('$modCount mods', style: valueStyle),
        Text('•', style: mutedStyle),
        Text(totalBytes.bytesAsReadableMB(), style: valueStyle),
      ]);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(spacing: 8, children: children),
      ),
    );
  }
}
