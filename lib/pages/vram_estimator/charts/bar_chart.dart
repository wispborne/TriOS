import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:vram_estimator_flutter/utils/extensions.dart';

import '../models/mod_result.dart';
import '../../../utils/util.dart';
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
    return AspectRatio(
      aspectRatio: 1.3, // Adjust as needed
      child: Card(
        elevation: 4, // Add some visual elevation
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _calculateMaxY(),
              // Helper to calculate max Y
              barTouchData: BarTouchData(enabled: false),
              // No touch behavior needed
              titlesData: _buildTitlesData(),
              gridData: FlGridData(show: false),
              // Optionally remove grid lines
              barGroups: _buildBarGroups(context),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateMaxY() {
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
          widget.modVramInfo[modIndex].info.name,
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
                      ColorGenerator.generateFromColor(mod.info.id, baseColor)
                          .createMaterialColor()
                          .shade700,
                  width: 12, // Adjust bar width
                ),
              ],
            ))
        .toList();
  }
}
