import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/version.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/vram_estimator_manager.dart';

VramEstimatorManagerState _buildFixtureState() {
  final referenced = ModImageTable.fromRows([
    {
      'filePath': 'graphics/ships/foo.png',
      'textureHeight': 128,
      'textureWidth': 128,
      'bitsInAllChannelsSum': 32,
      'imageType': 'texture',
      'graphicsLibType': null,
    },
    {
      'filePath': 'graphics/ships/foo_normal.png',
      'textureHeight': 128,
      'textureWidth': 128,
      'bitsInAllChannelsSum': 32,
      'imageType': 'texture',
      'graphicsLibType': 'Normal',
      'referencedBy': ['graphicslib-csv'],
    },
  ]);
  final unreferenced = ModImageTable.fromRows([
    {
      'filePath': 'graphics/unused_draft.png',
      'textureHeight': 256,
      'textureWidth': 256,
      'bitsInAllChannelsSum': 32,
      'imageType': 'texture',
      'graphicsLibType': null,
    },
  ]);
  final info = VramCheckerMod(
    ModInfo(
      id: 'test_mod',
      name: 'Test Mod',
      version: Version.parse('1.2.3'),
    ),
    '/does/not/exist',
  );
  final mod = VramMod(
    info,
    true,
    referenced,
    const [],
    unreferencedImages: unreferenced,
    scannedAt: DateTime.utc(2026, 4, 24, 12, 0, 0),
  );
  return VramEstimatorManagerState(
    modVramInfo: {info.smolId: mod},
    lastUpdated: DateTime.utc(2026, 4, 24, 12, 5, 0),
  );
}

void _assertRoundTripped(
  VramEstimatorManagerState original,
  VramEstimatorManagerState roundTripped,
) {
  expect(
    roundTripped.modVramInfo.keys.toList(),
    original.modVramInfo.keys.toList(),
  );
  expect(roundTripped.lastUpdated, original.lastUpdated);

  for (final key in original.modVramInfo.keys) {
    final a = original.modVramInfo[key]!;
    final b = roundTripped.modVramInfo[key]!;
    expect(b.info.modInfo.id, a.info.modInfo.id);
    expect(b.info.modInfo.name, a.info.modInfo.name);
    expect(b.images.filePaths, a.images.filePaths);
    expect(b.images.textureWidths, a.images.textureWidths);
    expect(b.images.textureHeights, a.images.textureHeights);
    expect(b.images.graphicsLibTypes, a.images.graphicsLibTypes);
    expect(b.unreferencedImages?.filePaths, a.unreferencedImages?.filePaths);
    expect(b.scannedAt, a.scannedAt);
  }

  // Transient scan fields should always be reset after fromMap.
  expect(roundTripped.isScanning, false);
  expect(roundTripped.isCancelled, false);
  expect(roundTripped.currentlyScanningModName, isNull);
  expect(roundTripped.totalModsToScan, 0);
  expect(roundTripped.modsScannedThisRun, 0);
}

