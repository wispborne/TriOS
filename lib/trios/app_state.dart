import 'dart:async';
import 'dart:io';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/changelogs/mod_changelogs_manager.dart';
import 'package:trios/compression/archive.dart';
import 'package:trios/jre_manager/jre_entry.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/portraits/portrait_replacements_manager.dart';
import 'package:trios/portraits/portraits_manager.dart';
import 'package:trios/themes/theme_manager.dart';
import 'package:trios/tips/tip.dart';
import 'package:trios/tips/tips_notifier.dart';
import 'package:trios/trios/self_updater/self_updater.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/platform_paths.dart';
import 'package:trios/utils/util.dart';
import 'package:trios/vram_estimator/vram_estimator_manager.dart';

import '../jre_manager/jre_manager_logic.dart';
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
  static final variantSmolIds = Provider<List<String>>((ref) {
    final mods = ref.watch(AppState.modVariants).valueOrNull ?? [];
    return mods.map((mod) => mod.smolId).toList()..sort();
  });

  static final modAudit = AsyncNotifierProvider<AuditLog, List<AuditEntry>>(
    AuditLog.new,
  );

  static final modCompatibility = Provider<Map<SmolId, DependencyCheck>>((ref) {
    final modVariants = ref.watch(AppState.modVariants).valueOrNull ?? [];
    final gameVersion = ref.watch(AppState.starsectorVersion).valueOrNull;
    final enabledMods = ref.watch(AppState.enabledModsFile).valueOrNull;
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
  static final starsectorVersion = FutureProvider<String?>((ref) async {
    final gamePath = ref
        .watch(appSettings.select((value) => value.gameDir))
        ?.toDirectory();
    if (gamePath == null || gamePath.existsSync() == false) return null;
    final gameCorePath = generateGameCorePath(gamePath)!;

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
      ref.read(enabledModsFile).valueOrNull?.enabledMods.toList(),
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
    final gamePath = ref.watch(gameFolder).valueOrNull;
    if (gamePath == null) return null;
    return generateModsFolderPath(gamePath)?.toDirectory();
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

    final isJre23 =
        ref.watch(jreManagerProvider).valueOrNull?.activeJre?.isCustomJre ??
        false;
    final gamePath = ref.watch(gameFolder).value?.toDirectory();
    if (gamePath == null) return null;

    return isJre23
        ? gamePath
              .resolve(
                ref.watch(
                      appSettings.select(
                        (value) => value.showCustomJreConsoleWindow,
                      ),
                    )
                    ? "Miko_Rouge.bat"
                    : "Miko_Silent.bat",
              )
              .toFile()
        : getVanillaGameExecutable(gamePath).toFile();
  });

  static final vmParamsFile = FutureProvider<File?>((ref) async {
    return ref
        .watch(jreManagerProvider)
        .valueOrNull
        ?.activeJre
        ?.vmParamsFileAbsolutePath
        .toFile();
  });

  static final canWriteToStarsectorFolder = FutureProvider<bool>((ref) async {
    final vmParamsFileLocal = ref.watch(vmParamsFile).valueOrNull;
    if (vmParamsFileLocal == null) return false;
    final filesAndFolders = [vmParamsFileLocal].nonNulls;
    for (var file in filesAndFolders) {
      if (!file.existsSync() || await file.isNotWritable()) {
        Fimber.d("Cannot find or write to: $file");
        return false;
      }
    }
    return true;
  });

  static final isEnabledModsFileWritable = FutureProvider<bool>((ref) async {
    final modsPath = ref.watch(modsFolder).valueOrNull;
    if (modsPath == null) return false;
    return ref.read(AppState.enabledModsFile.notifier).isWritable();
  });

  static final activeJre = FutureProvider<JreEntryInstalled?>(
    (ref) async => ref.watch(jreManagerProvider).valueOrNull?.activeJre,
  );

  static final isGameRunning = AsyncNotifierProvider<_GameRunningChecker, bool>(
    _GameRunningChecker.new,
  );

  static final ignoringDrop = StateProvider<bool>((ref) => false);
}

class _GameRunningChecker extends AsyncNotifier<bool> {
  Timer? _timer;
  static const int period = 1500;
  List<File?> _gameExecutables = [];

  @override
  Future<bool> build() async {
    final isSettingEnabled = ref.watch(
      appSettings.select((value) => value.checkIfGameIsRunning),
    );
    if (!isSettingEnabled) {
      return false;
    }

    // Retrieve the list of executable files
    _gameExecutables = [ref.watch(AppState.gameExecutable).value];

    // Extract executable names from file paths
    final List<String> executableNames = _gameExecutables
        .whereType<File>()
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .toList();

    // Perform an initial check
    bool isRunning = await _checkIfAnyProcessIsRunning(executableNames);

    // Update the state with the initial value
    state = AsyncValue.data(isRunning);

    // Set up periodic checking every x milliseconds
    const duration = Duration(milliseconds: period);
    final isWindowFocused = ref.watch(AppState.isWindowFocused);

    _timer?.cancel();
    _timer = Timer.periodic(duration, (timer) async {
      if (!isWindowFocused) {
        return;
      } else {
        bool isRunning = await _checkIfAnyProcessIsRunning(executableNames);
        state = AsyncValue.data(isRunning);
      }
    });

    // Clean up the timer when the notifier is disposed
    ref.onDispose(() {
      _timer?.cancel();
    });

    return isRunning;
  }

  Future<bool> _checkIfAnyProcessIsRunning(List<String> identifiers) async {
    // First try using homebrew JPS to get Java processes
    // Requires Java JDK on the host machine, or Java 23.
    try {
      final jpsAtHomePath = getAssetsPath().toFile().resolve(
        "common/JpsAtHome.jar",
      );
      final process = await Process.start('java', ['-jar', jpsAtHomePath.path]);

      final outputBuffer = StringBuffer();
      process.stdout
          .transform(systemEncoding.decoder)
          .listen(outputBuffer.write);
      process.stderr
          .transform(systemEncoding.decoder)
          .listen(outputBuffer.write);

      final exitCodeFuture = process.exitCode;
      const jpsRunMaxDuration = Duration(milliseconds: 750);
      final result = await Future.any<int>([
        exitCodeFuture,
        Future.delayed(jpsRunMaxDuration, () => -1),
      ]);

      if (result == -1) {
        process.kill(ProcessSignal.sigkill);
        Fimber.w(
          "Killed java process after $jpsRunMaxDuration because it has a result of -1.",
        );
      } else {
        final output = outputBuffer.toString().toLowerCase();
        Fimber.v(() => "JPS output: $output");
        if (output.contains(
          "com.fs.starfarer.starfarerlauncher".toLowerCase(),
        )) {
          return true;
        }
      }
    } catch (e) {
      // ignored, probably can't run due to no java/jdk installed
    }

    // Fall back to using platform-specific commands to check process names.
    try {
      // Check the titles of all windows
      if (Platform.isWindows) {
        final process = await Process.run('powershell', [
          '-Command',
          'Get-Process | Where-Object { \$_.MainWindowTitle } | Select-Object -ExpandProperty MainWindowTitle',
        ]);
        if (process.exitCode == 0) {
          final output = process.stdout as String;
          final windowTitles = output
              .split('\n')
              .map((line) => line.trim())
              .toList();
          final isStarsectorRunning = windowTitles.any(
            (title) => title.contains(
              'Starsector ${ref.watch(appSettings).lastStarsectorVersion}',
            ),
          );
          return isStarsectorRunning;
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        // Use 'ps aux' command to get processes with command line
        ProcessResult result = await Process.run('ps', ['aux']);
        String output = result.stdout.toString().toLowerCase();
        for (String identifier in identifiers) {
          if (output.contains(identifier.toLowerCase())) {
            return true;
          }
        }
        return false;
      } else {
        // Unsupported platform
        return false;
      }
    } catch (e) {
      // ignored - this is running every second while in focus, don't spam logs
    }

    // Handle any exceptions
    return false;
  }
}

var currentFileHandles = 0;
var maxFileHandles = 2000;

Future<T> withFileHandleLimit<T>(Future<T> Function() function) async {
  while (currentFileHandles + 1 > maxFileHandles) {
    Fimber.v(
      () =>
          "Waiting for file handles to free up. Current file handles: $currentFileHandles",
    );
    await Future.delayed(const Duration(milliseconds: 100));
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
