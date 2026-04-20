import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:trios/changelogs/mod_changelogs_manager.dart';
import 'package:trios/compression/archive.dart';
import 'package:trios/vmparams/vmparams_manager.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/result.dart';
import 'package:trios/portraits/portrait_metadata.dart';
import 'package:trios/portraits/portrait_metadata_manager.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/portraits/portrait_replacements_manager.dart';
import 'package:trios/portraits/portraits_manager.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/tips/tip.dart';
import 'package:trios/tips/tips_notifier.dart';
import 'package:trios/trios/navigation_request.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/trios/process_detection/jps_process_detector.dart';
import 'package:trios/trios/process_detection/process_detection_diagnostics.dart';
import 'package:trios/trios/process_detection/process_detector.dart';
import 'package:trios/trios/process_detection/unix_process_detector.dart';
import 'package:trios/trios/process_detection/win32_process_detector.dart';
import 'package:trios/trios/process_detection/wmic_process_detector.dart';
import 'package:trios/utils/platform_paths.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/vram_estimator/vram_estimator_manager.dart';

import '../mod_manager/audit_log.dart';
import '../mod_manager/version_checker.dart';
import '../models/enabled_mods.dart';
import '../models/mod.dart';
import 'data_cache/enabled_mods.dart';
import 'mod_metadata.dart';
import 'mod_variants.dart';

class AppState {
  static final isWindowFocused = StateProvider<bool>((ref) => true);
  static final selfUpdate =
      AsyncNotifierProvider<SelfUpdater, TriOSDownloadProgress?>(
        SelfUpdater.new,
      );
  static final appContext = StateProvider<BuildContext?>((ref) => null);

  /// Set this to programmatically navigate to a page, optionally highlighting a widget.
  static final navigationRequest =
      StateProvider<NavigationRequest?>((ref) => null);

  /// One-shot request to filter a viewer page by mod name.
  /// Set before navigating; the target page reads it, applies the filter, then clears it.
  static final viewerFilterRequest =
      StateProvider<ViewerFilterRequest?>((ref) => null);

  /// The highlight key of the widget to highlight on the current page.
  static final activeHighlightKey = StateProvider<String?>((ref) => null);

  /// Master list of all mod variants found in the mods folder.
  static final modVariants =
      AsyncNotifierProvider<ModVariantsNotifier, List<ModVariant>>(
        ModVariantsNotifier.new,
      );

  /// String is the smolId
  static final versionCheckResults =
      AsyncNotifierProvider<VersionCheckerAsyncProvider, VersionCheckerState>(
        VersionCheckerAsyncProvider.new,
      );

  static var skipCacheOnNextVersionCheck = false;

  static List<Mod> getModsFromVariants(
    List<ModVariant> modVariants,
    List<String> enabledMods,
  ) {
    return modVariants
        .groupBy((ModVariant variant) => variant.modInfo.id)
        .entries
        .map((entry) {
          return Mod(
            id: entry.key,
            isEnabledInGame: enabledMods.contains(entry.key),
            modVariants: entry.value.toList(),
          );
        })
        .toList();
  }

  /// Provides a list of [ModTip].
  static final tipsProvider = AsyncNotifierProvider<TipsNotifier, List<ModTip>>(
    TipsNotifier.new,
  );

  /// Provides a list of [ModChangelog]s.
  /// The keys are mod ids, not smol ids.
  static final changelogsProvider =
      AsyncNotifierProvider<ModChangelogsManager, Map<String, ModChangelog>>(
        ModChangelogsManager.new,
      );

  /// Provides [ModMetadata]s, observable state.
  static final modsMetadata =
      AsyncNotifierProvider<ModMetadataStore, ModsMetadata>(
        ModMetadataStore.new,
      );

  static final themeData = AsyncNotifierProvider<ThemeManager, ThemeState>(
    ThemeManager.new,
  );

  /// Projection of [modVariants], grouping them by mod id.
  static final mods = Provider<List<Mod>>((ref) {
    // Fimber.d("Recalculating mods from variants.");
    final modVariants = ref.watch(AppState.modVariants).value ?? [];
    final enabledMods = ref
        .watch(AppState.enabledModIds)
        .value
        .orEmpty()
        .toList();
    final mods = getModsFromVariants(modVariants, enabledMods);
    return mods;
  });

  static final enabledModVariants = Provider<List<ModVariant>>((ref) {
    final mods = ref.watch(AppState.mods);
    return mods.map((mod) => mod.findFirstEnabled).nonNulls.toList()..sort();
  });

  /// Emits when a mod is added/removed, but not when it's changed (e.g. enabled/disabled)
  static final smolIds = Provider<List<String>>((ref) {
    final mods = ref.watch(AppState.modVariants).value ?? [];
    return mods.map((mod) => mod.smolId).toList()..sort();
  });

