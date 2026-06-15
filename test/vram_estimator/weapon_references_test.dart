import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/references/weapon_references.dart';

import '_helpers.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('vram_weapon_refs_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('extracts known sprite keys from .wpn JSON', () async {
    final fx = buildModFixture(tmp, {
      'data/weapons/laser.wpn': '''
        {
          "turretSprite": "graphics/weapons/laser_turret.png",
          "hardpointSprite": "graphics/weapons/laser_hardpoint.png",
          "turretUnderSprite": "graphics/weapons/laser_turret_under.png"
        }
      ''',
    });
    final refs = await WeaponReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/weapons/laser_turret.png'));
    expect(refs, contains('graphics/weapons/laser_hardpoint.png'));
    expect(refs, contains('graphics/weapons/laser_turret_under.png'));
  });

  test('recursively walks nested JSON for sprite keys', () async {
    final fx = buildModFixture(tmp, {
      'data/weapons/nested.wpn': '''
        {
          "projectileSpec": {
            "glowSprite": "graphics/fx/glow.png",
            "sprite": "graphics/fx/shot.png"
          }
        }
      ''',
    });
    final refs = await WeaponReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/fx/glow.png'));
    expect(refs, contains('graphics/fx/shot.png'));
  });

  test('picks up array-valued sprite fields like turretChargeUpSprites',
      () async {
    // Beam and charge-up weapons store frames in arrays. The filter is
    // shape-based so it catches list elements as readily as scalars.
    final fx = buildModFixture(tmp, {
      'data/weapons/charged.wpn': '''
        {
          "turretChargeUpSprites": [
            "graphics/weapons/charge_00.png",
            "graphics/weapons/charge_01.png"
          ]
        }
      ''',
    });
    final refs = await WeaponReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/weapons/charge_00.png'));
    expect(refs, contains('graphics/weapons/charge_01.png'));
  });

  test('picks up unconventional sprite keys (e.g. beam core / fringe)',
      () async {
    // Beam weapons commonly cite their visuals via coreTexture /
    // fringeTexture, and mods add custom keys like `coreSprite` all the
    // time. A shape-based filter catches them without a maintenance
    // burden.
    final fx = buildModFixture(tmp, {
      'data/weapons/beam.wpn': '''
        {
          "coreTexture": "graphics/weapons/beam_core.png",
          "fringeTexture": "graphics/weapons/beam_fringe.png",
          "customGlow": "graphics/weapons/beam_glow.png"
        }
      ''',
    });
    final refs = await WeaponReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/weapons/beam_core.png'));
    expect(refs, contains('graphics/weapons/beam_fringe.png'));
    expect(refs, contains('graphics/weapons/beam_glow.png'));
  });

  test('does not leak non-path strings (engine classes, ids, enums)',
      () async {
    final fx = buildModFixture(tmp, {
      'data/weapons/noisy.wpn': '''
        {
          "id": "some_weapon_id",
          "specClass": "beam",
          "everyFrameEffect": "data.scripts.weapons.MyScript",
          "renderHints": ["RENDER_ADDITIVE"],
          "turretSprite": "graphics/weapons/ok.png"
        }
      ''',
    });
    final refs = await WeaponReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs.keys, contains('graphics/weapons/ok.png'));
    expect(refs.keys.any((r) => r.contains('some_weapon_id')), isFalse);
    expect(refs.keys.any((r) => r.contains('beam')), isFalse);
    expect(refs.keys.any((r) => r.contains('myscript')), isFalse);
    expect(refs.keys.any((r) => r.contains('render_additive')), isFalse);
  });

  test('parses .proj files', () async {
    final fx = buildModFixture(tmp, {
      'data/weapons/proj/missile.proj': '''
        {
          "spriteName": "graphics/projectiles/missile.png"
        }
      ''',
    });
    final refs = await WeaponReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/projectiles/missile.png'));
  });

  test('parses weapon_data.csv sprite columns', () async {
    final fx = buildModFixture(tmp, {
      'data/weapons/weapon_data.csv':
          'id,name,turret sprite,hardpoint sprite\n'
          'foo,Foo,graphics/weapons/foo_turret.png,graphics/weapons/foo_hardpoint.png\n',
    });
    final refs = await WeaponReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, contains('graphics/weapons/foo_turret.png'));
    expect(refs, contains('graphics/weapons/foo_hardpoint.png'));
  });

  test('ignores non-weapon-path files', () async {
    final fx = buildModFixture(tmp, {
      'graphics/stuff/other.wpn': '{"turretSprite": "graphics/nope.png"}',
    });
    final refs = await WeaponReferences().collect(
      fx.mod,
      fx.files,
      buildTestContext(),
    );
    expect(refs, isEmpty);
  });
}
