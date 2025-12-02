import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:trios/changelogs/mod_changelogs_manager.dart';
import 'package:trios/compression/archive.dart';
import 'package:trios/jre_manager/jre_entry.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/download_progress.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/result.dart';
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

    final isJre23 =
        ref.watch(jreManagerProvider).value?.activeJre?.isCustomJre ??
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
        : getDefaultGameExecutable(gamePath).toFile();
  });

  static final vmParamsFile = FutureProvider<File?>((ref) async {
    return ref
        .watch(jreManagerProvider)
        .value
        ?.activeJre
        ?.vmParamsFileAbsolutePath
        .toFile();
  });

  static final canWriteToStarsectorFolder = FutureProvider<bool>((ref) async {
    final vmParamsFileLocal = ref.watch(vmParamsFile).value;
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
    final modsPath = ref.watch(modsFolder).value;
    if (modsPath == null) return false;
    return ref.read(AppState.enabledModsFile.notifier).isWritable();
  });

  static final activeJre = FutureProvider<JreEntryInstalled?>(
    (ref) async => ref.watch(jreManagerProvider).value?.activeJre,
  );

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

  static final ignoringDrop = StateProvider<bool>((ref) => false);
}

class _GameRunningChecker extends AsyncNotifier<Result> {
  Timer? _timer;
  static const int period = 1500;
  List<File?> _gameExecutables = [];

  @override
  Future<Result> build() async {
    final isSettingEnabled = ref.watch(
      appSettings.select((value) => value.checkIfGameIsRunning),
    );
    if (!isSettingEnabled) {
      return Result.unmitigatedFailure([]);
    }

    // Retrieve the list of executable files
    _gameExecutables = [ref.watch(AppState.gameExecutable).value];

    // Extract executable names from file paths
    final List<String> executableNames = _gameExecutables
        .whereType<File>()
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .toList();

    // Perform an initial check
    // final stopwatch = Stopwatch()..start();
    Result result = (await _checkIfStarsectorIsRunning(executableNames));
    // Fimber.d(
    //   "Checked if game is running in ${(stopwatch..stop()).elapsedMilliseconds}ms",
    // );

    // Update the state with the initial value
    state = AsyncValue.data(result);

    // Set up periodic checking every x milliseconds
    const duration = Duration(milliseconds: period);
    final isWindowFocused = ref.watch(AppState.isWindowFocused);

    _timer?.cancel();
    _timer = Timer.periodic(duration, (timer) async {
      if (!isWindowFocused) {
        return;
      } else {
        Result result = await _checkIfStarsectorIsRunning(executableNames);
        bool isGameRunning = result.wasSuccessful;
        state = AsyncValue.data(result);
      }
    });

    // Clean up the timer when the notifier is disposed
    ref.onDispose(() {
      _timer?.cancel();
    });

    return result;
  }