  static final modAudit = AsyncNotifierProvider<AuditLog, List<AuditEntry>>(
    AuditLog.new,
  );

  static final modCompatibility = Provider<Map<SmolId, DependencyCheck>>((ref) {
    final modVariants = ref.watch(AppState.modVariants).value ?? [];
    final gameVersion = ref.watch(AppState.starsectorVersion).value;
    final enabledMods = ref.watch(AppState.enabledModsFile).value;
    if (enabledMods == null) return {};

    return modVariants.map((variant) {
      final compatibility = compareGameVersions(
        variant.modInfo.gameVersion,
        gameVersion,
      );
      final dependencyCheckResult = variant.checkDependencies(
        modVariants,
        enabledMods.enabledMods.toList(),
        gameVersion,
      );
      return MapEntry(
        variant.smolId,
        DependencyCheck(compatibility, dependencyCheckResult),
      );
    }).toMap();
  });

  static final vramEstimatorProvider =
      AsyncNotifierProvider<VramEstimatorNotifier, VramEstimatorManagerState>(
        VramEstimatorNotifier.new,
      );

  static final enabledModsFile =
      AsyncNotifierProvider<EnabledModsNotifier, EnabledMods>(
        EnabledModsNotifier.new,
      );
  static final enabledModIds = FutureProvider<List<String>>(
    (ref) async => ref.watch(enabledModsFile).value?.enabledMods.toList() ?? [],
  );
  static final modsState = Provider<Map<String, ModState>>((ref) => {});

  static final portraits =
      AsyncNotifierProvider<
        PortraitsNotifier,
        Map<ModVariant?, List<Portrait>>
      >(PortraitsNotifier.new);

  /// Key is original portrait hash, value is replacement portrait
  static final portraitReplacementsManager =
      AsyncNotifierProvider<
        PortraitReplacementsNotifier,
        Map<String, SavedPortrait>
      >(() => PortraitReplacementsNotifier());

  /// Portrait metadata extracted from faction files.
  /// Key is relative portrait path, value is metadata (gender, factions).
  static final portraitMetadata =
      AsyncNotifierProvider<
        PortraitMetadataNotifier,
        Map<String, PortraitMetadata>
      >(PortraitMetadataNotifier.new);

  static final starsectorVersion = FutureProvider<String?>((ref) async {
    final gamePath = ref
        .watch(appSettings.select((value) => value.gameDir))
        ?.toDirectory();
    if (gamePath == null || gamePath.existsSync() == false) return null;
    final gameCorePath = ref.watch(gameCoreFolder).value;
    if (gameCorePath == null || gameCorePath.existsSync() == false) return null;

    try {
      final archive = ref.watch(archiveProvider).value;
      if (archive == null) return null;

      final trueVersion = await getStarsectorVersionFromObf(
        gameCorePath,
        archive,
      );
      if (trueVersion != null && trueVersion.isNotEmpty) {
        ref
            .read(appSettings.notifier)
            .update((s) => s.copyWith(lastStarsectorVersion: trueVersion));
        return trueVersion;
      }
    } catch (e, stack) {
      Fimber.e(
        "Failed to read starsector version from obf jar, falling back to log.",
        ex: e,
        stacktrace: stack,
      );
    }

    try {
      final versionInLog = await readStarsectorVersionFromLog(gamePath);
      if (versionInLog != null) {
        ref
            .read(appSettings.notifier)
            .update((s) => s.copyWith(lastStarsectorVersion: versionInLog));
        return versionInLog;
      } else {
        return ref.read(
          appSettings.select((value) => value.lastStarsectorVersion),
        );
      }
    } catch (e, stack) {
      Fimber.w(
        "Failed to read starsector version from log",
        ex: e,
        stacktrace: stack,
      );
      return ref.read(
        appSettings.select((value) => value.lastStarsectorVersion),
      );
    }
  });

  static final canWriteToModsFolder = FutureProvider<bool>((ref) async {
    final gamePath = ref
        .watch(appSettings.select((value) => value.gameDir))
        ?.toDirectory();
    if (gamePath == null) return false;

    final filesAndFolders = [
      ref.read(enabledModsFile).value?.enabledMods.toList(),
    ].nonNulls;
    for (final file in filesAndFolders) {
      if (filesAndFolders.isEmpty) {
        Fimber.d("Cannot find or write to: $file");
        return false;
      }
    }
    return true;
  });

  static final gameFolder = FutureProvider<Directory?>(
    (ref) async =>
        ref.watch(appSettings.select((value) => value.gameDir))?.toDirectory(),
  );

