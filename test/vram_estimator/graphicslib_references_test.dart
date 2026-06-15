import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/vram_estimator/models/graphics_lib_info.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/references/graphicslib_references.dart';

import '_helpers.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('vram_gfxlib_refs_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('GraphicsLibReferences.parse', () {
    test('parses normal/material/surface map rows from the CSV', () async {
      final fx = buildModFixture(tmp, {
        'data/config/maps.csv':
            'id,type,map,path\n'
            'foo_ship,spec,normal,graphics/ships/foo_normal.png\n'
            'foo_ship,spec,material,graphics/ships/foo_material.png\n'
            'foo_ship,spec,surface,graphics/ships/foo_surface.png\n'
            'foo_ship,spec,ignored,graphics/ships/foo_ignored.png\n',
      });
      final entries = await GraphicsLibReferences.parse(fx.mod, fx.files);
      expect(entries, hasLength(3));
      expect(
        entries.map((e) => e.mapType).toSet(),
        {MapType.Normal, MapType.Material, MapType.Surface},
      );
    });

    test('returns empty list when no CSV has the right header', () async {
      final fx = buildModFixture(tmp, {
        'data/something.csv': 'a,b,c\n1,2,3\n',
      });
      final entries = await GraphicsLibReferences.parse(fx.mod, fx.files);
      expect(entries, isEmpty);
    });
  });

  group('GraphicsLibReferences.mapTypeFor', () {
    test('returns CSV-declared type for matching file', () async {
      final fx = buildModFixture(tmp, {
        'data/config/maps.csv':
            'id,type,map,path\nfoo,spec,normal,graphics/ships/foo_normal.png\n',
        'graphics/ships/foo_normal.png': 'stub',
      });
      final entries = await GraphicsLibReferences.parse(fx.mod, fx.files);
      final normalFile = fx.files.firstWhere(
        (f) => f.relativePath.endsWith('foo_normal.png'),
      );
      expect(
        GraphicsLibReferences.mapTypeFor(fx.mod, normalFile, entries),
        MapType.Normal,
      );
    });

    test('GraphicsLib mod cache folder is always Normal', () async {
      tmp.deleteSync(recursive: true);
      tmp = Directory.systemTemp.createTempSync('vram_gfxlib_cache_test_');
      final fx = buildModFixture(tmp, {
        'cache/foo.png': 'stub',
      });
      // Build a mod whose id matches the GraphicsLib constant so the
      // cache-folder hardcode fires.
      final gfxMod = VramCheckerMod(
        ModInfo(id: Constants.graphicsLibId, name: 'GraphicsLib'),
        fx.mod.modFolder,
      );
      final cacheFile =
          fx.files.firstWhere((f) => f.relativePath.endsWith('foo.png'));
      expect(
        GraphicsLibReferences.mapTypeFor(gfxMod, cacheFile, const []),
        MapType.Normal,
      );
    });
  });
}
