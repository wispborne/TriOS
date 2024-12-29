import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

import '../utils/platform_paths.dart';
import 'jre_entry.dart';

final minRamInVmparamsRegex =
    RegExp(r"(?<=xms).*?(?=\s)", caseSensitive: false);
final maxRamInVmparamsRegex =
    RegExp(r"(?<=xmx).*?(?=\s)", caseSensitive: false);
final jreVersionRegex = RegExp(r'"(\.*?\d+.*?)"');
const mbPerGb = 1024;

/// Provider for [doesJre23ExistInGameFolder].
final doesJre23ExistInGameFolderProvider = FutureProvider<bool>((ref) async {
  /// Returns true if the game directory contains a JRE 23 installation.
  bool doesJre23ExistInGameFolder(Directory gameDir) {
    return gameDir.resolve("mikohime").toDirectory().existsSync() &&
        gameDir.resolve("Miko_Rouge.bat").toFile().existsSync();
  }

  final gamePath =
      ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
  if (gamePath == null) {
    return false;
  }
  return doesJre23ExistInGameFolder(gamePath);
});

/// Provider for [JreManagerState].
final jreManagerProvider =
    AsyncNotifierProvider<JreManager, JreManagerState>(JreManager.new);

class JreManager extends AsyncNotifier<JreManagerState> {
  static const supportedJreVersions = [7, 8, 23, 24];
  StreamSubscription? _jreWatcherSubscription;

  @override
  Future<JreManagerState> build() async {
    final installedJres = await _findJREs();
    _startWatchingJres();
    final activeJres = installedJres
        .whereType<JreEntryInstalled>()
        .where((jre) => jre.hasAllFilesReadyToLaunch())
        .toList();
    final lastActiveJreVersion =
        ref.watch(appSettings.select((value) => value.lastActiveJreVersion));

    return JreManagerState(installedJres, activeJres, lastActiveJreVersion);
  }

  /// Change the amount of RAM allocated to the game
  Future<void> changeRamAmount(double ramInMb,
      {bool alsoChangeCustomVmparams = true}) async {
    final gamePath =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null) {
      return;
    }

    for (var jre in state.valueOrNull?.activeJres ?? []) {
      await jre.setRamAmountInMb(ramInMb);
    }

