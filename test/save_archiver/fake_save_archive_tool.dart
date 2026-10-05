import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart' show getCrc32;
import 'package:path/path.dart' as p;
import 'package:trios/save_archiver/save_archive_tool.dart';

/// A stand-in archive tool that keeps everything in a small JSON file.
///
/// The point is not to be a good archiver. It is to be an archiver that can be
/// told to fail in one exact way — lose a file, report a wrong size, write a
/// damaged archive, unpack the wrong bytes — so the tests can check that none
/// of those ever costs somebody their save folder.
class FakeSaveArchiveTool implements SaveArchiveTool {
  /// Thrown out of [create] when set.
  Object? throwOnCreate;

  /// When true, [create] reports success without writing anything.
  bool writeNothingOnCreate = false;

  /// When false, every archive fails its integrity check.
  bool integrityPasses = true;

  /// Thrown out of [passesIntegrityTest] when set.
  Object? throwOnIntegrityTest;

  /// Last chance to mangle the archive file after it is written.
  void Function(File archiveFile)? afterCreate;

  /// Changes what [listEntries] reports, without changing the archive.
  List<SaveArchiveEntry> Function(List<SaveArchiveEntry> entries)?
  tamperWithListing;

  /// Thrown out of [extractAll] when set.
  Object? throwOnExtract;

  /// Runs after unpacking, so a test can damage what came out.
  void Function(Directory destination)? afterExtract;

  /// Every archive this tool was asked to create, in order.
  final List<File> created = [];

  @override
  Future<void> create({
    required File archiveFile,
    required Directory sourceFolder,
  }) async {
    created.add(archiveFile);

    final thrown = throwOnCreate;
    if (thrown != null) throw thrown;
    if (writeNothingOnCreate) return;

    final entries = <Map<String, Object?>>[];
    final contents = <String, String>{};
    final rootName = p.basename(sourceFolder.path);

    await for (final entity in sourceFolder.list(
      recursive: true,
      followLinks: false,
    )) {
      final relative = p
          .relative(entity.path, from: sourceFolder.path)
          .replaceAll('\\', '/');
      final archivePath = '$rootName/$relative';

      if (entity is Directory) {
        entries.add({'path': archivePath, 'size': 0, 'crc': null, 'dir': true});
      } else if (entity is File) {
        final bytes = await entity.readAsBytes();
        entries.add({
          'path': archivePath,
          'size': bytes.length,
          'crc': bytes.isEmpty ? null : getCrc32(bytes),
          'dir': false,
        });
        contents[archivePath] = base64Encode(bytes);
      }
    }

    entries.insert(0, {'path': rootName, 'size': 0, 'crc': null, 'dir': true});

    await archiveFile.parent.create(recursive: true);
    await archiveFile.writeAsString(
      jsonEncode({'entries': entries, 'contents': contents}),
      flush: true,
    );

    afterCreate?.call(archiveFile);
  }

  @override
  Future<bool> passesIntegrityTest(File archiveFile) async {
    final thrown = throwOnIntegrityTest;
    if (thrown != null) throw thrown;
    if (!integrityPasses) return false;
    return _read(archiveFile) != null;
  }

  @override
  Future<List<SaveArchiveEntry>> listEntries(File archiveFile) async {
    final body = _read(archiveFile);
    if (body == null)
      throw Exception('Not a fake archive: ${archiveFile.path}');

    final entries = (body['entries'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (entry) => SaveArchiveEntry(
            path: entry['path'] as String,
            sizeInBytes: entry['size'] as int,
            crc32: entry['crc'] as int?,
            isDirectory: entry['dir'] as bool,
          ),
        )
        .toList();

    return tamperWithListing?.call(entries) ?? entries;
  }

  @override
  Future<void> extractAll({
    required File archiveFile,
    required Directory destination,
  }) async {
    final thrown = throwOnExtract;
    if (thrown != null) throw thrown;

    final body = _read(archiveFile);
    if (body == null)
      throw Exception('Not a fake archive: ${archiveFile.path}');

    for (final entry
        in (body['entries'] as List).cast<Map<String, dynamic>>()) {
      final path = entry['path'] as String;
      final target = p.joinAll([destination.path, ...p.posix.split(path)]);
      if (entry['dir'] as bool) {
        await Directory(target).create(recursive: true);
      }
    }

    final contents = (body['contents'] as Map).cast<String, String>();
    for (final entry in contents.entries) {
      final file = File(
        p.joinAll([destination.path, ...p.posix.split(entry.key)]),
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(base64Decode(entry.value), flush: true);
    }

    afterExtract?.call(destination);
  }

  @override
  Future<String?> readTextEntry(File archiveFile, String entryPath) async {
    final body = _read(archiveFile);
    if (body == null) return null;
    final contents = (body['contents'] as Map).cast<String, String>();
    final wanted = entryPath.toLowerCase();
    for (final entry in contents.entries) {
      if (entry.key.toLowerCase() == wanted) {
        return utf8.decode(base64Decode(entry.value), allowMalformed: true);
      }
    }
    return null;
  }

  Map<String, dynamic>? _read(File archiveFile) {
    if (!archiveFile.existsSync()) return null;
    try {
      return jsonDecode(archiveFile.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
