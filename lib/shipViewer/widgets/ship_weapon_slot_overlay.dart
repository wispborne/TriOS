import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/shipViewer/models/ship_weapon_slot.dart';
import 'package:trios/shipViewer/ship_module_resolver.dart';
import 'package:trios/shipViewer/utils/polygon_utils.dart';
import 'package:trios/shipViewer/utils/sprite_utils.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/tooltip_frame.dart';

/// Displays a ship sprite at 1:1 scale with weapon slot markers and firing
/// arcs overlaid. Scrollable if the sprite exceeds the available space.
///
/// When [modules] is provided, module sprites are rendered at their docking
/// positions beneath the weapon slot overlay.
class ShipWeaponSlotOverlay extends StatefulWidget {
  final Ship ship;
  final List<ResolvedModule> modules;

  const ShipWeaponSlotOverlay({
    super.key,
    required this.ship,
    this.modules = const [],
  });

  @override
  State<ShipWeaponSlotOverlay> createState() => _ShipWeaponSlotOverlayState();
}

class _ShipWeaponSlotOverlayState extends State<ShipWeaponSlotOverlay> {
  int? _hoveredIndex;
  int? _hoveredModuleIndex;
  bool _showModules = true;
  Size? _imageSize;
  double? _viewportWidth;
  bool _hasAppliedInitialTransform = false;
  final _transformController = TransformationController();
  final _moduleSizes = <String, Size>{};
  bool _showBounds = false;
  bool _showMounts = true;
  bool _showArcs = true;
  _ModuleGeometry? _cachedModuleGeometry;

  static const _slotColors = <String, Color>{
    'ENERGY': Colors.cyan,
    'MISSILE': Colors.lime,
    'DECORATIVE': Colors.red,
    'SYSTEM': Colors.grey,
    'BUILT_IN': Color(0xFFD0D0D0),
    'HYBRID': Colors.orange,
    'BALLISTIC': Color(0xFFFFAA33),
    'COMPOSITE': Colors.orange,
    'SYNERGY': Colors.cyan,
    'UNIVERSAL': Colors.white,
    'STATION_MODULE': Colors.amber,
  };

  static const _slotBaseRadius = <String, double>{
    'SMALL': 5.0,
    'MEDIUM': 8.0,
    'LARGE': 12.0,
  };

  Color _colorForType(String type) =>
      _slotColors[type.toUpperCase()] ?? Colors.white;

