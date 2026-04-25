import 'dart:async';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
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

  // File-level progress within the mod currently being scanned. Both zero
  // when no scan is running or when the selector hasn't yet produced its
  // asset list for a new mod.
  int currentModFilesScanned;
  int currentModTotalFiles;

  // Mod-relative path of the asset whose completion most recently ticked
  // the file counter. Not authoritative — reads run concurrently — but
  // useful as a live activity indicator. Null when no file has been read
  // yet for the current mod, or when no scan is running.
  String? currentlyScanningFilePath;

  VramEstimatorManagerState({
    required this.modVramInfo,
    required this.lastUpdated,
    this.isScanning = false,
    this.isCancelled = false,
    this.currentlyScanningModName,
    this.totalModsToScan = 0,
    this.modsScannedThisRun = 0,
    this.currentModFilesScanned = 0,
    this.currentModTotalFiles = 0,
    this.currentlyScanningFilePath,
  });

  factory VramEstimatorManagerState.initial() {
    return VramEstimatorManagerState(modVramInfo: {}, lastUpdated: null);
  }
}

class VramEstimatorManager
    extends GenericAsyncSettingsManager<VramEstimatorManagerState> {
  static const String _legacyJsonFileName = "TriOS-VRAM_CheckerCache.json";
  static const String _legacyJsonBackupFileName =
      "TriOS-VRAM_CheckerCache.json_backup.bak";
  // The pre-per-selector single msgpack cache filename. Migrated into the
  // active selector's per-selector file on first launch after upgrade.
  static const String _legacyMsgpackFileName = "TriOS-VRAM_CheckerCache.mp";
  static const String _legacyMsgpackBackupFileName =
      "TriOS-VRAM_CheckerCache.mp_backup.bak";

  bool _legacyCleanupAttempted = false;

  // The selector whose cache file this manager currently reads/writes. The
  // filename interpolates this value, so [setActiveSelector] effectively
  // swaps the underlying file.
  String _activeSelectorId = 'folder-scan';

  String get activeSelectorId => _activeSelectorId;

  @override
  FileFormat get fileFormat => FileFormat.msgpack;

  @override
  String get fileName => "TriOS-VRAM_CheckerCache-$_activeSelectorId.mp";

  // Large payload — coalesce the burst of per-mod progress updates during a
  // scan into a single write after the scan settles.
  @override
  Duration get debounceDuration => const Duration(seconds: 10);

  /// Point this manager at a different selector's cache file. Clears the
  /// in-memory cached value and resolved file handle so the next [read]
  /// loads from the new path on disk. Intended to be called while no scan
  /// is in flight; callers are responsible for awaiting cancellation and
  /// draining pending writes first.
  void setActiveSelector(String selectorId) {
    if (selectorId == _activeSelectorId) return;
    _activeSelectorId = selectorId;
    settingsFile = File("");
    lastKnownValue = null;
  }

  @override
  Future<Directory> getConfigDataFolderPath() async {
    final dir = Constants.cacheDirPath;
    await cleanupLegacyCachesOnce(dir);
    return dir;
  }

  /// Runs once per manager lifetime. Removes the legacy JSON cache (from
  /// before the msgpack switch) and migrates the legacy single-file
  /// msgpack cache into the per-selector filename for the currently
  /// active selector.
  Future<void> cleanupLegacyCachesOnce(Directory dir) async {
    if (_legacyCleanupAttempted) return;
    _legacyCleanupAttempted = true;

    // Phase 1: delete legacy JSON cache + its backup (pre-msgpack era).
    final legacyJson = File(p.join(dir.path, _legacyJsonFileName));
    final legacyJsonBackup = File(
      p.join(dir.path, _legacyJsonBackupFileName),
    );
    var deletedAny = false;
    for (final f in [legacyJson, legacyJsonBackup]) {
      try {
        if (await f.exists()) {
          await f.delete();
          deletedAny = true;
        }
      } catch (e, st) {
        Fimber.w(
          "Failed to delete legacy VRAM JSON cache ${f.path}: $e",
          ex: e,
          stacktrace: st,
        );
      }
    }
    if (deletedAny) {
      Fimber.i("Removed legacy VRAM JSON cache from ${dir.path}");
    }

    // Phase 2: migrate legacy single-file msgpack cache into the active
    // selector's per-selector filename. The legacy file was authoritative
    // for *whichever* selector was active at the time of the last write;
    // we assume that's the same selector active now (best approximation
    // with no metadata).
    final legacyMp = File(p.join(dir.path, _legacyMsgpackFileName));
    final legacyMpBackup = File(
      p.join(dir.path, _legacyMsgpackBackupFileName),
    );
    try {
      if (await legacyMp.exists()) {
        final target = File(
          p.join(dir.path, "TriOS-VRAM_CheckerCache-$_activeSelectorId.mp"),
        );
        if (await target.exists()) {
          // Per-selector file wins — user already moved past the legacy
          // layout. Discard the legacy file.
          await legacyMp.delete();
          Fimber.i(
            "Discarded legacy VRAM msgpack cache (per-selector file already present)",
          );
        } else {
          await legacyMp.rename(target.path);
          Fimber.i(
            "Migrated legacy VRAM msgpack cache into ${target.path}",
          );
        }
      }
    } catch (e, st) {
      Fimber.w(
        "Failed to migrate legacy VRAM msgpack cache ${legacyMp.path}: $e",
        ex: e,
        stacktrace: st,
      );
    }
    // Legacy backup is never needed post-migration.
    try {
      if (await legacyMpBackup.exists()) {
        await legacyMpBackup.delete();
      }
    } catch (e, st) {
      Fimber.w(
        "Failed to delete legacy VRAM msgpack backup ${legacyMpBackup.path}: $e",
        ex: e,
        stacktrace: st,
      );
    }
  }

  @override
  VramEstimatorManagerState Function(Map<String, dynamic> map) get fromMap =>
      (map) {
        final loaded = VramEstimatorManagerStateMapper.fromMap(map);
        loaded.isScanning = false;
        loaded.isCancelled = false;
        loaded.currentlyScanningModName = null;
        loaded.totalModsToScan = 0;
        loaded.modsScannedThisRun = 0;
        loaded.currentModFilesScanned = 0;
        loaded.currentModTotalFiles = 0;
        loaded.currentlyScanningFilePath = null;
        return loaded;
      };

  @override
  Map<String, dynamic> Function(VramEstimatorManagerState obj) get toMap =>
      (obj) => obj.toMap();

  /// Writes the given state to [target] as pretty-printed JSON (the same
  /// shape as the msgpack cache, just in text form). Writes atomically via
  /// a sibling `.tmp` + rename so a partial write never leaves a truncated
  /// file at [target].
  Future<void> exportAsJson(
    VramEstimatorManagerState state,
    File target,
  ) async {
    final json = toMap(state).prettyPrintJson();
    final tempFile = File('${target.path}.tmp');
    await tempFile.writeAsString(json, flush: true);
    await tempFile.rename(target.path);
  }
}

