import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/generic_settings_manager.dart';
import 'package:trios/utils/generic_settings_notifier.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/vram_estimator/selectors/referenced_assets_selector_config.dart';
import 'package:trios/vram_estimator/selectors/selector_registry.dart';
import 'package:trios/vram_estimator/vram_checker_logic.dart';

import '../models/mod_variant.dart';
import 'graphics_lib_config_provider.dart';
import 'models/graphics_lib_config.dart';
import 'models/vram_checker_models.dart';

part 'vram_estimator_manager.mapper.dart';

@MappableClass()
class VramEstimatorManagerState with VramEstimatorManagerStateMappable {
  final Map<String, VramMod> modVramInfo;

  // Transient scan state. dart_mappable serializes these, but [fromMap]
  // resets them so a mid-scan crash can't leave the UI stuck on "scanning".
  bool isScanning;
  bool isCancelled;

  final DateTime? lastUpdated;
  String? currentlyScanningModName;
  int totalModsToScan;
  int modsScannedThisRun;

  VramEstimatorManagerState({
    required this.modVramInfo,
    required this.lastUpdated,
    this.isScanning = false,
    this.isCancelled = false,
    this.currentlyScanningModName,
    this.totalModsToScan = 0,
    this.modsScannedThisRun = 0,
  });

  factory VramEstimatorManagerState.initial() {
    return VramEstimatorManagerState(modVramInfo: {}, lastUpdated: null);
  }
}

class VramEstimatorManager
    extends GenericAsyncSettingsManager<VramEstimatorManagerState> {
  @override
  FileFormat get fileFormat => FileFormat.json;

  @override
  String get fileName => "TriOS-VRAM_CheckerCache.json";

  @override
  Future<Directory> getConfigDataFolderPath() =>
      Future.value(Constants.cacheDirPath);

  @override
  VramEstimatorManagerState Function(Map<String, dynamic> map) get fromMap =>
      (map) {
        final loaded = VramEstimatorManagerStateMapper.fromMap(map);
        loaded.isScanning = false;
        loaded.isCancelled = false;
        loaded.currentlyScanningModName = null;
        loaded.totalModsToScan = 0;
        loaded.modsScannedThisRun = 0;
        return loaded;
      };

  @override
  Map<String, dynamic> Function(VramEstimatorManagerState obj) get toMap =>
      (obj) => obj.toMap();
}

String _cacheKey(String selectorId, ReferencedAssetsSelectorConfig config) {
  if (selectorId == 'referenced') {
    return 'referenced:${config.cacheHash}';
  }
  return selectorId;
}

class VramEstimatorNotifier
    extends GenericSettingsAsyncNotifier<VramEstimatorManagerState> {
  // In-memory cache of scan results per (selectorId, configHash). Lost on
  // app restart; survives selector/config toggles within a session.
  final Map<String, Map<String, VramMod>> _perKeyCache = {};
  String? _activeCacheKey;

  @override
  GenericAsyncSettingsManager<VramEstimatorManagerState>
  createSettingsManager() => VramEstimatorManager();

  @override
  VramEstimatorManagerState createDefaultState() =>
      VramEstimatorManagerState.initial();

  ({String selectorId, ReferencedAssetsSelectorConfig config})
  _readActiveSelector() {
    final settings = ref.read(appSettings);
    return (
      selectorId: settings.vramEstimatorSelectorId,
      config: settings.referencedAssetsSelectorConfig,
    );
  }

  Future<void> onSelectorOrConfigChanged() async {
    final active = _readActiveSelector();
    final newKey = _cacheKey(active.selectorId, active.config);
    if (newKey == _activeCacheKey) return;

    if (_activeCacheKey != null && state.value != null) {
      _perKeyCache[_activeCacheKey!] = Map.from(state.requireValue.modVramInfo);
    }

    final cached = _perKeyCache[newKey];
    _activeCacheKey = newKey;

    if (cached != null) {
      updateState(
        (s) => s.copyWith(modVramInfo: Map.from(cached))..isScanning = false,
      );
    } else {
      updateState(
        (s) => s.copyWith(modVramInfo: <String, VramMod>{})..isScanning = false,
      );
      await startEstimating();
    }
  }

  Future<void> startEstimating({List<ModVariant>? variantsToCheck}) async {
    if (state.value?.isScanning == true) return;

    var modsFolder = ref.read(AppState.modsFolder).value;
    if (modsFolder == null || !modsFolder.existsSync()) {
      Fimber.e('Mods folder not set');
      return;
    }

    final active = _readActiveSelector();
    final activeKey = _cacheKey(active.selectorId, active.config);
    _activeCacheKey = activeKey;
    final selector = resolveSelector(active.selectorId, active.config);

    final resolvedVariants =
        variantsToCheck ??
        ref
            .read(AppState.mods)
            .map((mod) => mod.findFirstEnabledOrHighestVersion)
            .nonNulls
            .toList();

    updateState(
      (s) => s.copyWith()
        ..isScanning = true
        ..isCancelled = false
        ..totalModsToScan = resolvedVariants.length
        ..modsScannedThisRun = 0
        ..currentlyScanningModName = null,
    );

    try {
      final info = await VramChecker(
        enabledModIds: ref.read(AppState.enabledModIds).value,
        variantsToCheck: resolvedVariants,
        graphicsLibConfig:
            ref.read(graphicsLibConfigProvider) ?? GraphicsLibConfig.disabled,
        showCountedFiles: true,
        showSkippedFiles: true,
        showGfxLibDebugOutput: true,
        showPerformance: true,
        selector: selector,
        onModStart: (checkerMod) {
          updateState(
            (s) => s.copyWith()
              ..currentlyScanningModName =
                  checkerMod.name ?? checkerMod.modId,
          );
        },
        modProgressOut: (VramMod mod) {
          final updatedModVramInfo = {
            ...state.requireValue.modVramInfo,
            mod.info.smolId: mod,
          };
          updateState(
            (state) => state.copyWith(
              modVramInfo: updatedModVramInfo,
              lastUpdated: DateTime.now(),
            )..modsScannedThisRun = state.modsScannedThisRun + 1,
          );
        },
        debugOut: Fimber.d,
        verboseOut: (String message) => Fimber.v(() => message),
        isCancelled: () => state.value?.isCancelled ?? false,
      ).check();

      final modVramInfo = info.fold<Map<String, VramMod>>(
        state.requireValue.modVramInfo,
        (previousValue, element) =>
            previousValue..[element.info.smolId] = element,
      );

      _perKeyCache[activeKey] = Map.from(modVramInfo);

      updateState(
        (state) => state.copyWith(modVramInfo: modVramInfo)
          ..isScanning = false
          ..isCancelled = false
          ..currentlyScanningModName = null,
      );
    } catch (e) {
      Fimber.w('Error scanning for VRAM usage: $e');
      updateState(
        (state) => state
          ..isScanning = false
          ..isCancelled = false
          ..currentlyScanningModName = null,
      );
    }
  }

  Future<void> refresh({List<ModVariant>? variantsToCheck}) async {
    _perKeyCache.clear();
    _activeCacheKey = null;
    updateState(
      (s) => s.copyWith(modVramInfo: <String, VramMod>{}),
    );
    await startEstimating(variantsToCheck: variantsToCheck);
  }

  void cancelEstimation() {
    updateState((s) => s..isCancelled = true);
  }
}
