import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Resizes an image to fit within a box without allowing either decoded
/// dimension to round down to zero.
class SafeResizeImage extends ImageProvider<SafeResizeImageKey> {
  final ImageProvider<Object> imageProvider;
  final int maxWidth;
  final int maxHeight;

  const SafeResizeImage(
    this.imageProvider, {
    required this.maxWidth,
    required this.maxHeight,
  }) : assert(maxWidth > 0),
       assert(maxHeight > 0);

  @override
  Future<SafeResizeImageKey> obtainKey(ImageConfiguration configuration) async {
    return SafeResizeImageKey(
      imageProvider: imageProvider,
      providerKey: await imageProvider.obtainKey(configuration),
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  @override
  ImageStreamCompleter loadImage(
    SafeResizeImageKey key,
    ImageDecoderCallback decode,
  ) {
    Future<ui.Codec> decodeAtSafeSize(
      ui.ImmutableBuffer buffer, {
      ui.TargetImageSizeCallback? getTargetSize,
    }) {
      assert(
        getTargetSize == null,
        'SafeResizeImage cannot wrap another provider that changes the decode size.',
      );
      return decode(
        buffer,
        getTargetSize: (intrinsicWidth, intrinsicHeight) =>
            calculateSafeImageSize(
              intrinsicWidth: intrinsicWidth,
              intrinsicHeight: intrinsicHeight,
              maxWidth: key.maxWidth,
              maxHeight: key.maxHeight,
            ),
      );
    }

    // ImageProvider marks this method as protected, but provider wrappers need
    // to pass their adjusted decoder to the wrapped provider.
    // ignore: invalid_use_of_protected_member
    return key.imageProvider.loadImage(key.providerKey, decodeAtSafeSize);
  }
}

ui.TargetImageSize calculateSafeImageSize({
  required int intrinsicWidth,
  required int intrinsicHeight,
  required int maxWidth,
  required int maxHeight,
}) {
  assert(intrinsicWidth > 0);
  assert(intrinsicHeight > 0);
  assert(maxWidth > 0);
  assert(maxHeight > 0);

  final widthScale = maxWidth / intrinsicWidth;
  final heightScale = maxHeight / intrinsicHeight;
  final scale = math.min(1.0, math.min(widthScale, heightScale));

  return ui.TargetImageSize(
    width: math.max(1, (intrinsicWidth * scale).floor()),
    height: math.max(1, (intrinsicHeight * scale).floor()),
  );
}

@immutable
class SafeResizeImageKey {
  final ImageProvider<Object> imageProvider;
  final Object providerKey;
  final int maxWidth;
  final int maxHeight;

  const SafeResizeImageKey({
    required this.imageProvider,
    required this.providerKey,
    required this.maxWidth,
    required this.maxHeight,
  });

  @override
  bool operator ==(Object other) {
    return other is SafeResizeImageKey &&
        other.providerKey == providerKey &&
        other.maxWidth == maxWidth &&
        other.maxHeight == maxHeight;
  }

  @override
  int get hashCode => Object.hash(providerKey, maxWidth, maxHeight);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'SafeResizeImageKey')}'
        '($providerKey, ${maxWidth}x$maxHeight)';
  }
}
