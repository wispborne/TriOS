import 'dart:convert';
import 'dart:io';

import 'package:trios/compression/seven_zip/seven_zip.dart';

class SaveArchiveEntry {
  /// Path inside the archive, always separated by `/`, never starting with one.
  final String path;

  final int sizeInBytes;

  /// Null when the archive records no checksum, including for empty files.
  final int? crc32;

  final bool isDirectory;

  const SaveArchiveEntry({
    required this.path,
    required this.sizeInBytes,
    required this.crc32,
    required this.isDirectory,
  });

  @override
  String toString() =>
      'SaveArchiveEntry($path, $sizeInBytes bytes, crc: $crc32, dir: $isDirectory)';
}

/// Archive operations used by the save archiver.
///
/// Tests can inject compression, corruption, and extraction failures without
/// depending on a real 7-Zip process.
abstract class SaveArchiveTool {
  /// Compresses [sourceFolder] into [archiveFile].
  ///
  /// Paths inside the archive start with [sourceFolder]'s own name, so
  /// extracting into a parent folder recreates the folder itself.
  Future<void> create({
    required File archiveFile,
    required Directory sourceFolder,
  });

  /// Runs the archive format's own integrity check.
  ///
  /// The archiver treats false and exceptions as verification failures.
  Future<bool> passesIntegrityTest(File archiveFile);

  /// Lists both files and directories.
  Future<List<SaveArchiveEntry>> listEntries(File archiveFile);

  /// Unpacks everything in [archiveFile] into [destination].
  Future<void> extractAll({
    required File archiveFile,
    required Directory destination,
  });

  /// Reads one entry out of [archiveFile] as text, without unpacking the rest.
  ///
  /// Returns null when the archive has no such entry.
  Future<String?> readTextEntry(File archiveFile, String entryPath);
}

/// [SaveArchiveTool] backed by the bundled 7-Zip command line tool.
class SevenZipSaveArchiveTool implements SaveArchiveTool {
  final SevenZip sevenZip;

  final int compressionLevel;

  SevenZipSaveArchiveTool(this.sevenZip, {this.compressionLevel = 5});

  @override
  Future<void> create({
    required File archiveFile,
    required Directory sourceFolder,
  }) => sevenZip.createArchiveFromFolder(
    archiveFile,
    sourceFolder,
    extraArgs: ['-mx=$compressionLevel', '-mmt=on'],
  );

  @override
  Future<bool> passesIntegrityTest(File archiveFile) =>
      sevenZip.testArchive(archiveFile);

  @override
  Future<List<SaveArchiveEntry>> listEntries(File archiveFile) async {
    final listed = await sevenZip.listEntriesWithDetails(archiveFile);
    return listed
        .map(
          (entry) => SaveArchiveEntry(
            path: normalizeArchivePath(entry.path),
            sizeInBytes: entry.size,
            crc32: entry.crc32,
            isDirectory: entry.isDirectory,
          ),
        )
        .toList();
  }

  @override
  Future<void> extractAll({
    required File archiveFile,
    required Directory destination,
  }) => sevenZip.extractAll(archiveFile, destination);

  @override
  Future<String?> readTextEntry(File archiveFile, String entryPath) async {
    final wanted = normalizeArchivePath(entryPath).toLowerCase();
    final read = await sevenZip.readEntriesInArchive(
      archiveFile,
      fileFilter: (entry) =>
          normalizeArchivePath(entry.path).toLowerCase() == wanted,
    );
    final found = read.nonNulls.firstOrNull;
    if (found == null) return null;
    // Leave damaged descriptor content for the parser to handle.
    return utf8.decode(found.extractedContent, allowMalformed: true);
  }
}

/// Normalizes paths for comparison across platforms:
/// `/` separators, no leading or trailing separator, no `./` prefix.
///
/// 7-Zip uses platform-specific separators when listing the same archive.
String normalizeArchivePath(String path) {
  var normalized = path.replaceAll('\\', '/');
  while (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }
  while (normalized.startsWith('/')) {
    normalized = normalized.substring(1);
  }
  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}
