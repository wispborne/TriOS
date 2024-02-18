import 'dart:io';

import '../utils/util.dart';

class ScriptGenerator {
  static String generateFileUpdateScript(List<Tuple2<File?, File>> filePairs, String platform, int delaySeconds) {
    switch (platform) {
      case "windows":
        return _generateBatchScript(filePairs, delaySeconds);
      case "linux":
      case "macos":
        return _generateBashScript(filePairs, delaySeconds);
      default:
        throw UnimplementedError('Script generation not supported for this platform');
    }
  }

  static String _generateBatchScript(List<Tuple2<File?, File?>> filePairs, int delaySeconds) {
    final commands = <String>[];
    commands.add('@echo off');
    commands.add('timeout /t $delaySeconds'); // Windows wait command

    for (final pair in filePairs) {
      final sourceFile = pair.item1;
      final targetFile = pair.item2;
      if (sourceFile != null && sourceFile.existsSync() && targetFile == null) {
        commands.add('del "${sourceFile.path}"');
      } else if (sourceFile != null && sourceFile.existsSync() && targetFile != null) {
        commands.add('move /Y "${sourceFile.path}" "${targetFile.path}"');
      }
    }

    // windows batch command to run Platform.executable in a new thread
    commands.add('start "" "${Platform.executable}"');

    return commands.join('\r\n');
  }

  static String _generateBashScript(List<Tuple2<File?, File?>> filePairs, int delaySeconds) {
    final commands = <String>[];
    commands.add('#!/bin/bash');
    commands.add('sleep $delaySeconds'); // Unix wait command

    for (final pair in filePairs) {
      final sourceFile = pair.item1;
      final targetFile = pair.item2;

      if (sourceFile != null && sourceFile.existsSync() == true && targetFile == null) {
        commands.add('rm "${sourceFile.path}"');
      } else if (sourceFile != null && sourceFile.existsSync() && targetFile != null) {
        commands.add('mv -f "${sourceFile.path}" "${targetFile.path}"');
      }
    }
    // bash command to run Platform.executable in a new thread
    commands.add("${Platform.executable} &");

    return commands.join('\n');
  }
}
