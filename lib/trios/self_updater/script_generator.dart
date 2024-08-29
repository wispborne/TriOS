import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';

class ScriptGenerator {
  static const SELF_UPDATE_FILE_NAME = "TriOS_self_updater";

  static String scriptName() {
    final tempFileNameExt = switch (currentPlatform) {
      TargetPlatform.windows => "ps1",
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
        return _generatePowerShellScript(filePairs, triOSFile, delaySeconds);
      case "linux":
      case "macos":
        return _generateBashScript(filePairs, triOSFile, delaySeconds);
      default:
        throw UnimplementedError(
            'Script generation not supported for this platform');
    }
  }

  /// IMPORTANT: All lines must be a single line because they are run one line at a time because of the French.
  static String _generatePowerShellScript(
      List<Tuple2<File?, File?>> filePairs, File triOSFile, int delaySeconds,
      {bool dryRun = false}) {
    final commands = <String>[];

    commands.add(
        '\$OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding');
    // Set verbose output preference
    commands.add('\$VerbosePreference = "Continue"');

    // Add sleep delay
    commands.add('Start-Sleep -Seconds $delaySeconds');

    // Iterate over file pairs to generate move or delete commands
    for (final pair in filePairs) {
      final sourceFile = pair.item1;
      final targetFile = pair.item2;

      if (sourceFile != null && sourceFile.existsSync() && targetFile == null) {
        // Delete the source file if no target file is specified
        if (dryRun) {
          commands.add('Write-Host "Would remove: ${sourceFile.path}"');
        } else {
          commands.add('Remove-Item -Path "${sourceFile.path}" -Force');
        }
      } else if (sourceFile != null &&
          sourceFile.existsSync() &&
          targetFile != null) {
        // Ensure paths are properly quoted
        final sourcePath = sourceFile.path.replaceAll(r'\', r'\\');
        final targetPath = targetFile.path.replaceAll(r'\', r'\\');
        final targetDir = targetFile.parent.path.replaceAll(r'\', r'\\');

        // Create the target directory if it doesn't exist
        if (dryRun) {
          commands.add('Write-Host "Would create directory: $targetDir"');
          commands.add('Write-Host "Would move: $sourcePath to $targetPath"');
        } else {
          commands.add(
              'if (-not (Test-Path -Path "$targetDir")) { New-Item -ItemType Directory -Force -Path "$targetDir" }');
          // Move the file from source to target
          commands.add(
              'Move-Item -Path "$sourcePath" -Destination "$targetPath" -Force');
        }
      }
    }

    // Print a message indicating the update is complete and run the executable
    final triOSFilePath = triOSFile.absolute.path.replaceAll(r'\', r'\\');
    if (dryRun) {
      commands.add('Write-Host "Would run: $triOSFilePath"');
    } else {
      commands.add('Write-Host "Update complete. Running $triOSFilePath..."');
      commands.add('Start-Process -FilePath "$triOSFilePath"');
    }
    commands.add('pause');

    return commands.join('\r\n');
  }

  static String _generateBashScript(
      List<Tuple2<File?, File?>> filePairs, File triOSFile, int delaySeconds) {
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
    commands.add("${triOSFile.absolute.path} &");

    return commands.join('\n');
  }
}
