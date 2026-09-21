import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/save_archiver/models/archived_save.dart';
import 'package:trios/save_archiver/save_archive_tool.dart';
import 'package:trios/save_archiver/save_archiver.dart';
import 'package:trios/utils/logging.dart';

/// One archive on disk, with whatever is known about the save inside it.
class ArchivedSaveEntry {
  final File archiveFile;

  /// Null when neither the note beside the archive nor the archive's own
  /// descriptor could be read. The archive can still be restored.
  final ArchivedSave? info;

  /// Size of the archive file right now.
  final int sizeOnDiskInBytes;

  /// When the archive file was last written.
  final DateTime fileModified;

  const ArchivedSaveEntry({
    required this.archiveFile,
    required this.info,
    required this.sizeOnDiskInBytes,
    required this.fileModified,
  });

  /// The name the save folder gets back when restored.
  String get saveFolderName =>
      info?.saveFolderName ?? p.basenameWithoutExtension(archiveFile.path);

  /// What to call this in a list.
  String get displayName {
    final character = info?.characterName;
    if (character != null && character.isNotEmpty) return character;
    return saveFolderName;
  }

  /// The date to sort and filter on: when the game wrote the save, falling back
  /// to when TriOS archived it, falling back to the file's own timestamp.
  DateTime get sortDate => info?.saveDate ?? info?.archivedDate ?? fileModified;

  /// A stable second key, so two archives with the same date never swap order
  /// between one listing and the next.
  String get sortTieBreaker => archiveFile.path;

  /// The note file written beside [archiveFile].
  File get metadataFile => metadataFileFor(archiveFile);
}

/// The note written beside an archive, holding what TriOS knows about the save.
File metadataFileFor(File archiveFile) =>
    File('${archiveFile.path}$archivedSaveMetadataSuffix');

/// Suffix of the note file, appended to the whole archive file name so it never
/// collides with an archive.
const archivedSaveMetadataSuffix = '.info.json';

/// Builds the note to write beside an archive.
ArchivedSave buildArchivedSave({
  required String saveFolderName,
  required SaveFile? save,
  required int fileCount,
  required int originalSizeInBytes,
  required int archiveSizeInBytes,
  DateTime? archivedDate,
}) => ArchivedSave(
  saveFolderName: saveFolderName,
  characterName: save?.characterName,
  characterLevel: save?.characterLevel,
  portraitPath: save?.portraitPath,
  saveFileVersion: save?.saveFileVersion,
  saveDate: save?.saveDate,
  gameTimestamp: save?.gameTimestamp,
  secondsPerDay: save?.secondsPerDay,
  difficulty: save?.difficulty,
  isIronMode: save?.isIronMode,
  modNames: save?.mods.map((mod) => mod.name).toList() ?? const [],
  fileCount: fileCount,
  originalSizeInBytes: originalSizeInBytes,
  archiveSizeInBytes: archiveSizeInBytes,
  archivedDate: archivedDate ?? DateTime.now(),
);

/// Writes the note beside [archiveFile].
///
/// Failing to write it is not worth telling anybody about: the archive is
/// already safe, and the list falls back to reading the archive itself.
Future<void> writeArchivedSaveMetadata(
  File archiveFile,
  ArchivedSave info,
) async {
  try {
    await metadataFileFor(
      archiveFile,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(info.toMap()));
  } catch (error, stackTrace) {
    Fimber.w(
      'Could not write the note beside ${archiveFile.path}',
      ex: error,
      stacktrace: stackTrace,
    );
  }
}

/// Reads the note beside [archiveFile], or null when there isn't a usable one.
Future<ArchivedSave?> readArchivedSaveMetadata(File archiveFile) async {
  final file = metadataFileFor(archiveFile);
  if (!await file.exists()) return null;
  try {
    return ArchivedSaveMapper.fromMap(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
  } catch (error) {
    Fimber.w(
      'Could not read ${file.path}, will read the archive instead: $error',
    );
    return null;
  }
}

/// Lists the archives in [archiveFolder], newest save first.
///
/// For each archive it tries the note beside it, then the `descriptor.xml`
/// inside the archive, and failing both still lists the archive with just its
/// file name — an archive TriOS can't describe is still an archive somebody
/// might need back.
Future<List<ArchivedSaveEntry>> readArchivedSaves(
  Directory archiveFolder,
  SaveArchiveTool tool,
) async {
  if (!await archiveFolder.exists()) return [];

  final archives = <File>[];
  await for (final entity in archiveFolder.list(followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.toLowerCase().endsWith(SaveArchiver.archiveExtension)) {
      continue;
    }
    archives.add(entity);
  }

  final entries = <ArchivedSaveEntry>[];
  for (final archive in archives) {
    entries.add(await _readOne(archive, tool));
  }

  entries.sort((a, b) {
    final byDate = b.sortDate.compareTo(a.sortDate);
    if (byDate != 0) return byDate;
    return a.sortTieBreaker.compareTo(b.sortTieBreaker);
  });
  return entries;
}

Future<ArchivedSaveEntry> _readOne(File archive, SaveArchiveTool tool) async {
  final stat = await archive.stat();

  var info = await readArchivedSaveMetadata(archive);
  if (info == null) {
    info = await _readMetadataFromArchive(archive, tool, stat.size);
    // Write the note so the next listing doesn't have to unpack anything.
    if (info != null) await writeArchivedSaveMetadata(archive, info);
  }

  return ArchivedSaveEntry(
    archiveFile: archive,
    info: info,
    sizeOnDiskInBytes: stat.size,
    fileModified: stat.modified,
  );
}

/// Reads the save's details out of the archive itself, for an archive with no
/// note beside it — one made by an older version, or copied in by hand.
Future<ArchivedSave?> _readMetadataFromArchive(
  File archive,
  SaveArchiveTool tool,
  int archiveSizeInBytes,
) async {
  try {
    final entries = await tool.listEntries(archive);
    final fileEntries = entries.where((entry) => !entry.isDirectory).toList();
    if (fileEntries.isEmpty) return null;

    final rootFolderName =
        SaveArchiver.archiveRootFolderName(entries) ??
        p.basenameWithoutExtension(archive.path);

    final descriptorEntry = fileEntries.firstWhereOrNull(
      (entry) =>
          p.basename(normalizeArchivePath(entry.path)).toLowerCase() ==
          saveDescriptorFileName,
    );

    SaveFile? save;
    if (descriptorEntry != null) {
      final text = await tool.readTextEntry(archive, descriptorEntry.path);
      if (text != null) {
        save = parseSaveDescriptor(text, Directory(rootFolderName));
      }
    }

    return buildArchivedSave(
      saveFolderName: rootFolderName,
      save: save,
      fileCount: fileEntries.length,
      originalSizeInBytes: fileEntries.fold(
        0,
        (total, entry) => total + entry.sizeInBytes,
      ),
      archiveSizeInBytes: archiveSizeInBytes,
      // Nothing recorded when it was archived, so the file's own date is the
      // closest thing there is.
      archivedDate: archive.statSync().modified,
    );
  } catch (error) {
    Fimber.w('Could not read the save details out of ${archive.path}: $error');
    return null;
  }
}
