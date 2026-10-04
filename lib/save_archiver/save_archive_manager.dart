import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/compression/seven_zip/seven_zip.dart';
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/save_archiver/archived_save_store.dart';
import 'package:trios/save_archiver/save_archive_tool.dart';
import 'package:trios/save_archiver/save_archiver.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/platform_specific.dart';

/// Where archived saves are kept.
///
/// Beside the saves folder by default, not inside it, so the game never has to
/// look at it. Null when there is no saves folder to sit beside yet.
final saveArchiveFolderProvider = Provider<Directory?>((ref) {
  final useCustom = ref.watch(
    appSettings.select((settings) => settings.useCustomSavesArchivePath),
  );
  final custom = ref.watch(
    appSettings.select((settings) => settings.customSavesArchivePath),
  );
  if (useCustom && custom != null) return custom.normalize;

  final savesFolder = ref.watch(AppState.savesFolder).value;
  if (savesFolder == null) return null;
  return defaultSaveArchiveFolder(savesFolder);
});

/// The folder archives go in when nothing else is set.
Directory defaultSaveArchiveFolder(Directory savesFolder) => Directory(
  p.join(savesFolder.normalize.parent.path, Constants.savesArchiveFolderName),
).normalize;

/// The 7-Zip-backed tool the archiver uses.
///
/// Built once: constructing [SevenZip] runs `chmod` on macOS and Linux.
final saveArchiveToolProvider = Provider<SaveArchiveTool>(
  (ref) => SevenZipSaveArchiveTool(SevenZip()),
);

/// The archiver, or null when the saves folder or archive folder isn't known
/// yet — which is what happens before the game folder has been set.
final saveArchiverProvider = Provider<SaveArchiver?>((ref) {
  final savesFolder = ref.watch(AppState.savesFolder).value;
  final archiveFolder = ref.watch(saveArchiveFolderProvider);
  if (savesFolder == null || archiveFolder == null) return null;

  return SaveArchiver(
    tool: ref.watch(saveArchiveToolProvider),
    savesFolder: savesFolder.normalize,
    archiveFolder: archiveFolder,
    removeFolder: moveFolderToTrash,
    removeFile: moveFileToTrash,
  );
});

/// The archives on disk, newest save first.
final archivedSavesProvider =
    AsyncNotifierProvider<ArchivedSavesNotifier, List<ArchivedSaveEntry>>(
      ArchivedSavesNotifier.new,
    );

class ArchivedSavesNotifier extends AsyncNotifier<List<ArchivedSaveEntry>> {
  @override
  Future<List<ArchivedSaveEntry>> build() async {
    final archiveFolder = ref.watch(saveArchiveFolderProvider);
    if (archiveFolder == null) return [];
    return readArchivedSaves(archiveFolder, ref.watch(saveArchiveToolProvider));
  }

  /// Rereads the archive folder.
  Future<void> reload() async {
    final archiveFolder = ref.read(saveArchiveFolderProvider);
    if (archiveFolder == null) {
      state = const AsyncData([]);
      return;
    }
    state = AsyncData(
      await readArchivedSaves(archiveFolder, ref.read(saveArchiveToolProvider)),
    );
  }
}

/// Why the app won't archive or restore right now, or null when it will.
///
/// Takes a `WidgetRef` because everything here is started by somebody pressing
/// a button; nothing archives on its own.
///
/// Checked before every job rather than once per dialog: batches take minutes,
/// and somebody can start the game in the middle of one.
String? saveArchivingBlockedReason(WidgetRef ref) {
  if (ref.read(AppState.isGameRunning).value == true) {
    return 'Starsector is running. Close it first — archiving a save while the '
        'game has it open could damage it.';
  }
  if (ref.read(saveArchiverProvider) == null) {
    return 'TriOS does not know where your saves folder is yet. Set the game '
        'folder in Settings first.';
  }
  return null;
}

/// Archives one save, then writes the note that lets the archive list show its
/// character name and date without unpacking anything.
///
/// The note is written after the fact on purpose: it is a convenience, and a
/// failure to write it must never turn a finished archive into a failed one.
Future<ArchiveSaveOutcome> archiveOneSave(
  WidgetRef ref,
  SaveFile save, {
  SaveArchiveProgressCallback? onProgress,
}) async {
  final blocked = saveArchivingBlockedReason(ref);
  if (blocked != null) {
    return ArchiveSaveOutcome(
      archiveCreated: false,
      originalRemoved: false,
      archiveFile: null,
      failure: SaveArchiveFailure.unexpectedError,
      message: blocked,
    );
  }

  final archiver = ref.read(saveArchiverProvider)!;
  final outcome = await archiver.archiveSave(
    save.folder,
    onProgress: onProgress,
  );

  if (outcome.archiveCreated && outcome.archiveFile != null) {
    await writeArchivedSaveMetadata(
      outcome.archiveFile!,
      buildArchivedSave(
        saveFolderName: save.folder.name,
        save: save,
        fileCount: outcome.fileCount,
        originalSizeInBytes: outcome.originalSizeInBytes,
        archiveSizeInBytes: outcome.archiveSizeInBytes,
      ),
    );
  }

  return outcome;
}

/// Restores one archive back into the saves folder.
Future<RestoreSaveOutcome> restoreOneArchive(
  WidgetRef ref,
  ArchivedSaveEntry entry, {
  bool removeArchiveAfterwards = false,
  SaveArchiveProgressCallback? onProgress,
}) async {
  final blocked = saveArchivingBlockedReason(ref);
  if (blocked != null) {
    return RestoreSaveOutcome(
      restored: false,
      archiveRemoved: false,
      restoredFolder: null,
      failure: SaveArchiveFailure.unexpectedError,
      message: blocked,
    );
  }

  final archiver = ref.read(saveArchiverProvider)!;
  final outcome = await archiver.restoreSave(
    entry.archiveFile,
    removeArchiveAfterwards: removeArchiveAfterwards,
    onProgress: onProgress,
  );

  if (outcome.archiveRemoved) {
    await _removeQuietly(entry.metadataFile);
  }

  return outcome;
}

/// Deletes an archive and the note beside it, after the person has confirmed.
///
/// This is the one place in the feature that removes something without a
/// verified copy elsewhere, so it goes to the recycle bin and nothing calls it
/// on its own.
Future<void> deleteArchive(ArchivedSaveEntry entry) async {
  await moveFileToTrash(entry.archiveFile);
  await _removeQuietly(entry.metadataFile);
}

Future<void> _removeQuietly(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } catch (error) {
    Fimber.w('Could not remove ${file.path}: $error');
  }
}

/// Sends a folder to the recycle bin, falling back to deleting it outright.
///
/// The fallback is only reached once the archive has been written and checked,
/// so the recycle bin is a second net rather than the only one.
Future<void> moveFolderToTrash(Directory folder) async {
  folder.moveToTrash(deleteIfFailed: true);
}

/// Sends a file to the recycle bin, falling back to deleting it outright.
Future<void> moveFileToTrash(File file) async {
  file.moveToTrash(deleteIfFailed: true);
}
