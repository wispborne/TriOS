import 'dart:io';

import 'package:archive/archive.dart' show getCrc32;
import 'package:path/path.dart' as p;
import 'package:trios/save_archiver/save_archive_tool.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

/// Archive and restore failures. Outcome flags describe which steps completed.
enum SaveArchiveFailure {
  saveFolderMissing,

  saveFolderEmpty,

  saveFolderOutsideSavesFolder,

  /// The archive folder sits inside the save folder being archived, so
  /// archiving would try to compress its own output.
  archiveFolderInsideSaveFolder,

  archiveFolderNotWritable,

  compressionFailed,

  integrityTestFailed,

  /// A file is missing from the archive or has a different size or checksum.
  contentsDoNotMatch,

  /// The save contains a link that cannot be verified against the archive.
  unsupportedFolderContents,

  /// The archive is verified, but the original save folder remains.
  couldNotRemoveOriginal,

  archiveMissing,

  archiveEmpty,

  saveAlreadyExists,

  extractionFailed,

  /// Extracted files differ from the archive, or the file count changed after
  /// the move. Check [RestoreSaveOutcome.restored] before treating this as a
  /// failed restore.
  extractedContentsDoNotMatch,

  couldNotMoveIntoPlace,

  unexpectedError,
}

enum SaveArchiveStep {
  checking,
  readingSaveFolder,
  compressing,
  verifying,
  removingOriginal,
  extracting,
  movingIntoPlace,
  copying,
  finished,
}

extension SaveArchiveStepLabel on SaveArchiveStep {
  String get label => switch (this) {
    SaveArchiveStep.checking => 'Checking',
    SaveArchiveStep.readingSaveFolder => 'Reading save',
    SaveArchiveStep.compressing => 'Compressing',
    SaveArchiveStep.verifying => 'Verifying',
    SaveArchiveStep.copying => 'Copying',
    SaveArchiveStep.removingOriginal => 'Removing original',
    SaveArchiveStep.extracting => 'Unpacking',
    SaveArchiveStep.movingIntoPlace => 'Moving into place',
    SaveArchiveStep.finished => 'Done',
  };
}

typedef SaveArchiveProgressCallback = void Function(SaveArchiveStep step);

class ArchiveSaveOutcome {
  /// True when a verified archive exists on disk at [archiveFile].
  final bool archiveCreated;

  /// True when the original save folder is gone.
  final bool originalRemoved;

  final File? archiveFile;
  final SaveArchiveFailure? failure;

  /// User-facing result or error message.
  final String message;

  /// How many files the save folder held. Zero when it was never read.
  final int fileCount;

  /// Size of the save folder before compressing. Zero when it was never read.
  final int originalSizeInBytes;

  /// Size of the finished archive. Zero when there isn't one.
  final int archiveSizeInBytes;

  const ArchiveSaveOutcome({
    required this.archiveCreated,
    required this.originalRemoved,
    required this.archiveFile,
    required this.failure,
    required this.message,
    this.fileCount = 0,
    this.originalSizeInBytes = 0,
    this.archiveSizeInBytes = 0,
  });

  bool get succeeded => archiveCreated && originalRemoved && failure == null;

  @override
  String toString() =>
      'ArchiveSaveOutcome(created: $archiveCreated, removed: $originalRemoved, '
      'failure: $failure, message: $message)';
}

class RestoreSaveOutcome {
  /// True when the extracted save was moved into the saves folder. A later
  /// file-count mismatch is reported in [failure].
  final bool restored;

  /// True when the archive was removed after restoring.
  final bool archiveRemoved;

  final Directory? restoredFolder;
  final SaveArchiveFailure? failure;
  final String message;

  const RestoreSaveOutcome({
    required this.restored,
    required this.archiveRemoved,
    required this.restoredFolder,
    required this.failure,
    required this.message,
  });

  bool get succeeded => restored && failure == null;

  @override
  String toString() =>
      'RestoreSaveOutcome(restored: $restored, failure: $failure, '
      'message: $message)';
}

class SaveEntryFingerprint {
  /// Path relative to the save folder, `/` separated.
  final String relativePath;
  final int sizeInBytes;
  final int crc32;

