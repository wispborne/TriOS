import 'dart:async';
import 'dart:io';

import 'package:trios/compression/archive.dart';
import 'package:trios/utils/extensions.dart';

/// Archive or folder that user installs mods from.
abstract class ModInstallSource {
  FileSystemEntity get entity;

  /// Lists all the file paths, which may or may not exist on disk.
  /// Return absolute paths.
  Future<List<String>> listFilePaths(ArchiveInterface archive);

  /// Give paths, gets real files. For archives, extracts the files to a temp folder to read them first.
  Future<List<SourcedFile>> getActualFiles(
      List<String> filePaths, ArchiveInterface archive);

  /// Extracts or copies the files to the destination.
  /// [fileFilter] should be given absolute paths.
  Future<List<SourcedFile>> createFilesAtDestination(
    String destinationPath,
    ArchiveInterface archive, {
    bool Function(String path)? fileFilter,
    String Function(String path)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
  });
}

/// Archive that user installs mods from.
class ArchiveModInstallSource extends ModInstallSource {
  final File _archive;

  ArchiveModInstallSource(this._archive);

  @override
  FileSystemEntity get entity => _archive;

  @override
  Future<List<String>> listFilePaths(ArchiveInterface archive) async {
    return (await archive.listFiles(_archive))
        .map((entry) => entry.path)
        .toList();
  }

  @override
  Future<List<SourcedFile>> getActualFiles(
      List<String> filePaths, ArchiveInterface archive) async {
    // Extract specified files to a temporary folder.
    final tempFolder = await Directory.systemTemp.createTemp();

    final extractedFiles = await archive.extractEntriesInArchive(
      _archive,
      tempFolder.path,
      fileFilter: (entry) => filePaths.contains(entry.path),
    );

    return extractedFiles.nonNulls.map((extracted) {
      return SourcedFile(
        extracted.archiveFile.path.toFile(),
        extracted.extractedFile,
        extracted.archiveFile.path,
      );
    }).toList();
  }

  @override
  Future<List<SourcedFile>> createFilesAtDestination(
    String destinationPath,
    archive, {
    bool Function(String path)? fileFilter,
    String Function(String path)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
  }) async {
    return (await archive.extractEntriesInArchive(_archive, destinationPath,
            fileFilter:
                fileFilter != null ? (entry) => fileFilter(entry.path) : null,
            pathTransform: pathTransform != null
                ? (entry) => pathTransform(entry.path)
                : null,
            onError: onError))
        .nonNulls
        .map((it) => SourcedFile(
              it.archiveFile.path.toFile(),
              it.extractedFile,
              it.archiveFile.path,
            ))
        .toList();
  }
}

/// Directory that user installs mods from.
class DirectoryModInstallSource extends ModInstallSource {
  final Directory _directory;

  DirectoryModInstallSource(this._directory);

  @override
  FileSystemEntity get entity => _directory;

  @override
  Future<List<String>> listFilePaths(ArchiveInterface archive) async {
    return _directory
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path)
        // .map((file) => _relativePath(file.path))
        .toList();
  }

  @override
  Future<List<SourcedFile>> getActualFiles(
      List<String> filePaths, ArchiveInterface archive) async {
    List<SourcedFile> sourcedFiles = [];
    for (String path in filePaths) {
      File file = path.toFile();
      if (await file.exists()) {
        sourcedFiles.add(SourcedFile(
          file,
          file,
          path,
        ));
      }
    }
    return sourcedFiles;
  }

  @override
  Future<List<SourcedFile>> createFilesAtDestination(
    String destinationPath,
    ArchiveInterface archive, {
    bool Function(String path)? fileFilter,
    String Function(String path)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
  }) async {
    List<SourcedFile> sourcedFiles = [];
    try {
      await for (FileSystemEntity entity in _directory.list(recursive: true)) {
        if (entity is File) {
          String relativePath = _relativePath(entity.path);

          if (fileFilter != null && !fileFilter(entity.path)) {
            continue;
          }

          String destRelativePath =
              pathTransform != null ? pathTransform(entity.path) : relativePath;

          File destFile = File(
              '$destinationPath${Platform.pathSeparator}$destRelativePath');
          await destFile.parent.create(recursive: true);
          await entity.copy(destFile.path);

          sourcedFiles.add(SourcedFile(
            entity,
            destFile,
            relativePath,
          ));
        }
      }
    } catch (e, st) {
      if (onError == null || !onError(e, st)) {
        rethrow;
      }
    }
    return sourcedFiles;
  }

  String _relativePath(String fullPath) {
    return fullPath.replaceFirst(
        '${_directory.path}${Platform.pathSeparator}', '');
  }
}

class SourcedFile {
  final File originalFile;
  final File extractedFile;
  final String relativePath;

  SourcedFile(this.originalFile, this.extractedFile, this.relativePath);
}