  static final modsFolder = FutureProvider<Directory?>((ref) async {
    // Compute the *effective* mods path based on settings,
    // and use that as the only dependency for this provider.
    final effectiveModsPath = ref.watch(
      appSettings.select((settings) {
        final useCustom = settings.hasCustomModsDir;
        final customModsDir = settings.modsDir;
        final gameDir = settings.gameDir;

        if (useCustom && customModsDir != null) {
          // Custom path
          return customModsDir.normalize.path;
        }

        // Non-custom path derived from gameDir
        if (gameDir == null) return null;
        return generateModsFolderPath(gameDir.toDirectory())?.normalize.path;
      }),
    );

    if (effectiveModsPath == null) return null;
    return Directory(effectiveModsPath);
  });

  static final savesFolder = FutureProvider<Directory?>((ref) async {
    final useCustomSavesPath = ref.watch(
      appSettings.select((value) => value.useCustomSavesPath),
    );

    if (useCustomSavesPath == true) {
      final customSavesPath = ref.watch(
        appSettings.select((value) => value.customSavesPath),
      );
      if (customSavesPath != null) {
        return customSavesPath.toDirectory();
      }
    } else {
      final gamePath = ref.watch(gameFolder).value;
      if (gamePath == null) return null;
      return generateSavesFolderPath(gamePath)?.toDirectory();
    }
    return null;
  });

  static final gameCoreFolder = FutureProvider<Directory?>((ref) async {
    final useCustomCoreFolderPath = ref.watch(
      appSettings.select((value) => value.useCustomCoreFolderPath),
    );

    if (useCustomCoreFolderPath == true) {
      final customCoreFolderPath = ref.watch(
        appSettings.select((value) => value.customCoreFolderPath),
      );
      if (customCoreFolderPath != null) {
        return customCoreFolderPath.toDirectory();
      }
    } else {
      final gamePath = ref.watch(gameFolder).value;
      if (gamePath == null) return null;
      return generateGameCorePath(gamePath)?.toDirectory();
    }
  });

  static final gameExecutable = FutureProvider<File?>((ref) async {
    try {
      final useCustomGameExePath = ref.watch(
        appSettings.select((value) => value.useCustomGameExePath),
      );
      if (useCustomGameExePath == true) {
        final customGameExePath = ref.watch(
          appSettings.select((value) => value.customGameExePath),
        );
        if (customGameExePath != null) {
          return File(customGameExePath);
        }
      }
    } catch (e) {
      Fimber.e("Error getting custom game executable", ex: e);
    }

    final gamePath = ref.watch(gameFolder).value?.toDirectory();
    if (gamePath == null) return null;

    return getDefaultGameExecutable(gamePath).toFile();
  });

  static final vmParamsFile = FutureProvider<File?>((ref) async {
    return ref
        .watch(vmparamsManagerProvider)
        .value
        ?.selectedVmparamsFiles
        .firstOrNull;
  });

  static final canWriteToStarsectorFolder = FutureProvider<bool>((ref) async {
    final selectedFiles =
        ref.watch(vmparamsManagerProvider).value?.selectedVmparamsFiles ?? [];
    if (selectedFiles.isEmpty) return false;
    for (var file in selectedFiles) {
      if (!file.existsSync() || await file.isNotWritable()) {
        Fimber.d("Cannot find or write to: $file");
        return false;
      }
    }
    return true;
  });

  static final isEnabledModsFileWritable = FutureProvider<bool>((ref) async {
    final modsPath = ref.watch(modsFolder).value;
    if (modsPath == null) return false;
    return ref.read(AppState.enabledModsFile.notifier).isWritable();
  });


  static final isGameRunning = FutureProvider<bool>(
    (ref) async =>
        ref.watch(_isGameRunning).value?.wasSuccessful ?? false,
  );

  static final gameRunningCheckError = FutureProvider<List<Exception>?>(
    (ref) async => ref.watch(_isGameRunning).value?.errors,
  );

  static final _isGameRunning =
      AsyncNotifierProvider<_GameRunningChecker, Result>(
        _GameRunningChecker.new,
      );

  static final processDetectionDiagnostics =
      StateProvider<ProcessDetectionDiagnostics?>((ref) => null);

  static final ignoringDrop = StateProvider<bool>((ref) => false);
}

class _GameRunningChecker extends AsyncNotifier<Result> {
  static const int period = 1500;
  int _generation = 0;
  late final List<ProcessDetector> _detectors;
  String? _lastMatchedDetectorName;
  List<String> _lastUsedDetectorNames = [];
  DateTime? _previousRunTime;
  StateController<ProcessDetectionDiagnostics?>? _diagnosticsController;

