import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:trios/save_archiver/archived_save_store.dart';
import 'package:trios/save_archiver/save_archiver.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

class MoveArchiveOutcome {
  /// True when a checked copy of the archive is in the new folder.
  final bool moved;

  /// True when the archive is gone from the old folder.
  final bool originalRemoved;

  final File? movedTo;

  /// User-facing result or error message. Empty for a plain success.
  final String message;

  const MoveArchiveOutcome({
    required this.moved,
    required this.originalRemoved,
    required this.movedTo,
    required this.message,
  });

  bool get succeeded => moved && originalRemoved;

  @override
  String toString() =>
      'MoveArchiveOutcome(moved: $moved, removed: $originalRemoved, '
      'message: $message)';
}

/// Moves archives from one archive folder to another.
///
/// Each archive is copied under a temporary name, checked against the
/// original's size and checksum, and renamed into place. Only then is the
/// original removed. A failure before that point leaves the original alone
/// and deletes the partial copy.
class ArchiveFolderMover {
  final Directory fromFolder;
  final Directory toFolder;

  final Future<void> Function(File source, File destination) copyFile;
  final Future<void> Function(File file) removeFile;

  ArchiveFolderMover({
    required this.fromFolder,
    required this.toFolder,
    required this.removeFile,
    this.copyFile = _copy,
  });

  static Future<void> _copy(File source, File destination) =>
      source.copy(destination.path);

  /// The archives directly inside [folder], skipping unfinished `.part` files.
  static Future<List<File>> listArchives(Directory folder) async {
    if (!await folder.exists()) return [];
    final archives = <File>[];
    await for (final entity in folder.list(followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith(SaveArchiver.archiveExtension)) {
        continue;
      }
      archives.add(entity);
    }
    return archives;
  }

  /// Returns null when [toFolder] can be written to, otherwise a user-facing
  /// error. Checked before moving anything so a bad folder fails once, not
  /// once per archive.
  Future<String?> checkCanMove() async {
    if (p.equals(fromFolder.normalize.path, toFolder.normalize.path)) {
      return 'The new folder is the same as the current one.';
    }

    final probe = toFolder
        .resolve('.trios-write-test-${DateTime.now().microsecondsSinceEpoch}')
        .toFile();
    try {
      await toFolder.create(recursive: true);
      await probe.writeAsString('test');
      await probe.delete();
      return null;
    } catch (error, stackTrace) {
      Fimber.w(
        'Cannot write to the new archive folder ${toFolder.path}',
        ex: error,
        stacktrace: stackTrace,
      );
      await _deleteQuietly(probe);
      return 'TriOS cannot write to ${toFolder.path}: $error';
    }
  }

