import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
/// Modules are resolved internally via Riverpod using [resolvedModulesProvider].
///
/// All visual layers are individually configurable via constructor parameters.
/// These serve as initial values for the internal state toggles. When
/// [showToolbar] is true (default), the user can toggle layers at runtime.
class ShipBlueprintView extends ConsumerStatefulWidget {
  final Ship ship;

  /// Whether to render module sprites at their docking positions.
  final bool initialShowModules;

  /// Whether to render ship + module bounds polygons.
  final bool initialShowBounds;

  /// Whether to render weapon slot markers.
  final bool initialShowMounts;

  /// Whether to render firing arc wedges.
  final bool initialShowArcs;

  /// Whether to render module bounds separately from parent bounds.
  final bool initialShowModuleBounds;

  /// Whether to render turret angle indicator lines.
  final bool initialShowAngleIndicators;

  /// Whether to show tooltips on slot hover.
  final bool showSlotTooltips;

  /// Whether to show the bottom-left toggle toolbar.
  final bool showToolbar;

  /// Whether zoom/pan and hover interactions are enabled.
  final bool interactive;

  /// Optional resize width in logical pixels for the decoded image cache.
  /// When set, all sprite images (parent + modules) are decoded at this
  /// width, significantly reducing memory usage for fixed-size previews
  /// (e.g. thumbnails in a grid). The aspect ratio is preserved.
  /// Has no effect when null (images are decoded at full resolution).
  final int? cacheWidth;

  const ShipBlueprintView({
    super.key,
    required this.ship,
    this.initialShowModules = true,
    this.initialShowBounds = false,
    this.initialShowMounts = true,
    this.initialShowArcs = true,
    this.initialShowModuleBounds = true,
    this.initialShowAngleIndicators = true,
    this.showSlotTooltips = true,
    this.showToolbar = true,
    this.interactive = true,
    this.cacheWidth,
  });

  /// Creates a minimal, non-interactive view suitable for thumbnails.
  ///
  /// [cacheWidth] controls the decoded image cache width in logical pixels,
  /// reducing memory for small previews (e.g. pass the thumbnail's pixel
  /// width multiplied by the device pixel ratio).
  static Widget minimal({
    Key? key,
    required Ship ship,
    bool initialShowModules = true,
    bool initialShowBounds = false,
    bool initialShowMounts = false,
    bool initialShowArcs = false,
    bool initialShowModuleBounds = false,
    bool initialShowAngleIndicators = false,
    bool showSlotTooltips = false,
    bool showToolbar = false,
    bool interactive = false,
    int? cacheWidth,
  }) {
    return ShipBlueprintView(
      key: key,
      ship: ship,
      initialShowModules: initialShowModules,
      initialShowBounds: initialShowBounds,
      initialShowMounts: initialShowMounts,
      initialShowArcs: initialShowArcs,
      initialShowModuleBounds: initialShowModuleBounds,
      initialShowAngleIndicators: initialShowAngleIndicators,
      showSlotTooltips: showSlotTooltips,
      showToolbar: showToolbar,
      interactive: interactive,
      cacheWidth: cacheWidth,
    );
  }

  @override
  ConsumerState<ShipBlueprintView> createState() => _ShipBlueprintViewState();
}

class _ShipBlueprintViewState extends ConsumerState<ShipBlueprintView> {
  int? _hoveredIndex;
  int? _hoveredModuleIndex;
  int? _hoveredModuleSlotIndex;
  late bool _showModules;
  late bool _showBounds;
  late bool _showMounts;
  late bool _showArcs;
  late bool _showModuleBounds;
  Size? _imageSize;
  double? _viewportWidth;
  bool _hasAppliedInitialTransform = false;
  TransformationController? _transformController;

  TransformationController get _controller =>
      _transformController ??= TransformationController();
  final _moduleSizes = <String, Size>{};
  _ModuleGeometry? _cachedModuleGeometry;

