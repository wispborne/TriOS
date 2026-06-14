import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/compression/archive.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation.dart';
import 'package:trios/mod_manager/batch_installation/batch_pre_scanner.dart';
import 'package:trios/mod_manager/mod_install_source.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';

// ── Helpers ──────────────────────────────────────────────────────────────

ModInfo _modInfo({
  String id = 'test_mod',
  String? name,
  Version? version,
}) =>
    ModInfo(id: id, name: name ?? id, version: version);

BatchEntry _entry({
  String id = '1',
  String path = 'fake.zip',
  BatchEntryStatus status = BatchEntryStatus.queued,
  ScannedArchive? scanResult,
}) =>
    BatchEntry(
      id: id,
      source: File(path),
      status: status,
      scanResult: scanResult,
    );

ScannedArchive _scannedArchive({
  ModInfo? modInfo,
  ModVariant? existingVariant,
  bool hasMultipleMods = false,
  List<ExtractedModInfo>? allModInfos,
}) {
  final info = modInfo ?? _modInfo();
  return ScannedArchive(
    modInfo: info,
    fileCount: 10,
    existingVariant: existingVariant,
    hasMultipleMods: hasMultipleMods,
    allModInfos: allModInfos ?? [],
  );
}

// ── Fake archive for BatchPreScanner tests ───────────────────────────

class _FakeArchiveEntry implements ArchiveEntry {
  @override
  final String path;
  _FakeArchiveEntry(this.path);
}

class _FakeExtractedFile implements ArchiveExtractedFile<_FakeArchiveEntry> {
  @override
  final _FakeArchiveEntry archiveFile;
  @override
  final File extractedFile;
  _FakeExtractedFile(this.archiveFile, this.extractedFile);
}

class _FakeArchive implements ArchiveInterface {
  final Map<String, List<String>> fileListings;
  final Map<String, String> modInfoContents;

  _FakeArchive({
    this.fileListings = const {},
    this.modInfoContents = const {},
  });

  @override
  Future<List<ArchiveEntry>> listFiles(File archiveFile) async {
    final paths = fileListings[archiveFile.path] ?? [];
    return paths.map((p) => _FakeArchiveEntry(p)).toList();
  }

  @override
  Future<List<ArchiveExtractedFile?>> extractEntriesInArchive(
    File archivePath,
    String destinationPath, {
    bool Function(ArchiveEntry entry)? fileFilter,
    String Function(ArchiveEntry entry)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
    void Function(int completed, int total)? onProgress,
    void Function(String phase)? onPhaseChanged,
  }) async {
    final paths = fileListings[archivePath.path] ?? [];
    final filtered = paths.where(
      (p) => fileFilter == null || fileFilter(_FakeArchiveEntry(p)),
    );

    final results = <ArchiveExtractedFile?>[];
    for (final path in filtered) {
      final content = modInfoContents[path];
      if (content != null) {
        final tempFile = File('$destinationPath/$path');
        await tempFile.parent.create(recursive: true);
        await tempFile.writeAsString(content);
        results.add(_FakeExtractedFile(_FakeArchiveEntry(path), tempFile));
      }
    }
    return results;
  }