  Future<MoveArchiveOutcome> moveArchive(
    File source, {
    SaveArchiveProgressCallback? onProgress,
  }) async {
    File? partial;

    try {
      onProgress?.call(SaveArchiveStep.checking);

      if (!await source.exists()) {
        return _failed('The archive is not there any more: ${source.path}');
      }

      try {
        await toFolder.create(recursive: true);
      } catch (error) {
        return _failed('Could not create ${toFolder.path}: $error');
      }

      final destination = _pickFreeDestination(
        p.basenameWithoutExtension(source.path),
      );
      if (destination == null) {
        return _failed('Could not find a free file name in ${toFolder.path}.');
      }

      partial = File('${destination.path}${SaveArchiver.partialExtension}');

      onProgress?.call(SaveArchiveStep.copying);

      try {
        await copyFile(source, partial);
      } catch (error, stackTrace) {
        Fimber.w(
          'Could not copy ${source.path} to ${partial.path}',
          ex: error,
          stacktrace: stackTrace,
        );
        return _failed('Copying failed: $error');
      }

      onProgress?.call(SaveArchiveStep.verifying);

      final sourceLength = await source.length();
      if (!await partial.exists() ||
          await partial.length() != sourceLength ||
          await SaveArchiver.crc32OfFile(partial) !=
              await SaveArchiver.crc32OfFile(source)) {
        return _failed('The copy does not match the original.');
      }

      // Copying may take long enough for another process to take this name.
      if (await destination.exists()) {
        return _failed(
          'Something else created ${destination.path} while the archive was '
          'being copied.',
        );
      }

      try {
        await partial.rename(destination.path);
      } catch (error, stackTrace) {
        Fimber.w(
          'Could not rename ${partial.path} into place',
          ex: error,
          stacktrace: stackTrace,
        );
        return _failed('The copy could not be renamed into place: $error');
      }

      if (!await destination.exists() ||
          await destination.length() != sourceLength) {
        // Don't leave a bad copy where it would be listed as an archive.
        await _deleteQuietly(destination);
        return _failed(
          'The copy is not where it should be after being renamed.',
        );
      }

      // The details can be read back out of the archive, so a failure here
      // does not stop the move.
      final sourceMetadata = metadataFileFor(source);
      if (await sourceMetadata.exists()) {
        try {
          await sourceMetadata.copy(metadataFileFor(destination).path);
        } catch (error) {
          Fimber.w(
            'Could not copy ${sourceMetadata.path} with its archive',
            ex: error,
          );
        }
      }

      // The checked copy is in place; the original can now be removed.
      onProgress?.call(SaveArchiveStep.removingOriginal);

      final renamedNote =
          p.basename(destination.path) == p.basename(source.path)
          ? ''
          : 'Renamed to ${p.basename(destination.path)} because that name was '
                'taken. ';

      try {
        await removeFile(source);
      } catch (error, stackTrace) {
        Fimber.w(
          'Moved ${source.path} but could not remove the original',
          ex: error,
          stacktrace: stackTrace,
        );
        return _twoCopies(destination, renamedNote, '$error');
      }
      if (await source.exists()) {
        return _twoCopies(destination, renamedNote, 'it is still there');
      }

      await _deleteQuietly(sourceMetadata);

      onProgress?.call(SaveArchiveStep.finished);
      Fimber.i('Moved ${source.path} to ${destination.path}');

      return MoveArchiveOutcome(
        moved: true,
        originalRemoved: true,
        movedTo: destination,
        message: renamedNote.trim(),
      );
    } catch (error, stackTrace) {
      Fimber.w(
        'Unexpected error moving ${source.path}',
        ex: error,
        stacktrace: stackTrace,
      );
      return _failed('Could not finish moving the archive: $error');
    } finally {
      // A finished move has already renamed the partial copy into place.
      await _deleteQuietly(partial);
    }
  }

  /// Finds a name in [toFolder] with no archive, partial copy, or metadata
  /// file already there. Returns null after the numbered alternatives run out.
  File? _pickFreeDestination(String baseName) {
    for (var attempt = 1; attempt <= 1000; attempt++) {
      final suffix = attempt == 1 ? '' : ' ($attempt)';
      final candidate = toFolder
          .resolve('$baseName$suffix${SaveArchiver.archiveExtension}')
          .toFile();
      if (!candidate.existsSync() &&
          !File('${candidate.path}${SaveArchiver.partialExtension}')
              .existsSync() &&
          !metadataFileFor(candidate).existsSync()) {
        return candidate;
      }
    }
    return null;
  }

  static Future<void> _deleteQuietly(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (error) {
      Fimber.w('Could not clean up ${file.path}', ex: error);
    }
  }

  static MoveArchiveOutcome _failed(String message) => MoveArchiveOutcome(
    moved: false,
    originalRemoved: false,
    movedTo: null,
    message: '$message The archive was left in the old folder.',
  );

  static MoveArchiveOutcome _twoCopies(
    File destination,
    String renamedNote,
    String reason,
  ) => MoveArchiveOutcome(
    moved: true,
    originalRemoved: false,
    movedTo: destination,
    message:
        '${renamedNote}Copied to the new folder, but the original could not '
        'be removed, so there are two copies: $reason',
  );
}
