import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';

ModImageView _makeView({
  required int width,
  required int height,
  int bitsInAllChannelsSum = 32,
  ImageType imageType = ImageType.texture,
}) {
  final table = ModImageTable.fromRows([
    {
      'filePath': 'test.png',
      'textureHeight': height,
      'textureWidth': width,
      'bitsInAllChannelsSum': bitsInAllChannelsSum,
      'imageType': imageType.name,
    },
  ]);
  return ModImageView(0, table);
}

void main() {
  group('nextPowerOfTwo', () {
    test('1 rounds up to 2', () => expect(nextPowerOfTwo(1), 2));
    test('2 stays 2', () => expect(nextPowerOfTwo(2), 2));
    test('3 rounds to 4', () => expect(nextPowerOfTwo(3), 4));
    test('256 stays 256', () => expect(nextPowerOfTwo(256), 256));
    test('300 rounds to 512', () => expect(nextPowerOfTwo(300), 512));
    test('1024 stays 1024', () => expect(nextPowerOfTwo(1024), 1024));
    test('1025 rounds to 2048', () => expect(nextPowerOfTwo(1025), 2048));
  });

  group('mipmapChainBytes', () {
    test('128x128 square', () {
      expect(mipmapChainBytes(128, 128), 87380);
    });

    test('256x128 non-square', () {
      expect(mipmapChainBytes(256, 128), 174764);
    });
  });

  group('bytesUsed', () {
    test('JPEG (3-channel source) still uses 4 bytes/pixel', () {
      final view = _makeView(
        width: 256,
        height: 256,
        bitsInAllChannelsSum: 24,
      );
      expect(view.bytesUsed, mipmapChainBytes(256, 256));
    });

    test('palette PNG (8bpp source) still uses 4 bytes/pixel', () {
      final view = _makeView(
        width: 128,
        height: 128,
        bitsInAllChannelsSum: 8,
      );
      expect(view.bytesUsed, mipmapChainBytes(128, 128));
    });
  });

  group('mipmap threshold', () {
    test('1024x1024 gets mipmaps', () {
      final view = _makeView(width: 1024, height: 1024);
      expect(view.hasMipmaps, isTrue);
      expect(view.bytesUsed, mipmapChainBytes(1024, 1024));
    });

    test('2048x512 does not get mipmaps', () {
      final view = _makeView(width: 2048, height: 512);
      expect(view.hasMipmaps, isFalse);
      expect(view.bytesUsed, 2048 * 512 * 4);
    });

    test('512x512 gets mipmaps', () {
      final view = _makeView(width: 512, height: 512);
      expect(view.hasMipmaps, isTrue);
    });

    test('2048x256 does not get mipmaps', () {
      final view = _makeView(width: 2048, height: 256);
      expect(view.hasMipmaps, isFalse);
      expect(view.bytesUsed, 2048 * 256 * 4);
    });
  });
}
