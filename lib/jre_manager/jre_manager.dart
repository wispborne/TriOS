import 'dart:convert';
import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/settings/settings.dart';
import 'package:trios/utils/extensions.dart';

import 'jre_entry.dart';

const gameJreFolderName = "jre";

class JreManager extends ConsumerStatefulWidget {
  const JreManager({super.key});

  @override
  ConsumerState createState() => _JreManagerState();
}

class _JreManagerState extends ConsumerState<JreManager> {
  List<JreEntry> jres = [];

  @override
  void initState() {
    super.initState();
    _findJREs().then((value) {
      jres = value;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appSettings.select((value) => value.gameDir), (_, __) async {
      _findJREs().then((value) {
        jres = value;
        setState(() {});
      });
    });

    return Container(
        child: Column(
      children: [
        for (var jre in jres)
          ListTile(
            title: Text(jre.versionString),
            subtitle: Text(jre.path.absolute.path),
            leading: jre.isUsedByGame ? const Icon(Icons.check) : const Icon(Icons.coffee),
          ),
      ],
    ));
  }

  final versionRegex = RegExp(r'"(\.*?\d+.*?)"');

  Future<List<JreEntry>> _findJREs() async {
    var gameDir = ref.read(appSettings.select((value) => value.gameDir));
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
}
