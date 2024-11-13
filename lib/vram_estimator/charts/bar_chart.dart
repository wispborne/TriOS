import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/models/gpu_info.dart';

import '../../../utils/util.dart';
import '../models/vram_checker_models.dart';
// ...  (Import extensions, any custom models, and util as in your existing code)

class VramBarChart extends StatefulWidget {
  final List<Mod> modVramInfo;

  const VramBarChart({super.key, required this.modVramInfo});

  @override
  State<StatefulWidget> createState() => VramBarChartState();
}

class VramBarChartState extends State<VramBarChart> {
  // You might not need a 'touchedIndex' for a simple bar chart

  @override
  Widget build(BuildContext context) {
    final mods = widget.modVramInfo;
    final baseColor = Theme.of(context).colorScheme.primary;
    final maxVramUsed = _calculateMostVramUse();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
              "Total System VRAM: ${getGPUInfo()?.freeVRAM.bytesAsReadableMB() ?? "unknown"}",
              style: theme.textTheme.labelLarge),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, layoutConstraints) {
            return mods.isEmpty
                ? const CircularProgressIndicator()
                : ListView.builder(
                    itemCount: mods.length,
                    itemBuilder: (context, index) {
                      if (index > mods.length - 1) return const SizedBox();
                      final mod = mods[index];
                      final percentOfMax = mod.totalBytesForMod / maxVramUsed;
                      final width = layoutConstraints.maxWidth * percentOfMax;

                      return Container(
                        child: Card(
                          clipBehavior: Clip.hardEdge,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(mod.info.formattedName,
                                      style: theme.textTheme.labelLarge),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(
                                      mod.totalBytesForMod.bytesAsReadableMB(),
                                      style: theme.textTheme.labelMedium),
                                ),
                                Opacity(
                                  opacity: 0.6,
                                  child: Container(
                                    width: width,
                                    height: 10,
                                    color: ColorGenerator.generateFromColor(
                                            mod.info.smolId, baseColor)
                                        .createMaterialColor()
                                        .shade700,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    });
          }),
        ),
      ],
    );
  }

  double _calculateMostVramUse() {
    return widget.modVramInfo
            .maxByOrNull<num>((mod) => mod.totalBytesForMod)
            ?.totalBytesForMod
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
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
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
        .where((element) => element.totalBytesForMod > 0)
        .map((mod) => BarChartGroupData(
              x: widget.modVramInfo.indexOf(mod),
              barRods: [
                BarChartRodData(
                  toY: mod.totalBytesForMod.toDouble(), // Y-axis value
                  color:
                      ColorGenerator.generateFromColor(mod.info.smolId, baseColor)
                          .createMaterialColor()
                          .shade700,
                  width: 12, // Adjust bar width
                ),
              ],
            ))
        .toList();
  }
}
