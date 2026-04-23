import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/selectors/path_normalizer.dart';

void main() {
  group('PathNormalizer.normalize', () {
    test('lowercases and forward-slashes', () {
      expect(
        PathNormalizer.normalize(r'Graphics\Ships\Foo.PNG'),
        'graphics/ships/foo.png',
      );
    });

    test('strips leading slashes', () {
      expect(PathNormalizer.normalize('/graphics/foo.png'), 'graphics/foo.png');
      expect(
        PathNormalizer.normalize('///graphics/foo.png'),
        'graphics/foo.png',
      );
    });

    test('trims whitespace', () {
      expect(
        PathNormalizer.normalize('  graphics/foo.png  '),
        'graphics/foo.png',
      );
    });

    test('empty input stays empty', () {
      expect(PathNormalizer.normalize(''), '');
      expect(PathNormalizer.normalize('   '), '');
    });
  });

  group('PathNormalizer.expand', () {
    test('with-extension paths pass through as single entry', () {
      final out = PathNormalizer.expand('graphics/ships/foo.png');
      expect(out, {'graphics/ships/foo.png'});
    });

    test('no-extension paths expand to every image extension', () {
      final out = PathNormalizer.expand('graphics/ships/foo');
      expect(out, contains('graphics/ships/foo'));
      expect(out, contains('graphics/ships/foo.png'));
      expect(out, contains('graphics/ships/foo.jpg'));
      expect(out, contains('graphics/ships/foo.jpeg'));
      expect(out, contains('graphics/ships/foo.gif'));
      expect(out, contains('graphics/ships/foo.webp'));
    });

    test('case and separator normalization happens before expansion', () {
      final out = PathNormalizer.expand(r'Graphics\Foo');
      expect(out, contains('graphics/foo'));
      expect(out, contains('graphics/foo.png'));
    });

    test('empty input yields empty set', () {
      expect(PathNormalizer.expand(''), isEmpty);
      expect(PathNormalizer.expand('   '), isEmpty);
    });
  });

  group('PathNormalizer.hasImageExtension', () {
    test('true for known image extensions', () {
      expect(PathNormalizer.hasImageExtension('foo.png'), isTrue);
      expect(PathNormalizer.hasImageExtension('foo.jpg'), isTrue);
      expect(PathNormalizer.hasImageExtension('foo.jpeg'), isTrue);
      expect(PathNormalizer.hasImageExtension('foo.gif'), isTrue);
      expect(PathNormalizer.hasImageExtension('foo.webp'), isTrue);
    });

    test('false for other extensions', () {
      expect(PathNormalizer.hasImageExtension('foo.txt'), isFalse);
      expect(PathNormalizer.hasImageExtension('foo.psd'), isFalse);
      expect(PathNormalizer.hasImageExtension('foo'), isFalse);
    });
  });
}
