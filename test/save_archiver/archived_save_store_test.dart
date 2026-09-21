import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/mod_profiles/save_reader.dart';
import 'package:trios/save_archiver/archived_save_store.dart';
import 'package:trios/save_archiver/models/archived_save.dart';
import 'package:trios/save_archiver/save_archive_selection.dart';
import 'package:trios/save_archiver/save_archiver.dart';

import 'fake_save_archive_tool.dart';

/// Reading an archive's details for the list. None of this is allowed to stop
/// an archive from showing up: an archive TriOS can't describe is still an
/// archive somebody might need back.
void main() {
  late Directory root;
  late Directory savesFolder;
  late Directory archiveFolder;
  late FakeSaveArchiveTool tool;

  String descriptorXml({
    String characterName = 'Wisp',
    int level = 42,
    String saveDate = '2026-09-14 11:22:33.44 UTC',
  }) =>
      '''
<SaveGameData>
  <portraitName>graphics/portraits/portrait1.png</portraitName>
  <characterName>$characterName</characterName>
  <characterLevel>$level</characterLevel>
  <saveFileVersion>0.98a-RC8</saveFileVersion>
  <saveDate>$saveDate</saveDate>
  <compressed>true</compressed>
  <isIronMode>false</isIronMode>
  <difficulty>normal</difficulty>
  <gameDate>
    <secondsPerDay>10.0</secondsPerDay>
    <timestamp>123456789</timestamp>
  </gameDate>
  <allModsEverEnabled>
    <EnabledModData>
      <spec z="1">
        <id>lw_lazylib</id>
        <name>LazyLib</name>
        <versionInfo>
          <string>2.8</string>
          <major>2</major>
          <minor>8</minor>
          <patch></patch>
        </versionInfo>
      </spec>
    </EnabledModData>
  </allModsEverEnabled>
  <enabledMods>
    <EnabledModData><spec ref="1"/></EnabledModData>
  </enabledMods>
</SaveGameData>
''';

  /// Makes a save folder and compresses it with the fake tool, returning the
  /// archive. No note is written, so each test can decide what state to put the
  /// archive in.
  Future<File> makeArchive(
    String folderName, {
    String? descriptor,
    String campaign = 'campaign data',
  }) async {
    final folder = Directory(p.join(savesFolder.path, folderName))
      ..createSync(recursive: true);
    if (descriptor != null) {
      File(p.join(folder.path, 'descriptor.xml')).writeAsStringSync(descriptor);
    }
    File(p.join(folder.path, 'campaign.xml')).writeAsStringSync(campaign);

    final archive = File(
      p.join(archiveFolder.path, '$folderName${SaveArchiver.archiveExtension}'),
    );
    await tool.create(archiveFile: archive, sourceFolder: folder);
    await folder.delete(recursive: true);
    return archive;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('trios_archive_store_test');
    savesFolder = Directory(p.join(root.path, 'saves'))..createSync();
    archiveFolder = Directory(p.join(root.path, 'archives'))..createSync();
    tool = FakeSaveArchiveTool();
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  group('the note beside an archive', () {
    test('round trips everything the list shows', () async {
      final archive = await makeArchive(
        'save_Wisp_1',
        descriptor: descriptorXml(),
      );
      final written = ArchivedSave(
        saveFolderName: 'save_Wisp_1',
        characterName: 'Wisp',
        characterLevel: 42,
        saveDate: DateTime.utc(2026, 9, 14, 11, 22, 33),
        modNames: const ['LazyLib', 'MagicLib'],
        fileCount: 2,
        originalSizeInBytes: 1000,
        archiveSizeInBytes: 250,
        archivedDate: DateTime.utc(2026, 9, 20),
      );

      await writeArchivedSaveMetadata(archive, written);
      final read = await readArchivedSaveMetadata(archive);

      expect(read, isNotNull);
      expect(read!.saveFolderName, 'save_Wisp_1');
      expect(read.characterName, 'Wisp');
      expect(read.characterLevel, 42);
      expect(read.saveDate, DateTime.utc(2026, 9, 14, 11, 22, 33));
      expect(read.modNames, ['LazyLib', 'MagicLib']);
      expect(read.archivedDate, DateTime.utc(2026, 9, 20));
    });

    test('is named after the whole archive file, so it never collides', () {
      final archive = File(p.join(archiveFolder.path, 'save_Wisp_1.7z'));

      expect(
        p.basename(metadataFileFor(archive).path),
        'save_Wisp_1.7z.info.json',
      );
    });

    test('a note that is not readable is ignored rather than thrown', () async {
      final archive = await makeArchive('save_Wisp_1');
      await metadataFileFor(archive).writeAsString('{ this is not json');

      expect(await readArchivedSaveMetadata(archive), isNull);
    });

    test('space saved is worked out from the two sizes', () {
      final info = ArchivedSave(
        saveFolderName: 'save_Wisp_1',
        originalSizeInBytes: 1000,
        archiveSizeInBytes: 250,
        archivedDate: DateTime.utc(2026),
      );

      expect(info.spaceSavedFraction, 0.75);
    });

    test('space saved is unknown when the original size was not recorded', () {
      final info = ArchivedSave(
        saveFolderName: 'save_Wisp_1',
        archiveSizeInBytes: 250,
        archivedDate: DateTime.utc(2026),
      );

      expect(info.spaceSavedFraction, isNull);
    });
  });

  group('listing the archive folder', () {
    test(
      'reads the details out of the archive when there is no note',
      () async {
        final archive = await makeArchive(
          'save_Wisp_1',
          descriptor: descriptorXml(characterName: 'Andrada', level: 7),
        );

        final entries = await readArchivedSaves(archiveFolder, tool);

        expect(entries, hasLength(1));
        expect(entries.single.info!.characterName, 'Andrada');
        expect(entries.single.info!.characterLevel, 7);
        expect(entries.single.info!.saveFolderName, 'save_Wisp_1');
        expect(entries.single.info!.modNames, ['LazyLib']);
        expect(entries.single.displayName, 'Andrada');
      },
    );

    test(
      'writes the note so the next listing does not unpack anything',
      () async {
        final archive = await makeArchive(
          'save_Wisp_1',
          descriptor: descriptorXml(),
        );
        expect(metadataFileFor(archive).existsSync(), isFalse);

        await readArchivedSaves(archiveFolder, tool);

        expect(metadataFileFor(archive).existsSync(), isTrue);
      },
    );

    test('prefers the note over unpacking the archive', () async {
      final archive = await makeArchive(
        'save_Wisp_1',
        descriptor: descriptorXml(characterName: 'FromTheArchive'),
      );
      await writeArchivedSaveMetadata(
        archive,
        ArchivedSave(
          saveFolderName: 'save_Wisp_1',
          characterName: 'FromTheNote',
          archivedDate: DateTime.utc(2026),
        ),
      );

      final entries = await readArchivedSaves(archiveFolder, tool);

      expect(entries.single.info!.characterName, 'FromTheNote');
    });

    test('still lists an archive with no descriptor in it', () async {
      await makeArchive('save_Wisp_1');

      final entries = await readArchivedSaves(archiveFolder, tool);

      expect(entries, hasLength(1));
      expect(entries.single.saveFolderName, 'save_Wisp_1');
      expect(entries.single.info!.characterName, isNull);
    });

    test('still lists an archive it cannot read at all', () async {
      await File(p.join(archiveFolder.path, 'handmade.7z'))
          .writeAsString('not an archive');

      final entries = await readArchivedSaves(archiveFolder, tool);

      expect(entries, hasLength(1));
      expect(entries.single.info, isNull);
      expect(entries.single.saveFolderName, 'handmade');
      expect(entries.single.displayName, 'handmade');
    });

    test(
      'ignores the notes and anything else that is not an archive',
      () async {
        await makeArchive('save_Wisp_1', descriptor: descriptorXml());
        await File(p.join(archiveFolder.path, 'readme.txt'))
            .writeAsString('hi');

        final entries = await readArchivedSaves(archiveFolder, tool);

        expect(entries, hasLength(1));
        expect(p.basename(entries.single.archiveFile.path), 'save_Wisp_1.7z');
      },
    );

    test('an archive folder that is not there yet lists as empty', () async {
      final missing = Directory(p.join(root.path, 'not_created_yet'));

      expect(await readArchivedSaves(missing, tool), isEmpty);
    });

    test('sorts newest save first', () async {
      await makeArchive(
        'save_old',
        descriptor: descriptorXml(saveDate: '2026-01-01 10:00:00.00 UTC'),
      );
      await makeArchive(
        'save_new',
        descriptor: descriptorXml(saveDate: '2026-09-01 10:00:00.00 UTC'),
      );
      await makeArchive(
        'save_middle',
        descriptor: descriptorXml(saveDate: '2026-05-01 10:00:00.00 UTC'),
      );

      final entries = await readArchivedSaves(archiveFolder, tool);

      expect(entries.map((entry) => entry.saveFolderName), [
        'save_new',
        'save_middle',
        'save_old',
      ]);
    });

    test('restoring the newest takes them off the top of that order', () async {
      await makeArchive(
        'save_old',
        descriptor: descriptorXml(saveDate: '2026-01-01 10:00:00.00 UTC'),
      );
      await makeArchive(
        'save_new',
        descriptor: descriptorXml(saveDate: '2026-09-01 10:00:00.00 UTC'),
      );

      final entries = await readArchivedSaves(archiveFolder, tool);

      expect(archivesToRestoreNewest(entries, 1).map((e) => e.saveFolderName), [
        'save_new',
      ]);
      expect(archivesToRestoreNewest(entries, 0), isEmpty);
      expect(archivesToRestoreNewest(entries, 99), hasLength(2));
    });
  });

  group('building the note after archiving', () {
    test('copies what the save said about itself', () async {
      final folder = Directory(p.join(savesFolder.path, 'save_Wisp_1'))
        ..createSync(recursive: true);
      final save = parseSaveDescriptor(
        descriptorXml(characterName: 'Cotton'),
        folder,
      );

      final info = buildArchivedSave(
        saveFolderName: 'save_Wisp_1',
        save: save,
        fileCount: 12,
        originalSizeInBytes: 5000,
        archiveSizeInBytes: 1200,
        archivedDate: DateTime.utc(2026, 9, 21),
      );

      expect(info.characterName, 'Cotton');
      expect(info.characterLevel, 42);
      expect(info.modNames, ['LazyLib']);
      expect(info.fileCount, 12);
      expect(info.originalSizeInBytes, 5000);
      expect(info.archiveSizeInBytes, 1200);
      expect(info.archivedDate, DateTime.utc(2026, 9, 21));
    });

    test('works with no save details at all', () {
      final info = buildArchivedSave(
        saveFolderName: 'save_Wisp_1',
        save: null,
        fileCount: 1,
        originalSizeInBytes: 10,
        archiveSizeInBytes: 5,
      );

      expect(info.saveFolderName, 'save_Wisp_1');
      expect(info.characterName, isNull);
      expect(info.modNames, isEmpty);
    });
  });
}
