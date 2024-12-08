import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/vram_checker_logic.dart';
import 'package:trios/widgets/disable.dart';
import 'package:trios/widgets/graph_radio_selector.dart';
import 'package:trios/widgets/spinning_refresh_fab.dart';

import '../../trios/settings/settings.dart';
import 'charts/bar_chart.dart';
import 'charts/pie_chart.dart';
import 'graphics_lib_config_provider.dart';
import 'models/graphics_lib_config.dart';
import 'models/vram_checker_models.dart';

part 'vram_estimator.mapper.dart';

@MappableClass()
class VramEstimatorState with VramEstimatorStateMappable {
  final bool isScanning;
  final Map<String, VRamMod> modVramInfo;
  final bool isCancelled;
  final DateTime? lastUpdated;

  VramEstimatorState({
    required this.isScanning,
    required this.modVramInfo,
    required this.isCancelled,
    required this.lastUpdated,
  });

  factory VramEstimatorState.initial() {
    return VramEstimatorState(
      isScanning: false,
      modVramInfo: {},
      isCancelled: false,
      lastUpdated: null,
    );
  }
}

class VramEstimatorManager extends GenericSettingsManager<VramEstimatorState> {
  @override
  VramEstimatorState Function() get createDefaultState =>
      () => VramEstimatorState.initial();

  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => "TriOS-VRAM_CheckerCache.json";

  @override
  VramEstimatorState Function(Map<String, dynamic> map) get fromMap =>
      (map) => VramEstimatorStateMapper.fromMap(map);

  @override
  Map<String, dynamic> Function(VramEstimatorState obj) get toMap =>
      (obj) => obj.toMap();
}

