import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Load the pixel dimensions of an image file without fully decoding it.
///
/// Returns `null` if the file doesn't exist or can't be decoded.
/// The result is delivered asynchronously via [ui.instantiateImageCodec].
/// Compute the axis-aligned bounding box of a rectangle after rotation
/// around [origin] (relative to the rect's top-left).
Rect rotatedBounds(
  double left,
  double top,
  double w,
  double h,
  double angle,
  Offset origin,
) {
  final cosA = cos(angle);
  final sinA = sin(angle);
  final corners = [
    Offset(0, 0),
    Offset(w, 0),
    Offset(w, h),
    Offset(0, h),
  ];

  double minX = double.infinity, minY = double.infinity;
  double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

  for (final c in corners) {
    final dx = c.dx - origin.dx;
    final dy = c.dy - origin.dy;
    final rx = left + origin.dx + dx * cosA - dy * sinA;
    final ry = top + origin.dy + dx * sinA + dy * cosA;
    minX = min(minX, rx);
    minY = min(minY, ry);
    maxX = max(maxX, rx);
    maxY = max(maxY, ry);
  }

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

/// Read and decode an image file's first frame.
///
/// Returns `null` if the file is missing or can't be decoded.
Future<ui.Image?> decodeImageFile(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    return (await codec.getNextFrame()).image;
  } catch (_) {
    return null;
  }
}

Future<ui.Size?> loadImageSize(String? path) async {
  if (path == null) return null;
  final image = await decodeImageFile(path);
  if (image == null) return null;
  return ui.Size(image.width.toDouble(), image.height.toDouble());
}

/// Decoded-image cache for sprite overlays (e.g. built-in weapons on the
/// ship blueprint), keyed by file path. Never evicted; weapon sprites are
/// small and shared across ships.
final Map<String, Future<ui.Image?>> _decodedImageCache = {};

/// Load and decode an image file, cached by path.
///
/// Returns `null` if the file doesn't exist or can't be decoded.
Future<ui.Image?> loadDecodedImage(String path) {
  return _decodedImageCache.putIfAbsent(path, () => decodeImageFile(path));
}
