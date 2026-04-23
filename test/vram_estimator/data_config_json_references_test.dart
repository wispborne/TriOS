import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/references/data_config_json_references.dart';

import '_helpers.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('vram_data_config_json_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('custom_entities.json: extracts icon and interactionImage, ignores '
      'pluginClass and tags', () async {
    final fx = buildModFixture(tmp, {
      'data/config/custom_entities.json': '''
        {
          # Starsector-style hash comments
          "rat_abyss_fracture": {
            "icon": "graphics/icons/icon_portal.png",
            "interactionImage": "graphics/illustrations/comm_relay.jpg",
            "pluginClass": "assortment_of_things.abyss.entities.hyper.AbyssalFracture",
            "tags": ["non_clickable", "has_interaction_dialog"]
          }
        }
      ''',
    });
    final refs = await DataConfigJsonReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/icons/icon_portal.png'));
    expect(refs, contains('graphics/illustrations/comm_relay.jpg'));
    expect(
      refs,
      isNot(contains(
          'assortment_of_things.abyss.entities.hyper.abyssalfracture')),
    );
    expect(refs, isNot(contains('non_clickable')));
    expect(refs, isNot(contains('has_interaction_dialog')));
  });

  test('planets.json: extracts texture, icon, starCoronaSprite', () async {
    final fx = buildModFixture(tmp, {
      'data/config/planets.json': '''
        {
          "rat_abyss_hyperspace_icon": {
            "name": "fracture",
            "texture": "graphics/planets/star_white.jpg",
            "icon": "graphics/icons/intel/rat_map_icon.png",
            "starCoronaSprite": "graphics/fx/star_halo.png"
          }
        }
      ''',
    });
    final refs = await DataConfigJsonReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/planets/star_white.jpg'));
    expect(refs, contains('graphics/icons/intel/rat_map_icon.png'));
    expect(refs, contains('graphics/fx/star_halo.png'));
    // "fracture" is not path-shaped — must not appear.
    expect(refs, isNot(contains('fracture')));
  });

  test('engine_styles.json: extracts glowSprite and glowOutline', () async {
    final fx = buildModFixture(tmp, {
      'data/config/engine_styles.json': '''
        {
          "ABYSSAL": {
            "mode": "QUAD_STRIP",
            "type": "GLOW",
            "glowSprite": "graphics/fx/rat_abyssal_glow.png",
            "glowOutline": "graphics/fx/rat_abyssal_flame.png"
          }
        }
      ''',
    });
    final refs = await DataConfigJsonReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/fx/rat_abyssal_glow.png'));
    expect(refs, contains('graphics/fx/rat_abyssal_flame.png'));
    expect(refs, isNot(contains('quad_strip')));
    expect(refs, isNot(contains('glow')));
  });

  test('hull_styles.json: extracts damageDecalSheet and damageDecalGlowSheet',
      () async {
    final fx = buildModFixture(tmp, {
      'data/config/hull_styles.json': '''
        {
          "ABYSSAL": {
            "damageDecalSheet": "graphics/damage/damage_decal_sheet_base.png",
            "damageDecalGlowSheet": "graphics/damage/damage_decal_sheet_glow.png",
            "engineLoopSet": "engine_loop"
          }
        }
      ''',
    });
    final refs = await DataConfigJsonReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/damage/damage_decal_sheet_base.png'));
    expect(refs, contains('graphics/damage/damage_decal_sheet_glow.png'));
    expect(refs, isNot(contains('engine_loop')));
  });

  test('malformed JSON with trailing comma: regex fallback still extracts '
      'paths', () async {
    final fx = buildModFixture(tmp, {
      // Trailing comma after last entry — strict json.decode rejects this.
      'data/config/custom_entities.json': '''
        {
          "entry": {
            "icon": "graphics/icons/fallback.png",
            "sprite": "graphics/fx/fallback_sprite.png",
          }
        }
      ''',
    });
    final refs = await DataConfigJsonReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/icons/fallback.png'));
    expect(refs, contains('graphics/fx/fallback_sprite.png'));
  });

  test('scans settings.json for path-shaped strings outside graphics', () async {
    // The dedicated SettingsGraphicsReferences parser only covers the
    // `graphics` block; this parser must pick up terrain / campaign /
    // etc. paths that live at other keys in settings.json.
    final fx = buildModFixture(tmp, {
      'data/config/settings.json': '''
        {
          "graphics": {
            "ui": { "logo": "graphics/ui/handled_by_other_parser.png" }
          },
          "terrain": {
            "rat_depths": { "texture": "graphics/terrain/rat_depths1.png" }
          }
        }
      ''',
    });
    final refs = await DataConfigJsonReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/terrain/rat_depths1.png'));
  });

  test('processes nested subdirectory files', () async {
    final fx = buildModFixture(tmp, {
      'data/config/exerelinFactionConfig/rat_exotech.json': '''
        {
          "logo": "graphics/factions/exotech_logo.png"
        }
      ''',
    });
    final refs = await DataConfigJsonReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/factions/exotech_logo.png'));
  });

  test('ignores files outside data/config/', () async {
    final fx = buildModFixture(tmp, {
      'data/world/foo.json': '{"image": "graphics/foo.png"}',
      'data/hulls/bar.json': '{"sprite": "graphics/bar.png"}',
    });
    final refs = await DataConfigJsonReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, isEmpty);
  });

  test('paths are normalized (lowercase, forward slashes)', () async {
    final fx = buildModFixture(tmp, {
      'data/config/custom_entities.json': r'''
        {
          "e": {
            "icon": "GRAPHICS\\Icons\\MixedCase.PNG"
          }
        }
      ''',
    });
    final refs = await DataConfigJsonReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/icons/mixedcase.png'));
  });

  test('extension-less graphics/ strings expand to extension candidates',
      () async {
    final fx = buildModFixture(tmp, {
      'data/config/custom_entities.json': '''
        {
          "e": { "spriteStem": "graphics/icons/no_ext" }
        }
      ''',
    });
    final refs = await DataConfigJsonReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    // PathNormalizer.expand emits the bare form + each image-ext candidate.
    expect(refs, contains('graphics/icons/no_ext'));
    expect(refs, contains('graphics/icons/no_ext.png'));
    expect(refs, contains('graphics/icons/no_ext.jpg'));
    expect(refs, contains('graphics/icons/no_ext.jpeg'));
    expect(refs, contains('graphics/icons/no_ext.gif'));
    expect(refs, contains('graphics/icons/no_ext.webp'));
  });

  test('non-graphics image extensions are still picked up', () async {
    // Any path ending in .png etc. qualifies even without the graphics/ prefix.
    final fx = buildModFixture(tmp, {
      'data/config/modSettings.json': '''
        {
          "logo": "ui/decorations/border.png"
        }
      ''',
    });
    final refs = await DataConfigJsonReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('ui/decorations/border.png'));
  });

  test('ignores non-path-shaped strings without extension or graphics/ prefix',
      () async {
    final fx = buildModFixture(tmp, {
      'data/config/custom_entities.json': '''
        {
          "defaultName": "Warning Beacon",
          "customDescriptionId": "rat_abyss_warning_beacon",
          "pluginClass": "com.example.plugin.MyPlugin"
        }
      ''',
    });
    final refs = await DataConfigJsonReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, isEmpty);
  });
}
