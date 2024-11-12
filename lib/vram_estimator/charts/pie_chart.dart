import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:trios/utils/extensions.dart';

import '../../../utils/util.dart';
import '../models/vram_checker_models.dart';

class VramPieChart extends StatefulWidget {
  final List<Mod> modVramInfo;

  const VramPieChart({super.key, required this.modVramInfo});

  @override
  State<StatefulWidget> createState() => VramPieChartState();
}

class VramPieChartState extends State<VramPieChart> {
  int touchedIndex = -1;

  List<PieChartSectionData> createSections(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.primary;

    return widget.modVramInfo
        .where((element) => element.totalBytesForMod > 0)
        .map((mod) {
      const fontSize = 12.0;
      const radius = 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      return PieChartSectionData(
        color: ColorGenerator.generateFromColor(mod.info.id, baseColor)
            .createMaterialColor()
            .shade700,
        value: mod.totalBytesForMod.toDouble(),
        title:
            "${mod.info.name} ${mod.info.version}\n${mod.totalBytesForMod.bytesAsReadableMB()}",
        radius: radius,
        titlePositionPercentageOffset: 2,
        titleStyle: const TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          // color: AppColors.mainTextColor1,
          shadows: shadows,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: PieChart(
                  PieChartData(
                    // pieTouchData: PieTouchData(
                    // touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    //   setState(() {
                    //     if (!event.isInterestedForInteractions ||
                    //         pieTouchResponse == null ||
                    //         pieTouchResponse.touchedSection == null) {
                    //       touchedIndex = -1;
                    //       return;
                    //     }
                    //     touchedIndex = pieTouchResponse
                    //         .touchedSection!.touchedSectionIndex;
                    //   });
                    // },
                    // ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    sectionsSpace: 1,
                    // centerSpaceRadius: 130,
                    sections: createSections(context),
                  ),
                ),
              ),
            ),
          ),
          // const Column(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: <Widget>[
          //     Indicator(
          //       color: AppColors.contentColorBlue,
          //       text: 'First',
          //       isSquare: true,
          //     ),
          //     SizedBox(
          //       height: 4,
          //     ),
          //     Indicator(
          //       color: AppColors.contentColorYellow,
          //       text: 'Second',
          //       isSquare: true,
          //     ),
          //     SizedBox(
          //       height: 4,
          //     ),
          //     Indicator(
          //       color: AppColors.contentColorPurple,
          //       text: 'Third',
          //       isSquare: true,
          //     ),
          //     SizedBox(
          //       height: 4,
          //     ),
          //     Indicator(
          //       color: AppColors.contentColorGreen,
          //       text: 'Fourth',
          //       isSquare: true,
          //     ),
          //     SizedBox(
          //       height: 18,
          //     ),
          //   ],
          // ),
          // const SizedBox(
          //   width: 28,
          // ),
        ],
      ),
    );
  }
}
