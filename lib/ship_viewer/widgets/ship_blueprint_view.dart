import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/ship_viewer/engine_styles_manager.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/models/ship_engine_slot.dart';
import 'package:trios/ship_viewer/models/ship_engine_style_spec.dart';
import 'package:trios/ship_viewer/models/ship_weapon_slot.dart';
import 'package:trios/ship_viewer/ships_page_controller.dart';
import 'package:trios/ship_viewer/ship_module_resolver.dart';
import 'package:trios/ship_viewer/widgets/ship_codex_card.dart';
import 'package:trios/hullmod_viewer/hullmods_manager.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/ship_systems_manager/ship_system.dart';
import 'package:trios/ship_systems_manager/ship_systems_manager.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/weapons_manager.dart';
import 'package:trios/ship_viewer/utils/polygon_utils.dart';
import 'package:trios/ship_viewer/utils/sprite_utils.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart';
import 'package:trios/widgets/broken_ship_image_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/text_trios.dart';
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

  /// Whether to render turret angle indicator lines.
  final bool initialShowAngleIndicators;

  /// Whether to render built-in weapon sprites over their slots (interactive
  /// view only). The toolbar toggle for this is shown only when the ship (or
  /// a visible module) actually has built-in weapons on non-decorative slots.
  final bool initialShowWeapons;

  /// Whether to render the weapon sprites of decorative slots (interactive
  /// view only). The toolbar toggle for this is shown only when the ship (or
  /// a visible module) actually has decorative slot weapons.
  final bool initialShowDecorativeWeapons;

  /// Whether to render the additive engine glow. In the interactive view this
  /// is the toolbar toggle's initial state; thumbnails reveal glow on hover
  /// (or always, per the ships-page setting) regardless of this value.
  final bool initialShowEngineGlow;

  /// Whether to show tooltips on slot hover.
  final bool showSlotTooltips;

  /// Whether to show the path of the ship's sprite.
  final bool showPath;

  /// Whether to show the bottom-left toggle toolbar.
  final bool showToolbar;

  /// Whether zoom/pan and hover interactions are enabled.
  final bool interactive;

  /// Whether to clip non-interactive (thumbnail) content to its bounds. Set
  /// false so hovered engine glow can overflow a small grid-row cell.
  final bool clipContent;

  /// Externally forces the engine glow on (non-interactive views only), e.g.
  /// driven by WispGrid row hover so the whole row reveals the glow.
  final bool forceEngineGlow;

  /// Optional resize width in logical pixels for the decoded image cache.
  /// When set, all sprite images (parent + modules) are decoded at this
  /// width, significantly reducing memory usage for fixed-size previews
  /// (e.g. thumbnails in a grid). The aspect ratio is preserved.
  /// Has no effect when null (images are decoded at full resolution).
  final int? cacheWidth;

  /// How to fit the ship sprite within the available space when
  /// non-interactive. Defaults to [BoxFit.contain].
  final BoxFit fit;

  const ShipBlueprintView({
    super.key,
    required this.ship,
    this.initialShowModules = true,
    this.initialShowBounds = false,
    this.initialShowMounts = true,
    this.initialShowArcs = true,
    this.initialShowAngleIndicators = true,
    this.initialShowWeapons = true,
    this.initialShowDecorativeWeapons = true,
    this.initialShowEngineGlow = false,
    this.showSlotTooltips = true,
    this.showPath = true,
    this.showToolbar = true,
    this.interactive = true,
    this.clipContent = true,
    this.forceEngineGlow = false,
    this.cacheWidth,
    this.fit = BoxFit.contain,
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
    bool initialShowAngleIndicators = false,
    bool initialShowWeapons = false,
    bool initialShowDecorativeWeapons = true,
    bool initialShowEngineGlow = false,
    bool showSlotTooltips = false,
    bool showPath = false,
    bool showToolbar = false,
    bool interactive = false,
    bool clipContent = true,
    bool forceEngineGlow = false,
    int? cacheWidth,
    BoxFit fit = BoxFit.contain,
  }) {
    return ShipBlueprintView(
      key: key,
      ship: ship,
      initialShowModules: initialShowModules,
      initialShowBounds: initialShowBounds,
      initialShowMounts: initialShowMounts,
      initialShowArcs: initialShowArcs,
      initialShowAngleIndicators: initialShowAngleIndicators,
      initialShowWeapons: initialShowWeapons,
      initialShowDecorativeWeapons: initialShowDecorativeWeapons,
      initialShowEngineGlow: initialShowEngineGlow,
      showSlotTooltips: showSlotTooltips,
      showPath: showPath,
      showToolbar: showToolbar,
      interactive: interactive,
      clipContent: clipContent,
      forceEngineGlow: forceEngineGlow,
      cacheWidth: cacheWidth,
      fit: fit,
    );
  }

  @override
  ConsumerState<ShipBlueprintView> createState() => _ShipBlueprintViewState();
}

