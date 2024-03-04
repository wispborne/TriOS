import 'dart:convert';
import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:trios/utils/extensions.dart';

import 'jre_entry.dart';

final versionRegex = RegExp(r'"(\.*?\d+.*?)"');

Future<List<JreEntry>> findJREs(String? gameDir) async {
  var gamePath = gameDir?.toDirectory();
  if (gamePath == null || !gamePath.existsSync()) {
    return [];
  }

  return (await Future.wait(gamePath.listSync().whereType<Directory>().map((path) async {
    var javaExe = (path.resolve("bin/java.exe") as File).normalize;
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