  const SaveEntryFingerprint({
    required this.relativePath,
    required this.sizeInBytes,
    required this.crc32,
  });
}

class SaveFolderManifest {
  final List<SaveEntryFingerprint> files;
  final int totalSizeInBytes;

  const SaveFolderManifest({
    required this.files,
    required this.totalSizeInBytes,
  });
}

/// The save contains an entry that cannot be verified against the archive.
class UnsupportedSaveContentsException implements Exception {
  final String path;

  UnsupportedSaveContentsException(this.path);

  @override
  String toString() => 'Cannot verify a shortcut or symlink: $path';
}

/// Archives and restores save folders.
///
/// Before removing a save, verifies archive integrity and each file's path,
/// size, and checksum. Only direct children of [savesFolder] can be archived.
/// Archives use a temporary name until verified; restores are extracted and
/// checked in a temporary folder before moving into place.
///
/// [removeFolder] and [removeFile] let the caller choose how to delete originals.
class SaveArchiver {
  final SaveArchiveTool tool;

  final Directory savesFolder;

  final Directory archiveFolder;

  final Future<void> Function(Directory folder) removeFolder;
  final Future<void> Function(File file) removeFile;

  static const archiveExtension = '.7z';

  static const partialExtension = '.part';

  static const restoreTempPrefix = 'trios-restoring-';

  SaveArchiver({
    required this.tool,
    required this.savesFolder,
    required this.archiveFolder,
    required this.removeFolder,
    required this.removeFile,
  });

