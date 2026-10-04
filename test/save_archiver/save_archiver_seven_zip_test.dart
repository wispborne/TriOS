import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/save_archiver/save_archive_tool.dart';
import 'package:trios/save_archiver/save_archiver.dart';

import 'seven_zip_for_tests.dart';

/// The same promises as `save_archiver_test.dart`, but against the real 7-Zip
/// binary the app ships, on real files. The fake tool can be told to fail on
/// cue; only this one proves the whole thing works end to end.
void main() {
  final sevenZip = sevenZipFromRepo();
  if (sevenZip == null) {
    // No binary for this machine's platform. Nothing here can run.
    return;
  }

  final tool = SevenZipSaveArchiveTool(sevenZip);

  late Directory root;
  late Directory savesFolder;
  late Directory archiveFolder;

  SaveArchiver buildArchiver() => SaveArchiver(
    tool: tool,
    savesFolder: savesFolder,
    archiveFolder: archiveFolder,
    removeFolder: (folder) => folder.delete(recursive: true),
    removeFile: (file) => file.delete(),
  );

  /// A save folder with the awkward cases in it: nested folders, an empty file,
  /// bytes that aren't text, a name that isn't ASCII, and a file big enough to
  /// be read in more than one chunk.
  Future<Directory> makeSave(String name) async {
    final folder = Directory(p.join(savesFolder.path, name));
    await folder.create(recursive: true);

    await File(p.join(folder.path, 'descriptor.xml')).writeAsString(
      '<SaveGameData><characterName>Wisp</characterName>'
      '</SaveGameData>',
    );
    await File(p.join(folder.path, 'empty.bin')).writeAsString('');
    await File(p.join(folder.path, 'Ünïcödé — name.txt'))
        .writeAsString('non-ascii name and contents: ✦ ☄ ♆');

    final random = Random(20260921);
    await File(p.join(folder.path, 'binary.dat')).writeAsBytes(
      Uint8List.fromList(List.generate(200000, (_) => random.nextInt(256))),
    );

    final nested = Directory(p.join(folder.path, 'nested', 'deeper'));
    await nested.create(recursive: true);
    await File(p.join(nested.path, 'campaign.xml'))
        .writeAsString('<campaign>${'sector data ' * 20000}</campaign>');

    return folder;
  }

  /// Every file under [folder], as a map of relative path to bytes.
  Future<Map<String, List<int>>> readEverything(Directory folder) async {
    final contents = <String, List<int>>{};
    await for (final entity in folder.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      contents[p
          .relative(entity.path, from: folder.path)
          .replaceAll('\\', '/')] = await entity
          .readAsBytes();
    }
    return contents;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('trios_save_7z_test');
    savesFolder = Directory(p.join(root.path, 'saves'))..createSync();
    archiveFolder = Directory(p.join(root.path, 'TriOS_Save_Archives'));
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('a save survives a full round trip, byte for byte', () async {
    final save = await makeSave('save_Wisp_9001');
    final before = await readEverything(save);
    expect(before, hasLength(5));

    final archived = await buildArchiver().archiveSave(save);
    expect(archived.succeeded, isTrue, reason: archived.message);
    expect(save.existsSync(), isFalse, reason: 'the original should be gone');
    expect(archived.archiveFile!.existsSync(), isTrue);

    final restored = await buildArchiver().restoreSave(archived.archiveFile!);
    expect(restored.succeeded, isTrue, reason: restored.message);

    final after = await readEverything(restored.restoredFolder!);
    expect(after.keys.toSet(), before.keys.toSet());
    for (final path in before.keys) {
      expect(after[path], before[path], reason: '$path changed');
    }
  });

  test('the archive is smaller than the save it came from', () async {
    final save = await makeSave('save_Wisp_9001');
    final manifest = await SaveArchiver.readSaveFolderManifest(save);

    final archived = await buildArchiver().archiveSave(save);

    expect(archived.succeeded, isTrue, reason: archived.message);
    expect(
      archived.archiveFile!.lengthSync(),
      lessThan(manifest.totalSizeInBytes),
    );
  });

  test('7-Zip reports the same sizes and checksums the folder has', () async {
    final save = await makeSave('save_Wisp_9001');
    final manifest = await SaveArchiver.readSaveFolderManifest(save);

    final archived = await buildArchiver().archiveSave(save);
    final entries = await tool.listEntries(archived.archiveFile!);
    final byPath = {
      for (final entry in entries.where((entry) => !entry.isDirectory))
        entry.path: entry,
    };

    for (final file in manifest.files) {
      final entry = byPath['save_Wisp_9001/${file.relativePath}'];
      expect(entry, isNotNull, reason: file.relativePath);
      expect(entry!.sizeInBytes, file.sizeInBytes, reason: file.relativePath);
      if (file.sizeInBytes > 0) {
        expect(entry.crc32, file.crc32, reason: file.relativePath);
      }
    }
  });

  test('a damaged archive is refused, and nothing lands in saves', () async {
    final save = await makeSave('save_Wisp_9001');
    final archived = await buildArchiver().archiveSave(save);
    final archiveFile = archived.archiveFile!;

    // Flip bits in the middle of the compressed data.
    final bytes = await archiveFile.readAsBytes();
    for (var offset = bytes.length ~/ 3; offset < bytes.length ~/ 2; offset++) {
      bytes[offset] = bytes[offset] ^ 0xFF;
    }
    await archiveFile.writeAsBytes(bytes, flush: true);

    expect(await tool.passesIntegrityTest(archiveFile), isFalse);

    final restored = await buildArchiver().restoreSave(
      archiveFile,
      removeArchiveAfterwards: true,
    );

    expect(restored.succeeded, isFalse);
    expect(savesFolder.listSync(), isEmpty);
    expect(
      archiveFile.existsSync(),
      isTrue,
      reason: 'a damaged archive is still the only copy; never delete it',
    );
  });

  test('a truncated archive is refused', () async {
    final save = await makeSave('save_Wisp_9001');
    final archived = await buildArchiver().archiveSave(save);
    final archiveFile = archived.archiveFile!;

    final bytes = await archiveFile.readAsBytes();
    await archiveFile.writeAsBytes(
      bytes.sublist(0, bytes.length ~/ 2),
      flush: true,
    );

    final restored = await buildArchiver().restoreSave(archiveFile);

    expect(restored.succeeded, isFalse);
    expect(savesFolder.listSync(), isEmpty);
  });

  test(
    'restoring refuses to write over a save that is already there',
    () async {
      final save = await makeSave('save_Wisp_9001');
      final archived = await buildArchiver().archiveSave(save);

      final inTheWay = Directory(p.join(savesFolder.path, 'save_Wisp_9001'))
        ..createSync();
      File(p.join(inTheWay.path, 'descriptor.xml'))
          .writeAsStringSync('the live save');

      final restored = await buildArchiver().restoreSave(archived.archiveFile!);

      expect(restored.failure, SaveArchiveFailure.saveAlreadyExists);
      expect(
        File(p.join(inTheWay.path, 'descriptor.xml')).readAsStringSync(),
        'the live save',
      );
    },
  );

  test('two saves of the same name get two archives, not one', () async {
    final first = await makeSave('save_Wisp_9001');
    final firstArchive = (await buildArchiver().archiveSave(first))
        .archiveFile!;
    final firstBytes = firstArchive.readAsBytesSync();

    final second = await makeSave('save_Wisp_9001');
    await File(p.join(second.path, 'descriptor.xml'))
        .writeAsString('a different save entirely');
    final secondArchive = (await buildArchiver().archiveSave(second))
        .archiveFile!;

    expect(p.basename(secondArchive.path), 'save_Wisp_9001 (2).7z');
    expect(firstArchive.readAsBytesSync(), firstBytes);
  });

  test('the descriptor can be read straight out of the archive', () async {
    final save = await makeSave('save_Wisp_9001');
    final archived = await buildArchiver().archiveSave(save);

    final text = await tool.readTextEntry(
      archived.archiveFile!,
      'save_Wisp_9001/descriptor.xml',
    );

    expect(text, contains('<characterName>Wisp</characterName>'));
  });

  test('reading an entry that is not in the archive gives null', () async {
    final save = await makeSave('save_Wisp_9001');
    final archived = await buildArchiver().archiveSave(save);

    expect(
      await tool.readTextEntry(
        archived.archiveFile!,
        'save_Wisp_9001/nope.xml',
      ),
      isNull,
    );
  });

  test('a save folder with one file still round trips', () async {
    final save = Directory(p.join(savesFolder.path, 'save_tiny'))
      ..createSync(recursive: true);
    File(p.join(save.path, 'descriptor.xml')).writeAsStringSync('x');

    final archived = await buildArchiver().archiveSave(save);
    expect(archived.succeeded, isTrue, reason: archived.message);

    final restored = await buildArchiver().restoreSave(archived.archiveFile!);
    expect(restored.succeeded, isTrue, reason: restored.message);
    expect(
      File(p.join(savesFolder.path, 'save_tiny', 'descriptor.xml'))
          .readAsStringSync(),
      'x',
    );
  });
}
