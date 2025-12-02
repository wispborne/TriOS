import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart';

import '../utils/platform_paths.dart';
import 'jre_entry.dart';

final minRamInVmparamsRegex = RegExp(
  r"(?<=xms).*?(?=\s)",
  caseSensitive: false,
);
final maxRamInVmparamsRegex = RegExp(
  r"(?<=xmx).*?(?=\s)",
  caseSensitive: false,
);
final jreVersionRegex = RegExp(r'"(\.*?\d+.*?)"');
const mbPerGb = 1024;

/// Provider for [doesJre23ExistInGameFolder].
final doesJre23ExistInGameFolderProvider = FutureProvider<bool>((ref) async {
  /// Returns true if the game directory contains a JRE 23 installation.
  bool doesJre23ExistInGameFolder(Directory gameDir) {
    return gameDir.resolve("mikohime").toDirectory().existsSync() &&
        gameDir.resolve("Miko_Rouge.bat").toFile().existsSync();
  }

  final gamePath = ref.read(AppState.gameFolder).value?.toDirectory();
  if (gamePath == null) {
    return false;
  }
  return doesJre23ExistInGameFolder(gamePath);
});

/// Provider for [JreManagerState].
final jreManagerProvider = AsyncNotifierProvider<JreManager, JreManagerState>(
  JreManager.new,
);

class JreManager extends AsyncNotifier<JreManagerState> {
  StreamSubscription? _jreWatcherSubscription;

  @override
  Future<JreManagerState> build() async {
    final gamePath = ref.watch(AppState.gameFolder).value;
    final corePath = ref.watch(AppState.gameCoreFolder).value;
    final installedJres = await findJREs(gamePath, corePath);
    _startWatchingJres(gamePath, corePath);
    final activeJres = installedJres
        .whereType<JreEntryInstalled>()
        .where((jre) => jre.hasAllFilesReadyToLaunch())
        .toList();
    final lastActiveJreVersion = ref.watch(
      appSettings.select((value) => value.lastActiveJreVersion),
    );

    return JreManagerState(installedJres, activeJres, lastActiveJreVersion);
  }

  /// Change the amount of RAM allocated to the game
  Future<void> changeRamAmount(
    double ramInMb, {
    bool alsoChangeCustomVmparams = true,
  }) async {
    final gamePath = ref.read(AppState.gameFolder).value?.toDirectory();
    if (gamePath == null) {
      return;
    }

    for (var jre in state.value?.activeJres ?? []) {
      await jre.setRamAmountInMb(ramInMb);
    }

    ref.invalidateSelf();
  }

  /// Async find all JREs in the game directory,
  /// including any supported downloadable JREs to the list.
  Future<List<JreEntry>> findJREs(
    Directory? gamePath,
    Directory? corePath,
  ) async {
    if (gamePath == null ||
        !gamePath.existsSync() ||
        corePath == null ||
        !corePath.existsSync()) {
      return [];
    }

    final jresRootPath = generateJresFolderPath(gamePath)!;

    final List<JreEntry> jres = (await Future.wait(
      jresRootPath.listSync().whereType<Directory>().map((jrePath) async {
        final javaExe = getJavaExecutable(jrePath);
        if (!javaExe.existsSync()) {
          return null;
        }

        String? versionString;
        final cmd = javaExe.absolute.normalize.path;
        try {
          final process = await Process.start(cmd, [
            "-Xmx128m",
            "-Xms32m",
            "-version",
          ]);
          final lines = await process.stderr
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .toList();
          final versionLine = lines.firstWhere(
            (line) => line.contains(jreVersionRegex),
            orElse: () => lines.first,
          );
          versionString =
              jreVersionRegex.firstMatch(versionLine)?.group(1) ?? versionLine;
        } catch (e, st) {
          Fimber.e(
            "Error getting java version from '$cmd'.",
            ex: e,
            stacktrace: st,
          );
        }

        if (versionString == null) {
          return null;
        }

        final jreVersion = JreVersion(versionString);
        switch (jreVersion.version) {
          case 23:
            return Jre23InstalledJreEntry(
              gamePath,
              corePath,
              jrePath,
              jreVersion,
            );
          case 24:
            return Jre24InstalledJreEntry(
              gamePath,
              corePath,
              jrePath,
              jreVersion,
            );
          default:
            return StandardInstalledJreEntry(
              gamePath,
              corePath,
              jrePath,
              jreVersion,
            );
        }
      }),
    )).whereType<JreEntry>().toList();

    // Look for Fast Rendering
    final frEntry = FastRenderingInstalledJreEntry(
      gamePath,
      corePath,
      Directory.current,
      JreVersion("1.0.0"),
    );
    if (frEntry.hasAllFilesReadyToLaunch()) {
      jres.add(frEntry);
    }

    // Add downloadable JREs
    final downloadableJres = [
      Jre23JreToDownload(gamePath, corePath, JreVersion("23-beta")),
      Jre24JreToDownload(gamePath, corePath, JreVersion("24-beta")),
    ];

    for (final downloadableJre in downloadableJres) {
      if (jres.none(
        (jre) => jre.versionString == downloadableJre.versionString,
      )) {
        jres.add(downloadableJre);
      }
    }

    return jres;
  }