  /// Compresses [saveFolder] into [archiveFolder], then removes the folder.
  ///
  /// Removes the original only after verification. A removal failure leaves
  /// the verified archive available and is reported separately.
  Future<ArchiveSaveOutcome> archiveSave(
    Directory saveFolder, {
    SaveArchiveProgressCallback? onProgress,
  }) async {
    final folderName = saveFolder.name;
    File? partialArchive;

    try {
      onProgress?.call(SaveArchiveStep.checking);

      if (!await saveFolder.exists()) {
        return _archiveFailed(
          SaveArchiveFailure.saveFolderMissing,
          'The save folder is not there any more: ${saveFolder.path}',
        );
      }

      final guardFailure = _checkSaveFolderIsSafeToRemove(saveFolder);
      if (guardFailure != null) return guardFailure;

      if (p.isWithin(saveFolder.normalize.path, archiveFolder.normalize.path)) {
        return _archiveFailed(
          SaveArchiveFailure.archiveFolderInsideSaveFolder,
          'The archive folder is inside the save being archived. Pick a '
          'different folder for archives.',
        );
      }

      try {
        await archiveFolder.create(recursive: true);
      } catch (error, stackTrace) {
        Fimber.w(
          'Could not create the save archive folder ${archiveFolder.path}',
          ex: error,
          stacktrace: stackTrace,
        );
        return _archiveFailed(
          SaveArchiveFailure.archiveFolderNotWritable,
          'Could not write to the archive folder ${archiveFolder.path}: $error',
        );
      }

      onProgress?.call(SaveArchiveStep.readingSaveFolder);

      final SaveFolderManifest manifest;
      try {
        manifest = await readSaveFolderManifest(saveFolder);
      } on UnsupportedSaveContentsException catch (error) {
        return _archiveFailed(
          SaveArchiveFailure.unsupportedFolderContents,
          'This save folder holds a shortcut or symlink '
          '(${error.path}), which cannot be checked against an archive. '
          'Nothing was changed.',
        );
      }

      if (manifest.files.isEmpty) {
        return _archiveFailed(
          SaveArchiveFailure.saveFolderEmpty,
          'There are no files in ${saveFolder.path}, so there is nothing to '
          'archive.',
        );
      }

      final finalArchive = _pickFreeArchiveFile(folderName);
      if (finalArchive == null) {
        return _archiveFailed(
          SaveArchiveFailure.archiveFolderNotWritable,
          'Could not find a free file name for an archive of "$folderName".',
        );
      }

      partialArchive = File('${finalArchive.path}$partialExtension');
      if (await partialArchive.exists()) {
        // Discard an unfinished archive before retrying.
        await partialArchive.delete();
      }

      onProgress?.call(SaveArchiveStep.compressing);

      try {
        await tool.create(
          archiveFile: partialArchive,
          sourceFolder: saveFolder,
        );
      } catch (error, stackTrace) {
        Fimber.w(
          'Could not compress ${saveFolder.path}',
          ex: error,
          stacktrace: stackTrace,
        );
        return _archiveFailed(
          SaveArchiveFailure.compressionFailed,
          'Compressing the save failed, so it was left alone: $error',
        );
      }

      if (!await partialArchive.exists() ||
          await partialArchive.length() <= 0) {
        return _archiveFailed(
          SaveArchiveFailure.compressionFailed,
          'Compressing the save produced no archive, so it was left alone.',
        );
      }

      onProgress?.call(SaveArchiveStep.verifying);

      final verificationProblem = await _verifyArchiveHoldsFolder(
        archiveFile: partialArchive,
        manifest: manifest,
        rootFolderName: folderName,
      );
      if (verificationProblem != null) {
        return _archiveFailed(
          verificationProblem.failure,
          '${verificationProblem.message} The save was left alone.',
        );
      }

      // Compression may take long enough for another process to take this name.
      if (await finalArchive.exists()) {
        return _archiveFailed(
          SaveArchiveFailure.archiveFolderNotWritable,
          'Something else created ${finalArchive.path} while this save was '
          'being compressed. The save was left alone.',
        );
      }

      final partialLength = await partialArchive.length();
      try {
        await partialArchive.rename(finalArchive.path);
      } catch (error, stackTrace) {
        Fimber.w(
          'Could not rename ${partialArchive.path} into place',
          ex: error,
          stacktrace: stackTrace,
        );
        return _archiveFailed(
          SaveArchiveFailure.archiveFolderNotWritable,
          'The archive could not be renamed into place, so the save was left '
          'alone: $error',
        );
      }

      if (!await finalArchive.exists() ||
          await finalArchive.length() != partialLength) {
        return _archiveFailed(
          SaveArchiveFailure.archiveFolderNotWritable,
          'The archive is not where it should be after being renamed. The save '
          'was left alone.',
        );
      }

      // The verified archive is in place; the original can now be removed.
      onProgress?.call(SaveArchiveStep.removingOriginal);

      try {
        await removeFolder(saveFolder);
      } catch (error, stackTrace) {
        Fimber.w(
          'Archived ${saveFolder.path} but could not remove the folder',
          ex: error,
          stacktrace: stackTrace,
        );
        return ArchiveSaveOutcome(
          archiveCreated: true,
          originalRemoved: false,
          archiveFile: finalArchive,
          failure: SaveArchiveFailure.couldNotRemoveOriginal,
          message:
              'The archive is finished and checked, but the save folder could '
              'not be removed, so there are two copies: $error',
          fileCount: manifest.files.length,
          originalSizeInBytes: manifest.totalSizeInBytes,
          archiveSizeInBytes: partialLength,
        );
      }

      if (await saveFolder.exists()) {
        return ArchiveSaveOutcome(
          archiveCreated: true,
          originalRemoved: false,
          archiveFile: finalArchive,
          failure: SaveArchiveFailure.couldNotRemoveOriginal,
          message:
              'The archive is finished and checked, but the save folder is '
              'still there, so there are two copies.',
          fileCount: manifest.files.length,
          originalSizeInBytes: manifest.totalSizeInBytes,
          archiveSizeInBytes: partialLength,
        );
      }

      onProgress?.call(SaveArchiveStep.finished);
      Fimber.i('Archived ${saveFolder.path} to ${finalArchive.path}');

      return ArchiveSaveOutcome(
        archiveCreated: true,
        originalRemoved: true,
        archiveFile: finalArchive,
        failure: null,
        message: 'Archived to ${finalArchive.nameWithExtension}.',
        fileCount: manifest.files.length,
        originalSizeInBytes: manifest.totalSizeInBytes,
        archiveSizeInBytes: partialLength,
      );
    } catch (error, stackTrace) {
      Fimber.w(
        'Unexpected error archiving ${saveFolder.path}',
        ex: error,
        stacktrace: stackTrace,
      );
      return _archiveFailed(
        SaveArchiveFailure.unexpectedError,
        'Could not finish archiving the save: $error. '
        'Check the saves and archive folders before retrying.',
      );
    } finally {
      // Successful archives have already been renamed out of the partial path.
      await _deleteQuietly(partialArchive);
    }
  }

