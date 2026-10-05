import 'dart:convert';
import 'dart:io';

import 'package:trios/compression/seven_zip/seven_zip.dart';

/// One item inside an archive.
class SaveArchiveEntry {
  /// Path inside the archive, always separated by `/`, never starting with one.
  final String path;

  final int sizeInBytes;

  /// The checksum the archive recorded for this item, or null when it didn't
  /// record one. Folders and empty files have no checksum.
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

/// The archive operations [SaveArchiver] needs, and nothing else.
///
/// This exists so tests can hand the archiver a tool that fails in one exact
/// way — writes a truncated archive, loses a file, reports a bad checksum — and
/// check that the original save survives it. Those are the cases that would
/// cost somebody hundreds of hours, and they can't be triggered on demand with
/// a real 7-Zip.
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
  /// Returns false when the archive is damaged. Throws when it can't be read at
  /// all; the archiver treats a throw the same as a false.
  Future<bool> passesIntegrityTest(File archiveFile);

  /// Everything the archive holds, files and folders.
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

  /// Compression level passed to 7-Zip. Save files are XML and shrink a lot
  /// even at the default level; a higher one costs minutes and saves little.
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
    // Save files are UTF-8, but a damaged one shouldn't throw on the way to
    // being reported as damaged.
    return utf8.decode(found.extractedContent, allowMalformed: true);
  }
}

/// Puts an in-archive path in the one shape the archiver compares against:
/// `/` separators, no leading or trailing separator, no `./` prefix.
///
/// 7-Zip writes `\` on Windows and `/` everywhere else, for the same archive.
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
