import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:trios/utils/game_file_resolver.dart';

/// A source that ships the given `graphics/` paths.
GameFileSource source(String folder, List<String> files) => GameFileSource(
  folderPath: folder,
  imageFiles: {for (final file in files) file.toLowerCase(): file},
);

/// The same path the resolver builds, for comparing without worrying about
/// which slash the platform uses.
String joined(String folder, String relative) =>
    p.normalize(p.join(folder, relative));

void main() {
  const sprite = 'graphics/weapons/autopulse_turret_base.png';

  test('a mod beats the game core', () {
    final resolver = GameFileResolver([
      source(p.join('C:', 'mods', 'art_pack'), [sprite]),
      source(p.join('C:', 'game'), [sprite]),
    ]);

    expect(
      resolver.resolve(sprite),
      joined(p.join('C:', 'mods', 'art_pack'), sprite),
    );
  });

  test('the game core answers when no mod has the file', () {
    final resolver = GameFileResolver([
      source(p.join('C:', 'mods', 'sound_tweak'), const []),
      source(p.join('C:', 'game'), [sprite]),
    ]);

    expect(resolver.resolve(sprite), joined(p.join('C:', 'game'), sprite));
  });

  test('the first mod in load order wins', () {
    final resolver = GameFileResolver([
      source(p.join('C:', 'mods', 'a_mod'), [sprite]),
      source(p.join('C:', 'mods', 'b_mod'), [sprite]),
      source(p.join('C:', 'game'), [sprite]),
    ]);

    expect(
      resolver.resolve(sprite),
      joined(p.join('C:', 'mods', 'a_mod'), sprite),
    );
  });

  test('a file no source has resolves to null', () {
    final resolver = GameFileResolver([
      source(p.join('C:', 'game'), [sprite]),
    ]);

    expect(resolver.resolve('graphics/weapons/does_not_exist.png'), isNull);
  });

  test('a blank or missing path resolves to null', () {
    final resolver = GameFileResolver([
      source(p.join('C:', 'game'), [sprite]),
    ]);

    expect(resolver.resolve(null), isNull);
    expect(resolver.resolve('   '), isNull);
  });

  test('lookups ignore case and slash direction', () {
    final resolver = GameFileResolver([
      source(p.join('C:', 'game'), [sprite]),
    ]);

    expect(
      resolver.resolve(r'GRAPHICS\Weapons\Autopulse_Turret_Base.PNG'),
      joined(p.join('C:', 'game'), sprite),
    );
  });

  test('the on-disk spelling is kept, not the lowercased lookup key', () {
    final resolver = GameFileResolver([
      source(p.join('C:', 'game'), ['graphics/ships/Onslaught.png']),
    ]);

    expect(
      resolver.resolve('graphics/ships/onslaught.png'),
      joined(p.join('C:', 'game'), 'graphics/ships/Onslaught.png'),
    );
  });

  group('paths outside graphics/', () {
    late Directory tempRoot;

    setUp(() => tempRoot = Directory.systemTemp.createTempSync('resolver_test'));
    tearDown(() => tempRoot.deleteSync(recursive: true));

    test('fall back to checking the disk, in load order', () {
      final modFolder = Directory(p.join(tempRoot.path, 'mod'))
        ..createSync(recursive: true);
      final coreFolder = Directory(p.join(tempRoot.path, 'core'))
        ..createSync(recursive: true);

      for (final folder in [modFolder, coreFolder]) {
        Directory(p.join(folder.path, 'data', 'ui')).createSync(recursive: true);
      }
      File(p.join(coreFolder.path, 'data', 'ui', 'icon.png')).writeAsStringSync(
        '',
      );

      final resolver = GameFileResolver([
        source(modFolder.path, const []),
        source(coreFolder.path, const []),
      ]);

      expect(
        resolver.resolve('data/ui/icon.png'),
        joined(coreFolder.path, 'data/ui/icon.png'),
      );
      expect(resolver.resolve('data/ui/missing.png'), isNull);
    });
  });
}
