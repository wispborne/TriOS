import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/vram_checker_explanation.dart';
import 'package:trios/models/version.dart';
import 'package:trios/thirdparty/dartx/iterable.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/graph_radio_selector.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/spinning_refresh_button.dart';
import 'package:trios/widgets/toolbar_checkbox_button.dart';

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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final vramStateProvider = ref.watch(AppState.vramEstimatorProvider);
    if (vramStateProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final vramState = vramStateProvider.requireValue;
    final isScanning = vramState.isScanning;
    final enabledSmolIds =
        ref
            .watch(AppState.enabledModVariants)
            .map((mod) => mod.smolId)
            .toList();

    // Display only the highest version of each mod.
    final groupedModVramInfo =
        vramState.modVramInfo.values
            .where(
              (mod) =>
                  // If only showing enabled, filter to only the enabled *variants*.
                  _onlyEnabled
                      ? enabledSmolIds.contains(mod.info.smolId)
                      : true,
            )
            .groupBy((mod) => mod.info.modInfo.id)
            .values
            .map(
              (group) => group.maxWith(
                (a, b) => (a.info.version ?? Version.zero()).compareTo(
                  b.info.version,
                ),
              ),
            )
            .nonNulls
            .toList();
    final modVramInfo =
        groupedModVramInfo.map((mod) => MapEntry(mod.info.smolId, mod)).toMap();
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
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 50,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Row(
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
                        onPressed:
                            () => showDialog(
                              context: context,
                              builder:
                                  (context) => VramCheckerExplanationDialog(),
                            ),
                      ),
                    ),
                    Disable(
                      isEnabled: !isScanning,
                      child: SpinningRefreshButton(
                        onPressed: () {
                          if (!isScanning) {
                            ref
                                .read(AppState.vramEstimatorProvider.notifier)
                                .startEstimating();
                          }
                        },
                        isScanning: isScanning,
                        tooltip: 'Estimate VRAM',
                      ),
                    ),
                    if (isScanning)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: OutlinedButton.icon(
                          onPressed:
                              () =>
                                  ref
                                      .read(
                                        AppState.vramEstimatorProvider.notifier,
                                      )
                                      .cancelEstimation(),
                          label: Text(
                            vramState.isCancelled ? 'Canceling...' : 'Cancel',
                          ),
                          icon: const Icon(Icons.cancel),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Disable(
                        isEnabled: modVramInfoToShow.isNotEmpty,
                        child: Text(
                          '${modVramInfo.length} mods scanned',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 32.0),
                      child: Disable(
                        isEnabled: modVramInfoToShow.isNotEmpty,
                        child: Card.outlined(
                          child: SizedBox(
                            width: 300,
                            child: GraphTypeSelector(
                              onGraphTypeChanged: (GraphType type) {
                                setState(() {
                                  graphType = type;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    Spacer(),
                    TriOSToolbarCheckboxButton(
                      onChanged:
                          (newValue) =>
                              setState(() => _onlyEnabled = newValue ?? true),
                      value: _onlyEnabled,
                      text: 'Enabled Mods Only',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (modVramInfo.isNotEmpty)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
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

  List<VramMod> _calculateModsToShow(
    Map<String, VramMod> modVramInfo,
    GraphicsLibConfig? graphicsLibConfig,
  ) {
    return modVramInfo.values
        .where(
          (mod) =>
              mod.totalBytesUsingGraphicsLibConfig(graphicsLibConfig) >=
                  (selectedSliderValues?.start ?? 0) &&
              mod.totalBytesUsingGraphicsLibConfig(graphicsLibConfig) <=
                  (selectedSliderValues?.end ??
                      _maxRange(modVramInfo, graphicsLibConfig)),
        )
        .sortedByDescending<num>(
          (mod) => mod.totalBytesUsingGraphicsLibConfig(graphicsLibConfig),
        )
        .toList();
  }

  double _maxRange(
    Map<String, VramMod> modVramInfo,
    GraphicsLibConfig? graphicsLibConfig,
  ) {
    return modVramInfo.values
            .sortedByButBetter<num>(
              (mod) => mod.totalBytesUsingGraphicsLibConfig(graphicsLibConfig),
            )
            .lastOrNull
            ?.totalBytesUsingGraphicsLibConfig(graphicsLibConfig)
            .toDouble() ??
        2;
  }
}