  /// Unpacks [archiveFile] back into the saves folder.
  ///
  /// Refuses if a save folder of the same name is already there. The archive is
  /// only removed when [removeArchiveAfterwards] is set, and only after the
  /// restored folder has been checked.
  Future<RestoreSaveOutcome> restoreSave(
    File archiveFile, {
    bool removeArchiveAfterwards = false,
    SaveArchiveProgressCallback? onProgress,
  }) async {
    Directory? tempFolder;

    try {
      onProgress?.call(SaveArchiveStep.checking);

      if (!await archiveFile.exists()) {
        return _restoreFailed(
          SaveArchiveFailure.archiveMissing,
          'The archive is not there any more: ${archiveFile.path}',
        );
      }

      if (!await _passesIntegrityTest(archiveFile)) {
        return _restoreFailed(
          SaveArchiveFailure.integrityTestFailed,
          'The archive is damaged, so nothing was unpacked. The archive was '
          'left alone.',
        );
      }

      final entries = await tool.listEntries(archiveFile);
      final fileEntries = entries.where((entry) => !entry.isDirectory).toList();
      if (fileEntries.isEmpty) {
        return _restoreFailed(
          SaveArchiveFailure.archiveEmpty,
          'There are no files in the archive.',
        );
      }

      final archiveRoot = archiveRootFolderName(entries);
      final rootFolderName =
          archiveRoot ?? p.basenameWithoutExtension(archiveFile.path);
      final archiveHasRootFolder = archiveRoot != null;

      if (rootFolderName.isEmpty) {
        return _restoreFailed(
          SaveArchiveFailure.archiveEmpty,
          'The archive does not say what the save folder should be called.',
        );
      }

      final target = savesFolder.resolve(rootFolderName).toDirectory();
      if (await target.exists()) {
        return _restoreFailed(
          SaveArchiveFailure.saveAlreadyExists,
          'There is already a save folder called "$rootFolderName". Rename or '
          'remove it first — nothing was overwritten.',
        );
      }

      try {
        await savesFolder.create(recursive: true);
      } catch (error) {
        return _restoreFailed(
          SaveArchiveFailure.couldNotMoveIntoPlace,
          'Could not write to the saves folder ${savesFolder.path}: $error',
        );
      }

      tempFolder = _pickFreeTempFolder();
      if (tempFolder == null) {
        return _restoreFailed(
          SaveArchiveFailure.couldNotMoveIntoPlace,
          'Could not make a temporary folder to unpack into.',
        );
      }
      await tempFolder.create(recursive: true);

      onProgress?.call(SaveArchiveStep.extracting);

      try {
        await tool.extractAll(
          archiveFile: archiveFile,
          destination: tempFolder,
        );
      } catch (error, stackTrace) {
        Fimber.w(
          'Could not unpack ${archiveFile.path}',
          ex: error,
          stacktrace: stackTrace,
        );
        return _restoreFailed(
          SaveArchiveFailure.extractionFailed,
          'Unpacking the archive failed, so nothing was put in the saves '
          'folder: $error',
        );
      }

      onProgress?.call(SaveArchiveStep.verifying);

      final mismatch = await _verifyExtractedMatchesArchive(
        extractedInto: tempFolder,
        fileEntries: fileEntries,
      );
      if (mismatch != null) {
        return _restoreFailed(
          SaveArchiveFailure.extractedContentsDoNotMatch,
          '$mismatch Nothing was put in the saves folder, and the archive was '
          'left alone.',
        );
      }

      final unpacked = archiveHasRootFolder
          ? tempFolder.resolve(rootFolderName).toDirectory()
          : tempFolder;

      if (!await unpacked.exists()) {
        return _restoreFailed(
          SaveArchiveFailure.extractedContentsDoNotMatch,
          'The unpacked save is not where it should be. Nothing was put in the '
          'saves folder.',
        );
      }

      onProgress?.call(SaveArchiveStep.movingIntoPlace);

      // A save may have appeared while extraction was running.
      if (await target.exists()) {
        return _restoreFailed(
          SaveArchiveFailure.saveAlreadyExists,
          'A save folder called "$rootFolderName" appeared while the archive '
          'was being unpacked. Nothing was overwritten.',
        );
      }

      try {
        await unpacked.moveDirectory(target);
      } catch (error, stackTrace) {
        Fimber.w(
          'Could not move the restored save into ${target.path}',
          ex: error,
          stacktrace: stackTrace,
        );
        // Remove an incomplete copy so the game does not list it as a save.
        await _deleteQuietly(target);
        return _restoreFailed(
          SaveArchiveFailure.couldNotMoveIntoPlace,
          'Could not move the restored save into the saves folder: $error. '
          'The archive was kept. Check for an incomplete save folder before retrying.',
        );
      }

      final restoredCount = await _countFiles(target);
      if (restoredCount != fileEntries.length) {
        Fimber.w(
          'Restored ${target.path} holds $restoredCount files but the archive '
          'holds ${fileEntries.length}',
        );
        return RestoreSaveOutcome(
          restored: true,
          archiveRemoved: false,
          restoredFolder: target,
          failure: SaveArchiveFailure.extractedContentsDoNotMatch,
          message:
              'The save was restored, but it holds $restoredCount files where '
              'the archive holds ${fileEntries.length}. The archive was kept — '
              'check the restored save before removing it.',
        );
      }

      var archiveRemoved = false;
      if (removeArchiveAfterwards) {
        try {
          await removeFile(archiveFile);
          archiveRemoved = !await archiveFile.exists();
        } catch (error, stackTrace) {
          Fimber.w(
            'Restored ${archiveFile.path} but could not remove the archive',
            ex: error,
            stacktrace: stackTrace,
          );
        }
      }

      onProgress?.call(SaveArchiveStep.finished);
      Fimber.i('Restored ${archiveFile.path} to ${target.path}');

      return RestoreSaveOutcome(
        restored: true,
        archiveRemoved: archiveRemoved,
        restoredFolder: target,
        failure: null,
        message: 'Restored "$rootFolderName".',
      );
    } catch (error, stackTrace) {
      Fimber.w(
        'Unexpected error restoring ${archiveFile.path}',
        ex: error,
        stacktrace: stackTrace,
      );
      return _restoreFailed(
        SaveArchiveFailure.unexpectedError,
        'Could not finish restoring the save: $error. '
        'Check the saves and archive folders before retrying.',
      );
    } finally {
      await _deleteQuietly(tempFolder);
    }
  }

