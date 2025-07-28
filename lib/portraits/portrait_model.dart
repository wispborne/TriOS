import 'dart:io';
import 'dart:typed_data';

import 'package:hashlib/hashlib.dart';

/// Represents a portrait image found in a mod
class Portrait {
  final String? smolId;
  final File imageFile;
  final int width;
  final int height;
  String hash;

  Portrait(
    this.smolId,
    this.imageFile,
    this.width,
    this.height,
    Uint8List imageBytes,
  ) : hash = crc64.convert(imageBytes).toString();

  @override
  String toString() {
    return 'Portrait{smolId: $smolId, path: ${imageFile.path}, size: ${width}x$height, hash: $hash}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Portrait &&
          runtimeType == other.runtimeType &&
          hash == other.hash;

  @override
  int get hashCode => hash.hashCode;
}