class VramEstimatorNotifier
    extends GenericSettingsNotifier<VramEstimatorState> {
  // @override
  // VramEstimatorState build() {
  //   readFromDisk();
  //
  //   return VramEstimatorState.initial();
  // }

  @override
  GenericSettingsManager<VramEstimatorState> createSettingsManager() =>
      VramEstimatorManager();

  // void readFromDisk() async {
  //   await configManager.readConfig();
  //
  //   if (configManager.config.isNotEmpty) {
  //     final modVramInfo =
  //         configManager.config['modVramInfo'] as Map<String, dynamic>;
  //     final lastUpdated = configManager.config['lastUpdated'] as String;
  //
  //     state = state.copyWith(
  //       modVramInfo: modVramInfo
  //           .map((key, value) => MapEntry(key, ModMapper.fromJson(value))),
  //       isCancelled: false,
  //       isScanning: false,
  //       lastUpdated: Constants.dateTimeFormat.parse(lastUpdated),
  //     );
  //   }
  // }

  Future<void> startEstimating({List<String>? smolIdsToCheck}) async {
    if (state.isScanning) return;

    var settings = ref.read(appSettings);
    if (settings.modsDir == null || !settings.modsDir!.existsSync()) {
      Fimber.e('Mods folder not set');
      // Optionally, you can set an error state here
      return;
    }

    state = state.copyWith(
      isScanning: true,
      isCancelled: false,
    );

    try {
      final info = await VramChecker(
        enabledModIds: ref.read(AppState.enabledModIds).value,
        modsToCheck: ref
            .read(AppState.mods)
            .map((mod) => mod.findFirstEnabledOrHighestVersion)
            .whereNotNull()
            .toList(),
        // TODO get graphicslib settings!
        graphicsLibConfig:
            ref.read(graphicsLibConfigProvider) ?? GraphicsLibConfig.disabled,
        showCountedFiles: true,
        showSkippedFiles: true,
        showGfxLibDebugOutput: true,
        showPerformance: true,
        modProgressOut: (VRamMod mod) {
          // Update modVramInfo with each mod's progress
          final updatedModVramInfo = {
            ...state.modVramInfo,
            mod.info.smolId: mod
          };
          state = state.copyWith(
            modVramInfo: updatedModVramInfo,
          );

          update(
            (state) => state.copyWith(
              modVramInfo: updatedModVramInfo,
              lastUpdated: DateTime.now(),
            ),
          );
        },
        debugOut: Fimber.d,
        verboseOut: (String message) => Fimber.v(() => message),
        isCancelled: () => state.isCancelled,
      ).check();

      final modVramInfo = info.fold<Map<String, VRamMod>>(
        state.modVramInfo,
        (previousValue, element) =>
            previousValue..[element.info.smolId] = element,
      );

      update(
        (state) => state.copyWith(
          modVramInfo: modVramInfo,
          isScanning: false,
          isCancelled: false,
        ),
      );
    } catch (e) {
      Fimber.w('Error scanning for VRAM usage: $e');
      // Optionally, set an error state
      update(
        (state) => state.copyWith(
          isScanning: false,
          isCancelled: false,
        ),
      );
    }
  }

  void cancelEstimation() {
    state = state.copyWith(isCancelled: true);
  }
}

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

  GraphType graphType = GraphType.bar;
  RangeValues? selectedSliderValues;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final vramState = ref.watch(AppState.vramEstimatorProvider);
    final isScanning = vramState.isScanning;
    final modVramInfo = vramState.modVramInfo;
    final graphicsLibConfig = ref.watch(graphicsLibConfigProvider);

    var modVramInfoToShow =
        _calculateModsToShow(modVramInfo, graphicsLibConfig);
    var rangeMax = _maxRange(modVramInfo, graphicsLibConfig);

    var showRangeSlider = selectedSliderValues != null &&
        !isScanning &&
        modVramInfoToShow.isNotEmpty;

    return Column(children: <Widget>[
      Row(
        children: [
          Disable(
            isEnabled: !isScanning,
            child: SpinningRefreshFAB(
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
              padding: const EdgeInsets.only(left: 16.0),
              child: OutlinedButton.icon(
                onPressed: () => ref
                    .read(AppState.vramEstimatorProvider.notifier)
                    .cancelEstimation(),
                label: Text(vramState.isCancelled ? 'Canceling...' : 'Cancel'),
                icon: const Icon(Icons.cancel),
              ),
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
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Disable(
              isEnabled: modVramInfoToShow.isNotEmpty,
              child: Card.outlined(
                child: SizedBox(
                  width: 300,
                  child:
                      GraphTypeSelector(onGraphTypeChanged: (GraphType type) {
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
                Text(0.bytesAsReadableMB(),
                    style: Theme.of(context).textTheme.labelLarge),
                Expanded(
                  child: RangeSlider(
                    values: selectedSliderValues?.let((it) => RangeValues(
                            it.start.coerceAtLeast(0),
                            it.end.coerceAtMost(rangeMax))) ??
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
                Text(rangeMax.bytesAsReadableMB(),
                    style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
        ),
    ]);
  }

  List<VRamMod> _calculateModsToShow(
      Map<String, VRamMod> modVramInfo, GraphicsLibConfig? graphicsLibConfig) {
    return modVramInfo.values
        .where((mod) =>
            mod.bytesUsingGraphicsLibConfig(graphicsLibConfig) >=
                (selectedSliderValues?.start ?? 0) &&
            mod.bytesUsingGraphicsLibConfig(graphicsLibConfig) <=
                (selectedSliderValues?.end ??
                    _maxRange(modVramInfo, graphicsLibConfig)))
        .sortedByDescending<num>(
            (mod) => mod.bytesUsingGraphicsLibConfig(graphicsLibConfig))
        .toList();
  }

  double _maxRange(
      Map<String, VRamMod> modVramInfo, GraphicsLibConfig? graphicsLibConfig) {
    return modVramInfo.values
            .sortedBy<num>(
                (mod) => mod.bytesUsingGraphicsLibConfig(graphicsLibConfig))
            .lastOrNull
            ?.bytesUsingGraphicsLibConfig(graphicsLibConfig)
            .toDouble() ??
        2;
  }
}
