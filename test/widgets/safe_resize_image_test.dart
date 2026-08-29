import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:trios/widgets/safe_resize_image.dart';

void main() {
  testWidgets('very wide images keep a non-zero thumbnail height', (
    tester,
  ) async {
    final source = image.Image(width: 600, height: 2);
    final bytes = Uint8List.fromList(image.encodePng(source));
    final provider = SafeResizeImage(
      MemoryImage(bytes),
      maxWidth: 120,
      maxHeight: 120,
    );

    final imageInfo = await tester.runAsync(() => _resolve(provider));
    expect(imageInfo, isNotNull);
    addTearDown(imageInfo!.dispose);

    expect(imageInfo.image.width, 120);
    expect(imageInfo.image.height, 1);
  });

  test('preserves aspect ratio for ordinary thumbnails', () {
    final size = calculateSafeImageSize(
      intrinsicWidth: 600,
      intrinsicHeight: 300,
      maxWidth: 120,
      maxHeight: 120,
    );

    expect(size.width, 120);
    expect(size.height, 60);
  });

  test('very tall images keep a non-zero thumbnail width', () {
    final size = calculateSafeImageSize(
      intrinsicWidth: 2,
      intrinsicHeight: 600,
      maxWidth: 120,
      maxHeight: 120,
    );

    expect(size.width, 1);
    expect(size.height, 120);
  });

  test('does not upscale images that already fit', () {
    final size = calculateSafeImageSize(
      intrinsicWidth: 32,
      intrinsicHeight: 16,
      maxWidth: 120,
      maxHeight: 120,
    );

    expect(size.width, 32);
    expect(size.height, 16);
  });

  test('cache key includes the requested bounds', () async {
    final bytes = Uint8List.fromList(
      image.encodePng(image.Image(width: 2, height: 2)),
    );
    final source = MemoryImage(bytes);
    final smallKey = await SafeResizeImage(
      source,
      maxWidth: 60,
      maxHeight: 60,
    ).obtainKey(ImageConfiguration.empty);
    final largeKey = await SafeResizeImage(
      source,
      maxWidth: 120,
      maxHeight: 120,
    ).obtainKey(ImageConfiguration.empty);

    expect(smallKey, isNot(equals(largeKey)));
  });
}

Future<ImageInfo> _resolve(ImageProvider<Object> provider) {
  final completer = Completer<ImageInfo>();
  late final ImageStreamListener listener;
  final stream = provider.resolve(ImageConfiguration.empty);
  listener = ImageStreamListener((imageInfo, _) {
    stream.removeListener(listener);
    completer.complete(imageInfo);
  }, onError: completer.completeError);
  stream.addListener(listener);
  return completer.future;
}
