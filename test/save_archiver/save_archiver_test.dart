import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/save_archiver/save_archive_tool.dart';
import 'package:trios/save_archiver/save_archiver.dart';

import 'fake_save_archive_tool.dart';

/// Every test here is about the same promise: a save folder is only ever
/// removed once there is a verified archive holding every byte of it, and
/// nothing on disk is ever written over.
void main() {
  late Directory root;
  late Directory savesFolder;
  late Directory archiveFolder;
  late FakeSaveArchiveTool tool;
  late List<Directory> removedFolders;
  late List<File> removedFiles;

  SaveArchiver buildArchiver({
    Future<void> Function(Directory folder)? removeFolder,
    Future<void> Function(File file)? removeFile,
  }) => SaveArchiver(
    tool: tool,
    savesFolder: savesFolder,
    archiveFolder: archiveFolder,
    removeFolder:
        removeFolder ??
        (folder) async {
          removedFolders.add(folder);
          await folder.delete(recursive: true);
        },
    removeFile:
        removeFile ??
        (file) async {
          removedFiles.add(file);
          await file.delete();
        },
  );

  /// A save folder with a descriptor, a nested file, and an empty file, since
  /// each of those is checked differently.
  Future<Directory> makeSave(
    String name, {
    String descriptor = '<SaveGameData></SaveGameData>',
    String campaign = 'lots and lots of campaign data',
  }) async {
    final folder = Directory(p.join(savesFolder.path, name));
    await folder.create(recursive: true);
    await File(p.join(folder.path, 'descriptor.xml')).writeAsString(descriptor);
    await File(p.join(folder.path, 'campaign.xml')).writeAsString(campaign);
    await Directory(p.join(folder.path, 'nested')).create();
    await File(p.join(folder.path, 'nested', 'deep.xml')).writeAsString('deep');
    await File(p.join(folder.path, 'nested', 'empty.bin')).writeAsString('');
    return folder;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('trios_save_archiver_test');
    savesFolder = Directory(p.join(root.path, 'saves'))..createSync();
    archiveFolder = Directory(p.join(root.path, 'TriOS_Save_Archives'));
    tool = FakeSaveArchiveTool();
    removedFolders = [];
    removedFiles = [];
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  group('archiving a save', () {
    test(
      'writes an archive and removes the folder once it checks out',
      () async {
        final save = await makeSave('save_Wisp_1');

        final outcome = await buildArchiver().archiveSave(save);

        expect(outcome.succeeded, isTrue, reason: outcome.message);
        expect(outcome.archiveFile!.existsSync(), isTrue);
        expect(save.existsSync(), isFalse);
        expect(removedFolders.single.path, save.path);
        expect(p.basename(outcome.archiveFile!.path), 'save_Wisp_1.7z');
      },
    );

    test('leaves no half-written archive behind', () async {
      final save = await makeSave('save_Wisp_1');

      await buildArchiver().archiveSave(save);

      final leftovers = archiveFolder
          .listSync()
          .where(
            (entity) => entity.path.endsWith(SaveArchiver.partialExtension),
          )
          .toList();
      expect(leftovers, isEmpty);
    });

    test('reports each step in order', () async {
      final save = await makeSave('save_Wisp_1');
      final steps = <SaveArchiveStep>[];

      await buildArchiver().archiveSave(save, onProgress: steps.add);

      expect(steps, [
        SaveArchiveStep.checking,
        SaveArchiveStep.readingSaveFolder,
        SaveArchiveStep.compressing,
        SaveArchiveStep.verifying,
        SaveArchiveStep.removingOriginal,
        SaveArchiveStep.finished,
      ]);
    });

    test('does not remove the save when compressing throws', () async {
      final save = await makeSave('save_Wisp_1');
      tool.throwOnCreate = Exception('7-Zip fell over');

      final outcome = await buildArchiver().archiveSave(save);

      expect(outcome.failure, SaveArchiveFailure.compressionFailed);
      expect(save.existsSync(), isTrue);
      expect(removedFolders, isEmpty);
    });

    test('does not remove the save when no archive was written', () async {
      final save = await makeSave('save_Wisp_1');
      tool.writeNothingOnCreate = true;

      final outcome = await buildArchiver().archiveSave(save);

      expect(outcome.failure, SaveArchiveFailure.compressionFailed);
      expect(save.existsSync(), isTrue);
    });

    test(
      'does not remove the save when the archive fails its integrity check',
      () async {
        final save = await makeSave('save_Wisp_1');
        tool.integrityPasses = false;

        final outcome = await buildArchiver().archiveSave(save);

        expect(outcome.failure, SaveArchiveFailure.integrityTestFailed);
        expect(save.existsSync(), isTrue);
        expect(removedFolders, isEmpty);
      },
    );

    test('does not remove the save when the integrity check throws', () async {
      final save = await makeSave('save_Wisp_1');
      tool.throwOnIntegrityTest = Exception('archive unreadable');

      final outcome = await buildArchiver().archiveSave(save);

      expect(outcome.failure, SaveArchiveFailure.integrityTestFailed);
      expect(save.existsSync(), isTrue);
    });

    test(
      'does not remove the save when a file is missing from the archive',
      () async {
        final save = await makeSave('save_Wisp_1');
        tool.tamperWithListing = (entries) => entries
            .where((entry) => !entry.path.endsWith('campaign.xml'))
            .toList();

        final outcome = await buildArchiver().archiveSave(save);

        expect(outcome.failure, SaveArchiveFailure.contentsDoNotMatch);
        expect(outcome.message, contains('campaign.xml'));
        expect(save.existsSync(), isTrue);
      },
    );

    test('does not remove the save when a file is the wrong size', () async {
      final save = await makeSave('save_Wisp_1');
      tool.tamperWithListing = (entries) => entries
          .map(
            (entry) => entry.path.endsWith('campaign.xml')
                ? SaveArchiveEntry(
                    path: entry.path,
                    sizeInBytes: entry.sizeInBytes - 1,
                    crc32: entry.crc32,
                    isDirectory: entry.isDirectory,
                  )
                : entry,
          )
          .toList();

      final outcome = await buildArchiver().archiveSave(save);

      expect(outcome.failure, SaveArchiveFailure.contentsDoNotMatch);
      expect(save.existsSync(), isTrue);
    });

    test('does not remove the save when a checksum does not match', () async {
      final save = await makeSave('save_Wisp_1');
      tool.tamperWithListing = (entries) => entries
          .map(
            (entry) => entry.path.endsWith('campaign.xml')
                ? SaveArchiveEntry(
                    path: entry.path,
                    sizeInBytes: entry.sizeInBytes,
                    crc32: (entry.crc32 ?? 0) + 1,
                    isDirectory: entry.isDirectory,
                  )
                : entry,
          )
          .toList();

      final outcome = await buildArchiver().archiveSave(save);

      expect(outcome.failure, SaveArchiveFailure.contentsDoNotMatch);
      expect(outcome.message, contains('campaign.xml'));
      expect(save.existsSync(), isTrue);
    });

    test(
      'does not remove the save when the archive recorded no checksum',
      () async {
        final save = await makeSave('save_Wisp_1');
        tool.tamperWithListing = (entries) => entries
            .map(
              (entry) => SaveArchiveEntry(
                path: entry.path,
                sizeInBytes: entry.sizeInBytes,
                crc32: null,
                isDirectory: entry.isDirectory,
              ),
            )
            .toList();

        final outcome = await buildArchiver().archiveSave(save);

        expect(outcome.failure, SaveArchiveFailure.contentsDoNotMatch);
        expect(save.existsSync(), isTrue);
      },
    );

    test('an empty file needs no checksum, only the right size', () async {
      final save = await makeSave('save_Wisp_1');

      final outcome = await buildArchiver().archiveSave(save);

      expect(outcome.succeeded, isTrue, reason: outcome.message);
    });

    test('deletes the half-written archive when verification fails', () async {
      final save = await makeSave('save_Wisp_1');
      tool.integrityPasses = false;

      await buildArchiver().archiveSave(save);

      final leftovers = archiveFolder.existsSync()
          ? archiveFolder.listSync()
          : <FileSystemEntity>[];
      expect(leftovers, isEmpty);
      expect(save.existsSync(), isTrue);
    });

    test('says the save is still there when removing it fails', () async {
      final save = await makeSave('save_Wisp_1');

      final outcome = await buildArchiver(
        removeFolder: (folder) async => throw Exception('folder is locked'),
      ).archiveSave(save);

      expect(outcome.succeeded, isFalse);
      expect(outcome.archiveCreated, isTrue);
      expect(outcome.originalRemoved, isFalse);
      expect(outcome.failure, SaveArchiveFailure.couldNotRemoveOriginal);
      expect(outcome.archiveFile!.existsSync(), isTrue);
      expect(save.existsSync(), isTrue);
    });

    test(
      'does not claim success when the remover quietly does nothing',
      () async {
        final save = await makeSave('save_Wisp_1');

        final outcome = await buildArchiver(removeFolder: (folder) async {})
            .archiveSave(save);

        expect(outcome.succeeded, isFalse);
        expect(outcome.failure, SaveArchiveFailure.couldNotRemoveOriginal);
        expect(save.existsSync(), isTrue);
      },
    );

    test('never writes over an existing archive of the same name', () async {
      final first = await makeSave('save_Wisp_1');
      final firstOutcome = await buildArchiver().archiveSave(first);
      final firstArchiveBytes = firstOutcome.archiveFile!.readAsBytesSync();

      final second = await makeSave(
        'save_Wisp_1',
        campaign: 'a completely different campaign',
      );
      final secondOutcome = await buildArchiver().archiveSave(second);

      expect(secondOutcome.succeeded, isTrue, reason: secondOutcome.message);
      expect(p.basename(secondOutcome.archiveFile!.path), 'save_Wisp_1 (2).7z');
      expect(firstOutcome.archiveFile!.readAsBytesSync(), firstArchiveBytes);
    });

    test('refuses a folder that is not in the saves folder', () async {
      final elsewhere = Directory(p.join(root.path, 'important_documents'))
        ..createSync();
      File(p.join(elsewhere.path, 'taxes.txt')).writeAsStringSync('do not');

      final outcome = await buildArchiver().archiveSave(elsewhere);

      expect(outcome.failure, SaveArchiveFailure.saveFolderOutsideSavesFolder);
      expect(elsewhere.existsSync(), isTrue);
      expect(removedFolders, isEmpty);
      expect(tool.created, isEmpty);
    });

    test('refuses a folder nested deeper inside the saves folder', () async {
      final nested = Directory(p.join(savesFolder.path, 'save_a', 'inner'))
        ..createSync(recursive: true);
      File(p.join(nested.path, 'file.txt')).writeAsStringSync('hi');

      final outcome = await buildArchiver().archiveSave(nested);

      expect(outcome.failure, SaveArchiveFailure.saveFolderOutsideSavesFolder);
      expect(nested.existsSync(), isTrue);
    });

    test('refuses the saves folder itself', () async {
      await makeSave('save_Wisp_1');

      final outcome = await buildArchiver().archiveSave(savesFolder);

      expect(outcome.failure, SaveArchiveFailure.saveFolderOutsideSavesFolder);
      expect(savesFolder.existsSync(), isTrue);
      expect(removedFolders, isEmpty);
    });

    test('refuses a folder that is not there', () async {
      final missing = Directory(p.join(savesFolder.path, 'save_gone'));

      final outcome = await buildArchiver().archiveSave(missing);

      expect(outcome.failure, SaveArchiveFailure.saveFolderMissing);
      expect(tool.created, isEmpty);
    });

    test('refuses an empty folder rather than archiving nothing', () async {
      final empty = Directory(p.join(savesFolder.path, 'save_empty'))
        ..createSync();

      final outcome = await buildArchiver().archiveSave(empty);

      expect(outcome.failure, SaveArchiveFailure.saveFolderEmpty);
      expect(empty.existsSync(), isTrue);
      expect(tool.created, isEmpty);
    });

    test('refuses when the archive folder is inside the save folder', () async {
      final save = await makeSave('save_Wisp_1');
      final archiver = SaveArchiver(
        tool: tool,
        savesFolder: savesFolder,
        archiveFolder: Directory(p.join(save.path, 'archives')),
        removeFolder: (folder) async => removedFolders.add(folder),
        removeFile: (file) async => removedFiles.add(file),
      );

      final outcome = await archiver.archiveSave(save);

      expect(outcome.failure, SaveArchiveFailure.archiveFolderInsideSaveFolder);
      expect(save.existsSync(), isTrue);
    });

    test('refuses a save folder holding a symlink', () async {
      final save = await makeSave('save_Wisp_1');
      final link = Link(p.join(save.path, 'shortcut'));
      try {
        link.createSync(p.join(savesFolder.path));
      } on FileSystemException {
        // Windows needs a privilege for this; nothing to test if it's absent.
        return;
      }

      final outcome = await buildArchiver().archiveSave(save);

      expect(outcome.failure, SaveArchiveFailure.unsupportedFolderContents);
      expect(save.existsSync(), isTrue);
      expect(tool.created, isEmpty);
    });
  });

  group('restoring a save', () {
    /// Archives a save and returns the archive, so restore tests start from a
    /// real round trip rather than a hand-made archive.
    Future<File> archiveOne(String name, {String campaign = 'campaign'}) async {
      final save = await makeSave(name, campaign: campaign);
      final outcome = await buildArchiver().archiveSave(save);
      expect(outcome.succeeded, isTrue, reason: outcome.message);
      return outcome.archiveFile!;
    }

    test('puts every file back exactly as it was', () async {
      final archive = await archiveOne('save_Wisp_1', campaign: 'the campaign');

      final outcome = await buildArchiver().restoreSave(archive);

      expect(outcome.succeeded, isTrue, reason: outcome.message);
      final restored = Directory(p.join(savesFolder.path, 'save_Wisp_1'));
      expect(restored.existsSync(), isTrue);
      expect(
        File(p.join(restored.path, 'campaign.xml')).readAsStringSync(),
        'the campaign',
      );
      expect(
        File(p.join(restored.path, 'nested', 'deep.xml')).readAsStringSync(),
        'deep',
      );
      expect(
        File(p.join(restored.path, 'nested', 'empty.bin')).readAsStringSync(),
        '',
      );
    });

    test('keeps the archive unless asked to remove it', () async {
      final archive = await archiveOne('save_Wisp_1');

      final outcome = await buildArchiver().restoreSave(archive);

      expect(outcome.archiveRemoved, isFalse);
      expect(archive.existsSync(), isTrue);
    });

    test('removes the archive when asked, and only after restoring', () async {
      final archive = await archiveOne('save_Wisp_1');

      final outcome = await buildArchiver().restoreSave(
        archive,
        removeArchiveAfterwards: true,
      );

      expect(outcome.succeeded, isTrue, reason: outcome.message);
      expect(outcome.archiveRemoved, isTrue);
      expect(archive.existsSync(), isFalse);
      expect(removedFiles.single.path, archive.path);
    });

    test('refuses to write over a save folder that is already there', () async {
      final archive = await archiveOne('save_Wisp_1', campaign: 'archived');
      final inTheWay = await makeSave('save_Wisp_1', campaign: 'live save');

      final outcome = await buildArchiver().restoreSave(
        archive,
        removeArchiveAfterwards: true,
      );

      expect(outcome.failure, SaveArchiveFailure.saveAlreadyExists);
      expect(outcome.restored, isFalse);
      expect(
        File(p.join(inTheWay.path, 'campaign.xml')).readAsStringSync(),
        'live save',
      );
      expect(archive.existsSync(), isTrue, reason: 'archive must be kept');
    });

    test('leaves nothing in the saves folder when unpacking throws', () async {
      final archive = await archiveOne('save_Wisp_1');
      tool.throwOnExtract = Exception('disk full');

      final outcome = await buildArchiver().restoreSave(archive);

      expect(outcome.failure, SaveArchiveFailure.extractionFailed);
      expect(savesFolder.listSync(), isEmpty);
      expect(archive.existsSync(), isTrue);
    });

    test(
      'leaves nothing in the saves folder when the archive is damaged',
      () async {
        final archive = await archiveOne('save_Wisp_1');
        tool.integrityPasses = false;

        final outcome = await buildArchiver().restoreSave(
          archive,
          removeArchiveAfterwards: true,
        );

        expect(outcome.failure, SaveArchiveFailure.integrityTestFailed);
        expect(savesFolder.listSync(), isEmpty);
        expect(archive.existsSync(), isTrue);
      },
    );

    test('refuses when a file comes out of the archive damaged', () async {
      final archive = await archiveOne('save_Wisp_1');
      tool.afterExtract = (destination) {
        File(p.join(destination.path, 'save_Wisp_1', 'campaign.xml'))
            .writeAsStringSync('corrupted but the same length!!!');
      };

      final outcome = await buildArchiver().restoreSave(archive);

      expect(outcome.failure, SaveArchiveFailure.extractedContentsDoNotMatch);
      expect(savesFolder.listSync(), isEmpty);
    });

    test('refuses when a file never comes out of the archive', () async {
      final archive = await archiveOne('save_Wisp_1');
      tool.afterExtract = (destination) {
        File(p.join(destination.path, 'save_Wisp_1', 'campaign.xml'))
            .deleteSync();
      };

      final outcome = await buildArchiver().restoreSave(archive);

      expect(outcome.failure, SaveArchiveFailure.extractedContentsDoNotMatch);
      expect(savesFolder.listSync(), isEmpty);
    });

    test('cleans up its temporary folder whether it works or not', () async {
      final archive = await archiveOne('save_Wisp_1');

      await buildArchiver().restoreSave(archive);
      tool.throwOnExtract = Exception('nope');
      final second = await archiveOne('save_Wisp_2');
      await buildArchiver().restoreSave(second);

      final leftovers = archiveFolder
          .listSync()
          .where(
            (entity) => p
                .basename(entity.path)
                .startsWith(SaveArchiver.restoreTempPrefix),
          )
          .toList();
      expect(leftovers, isEmpty);
    });

    test('refuses an archive that is not there', () async {
      final missing = File(p.join(root.path, 'nope.7z'));

      final outcome = await buildArchiver().restoreSave(missing);

      expect(outcome.failure, SaveArchiveFailure.archiveMissing);
    });

    test('a save survives being archived and restored twice', () async {
      final archive = await archiveOne('save_Wisp_1', campaign: 'round trip');

      await buildArchiver().restoreSave(archive, removeArchiveAfterwards: true);
      final restored = Directory(p.join(savesFolder.path, 'save_Wisp_1'));
      final secondOutcome = await buildArchiver().archiveSave(restored);
      expect(secondOutcome.succeeded, isTrue, reason: secondOutcome.message);
      final finalOutcome = await buildArchiver().restoreSave(
        secondOutcome.archiveFile!,
      );

      expect(finalOutcome.succeeded, isTrue, reason: finalOutcome.message);
      expect(
        File(p.join(savesFolder.path, 'save_Wisp_1', 'campaign.xml'))
            .readAsStringSync(),
        'round trip',
      );
    });
  });

  group('working out the folder inside an archive', () {
    SaveArchiveEntry entry(String path, {bool isDirectory = false}) =>
        SaveArchiveEntry(
          path: path,
          sizeInBytes: isDirectory ? 0 : 1,
          crc32: isDirectory ? null : 1,
          isDirectory: isDirectory,
        );

    test('finds the one folder everything sits in', () {
      expect(
        SaveArchiver.archiveRootFolderName([
          entry('save_Wisp_1', isDirectory: true),
          entry('save_Wisp_1/descriptor.xml'),
          entry('save_Wisp_1/nested/deep.xml'),
        ]),
        'save_Wisp_1',
      );
    });

    test('reads Windows separators the same as Unix ones', () {
      expect(
        SaveArchiveEntry(
          path: r'save_Wisp_1\descriptor.xml',
          sizeInBytes: 1,
          crc32: 1,
          isDirectory: false,
        ).path,
        r'save_Wisp_1\descriptor.xml',
      );
      expect(
        SaveArchiver.archiveRootFolderName([
          entry(r'save_Wisp_1\descriptor.xml'),
          entry(r'save_Wisp_1\nested\deep.xml'),
        ]),
        'save_Wisp_1',
      );
    });

    test('gives up when the entries are not all in one folder', () {
      expect(
        SaveArchiver.archiveRootFolderName([
          entry('save_a/descriptor.xml'),
          entry('save_b/descriptor.xml'),
        ]),
        isNull,
      );
    });

    test('gives up when everything is loose at the top', () {
      expect(
        SaveArchiver.archiveRootFolderName([
          entry('descriptor.xml'),
          entry('campaign.xml'),
        ]),
        isNull,
      );
    });
  });

  group('reading a save folder', () {
    test('lists every file, nested ones included, with sizes', () async {
      final save = await makeSave('save_Wisp_1', campaign: '12345');

      final manifest = await SaveArchiver.readSaveFolderManifest(save);

      expect(manifest.files.map((file) => file.relativePath).toSet(), {
        'descriptor.xml',
        'campaign.xml',
        'nested/deep.xml',
        'nested/empty.bin',
      });
      expect(
        manifest.files
            .firstWhere((file) => file.relativePath == 'campaign.xml')
            .sizeInBytes,
        5,
      );
      expect(manifest.totalSizeInBytes, greaterThan(0));
    });

    test('checksums match what the archive format would record', () async {
      final folder = Directory(p.join(root.path, 'crc'))..createSync();
      await File(p.join(folder.path, 'a.txt')).writeAsString('123456789');

      final manifest = await SaveArchiver.readSaveFolderManifest(folder);

      // The standard CRC32 of "123456789", which every implementation agrees on.
      expect(manifest.files.single.crc32, 0xCBF43926);
    });
  });
}
