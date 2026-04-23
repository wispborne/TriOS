import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/references/settings_graphics_references.dart';

import '_helpers.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('vram_settings_refs_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('extracts every string from the graphics block at any depth', () async {
    final fx = buildModFixture(tmp, {
      'data/config/settings.json': '''
        {
          "graphics": {
            "ui": {
              "logo": "graphics/ui/logo.png",
              "icon": "graphics/ui/icon.png"
            },
            "backgrounds": {
              "default": "graphics/backgrounds/default.png"
            },
            "flat_value": "graphics/flat.png"
          },
          "other_block": {
            "ignored": "graphics/ignored.png"
          }
        }
      ''',
    });
    final refs = await SettingsGraphicsReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/ui/logo.png'));
    expect(refs, contains('graphics/ui/icon.png'));
    expect(refs, contains('graphics/backgrounds/default.png'));
    expect(refs, contains('graphics/flat.png'));
    // Outside the graphics block — not collected.
    expect(refs, isNot(contains('graphics/ignored.png')));
  });

  test('ignores settings.json at other locations', () async {
    final fx = buildModFixture(tmp, {
      'settings.json': '{"graphics": {"x": "graphics/nope.png"}}',
    });
    final refs = await SettingsGraphicsReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, isEmpty);
  });

  test('handles JSON with comments', () async {
    final fx = buildModFixture(tmp, {
      'data/config/settings.json': '''
        {
          // Starsector tolerates comments; we should too.
          "graphics": {
            "x": "graphics/x.png"
          }
        }
      ''',
    });
    final refs = await SettingsGraphicsReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/x.png'));
  });
}
