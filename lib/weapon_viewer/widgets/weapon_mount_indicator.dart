import 'dart:io';

import 'package:flutter/material.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';

import '../weapons_page.dart';

/// Displays a weapon sprite overlaid on the geometric mount-type indicator
/// shapes used in Starsector's weapon codex/tooltip.
///
/// The shapes encode slot compatibility:
///   Diamond = Ballistic, Square = Energy, Circle = Missile.
/// Hybrid types overlay the shapes of each compatible slot type.
/// Larger weapon sizes draw more concentric rings (1/2/3 for S/M/L).
class WeaponMountIndicator extends StatelessWidget {
  final Weapon weapon;
  final double size;

  const WeaponMountIndicator({super.key, required this.weapon, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Geometric shape background.
          CustomPaint(
            size: Size(size, size),
            painter: _MountShapePainter(
              weaponType: weapon.effectiveMountType?.toUpperCase() ?? '',
              weaponSize: weapon.size?.toUpperCase() ?? 'SMALL',
            ),
          ),
          // Weapon sprite on top.
          if (weapon.spritesForWeapon.firstOrNull != null)
            Transform.rotate(
              angle: 0.785,
              child: WeaponImageCell(imagePaths: weapon.spritesForWeapon, fit: .none,),
            ),
        ],
      ),
    );
  }
}

// ─────────────── Colors (from com.fs.starfarer.O0OO) ───────────────

const _mountColors = <String, Color>{
  'BALLISTIC': Color(0xFFFFD700),
  'ENERGY': Color(0xFF46C8FF),
  'MISSILE': Color(0xFF9BFF00),
  'DECORATIVE': Color(0xFFFFFFFF),
  'HYBRID': Color(0xFFFFA500),
  'SYNERGY': Color(0xFF00FFC8),
  'COMPOSITE': Color(0xFFD7FF00),
  'UNIVERSAL': Color(0xFFFFFFFF),
  'BUILT_IN': Color(0xFFFFFFFF),
  'SYSTEM': Color(0xFFFFFFFF),
};

// ─────────────── Painter ───────────────

class _MountShapePainter extends CustomPainter {
  final String weaponType;
  final String weaponSize;

  _MountShapePainter({required this.weaponType, required this.weaponSize});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final baseRadius = canvasSize.width / 2;
    const strokeWeight = 3.5;
    const baseAlpha = 0.5;

    final color = _mountColors[weaponType] ?? Colors.white;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    switch (weaponType) {
      case 'BALLISTIC':
        _drawLayered(
          canvas,
          baseRadius,
          strokeWeight,
          baseAlpha,
          color,
          _drawSquare,
        );
      case 'ENERGY':
        _drawLayered(
          canvas,
          baseRadius,
          strokeWeight,
          baseAlpha,
          color,
          _drawCircle,
        );
      case 'MISSILE':
        _drawLayered(
          canvas,
          baseRadius,
          strokeWeight,
          baseAlpha,
          color,
          _drawDiamond,
        );
      case 'DECORATIVE':
        // All three shapes overlaid.
        _drawComposite(canvas, baseRadius, strokeWeight, baseAlpha, color, [
          _drawSquare,
          _drawDiamond,
          _drawCircle,
        ], innerScale: 0.71);
      case 'HYBRID':
        // Energy (square) + Missile (circle) — fits Ballistic/Energy slots.
        _drawComposite(canvas, baseRadius, strokeWeight, baseAlpha, color, [
          _drawCircle,
          _drawSquare,
        ], innerScale: 0.71);
      case 'SYNERGY':
        // Energy (square) + Ballistic (diamond).
        _drawComposite(canvas, baseRadius, strokeWeight, baseAlpha, color, [
          _drawSquare,
          _drawDiamond,
        ], innerScale: 0.64);
      case 'COMPOSITE':
        // Ballistic (diamond) + Missile (circle) — same size.
        _drawComposite(canvas, baseRadius, strokeWeight, baseAlpha, color, [
          _drawDiamond,
          _drawCircle,
        ], innerScale: 1.0);
      case 'UNIVERSAL':
        // Single square at 70% alpha.
        final sizeData = _singleLayerSize;
        final paint = _makePaint(color, baseAlpha * 0.7, strokeWeight);
        _drawSquare(canvas, sizeData * baseRadius, paint);
    }

    canvas.restore();
  }

  // ── Layered drawing (1/2/3 concentric rings by size) ──

  void _drawLayered(
    Canvas canvas,
    double baseRadius,
    double strokeWeight,
    double baseAlpha,
    Color color,
    void Function(Canvas, double, Paint) drawFn,
  ) {
    final layers = _sizeLayers(baseRadius);
    for (final (radius, alphaFactor) in layers) {
      final paint = _makePaint(color, baseAlpha * alphaFactor, strokeWeight);
      drawFn(canvas, radius, paint);
    }
  }

  // ── Composite types (hybrid/synergy/composite/decorative) ──

  void _drawComposite(
    Canvas canvas,
    double baseRadius,
    double strokeWeight,
    double baseAlpha,
    Color color,
    List<void Function(Canvas, double, Paint)> drawFns, {
    double innerScale = 0.71,
  }) {
    final outerRadius = _singleLayerSize * baseRadius;
    final alpha = baseAlpha * 0.7;

    // First shape at full radius, remaining at inner scale.
    for (var i = 0; i < drawFns.length; i++) {
      final r = i == 0 ? outerRadius : outerRadius * innerScale;
      final paint = _makePaint(color, alpha, strokeWeight);
      drawFns[i](canvas, r, paint);
    }
  }

  // Returns (radius, alphaFactor) layers based on weapon size.
  List<(double, double)> _sizeLayers(double baseRadius) {
    return switch (weaponSize) {
      'LARGE' => [
        (baseRadius * 1.0, 1.0),
        (baseRadius * 0.75, 0.5),
        (baseRadius * 0.5, 0.25),
      ],
      'MEDIUM' => [(baseRadius * 0.75, 1.0), (baseRadius * 0.5, 0.5)],
      _ => [
        // SMALL
        (baseRadius * 0.5, 1.0),
      ],
    };
  }

  // Size factor for composite/universal single-layer shapes.
  double get _singleLayerSize => switch (weaponSize) {
    'LARGE' => 1.0,
    'MEDIUM' => 0.75,
    _ => 0.5,
  };

  // ── Shape primitives ──

  /// Diamond (rotated square) — represents Ballistic.
  static void _drawDiamond(Canvas canvas, double radius, Paint paint) {
    final path = Path()
      ..moveTo(-radius, 0)
      ..lineTo(0, radius)
      ..lineTo(radius, 0)
      ..lineTo(0, -radius)
      ..close();
    canvas.drawPath(path, paint);
  }

  /// Axis-aligned square — represents Energy.
  static void _drawSquare(Canvas canvas, double radius, Paint paint) {
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 2,
        height: radius * 2,
      ),
      paint,
    );
  }

  /// Circle — represents Missile.
  static void _drawCircle(Canvas canvas, double radius, Paint paint) {
    canvas.drawCircle(Offset.zero, radius, paint);
  }

  // ── Helpers ──

  static Paint _makePaint(Color color, double alpha, double strokeWidth) {
    return Paint()
      ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
  }

  @override
  bool shouldRepaint(_MountShapePainter oldDelegate) =>
      weaponType != oldDelegate.weaponType ||
      weaponSize != oldDelegate.weaponSize;
}
