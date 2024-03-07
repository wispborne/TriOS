import 'dart:convert';
import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';

import '../utils/platform_paths.dart';
import 'jre_entry.dart';

final vmparamsVanillaContent = FutureProvider<String?>((ref) async {
  final gameDir = ref.watch(appSettings.select((value) => value.gameDir))?.toDirectory();
  if (gameDir == null) return null;
  return await readVanillaVmparams(gameDir.path);
});

final currentRamAmountInMb = FutureProvider<String?>((ref) async {
  final gameDir = ref.watch(appSettings.select((value) => value.gameDir))?.toDirectory();
  if (gameDir == null) return null;
  final vmparams = await ref.watch(vmparamsVanillaContent.future);
  if (vmparams == null) return null;
  return getRamAmountFromVmparamsInMb(vmparams) ?? "";
});

final maxRamInVmparamsRegex = RegExp(r"-Xmx(\d+\D)");
final minRamInVmparamsRegex = RegExp(r"-Xms(\d+\D)");
const mbPerGb = 1024;

/// Parses the amount of RAM from the vmparams file
String? getRamAmountFromVmparamsInMb(String vmparams) {
  var ramMatch = maxRamInVmparamsRegex.firstMatch(vmparams);
  if (ramMatch == null) {
    return null;
  }
  // eg 2048m
  var amountWithLowercaseChar = ramMatch.group(1)?.toLowerCase();
  if (amountWithLowercaseChar == null) {
    return null;
  }
  final amountInMb = amountWithLowercaseChar.endsWith("g")
      // Convert from GB to MB
      ? (double.parse(amountWithLowercaseChar.replaceAll("g", "")) * mbPerGb).toStringAsFixed(0)
      : double.parse(amountWithLowercaseChar).toStringAsFixed(0);
  return amountInMb;
}

/// Change the amount of RAM allocated to the game, both vanilla and JRE23/custom
Future<void> changeRamAmount(WidgetRef ref, double ramInMb, {bool alsoChangeCustomVmparams = true}) async {
  final gamePath = ref.read(appSettings.select((value) => value.gameDir))?.toDirectory();
  if (gamePath == null) {
    return;
  }
  final vmParams = getVmparamsFile(gamePath);
  final newRamStr = "${ramInMb}m";
  final newVmparams = vmParams
      .readAsStringSync()
      .replaceAll(maxRamInVmparamsRegex, "-Xmx${newRamStr}m")
      .replaceAll(minRamInVmparamsRegex, "-Xms${newRamStr}m");
  await vmParams.writeAsString(newVmparams);

  if (alsoChangeCustomVmparams) {
    // Change JRE23 vmparams
    final jre23Vmparams = gamePath.resolve("Miko_R3.txt").toFile();
    if (!jre23Vmparams.existsSync()) {
      Fimber.w("JRE 23 vmparams file does not exist: $jre23Vmparams");
      return;
    }

    jre23Vmparams.writeAsStringSync(jre23Vmparams
        .readAsStringSync()
        .replaceAll(maxRamInVmparamsRegex, "-Xmx${newRamStr}m")
        .replaceAll(minRamInVmparamsRegex, "-Xms${newRamStr}m"));
  }

  ref.refresh(vmparamsVanillaContent);
}

final versionRegex = RegExp(r'"(\.*?\d+.*?)"');

/// Async find all JREs in the game directory
Future<List<JreEntry>> findJREs(String? gameDir) async {
  var gamePath = gameDir?.toDirectory();
  if (gamePath == null || !gamePath.existsSync()) {
    return [];
  }

  return (await Future.wait(gamePath.listSync().whereType<Directory>().map((path) async {
    var javaExe = getJavaExecutable(path);
    if (!javaExe.existsSync()) {
      return null;
    }

    String? versionString;
    var cmd = javaExe.absolute.normalize.path;
    try {
      var process = await Process.start(cmd, ["-version"]);
      var lines = await process.stderr.transform(utf8.decoder).transform(const LineSplitter()).toList();
      var versionLine = lines.firstWhere((line) => line.contains(versionRegex), orElse: () => lines.first);
      versionString = versionRegex.firstMatch(versionLine)?.group(1) ?? versionLine;
    } catch (e, st) {
      Fimber.e("Error getting java version from '$cmd'.", ex: e, stacktrace: st);
    }

    if (versionString == null) {
      return null;
    }

    return JreEntry(versionString, path);
  })))
      .whereType<JreEntry>()
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
