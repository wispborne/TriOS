import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/util.dart';

import '../trios/constants.dart';

/// A simple wrapper for the `7z.exe` CLI on Windows (or `7z` on other platforms),
/// using Dart's [File] and [Directory] instead of raw String paths.
///
/// Example usage:
/// ```dart
/// final sevenZip = SevenZipCLI(File(r'C:\Program Files\7-Zip\7z.exe'));
/// final archive = File(r'C:\temp\example.7z');
/// final fileToAdd = File(r'C:\temp\somefile.txt');
/// await sevenZip.createArchive(archive, [fileToAdd]);
/// ```
class SevenZipCLI {
  /// The 7-Zip executable. For example:
  /// `File(r'C:\Program Files\7-Zip\7z.exe')`.
  ///
  /// If 7z is in your system PATH, you can just do:
  /// `SevenZipCLI(File('7z.exe'))`.
  late final File sevenZipExecutable;

  /// Creates a wrapper given a [File] that points to the 7z executable.
  SevenZipCLI() {
    final assetsPath = getAssetsPath();
    sevenZipExecutable = File("$assetsPath/windows/7zip/7z.exe").normalize;
  }

  SevenZipCLI.fromPath(this.sevenZipExecutable);

  // ---------------------------------------------------------------------------
  // 1. LIST FILES
  // ---------------------------------------------------------------------------

