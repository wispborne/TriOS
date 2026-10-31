import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/save_archiver/archive_folder_mover.dart';
import 'package:trios/save_archiver/archived_save_store.dart';
import 'package:trios/save_archiver/save_archiver.dart';

void main() {
  late Directory root;
  late Directory fromFolder;
  late Directory toFolder;

  ArchiveFolderMover buildMover({
    Future<void> Function(File source, File destination)? copyFile,
    Future<void> Function(File file)? removeFile,
  }) => ArchiveFolderMover(
    fromFolder: fromFolder,
    toFolder: toFolder,
    removeFile: removeFile ?? (file) => file.delete(),
    copyFile:
        copyFile ?? (source, destination) => source.copy(destination.path),
  );

  Future<File> makeArchive(
    String name, {
    String contents = 'archive bytes',
  }) async {
    final archive = File(p.join(fromFolder.path, '$name.7z'));
    await archive.writeAsString(contents);
    await metadataFileFor(archive).writeAsString('{"saveFolderName":"$name"}');
    return archive;
  }

  List<String> namesIn(Directory folder) => folder.existsSync()
      ? (folder.listSync().map((entity) => p.basename(entity.path)).toList()
          ..sort())
      : [];

  setUp(() async {
    root = await Directory.systemTemp.createTemp('trios_archive_mover_test');
    fromFolder = Directory(p.join(root.path, 'old'))..createSync();
    toFolder = Directory(p.join(root.path, 'new'));
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'moves the archive and its details, then removes the originals',
    () async {
      final archive = await makeArchive('save_Wisp_1', contents: 'the save');
      expect(await buildMover().checkCanMove(), isNull);

      final outcome = await buildMover().moveArchive(archive);

      expect(outcome.succeeded, isTrue, reason: outcome.message);
      expect(outcome.message, isEmpty);
      expect(namesIn(toFolder), ['save_Wisp_1.7z', 'save_Wisp_1.7z.info.json']);
      expect(namesIn(fromFolder), isEmpty);
      expect(outcome.movedTo!.readAsStringSync(), 'the save');
    },
  );

  test(
    'picks a new name instead of replacing an archive already there',
    () async {
      final archive = await makeArchive('save_Wisp_1', contents: 'moving');
      await toFolder.create();
      await File(p.join(toFolder.path, 'save_Wisp_1.7z'))
          .writeAsString('already here');

      final outcome = await buildMover().moveArchive(archive);

      expect(outcome.succeeded, isTrue, reason: outcome.message);
      expect(outcome.message, contains('save_Wisp_1 (2).7z'));
      expect(
        File(p.join(toFolder.path, 'save_Wisp_1.7z')).readAsStringSync(),
        'already here',
        reason: 'the archive already in the new folder must not be touched',
      );
      expect(
        File(p.join(toFolder.path, 'save_Wisp_1 (2).7z')).readAsStringSync(),
        'moving',
      );
    },
  );

  test('a failed copy leaves the original alone and no partial file', () async {
    final archive = await makeArchive('save_Wisp_1');

    final outcome = await buildMover(
      copyFile: (source, destination) async {
        await destination.writeAsString('half');
        throw const FileSystemException('disk full');
      },
    ).moveArchive(archive);

    expect(outcome.moved, isFalse);
    expect(outcome.message, contains('disk full'));
    expect(outcome.message, contains('left in the old folder'));
    expect(archive.existsSync(), isTrue);
    expect(metadataFileFor(archive).existsSync(), isTrue);
    expect(namesIn(toFolder), isEmpty);
  });

  test(
    'a copy that does not match is thrown away and the original kept',
    () async {
      final archive = await makeArchive(
        'save_Wisp_1',
        contents: 'the real save',
      );

      final outcome = await buildMover(
        copyFile: (source, destination) =>
            destination.writeAsString('the real sav!'),
      ).moveArchive(archive);

      expect(outcome.moved, isFalse);
      expect(outcome.message, contains('does not match'));
      expect(archive.readAsStringSync(), 'the real save');
      expect(namesIn(toFolder), isEmpty);
    },
  );

  test('a short copy is thrown away and the original kept', () async {
    final archive = await makeArchive('save_Wisp_1', contents: 'the real save');

    final outcome = await buildMover(
      copyFile: (source, destination) => destination.writeAsString('the'),
    ).moveArchive(archive);

    expect(outcome.moved, isFalse);
    expect(archive.existsSync(), isTrue);
    expect(namesIn(toFolder), isEmpty);
  });

  test(
    'when the original cannot be removed, both copies are kept and it says so',
    () async {
      final archive = await makeArchive('save_Wisp_1');

      final outcome = await buildMover(
        removeFile: (file) async => throw const FileSystemException('in use'),
      ).moveArchive(archive);

      expect(outcome.moved, isTrue);
      expect(outcome.originalRemoved, isFalse);
      expect(outcome.message, contains('two copies'));
      expect(outcome.message, contains('in use'));
      expect(archive.existsSync(), isTrue);
      expect(metadataFileFor(archive).existsSync(), isTrue);
      expect(outcome.movedTo!.existsSync(), isTrue);
    },
  );

  test('an archive that has gone missing is reported, not moved', () async {
    final archive = await makeArchive('save_Wisp_1');
    await archive.delete();

    final outcome = await buildMover().moveArchive(archive);

    expect(outcome.moved, isFalse);
    expect(outcome.message, contains('not there any more'));
  });

  test('an archive without a details file still moves', () async {
    final archive = await makeArchive('save_Wisp_1');
    await metadataFileFor(archive).delete();

    final outcome = await buildMover().moveArchive(archive);

    expect(outcome.succeeded, isTrue, reason: outcome.message);
    expect(namesIn(toFolder), ['save_Wisp_1.7z']);
  });

  test('lists only finished archives', () async {
    await makeArchive('save_Wisp_1');
    await File(
      p.join(fromFolder.path, 'save_Wisp_2.7z${SaveArchiver.partialExtension}'),
    ).writeAsString('unfinished');
    await File(p.join(fromFolder.path, 'notes.txt')).writeAsString('notes');

    final archives = await ArchiveFolderMover.listArchives(fromFolder);

    expect(archives.map((file) => p.basename(file.path)), ['save_Wisp_1.7z']);
  });

  test('refuses a new folder that cannot be written to', () async {
    // A file where the folder should be cannot be turned into a folder.
    toFolder = Directory(p.join(root.path, 'blocked'));
    await File(toFolder.path).writeAsString('in the way');

    expect(await buildMover().checkCanMove(), isNotNull);
  });

  test('refuses moving a folder onto itself', () async {
    toFolder = fromFolder;

    expect(await buildMover().checkCanMove(), contains('same'));
  });
}