  /// Reads every file in [folder], with its size and checksum.
  ///
  /// Throws [UnsupportedSaveContentsException] for links, which cannot be
  /// verified against archive entries.
  static Future<SaveFolderManifest> readSaveFolderManifest(
    Directory folder,
  ) async {
    final files = <SaveEntryFingerprint>[];
    var totalSize = 0;

    await for (final entity in folder.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is Link) {
        throw UnsupportedSaveContentsException(entity.path);
      }
      if (entity is! File) continue;

      final size = await entity.length();
      files.add(
        SaveEntryFingerprint(
          relativePath: relativePosixPath(entity.path, folder),
          sizeInBytes: size,
          crc32: await crc32OfFile(entity),
        ),
      );
      totalSize += size;
    }

    return SaveFolderManifest(files: files, totalSizeInBytes: totalSize);
  }

  /// The single folder every path in [entries] sits inside, or null when the
  /// entries aren't all under one folder.
  ///
  /// TriOS archives include the save folder name. Flat archives use the archive
  /// filename as the restore folder name instead.
  static String? archiveRootFolderName(List<SaveArchiveEntry> entries) {
    String? root;
    var sawNestedPath = false;

    for (final entry in entries) {
      final path = normalizeArchivePath(entry.path);
      if (path.isEmpty) continue;
      final firstSlash = path.indexOf('/');
      final top = firstSlash < 0 ? path : path.substring(0, firstSlash);
      if (firstSlash >= 0) sawNestedPath = true;
      if (root == null) {
        root = top;
      } else if (root != top) {
        return null;
      }
    }

    // Top-level entries alone do not establish a shared root folder.
    if (!sawNestedPath) return null;
    return root;
  }

  /// [path] relative to [folder], with `/` separators.
  static String relativePosixPath(String path, Directory folder) =>
      p.relative(path, from: folder.path).replaceAll('\\', '/');

  /// CRC32 of [file], read in chunks so a multi-gigabyte save doesn't have to
  /// fit in memory.
  static Future<int> crc32OfFile(File file) async {
    var crc = 0;
    await for (final chunk in file.openRead()) {
      crc = getCrc32(chunk, crc);
    }
    return crc;
  }

  Future<bool> _passesIntegrityTest(File archiveFile) async {
    try {
      return await tool.passesIntegrityTest(archiveFile);
    } catch (error) {
      Fimber.w('Integrity test threw for ${archiveFile.path}', ex: error);
      return false;
    }
  }

  /// Checks that [archiveFile] holds every file in [manifest], under
  /// [rootFolderName], at the right size and checksum.
  ///
  /// Returns null when everything matches.
  Future<_VerificationProblem?> _verifyArchiveHoldsFolder({
    required File archiveFile,
    required SaveFolderManifest manifest,
    required String rootFolderName,
  }) async {
    if (!await _passesIntegrityTest(archiveFile)) {
      return const _VerificationProblem(
        SaveArchiveFailure.integrityTestFailed,
        'The archive did not pass its integrity check.',
      );
    }

    final List<SaveArchiveEntry> entries;
    try {
      entries = await tool.listEntries(archiveFile);
    } catch (error) {
      Fimber.w('Could not list ${archiveFile.path}', ex: error);
      return _VerificationProblem(
        SaveArchiveFailure.contentsDoNotMatch,
        'The archive could not be read back: $error',
      );
    }

    final byPath = <String, SaveArchiveEntry>{};
    final byLowercasePath = <String, SaveArchiveEntry>{};
    final ambiguousLowercasePaths = <String>{};
    for (final entry in entries) {
      if (entry.isDirectory) continue;
      final path = normalizeArchivePath(entry.path);
      byPath[path] = entry;
      final lower = path.toLowerCase();
      if (byLowercasePath.containsKey(lower)) {
        ambiguousLowercasePaths.add(lower);
      }
      byLowercasePath[lower] = entry;
    }

    for (final wanted in manifest.files) {
      final expectedPath = '$rootFolderName/${wanted.relativePath}';
      var found = byPath[expectedPath];

      // Accept case differences only when the match is unambiguous.
      if (found == null) {
        final lower = expectedPath.toLowerCase();
        if (!ambiguousLowercasePaths.contains(lower)) {
          found = byLowercasePath[lower];
        }
      }

      if (found == null) {
        return _VerificationProblem(
          SaveArchiveFailure.contentsDoNotMatch,
          'The archive is missing "${wanted.relativePath}".',
        );
      }
      if (found.sizeInBytes != wanted.sizeInBytes) {
        return _VerificationProblem(
          SaveArchiveFailure.contentsDoNotMatch,
          'The archive has "${wanted.relativePath}" at ${found.sizeInBytes} '
          'bytes, but the save has it at ${wanted.sizeInBytes}.',
        );
      }
      // 7-Zip omits checksums for empty files; the size check is sufficient.
      if (wanted.sizeInBytes > 0 &&
          found.crc32 != null &&
          found.crc32 != wanted.crc32) {
        return _VerificationProblem(
          SaveArchiveFailure.contentsDoNotMatch,
          'The copy of "${wanted.relativePath}" in the archive does not match '
          'the one in the save.',
        );
      }
      if (wanted.sizeInBytes > 0 && found.crc32 == null) {
        return _VerificationProblem(
          SaveArchiveFailure.contentsDoNotMatch,
          'The archive recorded no checksum for "${wanted.relativePath}", so '
          'it cannot be checked.',
        );
      }
    }

    return null;
  }

  /// Checks the unpacked files against what the archive says it holds.
  ///
  /// Returns null on success, otherwise a user-facing error.
  Future<String?> _verifyExtractedMatchesArchive({
    required Directory extractedInto,
    required List<SaveArchiveEntry> fileEntries,
  }) async {
    for (final entry in fileEntries) {
      final path = normalizeArchivePath(entry.path);
      final file = File(
        p.joinAll([extractedInto.path, ...p.posix.split(path)]),
      );

      if (!await file.exists()) {
        return 'The unpacked save is missing "$path".';
      }

      final size = await file.length();
      if (size != entry.sizeInBytes) {
        return 'The unpacked "$path" is $size bytes, but the archive says it '
            'should be ${entry.sizeInBytes}.';
      }

      if (entry.crc32 != null && size > 0) {
        final crc = await crc32OfFile(file);
        if (crc != entry.crc32) {
          return 'The unpacked "$path" does not match the copy in the archive.';
        }
      }
    }

    return null;
  }

  /// Restricts archiving to direct children of [savesFolder].
  ArchiveSaveOutcome? _checkSaveFolderIsSafeToRemove(Directory saveFolder) {
    final normalized = saveFolder.normalize;
    final name = normalized.name;

    if (name.isEmpty || name == '.' || name == '..') {
      return _archiveFailed(
        SaveArchiveFailure.saveFolderOutsideSavesFolder,
        'Refusing to archive "${saveFolder.path}" — that is not a save folder.',
      );
    }

    if (p.equals(normalized.path, savesFolder.normalize.path)) {
      return _archiveFailed(
        SaveArchiveFailure.saveFolderOutsideSavesFolder,
        'Refusing to archive the saves folder itself.',
      );
    }

    if (!p.equals(
      Directory(normalized.parent.path).normalize.path,
      savesFolder.normalize.path,
    )) {
      return _archiveFailed(
        SaveArchiveFailure.saveFolderOutsideSavesFolder,
        'Refusing to archive "${saveFolder.path}" — it is not directly inside '
        'the saves folder (${savesFolder.path}).',
      );
    }

    return null;
  }

  /// Finds a name with neither an archive nor a partial file already present.
  /// Returns null after exhausting the numbered alternatives.
  File? _pickFreeArchiveFile(String saveFolderName) {
    final base = saveFolderName.fixFilenameForFileSystem();
    final safeBase = base.isEmpty ? 'save' : base;

    for (var attempt = 1; attempt <= 1000; attempt++) {
      final suffix = attempt == 1 ? '' : ' ($attempt)';
      final candidate = archiveFolder
          .resolve('$safeBase$suffix$archiveExtension')
          .toFile();
      final partial = File('${candidate.path}$partialExtension');
      if (!candidate.existsSync() && !partial.existsSync()) return candidate;
    }

    return null;
  }

  Directory? _pickFreeTempFolder() {
    for (var attempt = 0; attempt < 1000; attempt++) {
      final candidate = archiveFolder
          .resolve(
            '$restoreTempPrefix${DateTime.now().millisecondsSinceEpoch}-$attempt',
          )
          .toDirectory();
      if (!candidate.existsSync()) return candidate;
    }
    return null;
  }

  static Future<int> _countFiles(Directory folder) async {
    var count = 0;
    await for (final entity in folder.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) count++;
    }
    return count;
  }

  /// Cleans up partial archives, extraction folders, and failed restore copies.
  /// Logs deletion failures without replacing the job's result.
  static Future<void> _deleteQuietly(FileSystemEntity? entity) async {
    if (entity == null) return;
    try {
      if (await entity.exists()) {
        await entity.delete(recursive: true);
      }
    } catch (error) {
      Fimber.w('Could not clean up ${entity.path}', ex: error);
    }
  }

  static ArchiveSaveOutcome _archiveFailed(
    SaveArchiveFailure failure,
    String message,
  ) => ArchiveSaveOutcome(
    archiveCreated: false,
    originalRemoved: false,
    archiveFile: null,
    failure: failure,
    message: message,
  );

  static RestoreSaveOutcome _restoreFailed(
    SaveArchiveFailure failure,
    String message,
  ) => RestoreSaveOutcome(
    restored: false,
    archiveRemoved: false,
    restoredFolder: null,
    failure: failure,
    message: message,
  );
}

class _VerificationProblem {
  final SaveArchiveFailure failure;
  final String message;

  const _VerificationProblem(this.failure, this.message);
}