  /// Check if Starsector is running.
  /// First, try using system Java to run homebrew JPS.
  /// If that doesn't work, try using (Windows) WMIC or (Unix) `ps aux`.
  Future<Result> _checkIfStarsectorIsRunning(List<String> processNames) async {
    List<Exception> errors = [];
    // First try using homebrew JPS to get Java processes
    // Requires Java JDK on the host machine, or Java 17.

    //// This uses the game's own JRE to run JpsAtHome, but `java.lang.noclassdeffounderror: com/sun/tools/attach/virtualmachine`
    //// `tools.jar` isn't bundled with the game's JRE.
    // try {
    //   final jreFolder = ref
    //       .read(AppState.activeJre)
    //       .value
    //       ?.jreAbsolutePath;
    //   if (jreFolder != null) {
    //     final starsectorJavaExecutablePath = getJavaExecutable(jreFolder).path;
    //     final result = await _checkIfAnyProcessIsRunningUsingGivenJre(
    //       starsectorJavaExecutablePath,
    //     );
    //     if (result != null) {
    //       Fimber.v(
    //         () =>
    //             "Checked if game is running using JPS running on game's JRE $starsectorJavaExecutablePath. Is game running? ${result.wasSuccessful}",
    //       );
    //       return result;
    //     }
    //   }
    // } on Exception catch (e) {
    //   // ignored, probably can't run due to no java/jdk installed
    //   errors.add(e);
    // }

    // Try using the system's java executable to run JpsAtHome (requires JDK)
    try {
      final javaExecutablePath = 'java';
      final result = await _checkIfAnyProcessIsRunningUsingGivenJre(
        javaExecutablePath,
      );
      if (result != null) {
        Fimber.v(
          () =>
              "Checked if game is running using JPS running on system's JRE $javaExecutablePath. Is game running? ${result.wasSuccessful}",
        );
        return result;
      }
    } on Exception catch (e) {
      // ignored, probably can't run due to no java/jdk installed
      errors.add(e);
    }

    // Fall back to using platform-specific commands to check process names.
    try {
      // Check the titles of all windows
      if (Platform.isWindows) {
        _checkIfAnyProcessIsRunningUsingWmic(errors);
        // _checkIfAnyProcessIsRunningUsingPowershell(errors);
      } else if (Platform.isMacOS || Platform.isLinux) {
        // Use 'ps aux' command to get processes with command line
        ProcessResult result = await Process.run('ps', ['aux']);
        String output = result.stdout.toString().toLowerCase();
        for (String identifier in processNames) {
          // Check for e.g. `starsector.app` but not `starsector.app/`
          if (output.contains(identifier.toLowerCase()) &&
              !output.contains("${identifier.toLowerCase()}/")) {
            Fimber.v(
              () =>
                  "Checked if game is running using ps aux. Is game running? true",
            );
            return Result.partialSuccess(errors);
          }
        }
        return Result.unmitigatedFailure(
          errors..add(Exception("Game not found using fallback `ps` method.")),
        );
      } else {
        // Unsupported platform
        return Result.unmitigatedFailure(
          errors..add(Exception("No fallback method for this platform.")),
        );
      }
    } catch (e) {
      // ignored - this is running every second while in focus, don't spam logs
    }

    // Handle any exceptions
    return Result.unmitigatedFailure(errors);
  }

  Future<Result?> _checkIfAnyProcessIsRunningUsingGivenJre(
    String javaExecutablePath,
  ) async {
    final jpsAtHomePath = getAssetsPath().toFile().resolve(
      "common/JpsAtHome.jar",
    );
    final process = await Process.start(javaExecutablePath, [
      '-jar',
      jpsAtHomePath.path,
    ]);

    final outputBuffer = StringBuffer();
    process.stdout.transform(systemEncoding.decoder).listen(outputBuffer.write);
    process.stderr.transform(systemEncoding.decoder).listen(outputBuffer.write);

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
      if (output.contains("com.fs.starfarer.starfarerlauncher".toLowerCase())) {
        return Result.unmitigatedSuccess();
      }
    }

    return null;
  }

  Future<Result?> _checkIfAnyProcessIsRunningUsingWmic(
    List<Exception> errors,
  ) async {
    try {
      final process = await Process.run('wmic', [
        'process',
        'where',
        "name='java.exe'",
        'get',
        'ProcessId,CommandLine',
      ], runInShell: true);

      if (process.exitCode != 0) return null;

      final output = process.stdout is String
          ? process.stdout as String
          : String.fromCharCodes(process.stdout as List<int>);

      final lines = output
          .split(RegExp(r'\r?\r?\n'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && !e.startsWith('CommandLine'))
          .toList();

      final isStarsectorRunning = lines.any(
        (line) => line.contains('com.fs.starfarer.StarfarerLauncher'),
      );

      Fimber.v(
        () =>
            'Checked if game is running using wmic. Is game running? $isStarsectorRunning',
      );

      return Result(isStarsectorRunning, errors);
    } catch (e, st) {
      Fimber.w('Error checking JVM processes', ex: e, stacktrace: st);
      errors.add(Exception('WMIC check failed: $e'));
      return null;
    }
  }

  Future<Result?> _checkIfAnyProcessIsRunningUsingPowershell(
    List<Exception> errors,
  ) async {
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
      Fimber.v(
        () =>
            "Checked if game is running using window titles. Is game running? $isStarsectorRunning",
      );
      return Result(isStarsectorRunning, errors);
    }

    return null;
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
