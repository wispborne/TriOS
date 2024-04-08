import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/vram_estimator/vram_checker.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/graph_radio_selector.dart';
import 'package:trios/widgets/spinning_refresh_fab.dart';

import '../../trios/settings/settings.dart';
import 'charts/bar_chart.dart';
import 'charts/pie_chart.dart';
import 'models/graphics_lib_config.dart';
import 'models/mod_result.dart';

class VramEstimatorPage extends ConsumerStatefulWidget {
  const VramEstimatorPage({super.key});

  final String title = "VRAM Estimator";
  final String subtitle = "Estimate VRAM usage for mods";

  @override
  ConsumerState<VramEstimatorPage> createState() => _VramEstimatorPageState();
}

class _VramEstimatorPageState extends ConsumerState<VramEstimatorPage>
    with AutomaticKeepAliveClientMixin<VramEstimatorPage> {
  @override
  bool get wantKeepAlive => true;

  bool isScanning = false;
  GraphType graphType = GraphType.pie;
  Map<String, Mod> modVramInfo = {};

  List<Mod> modVramInfoToShow = [];
  double largestVramUsage = 0;

  RangeValues? selectedSliderValues;

  void _getVramUsage() async {
    if (isScanning) return;

    var settings = ref.read(appSettings);
    if (settings.modsDir == null || !settings.modsDir!.existsSync()) {
      Fimber.e('Mods folder not set');
      return;
    }

    setState(() {
      isScanning = true;
      modVramInfo = {};
      modVramInfoToShow = [];
      largestVramUsage = 0;
    });

    try {
      final info = await VramChecker(
        enabledModIds: ref.read(AppState.enabledModIds).value,
        modIdsToCheck: null,
        foldersToCheck: settings.modsDir == null ? [] : [settings.modsDir!],
        graphicsLibConfig: GraphicsLibConfig(
          areAnyEffectsEnabled: false,
          areGfxLibMaterialMapsEnabled: false,
          areGfxLibNormalMapsEnabled: false,
          areGfxLibSurfaceMapsEnabled: false,
        ),
        showCountedFiles: true,
        showSkippedFiles: true,
        showGfxLibDebugOutput: true,
        showPerformance: true,
        modProgressOut: (Mod mod) {
          // update modVramInfo with each mod's progress
          setState(() {
            modVramInfo = modVramInfo..[mod.info.id] = mod;
            modVramInfoToShow = _calculateModsToShow();
          });
        },
        debugOut: Fimber.d,
        verboseOut: Fimber.v,
      ).check();

      setState(() {
        isScanning = false;
        modVramInfo = info.fold<Map<String, Mod>>(
            {}, (previousValue, element) => previousValue..[element.info.id] = element); // sort by mod size
        largestVramUsage = modVramInfo.values
                .maxByOrNull<num>((mod) => mod.totalBytesForMod)
                ?.totalBytesForMod
                .toDouble()
                .coerceAtLeast(2) ??
            2;
        selectedSliderValues = RangeValues(0, _maxRange());
        modVramInfoToShow = _calculateModsToShow();
      });
    } catch (e) {
      Fimber.w('Error scanning for VRAM usage: $e');
      setState(() {
        isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var rangeMax = _maxRange();

    var showRangeSlider = selectedSliderValues != null && !isScanning && modVramInfoToShow.isNotEmpty;
    return Column(children: <Widget>[
      Row(
        children: [
          SpinningRefreshFAB(
            onPressed: () {
              if (!isScanning) _getVramUsage();
            },
            isScanning: isScanning,
            tooltip: 'Estimate VRAM',
            // needsAttention: modVramInfo.isEmpty && !isScanning,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Disable(
              isEnabled: modVramInfoToShow.isNotEmpty,
              child: Text(
                '${modVramInfo.length} mods scanned',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          // const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Disable(
              isEnabled: modVramInfoToShow.isNotEmpty,
              child: Card.outlined(
                child: SizedBox(
                  width: 300,
                  child: GraphTypeSelector(onGraphTypeChanged: (GraphType type) {
                    setState(() {
                      graphType = type;
                    });
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
      if (modVramInfo.isNotEmpty)
        Expanded(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                  child: switch (graphType) {
                GraphType.pie => VramPieChart(modVramInfo: modVramInfoToShow),
                GraphType.bar => VramBarChart(modVramInfo: modVramInfoToShow),
              })),
        ),
      if (showRangeSlider)
        SizedBox(
          width: 300,
          child: Disable(
            isEnabled: showRangeSlider,
            child: RangeSlider(
                values: selectedSliderValues
                        ?.let((it) => RangeValues(it.start.coerceAtLeast(0), it.end.coerceAtMost(rangeMax))) ??
                    RangeValues(0, rangeMax),
                min: 0,
                max: rangeMax,
                divisions: 50,
                labels: RangeLabels((selectedSliderValues?.start ?? 0).bytesAsReadableMB(),
                    (selectedSliderValues?.end ?? rangeMax).bytesAsReadableMB()),
                onChanged: (RangeValues values) {
                  setState(() {
                    selectedSliderValues = values;
                    modVramInfoToShow = _calculateModsToShow();
                  });
                }),
          ),
        ),
    ]);
  }

  List<Mod> _calculateModsToShow() {
    return modVramInfo.values
        .where((mod) =>
            mod.totalBytesForMod >= (selectedSliderValues?.start ?? 0) &&
            mod.totalBytesForMod <= (selectedSliderValues?.end ?? _maxRange()))
        .toList();
  }

  double roundToAppealing(double number) {
    if (number <= 0) {
      return 0; // Handle negative and zero
    }

    // Find the appropriate power of 10
    int powerOfTen = (number.abs().toString().length - 1);

    // Calculate the rounding base
    double roundingBase = pow(10, powerOfTen).toDouble();

    // Round up and multiply
    return (number / roundingBase).ceil() * roundingBase;
  }

  double _maxRange() {
    return modVramInfo.values.sortedBy<num>((mod) => mod.totalBytesForMod).lastOrNull?.totalBytesForMod.toDouble() ?? 2;
  }
}
