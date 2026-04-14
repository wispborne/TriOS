import 'dart:io';

import 'package:trios/models/result.dart';
import 'package:trios/utils/logging.dart';

import 'process_detector.dart';

/// Detects Starsector by running WMIC to check for java.exe processes
/// with `com.fs.starfarer.StarfarerLauncher` in the command line.
///
/// Windows only.
class WmicProcessDetector extends ProcessDetector {
  @override
  String get name => 'WMIC';

  @override
  Future<Result?> isStarsectorRunning(List<String> executableNames) async {
    final errors = <Exception>[];
    try {
      final process = await Process.run(
        'wmic',
        ['process', 'where', "name='java.exe'", 'get', 'ProcessId,CommandLine'],
        runInShell: true,
      );

      if (process.exitCode != 0) return null;

      final output =
          process.stdout is String
              ? process.stdout as String
              : String.fromCharCodes(process.stdout as List<int>);

      final lines =
          output
              .split(RegExp(r'\r?\r?\n'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty && !e.startsWith('CommandLine'))
              .toList();

      final isStarsectorRunning = lines.any(
        (line) => line.contains('com.fs.starfarer.StarfarerLauncher'),
      );

      Fimber.v(
        () =>
            'Checked if game is running using WMIC. Is game running? $isStarsectorRunning',
      );

      return Result(isStarsectorRunning, errors);
    } catch (e, st) {
      Fimber.w('Error checking JVM processes via WMIC', ex: e, stacktrace: st);
      return null;
    }
  }
}
