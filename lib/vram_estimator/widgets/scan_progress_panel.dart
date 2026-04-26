import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/relative_timestamp.dart';
import 'package:trios/vram_estimator/graphics_lib_config_provider.dart';
import 'package:trios/vram_estimator/models/active_mod_scan.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/vram_checker_logic.dart';
import 'package:trios/vram_estimator/vram_estimator_manager.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/moving_tooltip.dart';

/// Inline panel shown above the VRAM chart. While a scan is running it
/// displays live progress; when idle it collapses to a single-line
/// summary of the last scan's results.
class ScanProgressPanel extends ConsumerStatefulWidget {
  const ScanProgressPanel({super.key});

  @override
  ConsumerState<ScanProgressPanel> createState() => _ScanProgressPanelState();
}

class _ScanProgressPanelState extends ConsumerState<ScanProgressPanel> {
  // Persistent controller shared between the Scrollbar and the ListView
  // so the Scrollbar can find a ScrollPosition when there are enough
  // active scans to scroll.
  final ScrollController _activeScansController = ScrollController();

  @override
  void dispose() {
    _activeScansController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vramStateProvider = ref.watch(AppState.vramEstimatorProvider);
    if (vramStateProvider.isLoading) return const SizedBox.shrink();
    final state = vramStateProvider.requireValue;

    if (!state.isScanning) return _IdleSummary(state: state);

    final done = state.modsScannedThisRun;
    final total = state.totalModsToScan;
    final theme = Theme.of(context);
    final hasTotal = total > 0;
    final fraction = hasTotal ? (done / total).clamp(0.0, 1.0) : null;
    final percentText = fraction != null
        ? '${(fraction * 100).toStringAsFixed(0)}%'
        : '';

    // Collect every active scan. Sort: actively-reading-files first
    // (so the user sees the "live" rows up top), then mods that have
    // started but are still in selector / parse prep. Alphabetical
    // within each group keeps the list stable as workers complete.
    final activeScans = state.activeScans.values.toList()
      ..sort((a, b) {
        final aActive = a.totalFiles > 0;
        final bActive = b.totalFiles > 0;
        if (aActive != bActive) return aActive ? -1 : 1;
        return a.modName.toLowerCase().compareTo(b.modName.toLowerCase());
      });
    // Fallback for the brief window before the first onModStart fires
    // (or for the legacy single-mod path while activeScans is still
    // populating). Lets the user see *something* instead of an empty list.
    final fallbackName = activeScans.isEmpty
        ? state.currentlyScanningModName
        : null;

    return Card(
      margin: .zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Progress  •  ${activeScans.length} scan${activeScans.length == 1 ? '' : 's'} active',
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
            // Per-mod live rows. One row per scan currently in flight;
            // multiple rows under the multithreaded path. Capped + scrollable
            // so a long list (e.g. a freshly-submitted batch) never pushes
            // the rest of the page off-screen.
            if (activeScans.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Scrollbar(
                  controller: _activeScansController,
                  thumbVisibility: activeScans.length > 4,
                  child: ListView.builder(
                    controller: _activeScansController,
                    shrinkWrap: true,
                    itemCount: activeScans.length,
                    itemBuilder: (context, i) =>
                        _ActiveScanRow(scan: activeScans[i], theme: theme),
                  ),
                ),
              )
            else if (fallbackName != null && fallbackName.isNotEmpty)
              _ActiveScanRow(
                scan: ActiveModScan(modName: fallbackName),
                theme: theme,
              )
            else
              Text(
                'preparing…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            // Overall progress count + bar
            Row(
              children: [
                Text(
                  'Overall: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  hasTotal
                      ? '$done of $total mods  ($percentText)'
                      : '$done mods',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
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

/// One row of per-mod progress: name, file counter, file path, and a
/// thin per-mod progress bar. Renders compactly so several rows stack
/// without dwarfing the rest of the page.
class _ActiveScanRow extends StatelessWidget {
  const _ActiveScanRow({required this.scan, required this.theme});

  final ActiveModScan scan;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final hasFileProgress = scan.totalFiles > 0;
    final fileFraction = hasFileProgress
        ? (scan.filesScanned / scan.totalFiles).clamp(0.0, 1.0)
        : null;
    final filePercentText = fileFraction != null
        ? '${(fileFraction * 100).toStringAsFixed(0)}%'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  scan.modName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                hasFileProgress
                    ? '${scan.filesScanned} / ${scan.totalFiles}  ($filePercentText)'
                    : 'preparing…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: hasFileProgress
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ],
          ),
          if (scan.currentFilePath != null && scan.currentFilePath!.isNotEmpty)
            Text(
              scan.currentFilePath!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontFamily: 'Roboto Mono',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          // Always show a thin progress bar — determinate while reading
          // image headers, indeterminate during the selector / parse prelude
          // so the user can see the worker is doing CPU work even before
          // the file counter starts ticking.
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: hasFileProgress ? fileFraction : null,
                minHeight: 2,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleSummary extends ConsumerWidget {
  const _IdleSummary({required this.state});

  final VramEstimatorManagerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    final vramMap = state.modVramInfo;
    final modCount = vramMap.length;
    final lastUpdated = state.lastUpdated;
    final lastScanDurationMs = state.lastScanDurationMs;

    final lastScanRow = <Widget>[
      Icon(
        Icons.history,
        size: 16,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      Text('Last scan:', style: mutedStyle),
    ];

    if (lastUpdated == null || modCount == 0) {
      lastScanRow.add(Text('never', style: valueStyle));
    } else {
      lastScanRow.addAll([
        Tooltip(
          message: lastUpdated.relativeTimestamp(),
          child: Text(
            Constants.dateTimeFormat.format(lastUpdated),
            style: valueStyle,
          ),
        ),
        Text('•', style: mutedStyle),
        Text('$modCount mods', style: valueStyle),
        if (lastScanDurationMs != null) ...[
          Text('•', style: mutedStyle),
          Text(
            'took ${_formatScanDuration(Duration(milliseconds: lastScanDurationMs))}',
            style: valueStyle,
          ),
        ],
      ]);
    }

    final neverScanned = lastUpdated == null || modCount == 0;
    final mods = neverScanned ? const <Mod>[] : ref.watch(AppState.mods);
    final gfxConfig = neverScanned
        ? null
        : ref.watch(graphicsLibConfigProvider);

    final cohorts = neverScanned
        ? const <_CohortSummary>[]
        : <_CohortSummary>[
            _buildCohort(
              label: 'Enabled',
              mods: mods.where((m) => m.isEnabledOnUi).toList(),
              vramMap: vramMap,
              gfxConfig: gfxConfig,
            ),
            _buildCohort(
              label: 'Disabled',
              mods: mods.where((m) => !m.isEnabledOnUi).toList(),
              vramMap: vramMap,
              gfxConfig: gfxConfig,
            ),
            _buildCohort(
              label: 'All mods',
              mods: mods,
              vramMap: vramMap,
              gfxConfig: gfxConfig,
            ),
          ];

    return Card(
      margin: .zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(spacing: 8, mainAxisSize: .min, children: lastScanRow),
            if (cohorts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Estimated VRAM if launched now',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              for (final c in cohorts)
                _CohortRow(
                  cohort: c,
                  gfxConfig: gfxConfig,
                  mutedStyle: mutedStyle,
                  valueStyle: valueStyle,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatScanDuration(Duration d) {
  if (d.inMinutes >= 1) {
    final seconds = d.inSeconds % 60;
    return '${d.inMinutes}m ${seconds}s';
  }
  if (d.inSeconds >= 10) return '${d.inSeconds}s';
  // Sub-10s: show one decimal so a fast scan doesn't read as "1s".
  return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
}

/// Aggregated VRAM totals for a named cohort of mods.
class _CohortSummary {
  final String label;
  final int totalMods;
  final int scannedCount;
  final int modsBytes;
  final int modsImageCount;
  final int gfxBytes;
  final int gfxImageCount;
  final bool isApproxGfx;
  final int vanillaBytes;

  _CohortSummary({
    required this.label,
    required this.totalMods,
    required this.scannedCount,
    required this.modsBytes,
    required this.modsImageCount,
    required this.gfxBytes,
    required this.gfxImageCount,
    required this.isApproxGfx,
    required this.vanillaBytes,
  });

  int get unscannedCount => totalMods - scannedCount;

  int get totalBytes => modsBytes + gfxBytes + vanillaBytes;

  bool get hasNoMods => totalMods == 0;

  bool get hasNoScans => totalMods > 0 && scannedCount == 0;

  bool get hasData => scannedCount > 0;
}

_CohortSummary _buildCohort({
  required String label,
  required List<Mod> mods,
  required Map<String, VramMod> vramMap,
  required GraphicsLibConfig? gfxConfig,
}) {
  final variants = mods
      .map((m) => m.findFirstEnabledOrHighestVersion)
      .nonNulls
      .toList();
  final estimates = variants.map((v) => vramMap[v.smolId]).nonNulls.toList();

  final modsBytes = estimates
      .map((e) => e.imagesNotIncludingGraphicsLib().sum())
      .sum;
  final modsImageCount = estimates
      .map((e) => e.imagesNotIncludingGraphicsLib().length)
      .sum;

  final preloadAll = gfxConfig?.preloadAllMaps == true;
  int gfxBytes;
  int gfxImageCount;
  bool isApproxGfx;
  if (preloadAll) {
    final gfxBytesList = estimates
        .expand(
          (mod) => List.generate(
            mod.images.length,
            (i) => ModImageView(i, mod.images),
          ),
        )
        .where(
          (view) =>
              view.graphicsLibType != null &&
              view.isUsedBasedOnGraphicsLibConfig(gfxConfig),
        )
        .map((view) => view.bytesUsed)
        .toList();
    gfxBytes = gfxBytesList.sum();
    gfxImageCount = gfxBytesList.length;
    isApproxGfx = false;
  } else if (gfxConfig != null && gfxConfig.areAnyEffectsEnabled) {
    // Same heuristic as _vramSummaryOverlayWidget when preloadAllMaps=false.
    gfxBytes = 200000000;
    gfxImageCount = 0;
    isApproxGfx = true;
  } else {
    gfxBytes = 0;
    gfxImageCount = 0;
    isApproxGfx = false;
  }

  return _CohortSummary(
    label: label,
    totalMods: mods.length,
    scannedCount: estimates.length,
    modsBytes: modsBytes.toInt(),
    modsImageCount: modsImageCount.toInt(),
    gfxBytes: gfxBytes,
    gfxImageCount: gfxImageCount,
    isApproxGfx: isApproxGfx,
    vanillaBytes: VramChecker.VANILLA_GAME_VRAM_USAGE_IN_BYTES.toInt(),
  );
}

class _CohortRow extends StatelessWidget {
  final _CohortSummary cohort;
  final GraphicsLibConfig? gfxConfig;
  final TextStyle? mutedStyle;
  final TextStyle? valueStyle;

  const _CohortRow({
    required this.cohort,
    required this.gfxConfig,
    required this.mutedStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final approxStyle = valueStyle?.copyWith(
      fontStyle: FontStyle.italic,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
    );

    final hasScannedAllMods = cohort.hasData && cohort.unscannedCount == 0;
    Widget valueText;
    String? hideReason;

    if (!hasScannedAllMods) {
      valueText = Text(
        "(${cohort.unscannedCount} unscanned)",
        style: approxStyle,
      );
      hideReason = "Scan all ${cohort.label} mods to see totals";
    } else if (cohort.hasNoMods) {
      valueText = Text('— none', style: approxStyle);
      hideReason = 'No mods?';
    } else if (cohort.hasNoScans) {
      valueText = Text(
        '— not scanned (${cohort.totalMods} mods)',
        style: approxStyle,
      );
      hideReason =
          "These ${cohort.totalMods} mods haven't been scanned yet, so their VRAM usage is unknown. Run a scan to see a total.";
    } else {
      valueText = Text(
        cohort.totalBytes.bytesAsReadableMB(),
        style: valueStyle,
      );
    }

    final countSuffix = hasScannedAllMods ? '(${cohort.totalMods} mods)' : null;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        const SizedBox(width: 8),
        SizedBox(width: 64, child: Text(cohort.label, style: mutedStyle)),
        valueText,
        if (countSuffix != null) Text(countSuffix, style: mutedStyle),
      ],
    );

    final wrapped = hideReason != null
        ? MovingTooltipWidget.text(message: hideReason, child: row)
        : MovingTooltipWidget.framed(
            tooltipWidget: _CohortBreakdownTooltip(
              cohort: cohort,
              gfxConfig: gfxConfig,
            ),
            child: row,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Align(alignment: Alignment.centerLeft, child: wrapped),
    );
  }
}

class _CohortBreakdownTooltip extends StatelessWidget {
  final _CohortSummary cohort;
  final GraphicsLibConfig? gfxConfig;

  const _CohortBreakdownTooltip({
    required this.cohort,
    required this.gfxConfig,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = <String>[];
    lines.add(
      '${cohort.modsBytes.bytesAsReadableMB()} added by mods '
      '(${cohort.modsImageCount} images)',
    );
    if (cohort.gfxBytes > 0) {
      final detail = cohort.isApproxGfx
          ? 'roughly'
          : '${cohort.gfxImageCount} images';
      lines.add(
        '${cohort.gfxBytes.bytesAsReadableMB()} added by your '
        'GraphicsLib settings ($detail)',
      );
    }
    lines.add('${cohort.vanillaBytes.bytesAsReadableMB()} added by vanilla');
    lines.add('---');
    lines.add('${cohort.totalBytes.bytesAsReadableMB()} total');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Estimated VRAM use — ${cohort.label.toLowerCase()}',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (cohort.unscannedCount > 0)
          Text(
            '${cohort.unscannedCount} of ${cohort.totalMods} mods unscanned — '
            'total understates real VRAM use.',
            style: theme.textTheme.labelSmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        if (gfxConfig != null) ...[
          const SizedBox(height: 6),
          Text(
            'GraphicsLib settings',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Enabled: ${gfxConfig!.areAnyEffectsEnabled ? "yes" : "no"}'
            '\nGenerate Normal maps: ${gfxConfig!.autoGenNormals ? "on" : "off"}'
            '\nPreload all: ${gfxConfig!.preloadAllMaps ? "on" : "off"}',
            style: theme.textTheme.labelLarge,
          ),
          if (gfxConfig!.areAnyEffectsEnabled)
            Text(
              'Normal maps: ${gfxConfig!.areGfxLibNormalMapsEnabled ? "on" : "off"}'
              '\nMaterial maps: ${gfxConfig!.areGfxLibMaterialMapsEnabled ? "on" : "off"}'
              '\nSurface maps: ${gfxConfig!.areGfxLibSurfaceMapsEnabled ? "on" : "off"}',
              style: theme.textTheme.labelLarge,
            ),
        ],
        const SizedBox(height: 6),
        Text(lines.join('\n'), style: theme.textTheme.labelLarge),
      ],
    );
  }
}