String _cacheKey(String selectorId, ReferencedAssetsSelectorConfig config) {
  if (selectorId == 'referenced') {
    return 'referenced:${config.cacheHash}';
  }
  return selectorId;
}

class VramEstimatorNotifier
    extends GenericSettingsAsyncNotifier<VramEstimatorManagerState> {
  // Tracks the (selectorId, configHash) pair whose result is currently in
  // [state.modVramInfo], for detecting in-session invalidation on config
  // changes. Disk persistence is keyed by selector id alone (two files
  // total); this in-memory key also includes the config hash so we can
  // notice when the referenced config changes and trigger a rescan.
  String? _activeCacheKey;

  // Completes when the in-flight scan's [startEstimating] call returns
  // (success or error). Used by [onSelectorOrConfigChanged] to wait for a
  // cancelled scan to unwind before swapping the underlying cache file.
  Completer<void>? _scanCompleter;

  // Scan-time progress is buffered and flushed to Riverpod state at most
  // every [_chartFlushInterval]. Without this, a 50-mod scan triggers 50
  // full rebuilds of the VRAM page, each of which re-sorts the entire mod
  // list — the "left half" of the flame chart before this change.
  static const _chartFlushInterval = Duration(milliseconds: 250);
  final Map<String, VramMod> _pendingScanResults = {};
  String? _pendingScanningModName;
  int _pendingScanCount = 0;
  // Sentinel-less: track "has a pending update" via booleans so a 0 value
  // can be distinguished from "no update pending."
  int _pendingCurrentModFilesScanned = 0;
  int _pendingCurrentModTotalFiles = 0;
  String? _pendingCurrentlyScanningFilePath;
  bool _pendingFileProgressDirty = false;
  Timer? _chartFlushTimer;

  @override
  Future<VramEstimatorManagerState> build() async {
    ref.onDispose(_resetScanBuffer);
    // The base [build] resolves the settings file using the manager's
    // [fileName] at that moment — which defaults to the folder-scan
    // selector. Set the active selector from persisted settings *before*
    // the first read so app launch lands on the correct cache file.
    final initialSelector = ref.read(appSettings).vramEstimatorSelectorId;
    (settingsManager as VramEstimatorManager).setActiveSelector(
      initialSelector,
    );
    _activeCacheKey = _cacheKey(
      initialSelector,
      ref.read(appSettings).referencedAssetsSelectorConfig,
    );
    return super.build();
  }

  void _resetScanBuffer() {
    _chartFlushTimer?.cancel();
    _chartFlushTimer = null;
    _pendingScanResults.clear();
    _pendingScanCount = 0;
    _pendingScanningModName = null;
    _pendingCurrentModFilesScanned = 0;
    _pendingCurrentModTotalFiles = 0;
    _pendingCurrentlyScanningFilePath = null;
    _pendingFileProgressDirty = false;
  }

  void _scheduleChartFlush() {
    if (_chartFlushTimer?.isActive ?? false) return;
    _chartFlushTimer = Timer(_chartFlushInterval, _flushPendingToState);
  }

  Future<void> _flushPendingToState() async {
    _chartFlushTimer?.cancel();
    _chartFlushTimer = null;
    if (_pendingScanResults.isEmpty &&
        _pendingScanCount == 0 &&
        _pendingScanningModName == null &&
        !_pendingFileProgressDirty) {
      return;
    }
    final pendingMods = Map.of(_pendingScanResults);
    final pendingCount = _pendingScanCount;
    final pendingName = _pendingScanningModName;
    final pendingFilesScanned = _pendingCurrentModFilesScanned;
    final pendingTotalFiles = _pendingCurrentModTotalFiles;
    final pendingFilePath = _pendingCurrentlyScanningFilePath;
    final fileProgressDirty = _pendingFileProgressDirty;
    _pendingScanResults.clear();
    _pendingScanCount = 0;
    _pendingScanningModName = null;
    _pendingFileProgressDirty = false;

    await updateState(
      (s) {
        final merged = pendingMods.isEmpty
            ? s.modVramInfo
            : {...s.modVramInfo, ...pendingMods};
        final next = s.copyWith(
          modVramInfo: merged,
          lastUpdated: pendingMods.isNotEmpty ? DateTime.now() : s.lastUpdated,
        )
          ..modsScannedThisRun = s.modsScannedThisRun + pendingCount
          ..currentlyScanningModName =
              pendingName ?? s.currentlyScanningModName;
        if (fileProgressDirty) {
          next.currentModFilesScanned = pendingFilesScanned;
          next.currentModTotalFiles = pendingTotalFiles;
          next.currentlyScanningFilePath = pendingFilePath;
        }
        return next;
      },
      // We already know there's pending work, so the structural hash of
      // the full VRAM state would just be burnt CPU — skip it.
      skipChangeCheck: true,
    );
  }

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

    // Old and new selector ids. The id determines which cache *file* we
    // read/write; the config affects only in-session invalidation.
    final oldSelectorId = _selectorIdOfKey(_activeCacheKey);
    final newSelectorId = active.selectorId;
    final selectorIdChanged = oldSelectorId != newSelectorId;

    // If a scan is running, cancel it and wait for [startEstimating] to
    // unwind before touching the cache file. Prevents a late scan-complete
    // from landing in the wrong selector's file.
    if (state.value?.isScanning == true) {
      cancelEstimation();
      final completer = _scanCompleter;
      if (completer != null && !completer.isCompleted) {
        await completer.future;
      }
    }

    _activeCacheKey = newKey;

    final manager = settingsManager as VramEstimatorManager;

    if (!selectorIdChanged) {
      // Same selector, different referenced config. Invalidate the
      // in-memory cache and rescan; the on-disk file will be overwritten
      // at scan end.
      updateState(
        (s) =>
            s.copyWith(modVramInfo: <String, VramMod>{})..isScanning = false,
        skipChangeCheck: true,
      );
      await startEstimating();
      return;
    }

    // Selector id changed — drain any pending write for the old selector
    // before swapping the manager's filename, then load the new file.
    await manager.waitForPendingWrites();
    manager.setActiveSelector(newSelectorId);

    VramEstimatorManagerState loaded;
    try {
      loaded = await manager.read(
        createDefaultState(),
        forceLoadFromDisk: true,
      );
    } catch (e, st) {
      Fimber.w(
        'Failed to load VRAM cache for $newSelectorId: $e',
        ex: e,
        stacktrace: st,
      );
      loaded = createDefaultState();
    }

    final hasCachedData = loaded.modVramInfo.isNotEmpty;
    updateState(
      (s) => loaded
        ..isScanning = false
        ..isCancelled = false,
      skipChangeCheck: true,
    );

    if (!hasCachedData) {
      await startEstimating();
    }
  }

  String? _selectorIdOfKey(String? cacheKey) {
    if (cacheKey == null) return null;
    final colon = cacheKey.indexOf(':');
    return colon == -1 ? cacheKey : cacheKey.substring(0, colon);
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
    // Keep the manager's file target in sync with the active selector in
    // case settings changed without flowing through [onSelectorOrConfigChanged].
    (settingsManager as VramEstimatorManager).setActiveSelector(
      active.selectorId,
    );
    final selector = resolveSelector(active.selectorId, active.config);

    // Signal that a scan is in flight. [onSelectorOrConfigChanged] awaits
    // this completer when a mid-scan selector swap is requested.
    _scanCompleter = Completer<void>();

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
      skipChangeCheck: true,
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
          _pendingScanningModName = checkerMod.name ?? checkerMod.modId;
          // Zero the per-mod file counter and clear the last-file path
          // immediately so the UI doesn't keep showing the previous mod's
          // final state during the selector/parse prelude for the next mod.
          _pendingCurrentModFilesScanned = 0;
          _pendingCurrentModTotalFiles = 0;
          _pendingCurrentlyScanningFilePath = null;
          _pendingFileProgressDirty = true;
          _scheduleChartFlush();
        },
        onFileProgress: (processed, total, path) {
          _pendingCurrentModFilesScanned = processed;
          _pendingCurrentModTotalFiles = total;
          _pendingCurrentlyScanningFilePath = path;
          _pendingFileProgressDirty = true;
          _scheduleChartFlush();
        },
        modProgressOut: (VramMod mod) {
          _pendingScanResults[mod.info.smolId] = mod;
          _pendingScanCount++;
          _scheduleChartFlush();
        },
        debugOut: Fimber.d,
        verboseOut: (String message) => Fimber.v(() => message),
        isCancelled: () => state.value?.isCancelled ?? false,
      ).check();

      // `info` is the authoritative list of successful scans — drop any
      // buffered mods rather than merging, so we don't re-apply duplicates.
      _resetScanBuffer();

      final modVramInfo = info.fold<Map<String, VramMod>>(
        state.requireValue.modVramInfo,
        (previousValue, element) =>
            previousValue..[element.info.smolId] = element,
      );

      updateState(
        (state) => state.copyWith(modVramInfo: modVramInfo)
          ..isScanning = false
          ..isCancelled = false
          ..currentlyScanningModName = null
          ..currentModFilesScanned = 0
          ..currentModTotalFiles = 0
          ..currentlyScanningFilePath = null,
        skipChangeCheck: true,
      );
    } catch (e) {
      Fimber.w('Error scanning for VRAM usage: $e');
      // Surface any buffered progress before resetting the scanning flag,
      // so users see what got through before the error.
      await _flushPendingToState();
      updateState(
        (state) => state
          ..isScanning = false
          ..isCancelled = false
          ..currentlyScanningModName = null
          ..currentModFilesScanned = 0
          ..currentModTotalFiles = 0
          ..currentlyScanningFilePath = null,
        skipChangeCheck: true,
      );
    } finally {
      final completer = _scanCompleter;
      _scanCompleter = null;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    }
  }

  /// Returns the enabled-or-highest-version variants whose smolId is not
  /// currently in the cache — i.e. the mods a "scan only unscanned" action
  /// would process. Computed from the current Riverpod snapshot, no I/O.
  List<ModVariant> unscannedVariants() {
    final current = state.value;
    if (current == null) return const [];
    final scannedIds = current.modVramInfo.keys.toSet();
    return ref
        .read(AppState.mods)
        .map((mod) => mod.findFirstEnabledOrHighestVersion)
        .nonNulls
        .where((v) => !scannedIds.contains(v.smolId))
        .toList();
  }

  /// Scans only the mods whose smolId is not already in the VRAM cache.
  /// No-op when every mod has a cache entry or when a scan is already in
  /// flight.
  Future<void> scanUnscanned() async {
    if (state.value?.isScanning == true) return;
    final variants = unscannedVariants();
    if (variants.isEmpty) return;
    await startEstimating(variantsToCheck: variants);
  }

  Future<void> refresh({List<ModVariant>? variantsToCheck}) async {
    _resetScanBuffer();
    _activeCacheKey = null;
    updateState(
      (s) => s.copyWith(modVramInfo: <String, VramMod>{}),
      skipChangeCheck: true,
    );
    await startEstimating(variantsToCheck: variantsToCheck);
  }

  void cancelEstimation() {
    updateState((s) => s..isCancelled = true, skipChangeCheck: true);
  }

  /// Exports the current in-memory cache state to [target] as
  /// pretty-printed JSON. Does not touch the on-disk `.mp` cache.
  Future<void> exportAsJson(File target) async {
    final current = state.value;
    if (current == null) {
      throw StateError('VRAM cache is not loaded yet.');
    }
    final manager = settingsManager as VramEstimatorManager;
    await manager.exportAsJson(current, target);
  }
}
