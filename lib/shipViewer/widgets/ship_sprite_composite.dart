import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/shipViewer/ship_module_resolver.dart';
import 'package:trios/shipViewer/utils/sprite_utils.dart';

/// Renders a ship sprite with module sprites overlaid at their correct
/// docking positions. Scales to fit within the given constraints.
///
/// Usable anywhere a ship sprite is displayed — grid thumbnails, detail
/// dialogs, tooltips, etc.
class ShipSpriteComposite extends StatefulWidget {
  final Ship ship;
  final List<ResolvedModule> modules;
  final BoxFit fit;

  const ShipSpriteComposite({
    super.key,
    required this.ship,
    this.modules = const [],
    this.fit = BoxFit.contain,
  });

  @override
  State<ShipSpriteComposite> createState() => _ShipSpriteCompositeState();
}

class _ShipSpriteCompositeState extends State<ShipSpriteComposite> {
  /// Parent sprite dimensions at 1:1 scale.
  Size? _parentSize;

  /// Module sprite dimensions at 1:1 scale, keyed by module ship ID.
  final _moduleSizes = <String, Size>{};

  @override
  void initState() {
    super.initState();
    _loadImageSizes();
  }

  @override
  void didUpdateWidget(ShipSpriteComposite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ship.spriteFile != widget.ship.spriteFile ||
        oldWidget.modules.length != widget.modules.length) {
      _parentSize = null;
      _moduleSizes.clear();
      _loadImageSizes();
    }
  }

  void _loadImageSizes() {
    loadImageSize(widget.ship.spriteFile).then((size) {
      if (mounted && size != null) setState(() => _parentSize = size);
    });

    for (final mod in widget.modules) {
      loadImageSize(mod.moduleShip.spriteFile).then((size) {
        if (mounted && size != null) {
          setState(() => _moduleSizes[mod.moduleShip.id] = size);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ship = widget.ship;
    final spriteFile = ship.spriteFile;

    if (spriteFile == null || _parentSize == null) {
      return const SizedBox.shrink();
    }

    // No modules — just render the parent sprite directly.
    if (widget.modules.isEmpty) {
      return Image.file(File(spriteFile), fit: widget.fit);
    }

    final parentW = _parentSize!.width;
    final parentH = _parentSize!.height;
    final parentCenter = ship.center;

    if (parentCenter == null || parentCenter.length < 2) {
      return Image.file(File(spriteFile), fit: widget.fit);
    }

    // Compute each module's position and accumulate the overall bounding box.
    // Start with the parent rect at origin.
    var bounds = Rect.fromLTWH(0, 0, parentW, parentH);
    final moduleLayouts = <_ModuleLayout>[];

    for (final mod in widget.modules) {
      final modSize = _moduleSizes[mod.moduleShip.id];
      if (modSize == null) continue;
      if (mod.moduleShip.spriteFile == null) continue;

      final layout = _computeModuleLayout(
        parentCenter: parentCenter,
        parentImgH: parentH,
        slot: mod.parentSlot,
        moduleShip: mod.moduleShip,
        moduleSize: modSize,
      );

      moduleLayouts.add(layout);
      bounds = bounds.expandToInclude(layout.bounds);
    }

    // Offset everything so bounds start at (0,0).
    final dx = -bounds.left;
    final dy = -bounds.top;

    return FittedBox(
      fit: widget.fit,
      child: SizedBox(
        width: bounds.width,
        height: bounds.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Module sprites (behind parent).
            for (final layout in moduleLayouts)
              Positioned(
                left: layout.left + dx,
                top: layout.top + dy,
                width: layout.width,
                height: layout.height,
                child: layout.angle == 0
                    ? Image.file(File(layout.spriteFile))
                    : Transform.rotate(
                        angle: layout.angle,
                        origin: layout.rotationOrigin,
                        child: Image.file(File(layout.spriteFile)),
                      ),
              ),
            // Parent sprite on top.
            Positioned(
              left: dx,
              top: dy,
              width: parentW,
              height: parentH,
              child: Image.file(File(spriteFile)),
            ),
          ],
        ),
      ),
    );
  }

  /// Compute where a module sprite should be placed relative to the parent
  /// sprite's coordinate system.
  static _ModuleLayout _computeModuleLayout({
    required List<double> parentCenter,
    required double parentImgH,
    required dynamic slot,
    required Ship moduleShip,
    required Size moduleSize,
  }) {
    // Parent STATION slot position in screen coords.
    final pcx = parentCenter[0];
    final pcy = parentImgH - parentCenter[1];
    final slotX = pcx - slot.locations[1];
    final slotY = pcy - slot.locations[0];

    // moduleAnchor uses the rotated coordinate system (forward, left)
    // relative to the module's center — same as bounds and slot locations.
    final modCenter = moduleShip.center;
    double anchorX, anchorY;
    if (modCenter != null && modCenter.length >= 2) {
      final mcx = modCenter[0];
      final mcy = moduleSize.height - modCenter[1];
      final anchor = moduleShip.moduleAnchor;
      if (anchor != null && anchor.length >= 2) {
        anchorX = mcx - anchor[1];
        anchorY = mcy - anchor[0];
      } else {
        anchorX = mcx;
        anchorY = mcy;
      }
    } else {
      anchorX = moduleSize.width / 2;
      anchorY = moduleSize.height / 2;
    }

    // Module rotation from the STATION slot angle.
    // Starsector: 0° = forward (up), positive = CCW.
    // Flutter Transform.rotate: positive = CW.
    final angleDeg = (slot.angle as double?) ?? 0.0;
    final angleRad = -angleDeg * (pi / 180);

    // Position the module so its anchor aligns with the slot.
    final left = slotX - anchorX;
    final top = slotY - anchorY;

    // Compute rotated bounding box for the overall bounds calculation.
    Rect bounds;
    if (angleDeg == 0) {
      bounds = Rect.fromLTWH(left, top, moduleSize.width, moduleSize.height);
    } else {
      bounds = _rotatedBounds(
        left,
        top,
        moduleSize.width,
        moduleSize.height,
        angleRad,
        Offset(anchorX, anchorY),
      );
    }

    return _ModuleLayout(
      left: left,
      top: top,
      width: moduleSize.width,
      height: moduleSize.height,
      angle: angleRad,
      // origin is offset FROM CENTER of child, not from top-left.
      rotationOrigin: Offset(
        anchorX - moduleSize.width / 2,
        anchorY - moduleSize.height / 2,
      ),
      bounds: bounds,
      spriteFile: moduleShip.spriteFile!,
    );
  }

  /// Compute the axis-aligned bounding box of a rectangle after rotation
  /// around [origin] (relative to the rect's top-left).
  static Rect _rotatedBounds(
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
}

class _ModuleLayout {
  final double left;
  final double top;
  final double width;
  final double height;
  final double angle;
  final Offset rotationOrigin;
  final Rect bounds;
  final String spriteFile;

  const _ModuleLayout({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.angle,
    required this.rotationOrigin,
    required this.bounds,
    required this.spriteFile,
  });
}
