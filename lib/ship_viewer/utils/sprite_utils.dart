import 'dart:math';

import 'package:flutter/painting.dart';

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
