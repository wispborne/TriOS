import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

import '../utils/platform_paths.dart';
import 'jre_entry.dart';
import 'jre_manager.dart';

final vmparamsVanillaContent = FutureProvider<String?>((ref) async {
  final gameDir =
      ref.watch(appSettings.select((value) => value.gameDir))?.toDirectory();
  if (gameDir == null) return null;
  return await readVanillaVmparams(gameDir.path);
});

final currentRamAmountInMb = FutureProvider<String?>((ref) async {
  final gameDir =
      ref.watch(appSettings.select((value) => value.gameDir))?.toDirectory();
  if (gameDir == null) return null;
  final vmparams = await ref.watch(vmparamsVanillaContent.future);
  if (vmparams == null) return null;
  return getRamAmountFromVmparamsInMb(vmparams) ?? "";
});

final minRamInVmparamsRegex =
    RegExp(r"(?<=xms).*?(?=\s)", caseSensitive: false);
final maxRamInVmparamsRegex =
    RegExp(r"(?<=xmx).*?(?=\s)", caseSensitive: false);
const mbPerGb = 1024;

/// Parses the amount of RAM from the vmparams file
String? getRamAmountFromVmparamsInMb(String vmparams) {
  var ramMatch = maxRamInVmparamsRegex.stringMatch(vmparams);
  if (ramMatch == null) {
    return null;
  }
  // eg 2048m
  var amountWithLowercaseChar = ramMatch.toLowerCase();
  // remove all non-numeric characters
  final replace = RegExp(r"[^\d]");
  final amountInMb = amountWithLowercaseChar.endsWith("g")
      // Convert from GB to MB
      ? (double.parse(amountWithLowercaseChar.replaceAll(replace, "")) *
              mbPerGb)
          .toStringAsFixed(0)
      : double.parse(amountWithLowercaseChar.replaceAll(replace, ""))
          .toStringAsFixed(0);
  return amountInMb;
}

/// Change the amount of RAM allocated to the game, both vanilla and JRE23/custom
Future<void> changeRamAmount(WidgetRef ref, double ramInMb,
    {bool alsoChangeCustomVmparams = true}) async {
  final gamePath =
      ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
  if (gamePath == null) {
    return;
  }
  final vmParams = getVmparamsFile(gamePath);
  final newRamStr = "${ramInMb.toStringAsFixed(0)}m";
  final newVmparams = vmParams
      .readAsStringSync()
      .replaceAll(maxRamInVmparamsRegex, newRamStr)
      .replaceAll(minRamInVmparamsRegex, newRamStr);
  await vmParams.writeAsString(newVmparams);

  if (alsoChangeCustomVmparams) {
    // Change JRE23 vmparams
    final jre23Vmparams = getJre23VmparamsFile(gamePath);
    if (!jre23Vmparams.existsSync()) {
      Fimber.d(
          "JRE 23 vmparams file does not exist, not modifying (this is expected if JRE23 is not set up): ${jre23Vmparams.path}");
    } else {
      jre23Vmparams.writeAsStringSync(jre23Vmparams
          .readAsStringSync()
          .replaceAll(maxRamInVmparamsRegex, newRamStr)
          .replaceAll(minRamInVmparamsRegex, newRamStr));
    }
  }

  ref.invalidate(vmparamsVanillaContent);
}

final versionRegex = RegExp(r'"(\.*?\d+.*?)"');

/// Async find all JREs in the game directory
Future<List<JreEntryInstalled>> findJREs(String? gameDir) async {
  var gamePath = gameDir?.toDirectory();
  if (gamePath == null || !gamePath.existsSync()) {
    return [];
  }

  return (await Future.wait(
          gamePath.listSync().whereType<Directory>().map((path) async {
    var javaExe = getJavaExecutable(path);
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
      var versionLine = lines.firstWhere((line) => line.contains(versionRegex),
          orElse: () => lines.first);
      versionString =
          versionRegex.firstMatch(versionLine)?.group(1) ?? versionLine;
    } catch (e, st) {
      Fimber.e("Error getting java version from '$cmd'.",
          ex: e, stacktrace: st);
    }

    if (versionString == null) {
      return null;
    }

    return JreEntryInstalled(JreVersion(versionString), path);
  })))
      .whereType<JreEntryInstalled>()
      .toList();
}

/// Async reads the vanilla vmparams file
Future<String?> readVanillaVmparams(String gameDir) async {
  var gamePath = gameDir.toDirectory();
  if (!gamePath.existsSync()) {
    Fimber.w("Game path does not exist: $gamePath");
    return null;
  }

  final vmparamsFile = getVmparamsFile(gamePath);

  if (!vmparamsFile.existsSync()) {
    Fimber.w("vmparams file does not exist: $vmparamsFile");
    return null;
  }

  return await vmparamsFile.readAsString();
}

extension JreEntryWrapperExt on JreEntry {
  bool isActive(WidgetRef ref, List<JreEntry> otherJres) {
    if (this is JreEntryInstalled) {
      var useJre23 =
          ref.watch(appSettings.select((value) => value.useJre23)) ?? false;

      if (versionInt == 23) {
        return useJre23;
      }

      // If JRE23 is enabled and exists, do not allow other JREs to be active.
      // Otherwise, the active JRE will be named "jre".
      return (!useJre23 || otherJres.none((jre) => jre.versionInt == 23)) &&
          (this as JreEntryInstalled).path.name == gameJreFolderName;
    } else {
      return false;
    }
  }
}