  double _radiusForSize(String size) =>
      _slotBaseRadius[size.toUpperCase()] ?? 5.0;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
    _resolveModuleImageSizes();
    _recomputeModuleGeometry();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ShipWeaponSlotOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ship.spriteFile != widget.ship.spriteFile) {
      _hasAppliedInitialTransform = false;
      _resolveImageSize();
    }
    if (oldWidget.modules != widget.modules) {
      _moduleSizes.clear();
      _resolveModuleImageSizes();
    }
    _recomputeModuleGeometry();
  }

  Matrix4 _computeCenteringTransform() {
    if (_imageSize == null || _viewportWidth == null) return Matrix4.identity();

    final ship = widget.ship;
    final center = ship.center;
    final imgW = _imageSize!.width;
    final slots = ship.weaponSlots ?? [];

    final maxArcRadius =
        slots.isEmpty ? 0.0 : slots.map((s) => _radiusForSize(s.size) * 5).reduce(max);
    final pad = maxArcRadius;
    final totalContentWidth = imgW + pad * 2;

    double tx;
    if (totalContentWidth <= _viewportWidth!) {
      // Content fits — center the whole thing (padding included, so arcs visible)
      tx = (_viewportWidth! - totalContentWidth) / 2;
    } else if (center != null && center.length >= 2) {
      // Content wider than viewport — center on the ship's center point,
      // keeping the padding offset so left-side arcs aren't clipped.
      tx = _viewportWidth! / 2 - (pad + center[0]);
    } else {
      tx = 0;
    }

    return Matrix4.translationValues(tx, 0.0, 0.0);
  }

  void _resolveImageSize() {
    loadImageSize(widget.ship.spriteFile).then((size) {
      if (mounted && size != null) {
        setState(() {
          _imageSize = size;
          _recomputeModuleGeometry();
        });
      }
    });
  }

  void _resolveModuleImageSizes() {
    final modules = widget.modules;
    if (modules.isEmpty) return;

    // Load all module sizes in parallel, then batch into a single setState.
    Future.wait(
      modules.map((mod) async {
        final size = await loadImageSize(mod.moduleShip.spriteFile);
        return size != null ? MapEntry(mod.moduleShip.id, size) : null;
      }),
    ).then((results) {
      if (!mounted) return;
      final newSizes = <String, Size>{};
      for (final entry in results) {
        if (entry != null) newSizes[entry.key] = entry.value;
      }
      if (newSizes.isNotEmpty) {
        setState(() {
          _moduleSizes.addAll(newSizes);
          _recomputeModuleGeometry();
        });
      }
    });
  }

  /// Recompute cached module geometry when inputs change.
  void _recomputeModuleGeometry() {
    final imgH = _imageSize?.height;
    final parentCenter = widget.ship.center;
    if (imgH == null ||
        parentCenter == null ||
        parentCenter.length < 2) {
      _cachedModuleGeometry = null;
      return;
    }

    final pcx = parentCenter[0];
    final pcy = imgH - parentCenter[1];

    final layouts = <_ModuleSpriteLayout>[];
    final rects = <Rect>[];
    final polygons = <List<Offset>>[];

    for (var i = 0; i < widget.modules.length; i++) {
      final mod = widget.modules[i];
      final modSize = _moduleSizes[mod.moduleShip.id];
      if (modSize == null) continue;
      if (mod.moduleShip.spriteFile == null) continue;

      final slot = mod.parentSlot;
      final slotX = pcx - slot.locations[1];
      final slotY = pcy - slot.locations[0];

      // moduleAnchor uses the rotated coordinate system (forward, left)
      // relative to the module's center — same as bounds and slot locations.
      final modCenter = mod.moduleShip.center;
      double anchorX, anchorY;
      if (modCenter != null && modCenter.length >= 2) {
        final mcx = modCenter[0];
        final mcy = modSize.height - modCenter[1];
        final anchor = mod.moduleShip.moduleAnchor;
        if (anchor != null && anchor.length >= 2) {
          anchorX = mcx - anchor[1];
          anchorY = mcy - anchor[0];
        } else {
          anchorX = mcx;
          anchorY = mcy;
        }
      } else {
        anchorX = modSize.width / 2;
        anchorY = modSize.height / 2;
      }

      final left = slotX - anchorX;
      final top = slotY - anchorY;
      final angleDeg = slot.angle;
      final angleRad = -angleDeg * (pi / 180);

      final modBounds = mod.moduleShip.bounds;
      if (modBounds != null && modBounds.length >= 6) {
        // The module's center in screen coords (unrotated).
        final mc = mod.moduleShip.center;
        double sprCx = left + (mc != null && mc.length >= 2
            ? mc[0]
            : modSize.width / 2);
        double sprCy = top + (mc != null && mc.length >= 2
            ? modSize.height - mc[1]
            : modSize.height / 2);

        // The sprite rotates around the anchor (slot position). Rotate the
        // center around the anchor so the bounds match the visual sprite.
        if (angleDeg != 0) {
          final dx = sprCx - slotX;
          final dy = sprCy - slotY;
          final cosA = cos(angleRad);
          final sinA = sin(angleRad);
          sprCx = slotX + dx * cosA - dy * sinA;
          sprCy = slotY + dx * sinA + dy * cosA;
        }

        polygons.add(parseBoundsToPolygon(modBounds, sprCx, sprCy, angleRad));
      } else {
        polygons.add(const []);
      }

      rects.add(Rect.fromLTWH(left, top, modSize.width, modSize.height));
      layouts.add(_ModuleSpriteLayout(
        left: left,
        top: top,
        width: modSize.width,
        height: modSize.height,
        angleDeg: angleDeg,
        angleRad: angleRad,
        anchorX: anchorX,
        anchorY: anchorY,
        spriteFile: mod.moduleShip.spriteFile!,
      ));
    }

    _cachedModuleGeometry = _ModuleGeometry(
      layouts: layouts,
      rects: rects,
      polygons: polygons,
    );
  }

  /// Build positioned module sprite widgets from cached geometry.
  List<Widget> _buildModuleSprites() {
    final geom = _cachedModuleGeometry;
    if (geom == null) return const [];

    return [
      for (var i = 0; i < geom.layouts.length; i++)
        _buildModuleSpriteWidget(i, geom.layouts[i]),
    ];
  }

  Widget _buildModuleSpriteWidget(int index, _ModuleSpriteLayout layout) {
    final isHovered = _hoveredModuleIndex == index;

    Widget sprite = ColorFiltered(
      colorFilter: ColorFilter.mode(
        isHovered ? const Color(0x4DFFFFFF) : const Color(0x00000000),
        BlendMode.srcATop,
      ),
      child: Image.file(
        File(layout.spriteFile),
        width: layout.width,
        height: layout.height,
      ),
    );

    if (layout.angleDeg != 0) {
      sprite = Transform.rotate(
        angle: layout.angleRad,
        origin: Offset(
          layout.anchorX - layout.width / 2,
          layout.anchorY - layout.height / 2,
        ),
        child: sprite,
      );
    }

    return Positioned(
      left: layout.left,
      top: layout.top,
      width: layout.width,
      height: layout.height,
      child: sprite,
    );
  }

  /// Convert a weapon slot's game coordinates to screen pixel coordinates
  /// on the sprite image (at 1:1 scale).
  ///
  /// Starsector coordinate system:
  /// - `center` is [x, y] from the bottom-left of the sprite image.
  /// - `locations` is rotated 90° CW from standard:
  ///   - locations[0] = forward (UP on sprite)
  ///   - locations[1] = left of ship (LEFT on sprite)
  /// - Screen: origin at top-left, x-right, y-down.
  Offset _slotScreenPos(ShipWeaponSlot slot, double imgH) {
    final center = widget.ship.center!;
    final cx = center[0];
    final cy = imgH - center[1];
    return Offset(cx - slot.locations[1], cy - slot.locations[0]);
  }

  @override
  Widget build(BuildContext context) {
    final ship = widget.ship;
    final spriteFile = ship.spriteFile;
    final slots = ship.weaponSlots;
    final center = ship.center;

    if (spriteFile == null ||
        slots == null ||
        slots.isEmpty ||
        center == null ||
        center.length < 2 ||
        _imageSize == null) {
      return const SizedBox.shrink();
    }

    final imgW = _imageSize!.width;
    final imgH = _imageSize!.height;

    // Compute max arc overflow so arcs near edges aren't clipped.
    // Arc radius = slotBaseRadius * 5.
    final maxArcRadius = slots
        .map((s) => _radiusForSize(s.size) * 5)
        .reduce(max);
    final pad = maxArcRadius;

    // Display at 1:1 scale with zoom/pan support.
    // Cap the viewport height so this works inside a ScrollView.
    final viewportHeight = (imgH + pad * 2).clamp(0.0, 500.0);
    return LayoutBuilder(builder: (context, constraints) {
      final newViewportWidth = constraints.maxWidth;
      if (_viewportWidth != newViewportWidth) {
        _viewportWidth = newViewportWidth;
        _hasAppliedInitialTransform = false;
      }
      if (!_hasAppliedInitialTransform) {
        _hasAppliedInitialTransform = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _transformController.value = _computeCenteringTransform();
          }
        });
      }
      return SizedBox(
      height: viewportHeight,
      child: Stack(
        children: [
          Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                // Prevent the parent ScrollView from scrolling while zooming.
                GestureBinding.instance.pointerSignalResolver.register(
                  event,
                  (event) {},
                );
              }
            },
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _transformController,
                constrained: false,
                minScale: 0.1,
                maxScale: 5.0,
                boundaryMargin: EdgeInsets.all(double.infinity),
                child: Padding(
                  padding: EdgeInsets.all(pad),
                  child: MouseRegion(
                    hitTestBehavior: HitTestBehavior.translucent,
                    onHover: _showModules && _cachedModuleGeometry != null
                        ? (event) {
                            final geom = _cachedModuleGeometry!;
                            final pos = event.localPosition;
                            for (var i = geom.polygons.length - 1;
                                i >= 0;
                                i--) {
                              final poly = geom.polygons[i];
                              final hit = poly.isNotEmpty
                                  ? polygonContainsPoint(poly, pos)
                                  : i < geom.rects.length &&
                                      geom.rects[i].contains(pos);
                              if (hit) {
                                if (_hoveredModuleIndex != i) {
                                  setState(() => _hoveredModuleIndex = i);
                                }
                                return;
                              }
                            }
                            if (_hoveredModuleIndex != null) {
                              setState(() => _hoveredModuleIndex = null);
                            }
                          }
                        : null,
                    onExit: (_) {
                      if (_hoveredModuleIndex != null) {
                        setState(() => _hoveredModuleIndex = null);
                      }
                    },
                    child: SizedBox(
                      width: imgW,
                      height: imgH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Image.file(
                              File(spriteFile), width: imgW, height: imgH),
                          // Module sprites behind the weapon slot overlay.
                          if (_showModules) ..._buildModuleSprites(),
                          if (_showBounds)
                            CustomPaint(
                              size: Size(imgW, imgH),
                              painter: _BoundsPainter(
                                parentBoundsPolygon:
                                    ship.bounds != null &&
                                            ship.bounds!.length >= 6
                                        ? parseBoundsToPolygon(
                                            ship.bounds!,
                                            center[0],
                                            imgH - center[1],
                                          )
                                        : null,
                                moduleBoundsPolygons:
                                    _showModules ? (_cachedModuleGeometry?.polygons ?? const []) : const [],
                              ),
                            ),
                          if (_showMounts || _showArcs)
                            CustomPaint(
                              size: Size(imgW, imgH),
                              painter: _WeaponSlotPainter(
                                slots: slots,
                                imgH: imgH,
                                center: center,
                                hoveredIndex: _hoveredIndex,
                                colorForType: _colorForType,
                                radiusForSize: _radiusForSize,
                                showMounts: _showMounts,
                                showArcs: _showArcs,
                              ),
                            ),
                          if (_showMounts)
                            for (var i = 0; i < slots.length; i++)
                              if (slots[i].locations.length >= 2)
                                _buildSlotHitArea(i, slots[i], imgH, context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            bottom: 4,
            child: Row(
              spacing: 4,
              mainAxisSize: MainAxisSize.min,
              children: [
                _compactIconButton(
                  onPressed: () =>
                      _transformController.value = _computeCenteringTransform(),
                  icon: Icons.fit_screen_outlined,
                  tooltip: 'Reset zoom',
                ),
                if (widget.modules.isNotEmpty)
                  _compactIconButton(
                    onPressed: () =>
                        setState(() => _showModules = !_showModules),
                    icon: _showModules ? Icons.extension : Icons.extension_off,
                    tooltip: _showModules ? 'Hide modules' : 'Show modules',
                  ),
                _compactIconButton(
                  onPressed: () =>
                      setState(() => _showBounds = !_showBounds),
                  icon: _showBounds ? Icons.hexagon : Icons.hexagon_outlined,
                  tooltip: _showBounds ? 'Hide bounds' : 'Show bounds',
                ),
                _compactIconButton(
                  onPressed: () =>
                      setState(() => _showMounts = !_showMounts),
                  icon: _showMounts ? Icons.location_on : Icons.location_off,
                  tooltip: _showMounts ? 'Hide mounts' : 'Show mounts',
                ),
                _compactIconButton(
                  onPressed: () =>
                      setState(() => _showArcs = !_showArcs),
                  icon: _showArcs ? Icons.radar : Icons.adjust,
                  tooltip: _showArcs ? 'Hide arcs' : 'Show arcs',
                ),
              ],
            ),
          ),
        ],
      ),
    );
    });
  }

  static final _compactButtonStyle = IconButton.styleFrom(
    minimumSize: const Size(28, 28),
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  Widget _compactIconButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
  }) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      iconSize: 16,
      style: _compactButtonStyle,
      tooltip: tooltip,
    );
  }

  Widget _buildSlotHitArea(
    int index,
    ShipWeaponSlot slot,
    double imgH,
    BuildContext context,
  ) {
    final pos = _slotScreenPos(slot, imgH);
    final radius = _radiusForSize(slot.size);
    final hitSize = (radius + 6) * 2;

    return Positioned(
      left: pos.dx - hitSize / 2,
      top: pos.dy - hitSize / 2,
      width: hitSize,
      height: hitSize,
      child: MovingTooltipWidget(
        tooltipWidget: TooltipFrame(
          child: _buildSlotTooltipContent(slot, context),
        ),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredIndex = index),
          onExit: (_) => setState(() => _hoveredIndex = null),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildSlotTooltipContent(ShipWeaponSlot slot, BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForType(slot.type);
    final mountLabel = slot.mount.toUpperCase() == 'HARDPOINT'
        ? 'Hardpoint'
        : 'Turret';

    // Find module name for STATION slots.
    String? moduleName;
    if (slot.isStationModule) {
      for (final mod in widget.modules) {
        if (mod.parentSlot.id == slot.id) {
          moduleName = mod.moduleShip.hullNameForDisplay();
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: slot.mount.toUpperCase() == 'HARDPOINT'
                    ? BoxShape.rectangle
                    : BoxShape.circle,
              ),
            ),
            Text(
              slot.id,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (slot.isStationModule) ...[
          Text('Station Module', style: theme.textTheme.bodySmall),
          if (moduleName != null)
            Text(
              'Module: $moduleName',
              style: theme.textTheme.bodySmall,
            ),
        ] else ...[
          Text(
            '${slot.size.toUpperCase()} $mountLabel',
            style: theme.textTheme.bodySmall,
          ),
          Text('Type: ${slot.type}', style: theme.textTheme.bodySmall),
          if (slot.arc > 0)
            Text(
              'Arc: ${slot.arc.toStringAsFixed(0)}°',
              style: theme.textTheme.bodySmall,
            ),
        ],
        Text(
          'Angle: ${slot.angle.toStringAsFixed(0)}°',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _WeaponSlotPainter extends CustomPainter {
  final List<ShipWeaponSlot> slots;
  final double imgH;
  final List<double> center;
  final int? hoveredIndex;
  final Color Function(String type) colorForType;
  final double Function(String size) radiusForSize;

  final bool showMounts;
  final bool showArcs;

  _WeaponSlotPainter({
    required this.slots,
    required this.imgH,
    required this.center,
    required this.hoveredIndex,
    required this.colorForType,
    required this.radiusForSize,
    required this.showMounts,
    required this.showArcs,
  });

  Offset _slotPos(ShipWeaponSlot slot) {
    final cx = center[0];
    final cy = imgH - center[1];
    return Offset(cx - slot.locations[1], cy - slot.locations[0]);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      if (slot.locations.length < 2) continue;

      final pos = _slotPos(slot);
      final color = colorForType(slot.type);
      final radius = radiusForSize(slot.size);
      final isHovered = hoveredIndex == i;

      // Draw firing arc
      if (showArcs && slot.arc > 0) {
        _drawFiringArc(canvas, pos, slot, color, radius, isHovered);
      }

      // Draw slot marker
      if (showMounts) {
        _drawSlotMarker(canvas, pos, slot, color, radius, isHovered);
      }
    }
  }

  void _drawFiringArc(
    Canvas canvas,
    Offset pos,
    ShipWeaponSlot slot,
    Color color,
    double radius,
    bool isHovered,
  ) {
    final arcRadius = radius * 5;
    final arcRect = Rect.fromCircle(center: pos, radius: arcRadius);

    // Starsector angles: 0° = forward (UP on sprite), CCW positive.
    // Flutter canvas: 0 rad = right (3 o'clock), CW positive.
    // Forward (UP) = -π/2 in canvas coords.
    // To convert: canvasRad = -π/2 - starsectorRad (negate for CCW→CW)
    final angleDeg = slot.angle;
    final arcDeg = slot.arc;

    double startRad;
    double sweepRad;

    if (arcDeg >= 360) {
      startRad = 0;
      sweepRad = 2 * pi;
    } else {
      final centerRad = -pi / 2 - angleDeg * (pi / 180);
      final halfSweep = arcDeg * (pi / 180) / 2;
      startRad = centerRad - halfSweep;
      sweepRad = arcDeg * (pi / 180);
    }

    final fillPaint = Paint()
      ..color = color.withValues(alpha: isHovered ? 0.35 : 0.12)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(pos.dx, pos.dy)
      ..arcTo(arcRect, startRad, sweepRad, false)
      ..close();
    canvas.drawPath(path, fillPaint);

    final outlinePaint = Paint()
      ..color = color.withValues(alpha: isHovered ? 0.7 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, outlinePaint);
  }

  void _drawSlotMarker(
    Canvas canvas,
    Offset pos,
    ShipWeaponSlot slot,
    Color color,
    double radius,
    bool isHovered,
  ) {
    final isHardpoint = slot.mount.toUpperCase() == 'HARDPOINT';
    final coloredStrokeWidth = isHovered ? 2.0 : 1.2;

    // Dark outline behind the colored stroke for contrast
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = coloredStrokeWidth + 2.0;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: isHovered ? 0.7 : 0.5)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = coloredStrokeWidth;

    if (isHardpoint) {
      final rect = Rect.fromCenter(
        center: pos,
        width: radius * 2,
        height: radius * 2,
      );
      canvas.drawRect(rect, shadowPaint);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
    } else {
      canvas.drawCircle(pos, radius, shadowPaint);
      canvas.drawCircle(pos, radius, fillPaint);
      canvas.drawCircle(pos, radius, strokePaint);
    }

    // Angle indicator line for turrets, starting from the edge of the circle
    if (!isHardpoint) {
      final angleRad = -pi / 2 - slot.angle * (pi / 180);
      final lineStart = Offset(
        pos.dx + cos(angleRad) * radius,
        pos.dy + sin(angleRad) * radius,
      );
      final lineEnd = Offset(
        pos.dx + cos(angleRad) * (radius + radius * 1.0),
        pos.dy + sin(angleRad) * (radius + radius * 1.0),
      );

      canvas.drawLine(
        lineStart,
        lineEnd,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.7)
          ..strokeWidth = coloredStrokeWidth + 1
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        lineStart,
        lineEnd,
        Paint()
          ..color = color
          ..strokeWidth = coloredStrokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_WeaponSlotPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        !identical(oldDelegate.slots, slots) ||
        oldDelegate.showMounts != showMounts ||
        oldDelegate.showArcs != showArcs;
  }
}

class _BoundsPainter extends CustomPainter {
  final List<Offset>? parentBoundsPolygon;
  final List<List<Offset>> moduleBoundsPolygons;

  _BoundsPainter({
    required this.parentBoundsPolygon,
    required this.moduleBoundsPolygons,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fillPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    if (parentBoundsPolygon != null && parentBoundsPolygon!.length >= 3) {
      _drawPolygon(canvas, parentBoundsPolygon!, strokePaint, fillPaint);
    }

    for (final poly in moduleBoundsPolygons) {
      if (poly.length >= 3) {
        _drawPolygon(canvas, poly, strokePaint, fillPaint);
      }
    }
  }

  void _drawPolygon(
    Canvas canvas,
    List<Offset> vertices,
    Paint stroke,
    Paint fill,
  ) {
    final path = Path()..moveTo(vertices[0].dx, vertices[0].dy);
    for (var i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_BoundsPainter oldDelegate) {
    return !identical(oldDelegate.parentBoundsPolygon, parentBoundsPolygon) ||
        !identical(oldDelegate.moduleBoundsPolygons, moduleBoundsPolygons);
  }
}

class _ModuleGeometry {
  final List<_ModuleSpriteLayout> layouts;
  final List<Rect> rects;
  final List<List<Offset>> polygons;

  const _ModuleGeometry({
    required this.layouts,
    required this.rects,
    required this.polygons,
  });
}

class _ModuleSpriteLayout {
  final double left;
  final double top;
  final double width;
  final double height;
  final double angleDeg;
  final double angleRad;
  final double anchorX;
  final double anchorY;
  final String spriteFile;

  const _ModuleSpriteLayout({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.angleDeg,
    required this.angleRad,
    required this.anchorX,
    required this.anchorY,
    required this.spriteFile,
  });
}
