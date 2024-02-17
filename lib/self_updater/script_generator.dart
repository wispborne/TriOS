import 'dart:io';

import '../utils/util.dart';

class ScriptGenerator {
  static String generateFileUpdateScript(
      List<Tuple2<File?, File>> filePairs, String platform, int delaySeconds) {
    switch (platform) {
      case "windows":
        return _generateBatchScript(filePairs, delaySeconds);
      case "linux":
      case "macos":
        return _generateBashScript(filePairs, delaySeconds);
      default:
        throw UnimplementedError(
            'Script generation not supported for this platform');
    }
  }

  static String _generateBatchScript(
      List<Tuple2<File?, File?>> filePairs, int delaySeconds) {
    final commands = <String>[];
    commands.add('@echo off');
    commands.add('timeout /t $delaySeconds'); // Windows wait command

    for (final pair in filePairs) {
      final sourceFile = pair.item1;
      final targetFile = pair.item2;

      if (targetFile == null && sourceFile?.existsSync() == true) {
        commands.add('del "${sourceFile?.path}"');
      } else if (targetFile != null && targetFile.existsSync()) {
        // Using 'move' is appropriate for renaming (as well as moving) on Windows
        commands.add('move /Y "${targetFile.path}" "${sourceFile?.path}"');
      }
    }

    return commands.join('\r\n');
  }

  static String _generateBashScript(
      List<Tuple2<File?, File?>> filePairs, int delaySeconds) {
    final commands = <String>[];
    commands.add('#!/bin/bash');
    commands.add('sleep $delaySeconds'); // Unix wait command

    for (final pair in filePairs) {
      final sourceFile = pair.item1;
      final targetFile = pair.item2;

      if (targetFile == null && sourceFile?.existsSync() == true) {
        commands.add('rm "${sourceFile?.path}"');
      } else if (targetFile != null && targetFile.existsSync()) {
        commands.add('mv -f "${targetFile.path}" "${sourceFile?.path}"');
      }
    }

    return commands.join('\n');
  }
}
