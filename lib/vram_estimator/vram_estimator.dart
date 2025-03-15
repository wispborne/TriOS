import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/vram_checker_logic.dart';

import '../models/mod_variant.dart';
import 'graphics_lib_config_provider.dart';
import 'models/graphics_lib_config.dart';
import 'models/vram_checker_models.dart';

part 'vram_estimator.mapper.dart';

@MappableClass()
class VramEstimatorState with VramEstimatorStateMappable {
  /// SmolId to [VramMod] mapping.
  final Map<String, VramMod> modVramInfo;
  bool isScanning = false;
  bool isCancelled = false;
  final DateTime? lastUpdated;

  VramEstimatorState({required this.modVramInfo, required this.lastUpdated});

  factory VramEstimatorState.initial() {
    return VramEstimatorState(modVramInfo: {}, lastUpdated: null);
  }
}

class VramEstimatorManager
    extends GenericAsyncSettingsManager<VramEstimatorState> {
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
    extends GenericSettingsAsyncNotifier<VramEstimatorState> {
  @override
  GenericAsyncSettingsManager<VramEstimatorState> createSettingsManager() =>
      VramEstimatorManager();

  @override
  VramEstimatorState createDefaultState() => VramEstimatorState.initial();

  Future<void> startEstimating({List<ModVariant>? variantsToCheck}) async {
    if (state.valueOrNull?.isScanning == true) return;

    var settings = ref.read(appSettings);
    if (settings.modsDir == null || !settings.modsDir!.existsSync()) {
      Fimber.e('Mods folder not set');
      // Optionally, you can set an error state here
      return;
    }

    updateState(
      (s) =>
          s.copyWith()
            ..isScanning = true
            ..isCancelled = false,
    );

    try {
      final info =
          await VramChecker(
            enabledModIds: ref.read(AppState.enabledModIds).value,
            variantsToCheck:
                variantsToCheck ??
                ref
                    .read(AppState.mods)
                    .map((mod) => mod.findFirstEnabledOrHighestVersion)
                    .nonNulls
                    .toList(),
            graphicsLibConfig:
                ref.read(graphicsLibConfigProvider) ??
                GraphicsLibConfig.disabled,
            showCountedFiles: true,
            showSkippedFiles: true,
            showGfxLibDebugOutput: true,
            showPerformance: true,
            modProgressOut: (VramMod mod) {
              // Update modVramInfo with each mod's progress
              final updatedModVramInfo = {
                ...state.requireValue.modVramInfo,
                mod.info.smolId: mod,
              };
              updateState(
                (state) => state.copyWith(
                  modVramInfo: updatedModVramInfo,
                  lastUpdated: DateTime.now(),
                ),
              );
            },
            debugOut: Fimber.d,
            verboseOut: (String message) => Fimber.v(() => message),
            isCancelled: () => state.valueOrNull?.isCancelled ?? false,
          ).check();

      final modVramInfo = info.fold<Map<String, VramMod>>(
        state.requireValue.modVramInfo,
        (previousValue, element) =>
            previousValue..[element.info.smolId] = element,
      );

      updateState(
        (state) =>
            state.copyWith(modVramInfo: modVramInfo)
              ..isScanning = false
              ..isCancelled = false,
      );
    } catch (e) {
      Fimber.w('Error scanning for VRAM usage: $e');
      // Optionally, set an error state
      updateState(
        (state) =>
            state
              ..isScanning = false
              ..isCancelled = false,
      );
    }
  }

  void cancelEstimation() {
    updateState((s) => s..isCancelled = true);
  }
}