void main() {
  group('VramEstimatorManager', () {
    late VramEstimatorManager manager;

    setUp(() {
      manager = VramEstimatorManager();
    });

    test('serialize/deserialize round-trips losslessly via msgpack', () async {
      final original = _buildFixtureState();
      final bytes = await manager.serialize(original);
      final loaded = await manager.deserialize(bytes);
      _assertRoundTripped(original, loaded);
    });

    test(
      'exportAsJson writes pretty-printed JSON matching toMap(state)',
      () async {
        final original = _buildFixtureState();
        final tmp = await Directory.systemTemp.createTemp(
          'vram_export_test_',
        );
        try {
          final target = File(p.join(tmp.path, 'export.json'));
          await manager.exportAsJson(original, target);

          expect(await target.exists(), isTrue);
          final text = await target.readAsString();
          // Pretty-printed: JsonEncoder.withIndent('  ') emits newlines.
          expect(text, contains('\n'));

          final decoded = jsonDecode(text) as Map<String, dynamic>;
          // Decoded JSON should be structurally equal to toMap(state).
          final expected = manager.toMap(original);
          expect(decoded, equals(expected));
        } finally {
          if (await tmp.exists()) await tmp.delete(recursive: true);
        }
      },
    );

    test('cleanup deletes legacy JSON cache and backup via read()', () async {
      // Seed a tmp dir that stands in for the real cache dir by overriding
      // the manager's folder path.
      final tmp = await Directory.systemTemp.createTemp('vram_legacy_test_');
      try {
        final legacyJson = File(
          p.join(tmp.path, 'TriOS-VRAM_CheckerCache.json'),
        );
        final legacyBackup = File(
          p.join(tmp.path, 'TriOS-VRAM_CheckerCache.json_backup.bak'),
        );
        await legacyJson.writeAsString('{"modVramInfo":{},"lastUpdated":null}');
        await legacyBackup.writeAsString('stale');

        final m = _VramEstimatorManagerWithDir(tmp);

        // read() calls getConfigDataFolderPath() which performs the cleanup.
        await m.read(VramEstimatorManagerState.initial());

        expect(await legacyJson.exists(), isFalse);
        expect(await legacyBackup.exists(), isFalse);
        // A fresh per-selector .mp file was written on the default-state
        // fallback path.
        final mpFile = File(
          p.join(tmp.path, 'TriOS-VRAM_CheckerCache-folder-scan.mp'),
        );
        expect(await mpFile.exists(), isTrue);
      } finally {
        if (await tmp.exists()) await tmp.delete(recursive: true);
      }
    });

    test(
      'legacy single-file .mp is migrated to the active selector\'s file',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'vram_legacy_mp_test_',
        );
        try {
          // Produce a valid legacy payload by serializing via a fresh
          // manager (which still writes in the per-selector format today
          // — but the file contents are format-agnostic to this test, we
          // just need something msgpack-decodable).
          final original = _buildFixtureState();
          final bytes = await VramEstimatorManager().serialize(original);

          final legacyMp = File(p.join(tmp.path, 'TriOS-VRAM_CheckerCache.mp'));
          await legacyMp.writeAsBytes(bytes);

          final m = _VramEstimatorManagerWithDir(tmp);
          final loaded = await m.read(VramEstimatorManagerState.initial());

          // Legacy file gone, per-selector file exists, contents preserved.
          expect(await legacyMp.exists(), isFalse);
          final migrated = File(
            p.join(tmp.path, 'TriOS-VRAM_CheckerCache-folder-scan.mp'),
          );
          expect(await migrated.exists(), isTrue);
          _assertRoundTripped(original, loaded);
        } finally {
          if (await tmp.exists()) await tmp.delete(recursive: true);
        }
      },
    );

    test(
      'setActiveSelector swaps which file is read/written independently',
      () async {
        final tmp = await Directory.systemTemp.createTemp(
          'vram_swap_test_',
        );
        try {
          // Seed two distinct payloads, one per selector, directly on disk.
          final folderScanPayload = _buildFixtureState();
          final referencedPayload = VramEstimatorManagerState(
            modVramInfo: const {},
            lastUpdated: DateTime.utc(2026, 1, 1, 0, 0, 0),
          );
          final serializer = VramEstimatorManager();
          await File(
            p.join(tmp.path, 'TriOS-VRAM_CheckerCache-folder-scan.mp'),
          ).writeAsBytes(await serializer.serialize(folderScanPayload));
          await File(
            p.join(tmp.path, 'TriOS-VRAM_CheckerCache-referenced.mp'),
          ).writeAsBytes(await serializer.serialize(referencedPayload));

          // Read folder-scan first.
          final m = _VramEstimatorManagerWithDir(tmp);
          final loaded1 = await m.read(VramEstimatorManagerState.initial());
          _assertRoundTripped(folderScanPayload, loaded1);

          // Swap to referenced; next read should come from the other file.
          m.setActiveSelector('referenced');
          final loaded2 = await m.read(
            VramEstimatorManagerState.initial(),
            forceLoadFromDisk: true,
          );
          expect(loaded2.modVramInfo, isEmpty);
          expect(loaded2.lastUpdated, DateTime.utc(2026, 1, 1, 0, 0, 0));

          // Swap back: folder-scan payload is preserved.
          m.setActiveSelector('folder-scan');
          final loaded3 = await m.read(
            VramEstimatorManagerState.initial(),
            forceLoadFromDisk: true,
          );
          _assertRoundTripped(folderScanPayload, loaded3);
        } finally {
          if (await tmp.exists()) await tmp.delete(recursive: true);
        }
      },
    );
  });
}

class _VramEstimatorManagerWithDir extends VramEstimatorManager {
  _VramEstimatorManagerWithDir(this._dir);
  final Directory _dir;

  @override
  Future<Directory> getConfigDataFolderPath() async {
    await cleanupLegacyCachesOnce(_dir);
    return _dir;
  }
}
