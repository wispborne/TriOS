import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';

class ScriptGenerator {
  static const SELF_UPDATE_FILE_NAME = "TriOS_self_updater";



  static String scriptName() {
    final tempFileNameExt = switch (currentPlatform) {
      TargetPlatform.windows => "bat",
      TargetPlatform.macOS => "sh",
      TargetPlatform.linux => "sh",
      _ => throw UnsupportedError(
          "Unsupported platform: ${Platform.operatingSystem}"),
    };

    final scriptName = "$SELF_UPDATE_FILE_NAME.$tempFileNameExt";
    return scriptName;
  }

  /// Write a script to a file that will update the files in [filePairs] and then run the current executable.
  /// For destDir, use `Directory.systemTemp` to write to the system temp directory.
  static Future<File> writeUpdateScriptToFileManual(
      List<Tuple2<File?, File>> filePairs, Directory scriptDestDir,
      {int delaySeconds = 2}) async {
    if (!scriptDestDir.existsSync()) {
      scriptDestDir.createSync(recursive: true);
    }

    final tempFile = File('${scriptDestDir.path}/${scriptName()}');
    await tempFile.writeAsString(
      generateFileUpdateScript(
        filePairs,
        scriptDestDir.resolve(Platform.executable) as File,
        Platform.operatingSystem,
        delaySeconds,
      ),
    );
    return tempFile;
  }

  static Future<File> writeUpdateScriptToFileSimple(
      Directory sourceDir, Directory destDir,
      {int delaySeconds = 2}) async {
    final filePairs = sourceDir
        .listSync(recursive: true)
        .map((e) {
          if (e is File) {
            return Tuple2(
                e, File(p.join(destDir.path, e.relativeTo(sourceDir))));
          }
          return null;
        })
        .whereType<Tuple2<File, File>>()
        .toList();

    return writeUpdateScriptToFileManual(filePairs, destDir,
        delaySeconds: delaySeconds);
  }

  static String generateFileUpdateScript(List<Tuple2<File?, File>> filePairs,
      File triOSFile, String platform, int delaySeconds) {
    switch (platform) {
      case "windows":
        throw UnimplementedError(
            'Script generation not supported for this platform');
      case "linux":
      case "macos":
        return _generateBashScript(filePairs, triOSFile, delaySeconds, currentPlatform);
      default:
        throw UnimplementedError(
            'Script generation not supported for this platform');
    }
  }

  /// Generates a bash script that:
  ///
  /// 1. Waits for [delaySeconds] seconds.
  /// 2. Deletes or moves the files in [filePairs] to their respective target paths.
  /// 3. Runs the current executable in a new thread.
  ///
  /// The generated script will be a series of bash commands concatenated together.
  ///
  /// [filePairs] is a list of tuples, where the first element is the source file
  /// and the second element is the target file. If the target file is null, the
  /// source file will be deleted. If the source file does not exist, it will be
  /// ignored.
  ///
  /// [triOSFile] is the file that will be run in a new thread.
  ///
  /// [platform] is the current platform.
  ///
  /// Throws an [UnimplementedError] if the platform is not supported.
  ///
  /// Returns the generated script as a string.
  static String _generateBashScript(List<Tuple2<File?, File?>> filePairs,
      File triOSFile, int delaySeconds, TargetPlatform? platform) {
    final commands = <String>[];
    commands.add('#!/bin/bash');
    commands.add('sleep $delaySeconds'); // Unix wait command

    for (final pair in filePairs) {
      final sourceFile = pair.item1;
      final targetFile = pair.item2;

      if (sourceFile != null &&
          sourceFile.existsSync() == true &&
          targetFile == null) {
        commands.add('rm "${sourceFile.path}"');
      } else if (sourceFile != null &&
          sourceFile.existsSync() &&
          targetFile != null) {
        commands.add('mv -f "${sourceFile.path}" "${targetFile.path}"');
      }
    }
    // bash command to run Platform.executable in a new thread
    if (platform == TargetPlatform.macOS) {
      commands.add("${triOSFile.absolute.path} &");
    } else {
      // Linux
      commands.add("chmod +x ${Platform.resolvedExecutable.toFile().absolute.path}");
      commands.add("${Platform.resolvedExecutable.toFile().absolute.path} &");
    }

    return commands.join('\n');
  }
}
