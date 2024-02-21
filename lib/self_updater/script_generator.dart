import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../utils/extensions.dart';
import '../utils/util.dart';

class ScriptGenerator {
  /// Write a script to a file that will update the files in [filePairs] and then run the current executable.
  /// For destDir, use `Directory.systemTemp` to write to the system temp directory.
  static Future<File> writeUpdateScriptToFileManual(List<Tuple2<File?, File>> filePairs, Directory scriptDestDir,
      {int delaySeconds = 3}) async {
    final tempFileNameExt = switch (currentPlatform) {
      TargetPlatform.windows => "bat",
      TargetPlatform.macOS => "sh",
      TargetPlatform.linux => "sh",
      _ => throw UnsupportedError("Unsupported platform: ${Platform.operatingSystem}"),
    };

    if (!scriptDestDir.existsSync()) {
      scriptDestDir.createSync(recursive: true);
    }

    final tempFile = File('${scriptDestDir.path}/TriOS_self_updater.$tempFileNameExt');
    await tempFile.writeAsString(generateFileUpdateScript(filePairs, Platform.operatingSystem, delaySeconds));
    return tempFile;
  }

  static Future<File> writeUpdateScriptToFileSimple(Directory sourceDir, Directory destDir,
      {int delaySeconds = 3}) async {
    final filePairs = sourceDir
        .listSync(recursive: true)
        .map((e) {
          if (e is File) {
            return Tuple2(e, File(p.join(destDir.path, e.relativeTo(sourceDir))));
          }
          return null;
        })
        .whereType<Tuple2<File, File>>()
        .toList();

    return writeUpdateScriptToFileManual(filePairs, destDir, delaySeconds: delaySeconds);
  }

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
        commands.add('md "${p.dirname(targetFile.path)}" 2>nul');
        commands.add('move /Y "${sourceFile.path}" "${targetFile.path}"');
      }
    }

    // windows batch command to run Platform.executable in a new thread
    commands.add('echo Update complete. Running ${Platform.executable}...');
    commands.add('start "" "${Platform.executable}"');
    commands.add('pause');

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