class _ShipBlueprintViewState extends ConsumerState<ShipBlueprintView>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  int? _hoveredModuleIndex;
  int? _hoveredModuleSlotIndex;
  late bool _showModules;
  late bool _showBounds;
  late bool _showMounts;
  late bool _showArcs;
  late bool _showWeapons;
  late bool _showDecoWeapons;

  /// Decoded built-in weapon sprites, keyed by file path. Filled in
  /// asynchronously as sprites finish decoding; the painter skips paths that
  /// aren't loaded yet.
  final Map<String, ui.Image> _armamentImages = {};
  final Set<String> _requestedArmamentImages = {};

  /// Toolbar toggle state (interactive view). Thumbnails ignore this and use
  /// hover / the always-on setting instead.
  late bool _showEngineGlow;
  bool _engineGlowHovering = false;
  bool _alwaysShowEngineGlow = false;

  /// Drives the engine glow fade and repaints the painter while animating.
  late final AnimationController _engineGlowController;

  /// Engine data resolved from providers each build, read by the glow overlay.
  Map<String, EngineStyleSpec> _engineStyles = const {};
  EngineGlowSprites? _engineGlowSprites;

  /// Fallback flame tint for engine styles missing from `engine_styles.json`.
  static const Color _defaultEngineColor = Color(0xFFFFA94D);
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

  /// Lookup maps for the module hover tooltip (ship codex card). Populated
  /// each build only when [ShipBlueprintView.showSlotTooltips] is set.
  Map<String, ShipSystem> _shipSystemsMap = const {};
  Map<String, Weapon> _weaponsMap = const {};
  Map<String, Hullmod> _hullmodsMap = const {};

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

  Color _colorForType(String type) => _slotColors[type] ?? Colors.white;

  double _radiusForSize(String size) =>
      _slotBaseRadius[size.toUpperCase()] ?? 5.0;

  @override
  void initState() {
    super.initState();
    _showModules = widget.initialShowModules;
    _showBounds = widget.initialShowBounds;
    _showMounts = widget.initialShowMounts;
    _showArcs = widget.initialShowArcs;
    _showWeapons = widget.initialShowWeapons;
    _showDecoWeapons = widget.initialShowDecorativeWeapons;
    _showEngineGlow = widget.initialShowEngineGlow;
    _engineGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: _showEngineGlow ? 1.0 : 0.0,
    );
    _resolveImageSize();
  }

  @override
  void dispose() {
    _engineGlowController.dispose();
    _transformController?.dispose();
    super.dispose();
  }

  /// Animate the glow toward shown. The interactive (dialog) view is driven
  /// solely by its toolbar toggle; thumbnails use hover and the ships-page
  /// "always show" setting (which deliberately doesn't affect the dialog).
  void _updateEngineGlow() {
    final show = widget.interactive
        ? _showEngineGlow
        : (_showEngineGlow ||
              _alwaysShowEngineGlow ||
              _engineGlowHovering ||
              widget.forceEngineGlow);
    _engineGlowController.animateTo(show ? 1.0 : 0.0);
  }

  @override
  void didUpdateWidget(ShipBlueprintView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ship.spriteFile != widget.ship.spriteFile) {
      _hasAppliedInitialTransform = false;
      _resolveImageSize();
    }
    if (oldWidget.forceEngineGlow != widget.forceEngineGlow) {
      _updateEngineGlow();
    }
  }

  Matrix4 _computeCenteringTransform() {
    if (_imageSize == null || _viewportWidth == null) return Matrix4.identity();

    final ship = widget.ship;
    final center = ship.center;
    // Coordinate space is the declared .ship width, not the PNG's pixel width
    // (see the note in build() where imgW/imgH are derived).
    final imgW = ship.width ?? _imageSize!.width;
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
    // Parent coordinate space is the declared .ship height, not the PNG's.
    final imgH = widget.ship.height ?? _imageSize?.height;
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
      final natSize = _moduleSizes[mod.moduleShip.id];
      if (natSize == null) continue;
      if (mod.moduleShip.spriteFile == null) continue;
      // Use the module's declared .ship width/height as its coordinate space,
      // not the PNG's pixel size. The game stretches the sprite to the declared
      // size; a few module sprites (e.g. module_bastion_pd1) have a PNG that
      // doesn't match it, so using PNG pixels would misplace the art and slots.
      final modSize = Size(
        mod.moduleShip.width ?? natSize.width,
        mod.moduleShip.height ?? natSize.height,
      );

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

      rects.add(
        angleDeg == 0
            ? Rect.fromLTWH(left, top, modSize.width, modSize.height)
            : rotatedBounds(
                left,
                top,
                modSize.width,
                modSize.height,
                angleRad,
                Offset(anchorX, anchorY),
              ),
      );
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
          moduleShip: mod.moduleShip,
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
              builtInWeaponId: mod.moduleShip.builtInWeapons?[ws.id],
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
        // Stretch to the declared module size, matching the game.
        fit: BoxFit.fill,
        errorBuilder: (_, _, _) => const BrokenShipImageWidget(),
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

  /// A transparent surface over the currently-hovered module that shows the
  /// ship codex tooltip with that module's stats. Returns null when no module
  /// is hovered. Both its placement and its visibility follow
  /// [_hoveredModuleIndex] — the same signal that highlights the sprite — so the
  /// tooltip and the highlight always target the same module.
  Widget? _buildHoveredModuleTooltip(double dx, double dy) {
    if (!widget.showSlotTooltips || !_showModules) return null;
    final index = _hoveredModuleIndex;
    final geom = _cachedModuleGeometry;
    if (index == null || geom == null || index >= geom.rects.length) {
      return null;
    }

    final rect = geom.rects[index];
    final moduleShip = geom.layouts[index].moduleShip;
    return Positioned(
      // Key by module so switching modules rebuilds the tooltip content instead
      // of reusing the previous module's card.
      key: ValueKey('module-tooltip-${moduleShip.id}'),
      left: rect.left + dx,
      top: rect.top + dy,
      width: rect.width,
      height: rect.height,
      child: ShipCodexCard.tooltip(
        ship: moduleShip,
        shipSystemsMap: _shipSystemsMap,
        weaponsMap: _weaponsMap,
        hullmodsMap: _hullmodsMap,
        child: const SizedBox.expand(),
      ),
    );
  }

  /// Lightweight widget tree for non-interactive thumbnails.
  /// Skips LayoutBuilder, TransformationController, MouseRegion, slot
  /// processing, and padding — just the ship sprite, module sprites, and
  /// (by default) decorative slot weapons.
  Widget _buildMinimalContent(
    double imgW,
    double imgH,
    List<_ArmamentRender> visibleArmaments,
    List<_ArmamentRender> reservedArmaments,
  ) {
    final parentRect = Rect.fromLTWH(0, 0, imgW, imgH);
    final geom = _cachedModuleGeometry;
    final moduleTotalBounds = (_showModules && geom?.totalBounds != null)
        ? geom!.totalBounds!
        : null;
    var combinedRect = moduleTotalBounds != null
        ? parentRect.expandToInclude(moduleTotalBounds)
        : parentRect;
    combinedRect = _expandForArmaments(combinedRect, reservedArmaments);

    final originDx = -combinedRect.left;
    final originDy = -combinedRect.top;

    final engineGlow = _engineGlowPositioned(originDx, originDy, imgW, imgH);

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
              // Stretch to the declared ship size, matching the game.
              fit: BoxFit.fill,
              errorBuilder: (_, _, _) => const BrokenShipImageWidget(),
            ),
          ),
          if (_showModules) ..._buildModuleSpritesOffset(originDx, originDy),
          ?_armamentsPositioned(
            visibleArmaments,
            originDx,
            originDy,
            imgW,
            imgH,
          ),
          ?engineGlow,
        ],
      ),
    );
  }

  /// Builds the built-in weapon sprite overlay positioned over the parent
  /// hull sprite, or null when there's nothing to draw. Shared by both
  /// render paths.
  Widget? _armamentsPositioned(
    List<_ArmamentRender> visibleArmaments,
    double originDx,
    double originDy,
    double imgW,
    double imgH,
  ) {
    if (visibleArmaments.isEmpty) return null;
    return Positioned(
      left: originDx,
      top: originDy,
      width: imgW,
      height: imgH,
      // IgnorePointer: see the engine glow overlay below.
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(imgW, imgH),
          painter: _ArmamentPainter(
            armaments: visibleArmaments,
            images: _armamentImages,
            loadedImageCount: _armamentImages.length,
          ),
        ),
      ),
    );
  }

  /// Builds the additive engine glow overlay positioned over the parent hull
  /// sprite, or null when there's nothing to draw (no glow sprites yet, no
  /// sprite center, or the hull has no engines). Shared by both render paths.
  Widget? _engineGlowPositioned(
    double originDx,
    double originDy,
    double imgW,
    double imgH,
  ) {
    final sprites = _engineGlowSprites;
    if (sprites == null) return null;
    final ship = widget.ship;
    final center = ship.center;
    if (center == null || center.length < 2) return null;
    if (ship.engineSlotsParsed.isEmpty) return null;

    return Positioned(
      left: originDx,
      top: originDy,
      width: imgW,
      height: imgH,
      // IgnorePointer: a CustomPaint with a painter absorbs hit tests by
      // default, which would block hovers meant for the module tooltip
      // surface below it in the interactive stack.
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(imgW, imgH),
          painter: _EngineGlowPainter(
            slots: ship.engineSlotsParsed,
            styles: _engineStyles,
            hullStyle: ship.style,
            flame: sprites.flame,
            glow: sprites.glow,
            imgH: imgH,
            center: center,
            opacity: _engineGlowController,
            defaultColor: _defaultEngineColor,
          ),
        ),
      ),
    );
  }

  Offset _slotScreenPos(ShipWeaponSlot slot, double imgH) {
    final center = widget.ship.center!;
    final cx = center[0];
    final cy = imgH - center[1];
    return Offset(cx - slot.locations[1], cy - slot.locations[0]);
  }

  /// Collects the built-in ("hardcoded") weapons of the parent ship and, when
  /// modules are shown, of its modules, resolved to renderable sprite data.
  /// Slots whose weapon isn't in the loaded weapons list are skipped.
  List<_ArmamentRender> _computeArmaments(
    List<ShipWeaponSlot> slots,
    double imgH,
  ) {
    if (_weaponsMap.isEmpty) return const [];
    final result = <_ArmamentRender>[];

    final builtIns = widget.ship.builtInWeapons;
    if (builtIns != null && builtIns.isNotEmpty) {
      for (final slot in slots) {
        if (slot.locations.length < 2) continue;
        if (slot.isStationModule) continue;
        // The game never renders weapon sprites in hidden slots.
        if (slot.mount.toUpperCase() == 'HIDDEN') continue;
        final weaponId = builtIns[slot.id];
        if (weaponId == null) continue;
        final weapon = _weaponsMap[weaponId];
        if (weapon == null) continue;
        final render = _ArmamentRender.build(
          weapon: weapon,
          pos: _slotScreenPos(slot, imgH),
          angleDeg: slot.angle,
          isHardpointSlot: slot.mount.toUpperCase() == 'HARDPOINT',
          isDecorative: slot.typeUppercase == 'DECORATIVE',
        );
        if (render != null) result.add(render);
      }
    }

    if (_showModules) {
      final moduleSlots =
          _cachedModuleGeometry?.transformedSlots ?? const <_TransformedSlot>[];
      for (final ts in moduleSlots) {
        final weaponId = ts.builtInWeaponId;
        if (weaponId == null) continue;
        if (ts.slot.mount.toUpperCase() == 'HIDDEN') continue;
        final weapon = _weaponsMap[weaponId];
        if (weapon == null) continue;
        final render = _ArmamentRender.build(
          weapon: weapon,
          pos: ts.screenPos,
          angleDeg: ts.adjustedAngleDeg,
          isHardpointSlot: ts.slot.mount.toUpperCase() == 'HARDPOINT',
          isDecorative: ts.slot.typeUppercase == 'DECORATIVE',
        );
        if (render != null) result.add(render);
      }
    }

    return result;
  }

  /// Expands [base] to contain every visible armament sprite (using the
  /// images decoded so far), so the view sizes itself to weapons that stick
  /// out past the hull. As more sprites decode, the rebuild grows the rect.
  Rect _expandForArmaments(Rect base, List<_ArmamentRender> armaments) {
    var rect = base;
    for (final armament in armaments) {
      final b = armament.bounds(_armamentImages);
      if (b != null) rect = rect.expandToInclude(b);
    }
    return rect;
  }

  /// Kicks off decoding of any armament sprites not yet requested. Each
  /// finished decode repaints via setState; already-loaded paths are no-ops.
  void _requestArmamentImages(List<_ArmamentRender> armaments) {
    for (final armament in armaments) {
      for (final path in armament.spritePaths) {
        if (!_requestedArmamentImages.add(path)) continue;
        loadDecodedImage(path).then((img) {
          if (img != null && mounted) {
            setState(() => _armamentImages[path] = img);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ship = widget.ship;
    final spriteFile = ship.spriteFile;
    final slots = ship.weaponSlots;
    final center = ship.center;
    final modules = ref.watch(resolvedModulesProvider(ship.id));
    final theme = context.theme;

    // Weapon lookup for the module hover tooltip and built-in weapon
    // rendering (which thumbnails use too, for decorative weapons).
    if (widget.showSlotTooltips ||
        widget.interactive ||
        _showWeapons ||
        _showDecoWeapons) {
      _weaponsMap = ref.watch(weaponsByIdProvider);
    }
    if (widget.showSlotTooltips) {
      _shipSystemsMap = {
        for (final s
            in ref.watch(shipSystemListNotifierProvider).valueOrNull ??
                const <ShipSystem>[])
          s.id: s,
      };
      _hullmodsMap = {
        for (final h
            in ref.watch(hullmodListNotifierProvider).valueOrNull ??
                const <Hullmod>[])
          h.id: h,
      };
    }

    // Engine glow inputs (cached providers; cheap after first load).
    final hasEngines = ship.engineSlotsParsed.isNotEmpty;
    if (hasEngines) {
      _engineStyles = ref.watch(engineStylesProvider).value ?? const {};
      _engineGlowSprites = ref.watch(engineGlowSpritesProvider).value;
    }

    // Pin glow on (or release to hover/toggle) when the ships-page setting flips.
    final alwaysShowEngineGlow = ref.watch(
      shipsPageControllerProvider.select((s) => s.alwaysShowEngineGlow),
    );
    if (alwaysShowEngineGlow != _alwaysShowEngineGlow) {
      _alwaysShowEngineGlow = alwaysShowEngineGlow;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateEngineGlow();
      });
    }

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

    // Ship-space size: the .ship's declared width/height, which is the unit
    // space that center, bounds, weapon slots, and engine slots are measured
    // in. Usually this equals the PNG's pixel size, but not always (e.g.
    // station1 declares 400x400 while its PNG is 440x440). The game forces the
    // sprite to the declared size, so we draw it stretched to fill (BoxFit.fill
    // below) and use these dimensions as the coordinate space everywhere.
    final imgW = ship.width ?? _imageSize!.width;
    final imgH = ship.height ?? _imageSize!.height;
    final hasCenter = center != null && center.length >= 2;

    // Built-in weapons rendered over their slots. Computed even while the
    // toggles are off so the toolbar knows whether to show the buttons.
    // Filtered in slot order (rather than one pass per kind) so overlapping
    // weapons keep the game's draw order.
    final armaments = hasCenter
        ? _computeArmaments(slots ?? const [], imgH)
        : const <_ArmamentRender>[];
    final visibleArmaments = armaments
        .where((a) => a.isDecorative ? _showDecoWeapons : _showWeapons)
        .toList();
    // In the interactive view the user can toggle each group, so reserve
    // space for every armament (loaded regardless of toggle) to keep the
    // view from resizing when a group is turned off. Thumbnails have no
    // toggle, so they only reserve space for what they actually draw.
    final reservedArmaments = widget.interactive ? armaments : visibleArmaments;
    _requestArmamentImages(reservedArmaments);

    // --- Fast path for non-interactive (thumbnail) mode ---
    if (!widget.interactive) {
      Widget content = FittedBox(
        fit: widget.fit,
        child: _buildMinimalContent(
          imgW,
          imgH,
          visibleArmaments,
          reservedArmaments,
        ),
      );
      // Optionally clip to bounds. Disabled for grid-row icons so hovered
      // engine glow can overflow the small cell instead of being cut off.
      if (widget.clipContent) {
        content = ClipRect(child: content);
      }
      Widget thumbnail = RepaintBoundary(child: content);
      // Reveal engine glow on hover (like the weapon viewer's hover glow).
      if (hasEngines && _engineGlowSprites != null && hasCenter) {
        thumbnail = MouseRegion(
          opaque: false,
          onEnter: (_) {
            _engineGlowHovering = true;
            _updateEngineGlow();
          },
          onExit: (_) {
            _engineGlowHovering = false;
            _updateEngineGlow();
          },
          child: thumbnail,
        );
      }
      return thumbnail;
    }

    final effectiveSlots = (slots != null && slots.isNotEmpty && hasCenter)
        ? slots
        : <ShipWeaponSlot>[];

    // Compute the combined bounding rect of parent sprite + all module
    // sprites so the Stack can be sized to contain everything. Module
    // sprites and armament sprites may extend beyond the parent sprite bounds.
    final parentRect = Rect.fromLTWH(0, 0, imgW, imgH);
    final geom = _cachedModuleGeometry;
    final moduleTotalBounds = (_showModules && geom?.totalBounds != null)
        ? geom!.totalBounds!
        : null;
    var combinedRect = moduleTotalBounds != null
        ? parentRect.expandToInclude(moduleTotalBounds)
        : parentRect;
    combinedRect = _expandForArmaments(combinedRect, reservedArmaments);

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
                      // Stretch to the declared ship size, matching the game.
                      fit: BoxFit.fill,
                      errorBuilder: (_, _, _) => const BrokenShipImageWidget(),
                    ),
                  ),
                  if (_showModules)
                    ..._buildModuleSpritesOffset(originDx, originDy),
                  // Built-in weapon sprites, drawn over the hull and module
                  // sprites like the game does.
                  ?_armamentsPositioned(
                    visibleArmaments,
                    originDx,
                    originDy,
                    imgW,
                    imgH,
                  ),
                  // Hover tooltip for the module under the cursor. Driven by the
                  // same detection as the highlight above, so the two always
                  // agree on which module is targeted.
                  ?_buildHoveredModuleTooltip(originDx, originDy),
                  ?_engineGlowPositioned(originDx, originDy, imgW, imgH),
                  if (_showBounds)
                    Positioned(
                      left: originDx,
                      top: originDy,
                      width: imgW,
                      height: imgH,
                      // IgnorePointer: see the engine glow overlay above.
                      child: IgnorePointer(
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
                            moduleBoundsPolygons: _showModules
                                ? (_cachedModuleGeometry?.polygons ?? const [])
                                : const [],
                          ),
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
                      // IgnorePointer: see the engine glow overlay above.
                      child: IgnorePointer(
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
                        icon: Icons.polyline,
                        isActive: _showBounds,
                        tooltip: 'Show bounds',
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
                        icon: Icons.radar,
                        isActive: _showMounts,
                        tooltip: 'Show mounts',
                      ),
                      _compactIconButton(
                        onPressed: () => setState(() => _showArcs = !_showArcs),
                        icon: Icons.signal_wifi_4_bar,
                        isActive: _showArcs,
                        tooltip: 'Show arcs',
                      ),
                      if (armaments.any((a) => !a.isDecorative))
                        _compactIconButton(
                          onPressed: () =>
                              setState(() => _showWeapons = !_showWeapons),
                          icon: Icons.gps_fixed,
                          isActive: _showWeapons,
                          tooltip: 'Show built-in weapons',
                        ),
                      if (armaments.any((a) => a.isDecorative))
                        _compactIconButton(
                          onPressed: () => setState(
                            () => _showDecoWeapons = !_showDecoWeapons,
                          ),
                          icon: Icons.brush,
                          isActive: _showDecoWeapons,
                          tooltip: 'Show decorative weapons',
                        ),
                      if (hasEngines)
                        _compactIconButton(
                          onPressed: () {
                            setState(() => _showEngineGlow = !_showEngineGlow);
                            _updateEngineGlow();
                          },
                          icon: Icons.local_fire_department,
                          isActive: _showEngineGlow,
                          tooltip: 'Show engine glow',
                        ),
                      Flexible(
                        child: TextTriOS(
                          ship.spriteFile?.split(Platform.pathSeparator).last ??
                              "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
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

  /// Resolves a built-in weapon ID to its display name, falling back to the
  /// raw ID if the weapons list hasn't loaded yet.
  String _builtInWeaponName(String weaponId) {
    final weapons = ref.read(weaponListNotifierProvider).valueOrNull;
    if (weapons != null) {
      final weapon = weapons.firstWhereOrNull((w) => w.id == weaponId);
      if (weapon?.name != null) return weapon!.name!;
    }
    return weaponId;
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

    final builtInWeaponId = widget.ship.builtInWeapons?[slot.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (builtInWeaponId != null) ...[
          Text(
            'Built-in: ${_builtInWeaponName(builtInWeaponId)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
        ],
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
            '${slot.sizeUppercase} $mountLabel',
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
    final color = _colorForType(slot.typeUppercase);
    final mountLabel = slot.mount.toUpperCase() == 'HARDPOINT'
        ? 'Hardpoint'
        : 'Turret';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ts.builtInWeaponId != null) ...[
          Text(
            'Built-in: ${_builtInWeaponName(ts.builtInWeaponId!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
        ],
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
          '${slot.sizeUppercase} $mountLabel',
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

/// A built-in weapon resolved to sprite layers, positioned on its slot.
///
/// Sprite selection follows the slot's mount: hardpoint slots use the
/// hardpoint sprite set, turrets the turret set, falling back to the other
/// set when the matching main sprite is missing.
class _ArmamentRender {
  /// Slot position in ship-space screen coordinates.
  final Offset pos;

  /// Slot facing in game convention (0 = ship forward, counterclockwise).
  final double angleDeg;

  /// Whether sprites anchor at the hardpoint pivot (1/4 of the sprite height
  /// from the bottom) instead of the sprite center. The game uses this pivot
  /// whenever the hardpoint sprite set is rendered.
  final bool hardpointAnchor;

  /// Whether this weapon sits in a decorative slot (visual embellishment
  /// rather than an actual armament); toggled separately in the toolbar.
  final bool isDecorative;

  /// Drawn below every weapon's body sprites, like the game.
  final String? underSprite;

  /// Barrel + main sprites in draw order (barrel first when the weapon has
  /// the RENDER_BARREL_BELOW hint).
  final List<String> bodySprites;

  // Loaded-missile render data (RENDER_LOADED_MISSILES), one missile per
  // fire-point offset pair.
  final String? missileSprite;
  final List<double>? missileSize;
  final List<double>? missileCenter;
  final List<double>? missileOffsets;
  final List<double>? missileAngleOffsets;

  const _ArmamentRender({
    required this.pos,
    required this.angleDeg,
    required this.hardpointAnchor,
    required this.isDecorative,
    required this.underSprite,
    required this.bodySprites,
    this.missileSprite,
    this.missileSize,
    this.missileCenter,
    this.missileOffsets,
    this.missileAngleOffsets,
  });

  /// Every sprite file this armament needs decoded.
  Iterable<String> get spritePaths => [
    ?underSprite,
    ...bodySprites,
    ?missileSprite,
  ];

  /// Axis-aligned bounds of this armament in ship-space, using the [images]
  /// decoded so far. Mirrors [_ArmamentPainter]'s placement so the view can
  /// grow to contain weapons that extend past the hull. Returns null when
  /// none of its sprites have loaded yet.
  Rect? bounds(Map<String, ui.Image> images) {
    final angle = -angleDeg * (pi / 180);
    final cosA = cos(angle);
    final sinA = sin(angle);
    // Transform an armament-local point into ship-space (rotate by the slot
    // angle about the slot position, then translate to it).
    Offset toShip(double lx, double ly) =>
        Offset(pos.dx + lx * cosA - ly * sinA, pos.dy + lx * sinA + ly * cosA);

    Rect? total;
    void include(Rect r) => total = total?.expandToInclude(r) ?? r;

    for (final path in [?underSprite, ...bodySprites]) {
      final img = images[path];
      if (img == null) continue;
      final w = img.width.toDouble();
      final h = img.height.toDouble();
      final pivotY = hardpointAnchor ? h * 0.75 : h / 2;
      // Sprite is centered in x and pivoted [pivotY] from the top, rotated
      // about the slot position — the same placement _drawAnchored paints.
      include(
        rotatedBounds(
          pos.dx - w / 2,
          pos.dy - pivotY,
          w,
          h,
          angle,
          Offset(w / 2, pivotY),
        ),
      );
    }

    final missilePath = missileSprite;
    final missileImg = missilePath == null ? null : images[missilePath];
    final layout = missileImg == null ? null : missileLayout(missileImg);
    if (layout != null) {
      for (final tube in layout.tubes) {
        final mCos = cos(-tube.angleDeg * (pi / 180));
        final mSin = sin(-tube.angleDeg * (pi / 180));
        // Missile corners in tube-draw space, then rotate by the missile
        // angle and translate by its fire offset into armament-local space.
        for (final corner in [
          Offset(-layout.pivot.dx, -layout.pivot.dy),
          Offset(layout.w - layout.pivot.dx, -layout.pivot.dy),
          Offset(layout.w - layout.pivot.dx, layout.h - layout.pivot.dy),
          Offset(-layout.pivot.dx, layout.h - layout.pivot.dy),
        ]) {
          final lx = corner.dx * mCos - corner.dy * mSin - tube.lateral;
          final ly = corner.dx * mSin + corner.dy * mCos - tube.forward;
          final p = toShip(lx, ly);
          include(Rect.fromLTWH(p.dx, p.dy, 0, 0));
        }
      }
    }

    return total;
  }

  /// Returns null when the weapon has nothing renderable for this slot.
  static _ArmamentRender? build({
    required Weapon weapon,
    required Offset pos,
    required double angleDeg,
    required bool isHardpointSlot,
    required bool isDecorative,
  }) {
    final useHardpoint = isHardpointSlot
        ? weapon.hardpointSprite != null
        : weapon.turretSprite == null && weapon.hardpointSprite != null;

    final under = useHardpoint
        ? weapon.hardpointUnderSprite
        : weapon.turretUnderSprite;
    final main = useHardpoint ? weapon.hardpointSprite : weapon.turretSprite;
    final gun = useHardpoint
        ? weapon.hardpointGunSprite
        : weapon.turretGunSprite;
    final bodySprites = <String>[
      if (weapon.renderBarrelBelow && gun != null) gun,
      ?main,
      if (!weapon.renderBarrelBelow && gun != null) gun,
    ];

    String? missileSprite;
    List<double>? missileOffsets;
    List<double>? missileAngleOffsets;
    if (weapon.renderLoadedMissiles && weapon.loadedMissileSprite != null) {
      missileSprite = weapon.loadedMissileSprite;
      missileOffsets = useHardpoint
          ? weapon.hardpointOffsets
          : weapon.turretOffsets;
      missileAngleOffsets = useHardpoint
          ? weapon.hardpointAngleOffsets
          : weapon.turretAngleOffsets;
    }

    if (under == null && bodySprites.isEmpty && missileSprite == null) {
      return null;
    }

    return _ArmamentRender(
      pos: pos,
      angleDeg: angleDeg,
      hardpointAnchor: useHardpoint,
      isDecorative: isDecorative,
      underSprite: under,
      bodySprites: bodySprites,
      missileSprite: missileSprite,
      missileSize: weapon.loadedMissileSize,
      missileCenter: weapon.loadedMissileCenter,
      missileOffsets: missileOffsets,
      missileAngleOffsets: missileAngleOffsets,
    );
  }

  /// Resolved loaded-missile geometry for [image], shared by the bounds and
  /// paint passes so they place tubes identically. The declared `.proj` size
  /// (world units) overrides the sprite's pixels, and its "center" is measured
  /// from the sprite's bottom-left. Returns null when this armament draws no
  /// loaded missiles.
  _MissileLayout? missileLayout(ui.Image image) {
    final offsets = missileOffsets;
    if (missileSprite == null || offsets == null || offsets.length < 2) {
      return null;
    }
    final declared = missileSize;
    final hasDeclared = declared != null && declared.length >= 2;
    final w = hasDeclared ? declared[0] : image.width.toDouble();
    final h = hasDeclared ? declared[1] : image.height.toDouble();
    final c = missileCenter;
    final pivot = (c != null && c.length >= 2)
        ? Offset(c[0], h - c[1])
        : Offset(w / 2, h / 2);
    final angles = missileAngleOffsets;
    final tubes = [
      for (var i = 0; i < offsets.length ~/ 2; i++)
        _MissileTube(
          forward: offsets[i * 2],
          lateral: offsets[i * 2 + 1],
          angleDeg: (angles != null && angles.length > i) ? angles[i] : 0.0,
        ),
    ];
    return _MissileLayout(w: w, h: h, pivot: pivot, tubes: tubes);
  }
}

/// One loaded-missile fire point in weapon-local space: +[forward] along the
/// barrel, +[lateral] to the weapon's left, rotated by [angleDeg].
class _MissileTube {
  final double forward;
  final double lateral;
  final double angleDeg;

  const _MissileTube({
    required this.forward,
    required this.lateral,
    required this.angleDeg,
  });
}

/// Drawn size ([w]×[h]), draw-origin [pivot] within that size, and one entry
/// per fire point for a weapon's loaded missiles.
class _MissileLayout {
  final double w;
  final double h;
  final Offset pivot;
  final List<_MissileTube> tubes;

  const _MissileLayout({
    required this.w,
    required this.h,
    required this.pivot,
    required this.tubes,
  });
}

/// Draws built-in weapon sprites over their slots, matching the game's
/// at-rest rendering: 1 sprite pixel = 1 ship unit, turrets pivot on the
/// sprite center, hardpoints pivot 1/4 of the sprite height from the bottom,
/// rotated to the slot's angle.
class _ArmamentPainter extends CustomPainter {
  final List<_ArmamentRender> armaments;
  final Map<String, ui.Image> images;

  /// Repaint key: [images] is mutated in place as decodes finish, so the
  /// count stands in for its contents.
  final int loadedImageCount;

  _ArmamentPainter({
    required this.armaments,
    required this.images,
    required this.loadedImageCount,
  });

  static final Paint _spritePaint = Paint()..filterQuality = FilterQuality.high;

  @override
  void paint(Canvas canvas, Size size) {
    // The game draws every weapon's under-sprite below all weapon bodies,
    // not just below its own.
    for (final armament in armaments) {
      final under = armament.underSprite;
      if (under != null) {
        _drawAnchored(canvas, images[under], armament);
      }
    }
    for (final armament in armaments) {
      for (final path in armament.bodySprites) {
        _drawAnchored(canvas, images[path], armament);
      }
      _drawLoadedMissiles(canvas, armament);
    }
  }

  /// Draws [image] with its mount pivot at the slot position, rotated to the
  /// slot angle. Sprite art points up; game angles are counterclockwise, so
  /// the screen rotation is the negated angle.
  void _drawAnchored(Canvas canvas, ui.Image? image, _ArmamentRender armament) {
    if (image == null) return;
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    final pivotY = armament.hardpointAnchor ? h * 0.75 : h / 2;

    canvas.save();
    canvas.translate(armament.pos.dx, armament.pos.dy);
    if (armament.angleDeg != 0) {
      canvas.rotate(-armament.angleDeg * (pi / 180));
    }
    canvas.drawImage(image, Offset(-w / 2, -pivotY), _spritePaint);
    canvas.restore();
  }

  /// Draws one loaded missile per fire-point offset, on top of the weapon.
  /// Offsets are weapon-local: +x along the barrel (screen up before
  /// rotation), +y to the weapon's left.
  void _drawLoadedMissiles(Canvas canvas, _ArmamentRender armament) {
    final spritePath = armament.missileSprite;
    if (spritePath == null) return;
    final image = images[spritePath];
    if (image == null) return;
    final layout = armament.missileLayout(image);
    if (layout == null) return;

    final natW = image.width.toDouble();
    final natH = image.height.toDouble();

    canvas.save();
    canvas.translate(armament.pos.dx, armament.pos.dy);
    if (armament.angleDeg != 0) {
      canvas.rotate(-armament.angleDeg * (pi / 180));
    }
    for (final tube in layout.tubes) {
      canvas.save();
      canvas.translate(-tube.lateral, -tube.forward);
      if (tube.angleDeg != 0) canvas.rotate(-tube.angleDeg * (pi / 180));
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, natW, natH),
        Rect.fromLTWH(-layout.pivot.dx, -layout.pivot.dy, layout.w, layout.h),
        _spritePaint,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArmamentPainter oldDelegate) =>
      !identical(oldDelegate.armaments, armaments) ||
      oldDelegate.loadedImageCount != loadedImageCount;
}

/// Draws each engine slot's flame + round base glow, additively tinted by the
/// engine style color. Mirrors how the weapon viewer renders glow sprites.
class _EngineGlowPainter extends CustomPainter {
  final List<ShipEngineSlot> slots;
  final Map<String, EngineStyleSpec> styles;
  final String? hullStyle;
  final ui.Image flame;
  final ui.Image glow;
  final double imgH;
  final List<double> center;

  /// Current glow fade, 0 (hidden) to 1 (full). Drives repaint while animating.
  final Animation<double> opacity;
  final Color defaultColor;

  _EngineGlowPainter({
    required this.slots,
    required this.styles,
    required this.hullStyle,
    required this.flame,
    required this.glow,
    required this.imgH,
    required this.center,
    required this.opacity,
    required this.defaultColor,
  }) : super(repaint: opacity);

  EngineStyleSpec? _specFor(ShipEngineSlot s) => styles[s.style ?? hullStyle];

  @override
  void paint(Canvas canvas, Size size) {
    final op = opacity.value;
    if (op <= 0) return;

    final cx = center[0];
    final cy = imgH - center[1];

    final flameSrc = Rect.fromLTWH(
      0,
      0,
      flame.width.toDouble(),
      flame.height.toDouble(),
    );
    final glowSrc = Rect.fromLTWH(
      0,
      0,
      glow.width.toDouble(),
      glow.height.toDouble(),
    );

    for (final s in slots) {
      // Same ship-space → screen transform as the weapon slot markers.
      final pos = Offset(cx - s.location[1], cy - s.location[0]);

      final spec = _specFor(s);
      final paint = _engineGlowPaint(spec?.engineColor ?? defaultColor, op);

      final engineWidth = s.width > 0 ? s.width : 10.0;
      final maxLength = s.length > 0
          ? s.length
          : (s.contrailSize ?? engineWidth * 4);
      // The `.ship` length is the full-burn flame length (e.g. 64px on an 80px
      // hull). We render engines at rest, so use a fraction of it. We also
      // ignore glowSizeMult — styles like COBRA_BOMBER (3.5) otherwise dwarf
      // small hulls (drone_terminator, armaa_guppy).
      final flameLength = maxLength * 0.55;
      final flameWidth = engineWidth * 0.9;

      // The flame sprite points +x (base at left), so rotating the canvas to
      // the slot's facing aims it outward. angle 180 = aft = downward here.
      final phi = -pi / 2 - s.angle * (pi / 180);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(phi);

      // Round bloom at the nozzle, sized off the engine width.
      final g = engineWidth * 0.95;
      canvas.drawImageRect(
        glow,
        glowSrc,
        Rect.fromCenter(center: Offset.zero, width: g, height: g),
        paint,
      );

      // Flame extending outward from the nozzle along +x (post-rotation).
      canvas.drawImageRect(
        flame,
        flameSrc,
        Rect.fromLTWH(
          -flameLength * 0.1,
          -flameWidth / 2,
          flameLength * 1.1,
          flameWidth,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_EngineGlowPainter oldDelegate) =>
      !identical(oldDelegate.slots, slots) ||
      !identical(oldDelegate.flame, flame) ||
      !identical(oldDelegate.glow, glow) ||
      oldDelegate.defaultColor != defaultColor;
}

/// Additive glow paint, scaled by [op] (0–1) so the glow can fade in/out.
Paint _engineGlowPaint(Color tint, double op) => Paint()
  ..blendMode = BlendMode.plus
  ..filterQuality = FilterQuality.high
  ..colorFilter = ColorFilter.mode(
    Color.from(
      alpha: tint.a * op,
      red: tint.r * op,
      green: tint.g * op,
      blue: tint.b * op,
    ),
    BlendMode.modulate,
  );

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

  /// The module ship this sprite represents, used for the hover tooltip.
  final Ship moduleShip;

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
    required this.moduleShip,
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
  final String? builtInWeaponId;

  const _TransformedSlot({
    required this.slot,
    required this.screenPos,
    required this.adjustedAngleDeg,
    required this.moduleIndex,
    required this.moduleName,
    this.builtInWeaponId,
  });
}
