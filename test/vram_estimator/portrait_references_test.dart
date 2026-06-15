import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/references/portrait_references.dart';

import '_helpers.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('vram_portrait_refs_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('extracts portrait paths from portraits.csv', () async {
    final fx = buildModFixture(tmp, {
      'data/characters/portraits/portraits.csv':
          'id,image\nfoo,graphics/portraits/foo.png\nbar,graphics/portraits/bar.png\n',
    });
    final refs = await PortraitReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/portraits/foo.png'));
    expect(refs, contains('graphics/portraits/bar.png'));
  });

  test('ignores non-path cells', () async {
    final fx = buildModFixture(tmp, {
      'data/characters/portraits/portraits.csv':
          'id,name,image\nfoo,Foo Name,graphics/portraits/foo.png\n',
    });
    final refs = await PortraitReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs.keys, contains('graphics/portraits/foo.png'));
    // Plain text cells without slashes should not leak into refs.
    expect(refs.keys.any((r) => r.contains('foo name')), isFalse);
  });

  test('ignores csv files at other locations', () async {
    final fx = buildModFixture(tmp, {
      'data/characters/portraits.csv': 'id,image\nx,graphics/nope.png',
    });
    final refs = await PortraitReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, isEmpty);
  });
}