  /// Lists all in-archive file paths in [archiveFile].
  ///
  /// Returns a list of (String) paths found inside the archive.
  /// Throws an [Exception] on error (non-zero exit code, etc.).
  Future<List<String>> listFiles(File archiveFile) async {
    // e.g. 7z l archive.7z
    final result = await Process.run(
      sevenZipExecutable.path,
      ['l', archiveFile.path],
    );

    if (result.exitCode != 0) {
      throw Exception(
        '7z list failed (exit code: ${result.exitCode}).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }

    final lines = (result.stdout as String).split('\n');
    final files = <String>[];

    // 7z prints a header, a line of dashes, then files, then another line of dashes, then summary.
    bool inFilesSection = false;
    for (var line in lines) {
      line = line.trimRight();
      if (line.startsWith('----')) {
        // Toggle or stop.
        if (!inFilesSection) {
          inFilesSection = true;
          continue;
        } else {
          break;
        }
      }
      if (inFilesSection && line.isNotEmpty) {
        // Example line:
        // "2023-01-05  10:30:00 .....         344            200  path/to/file.txt"
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 5) {
          final filePath = parts.sublist(4).join(' ');
          files.add(filePath);
        }
      }
    }

    return files;
  }

  // ---------------------------------------------------------------------------
  // 2. EXTRACT
  // ---------------------------------------------------------------------------

  /// Extracts **all** items from [archiveFile] into [destination].
  ///
  /// - Uses the `x` command to preserve directory structure.
  /// - Overwrites existing files (`-y`).
  /// - Throws [Exception] on failure.
  Future<void> extractAll(File archiveFile, Directory destination) async {
    // 7z x archive.7z -o<destination> -y
    final result = await Process.run(
      sevenZipExecutable.path,
      [
        'x',
        archiveFile.path,
        '-o${destination.path}',
        '-y',
      ],
    );

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
  ///
  /// - Overwrites existing files (`-y`).
  /// - [inArchivePaths] are the paths **inside** the archive, e.g. 'folder/file.txt'.
  /// - Throws an [Exception] on failure.
  Future<void> extractSome(
    File archiveFile,
    Directory destination,
    List<String> inArchivePaths,
  ) async {
    if (inArchivePaths.isEmpty) {
      return;
    }

    // 7z x archive.7z -o<destination> -y path1 path2 ...
    final args = [
      'x',
      archiveFile.path,
      '-o${destination.path}',
      '-y',
      ...inArchivePaths,
    ];

    final result = await Process.run(sevenZipExecutable.path, args);

    if (result.exitCode != 0) {
      throw Exception(
        '7z partial extraction failed (exit code: ${result.exitCode}).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 3. TEST ARCHIVE
  // ---------------------------------------------------------------------------

  /// Tests the integrity of [archiveFile] (e.g. 7z t) and returns:
  /// - `true` if no errors found (exit code 0)
  /// - `false` if warnings/minor issues (exit code 2)
  /// - throws [Exception] if fatal error or unknown exit code
  Future<bool> testArchive(File archiveFile) async {
    // 7z t archive.7z
    final result = await Process.run(
      sevenZipExecutable.path,
      ['t', archiveFile.path],
    );

    // 7z returns 0 (no error), 1 (some error, used less often),
    // 2 (warning), and > 2 for fatal errors.
    // We'll interpret 2 as "archive is at least partially corrupt."
    // Adjust logic as needed.
    final exit = result.exitCode;
    if (exit == 0) {
      return true; // OK
    } else if (exit == 2) {
      return false; // Warnings found
    } else {
      throw Exception(
        '7z test failed (exit code: $exit).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 4. CREATE / ADD FILES
  // ---------------------------------------------------------------------------

  /// Creates a new archive at [archiveFile] containing [filesToAdd].
  /// If [archiveFile] already exists, 7-Zip will add or overwrite items.
  ///
  /// - Pass optional [extraArgs] for advanced CLI usage (e.g., `['-mx9']` for ultra compression).
  /// - Throws [Exception] on failure.
  Future<void> createArchive(
    File archiveFile,
    List<File> filesToAdd, {
    List<String> extraArgs = const [],
  }) async {
    if (filesToAdd.isEmpty) {
      return;
    }

    // 7z a archive.7z file1 file2 ... [extraArgs]
    final args = [
      'a',
      archiveFile.path,
      ...filesToAdd.map((f) => f.path),
      ...extraArgs,
    ];

    final result = await Process.run(sevenZipExecutable.path, args);

    if (result.exitCode != 0) {
      throw Exception(
        '7z createArchive failed (exit code: ${result.exitCode}).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  /// Adds [filesToAdd] to an existing archive [archiveFile].
  /// This is just a wrapper around [createArchive], but you can
  /// keep them separate for conceptual clarity.
  Future<void> addFiles(
    File archiveFile,
    List<File> filesToAdd, {
    List<String> extraArgs = const [],
  }) =>
      createArchive(archiveFile, filesToAdd, extraArgs: extraArgs);

  // ---------------------------------------------------------------------------
  // 5. DELETE FROM ARCHIVE
  // ---------------------------------------------------------------------------

  /// Deletes [inArchivePaths] (files **inside** the archive) from [archiveFile].
  ///
  /// - e.g. 7z d archive.7z folder/file.txt
  /// - Throws [Exception] on failure.
  Future<void> deleteFromArchive(
      File archiveFile, List<String> inArchivePaths) async {
    if (inArchivePaths.isEmpty) {
      return;
    }

    final args = [
      'd',
      archiveFile.path,
      ...inArchivePaths,
    ];

    final result = await Process.run(sevenZipExecutable.path, args);

    if (result.exitCode != 0) {
      throw Exception(
        '7z deleteFromArchive failed (exit code: ${result.exitCode}).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 6. UPDATE ARCHIVE
  // ---------------------------------------------------------------------------

  /// Updates [archiveFile] by adding/changing [filesToUpdate].
  /// If a file is already up-to-date, it won’t be replaced.
  ///
  /// - 7z u archive.7z file1 file2 ...
  /// - Throws an [Exception] on failure.
  Future<void> updateArchive(
    File archiveFile,
    List<File> filesToUpdate, {
    List<String> extraArgs = const [],
  }) async {
    if (filesToUpdate.isEmpty) {
      return;
    }

    final args = [
      'u',
      archiveFile.path,
      ...filesToUpdate.map((f) => f.path),
      ...extraArgs,
    ];

    final result = await Process.run(sevenZipExecutable.path, args);

    if (result.exitCode != 0) {
      throw Exception(
        '7z updateArchive failed (exit code: ${result.exitCode}).\n'
        'stdout: ${result.stdout}\n'
        'stderr: ${result.stderr}',
      );
    }
  }
}
