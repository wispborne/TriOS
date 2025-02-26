import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'seven_zip/seven_zip.dart';

final archiveProvider = FutureProvider<ArchiveInterface>((ref) async {
  return SevenZip();
});

/// Represents a basic archive entry with a [path].
abstract class ArchiveEntry {
  String get path;
}

/// Represents a file extracted from an archive.
abstract class ArchiveExtractedFile<E extends ArchiveEntry> {
  E get archiveFile;

  File get extractedFile;
}

/// Represents a file (and its content) read from an archive.
abstract class ArchiveReadFile<E extends ArchiveEntry> {
  E get archiveFile;

  Uint8List get extractedContent;
}

/// Common interface for archive operations.
abstract class ArchiveInterface {
  /// Lists all in-archive file paths in [archiveFile].
  Future<List<ArchiveEntry>> listFiles(File archiveFile);

  /// Extracts **all** items from [archiveFile] into [destination].
  Future<void> extractAll(File archiveFile, Directory destination);

  /// Extracts only the given [inArchivePaths] from [archiveFile] into [destination].
  Future<void> extractSome(
    File archiveFile,
    Directory destination,
    List<String> inArchivePaths,
  );

  /// Tests the integrity of [archiveFile].
  /// Returns `true` if fully OK, `false` if warnings, otherwise throws [Exception].
  // Future<bool> testArchive(File archiveFile);

  /// Creates a new archive at [archiveFile] containing [filesToAdd].
  // Future<void> createArchive(File archiveFile, List<File> filesToAdd, {List<String> extraArgs = const []});

  /// Adds [filesToAdd] to an existing archive [archiveFile].
  // Future<void> addFiles(File archiveFile, List<File> filesToAdd, {List<String> extraArgs = const []});

  /// Deletes [inArchivePaths] from [archiveFile].
  // Future<void> deleteFromArchive(File archiveFile, List<String> inArchivePaths);

  /// Updates [archiveFile] by adding/changing [filesToUpdate].
  // Future<void> updateArchive(File archiveFile, List<File> filesToUpdate, {List<String> extraArgs = const []});

  /// Extracts entries in a single call.
  Future<List<ArchiveExtractedFile?>> extractEntriesInArchive(
    File archivePath,
    String destinationPath, {
    bool Function(ArchiveEntry entry)? fileFilter,
    String Function(ArchiveEntry entry)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
  });

  /// Reads entries into memory from [archivePath].
  /// @param archivePath The archive file
  /// @param fileFilter Optional filter function to decide which entries to read
  /// @param pathTransform Optional transform function for the entry path
  /// @param onError Optional error callback; return true to skip, otherwise rethrow
  Future<List<ArchiveReadFile?>> readEntriesInArchive(
    File archivePath, {
    bool Function(ArchiveEntry entry)? fileFilter,
    String Function(ArchiveEntry entry)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
  });
}
