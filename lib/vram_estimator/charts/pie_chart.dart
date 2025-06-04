import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/graphics_lib_config_provider.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/vram_estimator_page.dart';
import 'package:trios/widgets/mod_icon.dart';
import 'package:trios/widgets/moving_tooltip.dart';

import '../../../utils/util.dart';
import '../models/vram_checker_models.dart';

class VramPieChart extends ConsumerStatefulWidget {
  final List<VramMod> modVramInfo;

  const VramPieChart({super.key, required this.modVramInfo});

  @override
  ConsumerState createState() => VramPieChartState();
}

class VramPieChartState extends ConsumerState<VramPieChart> {
  int touchedIndex = -1;
  GraphicsLibConfig? graphicsLibConfig;

  List<PieChartSectionData> createSections(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.primary;
    final theme = Theme.of(context);
    final realMods = ref.watch(AppState.mods);

    return widget.modVramInfo
        .where(
          (element) =>
              element.totalBytesUsingGraphicsLibConfig(graphicsLibConfig) > 0,
        )
        .map((mod) {
          const fontSize = 12.0;
          const radius = 50.0;
          const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
          final materialColor =
              ColorGenerator.generateFromColor(
                mod.info.smolId,
                baseColor,
              ).createMaterialColor();
          final realMod = realMods.firstWhereOrNull(
            (vramMod) => vramMod.id == mod.info.modInfo.id,
          );
          final iconFilePath =
              realMod?.findFirstEnabledOrHighestVersion?.iconFilePath;

          return PieChartSectionData(
            color: materialColor.shade700,
            value:
                mod.totalBytesUsingGraphicsLibConfig(graphicsLibConfig).toDouble(),
            title:
                "${mod.info.name} ${mod.info.version}\n${mod.totalBytesUsingGraphicsLibConfig(graphicsLibConfig).bytesAsReadableMB()}",
            radius: radius,
            titlePositionPercentageOffset: 2,
            titleStyle: const TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              // color: AppColors.mainTextColor1,
              shadows: shadows,
            ),
            badgeWidget: MovingTooltipWidget.framed(
              tooltipWidget: VramEstimatorPage.buildVramTopFilesTableWidget(
                theme,
                mod,
                graphicsLibConfig,
              ),
              child:
                  iconFilePath != null
                      ? ModIcon(iconFilePath)
                      : Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: materialColor.shade900,
                          shape: BoxShape.circle,
                        ),
                      ),
            ),
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    graphicsLibConfig = ref.watch(graphicsLibConfigProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: AspectRatio(
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
                      borderData: FlBorderData(show: false),
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
      ),
    );
  }
}
