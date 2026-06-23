import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:trios/sector_map/models/sector.dart';

/// World(hyperspace) <-> screen mapping. Y is flipped so positive-y is up,
/// matching the in-game map orientation.
class SectorViewTransform {
  final Offset offset;
  final double scale;

  const SectorViewTransform(this.offset, this.scale);

  Offset worldToScreen(Offset w) =>
      Offset(w.dx * scale + offset.dx, -w.dy * scale + offset.dy);

  Offset screenToWorld(Offset s) =>
      Offset((s.dx - offset.dx) / scale, -(s.dy - offset.dy) / scale);
}

class SectorMapPainter extends CustomPainter {
  final List<SectorSystem> systems;
  final List<SectorConstellation> constellations;
  final Map<String, Color> factionColors;
  final SectorViewTransform transform;
  final Color Function(String factionId) colorFor;
  final Set<String> hiddenFactionIds;
  final String? selectedSystemId;
  final String? hoveredSystemId;
  final Offset? playerLocation;
  final Color accentColor;
  final Color labelColor;
  final Color hullColor;

  SectorMapPainter({
    required this.systems,
    required this.constellations,
    required this.factionColors,
    required this.transform,
    required this.colorFor,
    required this.hiddenFactionIds,
    required this.selectedSystemId,
    required this.hoveredSystemId,
    required this.playerLocation,
    required this.accentColor,
    required this.labelColor,
    required this.hullColor,
  });

  static const Color _defaultStar = Color(0xFFBFD3FF);

  @override
  void paint(Canvas canvas, Size size) {
    _paintHulls(canvas);

    final showLabels = transform.scale > 0.012;
    for (final s in systems) {
      _paintSystem(canvas, s, showLabels);
    }

    if (playerLocation != null) {
      _paintPlayer(canvas, transform.worldToScreen(playerLocation!));
    }
  }

  bool _isDimmed(SectorSystem s) {
    if (hiddenFactionIds.isEmpty) return false;
    // uninhabited systems carry no faction — never dimmed by the faction filter
    if (s.markets.isEmpty) return false;
    // dim only if every market's faction is hidden
    return s.markets.every((m) => hiddenFactionIds.contains(m.factionId));
  }

  void _paintHulls(Canvas canvas) {
    final byCon = <String, List<Offset>>{};
    final conCentroid = <String, Offset>{};
    for (final s in systems) {
      final id = s.constellationId;
      if (id == null) continue;
      (byCon[id] ??= []).add(transform.worldToScreen(s.position));
    }

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = hullColor.withValues(alpha: 0.06);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = hullColor.withValues(alpha: 0.18);

    byCon.forEach((id, pts) {
      if (pts.length < 3) {
        if (pts.isNotEmpty) {
          conCentroid[id] = pts.reduce((a, b) => a + b) / pts.length.toDouble();
        }
        return;
      }
      final hull = convexHull(pts);
      final path = Path()..addPolygon(hull, true);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
      conCentroid[id] = pts.reduce((a, b) => a + b) / pts.length.toDouble();
    });

    // constellation labels
    for (final con in constellations) {
      final c = conCentroid[con.id];
      if (c == null) continue;
      _drawLabel(
        canvas,
        con.name,
        c,
        hullColor.withValues(alpha: 0.5),
        fontSize: 11,
        center: true,
      );
    }
  }

  void _paintSystem(Canvas canvas, SectorSystem s, bool showLabels) {
    final center = transform.worldToScreen(s.position);
    final dimmed = _isDimmed(s);
    final alpha = dimmed ? 0.25 : 1.0;

    final coreRadius = s.isInhabited ? 3.0 : 2.5;
    final starColor = (s.starColorValue ?? _defaultStar).withValues(
      alpha: alpha,
    );

    // star glyph
    if (s.isInhabited) {
      canvas.drawCircle(center, coreRadius, Paint()..color = starColor);
    } else {
      // hollow grey-ish glyph for uninhabited
      canvas.drawCircle(
        center,
        coreRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = starColor.withValues(alpha: alpha * 0.8),
      );
    }

    // faction pie ring
    if (s.isInhabited) {
      _paintPieRing(canvas, s, center, coreRadius + 3.0, alpha);
    }

    // selection / hover highlight
    final isSelected = s.id == selectedSystemId;
    final isHovered = s.id == hoveredSystemId;
    if (isSelected || isHovered) {
      canvas.drawCircle(
        center,
        coreRadius + 7.0,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.0 : 1.2
          ..color = accentColor.withValues(alpha: isSelected ? 0.9 : 0.6),
      );
    }

    if ((showLabels && !dimmed) || isSelected || isHovered) {
      _drawLabel(
        canvas,
        s.name,
        center + Offset(coreRadius + 8, -7),
        labelColor.withValues(alpha: isSelected || isHovered ? 1.0 : 0.7),
        fontSize: 11,
      );
    }
  }

  void _paintPieRing(
    Canvas canvas,
    SectorSystem s,
    Offset center,
    double radius,
    double alpha,
  ) {
    final total = s.totalMarketSize;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (total <= 0) {
      // markets exist but all size 0 — draw a thin neutral ring
      canvas.drawCircle(
        center,
        radius,
        paint..color = colorFor(s.markets.first.factionId).withValues(
          alpha: alpha,
        ),
      );
      return;
    }

    double start = -math.pi / 2; // start at top
    for (final m in s.markets) {
      final w = (m.size < 0 ? 0 : m.size) / total;
      if (w <= 0) continue;
      final sweep = w * 2 * math.pi;
      paint.color = colorFor(m.factionId).withValues(alpha: alpha);
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  void _paintPlayer(Canvas canvas, Offset center) {
    // a small upward chevron "you are here"
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - 9)
      ..lineTo(center.dx - 6, center.dy + 5)
      ..lineTo(center.dx + 6, center.dy + 5)
      ..close();
    canvas.drawShadow(path, Colors.black, 2, false);
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      center,
      2.0,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset at,
    Color color, {
    double fontSize = 11,
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pos = center ? at - Offset(tp.width / 2, tp.height / 2) : at;
    tp.paint(canvas, pos);
  }

  /// Andrew's monotone chain convex hull.
  static List<Offset> convexHull(List<Offset> points) {
    final pts = [...points]..sort(
      (a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy),
    );
    if (pts.length < 3) return pts;
    double cross(Offset o, Offset a, Offset b) =>
        (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

    final lower = <Offset>[];
    for (final p in pts) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }
    final upper = <Offset>[];
    for (final p in pts.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }
    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
  }

  @override
  bool shouldRepaint(covariant SectorMapPainter old) =>
      old.systems != systems ||
      old.transform.offset != transform.offset ||
      old.transform.scale != transform.scale ||
      old.selectedSystemId != selectedSystemId ||
      old.hoveredSystemId != hoveredSystemId ||
      old.hiddenFactionIds != hiddenFactionIds ||
      old.factionColors != factionColors;
}
