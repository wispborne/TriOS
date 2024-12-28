import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final installedJres = await findJREs();
    _startWatchingJres();
    final activeJres =
        installedJres.where((jre) => jre.hasAllFilesReadyToLaunch()).toList();
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
  Future<List<JreEntryInstalled>> findJREs() async {
    final gamePath = ref.watch(appSettings.select((value) => value.gameDir));
    if (gamePath == null || !gamePath.existsSync()) {
      return [];
    }

    return (await Future.wait(
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
        .whereType<JreEntryInstalled>()
        .toList();
  }

  Future<void> changeActiveJre(JreEntryInstalled newJre) async {
    var gamePath =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (gamePath == null || !gamePath.existsSync()) {
      return;
    }

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

    Directory? currentJreDest;
    final gameJrePath = currentJreSource!.jreAbsolutePath;

    // If current JRE is custom, don't move it.
    if (currentJreSource.jreAbsolutePath.existsSync() && !currentJreSource.isCustomJre) {
      // We'll move the current JRE to a new folder, which has the JRE's version string in the name.
      currentJreDest =
          "${currentJreSource.jreAbsolutePath}-${currentJreSource.versionString}"
              .toDirectory();

      // If the destination already exists, add a random suffix to the name.
      if (currentJreDest.existsSync()) {
        currentJreDest =
            "${currentJreDest.path}-${DateTime.now().millisecondsSinceEpoch.toString().takeLast(6)}"
                .toDirectory();
      }

      try {
        Fimber.i(
            "Moving JRE ${currentJreSource.versionString} from '${currentJreSource.jreAbsolutePath}' to '$currentJreDest'.");
        await currentJreSource.jreAbsolutePath.moveDirectory(currentJreDest);
      } catch (e, st) {
        Fimber.w(
            "Unable to move currently used JRE. Make sure the game is not running.",
            ex: e,
            stacktrace: st);
        return;
      }
    }

    // Rename target JRE to "jre".
    try {
      await newJre.jreAbsolutePath.moveDirectory(gameJrePath);
      Fimber.i("Moved JRE ${newJre.versionString} to '$gameJrePath'.");
      ref.read(appSettings.notifier).update(
          (it) => it.copyWith(lastActiveJreVersion: newJre.versionString));
      findJREs();
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
    }

    ref.invalidateSelf();
  }

  _startWatchingJres() async {
    _jreWatcherSubscription?.cancel();
    final jresDir =
        ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
    if (jresDir == null) return;
    _jreWatcherSubscription = jresDir.watch().listen((event) {
      findJREs();
    });
  }
}

class JreManagerState {
  final List<JreEntry> installedJres;
  final List<JreEntryInstalled> activeJres;
  final String? _lastActiveJreVersion;

  JreManagerState(
    this.installedJres,
    this.activeJres,
    this._lastActiveJreVersion,
  );

  JreEntryInstalled? get activeJre =>
      activeJres.firstWhereOrNull(
          (it) => it.versionString == _lastActiveJreVersion) ??
      activeJres.firstOrNull;

  List<StandardInstalledJreEntry> get standardInstalledJres =>
      installedJres.whereType<StandardInstalledJreEntry>().toList();

  List<CustomInstalledJreEntry> get customInstalledJres =>
      installedJres.whereType<CustomInstalledJreEntry>().toList();

  StandardInstalledJreEntry? get standardActiveJre =>
      activeJres.firstWhereOrNull((it) => it is StandardInstalledJreEntry)
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
