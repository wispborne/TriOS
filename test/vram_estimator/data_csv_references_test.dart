import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/references/data_csv_references.dart';

import '_helpers.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('vram_data_csv_refs_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('picks up path-shaped cells from mod-defined data/ CSVs', () async {
    final fx = buildModFixture(tmp, {
      'data/campaign/frontiers/rat_frontiers_facilities.csv':
          'id,name,icon\n'
              'beacon,Gate Beacon,graphics/campaign/frontiers/gate_beacon.png\n',
    });
    final refs = await DataCsvReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(
      refs.keys,
      contains('graphics/campaign/frontiers/gate_beacon.png'),
    );
  });

  test('picks up extension-less graphics/ cells and expands to image exts',
      () async {
    final fx = buildModFixture(tmp, {
      'data/campaign/misc/entries.csv':
          'id,sprite\nfoo,graphics/campaign/misc/foo\n',
    });
    final refs = await DataCsvReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs.keys, contains('graphics/campaign/misc/foo'));
    expect(refs.keys, contains('graphics/campaign/misc/foo.png'));
  });

  test('ignores non-path cells (ids, display names, tag lists)', () async {
    final fx = buildModFixture(tmp, {
      'data/campaign/widgets/widgets.csv':
          'id,name,tags,description\n'
              'foo,Foo Widget,tag_a tag_b,A shiny widget.\n',
    });
    final refs = await DataCsvReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, isEmpty);
  });

  test('skips ship_data.csv, weapon_data.csv, and portraits.csv', () async {
    final fx = buildModFixture(tmp, {
      'data/hulls/ship_data.csv':
          'name,sprite name\nfoo,graphics/ships/foo.png\n',
      'data/weapons/weapon_data.csv':
          'name,turret sprite\nfoo,graphics/weapons/foo.png\n',
      'data/characters/portraits/portraits.csv':
          'id,image\nfoo,graphics/portraits/foo.png\n',
    });
    final refs = await DataCsvReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    // None of these should be emitted — dedicated parsers own them.
    expect(refs, isEmpty);
  });

  test('skips GraphicsLib manifest CSVs (id/type/map/path header)', () async {
    final fx = buildModFixture(tmp, {
      'data/config/modFilesLists/gfxlib.csv':
          'id,type,map,path\n'
              'foo,normal,normal,graphics/effects/foo_n.png\n',
    });
    final refs = await DataCsvReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    // graphicslib parser owns this; data-csv should stay out.
    expect(refs, isEmpty);
  });

  test('ignores csv files outside data/', () async {
    final fx = buildModFixture(tmp, {
      'loose.csv': 'id,image\nx,graphics/nope.png\n',
    });
    final refs = await DataCsvReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, isEmpty);
  });

  test('source attribution carries the exact CSV relative path', () async {
    final fx = buildModFixture(tmp, {
      'data/campaign/frontiers/rat_frontiers_facilities.csv':
          'id,icon\nbeacon,graphics/campaign/frontiers/gate_beacon.png\n',
    });
    final refs = await DataCsvReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    final sources = refs['graphics/campaign/frontiers/gate_beacon.png'];
    expect(sources, isNotNull);
    expect(
      sources,
      contains('data/campaign/frontiers/rat_frontiers_facilities.csv'),
    );
  });

  test('survives a malformed csv without crashing', () async {
    // Binary garbage that CsvToListConverter may or may not tolerate —
    // either way, the parser should not throw out of collect().
    File('${tmp.path}/data/campaign/broken.csv')
      ..createSync(recursive: true)
      ..writeAsBytesSync([0, 255, 0, 255, 10, 13]);
    final fx = buildModFixture(tmp, {});
    final refs = await DataCsvReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, isEmpty);
  });
}
