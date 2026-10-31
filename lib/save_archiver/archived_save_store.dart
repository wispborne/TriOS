import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/save_archiver/models/archived_save.dart';
import 'package:trios/save_archiver/save_archive_tool.dart';
import 'package:trios/save_archiver/save_archiver.dart';
import 'package:trios/utils/logging.dart';

/// Archive file and cached save details.
class ArchivedSaveEntry {
  final File archiveFile;

  /// Missing metadata does not prevent restoring the archive.
  final ArchivedSave? info;

  final int sizeOnDiskInBytes;

  final DateTime fileModified;

  const ArchivedSaveEntry({
    required this.archiveFile,
    required this.info,
    required this.sizeOnDiskInBytes,
    required this.fileModified,
  });

  /// Folder name shown in the UI; restoration resolves it from archive entries.
  String get saveFolderName =>
      info?.saveFolderName ?? p.basenameWithoutExtension(archiveFile.path);

  String get displayName {
    final character = info?.characterName;
    if (character != null && character.isNotEmpty) return character;
    return saveFolderName;
  }

  DateTime get sortDate => info?.saveDate ?? info?.archivedDate ?? fileModified;

  /// Keeps archives with the same date in a consistent order.
  String get sortTieBreaker => archiveFile.path;

  File get metadataFile => metadataFileFor(archiveFile);
}

File metadataFileFor(File archiveFile) =>
    File('${archiveFile.path}$archivedSaveMetadataSuffix');

/// Appended to the full archive filename.
const archivedSaveMetadataSuffix = '.info.json';

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

/// Writes cached metadata beside [archiveFile].
///
/// Failure is logged; the list can recover details from the archive.
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
      'Unable to write the note beside ${archiveFile.path}',
      ex: error,
      stacktrace: stackTrace,
    );
  }
}

/// Returns null when the metadata file is missing or unreadable.
Future<ArchivedSave?> readArchivedSaveMetadata(File archiveFile) async {
  final file = metadataFileFor(archiveFile);
  if (!await file.exists()) return null;
  try {
    return ArchivedSaveMapper.fromMap(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
  } catch (error) {
    Fimber.w(
      'Unable to read ${file.path}. Will read the archive instead: $error',
    );
    return null;
  }
}

/// Lists the archives in [archiveFolder], newest save first.
///
/// Missing metadata falls back to the archived descriptor. Archives remain
/// listed when neither can be read.
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
    info = await _readMetadataFromArchive(archive, tool, stat);
    // Cache recovered metadata for subsequent listings.
    if (info != null) await writeArchivedSaveMetadata(archive, info);
  }

  return ArchivedSaveEntry(
    archiveFile: archive,
    info: info,
    sizeOnDiskInBytes: stat.size,
    fileModified: stat.modified,
  );
}

/// Recovers metadata from an archive without a usable metadata file.
Future<ArchivedSave?> _readMetadataFromArchive(
  File archive,
  SaveArchiveTool tool,
  FileStat stat,
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
      archiveSizeInBytes: stat.size,
      // Use the file timestamp when the archive date is unknown.
      archivedDate: stat.modified,
    );
  } catch (error) {
    Fimber.w('Unable to read the save details out of ${archive.path}: $error');
    return null;
  }
}
