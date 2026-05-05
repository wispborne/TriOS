import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trios/models/version.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/selectors/selector_registry.dart';
import 'package:trios/vram_estimator/selectors/vram_selector_id.dart';
import 'package:trios/vram_estimator/vram_checker_explanation.dart';
import 'package:trios/vram_estimator/vram_estimator_manager.dart';
import 'package:trios/vram_estimator/widgets/reference_scan_debug_panel.dart';
import 'package:trios/vram_estimator/widgets/scan_progress_panel.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/graph_radio_selector.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/overflow_menu_button.dart';
import 'package:trios/widgets/snackbar.dart';
import 'package:trios/widgets/viewer_search_box.dart';

import 'charts/bar_chart.dart';
import 'charts/pie_chart.dart';
import 'graphics_lib_config_provider.dart';
import 'models/graphics_lib_config.dart';
import 'models/vram_checker_models.dart';

class VramEstimatorPage extends ConsumerStatefulWidget {
  const VramEstimatorPage({super.key});

  final String title = "VRAM Estimator";
  final String subtitle = "Estimate VRAM usage for mods";

  static String buildHeaviestImagesTable(
    List<ModImageView> topTenLargestImagesByVram,
  ) {
    if (topTenLargestImagesByVram.isEmpty) return 'No images.';

    // Determine max column widths
    int maxFileNameLength = 0;
    int maxVramLength = 0;
    int maxDimsLength = 0;

    for (final image in topTenLargestImagesByVram) {
      maxFileNameLength = max(
        maxFileNameLength,
        image.file.nameWithExtension.length,
      );
      maxVramLength = max(
        maxVramLength,
        image.bytesUsed.bytesAsReadableMB().length,
      );
      maxDimsLength = max(
        maxDimsLength,
        '${image.textureWidth}x${image.textureHeight}'.length,
      );
    }

    // Add some padding for readability
    maxFileNameLength += 2;
    maxVramLength += 2;
    maxDimsLength += 2;

    final rows = topTenLargestImagesByVram
        .map((image) {
          final fileName = image.file.nameWithExtension;
          final vram = image.bytesUsed.bytesAsReadableMB();
          final dims = '${image.textureWidth}x${image.textureHeight}';

          return '${fileName.padRight(maxFileNameLength)}'
              ' | ${vram.padLeft(maxVramLength)}'
              ' | ${dims.padLeft(maxDimsLength)}';
        })
        .join('\n');

    return rows;
  }

  static Column buildVramTopFilesTableWidget(
    ThemeData theme,
    VramMod mod,
    GraphicsLibConfig? graphicsLibConfig,
  ) {
    final topTenLargestImagesByVram =
        List.generate(mod.images.length, mod.getModViewForIndex)
            .sortedByDescending<num>((image) => image.bytesUsed)
            .where(
              (image) =>
                  image.isUsedBasedOnGraphicsLibConfig(graphicsLibConfig),
            )
            .take(10)
            .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images Estimated to Use the Most VRAM ',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          "Note: Image dimensions in VRAM are usually bigger than actual.",
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          buildHeaviestImagesTable(topTenLargestImagesByVram),
          // Monospace font for table
          style: TextStyle(
            fontFamily: 'Roboto Mono',
            fontFamilyFallback: [
              'Courier',
              'Courier New',
              'Consolas',
              'Monaco',
              'Roboto Mono',
            ],
            fontSize: 14.0,
            fontFeatures: [
              FontFeature.tabularFigures(),
            ], // Ensures uniform character width
          ),
        ),
      ],
    );
  }

  @override
  ConsumerState<VramEstimatorPage> createState() => _VramEstimatorPageState();
}

