import 'dart:math';
import 'dart:ui';

/// Converts a flat [bounds] list (x,y pairs in Starsector coords, relative to
/// ship center, y-up) into screen-coordinate [Offset] vertices.
///
/// [centerScreenX] / [centerScreenY] is the ship center in screen coords
/// (y-down). [rotationRad] applies an additional rotation (e.g. for modules
/// docked at an angle); use 0 for the parent ship.
List<Offset> parseBoundsToPolygon(
  List<double> bounds,
  double centerScreenX,
  double centerScreenY, [
  double rotationRad = 0,
]) {
  final count = bounds.length ~/ 2;
  if (count < 3) return const [];

  final cosR = cos(rotationRad);
  final sinR = sin(rotationRad);
  final vertices = <Offset>[];

  for (var i = 0; i < count; i++) {
    // Starsector bounds use the same rotated axes as weapon slot locations:
    //   [0] = forward (up on sprite), [1] = left on sprite.
    // Convert to screen-local coords (x-right, y-down) with a 90° CCW rotation.
    final localX = -bounds[i * 2 + 1];
    final localY = -bounds[i * 2];

    // Apply additional rotation (for modules), then translate to screen center.
    final rx = localX * cosR - localY * sinR;
    final ry = localX * sinR + localY * cosR;
    vertices.add(Offset(centerScreenX + rx, centerScreenY + ry));
  }

  return vertices;
}

/// Ray-casting point-in-polygon test.
bool polygonContainsPoint(List<Offset> polygon, Offset point) {
  if (polygon.length < 3) return false;

  var inside = false;
  final n = polygon.length;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final yi = polygon[i].dy;
    final yj = polygon[j].dy;
    if ((yi > point.dy) != (yj > point.dy) &&
        point.dx <
            (polygon[j].dx - polygon[i].dx) *
                    (point.dy - yi) /
                    (yj - yi) +
                polygon[i].dx) {
      inside = !inside;
    }
  }
  return inside;
}
