import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/references/ship_references.dart';

import '_helpers.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('vram_ship_refs_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('parses spriteName from .ship JSON files', () async {
    final fx = buildModFixture(tmp, {
      'data/hulls/example.ship': '''
        {
          "hullName": "Example",
          "spriteName": "graphics/ships/example.png"
        }
      ''',
    });
    final refs = await ShipReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/ships/example.png'));
  });

  test('parses sprite name column from ship_data.csv', () async {
    final fx = buildModFixture(tmp, {
      'data/hulls/ship_data.csv':
          'id,name,sprite name\nfoo,Foo,graphics/ships/foo.png\nbar,Bar,graphics/ships/bar.png\n',
    });
    final refs = await ShipReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/ships/foo.png'));
    expect(refs, contains('graphics/ships/bar.png'));
  });

  test('ignores ship files outside data/hulls/', () async {
    final fx = buildModFixture(tmp, {
      'somewhere/else/rogue.ship': '{"spriteName": "graphics/rogue.png"}',
    });
    final refs = await ShipReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, isEmpty);
  });

  test('survives malformed JSON without crashing', () async {
    final fx = buildModFixture(tmp, {
      'data/hulls/broken.ship': '{ this is not json',
      'data/hulls/good.ship':
          '{"spriteName": "graphics/ships/good.png"}',
    });
    final logs = <String>[];
    final refs = await ShipReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(logLines: logs),
    );
    expect(refs, contains('graphics/ships/good.png'));
    expect(logs.any((l) => l.contains('broken.ship')), isTrue);
  });

  test('paths emit both with- and without-extension forms', () async {
    final fx = buildModFixture(tmp, {
      'data/hulls/no_ext.ship': '{"spriteName": "graphics/ships/noext"}',
    });
    final refs = await ShipReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/ships/noext'));
    expect(refs, contains('graphics/ships/noext.png'));
  });
}