  Future<void> changeActiveJre(JreEntryInstalled newJre) async {
    var gamePath = ref.read(AppState.gameFolder).value?.toDirectory();
    if (gamePath == null || !gamePath.existsSync()) {
      return;
    }

    bool didSwapFail = false;
    final currentJreSource = state.value?.activeJre;

    if (currentJreSource != null &&
        newJre.version == currentJreSource.version) {
      Fimber.i("JRE ${newJre.versionString} is already active.");
      ref
          .read(appSettings.notifier)
          .update(
            (it) => it.copyWith(lastActiveJreVersion: newJre.versionString),
          );
      return;
    }

    // Switching to custom JRE is just an app setting change,
    // no need to move the JRE.
    if (newJre is MikohimeCustomJreEntry) {
      ref
          .read(appSettings.notifier)
          .update(
            (it) => it.copyWith(lastActiveJreVersion: newJre.versionString),
          );
      ref.invalidateSelf();
      return;
    } else if (newJre is MikohimeCustomJreEntry) {
      // Unused, realized too late that there's no way to tell which JRE is associated with which mikohime folder.
      // So I'm just not going to support multiple Himemi JREs.
      final existingMikohimeJre = state.value?.activeJres
          .firstWhereOrNull((it) => it is MikohimeCustomJreEntry);
      final needsToReplaceMikohimeJre =
          newJre.jreRelativePath.name != newJre.mikohimeFolder.name;

      // Swap the mikohime folder with the existing mikohime folder
      if (needsToReplaceMikohimeJre && existingMikohimeJre != null) {
        final swapResult = await newJre.jreAbsolutePath.swapDirectoryWith(
          destDir: existingMikohimeJre.jreAbsolutePath,
          suffixForReplacedDestDir: existingMikohimeJre.versionString,
        );
        if (!swapResult) {
          didSwapFail = true;
          Fimber.w(
            "Failed to swap out currently active JRE. Game might still be running.",
          );
        }
      }
    } else if (newJre is StandardInstalledJreEntry) {
      // From here on out, we're switching to a standard JRE.

      // If we're switching to a standard JRE that's not in the "jre" folder, we need to swap it with the active standard one,
      // even if we're switching from a custom JRE.
      final needToChangeStandardJres =
          newJre.hasAllFilesReadyToLaunch() == false;

      if (needToChangeStandardJres) {
        didSwapFail = !await _activateStandardJre(gamePath, newJre);
      }
    } else {
      Fimber.e("JRE ${newJre.versionString} is not a supported JRE.");
      didSwapFail = true;
    }

    if (!didSwapFail) {
      ref
          .read(appSettings.notifier)
          .update(
            (it) => it.copyWith(lastActiveJreVersion: newJre.versionString),
          );
    }

    // Refresh JRE list
    ref.invalidateSelf();
  }