  /// Track the last modules list so we can detect changes from Riverpod.
  List<ResolvedModule> _lastModules = const [];

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
    _showModules = widget.initialShowModules;
    _showBounds = widget.initialShowBounds;
    _showMounts = widget.initialShowMounts;
    _showArcs = widget.initialShowArcs;
    _showModuleBounds = widget.initialShowModuleBounds;
    _resolveImageSize();
  }

  @override
  void dispose() {
    _transformController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ShipBlueprintView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ship.spriteFile != widget.ship.spriteFile) {
      _hasAppliedInitialTransform = false;
      _resolveImageSize();
    }
  }

  Matrix4 _computeCenteringTransform() {
    if (_imageSize == null || _viewportWidth == null) return Matrix4.identity();

    final ship = widget.ship;
    final center = ship.center;
    final imgW = _imageSize!.width;
    final slots = ship.weaponSlots ?? [];

    final maxArcRadius = slots.isEmpty
        ? 0.0
        : slots.map((s) => _radiusForSize(s.size) * 5).reduce(max);
    final pad = maxArcRadius;
    final totalContentWidth = imgW + pad * 2;

    double tx;
    if (totalContentWidth <= _viewportWidth!) {
      tx = (_viewportWidth! - totalContentWidth) / 2;
    } else if (center != null && center.length >= 2) {
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
        });
      }
    });
  }

  void _resolveModuleImageSizes(List<ResolvedModule> modules) {
    if (modules.isEmpty) return;

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
        });
      }
    });
  }

  /// Compute module geometry from the given [modules] list.
  _ModuleGeometry? _computeModuleGeometry(List<ResolvedModule> modules) {
    final imgH = _imageSize?.height;
    final parentCenter = widget.ship.center;
    if (imgH == null || parentCenter == null || parentCenter.length < 2) {
      return null;
    }

    final pcx = parentCenter[0];
    final pcy = imgH - parentCenter[1];

    final layouts = <_ModuleSpriteLayout>[];
    final rects = <Rect>[];
    final polygons = <List<Offset>>[];
    final allTransformedSlots = <_TransformedSlot>[];

    for (var i = 0; i < modules.length; i++) {
      final mod = modules[i];
      final modSize = _moduleSizes[mod.moduleShip.id];
      if (modSize == null) continue;
      if (mod.moduleShip.spriteFile == null) continue;

      final slot = mod.parentSlot;
      final slotX = pcx - slot.locations[1];
      final slotY = pcy - slot.locations[0];

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
        final mc = mod.moduleShip.center;
        double sprCx =
            left + (mc != null && mc.length >= 2 ? mc[0] : modSize.width / 2);
        double sprCy =
            top +
            (mc != null && mc.length >= 2
                ? modSize.height - mc[1]
                : modSize.height / 2);

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

      rects.add(angleDeg == 0
          ? Rect.fromLTWH(left, top, modSize.width, modSize.height)
          : rotatedBounds(
              left,
              top,
              modSize.width,
              modSize.height,
              angleRad,
              Offset(anchorX, anchorY),
            ));
      layouts.add(
        _ModuleSpriteLayout(
          left: left,
          top: top,
          width: modSize.width,
          height: modSize.height,
          angleDeg: angleDeg,
          angleRad: angleRad,
          anchorX: anchorX,
          anchorY: anchorY,
          spriteFile: mod.moduleShip.spriteFile!,
        ),
      );

      // Transform this module's weapon slots into parent screen coords.
      final modSlots = mod.moduleShip.weaponSlots;
      if (modSlots != null && modCenter != null && modCenter.length >= 2) {
        final mcx = modCenter[0];
        final mcy = modSize.height - modCenter[1];
        final modName = mod.moduleShip.hullNameForDisplay();
        final cosA = cos(angleRad);
        final sinA = sin(angleRad);

        for (final ws in modSlots) {
          if (ws.locations.length < 2) continue;
          if (ws.isStationModule) continue;

          // Slot position relative to module sprite origin.
          final localX = mcx - ws.locations[1];
          final localY = mcy - ws.locations[0];

          // Offset relative to module anchor (rotation pivot).
          final relX = localX - anchorX;
          final relY = localY - anchorY;

          // Rotate by module angle and translate to docking position.
          double screenX, screenY;
          if (angleDeg != 0) {
            screenX = slotX + relX * cosA - relY * sinA;
            screenY = slotY + relX * sinA + relY * cosA;
          } else {
            screenX = slotX + relX;
            screenY = slotY + relY;
          }

          allTransformedSlots.add(
            _TransformedSlot(
              slot: ws,
              screenPos: Offset(screenX, screenY),
              adjustedAngleDeg: ws.angle + angleDeg,
              moduleIndex: i,
              moduleName: modName,
            ),
          );
        }
      }
    }

    // Compute the bounding rect that encompasses all module sprites.
    Rect? totalBounds;
    for (final r in rects) {
      totalBounds = totalBounds?.expandToInclude(r) ?? r;
    }

    return _ModuleGeometry(
      layouts: layouts,
      rects: rects,
      polygons: polygons,
      totalBounds: totalBounds,
      transformedSlots: allTransformedSlots,
    );
  }

  /// Build positioned module sprite widgets, shifted by [dx]/[dy] so that
  /// all coordinates are non-negative within the expanded Stack.
  List<Widget> _buildModuleSpritesOffset(double dx, double dy) {
    final geom = _cachedModuleGeometry;
    if (geom == null) return const [];

    return [
      for (var i = 0; i < geom.layouts.length; i++)
        _buildModuleSpriteWidget(i, geom.layouts[i], dx, dy),
    ];
  }

  Widget _buildModuleSpriteWidget(
    int index,
    _ModuleSpriteLayout layout,
    double dx,
    double dy,
  ) {
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
      left: layout.left + dx,
      top: layout.top + dy,
      width: layout.width,
      height: layout.height,
      child: sprite,
    );
  }

  /// Lightweight widget tree for non-interactive thumbnails.
  /// Skips LayoutBuilder, TransformationController, MouseRegion, slot
  /// processing, and padding — just the ship sprite + module sprites.
  Widget _buildMinimalContent(double imgW, double imgH) {
    final parentRect = Rect.fromLTWH(0, 0, imgW, imgH);
    final geom = _cachedModuleGeometry;
    final moduleTotalBounds = (_showModules && geom?.totalBounds != null)
        ? geom!.totalBounds!
        : null;
    final combinedRect = moduleTotalBounds != null
        ? parentRect.expandToInclude(moduleTotalBounds)
        : parentRect;

    final originDx = -combinedRect.left;
    final originDy = -combinedRect.top;

    return SizedBox(
      width: combinedRect.width,
      height: combinedRect.height,
      child: Stack(
        children: [
          Positioned(
            left: originDx,
            top: originDy,
            width: imgW,
            height: imgH,
            child: Image.file(
              File(widget.ship.spriteFile!),
              width: imgW,
              height: imgH,
              cacheWidth: widget.cacheWidth,
              fit: widget.cacheWidth != null ? BoxFit.fill : BoxFit.scaleDown,
            ),
          ),
          if (_showModules) ..._buildModuleSpritesOffset(originDx, originDy),
        ],
      ),
    );
  }

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
    final modules = ref.watch(resolvedModulesProvider(ship.id));

    // Detect module changes from Riverpod and trigger image size resolution.
    if (!identical(_lastModules, modules)) {
      final oldIds = _lastModules.map((m) => m.moduleShip.id).toSet();
      final newIds = modules.map((m) => m.moduleShip.id).toSet();
      if (!const SetEquality<String>().equals(oldIds, newIds)) {
        _moduleSizes.clear();
        _resolveModuleImageSizes(modules);
      }
      _hoveredModuleSlotIndex = null;
      _lastModules = modules;
    }

    // Recompute module geometry each build (cheap — just math on cached sizes).
    _cachedModuleGeometry = _computeModuleGeometry(modules);

    if (spriteFile == null || _imageSize == null) {
      return const SizedBox.shrink();
    }

    final imgW = _imageSize!.width;
    final imgH = _imageSize!.height;
    final hasCenter = center != null && center.length >= 2;

    // --- Fast path for non-interactive (thumbnail) mode ---
    if (!widget.interactive) {
      return RepaintBoundary(
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.contain,
            child: _buildMinimalContent(imgW, imgH),
          ),
        ),
      );
    }

    final effectiveSlots = (slots != null && slots.isNotEmpty && hasCenter)
        ? slots
        : <ShipWeaponSlot>[];

    // Compute the combined bounding rect of parent sprite + all module
    // sprites so the Stack can be sized to contain everything. Module
    // sprites may extend beyond the parent sprite bounds.
    final parentRect = Rect.fromLTWH(0, 0, imgW, imgH);
    final geom = _cachedModuleGeometry;
    final moduleTotalBounds = (_showModules && geom?.totalBounds != null)
        ? geom!.totalBounds!
        : null;
    final combinedRect = moduleTotalBounds != null
        ? parentRect.expandToInclude(moduleTotalBounds)
        : parentRect;

    // Offset to shift everything into positive coordinate space.
    final originDx = -combinedRect.left;
    final originDy = -combinedRect.top;
    final totalW = combinedRect.width;
    final totalH = combinedRect.height;

    final parentArcRadius = effectiveSlots.isEmpty
        ? 0.0
        : effectiveSlots.map((s) => _radiusForSize(s.size) * 5).reduce(max);
    final moduleArcRadius =
        (_showModules &&
            _cachedModuleGeometry != null &&
            _cachedModuleGeometry!.transformedSlots.isNotEmpty)
        ? _cachedModuleGeometry!.transformedSlots
              .map((ts) => _radiusForSize(ts.slot.size) * 5)
              .reduce(max)
        : 0.0;
    final maxArcRadius = max(parentArcRadius, moduleArcRadius);
    final pad = maxArcRadius;

    final viewportHeight = (totalH + pad * 2).clamp(0.0, 500.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final newViewportWidth = constraints.maxWidth;
        if (_viewportWidth != newViewportWidth) {
          _viewportWidth = newViewportWidth;
          _hasAppliedInitialTransform = false;
        }
        if (!_hasAppliedInitialTransform) {
          _hasAppliedInitialTransform = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _controller.value = _computeCenteringTransform();
            }
          });
        }

        final content = Padding(
          padding: EdgeInsets.all(pad),
          child: MouseRegion(
            hitTestBehavior: HitTestBehavior.translucent,
            onHover:
                widget.interactive &&
                    _showModules &&
                    _cachedModuleGeometry != null
                ? (event) {
                    final cGeom = _cachedModuleGeometry!;
                    // Adjust hit-test position for the origin offset.
                    final pos =
                        event.localPosition - Offset(originDx, originDy);
                    for (var i = cGeom.polygons.length - 1; i >= 0; i--) {
                      final poly = cGeom.polygons[i];
                      final hit = poly.isNotEmpty
                          ? polygonContainsPoint(poly, pos)
                          : i < cGeom.rects.length &&
                                cGeom.rects[i].contains(pos);
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
              width: totalW,
              height: totalH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Parent ship sprite, offset so modules with negative
                  // coordinates still fit within the Stack.
                  Positioned(
                    left: originDx,
                    top: originDy,
                    width: imgW,
                    height: imgH,
                    child: Image.file(
                      File(spriteFile),
                      width: imgW,
                      height: imgH,
                      cacheWidth: widget.cacheWidth,
                      fit: widget.cacheWidth != null
                          ? BoxFit.fill
                          : BoxFit.scaleDown,
                    ),
                  ),
                  if (_showModules)
                    ..._buildModuleSpritesOffset(originDx, originDy),
                  if (_showBounds)
                    Positioned(
                      left: originDx,
                      top: originDy,
                      width: imgW,
                      height: imgH,
                      child: CustomPaint(
                        size: Size(imgW, imgH),
                        painter: _BoundsPainter(
                          parentBoundsPolygon:
                              ship.bounds != null &&
                                  ship.bounds!.length >= 6 &&
                                  hasCenter
                              ? parseBoundsToPolygon(
                                  ship.bounds!,
                                  center[0],
                                  imgH - center[1],
                                )
                              : null,
                          moduleBoundsPolygons:
                              _showModules && _showModuleBounds
                              ? (_cachedModuleGeometry?.polygons ?? const [])
                              : const [],
                        ),
                      ),
                    ),
                  if ((_showMounts || _showArcs) &&
                      (effectiveSlots.isNotEmpty ||
                          (_showModules &&
                              (_cachedModuleGeometry
                                      ?.transformedSlots
                                      .isNotEmpty ??
                                  false))))
                    Positioned(
                      left: originDx,
                      top: originDy,
                      width: imgW,
                      height: imgH,
                      child: CustomPaint(
                        size: Size(imgW, imgH),
                        painter: _WeaponSlotPainter(
                          slots: effectiveSlots,
                          moduleSlots: _showModules
                              ? (_cachedModuleGeometry?.transformedSlots ??
                                    const [])
                              : const [],
                          imgH: imgH,
                          center: center!,
                          hoveredIndex: _hoveredIndex,
                          hoveredModuleSlotIndex: _hoveredModuleSlotIndex,
                          colorForType: _colorForType,
                          radiusForSize: _radiusForSize,
                          showMounts: _showMounts,
                          showArcs: _showArcs,
                        ),
                      ),
                    ),
                  if (_showMounts)
                    for (var i = 0; i < effectiveSlots.length; i++)
                      if (effectiveSlots[i].locations.length >= 2)
                        _buildSlotHitAreaOffset(
                          i,
                          effectiveSlots[i],
                          imgH,
                          context,
                          modules,
                          originDx,
                          originDy,
                        ),
                  if (_showMounts &&
                      _showModules &&
                      _cachedModuleGeometry != null)
                    for (
                      var i = 0;
                      i < _cachedModuleGeometry!.transformedSlots.length;
                      i++
                    )
                      _buildModuleSlotHitAreaOffset(
                        i,
                        _cachedModuleGeometry!.transformedSlots[i],
                        context,
                        originDx,
                        originDy,
                      ),
                ],
              ),
            ),
          ),
        );

        final viewer = Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              GestureBinding.instance.pointerSignalResolver.register(
                event,
                (event) {},
              );
            }
          },
          child: ClipRect(
            child: InteractiveViewer(
              transformationController: _controller,
              constrained: false,
              minScale: 0.1,
              maxScale: 5.0,
              boundaryMargin: EdgeInsets.all(double.infinity),
              child: content,
            ),
          ),
        );

        return SizedBox(
          height: viewportHeight,
          child: Stack(
            children: [
              viewer,
              if (widget.showToolbar && widget.interactive)
                Positioned(
                  left: 4,
                  top: 4,
                  child: _compactIconButton(
                    onPressed: () =>
                        _controller.value = _computeCenteringTransform(),
                    icon: Icons.fit_screen_outlined,
                    tooltip: 'Reset zoom',
                  ),
                ),
              if (widget.showToolbar)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Row(
                    spacing: 4,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _compactIconButton(
                        onPressed: () =>
                            setState(() => _showBounds = !_showBounds),
                        icon: Icons.hexagon,
                        isActive: _showBounds,
                        tooltip: 'Show bounds',
                      ),
                      if (modules.isNotEmpty && _showModules)
                        _compactIconButton(
                          onPressed: () => setState(
                            () => _showModuleBounds = !_showModuleBounds,
                          ),
                          icon: Icons.dashboard,
                          isActive: _showModuleBounds,
                          tooltip: 'Show module bounds',
                        ),
                      if (modules.isNotEmpty)
                        _compactIconButton(
                          onPressed: () =>
                              setState(() => _showModules = !_showModules),
                          icon: Icons.extension,
                          isActive: _showModules,
                          tooltip: 'Show modules',
                        ),
                      _compactIconButton(
                        onPressed: () =>
                            setState(() => _showMounts = !_showMounts),
                        icon: Icons.location_on,
                        isActive: _showMounts,
                        tooltip: 'Show mounts',
                      ),
                      _compactIconButton(
                        onPressed: () => setState(() => _showArcs = !_showArcs),
                        icon: Icons.radar,
                        isActive: _showArcs,
                        tooltip: 'Show arcs',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
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
    bool isActive = true,
  }) {
    return isActive
        ? IconButton.filledTonal(
            onPressed: onPressed,
            icon: Icon(icon, size: 16),
            iconSize: 16,
            style: _compactButtonStyle,
            tooltip: tooltip,
          )
        : IconButton.outlined(
            onPressed: onPressed,
            icon: Icon(icon, size: 16),
            iconSize: 16,
            style: _compactButtonStyle,
            tooltip: tooltip,
          );
  }

  Widget _buildSlotHitAreaOffset(
    int index,
    ShipWeaponSlot slot,
    double imgH,
    BuildContext context,
    List<ResolvedModule> modules,
    double dx,
    double dy,
  ) {
    final pos = _slotScreenPos(slot, imgH);
    final radius = _radiusForSize(slot.size);
    final hitSize = (radius + 6) * 2;

    final hitRegion = MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: const SizedBox.expand(),
    );

    return Positioned(
      left: pos.dx - hitSize / 2 + dx,
      top: pos.dy - hitSize / 2 + dy,
      width: hitSize,
      height: hitSize,
      child: widget.showSlotTooltips
          ? MovingTooltipWidget(
              tooltipWidget: TooltipFrame(
                child: _buildSlotTooltipContent(slot, context, modules),
              ),
              child: hitRegion,
            )
          : hitRegion,
    );
  }

  Widget _buildSlotTooltipContent(
    ShipWeaponSlot slot,
    BuildContext context,
    List<ResolvedModule> modules,
  ) {
    final theme = Theme.of(context);
    final color = _colorForType(slot.type);
    final mountLabel = slot.mount.toUpperCase() == 'HARDPOINT'
        ? 'Hardpoint'
        : 'Turret';

    String? moduleName;
    if (slot.isStationModule) {
      for (final mod in modules) {
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
            Text('Module: $moduleName', style: theme.textTheme.bodySmall),
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

  Widget _buildModuleSlotHitAreaOffset(
    int index,
    _TransformedSlot ts,
    BuildContext context,
    double dx,
    double dy,
  ) {
    final radius = _radiusForSize(ts.slot.size);
    final hitSize = (radius + 6) * 2;

    final hitRegion = MouseRegion(
      onEnter: (_) => setState(() => _hoveredModuleSlotIndex = index),
      onExit: (_) => setState(() => _hoveredModuleSlotIndex = null),
      child: const SizedBox.expand(),
    );

    return Positioned(
      left: ts.screenPos.dx - hitSize / 2 + dx,
      top: ts.screenPos.dy - hitSize / 2 + dy,
      width: hitSize,
      height: hitSize,
      child: widget.showSlotTooltips
          ? MovingTooltipWidget(
              tooltipWidget: TooltipFrame(
                child: _buildModuleSlotTooltipContent(ts, context),
              ),
              child: hitRegion,
            )
          : hitRegion,
    );
  }

  Widget _buildModuleSlotTooltipContent(
    _TransformedSlot ts,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final slot = ts.slot;
    final color = _colorForType(slot.type);
    final mountLabel = slot.mount.toUpperCase() == 'HARDPOINT'
        ? 'Hardpoint'
        : 'Turret';

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
        Text(
          ts.moduleName,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
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
        Text(
          'Angle: ${ts.adjustedAngleDeg.toStringAsFixed(0)}°',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _WeaponSlotPainter extends CustomPainter {
  final List<ShipWeaponSlot> slots;
  final List<_TransformedSlot> moduleSlots;
  final double imgH;
  final List<double> center;
  final int? hoveredIndex;
  final int? hoveredModuleSlotIndex;
  final Color Function(String type) colorForType;
  final double Function(String size) radiusForSize;

  final bool showMounts;
  final bool showArcs;

  _WeaponSlotPainter({
    required this.slots,
    this.moduleSlots = const [],
    required this.imgH,
    required this.center,
    required this.hoveredIndex,
    this.hoveredModuleSlotIndex,
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

      if (showArcs && slot.arc > 0) {
        _drawFiringArc(
          canvas,
          pos,
          slot.angle,
          slot.arc,
          color,
          radius,
          isHovered,
        );
      }

      if (showMounts) {
        _drawSlotMarker(
          canvas,
          pos,
          slot.angle,
          slot,
          color,
          radius,
          isHovered,
        );
      }
    }

    // Draw module weapon slots (pre-transformed positions).
    for (var i = 0; i < moduleSlots.length; i++) {
      final ts = moduleSlots[i];
      final slot = ts.slot;
      final pos = ts.screenPos;
      final color = colorForType(slot.type);
      final radius = radiusForSize(slot.size);
      final isHovered = hoveredModuleSlotIndex == i;

      if (showArcs && slot.arc > 0) {
        _drawFiringArc(
          canvas,
          pos,
          ts.adjustedAngleDeg,
          slot.arc,
          color,
          radius,
          isHovered,
        );
      }

      if (showMounts) {
        _drawSlotMarker(
          canvas,
          pos,
          ts.adjustedAngleDeg,
          slot,
          color,
          radius,
          isHovered,
        );
      }
    }
  }

  void _drawFiringArc(
    Canvas canvas,
    Offset pos,
    double angleDeg,
    double arcDeg,
    Color color,
    double radius,
    bool isHovered,
  ) {
    final arcRadius = radius * 5;
    final arcRect = Rect.fromCircle(center: pos, radius: arcRadius);

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
    double angleDeg,
    ShipWeaponSlot slot,
    Color color,
    double radius,
    bool isHovered,
  ) {
    final isHardpoint = slot.mount.toUpperCase() == 'HARDPOINT';
    final coloredStrokeWidth = isHovered ? 2.0 : 1.2;

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

    if (showMounts && !isHardpoint) {
      final angleRad = -pi / 2 - angleDeg * (pi / 180);
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
        oldDelegate.hoveredModuleSlotIndex != hoveredModuleSlotIndex ||
        !identical(oldDelegate.slots, slots) ||
        !identical(oldDelegate.moduleSlots, moduleSlots) ||
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

  /// The bounding rect that encompasses all module sprite rects.
  /// May extend into negative coordinates relative to the parent sprite origin.
  final Rect? totalBounds;

  /// Module weapon slots pre-transformed into parent ship screen coords.
  final List<_TransformedSlot> transformedSlots;

  const _ModuleGeometry({
    required this.layouts,
    required this.rects,
    required this.polygons,
    this.totalBounds,
    this.transformedSlots = const [],
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

/// A module weapon slot with its position and angle pre-transformed into
/// the parent ship's screen coordinate space.
class _TransformedSlot {
  final ShipWeaponSlot slot;
  final Offset screenPos;
  final double adjustedAngleDeg;
  final int moduleIndex;
  final String moduleName;

  const _TransformedSlot({
    required this.slot,
    required this.screenPos,
    required this.adjustedAngleDeg,
    required this.moduleIndex,
    required this.moduleName,
  });
}