    ref.invalidateSelf();
  }

  /// Async find all JREs in the game directory,
  /// including any supported downloadable JREs to the list.
  Future<List<JreEntry>> _findJREs() async {
    final gamePath = ref.watch(appSettings.select((value) => value.gameDir));
    if (gamePath == null || !gamePath.existsSync()) {
      return [];
    }

    final List<JreEntry> jres = (await Future.wait(
            gamePath.listSync().whereType<Directory>().map((jrePath) async {
      var javaExe = getJavaExecutable(jrePath);
      if (!javaExe.existsSync()) {
        return null;
      }

      String? versionString;
      var cmd = javaExe.absolute.normalize.path;
      try {
        var process = await Process.start(cmd, ["-version"]);
        var lines = await process.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .toList();
        var versionLine = lines.firstWhere(
            (line) => line.contains(jreVersionRegex),
            orElse: () => lines.first);
        versionString =
            jreVersionRegex.firstMatch(versionLine)?.group(1) ?? versionLine;
      } catch (e, st) {
        Fimber.e("Error getting java version from '$cmd'.",
            ex: e, stacktrace: st);
      }

      if (versionString == null) {
        return null;
      }

      final jreVersion = JreVersion(versionString);
      switch (jreVersion.version) {
        case 23:
          return Jre23InstalledJreEntry(gamePath, jrePath, jreVersion);
        case 24:
          return Jre24InstalledJreEntry(gamePath, jrePath, jreVersion);
        default:
          return StandardInstalledJreEntry(gamePath, jrePath, jreVersion);
      }
    })))
        .whereType<JreEntry>()
        .toList();

    // Add downloadable JREs
    final downloadableJres = [
      Jre23JreToDownload(gamePath, JreVersion("23-beta")),
      Jre24JreToDownload(gamePath, JreVersion("24-beta")),
    ];

    for (final downloadableJre in downloadableJres) {
      if (jres
          .none((jre) => jre.versionString == downloadableJre.versionString)) {
        jres.add(downloadableJre);
      }
    }

    return jres;
  }

  Future<void> changeActiveJre(JreEntryInstalled newJre) async {
    var gamePath =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null || !gamePath.existsSync()) {
      return;
    }

    bool didSwapFail = false;
    final currentJreSource = state.valueOrNull?.activeJre;

    if (currentJreSource != null &&
        newJre.version == currentJreSource.version) {
      Fimber.i("JRE ${newJre.versionString} is already active.");
      ref.read(appSettings.notifier).update(
          (it) => it.copyWith(lastActiveJreVersion: newJre.versionString));
      return;
    }

    // Switching to custom JRE is just an app setting change,
    // no need to move the JRE.
    if (newJre is CustomInstalledJreEntry) {
      ref.read(appSettings.notifier).update(
          (it) => it.copyWith(lastActiveJreVersion: newJre.versionString));
      ref.invalidateSelf();
      return;
    }

    if (newJre is! StandardInstalledJreEntry) {
      Fimber.e("JRE ${newJre.versionString} is not a supported JRE.");
      return;
    }
    // From here on out, we're switching to a standard JRE.

    // If we're switching to a standard JRE that's not in the "jre" folder, we need to swap it with the active standard one,
    // even if we're switching from a custom JRE.
    final needToChangeStandardJres = newJre.hasAllFilesReadyToLaunch() == false;

    if (needToChangeStandardJres) {
      didSwapFail = !await _activateStandardJre(gamePath, newJre);
    }

    if (!didSwapFail) {
      ref.read(appSettings.notifier).update(
          (it) => it.copyWith(lastActiveJreVersion: newJre.versionString));
    }

    // Refresh JRE list
    ref.invalidateSelf();
  }

  /// Returns false if the swap failed.
  Future<bool> _activateStandardJre(
      Directory gamePath, StandardInstalledJreEntry newJre) async {
    final sourceStandardJre = state.valueOrNull?.standardActiveJre;
    Directory? currentJreDest;
    final gameJrePath =
        gamePath.resolve(Constants.gameJreFolderName).toDirectory();

    // Step: If current JRE is standard, then change its folder name from `jre` to `jre-${version}`.
    if (sourceStandardJre != null &&
        !sourceStandardJre.isCustomJre &&
        sourceStandardJre.jreAbsolutePath.existsSync()) {
      // We'll move the current JRE to a new folder, which has the JRE's version string in the name.
      currentJreDest =
          "${sourceStandardJre.jreAbsolutePath.path}-${sourceStandardJre.versionString}"
              .toDirectory();

      // If the destination already exists, add a random suffix to the name.
      if (currentJreDest.existsSync()) {
        currentJreDest =
            "${currentJreDest.path}-${DateTime.now().millisecondsSinceEpoch.toString().takeLast(6)}"
                .toDirectory();
      }

      try {
        Fimber.i(
            "Moving JRE ${sourceStandardJre.versionString} from '${sourceStandardJre.jreAbsolutePath.path}' to '$currentJreDest'.");
        await sourceStandardJre.jreAbsolutePath.moveDirectory(currentJreDest);
      } catch (e, st) {
        Fimber.w(
            "Unable to move currently used JRE. Make sure the game is not running.",
            ex: e,
            stacktrace: st);
        return false;
      }
    }

    // Step: Change the name of the target JRE to "jre".
    try {
      await newJre.jreAbsolutePath.moveDirectory(gameJrePath);
      Fimber.i("Moved JRE ${newJre.versionString} to '$gameJrePath'.");
    } catch (e, st) {
      Fimber.w(
          "Unable to move new JRE ${newJre.versionString} to '$gameJrePath'. Maybe you need to run as Admin?",
          ex: e,
          stacktrace: st);
      if (!gameJrePath.existsSync() &&
          currentJreDest != null &&
          currentJreDest.existsSync()) {
        Fimber.w(
            "Rolling back JRE change. Moving '$currentJreDest' to '$gameJrePath'.");

        try {
          await currentJreDest.moveDirectory(gameJrePath);
        } catch (e, st) {
          Fimber.e("Failed to roll back JRE change.", ex: e, stacktrace: st);
        }
      }

      return false;
    }

    return true;
  }

  _startWatchingJres() async {
    _jreWatcherSubscription?.cancel();
    final jresDir =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (jresDir == null) return;
    _jreWatcherSubscription = jresDir.watch().listen((event) {
      _findJREs();
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
          (it) => it.versionString == _lastActiveJreVersion) ??
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
}

final currentRamAmountInMb = FutureProvider<String?>((ref) async {
  return ref
      .watch(jreManagerProvider)
      .valueOrNull
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
