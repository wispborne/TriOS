import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:trios/viewer_cache/cache_envelope.dart';
import 'package:trios/viewer_cache/cache_fingerprint.dart';
import 'package:trios/viewer_cache/parse_recorder.dart';

void main() {
  group('CacheEnvelope round-trip', () {
    final payload = Uint8List.fromList([1, 2, 3, 4]);

    test('with a fingerprint', () {
      final fingerprint = CacheFingerprint(
        directories: {
          'data/hulls': const RecordedDirectory(
            recursive: false,
            entryNames: ['atlas.ship', 'ship_data.csv', 'skins'],
          ),
          'data/variants': const RecordedDirectory(
            recursive: true,
            entryNames: ['atlas_Standard.variant'],
          ),
        },
        files: {'data/hulls/atlas.ship': 1754500000000},
      );
      final envelope = CacheEnvelope(
        schemaVersion: 4,
        smolId: 'test-1.0.0-abc',
        payload: payload,
        fingerprint: fingerprint,
      );

      final decoded = CacheEnvelope.tryDecode(envelope.encode());
      expect(decoded, isNotNull);
      expect(decoded!.payload, payload);
      final fp = decoded.fingerprint;
      expect(fp, isNotNull);
      expect(fp!.files, {'data/hulls/atlas.ship': 1754500000000});
      expect(fp.directories.keys, ['data/hulls', 'data/variants']);
      expect(fp.directories['data/hulls']!.recursive, false);
      expect(fp.directories['data/hulls']!.entryNames, [
        'atlas.ship',
        'ship_data.csv',
        'skins',
      ]);
      expect(fp.directories['data/variants']!.recursive, true);
    });

    test('without a fingerprint', () {
      final envelope = CacheEnvelope(
        schemaVersion: 4,
        smolId: 'test-1.0.0-abc',
        payload: payload,
      );
      final decoded = CacheEnvelope.tryDecode(envelope.encode());
      expect(decoded, isNotNull);
      expect(decoded!.payload, payload);
      expect(decoded.fingerprint, isNull);
    });

    test('a corrupt fingerprint does not take the payload down with it', () {
      final corruptValues = [
        42,
        'not a map',
        {'dirs': 'wrong type', 'files': {}},
        {
          'dirs': {
            'data/hulls': {'recursive': 'not a bool', 'entries': []},
          },
          'files': {},
        },
        {
          'dirs': {},
          'files': {'a.ship': 'not an int'},
        },
      ];
      for (final corrupt in corruptValues) {
        final bytes = msgpack.serialize({
          'v': 4,
          'smolId': 'test-1.0.0-abc',
          'payload': payload,
          'fingerprint': corrupt,
        });
        final decoded = CacheEnvelope.tryDecode(bytes);
        expect(decoded, isNotNull, reason: 'fingerprint was $corrupt');
        expect(decoded!.payload, payload);
        expect(decoded.fingerprint, isNull, reason: 'fingerprint was $corrupt');
      }
    });
  });

  group('ParseRecorder', () {
    late Directory sourceFolder;

    setUp(() {
      sourceFolder = Directory.systemTemp.createTempSync('trios_recorder_test');
    });

    tearDown(() {
      sourceFolder.deleteSync(recursive: true);
    });

    File makeFile(String relativePath) {
      final file = File('${sourceFolder.path}/$relativePath');
      file.createSync(recursive: true);
      return file;
    }

    test('stores relative forward-slash paths and sorted names', () {
      makeFile('data/hulls/beta.ship');
      makeFile('data/hulls/alpha.ship');
      final hullsDir = Directory('${sourceFolder.path}/data/hulls');

      final recorder = ParseRecorder(sourceFolder);
      recorder.directory(hullsDir, hullsDir.listSync());
      recorder.file(File('${hullsDir.path}/alpha.ship'));

      final fingerprint = recorder.build();
      expect(fingerprint, isNotNull);
      expect(fingerprint!.directories.keys, ['data/hulls']);
      expect(fingerprint.directories['data/hulls']!.entryNames, [
        'alpha.ship',
        'beta.ship',
      ]);
      expect(fingerprint.files.keys, ['data/hulls/alpha.ship']);
    });

    test('recursive listing stores nested paths relative to the listed dir',
        () {
      makeFile('data/hulls/skins/lowtech/atlas_lp.skin');
      makeFile('data/hulls/skins/atlas_pirate.skin');
      final skinsDir = Directory('${sourceFolder.path}/data/hulls/skins');

      final recorder = ParseRecorder(sourceFolder);
      recorder.directory(
        skinsDir,
        skinsDir.listSync(recursive: true),
        recursive: true,
      );

      final recorded = recorder.build()!.directories['data/hulls/skins']!;
      expect(recorded.recursive, true);
      expect(recorded.entryNames, [
        'atlas_pirate.skin',
        'lowtech',
        'lowtech/atlas_lp.skin',
      ]);
    });

    test('an absent folder is recorded with an empty list', () {
      final missingDir = Directory('${sourceFolder.path}/data/variants');
      final recorder = ParseRecorder(sourceFolder);
      recorder.directory(missingDir, const [], recursive: true);

      final fingerprint = recorder.build();
      expect(fingerprint!.directories['data/variants']!.entryNames, isEmpty);
    });

    test('build() is null when nothing was recorded', () {
      expect(ParseRecorder(sourceFolder).build(), isNull);
    });

    test('a file that vanished before recording is skipped', () {
      final gone = File('${sourceFolder.path}/gone.ship');
      final recorder = ParseRecorder(sourceFolder);
      recorder.file(gone);
      expect(recorder.build(), isNull);
    });
  });

  group('CacheFingerprint.isUnchanged', () {
    late Directory sourceFolder;

    setUp(() {
      sourceFolder = Directory.systemTemp.createTempSync(
        'trios_fingerprint_test',
      );
    });

    tearDown(() {
      if (sourceFolder.existsSync()) {
        sourceFolder.deleteSync(recursive: true);
      }
    });

    File makeFile(String relativePath) {
      final file = File('${sourceFolder.path}/$relativePath');
      file.createSync(recursive: true);
      return file;
    }

    /// Records the layout the way the ships parse would: one flat hulls
    /// listing, one recursive variants listing, every .ship file read.
    CacheFingerprint record() {
      final recorder = ParseRecorder(sourceFolder);
      final hullsDir = Directory('${sourceFolder.path}/data/hulls');
      if (hullsDir.existsSync()) {
        final entries = hullsDir.listSync();
        recorder.directory(hullsDir, entries);
        for (final file in entries.whereType<File>().where(
          (f) => f.path.endsWith('.ship'),
        )) {
          recorder.file(file);
        }
      } else {
        recorder.directory(hullsDir, const []);
      }
      final variantsDir = Directory('${sourceFolder.path}/data/variants');
      if (variantsDir.existsSync()) {
        recorder.directory(
          variantsDir,
          variantsDir.listSync(recursive: true),
          recursive: true,
        );
      } else {
        recorder.directory(variantsDir, const [], recursive: true);
      }
      return recorder.build()!;
    }

    test('nothing changed', () {
      makeFile('data/hulls/atlas.ship');
      makeFile('data/variants/atlas_Standard.variant');
      final fingerprint = record();
      expect(fingerprint.isUnchanged(sourceFolder), true);
    });

    test('an edited file (new modified time) is a change', () {
      final ship = makeFile('data/hulls/atlas.ship');
      final fingerprint = record();
      ship.setLastModifiedSync(
        ship.lastModifiedSync().add(const Duration(minutes: 5)),
      );
      expect(fingerprint.isUnchanged(sourceFolder), false);
    });

    test('an added file is a change', () {
      makeFile('data/hulls/atlas.ship');
      final fingerprint = record();
      makeFile('data/hulls/onslaught.ship');
      expect(fingerprint.isUnchanged(sourceFolder), false);
    });

    test('a file added in a nested subfolder of a recursive listing is a '
        'change', () {
      makeFile('data/variants/pirates/atlas_P.variant');
      final fingerprint = record();
      makeFile('data/variants/pirates/atlas_P2.variant');
      expect(fingerprint.isUnchanged(sourceFolder), false);
    });

    test('a removed file is a change', () {
      makeFile('data/hulls/atlas.ship');
      final extra = makeFile('data/hulls/readme.txt');
      final fingerprint = record();
      extra.deleteSync();
      expect(fingerprint.isUnchanged(sourceFolder), false);
    });

    test('a renamed file is a change', () {
      final ship = makeFile('data/hulls/atlas.ship');
      final fingerprint = record();
      ship.renameSync('${sourceFolder.path}/data/hulls/atlas2.ship');
      expect(fingerprint.isUnchanged(sourceFolder), false);
    });

    test('a deleted recorded file is a change', () {
      final ship = makeFile('data/hulls/atlas.ship');
      final fingerprint = record();
      ship.deleteSync();
      expect(fingerprint.isUnchanged(sourceFolder), false);
    });

    test('a folder recorded absent and still absent is unchanged', () {
      makeFile('data/hulls/atlas.ship');
      final fingerprint = record();
      expect(fingerprint.directories['data/variants']!.entryNames, isEmpty);
      expect(fingerprint.isUnchanged(sourceFolder), true);
    });

    test('a newly created folder with content is a change', () {
      makeFile('data/hulls/atlas.ship');
      final fingerprint = record();
      makeFile('data/variants/atlas_Standard.variant');
      expect(fingerprint.isUnchanged(sourceFolder), false);
    });

    test('a recorded flat listing ignores changes inside subfolders', () {
      // data/hulls is listed flat, so a file inside data/hulls/skins doesn't
      // change ITS listing — the skins folder has its own recorded entry when
      // the parse lists it. Here only hulls is recorded, so the nested change
      // passes unseen. This pins down that flat means flat.
      makeFile('data/hulls/atlas.ship');
      makeFile('data/hulls/skins/atlas_pirate.skin');
      final fingerprint = record();
      makeFile('data/hulls/skins/atlas_new.skin');
      expect(fingerprint.isUnchanged(sourceFolder), true);
    });
  });
}
