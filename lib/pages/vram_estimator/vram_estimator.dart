import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/pages/vram_estimator/charts/bar_chart.dart';
import 'package:trios/pages/vram_estimator/charts/pie_chart.dart';
import 'package:trios/pages/vram_estimator/vram_checker.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/graph_radio_selector.dart';
import 'package:trios/widgets/spinning_refresh_button.dart';

import '../../models/enabled_mods.dart';
import '../../models/graphics_lib_config.dart';
import '../../trios/settings/settings.dart';
import '../../utils/util.dart';
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

  List<Mod> get modVramInfoToShow =>
      modVramInfo.values.toList().sublist(viewRangeEnds.item1 ?? 0, viewRangeEnds.item2 ?? modVramInfo.length);

  Tuple2<int?, int?> viewRangeEnds = Tuple2(null, null);

  List<String>? getEnabledMods() {
    var settings = ref.read(appSettings);
    var modsFolder = settings.modsDir == null ? null : Directory(settings.modsDir!);

    return modsFolder == null
        ? null
        : JsonMapper.deserialize<EnabledMods>(File(p.join(modsFolder.path, "enabled_mods.json")).readAsStringSync())
            ?.enabledMods;
  }

  void _getVramUsage() async {
    if (isScanning) return;

    var settings = ref.read(appSettings);
    if (settings.modsDir == null || !Directory(settings.modsDir!).existsSync()) {
      Fimber.e('Mods folder not set');
      return;
    }

    setState(() {
      isScanning = true;
    });

    try {
      final info = await VramChecker(
        enabledModIds: settings.enabledModIds,
        modIdsToCheck: null,
        foldersToCheck: settings.modsDir == null ? [] : [Directory(settings.modsDir!)],
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
        modProgressOut: (mod) {
          // update modVramInfo with each mod's progress
          setState(() {
            modVramInfo = modVramInfo..[mod.info.id] = mod;
          });
        },
        debugOut: Fimber.d,
        verboseOut: Fimber.v,
      ).check();

      setState(() {
        isScanning = false;
        modVramInfo = info.fold<Map<String, Mod>>(
            {}, (previousValue, element) => previousValue..[element.info.id] = element); // sort by mod size
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
    var sortedModData = modVramInfoToShow.sortedByDescending<num>((mod) => mod.totalBytesForMod).toList();
    return Column(
      children: <Widget>[
        Row(
          children: [
            SpinningRefreshButton(
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
                isEnabled: sortedModData.isNotEmpty,
                child: Text(
                  '${modVramInfo.length} mods scanned',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Disable(
                isEnabled: sortedModData.isNotEmpty,
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
            // Disable(
            // isEnabled: sortedModData.isNotEmpty,
            // child: RangeSlider(
            // values: RangeValues(
            // viewRangeEnds.item1?.toDouble() ?? 0,
            // viewRangeEnds.item2?.toDouble() ??
            //     (sortedModData.isEmpty
            //         ? 1
            //         : sortedModData.length.toDouble())),
            // min: 0,
            // max:
            //     sortedModData.isEmpty ? 1 : sortedModData.length.toDouble(),
            // divisions: sortedModData.isEmpty ? 1 : sortedModData.length,
            // labels: RangeLabels(
            //     viewRangeEnds.item1?.toString() ?? '0',
            //     viewRangeEnds.item2?.toString() ??
            //         sortedModData.length.toString()),
            // onChanged: (RangeValues values) {
            // setState(() {
            //   viewRangeEnds =
            //       Tuple2(values.start.toInt(), values.end.toInt());
            // });
            // }),
            // ),
            // ),
          ],
        ),
        if (modVramInfo.isNotEmpty)
          Expanded(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                    child: switch (graphType) {
                  GraphType.pie => VramPieChart(modVramInfo: sortedModData),
                  GraphType.bar => VramBarChart(modVramInfo: sortedModData),
                })),
          ),
      ],
    );
  }
}
