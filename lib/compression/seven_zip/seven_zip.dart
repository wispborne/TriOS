import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:trios/compression/archive.dart'; // your interface
import 'package:trios/trios/constants.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/util.dart'; // your own utilities

class SevenZipEntry implements ArchiveEntry {
  @override
  final String path;

  SevenZipEntry(this.path);

  @Deprecated('Use path instead.')
  String get pathName => path;

  late FileSystemEntity file = FileSystemEntity.isDirectorySync(path)
      ? Directory(path)
      : File(path);

  @override
  String toString() => path;
}

class SevenZipExtractedFile implements ArchiveExtractedFile<SevenZipEntry> {
  @override
  final SevenZipEntry archiveFile;
  @override
  final File extractedFile;

  SevenZipExtractedFile(this.archiveFile, this.extractedFile);
}

class SevenZipReadFile implements ArchiveReadFile<SevenZipEntry> {
  @override
  final SevenZipEntry archiveFile;
  @override
  final Uint8List extractedContent;

  SevenZipReadFile(this.archiveFile, this.extractedContent);
}

/// A simple wrapper for the `7z.exe` CLI on Windows (or `7z` on other platforms),
/// using Dart's [File] and [Directory] instead of raw String paths.
class SevenZip implements ArchiveInterface {
  late final File sevenZipExecutable;

  SevenZip() {
    final assetsPath = getAssetsPath();
    sevenZipExecutable = switch (currentPlatform) {
      TargetPlatform.windows => File(
        "$assetsPath/windows/7zip/7z.exe",
      ).normalize,
      TargetPlatform.linux => () {
        final platform = Process.runSync('uname', [
          '-m',
        ]).stdout.toString().trim();
        final executable = switch (platform) {
          "x86_64" => assetsPath.toDirectory().resolve("linux/7zip/x64/7zzs"),
          "aarch64" => assetsPath.toDirectory().resolve(
            "linux/7zip/arm64/7zzs",
          ),
          _ => throw Exception("Not supported: $platform"),
        }.toFile();

        final chmodResult = Process.runSync('chmod', ['+x', executable.path]);
        final success = chmodResult.stdout.toString().trim();
        final failure = chmodResult.stderr.toString().trim();
        Fimber.i(
          "Making $executable executable result: success: $success, error: $failure",
        );
        return executable;
      }(),
      TargetPlatform.macOS => () {
        final executable = assetsPath
            .toDirectory()
            .resolve("macos/7zip/7zz")
            .toFile();
        final chmodResult = Process.runSync('chmod', ['+x', executable.path]);
        final success = chmodResult.stdout.toString().trim();
        final failure = chmodResult.stderr.toString().trim();
        Fimber.i(
          "Making $executable executable result: success: $success, error: $failure",
        );
        return executable;
      }(),
      _ => File(
        '7z',
      ), // Consider throwing an exception for unsupported platforms
    };
  }

  SevenZip.fromPath(this.sevenZipExecutable);

  /// ---------------------------------------------------------------------------
  /// Private helper to handle potential command line length issues.
  /// If [additionalArgs] is too big, we write them to a temp file and pass
  /// `@listFile` to 7z. Otherwise, pass them inline.
  /// Returns the [ProcessResult].
  Future<ProcessResult> _run7zCommandWithPossibleFileList(
    List<String> baseArgs,
    List<String> additionalArgs, {
    int maxCmdLength = 8000,
  }) async {
    // Calculate the total length if we pass them inline
    final inlineLength =
        baseArgs.fold<int>(0, (sum, arg) => sum + arg.length + 1) +
        additionalArgs.fold<int>(0, (sum, arg) => sum + arg.length + 1);

    if (inlineLength <= maxCmdLength) {
      // Safely pass them inline
      final args = [...baseArgs, ...additionalArgs];
      return Process.run(sevenZipExecutable.path, args);
    } else {
      // Write the additional args to a temp file
      final listFile = File(
        p.join(
          Directory.systemTemp.path,
          '7z_filelist_${DateTime.now().millisecondsSinceEpoch}.txt',
        ),
      );
      await listFile.writeAsString(additionalArgs.join('\n'), flush: true);

      // Use the @listFile syntax
      final args = [...baseArgs, '@${listFile.path}'];
      final result = await Process.run(sevenZipExecutable.path, args);

      // Clean up
      try {
        if (listFile.existsSync()) {
          listFile.deleteSync();
        }
      } catch (_) {
        // ignore
      }

      return result;
    }
  }

