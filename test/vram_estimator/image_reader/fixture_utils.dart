import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:trios/vram_estimator/image_reader/png_chatgpt.dart';

typedef HeaderReader = Future<ImageHeader?> Function(String path);

/// Reads the file with both the new per-format reader and `package:image`,
/// then asserts the resulting (width, height, bitDepth, numChannels) tuples
/// are equal.
Future<void> expectParityWithImagePackage(
  File file,
  HeaderReader reader,
) async {
  final ours = await reader(file.path);
  expect(ours, isNotNull, reason: 'reader returned null for ${file.path}');
  final theirs = img.decodeNamedImage(file.path, await file.readAsBytes());
  expect(theirs, isNotNull,
      reason: 'package:image failed to decode ${file.path}');
  expect(ours!.width, theirs!.width, reason: 'width mismatch');
  expect(ours.height, theirs.height, reason: 'height mismatch');
  expect(ours.bitDepth, theirs.bitsPerChannel, reason: 'bitDepth mismatch');
  expect(ours.numChannels, theirs.numChannels,
      reason: 'numChannels mismatch');
}

/// Computes the same VRAM byte total `ModImageView.bytesUsed` would compute
/// for a non-background image with this header tuple. Used in tests where
/// strict tuple parity cannot hold but byte-equivalence must.
int vramBytesForTuple(ImageHeader h) {
  // multiplier for non-background images is 4/3.
  final raw =
      h.height * h.width * (h.bitDepth * h.numChannels / 8) * (4.0 / 3.0);
  return raw.ceil();
}

/// Asserts that the supplied async closure throws.
Future<void> expectThrows(Future<dynamic> Function() body) async {
  Object? caught;
  try {
    await body();
  } catch (e) {
    caught = e;
  }
  expect(caught, isNotNull, reason: 'expected the call to throw');
}