class _VramEstimatorPageState extends ConsumerState<VramEstimatorPage>
    with AutomaticKeepAliveClientMixin<VramEstimatorPage> {
  @override
  bool get wantKeepAlive => true;

  GraphType graphType = GraphType.bar;
  RangeValues? selectedSliderValues;
  bool _onlyEnabled = false;
  final SearchController _searchController = SearchController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final vramStateProvider = ref.watch(AppState.vramEstimatorProvider);
    if (vramStateProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final vramState = vramStateProvider.requireValue;
    final isScanning = vramState.isScanning;
    final enabledSmolIds = ref
        .watch(AppState.enabledModVariants)
        .map((mod) => mod.smolId)
        .toList();

    // Count of mods that would be scanned by the "scan unscanned only"
    // button — enabled-or-highest-version variants whose smolId is not yet
    // in the cache. Recomputed per rebuild; cheap (just a set lookup).
    final scannedSmolIds = vramState.modVramInfo.keys.toSet();
    final unscannedCount = ref
        .watch(AppState.mods)
        .map((mod) => mod.findFirstEnabledOrHighestVersion)
        .nonNulls
        .where((v) => !scannedSmolIds.contains(v.smolId))
        .length;

    final searchQuery = _searchQuery.trim().toLowerCase();

    // Display only the highest version of each mod.
    final groupedModVramInfo = vramState.modVramInfo.values
        .where(
          (mod) =>
              // If only showing enabled, filter to only the enabled *variants*.
              _onlyEnabled ? enabledSmolIds.contains(mod.info.smolId) : true,
        )
        .where((mod) {
          if (searchQuery.isEmpty) return true;
          final name = mod.info.name?.toLowerCase() ?? '';
          final id = mod.info.modInfo.id.toLowerCase();
          return name.contains(searchQuery) || id.contains(searchQuery);
        })
        .groupBy((mod) => mod.info.modInfo.id)
        .values
        .map(
          (group) => group.maxWith(
            (a, b) =>
                (a.info.version ?? Version.zero()).compareTo(b.info.version),
          ),
        )
        .nonNulls
        .toList();
    final modVramInfo = groupedModVramInfo
        .map((mod) => MapEntry(mod.info.smolId, mod))
        .toMap();
    final graphicsLibConfig = ref.watch(graphicsLibConfigProvider);

    var modVramInfoToShow = _calculateModsToShow(
      modVramInfo,
      graphicsLibConfig,
    );
    var rangeMax = _maxRange(modVramInfo, graphicsLibConfig);

    var showRangeSlider =
        selectedSliderValues != null &&
        !isScanning &&
        modVramInfoToShow.isNotEmpty;

    return Column(
      children: <Widget>[
        Padding(
          padding: const .only(top: 4, left: 4, right: 4),
          child: buildToolbar(
            context,
            isScanning,
            vramState,
            unscannedCount,
            modVramInfoToShow,
          ),
        ),
        if (ref.watch(appSettings.select((s) => s.debugMode)))
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: ReferenceScanDebugPanel(),
          ),
        if (modVramInfo.isNotEmpty)
          Expanded(
            child: Padding(
              padding: const .only(left: 4, right: 4),
              child: switch (graphType) {
                GraphType.bar => VramBarChart(modVramInfo: modVramInfoToShow),
                GraphType.pie => VramPieChart(modVramInfo: modVramInfoToShow),
              },
            ),
          ),
        if (showRangeSlider)
          SizedBox(
            width: 420,
            child: Disable(
              isEnabled: showRangeSlider,
              child: Row(
                children: [
                  Text(
                    0.bytesAsReadableMB(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Expanded(
                    child: RangeSlider(
                      values:
                          selectedSliderValues?.let(
                            (it) => RangeValues(
                              it.start.coerceAtLeast(0),
                              it.end.coerceAtMost(rangeMax),
                            ),
                          ) ??
                          RangeValues(0, rangeMax),
                      min: 0,
                      max: rangeMax,
                      divisions: 50,
                      labels: RangeLabels(
                        (selectedSliderValues?.start ?? 0).bytesAsReadableMB(),
                        (selectedSliderValues?.end ?? rangeMax)
                            .bytesAsReadableMB(),
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          selectedSliderValues = values;
                        });
                      },
                    ),
                  ),
                  Text(
                    rangeMax.bytesAsReadableMB(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  SizedBox buildToolbar(
    BuildContext context,
    bool isScanning,
    VramEstimatorManagerState vramState,
    int unscannedCount,
    List<VramMod> modVramInfoToShow,
  ) {
    final hasUnscanned = !isScanning && unscannedCount > 0;
    final scanLabel = hasUnscanned
        ? 'Scan $unscannedCount mod${unscannedCount == 1 ? "" : "s"}'
        : isScanning
        ? _buildRefreshTooltip(vramState)
        : 'All mods scanned';

    return SizedBox(
      // height: 50,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 4),
                  Text(
                    'VRAM Estimator',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  MovingTooltipWidget.text(
                    message: "About VRAM & VRAM Estimator",
                    child: IconButton(
                      icon: const Icon(Icons.info),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => VramCheckerExplanationDialog(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Disable(
                      isEnabled: modVramInfoToShow.isNotEmpty,
                      child: GraphTypeSelector(
                        onGraphTypeChanged: (GraphType type) {
                          setState(() {
                            graphType = type;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildScanButton(
                    isScanning,
                    hasUnscanned,
                    scanLabel,
                    vramState,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: ViewerSearchBox(
                            searchController: _searchController,
                            hintText: 'Filter mods...',
                            onChanged: (query) =>
                                setState(() => _searchQuery = query),
                            onClear: () => setState(() => _searchQuery = ''),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildOverflowMenu(vramState),
                ],
              ),
              const Padding(
                padding: .only(left: 8, right: 8, bottom: 8, top: 8),
                child: ScanProgressPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton(
    bool isScanning,
    bool hasUnscanned,
    String scanLabel,
    VramEstimatorManagerState vramState,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MovingTooltipWidget.text(
          message: scanLabel,
          child: Disable(
            isEnabled: !isScanning && hasUnscanned,
            child: Material(
              color: colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                onTap: hasUnscanned
                    ? () => ref
                          .read(AppState.vramEstimatorProvider.notifier)
                          .scanUnscanned()
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      if (isScanning)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onSurface,
                          ),
                        )
                      else
                        Icon(
                          Icons.memory,
                          size: 18,
                          color: colorScheme.onSurface,
                        ),
                      Text(
                        scanLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 1,
          height: 28,
          color: colorScheme.onInverseSurface.withValues(alpha: 0.3),
        ),
        MovingTooltipWidget.text(
          message: 'More scan options',
          child: Disable(
            isEnabled: !isScanning,
            child: Material(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: PopupMenuButton<String>(
                tooltip: '',
                padding: EdgeInsets.zero,
                position: PopupMenuPosition.under,
                onSelected: (value) {
                  if (value == 'rescan_all') {
                    ref
                        .read(AppState.vramEstimatorProvider.notifier)
                        .startEstimating();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'rescan_all',
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.refresh),
                      title: Text(
                        vramState.modVramInfo.isEmpty
                            ? 'Scan all mods'
                            : 'Re-scan all mods',
                      ),
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverflowMenu(VramEstimatorManagerState vramState) {
    final settings = ref.watch(appSettings);
    final activeId = settings.vramEstimatorSelectorId;
    final options = allSelectorOptions();

    return OverflowMenuButton(
      menuItems: [
        OverflowMenuCheckItem(
          title: 'Enabled Mods Only',
          icon: Icons.filter_list,
          checked: _onlyEnabled,
          onTap: () => setState(() => _onlyEnabled = !_onlyEnabled),
        ).toEntry(0),
        const PopupMenuDivider(),
        for (final opt in options)
          OverflowMenuCheckItem(
            title: opt.displayName,
            icon: opt.id == VramSelectorId.folderScan
                ? Icons.folder_open
                : Icons.manage_search,
            checked: activeId == opt.id,
            onTap: () {
              ref
                  .read(appSettings.notifier)
                  .update((s) => s.copyWith(vramEstimatorSelectorId: opt.id));
              ref
                  .read(AppState.vramEstimatorProvider.notifier)
                  .onSelectorOrConfigChanged();
            },
          ).toEntry(null),
        const PopupMenuDivider(),
        OverflowMenuItem(
          title: 'Export cache as JSON…',
          icon: Icons.file_download,
          onTap: vramState.modVramInfo.isEmpty
              ? () {}
              : () => _exportCacheAsJson(context, ref),
        ).toEntry(1),
      ],
    );
  }

  List<VramMod> _calculateModsToShow(
    Map<String, VramMod> modVramInfo,
    GraphicsLibConfig? graphicsLibConfig,
  ) {
    final start = selectedSliderValues?.start ?? 0;
    final end =
        selectedSliderValues?.end ?? _maxRange(modVramInfo, graphicsLibConfig);
    return modVramInfo.values
        .where((mod) {
          final bytes = mod.bytesNotIncludingGraphicsLib();
          return bytes >= start && bytes <= end;
        })
        .sortedByDescending<num>((mod) => mod.bytesNotIncludingGraphicsLib())
        .toList();
  }

  String _buildRefreshTooltip(VramEstimatorManagerState state) {
    if (!state.isScanning) {
      return state.modVramInfo.isEmpty ? 'Estimate VRAM' : 'Re-estimate VRAM';
    }
    final done = state.modsScannedThisRun;
    final total = state.totalModsToScan;
    final progress = total > 0 ? ' ($done/$total)' : '';
    final current = state.currentlyScanningModName;
    if (current != null && current.isNotEmpty) {
      return 'Scanning: $current$progress';
    }
    return 'Scanning$progress';
  }

  Future<void> _exportCacheAsJson(BuildContext context, WidgetRef ref) async {
    final timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final suggestedName = 'TriOS-VRAM_CheckerCache-$timestamp.json';

    String? chosen;
    try {
      chosen = await FilePicker.platform.saveFile(
        dialogTitle: 'Export VRAM cache as JSON',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        lockParentWindow: true,
      );
    } catch (e, st) {
      Fimber.e(
        'Failed to open save-file dialog for VRAM JSON export: $e',
        ex: e,
        stacktrace: st,
      );
      if (context.mounted) {
        showSnackBar(
          context: context,
          type: SnackBarType.error,
          content: const Text('Could not open save dialog.'),
        );
      }
      return;
    }

    if (chosen == null) return;
    if (!chosen.toLowerCase().endsWith('.json')) {
      chosen = '$chosen.json';
    }

    try {
      await ref
          .read(AppState.vramEstimatorProvider.notifier)
          .exportAsJson(File(chosen));
      if (context.mounted) {
        showSnackBar(
          context: context,
          type: SnackBarType.info,
          content: Text('Exported VRAM cache to $chosen'),
        );
      }
    } catch (e, st) {
      Fimber.e(
        'Failed to write VRAM cache JSON export to $chosen: $e',
        ex: e,
        stacktrace: st,
      );
      if (context.mounted) {
        showSnackBar(
          context: context,
          type: SnackBarType.error,
          content: Text('Export failed: $e'),
        );
      }
    }
  }

  double _maxRange(
    Map<String, VramMod> modVramInfo,
    GraphicsLibConfig? graphicsLibConfig,
  ) {
    var max = 0;
    for (final mod in modVramInfo.values) {
      final bytes = mod.bytesNotIncludingGraphicsLib();
      if (bytes > max) max = bytes;
    }
    return max == 0 ? 2 : max.toDouble();
  }
}