  /// Lists all in-archive file paths in [archiveFile].
  /// Returns a list of (String) paths found inside the archive.
  /// Throws an [Exception] on error (non-zero exit code, etc.).
  @override
  Future<List<SevenZipEntry>> listFiles(File archiveFile) async {
    final result = await Process.run(sevenZipExecutable.path, [
      'l',
      '-slt',
      '-sccUTF-8', // Tells 7zip to use UTF-8 for the output instead of DOS
      archiveFile.path,
    ], stdoutEncoding: utf8);

    if (result.exitCode != 0) {
      throw Exception(
        '7z list failed (exit code: ${result.exitCode}).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }

    final lines = (result.stdout as String).split('\n');
    final files = <SevenZipEntry>[];
    for (final line in lines) {
      final trimmed = line.trimRight();
      if (trimmed.startsWith('Path = ')) {
        final filePath = trimmed.substring('Path = '.length);
        if (filePath.isNotEmpty && filePath != archiveFile.path) {
          files.add(SevenZipEntry(filePath));
        }
      }
    }
    return files;
  }

  /// Extracts **all** items from [archiveFile] into [destination].
  /// Uses the `x` command to preserve directory structure.
  /// Overwrites existing files (`-y`).
  /// Throws [Exception] on failure.
  @override
  Future<void> extractAll(File archiveFile, Directory destination) async {
    final result = await Process.run(sevenZipExecutable.path, [
      'x',
      archiveFile.path,
      '-o${destination.path}',
      '-y',
      '-sccUTF-8', // Tells 7zip to use UTF-8 for the output instead of DOS
    ], stdoutEncoding: utf8);

    if (result.exitCode != 0) {
      throw Exception(
        '7z extraction (all) failed (exit code: ${result.exitCode}).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  /// Extracts only the given [inArchivePaths] (files inside the archive)
  /// from [archiveFile] into [destination].
  /// Overwrites existing files (`-y`).
  /// Throws an [Exception] on failure.
  @override
  Future<void> extractSome(
    File archiveFile,
    Directory destination,
    List<String> inArchivePaths,
  ) async {
    if (inArchivePaths.isEmpty) {
      return;
    }

    final baseArgs = ['x', archiveFile.path, '-o${destination.path}', '-y'];

    final result = await _run7zCommandWithPossibleFileList(
      baseArgs,
      inArchivePaths,
    );
    if (result.exitCode != 0) {
      throw Exception(
        '7z partial extraction failed (exit code: ${result.exitCode}).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  /// Extracts entries from [archivePath] to [destinationPath] in a single call.
  /// If the number of in-archive paths is huge, we fallback to a file-based approach.
  /// Creates a new temp folder each time it's called, so avoid spamming this call.
  /// The temp folder is needed because 7zip cannot transform a file's path during extraction,
  /// and we don't want to extract to a folder (the folder name inside the archive, not the transformed path) that already exists.
  @override
  Future<List<SevenZipExtractedFile?>> extractEntriesInArchive(
    File archivePath,
    String destinationPath, {
    bool Function(SevenZipEntry entry)? fileFilter,
    String Function(SevenZipEntry entry)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
  }) async {
    final maxRenameRetries = 10;
    final renameRetryDelay = Duration(milliseconds: 200);

    final allEntries = await listFiles(archivePath);
    final toExtract = allEntries
        .where((e) => fileFilter == null || fileFilter(e))
        .toList();
    if (toExtract.isEmpty) return [];

    // Unlike libarchive, 7zip cannot transform a file's path during extraction.
    // Create a temporary folder to extract to, preventing any folder name collisions
    // e.g. if "LazyLib" already exists in the mod folder, we don't want to extract to it.
    final tempFolder = (await Directory.systemTemp.createTemp(
      "${Constants.appName}-${archivePath.hashCode}",
    )).normalize.path;

    final results = <SevenZipExtractedFile?>[];

    final baseArgs = ['x', archivePath.path, '-y', '-o$tempFolder'];
    final inArchivePaths = toExtract.map((e) => e.path).toList();

    final extractionResult = await _run7zCommandWithPossibleFileList(
      baseArgs,
      inArchivePaths,
    );

    try {
      if (extractionResult.exitCode != 0) {
        throw Exception(
          '7z extraction failed (exit code: ${extractionResult.exitCode}).\n'
          'stdout: ${extractionResult.stdout}\n'
          'stderr: ${extractionResult.stderr}',
        );
      }
      final oldFiles = toExtract
          .map((entry) => File('$tempFolder/${entry.path}'))
          .toList();
      await oldFiles.waitToBeAccessible();

      for (final entry in toExtract) {
        try {
          final oldFile = File('$tempFolder/${entry.path}');
          final transformed = pathTransform?.call(entry) ?? entry.path;
          final newFile = File('$destinationPath/$transformed');

          if (oldFile.path != newFile.path && oldFile.existsSync()) {
            await newFile.parent.create(recursive: true);

            bool renamed = false;
            for (var i = 0; i < maxRenameRetries && !renamed; i++) {
              try {
                await oldFile.renameSafely(newFile.path);
                renamed = true;
              } on FileSystemException catch (e) {
                // Possibly locked by AV, or 7z hasn't released it yet, etc.
                if (i < maxRenameRetries - 1) {
                  // Log a warning, then wait briefly before trying again
                  Fimber.w(
                    'Rename attempt ${i + 1} failed. Retrying...',
                    ex: e,
                  );
                  await Future.delayed(renameRetryDelay);
                } else {
                  // After the last attempt, rethrow
                  rethrow;
                }
              }
            }
          } else if (!oldFile.isDirectory()) {
            Fimber.i(
              "${oldFile.path} did not exist or was already in place (same as transformed path). Skipped.",
            );
          }

          // Check that the file was extracted correctly. Directories are created automatically and don't show up here.
          if (oldFile.isDirectory() || await newFile.exists()) {
            results.add(SevenZipExtractedFile(entry, newFile));
          }
        } catch (ex, st) {
          if (onError != null && onError(ex, st) == true) {
            continue;
          }
          rethrow;
        }
      }
    } finally {
      try {
        if (tempFolder.toDirectory().existsSync()) {
          tempFolder.toDirectory().deleteSync(recursive: true);
        }
      } catch (ex, st) {
        Fimber.e(
          "Error deleting temporary folder: $tempFolder",
          ex: ex,
          stacktrace: st,
        );
      }
    }

    try {
      // Wait for all files to be accessible before returning.
      await results
          .map((it) => it?.extractedFile)
          .whereType<File>()
          .toList()
          .waitToBeAccessible();
    } catch (e, st) {
      Fimber.w(
        "Error waiting for files to be accessible after extraction.",
        ex: e,
        stacktrace: st,
      );
    }

    return results;
  }

  Future<bool> testArchive(File archiveFile) async {
    final result = await Process.run(sevenZipExecutable.path, [
      't',
      archiveFile.path,
    ]);

    final exit = result.exitCode;
    if (exit == 0) {
      return true;
    } else if (exit == 1 || exit == 2) {
      return false;
    } else {
      throw Exception(
        '7z test failed (exit code: $exit).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  /// Creates a new archive at [archiveFile] containing [filesToAdd].
  /// If [archiveFile] already exists, 7-Zip will add or overwrite items.
  /// Throws [Exception] on failure.
  Future<void> createArchive(
    File archiveFile,
    List<File> filesToAdd, {
    List<String> extraArgs = const [],
  }) async {
    if (filesToAdd.isEmpty) {
      return;
    }

    final baseArgs = ['a', archiveFile.path, ...extraArgs];
    final filePaths = filesToAdd.map((f) => f.path).toList();

    final result = await _run7zCommandWithPossibleFileList(baseArgs, filePaths);
    if (result.exitCode != 0) {
      throw Exception(
        '7z createArchive failed (exit code: ${result.exitCode}).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  Future<void> addFiles(
    File archiveFile,
    List<File> filesToAdd, {
    List<String> extraArgs = const [],
  }) => createArchive(archiveFile, filesToAdd, extraArgs: extraArgs);

  Future<void> deleteFromArchive(
    File archiveFile,
    List<String> inArchivePaths,
  ) async {
    if (inArchivePaths.isEmpty) {
      return;
    }

    final baseArgs = ['d', archiveFile.path];
    final result = await _run7zCommandWithPossibleFileList(
      baseArgs,
      inArchivePaths,
    );
    if (result.exitCode != 0) {
      throw Exception(
        '7z deleteFromArchive failed (exit code: ${result.exitCode}).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  /// Updates [archiveFile] by adding/changing [filesToUpdate].
  /// If a file is already up-to-date, it won’t be replaced.
  /// Throws [Exception] on failure.
  Future<void> updateArchive(
    File archiveFile,
    List<File> filesToUpdate, {
    List<String> extraArgs = const [],
  }) async {
    if (filesToUpdate.isEmpty) {
      return;
    }

    final baseArgs = ['u', archiveFile.path, ...extraArgs];
    final filePaths = filesToUpdate.map((f) => f.path).toList();

    final result = await _run7zCommandWithPossibleFileList(baseArgs, filePaths);
    if (result.exitCode != 0) {
      throw Exception(
        '7z updateArchive failed (exit code: ${result.exitCode}).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  /// Streams the contents of a single file within an archive as bytes.
  /// @param archiveFile The archive file
  /// @param inArchivePath The path within the archive
  Future<Uint8List> _readSingleFileAsBytes(
    File archiveFile,
    String inArchivePath,
  ) async {
    final process = await Process.start(sevenZipExecutable.path, [
      'x',
      archiveFile.path,
      '-y',
      '-so',
      inArchivePath,
    ]);

    final collectedBytes = <int>[];
    await for (final chunk in process.stdout) {
      collectedBytes.addAll(chunk);
    }

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final stderrData = await process.stderr
          .transform(systemEncoding.decoder)
          .join();
      throw Exception(
        '7z extraction of $inArchivePath failed (exit code: $exitCode).\n'
        'stderr: $stderrData',
      );
    }

    return Uint8List.fromList(collectedBytes);
  }

  /// Reads entries into memory from [archivePath].
  /// @param archivePath The archive file
  /// @param fileFilter Optional filter function to decide which entries to read
  /// @param pathTransform Optional transform function for the entry path
  /// @param onError Optional error callback; return true to skip, otherwise rethrow
  @override
  Future<List<SevenZipReadFile?>> readEntriesInArchive(
    File archivePath, {
    bool Function(SevenZipEntry entry)? fileFilter,
    String Function(SevenZipEntry entry)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
  }) async {
    final allEntries = await listFiles(archivePath);
    final results = <SevenZipReadFile?>[];
    for (final entry in allEntries) {
      if (fileFilter != null && !fileFilter(entry)) {
        continue;
      }
      try {
        final content = await _readSingleFileAsBytes(archivePath, entry.path);
        results.add(SevenZipReadFile(entry, content));
      } catch (ex, st) {
        if (onError != null && onError(ex, st) == true) {
          continue;
        }
        rethrow;
      }
    }
    return results;
  }
}
