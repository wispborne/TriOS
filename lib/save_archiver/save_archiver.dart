import 'dart:io';

import 'package:archive/archive.dart' show getCrc32;
import 'package:path/path.dart' as p;
import 'package:trios/save_archiver/save_archive_tool.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

/// Why archiving or restoring a save stopped.
///
/// Every one of these leaves both the save folder and the archive exactly as
/// they were before the attempt, except [couldNotRemoveOriginal], which means
/// the archive is finished and correct but the save folder is still there.
enum SaveArchiveFailure {
  /// The save folder isn't where it was said to be.
  saveFolderMissing,

  /// The folder holds no files, so there is nothing to archive.
  saveFolderEmpty,

  /// The folder isn't directly inside the saves folder. Refusing to touch
  /// anything else is the whole point of the check.
  saveFolderOutsideSavesFolder,

  /// The archive folder sits inside the save folder being archived, so
  /// archiving would try to compress its own output.
  archiveFolderInsideSaveFolder,

  /// Couldn't create or write to the archive folder.
  archiveFolderNotWritable,

  /// 7-Zip failed, or produced nothing.
  compressionFailed,

  /// The archive is damaged, by its own format's check.
  integrityTestFailed,

  /// The archive is readable, but it doesn't hold everything the save folder
  /// holds. A file is missing, the wrong size, or has the wrong checksum.
  contentsDoNotMatch,

  /// The save folder holds a shortcut or symlink, which can't be checked
  /// against the archive, so archiving won't risk it.
  unsupportedFolderContents,

  /// The archive is complete and verified, but the save folder couldn't be
  /// removed. Nothing was lost — there are now two copies.
  couldNotRemoveOriginal,

  /// The archive file isn't where it was said to be.
  archiveMissing,

  /// The archive holds nothing.
  archiveEmpty,

  /// A save folder of that name is already in the saves folder. Restoring
  /// would overwrite it.
  saveAlreadyExists,

  /// 7-Zip failed to unpack the archive.
  extractionFailed,

  /// What came out of the archive doesn't match what the archive says is in
  /// it. Nothing was moved into the saves folder.
  extractedContentsDoNotMatch,

  /// The unpacked save couldn't be moved into the saves folder.
  couldNotMoveIntoPlace,

  /// Something threw that wasn't expected.
  unexpectedError,
}

/// The stage a job is at, for showing progress.
enum SaveArchiveStep {
  checking,
  readingSaveFolder,
  compressing,
  verifying,
  removingOriginal,
  extracting,
  movingIntoPlace,
  finished,
}

extension SaveArchiveStepLabel on SaveArchiveStep {
  String get label => switch (this) {
    SaveArchiveStep.checking => 'Checking',
    SaveArchiveStep.readingSaveFolder => 'Reading save',
    SaveArchiveStep.compressing => 'Compressing',
    SaveArchiveStep.verifying => 'Verifying',
    SaveArchiveStep.removingOriginal => 'Removing original',
    SaveArchiveStep.extracting => 'Unpacking',
    SaveArchiveStep.movingIntoPlace => 'Moving into place',
    SaveArchiveStep.finished => 'Done',
  };
}

typedef SaveArchiveProgressCallback = void Function(SaveArchiveStep step);

/// What happened to one save that was asked to be archived.
class ArchiveSaveOutcome {
  /// True when a verified archive exists on disk at [archiveFile].
  final bool archiveCreated;

  /// True when the original save folder is gone.
  final bool originalRemoved;

  final File? archiveFile;
  final SaveArchiveFailure? failure;

  /// Plain English, safe to show to a person as-is.
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

/// What happened to one archive that was asked to be restored.
class RestoreSaveOutcome {
  /// True when the save folder is back in the saves folder, verified.
  final bool restored;

  /// True when the archive was removed afterwards, because it was asked for.
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

/// One file in a save folder, with enough detail to prove the archive holds it.
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

/// Everything in a save folder, as read off disk.
class SaveFolderManifest {
  final List<SaveEntryFingerprint> files;
  final int totalSizeInBytes;

  const SaveFolderManifest({
    required this.files,
    required this.totalSizeInBytes,
  });
}

/// Thrown while reading a save folder that holds something that can't be
/// checked against an archive.
class UnsupportedSaveContentsException implements Exception {
  final String path;

  UnsupportedSaveContentsException(this.path);