  @override
  Future<Result> build() async {
    final isSettingEnabled = ref.watch(
      appSettings.select((value) => value.checkIfGameIsRunning),
    );
    if (!isSettingEnabled) {
      return Result.unmitigatedFailure([]);
    }

    // Retrieve executable names for detectors that need them.
    final gameExecutables = [ref.watch(AppState.gameExecutable).value];
    final List<String> executableNames =
        gameExecutables
            .whereType<File>()
            .map((file) => file.path.split(Platform.pathSeparator).last)
            .toList();

    // Build the platform-specific detector chain.
    _detectors = _buildDetectorChain();

    // Cache the diagnostics controller before any async gap so that
    // _updateDiagnostics doesn't touch ref after an await — watched deps
    // could change mid-flight and invalidate the ref.
    _diagnosticsController = ref.read(
      AppState.processDetectionDiagnostics.notifier,
    );

    // Perform an initial check.
    final stopwatch = Stopwatch()..start();
    final result = await _runDetectors(executableNames);
    stopwatch.stop();
    _updateDiagnostics(result, stopwatch.elapsed);

    // Start the sequential polling loop.
    // Increment generation so any prior loop from a previous build() exits.
    final gen = ++_generation;
    _poll(executableNames, gen);

    ref.onDispose(() {
      _generation++;
    });

    return result;
  }

  List<ProcessDetector> _buildDetectorChain() {
    if (Platform.isWindows) {
      final gamePath = ref.read(AppState.gameFolder).value;
      return [
        if (gamePath != null)
          Win32ProcessDetector(getJreDir(gamePath)),
        WmicProcessDetector(),
      ];
    } else {
      return [
        UnixProcessDetector(),
        JpsProcessDetector('java'),
      ];
    }
  }

  Future<Result> _runDetectors(List<String> executableNames) async {
    final errors = <Exception>[];
    final usedNames = <String>[];
    _lastMatchedDetectorName = null;
    for (final detector in _detectors) {
      usedNames.add(detector.name);
      try {
        final result = await detector.isStarsectorRunning(executableNames);
        if (result != null) {
          _lastMatchedDetectorName = detector.name;
          _lastUsedDetectorNames = usedNames;
          return result;
        }
      } on Exception catch (e) {
        errors.add(e);
      }
    }
    _lastUsedDetectorNames = usedNames;
    return Result.unmitigatedFailure(errors);
  }

  void _updateDiagnostics(Result result, Duration elapsed) {
    final controller = _diagnosticsController;
    if (controller == null) return;
    try {
      final now = DateTime.now();
      final interval = _previousRunTime != null
          ? now.difference(_previousRunTime!)
          : null;
      _previousRunTime = now;
      controller.state = ProcessDetectionDiagnostics(
        detectorNames: _lastUsedDetectorNames,
        matchedDetectorName: _lastMatchedDetectorName,
        wasGameRunning: result.wasSuccessful,
        checkDuration: elapsed,
        timestamp: now,
        runInterval: interval,
        errors: result.errors,
      );
    } catch (e) {
      // Don't let diagnostics tracking break process detection.
      Fimber.w('Failed to update process detection diagnostics: $e');
    }
  }

  Future<void> _poll(List<String> executableNames, int gen) async {
    while (_generation == gen) {
      await Future.delayed(const Duration(milliseconds: period));
      if (_generation != gen) break;
      if (!ref.read(AppState.isWindowFocused)) continue;

      final stopwatch = Stopwatch()..start();
      final result = await _runDetectors(executableNames);
      stopwatch.stop();
      state = AsyncValue.data(result);
      _updateDiagnostics(result, stopwatch.elapsed);
    }
  }
}

var currentFileHandles = 0;
var maxFileHandles = 2000;

Future<T> withFileHandleLimit<T>(Future<T> Function() function) async {
  int attempts = 0;
  const maxAttempts = 50; // Maximum number of retry attempts
  const backoffMs = 100; // Initial backoff delay in milliseconds

  while (currentFileHandles + 1 > maxFileHandles) {
    if (attempts >= maxAttempts) {
      throw TimeoutException(
        'Exceeded maximum attempts waiting for file handles to free up',
      );
    }

    Fimber.v(
      () =>
          "Waiting for file handles to free up. Current file handles: $currentFileHandles",
    );

    // Exponential backoff with a max of 5 seconds
    final delay = Duration(
      milliseconds: min(backoffMs * pow(2, attempts).round(), 5000),
    );
    await Future.delayed(delay);
    attempts++;
  }

  currentFileHandles++;
  try {
    return await function();
  } finally {
    currentFileHandles--;
  }
}

enum ModState {
  disablingVariants,
  deletingVariants,
  enablingVariant,
  backingUpVariant,
}

extension ModDependencies on List<DependencyCheck?> {
  bool get isCompatibleWithGameVersion =>
      any((d) => d?.gameCompatibility != GameCompatibility.incompatible);

  GameCompatibility get leastSevereCompatibility =>
      reduce((a, b) {
        if (a == null) return b!;
        if (b == null) return a;
        return a.gameCompatibility.index < b.gameCompatibility.index ? a : b;
      })?.gameCompatibility ??
      GameCompatibility.incompatible;
}
