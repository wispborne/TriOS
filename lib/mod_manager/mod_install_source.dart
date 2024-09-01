import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/utils/extensions.dart';

abstract class ModInstallSource {
  FileSystemEntity get entity;

  /// Lists all the file paths, which may or may not exist on disk.
  List<String> listFilePaths();

  /// Give paths, gets real files. For archives, extracts the files to a temp folder to read them first.
  Future<List<SourcedFile>> getActualFiles(List<String> filePaths);

  /// Extracts or copies the files to the destination.
  Future<List<SourcedFile>> createFilesAtDestination(String destinationPath,
      {bool Function(LibArchiveEntry entry)? fileFilter,
      String Function(LibArchiveEntry entry)? pathTransform,
      bool Function(Object ex, StackTrace st)? onError});
}

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
        .map((it) => it.pathName)
        .toList();
  }

  @override
  Future<List<SourcedFile>> getActualFiles(List<String> filePaths) async {
    // Extract just mod_info.json files to a temp folder.
    var modInfosTempFolder = Directory.systemTemp.createTempSync();

    final extractedModInfos = await _libArchive.extractEntriesInArchive(
      _archive,
      modInfosTempFolder.path,
      fileFilter: (entry) => filePaths.contains(entry.file.path)
    );

    return extractedModInfos.whereNotNull().map((it) {
      return SourcedFile(it.archiveFile.file.toFile(), it.extractedFile);
    }).toList();
  }

  @override
  Future<List<SourcedFile>> createFilesAtDestination(String destinationPath,
      {bool Function(LibArchiveEntry entry)? fileFilter,
      String Function(LibArchiveEntry entry)? pathTransform,
      bool Function(Object ex, StackTrace st)? onError}) async {
    return (await _libArchive.extractEntriesInArchive(_archive, destinationPath,
            fileFilter: fileFilter,
            pathTransform: pathTransform,
            onError: onError))
        .whereNotNull()
        .map((it) => SourcedFile(
              it.archiveFile.file.toFile(),
              it.extractedFile,
            ))
        .toList();
  }
}

class SourcedFile {
  final File originalFile;
  final File extractedFile;

  SourcedFile(this.originalFile, this.extractedFile);
}