  @override
  String toString() => 'Cannot verify a shortcut or symlink: $path';
}

/// Compresses save folders, and puts them back.
///
/// The rules this class is built around, in order of importance:
///
/// 1. A save folder is only ever removed after the archive has been written,
///    passed its format's integrity check, and been compared file by file
///    against the folder — name, size, and checksum, for every single file.
/// 2. Nothing already on disk is overwritten. Not an existing archive, and
///    never an existing save folder.
/// 3. The archive is built under a temporary name and only renamed into place
///    once it is verified, so a crash halfway can't leave a half-written file
///    that looks finished.
/// 4. Only a folder sitting directly inside the saves folder can be removed.
/// 5. Anything unexpected stops the job with both copies intact.
///
/// It knows nothing about Riverpod, Flutter, or what a Starsector save looks
/// like inside. [removeFolder] and [removeFile] are handed in so that tests can
/// watch what would have been deleted, and so the app can send deletions to the
/// recycle bin without this file depending on the platform code that does it.
class SaveArchiver {
  final SaveArchiveTool tool;

  /// The game's saves folder. A folder is only ever removed from here, and a
  /// restored save only ever lands here.
  final Directory savesFolder;

  /// Where archives are kept.
  final Directory archiveFolder;

  final Future<void> Function(Directory folder) removeFolder;
  final Future<void> Function(File file) removeFile;

  /// File extension used for archives, including the dot.
  static const archiveExtension = '.7z';

  /// Extension used while an archive is still being written.
  static const partialExtension = '.part';

  /// Prefix of the temporary folders used while unpacking.
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
  /// The folder is only removed once the archive is verified. Every failure
  /// leaves the save folder untouched.
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
        // Left over from a run that was interrupted. It was never verified, so
        // it is safe to drop.
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

      // Somebody could have created this name in the meantime. Renaming over it
      // would destroy whatever is there.
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

      // From here on the archive is real, verified, and final. Only now is the
      // save folder allowed to go.
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
        'Something went wrong, so the save was left alone: $error',
      );
    } finally {
      // A partial archive is never anything but rubbish: it is only renamed
      // into place after it passes every check, so anything still under the
      // partial name failed.
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

      bool passedIntegrityTest;
      try {
        passedIntegrityTest = await tool.passesIntegrityTest(archiveFile);
      } catch (error) {
        passedIntegrityTest = false;
        Fimber.w('Integrity test threw for ${archiveFile.path}', ex: error);
      }
      if (!passedIntegrityTest) {
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

      final rootFolderName =
          archiveRootFolderName(entries) ??
          p.basenameWithoutExtension(archiveFile.path);
      final archiveHasRootFolder = archiveRootFolderName(entries) != null;

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

      // Checked again right before the move, because unpacking takes time and
      // the game could have written a save in the meantime.
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
        // A half-copied folder in the saves folder would look like a save and
        // fail to load, so take it back out.
        await _deleteQuietly(target);
        return _restoreFailed(
          SaveArchiveFailure.couldNotMoveIntoPlace,
          'The save could not be moved into the saves folder, so nothing was '
          'left there: $error',
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
        'Something went wrong, so nothing was put in the saves folder: $error',
      );
    } finally {
      await _deleteQuietly(tempFolder);
    }
  }

  /// Reads every file in [folder], with its size and checksum.
  ///
  /// Throws [UnsupportedSaveContentsException] when it finds a shortcut or
  /// symlink, because there is no way to check one of those against an archive.
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
  /// Archives this app writes always have one: the save folder's own name.
  /// An archive somebody made by hand might not, and that is handled rather
  /// than refused.
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

    // A single file at the archive root is a file, not a folder.
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

  /// Checks that [archiveFile] holds every file in [manifest], under
  /// [rootFolderName], at the right size and checksum.
  ///
  /// Returns null when everything matches.
  Future<_VerificationProblem?> _verifyArchiveHoldsFolder({
    required File archiveFile,
    required SaveFolderManifest manifest,
    required String rootFolderName,
  }) async {
    bool passedIntegrityTest;
    try {
      passedIntegrityTest = await tool.passesIntegrityTest(archiveFile);
    } catch (error) {
      Fimber.w('Integrity test threw for ${archiveFile.path}', ex: error);
      passedIntegrityTest = false;
    }
    if (!passedIntegrityTest) {
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

      // Windows reports the same path with different capitalisation from time
      // to time. Only fall back when there is exactly one candidate, so two
      // files differing only in case can never be mistaken for each other.
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
      // 7-Zip records no checksum for an empty file, and there is nothing to
      // check in one anyway — the size already proved it.
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
  /// Returns null when everything matches, or a sentence saying what didn't.
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

  /// Refuses anything that isn't a folder sitting directly inside the saves
  /// folder, so a wrong path can never take out something else.
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

  /// An archive path that nothing is using yet.
  ///
  /// Never returns a path that exists, so an archive can't be written over a
  /// previous one. Returns null if it somehow can't find a free name.
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

  /// Deletes [entity] and swallows any error. Only used on things this class
  /// created itself: partial archives and its own temporary folders.
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

/// A reason an archive doesn't match the folder it was made from.
class _VerificationProblem {
  final SaveArchiveFailure failure;
  final String message;

  const _VerificationProblem(this.failure, this.message);
}
