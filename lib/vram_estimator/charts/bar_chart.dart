import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/graphics_lib_config_provider.dart';
import 'package:trios/vram_estimator/models/gpu_info.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/vram_estimator_page.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';

import '../../../utils/util.dart';
import '../models/vram_checker_models.dart';
// ...  (Import extensions, any custom models, and util as in your existing code)

class VramBarChart extends ConsumerStatefulWidget {
  final List<VramMod> modVramInfo;

  const VramBarChart({super.key, required this.modVramInfo});

  @override
  ConsumerState createState() => VramBarChartState();
}

class VramBarChartState extends ConsumerState<VramBarChart> {
  GraphicsLibConfig? graphicsLibConfig;

  @override
  Widget build(BuildContext context) {
    final mods = widget.modVramInfo;
    final baseColor = Theme.of(context).colorScheme.primary;
    final maxVramUsed = _calculateMostVramUse();
    final theme = Theme.of(context);
    graphicsLibConfig = ref.watch(graphicsLibConfigProvider);
    final realMods = ref.watch(AppState.mods);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            "Total System VRAM: ${getGPUInfo()?.freeVRAM.bytesAsReadableMB() ?? "unknown"}",
            style: theme.textTheme.labelLarge,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, layoutConstraints) {
              return mods.isEmpty
                  ? const CircularProgressIndicator()
                  : ListView.builder(
                    itemCount: mods.length,
                    itemBuilder: (context, index) {
                      if (index > mods.length - 1) return const SizedBox();
                      final mod = mods[index];
                      final realMod = realMods.firstWhereOrNull(
                        (vramMod) => vramMod.id == mod.info.modInfo.id,
                      );
                      final percentOfMax =
                          mod.bytesUsingGraphicsLibConfig(graphicsLibConfig) /
                          maxVramUsed;
                      final width = layoutConstraints.maxWidth * percentOfMax;

                      final iconFilePath =
                          realMod
                              ?.findFirstEnabledOrHighestVersion
                              ?.iconFilePath;

                      return MovingTooltipWidget.framed(
                        tooltipWidget:
                            VramEstimatorPage.buildVramTopFilesTableWidget(
                              theme,
                              mod,
                              graphicsLibConfig,
                            ),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (iconFilePath != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                        ),
                                        child: ModIcon(iconFilePath, size: 28),
                                      ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: Text(
                                            mod.info.formattedName,
                                            style: theme.textTheme.labelLarge,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: Text(
                                            mod
                                                .bytesUsingGraphicsLibConfig(
                                                  graphicsLibConfig,
                                                )
                                                .bytesAsReadableMB(),
                                            style: theme.textTheme.labelMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Opacity(
                                  opacity: 0.6,
                                  child: Container(
                                    width: width,
                                    height: 10,
                                    color:
                                        ColorGenerator.generateFromColor(
                                          mod.info.smolId,
                                          baseColor,
                                        ).createMaterialColor().shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
            },
          ),
        ),
      ],
    );
  }

  double _calculateMostVramUse() {
    return widget.modVramInfo
            .maxByOrNull<num>(
              (mod) => mod.bytesUsingGraphicsLibConfig(graphicsLibConfig),
            )
            ?.bytesUsingGraphicsLibConfig(graphicsLibConfig)
            .toDouble() ??
        0;
  }

  FlTitlesData _buildTitlesData() => FlTitlesData(
    show: true,
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30, // Allocate space for labels
        getTitlesWidget: (value, meta) => _buildBottomLabel(value, meta),
      ),
    ),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
  );

  Widget _buildBottomLabel(double value, TitleMeta meta) {
    int modIndex = value.toInt();
    if (modIndex >= 0 && modIndex < widget.modVramInfo.length) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          widget.modVramInfo[modIndex].info.name ?? '(no name)',
          style: const TextStyle(fontSize: 10),
        ),
      );
    } else {
      return const Text('');
    }
  }

  List<BarChartGroupData> _buildBarGroups(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.primary;
    return widget.modVramInfo
        .where(
          (element) =>
              element.bytesUsingGraphicsLibConfig(graphicsLibConfig) > 0,
        )
        .map(
          (mod) => BarChartGroupData(
            x: widget.modVramInfo.indexOf(mod),
            barRods: [
              BarChartRodData(
                toY:
                    mod
                        .bytesUsingGraphicsLibConfig(graphicsLibConfig)
                        .toDouble(), // Y-axis value
                color:
                    ColorGenerator.generateFromColor(
                      mod.info.smolId,
                      baseColor,
                    ).createMaterialColor().shade700,
                width: 12, // Adjust bar width
              ),
            ],
          ),
        )
        .toList();
  }
}
