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

/// Defaults to a sibling of the saves folder, outside the game's save list.
/// Null when neither a custom path nor the saves folder is available.
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

Directory defaultSaveArchiveFolder(Directory savesFolder) => Directory(
  p.join(savesFolder.normalize.parent.path, Constants.savesArchiveFolderName),
).normalize;

/// Reuses [SevenZip], whose constructor runs `chmod` on macOS and Linux.
final saveArchiveToolProvider = Provider<SaveArchiveTool>(
  (ref) => SevenZipSaveArchiveTool(SevenZip()),
);

/// Null until both save and archive folders are available.
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

/// Returns a blocking reason, or null when archiving and restoring are allowed.
/// Checked before each job because the game can start during a batch.
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

/// Caches metadata after archiving. A metadata write failure must not change
/// the archive outcome.
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

/// Deletes the archive and its metadata. The caller must confirm deletion;
/// this may be the only copy, and trash failures fall back to permanent deletion.
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

/// Falls back to permanent deletion if trash is unavailable. Call only after
/// verifying the archive.
Future<void> moveFolderToTrash(Directory folder) async {
  folder.moveToTrash(deleteIfFailed: true);
}

/// Falls back to permanent deletion if trash is unavailable.
Future<void> moveFileToTrash(File file) async {
  file.moveToTrash(deleteIfFailed: true);
}