  /// Returns false if the swap failed.
  Future<bool> _activateStandardJre(
    Directory gamePath,
    StandardInstalledJreEntry newJre,
  ) async {
    final existingStandardJre = state.value?.standardActiveJre;
    final gameJrePath = gamePath
        .resolve(Constants.gameJreFolderName)
        .toDirectory();

    // If there is an active standard JRE, attempt to swap it out.
    if (existingStandardJre != null &&
        existingStandardJre.jreAbsolutePath.existsSync()) {
      final currentJreDest =
          "${existingStandardJre.jreAbsolutePath.path}-${existingStandardJre.versionString}"
              .toDirectory();

      final swapResult = await existingStandardJre.jreAbsolutePath
          .swapDirectoryWith(
            destDir: currentJreDest,
            suffixForReplacedDestDir: existingStandardJre.versionString,
          );

      if (!swapResult) {
        Fimber.w(
          "Failed to swap out currently active JRE. Game might still be running.",
        );
        return false;
      }
    }

    // Move the new JRE to the active game JRE path
    final moveResult = await newJre.jreAbsolutePath.swapDirectoryWith(
      destDir: gameJrePath,
      suffixForReplacedDestDir: newJre.versionString,
    );

    if (!moveResult) {
      Fimber.w(
        "Failed to activate new JRE ${newJre.versionString}. Attempting rollback.",
      );
      return false;
    }

    return true;
  }

  void _startWatchingJres(Directory? gamePath, Directory? corePath) {
    _jreWatcherSubscription?.cancel();
    if (gamePath == null) {
      return;
    }
    final jresDir = generateJresFolderPath(gamePath);
    if (jresDir == null || !jresDir.existsSync()) return;
    _jreWatcherSubscription = jresDir.watch().listen((event) {
      findJREs(gamePath, corePath);
    });
  }
}

class JreManagerState {
  final List<JreEntry> installedJres;

  /// All valid JREs (one standard, could be multiple custom JREs).
  final List<JreEntryInstalled> activeJres;
  final String? _lastActiveJreVersion;

  JreManagerState(
    this.installedJres,
    this.activeJres,
    this._lastActiveJreVersion,
  );

  /// Returns the last activated JRE (via TriOS).
  JreEntryInstalled? get activeJre =>
      activeJres.firstWhereOrNull(
        (it) => it.versionString == _lastActiveJreVersion,
      ) ??
      activeJres.firstOrNull;

  List<StandardInstalledJreEntry> get standardInstalledJres =>
      installedJres.whereType<StandardInstalledJreEntry>().toList();

  List<CustomInstalledJreEntry> get customInstalledJres =>
      installedJres.whereType<CustomInstalledJreEntry>().toList();

  /// Returns the active JRE that is not a custom JRE.
  StandardInstalledJreEntry? get standardActiveJre =>
      activeJres.firstWhereOrNull((it) => it.isStandardJre)
          as StandardInstalledJreEntry?;

  bool get isUsingJre23 => activeJres.any((jre) => jre.versionInt == 23);

  bool get hasMultipleActiveJresWithDifferentRamAmounts =>
      (activeJres.map((jre) => jre.ramAmountInMb).toSet().length) > 1;
}

final currentRamAmountInMb = FutureProvider<String?>((ref) async {
  return ref
      .watch(jreManagerProvider)
      .value
      ?.activeJres
      .firstOrNull
      ?.ramAmountInMb;
});

// extension JreEntryWrapperExt on JreEntry {
//   bool isActive(bool? isUsingJre23, List<JreEntry> otherJres) {
//     if (this is JreEntryInstalled) {
//       var useJre23 = isUsingJre23 ?? false;
//
//       if (versionInt == 23) {
//         return useJre23;
//       }
//
//       // If JRE23 is enabled and exists, do not allow other JREs to be active.
//       // Otherwise, the active JRE will be named "jre".
//       return (!useJre23 || otherJres.none((jre) => jre.versionInt == 23)) &&
//           (this as JreEntryInstalled).path.name == gameJreFolderName;
//     } else {
//       return false;
//     }
//   }
// }
