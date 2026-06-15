import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/references/faction_references.dart';

import '_helpers.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('vram_faction_refs_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('extracts logo, crest, and portrait paths', () async {
    final fx = buildModFixture(tmp, {
      'data/world/factions/example.faction': '''
        {
          "logo": "graphics/factions/logo.png",
          "crest": "graphics/factions/crest.png",
          "portraits": {
            "standard_male": [
              "graphics/portraits/male1.png",
              "graphics/portraits/male2.png"
            ],
            "standard_female": [
              "graphics/portraits/female1.png"
            ]
          }
        }
      ''',
    });
    final refs = await FactionReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/factions/logo.png'));
    expect(refs, contains('graphics/factions/crest.png'));
    expect(refs, contains('graphics/portraits/male1.png'));
    expect(refs, contains('graphics/portraits/male2.png'));
    expect(refs, contains('graphics/portraits/female1.png'));
  });

  test('ignores .faction outside data/world/factions', () async {
    final fx = buildModFixture(tmp, {
      'somewhere/else/example.faction':
          '{"logo": "graphics/factions/logo.png"}',
    });
    final refs = await FactionReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, isEmpty);
  });

  test('handles JSON with // comments (SS convention)', () async {
    final fx = buildModFixture(tmp, {
      'data/world/factions/commented.faction': '''
        // leading comment
        {
          "logo": "graphics/factions/logo.png" // inline comment
        }
      ''',
    });
    final refs = await FactionReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/factions/logo.png'));
  });
}
