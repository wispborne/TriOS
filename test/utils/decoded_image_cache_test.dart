import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/decoded_image_cache.dart';

void main() {
  test('clear makes a changed image path decode again', () async {
    var decodeCount = 0;
    final cache = DecodedImageCache(
      budgetBytes: 1024,
      decode: (path) async {
        decodeCount++;
        return null;
      },
    );

    await cache.load('shield.png');
    await cache.load('shield.png');
    expect(decodeCount, 1);

    cache.clear();
    await cache.load('shield.png');
    expect(decodeCount, 2);
  });
}
