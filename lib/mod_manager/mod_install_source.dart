import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/utils/extensions.dart';

/// Archive or folder that user installs mods from.
abstract class ModInstallSource {
  FileSystemEntity get entity;

  /// Lists all the file paths, which may or may not exist on disk.
  /// Return absolute paths.
  List<String> listFilePaths();

  /// Give paths, gets real files. For archives, extracts the files to a temp folder to read them first.
  Future<List<SourcedFile>> getActualFiles(List<String> filePaths);

  /// Extracts or copies the files to the destination.
  /// [fileFilter] should be given absolute paths.
  Future<List<SourcedFile>> createFilesAtDestination(
    String destinationPath, {
    bool Function(String path)? fileFilter,
    String Function(String path)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
  });
}

/// Archive that user installs mods from.
class ArchiveModInstallSource extends ModInstallSource {
  final File _archive;
  final _libArchive = LibArchive();

  ArchiveModInstallSource(this._archive);

  @override
  FileSystemEntity get entity => _archive;

  @override
  List<String> listFilePaths() {
    return _libArchive
        .listEntriesInArchive(_archive)
        .map((entry) => entry.pathName)
        .toList();
  }

  @override
  Future<List<SourcedFile>> getActualFiles(List<String> filePaths) async {
    // Extract specified files to a temporary folder.
    final tempFolder = await Directory.systemTemp.createTemp();

    final extractedFiles = await _libArchive.extractEntriesInArchive(
      _archive,
      tempFolder.path,
      fileFilter: (entry) => filePaths.contains(entry.file.path),
    );

    return extractedFiles.nonNulls.map((extracted) {
      return SourcedFile(
        extracted.archiveFile.file.toFile(),
        extracted.extractedFile,
        extracted.archiveFile.pathName,
      );
    }).toList();
  }

  @override
  Future<List<SourcedFile>> createFilesAtDestination(
    String destinationPath, {
    bool Function(String path)? fileFilter,
    String Function(String path)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
  }) async {
    return (await _libArchive.extractEntriesInArchive(_archive, destinationPath,
            fileFilter: fileFilter != null
                ? (entry) => fileFilter(entry.file.path)
                : null,
            pathTransform: pathTransform != null
                ? (entry) => pathTransform(entry.file.path)
                : null,
            onError: onError))
        .nonNulls
        .map((it) => SourcedFile(
              it.archiveFile.file.toFile(),
              it.extractedFile,
              it.archiveFile.pathName,
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
  List<String> listFilePaths() {
    return _directory
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path)
        // .map((file) => _relativePath(file.path))
        .toList();
  }

  @override
  Future<List<SourcedFile>> getActualFiles(List<String> filePaths) async {
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
    String destinationPath, {
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