  @override
  Future<void> extractAll(File archiveFile, Directory destination) async {}
  @override
  Future<void> extractSome(
    File archiveFile,
    Directory destination,
    List<String> inArchivePaths,
  ) async {}
  @override
  Future<List<ArchiveReadFile?>> readEntriesInArchive(
    File archivePath, {
    bool Function(ArchiveEntry entry)? fileFilter,
    String Function(ArchiveEntry entry)? pathTransform,
    bool Function(Object ex, StackTrace st)? onError,
  }) async =>
      [];
}

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  group('BatchEntry', () {
    test('displayName falls back to archive filename', () {
      final entry = _entry(path: '/mods/CoolMod.zip');
      expect(entry.displayName, 'CoolMod.zip');
    });

    test('displayName uses scan result mod name when scanned', () {
      final entry = _entry(
        scanResult: _scannedArchive(modInfo: _modInfo(name: 'Cool Mod')),
      );
      expect(entry.displayName, 'Cool Mod');
    });

    test('displayName uses currentModName when extracting', () {
      final entry = _entry(
        scanResult: _scannedArchive(modInfo: _modInfo(name: 'Cool Mod')),
      );
      entry.currentModName = 'Sub Mod';
      expect(entry.displayName, 'Sub Mod');
    });

    test('hasConflict is true when existing variant is present', () {
      final variant = ModVariant(
        modInfo: _modInfo(),
        versionCheckerInfo: null,
        modFolder: Directory('.'),
        hasNonBrickedModInfo: true,
        gameCoreFolder: Directory('.'),
      );
      final entry = _entry(
        scanResult: _scannedArchive(existingVariant: variant),
      );
      expect(entry.hasConflict, isTrue);
    });

    test('hasConflict is false when no existing variant', () {
      final entry = _entry(scanResult: _scannedArchive());
      expect(entry.hasConflict, isFalse);
    });
  });

  group('BatchInstallation', () {
    test('completedCount counts done, failed, and skipped entries', () {
      final batch = BatchInstallation(id: 'b1', entries: [
        _entry(id: '1', status: BatchEntryStatus.done),
        _entry(id: '2', status: BatchEntryStatus.failed),
        _entry(id: '3', status: BatchEntryStatus.skipped),
        _entry(id: '4', status: BatchEntryStatus.extracting),
        _entry(id: '5', status: BatchEntryStatus.queued),
      ]);
      expect(batch.completedCount, 3);
    });

    test('isFinished is true when all entries are terminal', () {
      final batch = BatchInstallation(id: 'b1', entries: [
        _entry(id: '1', status: BatchEntryStatus.done),
        _entry(id: '2', status: BatchEntryStatus.skipped),
        _entry(id: '3', status: BatchEntryStatus.failed),
      ]);
      expect(batch.isFinished, isTrue);
    });

    test('isFinished is false when any entry is still in progress', () {
      final batch = BatchInstallation(id: 'b1', entries: [
        _entry(id: '1', status: BatchEntryStatus.done),
        _entry(id: '2', status: BatchEntryStatus.extracting),
      ]);
      expect(batch.isFinished, isFalse);
    });

    test('installableCount excludes failed entries without scan results', () {
      final batch = BatchInstallation(id: 'b1', entries: [
        _entry(
          id: '1',
          status: BatchEntryStatus.scanned,
          scanResult: _scannedArchive(),
        ),
        _entry(id: '2', status: BatchEntryStatus.failed),
        _entry(
          id: '3',
          status: BatchEntryStatus.scanned,
          scanResult: _scannedArchive(),
        ),
      ]);
      expect(batch.installableCount, 2);
    });

    test('entriesToInstall returns only scanned entries', () {
      final batch = BatchInstallation(id: 'b1', entries: [
        _entry(id: '1', status: BatchEntryStatus.scanned),
        _entry(id: '2', status: BatchEntryStatus.failed),
        _entry(id: '3', status: BatchEntryStatus.done),
        _entry(id: '4', status: BatchEntryStatus.scanned),
      ]);
      expect(batch.entriesToInstall.map((e) => e.id), ['1', '4']);
    });

    test('invalidEntries returns only failed entries without scan results', () {
      final batch = BatchInstallation(id: 'b1', entries: [
        _entry(id: '1', status: BatchEntryStatus.failed),
        _entry(
          id: '2',
          status: BatchEntryStatus.failed,
          scanResult: _scannedArchive(),
        ),
        _entry(id: '3', status: BatchEntryStatus.scanned),
      ]);
      expect(batch.invalidEntries.map((e) => e.id), ['1']);
    });

    test('conflictEntries returns entries with existing variants', () {
      final variant = ModVariant(
        modInfo: _modInfo(),
        versionCheckerInfo: null,
        modFolder: Directory('.'),
        hasNonBrickedModInfo: true,
        gameCoreFolder: Directory('.'),
      );
      final batch = BatchInstallation(id: 'b1', entries: [
        _entry(
          id: '1',
          scanResult: _scannedArchive(existingVariant: variant),
        ),
        _entry(id: '2', scanResult: _scannedArchive()),
      ]);
      expect(batch.conflictEntries.map((e) => e.id), ['1']);
    });

    test('totalCount returns all entries', () {
      final batch = BatchInstallation(id: 'b1', entries: [
        _entry(id: '1'),
        _entry(id: '2'),
        _entry(id: '3'),
      ]);
      expect(batch.totalCount, 3);
    });
  });

  group('BatchPreScanner', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('batch_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('rejects unsupported archive extension', () async {
      final file = File('${tempDir.path}/readme.txt');
      await file.writeAsString('not an archive');

      final entry = _entry(path: file.path);
      final scanner = BatchPreScanner(
        archive: _FakeArchive(),
        existingVariants: [],
      );
      await scanner.scanArchive(entry);

      expect(entry.status, BatchEntryStatus.failed);
      expect(entry.errorDetail, contains('Not a supported archive format'));
    });

    test('rejects nonexistent file', () async {
      final entry = _entry(path: '${tempDir.path}/nonexistent.zip');
      final scanner = BatchPreScanner(
        archive: _FakeArchive(),
        existingVariants: [],
      );
      await scanner.scanArchive(entry);

      expect(entry.status, BatchEntryStatus.failed);
      expect(entry.errorDetail, contains('Source does not exist'));
    });

    test('fails when archive has no mod_info.json', () async {
      final archiveFile = File('${tempDir.path}/empty_mod.zip');
      await archiveFile.writeAsString('fake archive');

      final fakeArchive = _FakeArchive(
        fileListings: {
          archiveFile.path: ['readme.txt', 'data/config.json'],
        },
      );

      final entry = _entry(path: archiveFile.path);
      final scanner = BatchPreScanner(
        archive: fakeArchive,
        existingVariants: [],
      );
      await scanner.scanArchive(entry);

      expect(entry.status, BatchEntryStatus.failed);
      expect(entry.errorDetail, contains('No mod_info.json'));
    });

    test('succeeds with valid single-mod archive', () async {
      final archiveFile = File('${tempDir.path}/good_mod.zip');
      await archiveFile.writeAsString('fake archive');

      const modInfoJson = '{'
          '"id": "test_mod",'
          '"name": "Test Mod",'
          '"version": "1.0.0",'
          '"gameVersion": "0.97a"'
          '}';

      final fakeArchive = _FakeArchive(
        fileListings: {
          archiveFile.path: [
            'TestMod/mod_info.json',
            'TestMod/data/config.json',
          ],
        },
        modInfoContents: {'TestMod/mod_info.json': modInfoJson},
      );

      final entry = _entry(path: archiveFile.path);
      final scanner = BatchPreScanner(
        archive: fakeArchive,
        existingVariants: [],
      );
      await scanner.scanArchive(entry);

      expect(entry.status, BatchEntryStatus.scanned);
      expect(entry.scanResult, isNotNull);
      expect(entry.scanResult!.modInfo.id, 'test_mod');
      expect(entry.scanResult!.modInfo.name, 'Test Mod');
      expect(entry.scanResult!.fileCount, 2);
      expect(entry.scanResult!.hasMultipleMods, isFalse);
      expect(entry.scanResult!.allModInfos.length, 1);
      expect(entry.installSource, isA<ArchiveModInstallSource>());
    });

    test('detects multiple mods in one archive', () async {
      final archiveFile = File('${tempDir.path}/multi_mod.zip');
      await archiveFile.writeAsString('fake archive');

      const modInfoA = '{'
          '"id": "mod_a",'
          '"name": "Mod A",'
          '"version": "1.0.0"'
          '}';
      const modInfoB = '{'
          '"id": "mod_b",'
          '"name": "Mod B",'
          '"version": "2.0.0"'
          '}';

      final fakeArchive = _FakeArchive(
        fileListings: {
          archiveFile.path: [
            'ModA/mod_info.json',
            'ModA/data/stuff.csv',
            'ModB/mod_info.json',
            'ModB/data/other.csv',
          ],
        },
        modInfoContents: {
          'ModA/mod_info.json': modInfoA,
          'ModB/mod_info.json': modInfoB,
        },
      );

      final entry = _entry(path: archiveFile.path);
      final scanner = BatchPreScanner(
        archive: fakeArchive,
        existingVariants: [],
      );
      await scanner.scanArchive(entry);

      expect(entry.status, BatchEntryStatus.scanned);
      expect(entry.scanResult!.hasMultipleMods, isTrue);
      expect(entry.scanResult!.allModInfos.length, 2);
    });

    test('detects existing variant as conflict', () async {
      final archiveFile = File('${tempDir.path}/conflict.zip');
      await archiveFile.writeAsString('fake archive');

      final existingInfo = _modInfo(
        id: 'test_mod',
        version: Version.parse('1.0.0'),
      );
      final existingVariant = ModVariant(
        modInfo: existingInfo,
        versionCheckerInfo: null,
        modFolder: Directory('.'),
        hasNonBrickedModInfo: true,
        gameCoreFolder: Directory('.'),
      );

      const modInfoJson = '{'
          '"id": "test_mod",'
          '"name": "Test Mod",'
          '"version": "1.0.0"'
          '}';

      final fakeArchive = _FakeArchive(
        fileListings: {
          archiveFile.path: ['TestMod/mod_info.json'],
        },
        modInfoContents: {'TestMod/mod_info.json': modInfoJson},
      );

      final entry = _entry(path: archiveFile.path);
      final scanner = BatchPreScanner(
        archive: fakeArchive,
        existingVariants: [existingVariant],
      );
      await scanner.scanArchive(entry);

      expect(entry.status, BatchEntryStatus.scanned);
      expect(entry.scanResult!.existingVariant, existingVariant);
      expect(entry.hasConflict, isTrue);
    });

    test('ignores hidden mod_info.json files starting with dot', () async {
      final archiveFile = File('${tempDir.path}/hidden.zip');
      await archiveFile.writeAsString('fake archive');

      const realModInfo = '{'
          '"id": "real_mod",'
          '"name": "Real Mod",'
          '"version": "1.0.0"'
          '}';

      final fakeArchive = _FakeArchive(
        fileListings: {
          archiveFile.path: [
            'Mod/.mod_info.json',
            'Mod/mod_info.json',
          ],
        },
        modInfoContents: {
          'Mod/mod_info.json': realModInfo,
        },
      );

      final entry = _entry(path: archiveFile.path);
      final scanner = BatchPreScanner(
        archive: fakeArchive,
        existingVariants: [],
      );
      await scanner.scanArchive(entry);

      expect(entry.status, BatchEntryStatus.scanned);
      expect(entry.scanResult!.allModInfos.length, 1);
      expect(entry.scanResult!.modInfo.id, 'real_mod');
    });

    test('scanAll processes multiple entries concurrently', () async {
      final entries = <BatchEntry>[];
      final fakeFileListings = <String, List<String>>{};
      final fakeModInfoContents = <String, String>{};

      for (var i = 0; i < 4; i++) {
        final archiveFile = File('${tempDir.path}/mod_$i.zip');
        await archiveFile.writeAsString('fake');

        final modInfoPath = 'Mod$i/mod_info.json';
        fakeFileListings[archiveFile.path] = [modInfoPath];
        fakeModInfoContents[modInfoPath] = '{'
            '"id": "mod_$i",'
            '"name": "Mod $i",'
            '"version": "1.0.$i"'
            '}';

        entries.add(_entry(id: '$i', path: archiveFile.path));
      }

      final fakeArchive = _FakeArchive(
        fileListings: fakeFileListings,
        modInfoContents: fakeModInfoContents,
      );

      final scannedEntries = <BatchEntry>[];
      final scanner = BatchPreScanner(
        archive: fakeArchive,
        existingVariants: [],
      );
      await scanner.scanAll(
        entries,
        concurrency: 2,
        onEntryScanned: (e) => scannedEntries.add(e),
      );

      expect(scannedEntries.length, 4);
      for (final entry in entries) {
        expect(entry.status, BatchEntryStatus.scanned);
        expect(entry.scanResult, isNotNull);
      }
    });

    test('scanAll handles mix of valid and invalid archives', () async {
      final goodFile = File('${tempDir.path}/good.zip');
      await goodFile.writeAsString('fake');
      final badFile = File('${tempDir.path}/bad.txt');
      await badFile.writeAsString('not archive');

      final fakeArchive = _FakeArchive(
        fileListings: {
          goodFile.path: ['Mod/mod_info.json'],
        },
        modInfoContents: {
          'Mod/mod_info.json': '{'
              '"id": "good_mod",'
              '"name": "Good Mod",'
              '"version": "1.0.0"'
              '}',
        },
      );

      final goodEntry = _entry(id: 'good', path: goodFile.path);
      final badEntry = _entry(id: 'bad', path: badFile.path);

      final scanner = BatchPreScanner(
        archive: fakeArchive,
        existingVariants: [],
      );
      await scanner.scanAll([goodEntry, badEntry], concurrency: 2);

      expect(goodEntry.status, BatchEntryStatus.scanned);
      expect(badEntry.status, BatchEntryStatus.failed);
    });

    test('fails when mod_info.json has invalid JSON', () async {
      final archiveFile = File('${tempDir.path}/bad_json.zip');
      await archiveFile.writeAsString('fake');

      final fakeArchive = _FakeArchive(
        fileListings: {
          archiveFile.path: ['Mod/mod_info.json'],
        },
        modInfoContents: {'Mod/mod_info.json': 'not valid json {{{'},
      );

      final entry = _entry(path: archiveFile.path);
      final scanner = BatchPreScanner(
        archive: fakeArchive,
        existingVariants: [],
      );
      await scanner.scanArchive(entry);

      expect(entry.status, BatchEntryStatus.failed);
      expect(entry.errorDetail, contains('Could not parse'));
    });
  });

  group('BatchStatus', () {
    test('all status values exist', () {
      expect(BatchStatus.values, containsAll([
        BatchStatus.pending,
        BatchStatus.scanning,
        BatchStatus.confirming,
        BatchStatus.installing,
        BatchStatus.complete,
      ]));
    });
  });

  group('BatchEntryStatus', () {
    test('all status values exist', () {
      expect(BatchEntryStatus.values, containsAll([
        BatchEntryStatus.queued,
        BatchEntryStatus.scanning,
        BatchEntryStatus.scanned,
        BatchEntryStatus.extracting,
        BatchEntryStatus.done,
        BatchEntryStatus.failed,
        BatchEntryStatus.skipped,
      ]));
    });
  });
}
