import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/ship_viewer/engine_styles_manager.dart';
import 'package:trios/ship_viewer/hull_styles_manager.dart';
import 'package:trios/ship_viewer/ship_blueprint_view_state.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/settings/app_settings_logic.dart';
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
import 'package:trios/utils/logging.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/utils/extensions.dart';
import 'package:trios/widgets/broken_ship_image_widget.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/overflow_menu_button.dart';
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

  /// Whether to render the ship's shield (interactive view only). This is the
  /// toolbar toggle's initial state; the toggle only appears for ships that
  /// actually have a FRONT or OMNI shield.
  final bool initialShowShield;

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
    this.initialShowShield = false,
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
    with TickerProviderStateMixin {
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

  /// Loops once a second to scroll the flame texture, which is what makes the
  /// flames flicker. Only runs while the glow is showing and TriOS is the
  /// window in front — otherwise it's a repaint every frame for nothing.
  late final AnimationController _engineFlickerController;
  bool _windowFocused = true;

  /// Engine data resolved from providers each build, read by the glow overlay.
  Map<String, EngineStyleSpec> _engineStyles = const {};
  EngineGlowSprites? _engineGlowSprites;

  /// Toolbar toggle state (interactive view) for the shield overlay.
  late bool _showShield;

  /// Whether shields animate, toggled from the blueprint view's own overflow
  /// menu and saved across restarts. When off, the shield is drawn as a single
  /// still frame.
  bool _animateShields = true;

  /// Loops once every 16 seconds. Drives both the shield fill's slow spin and
  /// the edge ring's ripple. Only runs while a shield is showing, animation is
  /// on, and TriOS is the window in front.
  late final AnimationController _shieldClockController;

  /// Shield data resolved from providers each build, read by the overlay.
  Map<String, ShieldStyleColors> _shieldColors = const {};
  ShieldSprites? _shieldSprites;

  /// Fallback flame tint for engine styles missing from `engine_styles.json`.
  static const Color _defaultEngineColor = Color(0xFFFFA94D);

  /// Zoom limits, shared by the viewer and the "reset zoom" fit.
  static const double _minScale = 0.1;
  static const double _maxScale = 5.0;
  Size? _imageSize;
  double? _viewportWidth;
  double? _viewportHeight;

  /// Size of everything drawn in the viewer — hull, modules, built-in weapon
  /// sprites, and the arc padding around them — in ship-space units.
  Size? _contentSize;

  /// The [_contentSize] the view was last centered for. Module and weapon
  /// sprites decode after the first frame and grow the content, so we
  /// re-center when this goes stale.
  Size? _centeredForContentSize;

  /// The transform we last applied ourselves. Once the controller has moved
  /// away from it the user has panned or zoomed, and we stop auto-centering.
  Matrix4? _lastAppliedTransform;
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
    // The interactive view remembers its shown layers across restarts, shared
    // by every place it's used. Thumbnails aren't interactive and just use
    // their constructor values.
    if (widget.interactive) {
      final saved = ref.read(appSettings).shipBlueprintViewState;
      _showModules = saved.showModules;
      _showBounds = saved.showBounds;
      _showMounts = saved.showMounts;
      _showArcs = saved.showArcs;
      _showWeapons = saved.showWeapons;
      _showDecoWeapons = saved.showDecorativeWeapons;
      _showEngineGlow = saved.showEngineGlow;
      _showShield = saved.showShield;
      _animateShields = saved.animateShields;
    } else {
      _showModules = widget.initialShowModules;
      _showBounds = widget.initialShowBounds;
      _showMounts = widget.initialShowMounts;
      _showArcs = widget.initialShowArcs;
      _showWeapons = widget.initialShowWeapons;
      _showDecoWeapons = widget.initialShowDecorativeWeapons;
      _showEngineGlow = widget.initialShowEngineGlow;
      _showShield = widget.initialShowShield;
    }
    _engineGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: _showEngineGlow ? 1.0 : 0.0,
    );
    _engineFlickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    // Catches the end of a fade-out, which no rebuild would tell us about.
    _engineGlowController.addStatusListener((_) => _updateEngineFlicker());
    _shieldClockController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _resolveImageSize();
  }

  /// Saves the interactive view's shown layers (and the shield animation
  /// setting) so they come back the same next time — anywhere the view is used.
  /// No-op for thumbnails, which aren't user-configurable.
  void _persistBlueprintState() {
    if (!widget.interactive) return;
    try {
      ref.read(appSettings.notifier).update(
        (s) => s.copyWith(
          shipBlueprintViewState: ShipBlueprintViewState(
            showModules: _showModules,
            showBounds: _showBounds,
            showMounts: _showMounts,
            showArcs: _showArcs,
            showWeapons: _showWeapons,
            showDecorativeWeapons: _showDecoWeapons,
            showEngineGlow: _showEngineGlow,
            showShield: _showShield,
            animateShields: _animateShields,
          ),
        ),
      );
    } catch (e, st) {
      Fimber.w('Failed to persist ship blueprint view state', ex: e, stacktrace: st);
    }
  }

  /// Applies a toolbar toggle and saves the new choice.
  void _toggleLayer(VoidCallback mutate) {
    setState(mutate);
    _persistBlueprintState();
  }

  @override
  void dispose() {
    _engineGlowController.dispose();
    _engineFlickerController.dispose();
    _shieldClockController.dispose();
    _transformController?.dispose();
    super.dispose();
  }

  /// Runs the shield clock only while a shield is on screen, animation is on,
  /// and TriOS is in front.
  void _updateShieldClock() {
    final shouldRun = _showShield && _animateShields && _windowFocused;
    if (shouldRun == _shieldClockController.isAnimating) return;
    if (shouldRun) {
      _shieldClockController.repeat();
    } else {
      _shieldClockController.stop();
    }
  }

  /// Runs the flicker only while there's a flame on screen and TriOS is in
  /// front.
  void _updateEngineFlicker() {
    final shouldRun = _windowFocused && _engineGlowController.value > 0;
    if (shouldRun == _engineFlickerController.isAnimating) return;
    if (shouldRun) {
      _engineFlickerController.repeat();
    } else {
      _engineFlickerController.stop();
    }
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
    _updateEngineFlicker();
  }

  @override
  void didUpdateWidget(ShipBlueprintView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ship.spriteFile != widget.ship.spriteFile) {
      _centeredForContentSize = null;
      _lastAppliedTransform = null;
      _resolveImageSize();
    }
    if (oldWidget.forceEngineGlow != widget.forceEngineGlow) {
      _updateEngineGlow();
    }
  }

  /// Fits everything the viewer draws into the viewport and centers it.
  ///
  /// This uses the whole drawn area, not just the hull sprite: on ships with
  /// modules (e.g. `ii_battlestation`) the modules can stick out well past the
  /// hull, so centering the hull alone leaves the picture visibly off to one
  /// side.
  ///
  /// Anything that fits is shown at 1:1; bigger stations are zoomed out just
  /// enough to fit, rather than having their edges cut off. We never zoom in
  /// past 1:1, so small ships aren't blown up to fill the space.
  Matrix4 _computeCenteringTransform() {
    final content = _contentSize;
    final viewportWidth = _viewportWidth;
    final viewportHeight = _viewportHeight;
    if (content == null || viewportWidth == null || viewportHeight == null) {
      return Matrix4.identity();
    }
    if (content.width <= 0 || content.height <= 0) return Matrix4.identity();

    final scale = min(
      1.0,
      min(viewportWidth / content.width, viewportHeight / content.height),
    ).clamp(_minScale, 1.0);

    return Matrix4.identity()
      ..translateByDouble(
        (viewportWidth - content.width * scale) / 2,
        (viewportHeight - content.height * scale) / 2,
        0.0,
        1.0,
      )
      ..scaleByDouble(scale, scale, scale, 1.0);
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

    return SizedBox(
      width: combinedRect.width,
      height: combinedRect.height,
      child: Stack(
        children: [
          // Particle contrails go under the hull sprite, like the game.
          ?_engineGlowPositioned(originDx, originDy, imgW, imgH,
              underHull: true),
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
          ?_engineGlowPositioned(originDx, originDy, imgW, imgH,
              underHull: false),
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

  /// Builds one layer of the engine glow overlay, or null when there's nothing
  /// to draw (no glow sprites yet, no sprite center, or the hull has no
  /// engines). Called twice per render path: once with [underHull] true,
  /// placed under the hull sprite (particle contrails render below ships in
  /// the game), and once with it false, placed over the sprite (flames,
  /// blooms, and ribbon contrails). The under-hull layer is skipped entirely
  /// when engine trails are turned off, since trails are all it draws.
  Widget? _engineGlowPositioned(
    double originDx,
    double originDy,
    double imgW,
    double imgH, {
    required bool underHull,
  }) {
    final sprites = _engineGlowSprites;
    if (sprites == null) return null;
    final showTrails = ref.watch(
      appSettings.select((s) => s.showEngineTrails),
    );
    if (underHull && !showTrails) return null;
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
            sprites: sprites,
            imgH: imgH,
            center: center,
            isFighter: ship.hullSize?.toUpperCase() == 'FIGHTER',
            maxSpeed: ship.maxSpeed,
            opacity: _engineGlowController,
            flicker: _engineFlickerController,
            defaultColor: _defaultEngineColor,
            underHull: underHull,
            showTrails: showTrails,
          ),
        ),
      ),
    );
  }

  /// Whether [ship] has a shield worth drawing: a FRONT or OMNI shield with a
  /// real radius, and the sprite center/shield center needed to place it.
  bool _shipHasShield(Ship ship) {
    final type = ship.shieldType?.toUpperCase();
    if (type != 'FRONT' && type != 'OMNI') return false;
    final radius = ship.shieldRadius;
    if (radius == null || radius <= 0) return false;
    if (ship.shieldCenter == null || ship.shieldCenter!.length < 2) return false;
    return ship.center != null && ship.center!.length >= 2;
  }

  /// Builds the shield overlay positioned over the parent hull sprite, or null
  /// when there's nothing to draw (toggle off, no shield, or textures not
  /// decoded yet).
  Widget? _shieldPositioned(
    double originDx,
    double originDy,
    double imgW,
    double imgH,
  ) {
    if (!_showShield) return null;
    final ship = widget.ship;
    if (!_shipHasShield(ship)) return null;
    final sprites = _shieldSprites;
    if (sprites == null) return null;

    final colors =
        _shieldColors[ship.style?.toUpperCase()] ?? ShieldStyleColors.fallback;
    final radius = ship.shieldRadius!;
    // The game draws a thinner ring on small hulls.
    final hullSize = ship.hullSize?.toUpperCase();
    final ringThickness = hullSize == 'FIGHTER'
        ? 3.0
        : hullSize == 'FRIGATE'
        ? 4.0
        : 5.0;

    return Positioned(
      left: originDx,
      top: originDy,
      width: imgW,
      height: imgH,
      // IgnorePointer: see the engine glow overlay above.
      child: IgnorePointer(
        child: CustomPaint(
          size: Size(imgW, imgH),
          painter: _ShieldPainter(
            center: ship.center!,
            imgH: imgH,
            shieldCenter: ship.shieldCenter!,
            radius: radius,
            arcDegrees: ship.shieldArc ?? 30,
            colors: colors,
            fillImage: sprites.fillForRadius(radius),
            ringImage: sprites.ring,
            ringThickness: ringThickness,
            clock: _animateShields ? _shieldClockController : null,
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
      // Every mod, enabled or not: this only resolves weapon ids the ship
      // already names, for tooltips and built-in weapon art.
      _weaponsMap = ref.watch(weaponsByIdProvider(false));
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

    // Engine glow and shield inputs (cached providers; cheap after first load).
    final hasEngines = ship.engineSlotsParsed.isNotEmpty;
    final hasShield = _shipHasShield(ship);
    if (hasEngines) {
      _engineStyles = ref.watch(engineStylesProvider).value ?? const {};
      _engineGlowSprites = ref.watch(engineGlowSpritesProvider).value;
    }
    if (hasShield) {
      _shieldColors =
          ref.watch(hullStyleShieldColorsProvider).value ?? const {};
      _shieldSprites = ref.watch(shieldSpritesProvider).value;
    }

    // Pause the engine flicker and the shield clock while TriOS is behind
    // another window — they'd otherwise repaint every frame for nothing.
    if (hasEngines || hasShield) {
      final focused = ref.watch(AppState.isWindowFocused);
      if (focused != _windowFocused) _windowFocused = focused;
    }
    if (hasEngines) _updateEngineFlicker();
    if (hasShield) _updateShieldClock();

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

    // The padding below sits outside the Stack, so the drawn area is the
    // combined rect grown by `pad` on every side.
    _contentSize = Size(totalW + pad * 2, totalH + pad * 2);

    final viewportHeight = (totalH + pad * 2).clamp(0.0, 500.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportChanged =
            _viewportWidth != constraints.maxWidth ||
            _viewportHeight != viewportHeight;
        _viewportWidth = constraints.maxWidth;
        _viewportHeight = viewportHeight;

        // Re-center when the viewport resizes, and — as long as the user
        // hasn't panned or zoomed — whenever the content changes size, since
        // module and weapon sprites decode after the first frame and grow it.
        final untouched =
            _lastAppliedTransform == null ||
            _controller.value == _lastAppliedTransform;
        if (viewportChanged ||
            (untouched && _centeredForContentSize != _contentSize)) {
          _centeredForContentSize = _contentSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _controller.value = _lastAppliedTransform =
                  _computeCenteringTransform();
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
                  // Particle contrails go under the hull sprite, like the
                  // game.
                  ?_engineGlowPositioned(originDx, originDy, imgW, imgH,
                      underHull: true),
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
                  ?_engineGlowPositioned(originDx, originDy, imgW, imgH,
                      underHull: false),
                  // Shield sits over the ship like in the game, but under the
                  // blueprint's own mount/bounds markers so they stay readable.
                  ?_shieldPositioned(originDx, originDy, imgW, imgH),
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
              minScale: _minScale,
              maxScale: _maxScale,
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
                    onPressed: () {
                      _centeredForContentSize = _contentSize;
                      _controller.value = _lastAppliedTransform =
                          _computeCenteringTransform();
                    },
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
                      if (hasShield) _buildBlueprintOverflowMenu(),
                      _compactIconButton(
                        onPressed: () =>
                            _toggleLayer(() => _showBounds = !_showBounds),
                        icon: Icons.polyline,
                        isActive: _showBounds,
                        tooltip: 'Show bounds',
                      ),
                      if (modules.isNotEmpty)
                        _compactIconButton(
                          onPressed: () =>
                              _toggleLayer(() => _showModules = !_showModules),
                          icon: Icons.extension,
                          isActive: _showModules,
                          tooltip: 'Show modules',
                        ),
                      _compactIconButton(
                        onPressed: () =>
                            _toggleLayer(() => _showMounts = !_showMounts),
                        icon: Icons.radar,
                        isActive: _showMounts,
                        tooltip: 'Show mounts',
                      ),
                      _compactIconButton(
                        onPressed: () =>
                            _toggleLayer(() => _showArcs = !_showArcs),
                        icon: Icons.signal_wifi_4_bar,
                        isActive: _showArcs,
                        tooltip: 'Show arcs',
                      ),
                      if (armaments.any((a) => !a.isDecorative))
                        _compactIconButton(
                          onPressed: () =>
                              _toggleLayer(() => _showWeapons = !_showWeapons),
                          icon: Icons.gps_fixed,
                          isActive: _showWeapons,
                          tooltip: 'Show built-in weapons',
                        ),
                      if (armaments.any((a) => a.isDecorative))
                        _compactIconButton(
                          onPressed: () => _toggleLayer(
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
                            _persistBlueprintState();
                          },
                          icon: Icons.local_fire_department,
                          isActive: _showEngineGlow,
                          tooltip: 'Show engine glow',
                        ),
                      if (hasShield)
                        _compactIconButton(
                          onPressed: () {
                            setState(() => _showShield = !_showShield);
                            _updateShieldClock();
                            _persistBlueprintState();
                          },
                          icon: Icons.shield_outlined,
                          isActive: _showShield,
                          tooltip: 'Show shields',
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

  /// The blueprint view's own three-dot menu. Holds the "Animate shields"
  /// toggle (and is a home for any future view options).
  Widget _buildBlueprintOverflowMenu() {
    return SizedBox(
      width: 30,
      child: OverflowMenuButton(
        iconSize: 16,
        menuItems: [
          OverflowMenuCheckItem(
            title: 'Animate shields',
            icon: Icons.shield_outlined,
            checked: _animateShields,
            onTap: () {
              setState(() => _animateShields = !_animateShields);
              _updateShieldClock();
              _persistBlueprintState();
            },
          ).toEntry(0),
        ],
      ),
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
    final weapons = ref.read(weaponListNotifierProvider(false)).valueOrNull;
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

/// Draws each engine slot's flame and the round bloom at its nozzle, the same
/// way the game does in combat (`com.fs.starfarer.combat.entities.G`).
///
/// Per slot the game draws the flame sprite several times over, each pass
/// narrower and longer than the last, with the brightness ramping from nearly
/// nothing at the nozzle up to full a short way out and back down to nothing at
/// the tip. Non-fighters then get a teardrop outline laid faintly over the top.
/// Last comes a round bloom over the nozzle in the engine colour, with a smaller
/// white one on top of it. That white core is what makes a flame look hot.
///
/// The game has two paths: fighters go through `G.class(float)`, everything else
/// through `G.o00000(float)`. They differ in the pass count, how bright the
/// flame gets, and whether there's an outline.
class _EngineGlowPainter extends CustomPainter {
  final List<ShipEngineSlot> slots;
  final Map<String, EngineStyleSpec> styles;
  final String? hullStyle;
  final EngineGlowSprites sprites;
  final double imgH;
  final List<double> center;

  /// True when the hull is a fighter. The game shrinks their bloom.
  final bool isFighter;

  /// The hull's top speed. Contrail length comes from it: particles fall
  /// behind a ship at cruise. Null or zero (stations) means no contrail —
  /// same as the game, where a ship that isn't moving leaves no trail.
  final double? maxSpeed;

  /// Current glow fade, 0 (hidden) to 1 (full). Drives repaint while animating.
  final Animation<double> opacity;

  /// Loops 0 → 1 once a second. The game scrolls the flame texture sideways at
  /// this rate, which is where the flicker comes from. Null holds it still.
  final Animation<double>? flicker;
  final Color defaultColor;

  /// Which layer this painter draws. The game splits contrails across the
  /// ship sprite: particle trails render below ships, ribbon trails (and the
  /// flames themselves) above. One painter instance goes under the hull
  /// sprite in the stack and draws only particle trails; the other goes over
  /// it and draws everything else.
  final bool underHull;

  /// Whether to draw engine trails at all. Off by default, behind a setting
  /// in Debug Settings.
  final bool showTrails;

  _EngineGlowPainter({
    required this.slots,
    required this.styles,
    required this.hullStyle,
    required this.sprites,
    required this.imgH,
    required this.center,
    required this.isFighter,
    required this.maxSpeed,
    required this.opacity,
    required this.flicker,
    required this.defaultColor,
    required this.underHull,
    required this.showTrails,
  }) : super(repaint: Listenable.merge([opacity, flicker]));

  /// How hard the engines are running, 0 (idle) to 1 (full burn). The game
  /// varies this; we show a steady mid-burn.
  static const double _throttle = 0.6;

  /// Resolves a slot's engine style the way the game's hull loader does:
  /// the `style` name looks up the merged styles map (unknown names are
  /// treated as style ids, so this also covers mods that put their own id
  /// straight in `style`); `CUSTOM` slots fall through to `styleId`, then to
  /// a style written inline in the `.ship` file.
  EngineStyleSpec? _specFor(ShipEngineSlot s) =>
      styles[s.style ?? hullStyle] ?? styles[s.styleId] ?? s.styleSpec;

  @override
  void paint(Canvas canvas, Size size) {
    final op = opacity.value;
    if (op <= 0) return;

    final cx = center[0];
    final cy = imgH - center[1];
    final scroll = flicker?.value ?? 0.0;

    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];
      // Same ship-space → screen transform as the weapon slot markers.
      final pos = Offset(cx - s.location[1], cy - s.location[0]);

      final spec = _specFor(s);
      final tint = spec?.engineColor ?? defaultColor;

      // The game requires both in a .ship file, so the fallbacks almost never
      // fire. (`contrailSize` is NOT a length — the game only checks it
      // against 128/256 as a legacy flag.)
      final engineWidth = s.width > 0 ? s.width : 10.0;
      final maxLength = s.length > 0 ? s.length : engineWidth * 4;

      // The `.ship` numbers are the full-burn size. The game scales length by
      // 0.2 + 0.8 × throttle and width by 0.1 + 0.9 × throttle.
      final flameLength = maxLength * (0.2 + 0.8 * _throttle);
      final flameWidth = engineWidth * (0.1 + 0.9 * _throttle);
      if (flameLength <= 0 || flameWidth <= 0) continue;

      // Distance from the nozzle to the brightest point of the flame.
      final shoulder = min(flameWidth / 2, flameLength / 4);

      // The flame points along +x once the canvas is rotated to the slot's
      // facing. angle 180 = aft, which is downward here.
      final phi = -pi / 2 - s.angle * (pi / 180);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);

      // Contrail first, so the flame and bloom draw over its head. Drawn
      // before the rotate: a particle's own drift follows the engine's angle,
      // but the ship flies out from under it along its facing — straight aft
      // on screen — and that second part doesn't rotate with the slot.
      // Which contrail kind this pass draws is decided inside, by [underHull].
      _paintContrail(
        canvas,
        spec: spec,
        slot: s,
        slotIndex: i,
        alphaMult: op,
        slotAngle: phi,
        scroll: scroll,
      );

      // The under-hull pass carries only particle trails.
      if (underHull) {
        canvas.restore();
        continue;
      }

      canvas.rotate(phi);

      // Each slot starts its texture scroll at a different place so nearby
      // engines don't flicker in lockstep. Fixed per slot, not random, so a
      // repaint doesn't make the flames jump.
      final slotOffset = (i * 0.37) % 1.0;
      // Fighters get a plain three-pass flame. Everything else gets six thinner
      // passes with an outline laid over them, and Omega engines get one wide
      // pass stamped twice instead.
      final omega = spec?.omegaMode ?? false;
      final passes = isFighter
          ? 3
          : omega
          ? 1
          : 6;
      final stamps = omega ? 2 : 1;
      // Fighters burn their flame to full at the shoulder; other ships only
      // reach 100/255 there, because the outline fills in the rest.
      final shoulderAlpha = isFighter ? 1.0 : 100 / 255;

      // A style can name its own flame and outline sprites. Fall back to the
      // defaults when we can't find one, so a bad path dims the flame rather
      // than deleting it. The outline is the exception: a style that points at
      // a blank sprite (THREAT uses `empty.png`) means "no outline", and the
      // sprite index skips files it can't read, so treat missing as blank.
      final defaultFlame = (spec?.isSmoke ?? false)
          ? sprites.flameSmoke
          : sprites.flameGlow;
      final customFlame = spec?.glowSprite;
      final flameImage =
          (customFlame != null ? sprites.custom[customFlame] : null) ??
          defaultFlame;
      final customOutline = spec?.glowOutline;
      final outlineImage = customOutline != null
          ? sprites.custom[customOutline]
          : sprites.outline;

      for (var stamp = 0; stamp < stamps; stamp++) {
        _paintFlame(
          canvas,
          image: flameImage,
          tint: tint,
          alphaMult: op,
          length: flameLength,
          width: flameWidth,
          shoulder: shoulder,
          scrollStart: slotOffset - scroll,
          passes: passes,
          shoulderAlpha: shoulderAlpha,
        );
      }

      if (!isFighter && outlineImage != null) {
        _paintOutline(
          canvas,
          image: outlineImage,
          tint: tint,
          alphaMult: op,
          length: flameLength,
          width: flameWidth,
        );
      }

      _paintBloom(
        canvas,
        tint: spec?.glowAlternateColor ?? tint,
        alphaMult: op,
        flameWidth: flameWidth,
        sizeMult: spec?.glowSizeMult ?? 1.0,
      );

      canvas.restore();
    }
  }

  /// Draws the flame body: [passes] stacked quad strips, brightness ramping
  /// nozzle → shoulder → tip.
  void _paintFlame(
    Canvas canvas, {
    required ui.Image image,
    required Color tint,
    required double alphaMult,
    required double length,
    required double width,
    required double shoulder,
    required double scrollStart,
    required int passes,
    required double shoulderAlpha,
  }) {
    final texW = image.width.toDouble();
    final texH = image.height.toDouble();
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..filterQuality = FilterQuality.high
      ..shader = ui.ImageShader(
        image,
        TileMode.repeated,
        TileMode.clamp,
        Matrix4.identity().storage,
      );

    // Texture rows to sample. Staying a hair inside the edges avoids picking up
    // the transparent border, same as the game does.
    final vTop = 0.01 * texH;
    final vBottom = 0.99 * texH;

    var u = scrollStart;
    for (var pass = 0; pass < passes; pass++) {
      final halfWidth = width / 2;
      final uShoulder = u + shoulder / length;
      final uTip = u + _throttle;

      final positions = Float32List.fromList([
        0,
        -halfWidth,
        0,
        halfWidth,
        shoulder,
        -halfWidth,
        shoulder,
        halfWidth,
        length,
        -halfWidth,
        length,
        halfWidth,
      ]);
      final texCoords = Float32List.fromList([
        u * texW,
        vTop,
        u * texW,
        vBottom,
        uShoulder * texW,
        vTop,
        uShoulder * texW,
        vBottom,
        uTip * texW,
        vTop,
        uTip * texW,
        vBottom,
      ]);

      // Nearly dark at the nozzle, full at the shoulder, gone at the tip.
      final atNozzle = _dimmedInt(tint, pass * 5 / 255 * alphaMult);
      final atShoulder = _dimmedInt(tint, shoulderAlpha * alphaMult);
      final atTip = _dimmedInt(tint, 0);
      final colors = Int32List.fromList([
        atNozzle,
        atNozzle,
        atShoulder,
        atShoulder,
        atTip,
        atTip,
      ]);

      canvas.save();
      // Nudge each pass forward and squash it: later passes are narrower and
      // reach further, which is what gives the flame its tapered core.
      canvas.translate((passes - pass - 1) * shoulder / (passes * 2), 0);
      canvas.scale(0.5 + 0.5 * (pass + 1) / passes, (passes - pass) / passes);
      canvas.drawVertices(
        ui.Vertices.raw(
          VertexMode.triangleStrip,
          positions,
          textureCoordinates: texCoords,
          colors: colors,
        ),
        BlendMode.modulate,
        paint,
      );
      canvas.restore();

      u += 1.0 / passes;
    }
  }

  /// Seconds between contrail particles in the game.
  static const double _emitInterval = 0.1;

  /// Seconds a particle takes to fade in after it spawns.
  static const double _rampUpSeconds = 0.35;

  /// Draws the trail behind one engine, as if the ship were flying at top
  /// speed. Particles spawn at the nozzle every 0.1s; the ship flies out from
  /// under them straight aft at top speed, while each also drifts along its
  /// engine's angle at `maxSpeed × contrailMaxSpeedMult`. Each fades in over
  /// 0.35s, then fades out and grows (or shrinks) until it dies at
  /// `contrailDuration`. OMEGA-style engines draw one textured ribbon instead.
  ///
  /// One deliberate difference from the game: a full-length trail (seconds of
  /// flight) dwarfs a still sprite, so trails are compressed to at most one
  /// hull length. Proportions, lean, and fade are preserved.
  ///
  /// Runs in ship space, translated to the nozzle but NOT rotated to the slot:
  /// straight aft is `(0, 1)` here regardless of the engine's angle, so an
  /// angled engine's trail leans only as much as its drift share.
  void _paintContrail(
    Canvas canvas, {
    required EngineStyleSpec? spec,
    required ShipEngineSlot slot,
    required int slotIndex,
    required double alphaMult,
    required double slotAngle,
    required double scroll,
  }) {
    final speed = maxSpeed ?? 0;
    if (!showTrails || spec == null || speed <= 0) return;
    if (spec.contrailMode == ContrailMode.none) return;
    // Particle trails belong to the under-hull pass, ribbons to the over-hull
    // pass — the game's layering (particles below ships, ribbons above).
    final isRibbon = spec.contrailMode == ContrailMode.quadStrip;
    if (isRibbon == underHull) return;
    final color = spec.contrailColor;
    if (color == null || color.a <= 0) return;
    final duration = spec.contrailDuration;
    final startWidth = slot.width * spec.contrailSizeMult;
    if (duration <= 0 || startWidth <= 0) return;

    // In game the trail's alpha scales with ship speed over top speed, times
    // the engine glow level. At cruise that's 1 × (0.4 + 0.6 × throttle).
    final cruise = 0.4 + 0.6 * _throttle;
    final alpha = alphaMult * cruise;

    // The direction the engine points, in this unrotated space.
    final slotDir = Offset(cos(slotAngle), sin(slotAngle));

    if (isRibbon) {
      // The ribbon's head sits a little out from the nozzle along the engine's
      // angle. Ribbon points drift along that angle too, but the game damps
      // the drift by ×(1 − life) every frame, so over its whole life a point
      // moves only ~0.16·√duration seconds' worth of its starting drift speed
      // (at 60 fps). The trail's shape is dominated by the ship flying out
      // from under it, straight aft on screen.
      final head = slotDir * (slot.length * 0.4 * spec.contrailSpawnDistMult);
      final drift =
          slotDir * (speed * spec.contrailMaxSpeedMult * 0.16 * sqrt(duration));
      var tail = Offset(0, speed * duration) + drift;
      // A trail at full game length runs for seconds of flight — hundreds of
      // pixels hanging off a still sprite. Deliberate preview choice: compress
      // it to at most one hull length. Shape, lean, and fade are unchanged.
      if (tail.distance > imgH) tail *= imgH / tail.distance;
      canvas.save();
      canvas.translate(head.dx, head.dy);
      canvas.rotate(atan2(tail.dy, tail.dx));
      _paintContrailRibbon(
        canvas,
        color: color,
        alphaMult: alpha,
        length: tail.distance,
        startWidth: startWidth,
        endWidth: (startWidth * (1 + spec.contrailEndMult)).clamp(
          0.0,
          double.infinity,
        ),
        duration: duration,
        scroll: scroll,
        isSmoke: spec.isSmoke,
      );
      canvas.restore();
      return;
    }

    // A particle trail at full game length spans (1 + drift mult) × top speed
    // × duration — hundreds of pixels hanging off a still sprite. Deliberate
    // preview choice: compress it to at most one hull length by scaling the
    // speed the trail math sees. Spacing, lean, and fade compress together.
    final naturalLength =
        speed * (1 + spec.contrailMaxSpeedMult) * duration;
    final displaySpeed = naturalLength > imgH
        ? speed * imgH / naturalLength
        : speed;

    _paintContrailParticles(
      canvas,
      spec: spec,
      color: color,
      alphaMult: alpha,
      slotIndex: slotIndex,
      slotDir: slotDir,
      shipSpeed: displaySpeed,
      duration: duration,
      startWidth: startWidth,
      scroll: scroll,
    );
  }

  void _paintContrailParticles(
    Canvas canvas, {
    required EngineStyleSpec spec,
    required Color color,
    required double alphaMult,
    required int slotIndex,
    required Offset slotDir,
    required double shipSpeed,
    required double duration,
    required double startWidth,
    required double scroll,
  }) {
    final image = spec.isSmoke ? sprites.smoke : sprites.particle;
    final src = Rect.fromLTWH(0, 0, image.width * 1.0, image.height * 1.0);
    final endWidth = startWidth * spec.contrailEndMult;
    final driftSpeed = shipSpeed * spec.contrailMaxSpeedMult;

    // The game scatters each particle's drift direction by ±5°; this is the
    // matching sideways share of the drift, as a smooth wobble instead of
    // randomness so the loop stays seamless.
    const spread = 0.087;

    // The flicker loops once a second; ten emissions happen in that time, so
    // sliding every particle forward by one slot per tenth loops seamlessly.
    final f = (scroll * 10) % 1.0;
    final count = min(40, (duration / _emitInterval).ceil());

    // Smoke puffs spin as they age, alternating direction per engine.
    final spin = spec.isSmoke ? (slotIndex.isEven ? 1.2 : -1.2) : 0.0;

    for (var k = 0; k < count; k++) {
      final age = (k + f) * _emitInterval;
      if (age >= duration) break;
      final life = age / duration;

      final brightness = age < _rampUpSeconds
          ? age / _rampUpSeconds
          : 1 - (age - _rampUpSeconds) / max(0.001, duration - _rampUpSeconds);
      if (brightness <= 0) continue;

      // Where the ship's motion left it (straight aft) plus its own drift
      // (along the engine's angle), plus the sideways wobble.
      final driftDist = driftSpeed * age;
      final wobble = sin(age * 1.3 + slotIndex * 2.399) * driftDist * spread;
      final center =
          Offset(0, shipSpeed * age) +
          slotDir * driftDist +
          Offset(-slotDir.dy, slotDir.dx) * wobble;

      final size = startWidth + (endWidth - startWidth) * life;
      if (size <= 0) continue;

      final paint = Paint()
        ..blendMode = spec.isSmoke ? BlendMode.srcOver : BlendMode.plus
        ..filterQuality = FilterQuality.high
        ..colorFilter = ColorFilter.mode(
          _dimmed(color, brightness * alphaMult),
          BlendMode.modulate,
        );

      if (spin != 0) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(age * spin);
        canvas.drawImageRect(
          image,
          src,
          Rect.fromCenter(center: Offset.zero, width: size, height: size),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawImageRect(
          image,
          src,
          Rect.fromCenter(center: center, width: size, height: size),
          paint,
        );
      }
    }
  }

  /// One textured ribbon (OMEGA), using the game's exact per-point alpha
  /// curve. That curve is piecewise linear in trail progress, so four vertex
  /// columns draw it exactly: alpha climbs at a fixed slope of 10 per unit of
  /// progress until `min(0.05 / duration, 0.5)`, then restarts at full and
  /// falls linearly to zero at the tail. For durations over half a second
  /// that's a genuine jump — a short dim lead-in at the head, then full
  /// brightness — and the game draws it that way too. (For shorter durations
  /// the game lets the climb pass full brightness and its colour byte wraps
  /// around; we clamp instead.) Width tapers linearly per the style. Drawn
  /// along +x; the caller rotates the canvas to the trail's real direction.
  void _paintContrailRibbon(
    Canvas canvas, {
    required Color color,
    required double alphaMult,
    required double length,
    required double startWidth,
    required double endWidth,
    required double duration,
    required double scroll,
    required bool isSmoke,
  }) {
    if (length <= 0 || duration <= 0) return;
    final image = sprites.ribbon;
    final texW = image.width.toDouble();
    final texH = image.height.toDouble();

    // The game repeats the ribbon texture once per 256 world units — a fixed
    // constant, nothing to do with the texture's own pixel size.
    const unitsPerRepeat = 256.0;

    // The texture rides with the trail's points, so it streams tailward at
    // the point speed; rounded to a whole number of repeats per loop of the
    // one-second flicker cycle so the loop is seamless.
    final repeatsPerLoop = max(1, (length / duration / unitsPerRepeat).round());
    final uOffset = -scroll * repeatsPerLoop * texW;

    // (progress, alpha) of the four columns: head, both sides of the alpha
    // jump, tail. Duplicate positions in a triangle strip just make zero-area
    // triangles, which is the standard way to draw a hard colour step.
    final t = min(0.05 / duration, 0.5);
    final columns = [
      (0.0, 0.0),
      (t, min(1.0, 10.0 * t)),
      (t, 1.0),
      (1.0, 0.0),
    ];

    final positions = Float32List(columns.length * 4);
    final texCoords = Float32List(columns.length * 4);
    final colors = Int32List(columns.length * 2);

    for (var i = 0; i < columns.length; i++) {
      final (p, brightness) = columns[i];
      final x = length * p;
      final halfWidth = (startWidth + (endWidth - startWidth) * p) / 2;
      final c = _dimmedInt(color, brightness * alphaMult);

      final j = i * 4;
      positions[j] = x;
      positions[j + 1] = -halfWidth;
      positions[j + 2] = x;
      positions[j + 3] = halfWidth;
      final u = x / unitsPerRepeat * texW + uOffset;
      texCoords[j] = u;
      texCoords[j + 1] = 0.01 * texH;
      texCoords[j + 2] = u;
      texCoords[j + 3] = 0.99 * texH;
      colors[i * 2] = c;
      colors[i * 2 + 1] = c;
    }

    canvas.drawVertices(
      ui.Vertices.raw(
        VertexMode.triangleStrip,
        positions,
        textureCoordinates: texCoords,
        colors: colors,
      ),
      BlendMode.modulate,
      Paint()
        // The style's type is the blend mode, same as for particles: GLOW
        // ribbons add light, SMOKE ribbons paint over what's behind them.
        ..blendMode = isSmoke ? BlendMode.srcOver : BlendMode.plus
        ..filterQuality = FilterQuality.high
        ..shader = ui.ImageShader(
          image,
          TileMode.repeated,
          TileMode.clamp,
          Matrix4.identity().storage,
        ),
    );
  }

  /// Lays the outline sprite faintly over the whole flame. This is the teardrop
  /// shape that gives a non-fighter flame its edge.
  void _paintOutline(
    Canvas canvas, {
    required ui.Image image,
    required Color tint,
    required double alphaMult,
    required double length,
    required double width,
  }) {
    final src = Rect.fromLTWH(
      image.width * 0.01,
      image.height * 0.01,
      image.width * 0.98,
      image.height * 0.98,
    );
    canvas.drawImageRect(
      image,
      src,
      // The game squashes the outline to 90% of the flame's length.
      Rect.fromLTWH(0, -width / 2, length * 0.9, width),
      Paint()
        ..blendMode = BlendMode.plus
        ..filterQuality = FilterQuality.high
        ..colorFilter = ColorFilter.mode(
          _dimmed(tint, _throttle * 50 / 255 * alphaMult),
          BlendMode.modulate,
        ),
    );
  }

  /// Draws the round bloom over the nozzle: engine colour first, then a smaller
  /// white core on top.
  void _paintBloom(
    Canvas canvas, {
    required Color tint,
    required double alphaMult,
    required double flameWidth,
    required double sizeMult,
  }) {
    var bloomSize = flameWidth * 2;
    if (isFighter) bloomSize *= 0.66;

    final bloom = sprites.bloom;
    final src = Rect.fromLTWH(0, 0, bloom.width * 1.0, bloom.height * 1.0);

    void draw(Color color, double size, double alpha) {
      if (size <= 0) return;
      canvas.drawImageRect(
        bloom,
        src,
        Rect.fromCenter(center: Offset.zero, width: size, height: size),
        Paint()
          ..blendMode = BlendMode.plus
          ..filterQuality = FilterQuality.high
          ..colorFilter = ColorFilter.mode(
            _dimmed(color, alpha),
            BlendMode.modulate,
          ),
      );
    }

    // 0.45 is the alpha the game settles on for an engine that's running but
    // not flaring.
    final alpha = 0.45 * alphaMult;
    draw(tint, sizeMult * bloomSize * 2, alpha);
    draw(Colors.white, sizeMult * bloomSize * 0.75, alpha);
  }

  @override
  bool shouldRepaint(_EngineGlowPainter oldDelegate) =>
      !identical(oldDelegate.slots, slots) ||
      !identical(oldDelegate.sprites, sprites) ||
      oldDelegate.isFighter != isFighter ||
      oldDelegate.maxSpeed != maxSpeed ||
      oldDelegate.defaultColor != defaultColor ||
      oldDelegate.underHull != underHull ||
      oldDelegate.showTrails != showTrails;
}

/// Draws a ship's shield the way the game draws it in combat: a cloudy inner
/// fill under a soft edge ring, over the shield arc. Everything here follows
/// the game's own shield rendering (radius, colors, arc, and the idle
/// animation), so the blueprint matches what a player sees.
///
/// Only the idle, raised shield is drawn — no hit flashes, no raise/lower
/// unfold. The arc is centered on the ship's nose (straight up here), which is
/// exactly right for FRONT shields; OMNI shields are shown the same way, since
/// an idle omni shield has no target to face.
class _ShieldPainter extends CustomPainter {
  final List<double> center;
  final double imgH;

  /// Shield center offset from the ship's pivot, `[forward, lateral]`, in the
  /// same ship-space units as weapon slots.
  final List<double> shieldCenter;
  final double radius;

  /// The shield arc from `ship_data.csv`, in degrees.
  final double arcDegrees;

  final ShieldStyleColors colors;

  /// The inner-fill texture (already picked for this shield's radius) and the
  /// edge-ring texture.
  final ui.Image fillImage;
  final ui.Image ringImage;

  /// Ring band thickness in ship-space units (thinner for small hulls).
  final double ringThickness;

  /// Loops 0 → 1 every 16 seconds while animating; null holds the shield still.
  /// Drives the fill's rotation and the ring's ripple.
  final Animation<double>? clock;

  _ShieldPainter({
    required this.center,
    required this.imgH,
    required this.shieldCenter,
    required this.radius,
    required this.arcDegrees,
    required this.colors,
    required this.fillImage,
    required this.ringImage,
    required this.ringThickness,
    required this.clock,
  }) : super(repaint: clock);

  /// The game draws the shield 10° wider than its stated arc, fading the extra
  /// out at each end.
  static const double _arcPaddingDeg = 10.0;

  /// A raised, undamaged shield sits at this brightness in the game (it gets
  /// brighter only where it's hit).
  static const double _idleBrightness = 0.55;

  /// The fill reaches a little past the ring, same as the game.
  static const double _fillRadiusMult = 1.07;

  @override
  void paint(Canvas canvas, Size size) {
    if (center.length < 2 || shieldCenter.length < 2 || radius <= 0) return;

    final cx = center[0];
    final cy = imgH - center[1];
    // Same ship-space → screen transform as the weapon slots and engine glow.
    final origin = Offset(cx - shieldCenter[1], cy - shieldCenter[0]);

    final drawnArcDeg = arcDegrees + _arcPaddingDeg;
    if (drawnArcDeg <= 0) return;
    final drawnArcRad = drawnArcDeg * pi / 180;
    final halfArcRad = drawnArcRad / 2;

    // One perimeter point per ~20 units of arc, at least one per 5°.
    final byLength = (radius * drawnArcRad / 20).floor() + 1;
    final byAngle = (drawnArcDeg / 5).floor() + 1;
    final pointCount = max(max(byLength, byAngle), 2);

    // Animation phases. The fill texture spins at π/8 rad/s (a full turn every
    // 16s), so the 16s clock maps straight to a 0 → 2π spin. The ring ripple's
    // speed depends on radius; it's quantized to a whole number of cycles per
    // clock loop so it repeats seamlessly when the clock wraps.
    final t = clock?.value ?? 0.0;
    final spin = t * 2 * pi;
    final ringRate = sqrt(20 * pi / radius) * 10; // radians/sec inside the sine
    final ringCycles = max(1, (ringRate * 16 / (2 * pi)).round());
    final ringTimeArg = t * 2 * pi * ringCycles;
    final rippleAmplitude = (0.25 + 0.75 * radius / 256).clamp(0.0, 1.0);

    // Precompute each perimeter point's angle, direction, and end-fade.
    final gammas = List<double>.filled(pointCount, 0);
    final dirs = List<Offset>.filled(pointCount, Offset.zero);
    final fades = List<double>.filled(pointCount, 0);
    for (var i = 0; i < pointCount; i++) {
      final frac = i / (pointCount - 1);
      final gamma = -halfArcRad + frac * drawnArcRad;
      gammas[i] = gamma;
      // Ship-space (cosγ forward, sinγ lateral) → screen delta.
      dirs[i] = Offset(-sin(gamma), -cos(gamma));
      // Fade to nothing over the last 10° at each end of the drawn arc.
      final degFromEnd =
          min(gamma + halfArcRad, halfArcRad - gamma) * 180 / pi;
      final edgeFade = (degFromEnd / _arcPaddingDeg).clamp(0.0, 1.0);
      fades[i] = _idleBrightness * edgeFade;
    }

    _paintFill(canvas, origin, gammas, dirs, fades, spin);
    _paintRing(
      canvas,
      origin,
      gammas,
      dirs,
      fades,
      ringTimeArg,
      rippleAmplitude,
    );
  }

  /// The translucent inner fill: a textured triangle fan, drawn twice with the
  /// texture spinning in opposite directions and added together, which is what
  /// gives the shield its cloudy shimmer.
  void _paintFill(
    Canvas canvas,
    Offset origin,
    List<double> gammas,
    List<Offset> dirs,
    List<double> fades,
    double spin,
  ) {
    final r = radius * _fillRadiusMult;
    final texW = fillImage.width.toDouble();
    final texH = fillImage.height.toDouble();
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..filterQuality = FilterQuality.high
      ..shader = ui.ImageShader(
        fillImage,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      );

    final count = gammas.length;
    // Fan: one center vertex, then every perimeter point.
    final vertexCount = count + 1;

    for (final dir in [1.0, -1.0]) {
      final positions = Float32List(vertexCount * 2);
      final texCoords = Float32List(vertexCount * 2);
      final vColors = Int32List(vertexCount);

      // Center vertex: fully transparent, texture centre.
      positions[0] = origin.dx;
      positions[1] = origin.dy;
      texCoords[0] = 0.5 * texW;
      texCoords[1] = 0.5 * texH;
      vColors[0] = _dimmedInt(colors.inner, 0);

      for (var i = 0; i < count; i++) {
        final v = i + 1;
        final p = origin + dirs[i] * r;
        positions[v * 2] = p.dx;
        positions[v * 2 + 1] = p.dy;
        // Texture mapped as a full circle in UV space, spun over time.
        final a = gammas[i] + dir * spin;
        texCoords[v * 2] = (0.5 + cos(a) * 0.5) * texW;
        texCoords[v * 2 + 1] = (0.5 + sin(a) * 0.5) * texH;
        vColors[v] = _dimmedInt(colors.inner, fades[i]);
      }

      canvas.drawVertices(
        ui.Vertices.raw(
          VertexMode.triangleFan,
          positions,
          textureCoordinates: texCoords,
          colors: vColors,
        ),
        BlendMode.modulate,
        paint,
      );
    }
  }

  /// The bright edge ring: a textured strip along the shield radius whose edges
  /// are softened by the line texture, and whose radius ripples over time.
  void _paintRing(
    Canvas canvas,
    Offset origin,
    List<double> gammas,
    List<Offset> dirs,
    List<double> fades,
    double timeArg,
    double amplitude,
  ) {
    final texW = ringImage.width.toDouble();
    final texH = ringImage.height.toDouble();
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..shader = ui.ImageShader(
        ringImage,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      );

    final count = gammas.length;
    final positions = Float32List(count * 2 * 2);
    final texCoords = Float32List(count * 2 * 2);
    final vColors = Int32List(count * 2);

    for (var i = 0; i < count; i++) {
      final wobble = amplitude * sin(timeArg + 10 * gammas[i]);
      final outer = origin + dirs[i] * (radius + wobble);
      final inner = origin + dirs[i] * (radius + wobble - ringThickness);
      final o = i * 2;
      final inn = i * 2 + 1;
      positions[o * 2] = outer.dx;
      positions[o * 2 + 1] = outer.dy;
      positions[inn * 2] = inner.dx;
      positions[inn * 2 + 1] = inner.dy;
      // Sample down the middle column, outer edge to inner edge, so the line
      // texture's soft top and bottom become the ring's soft edges.
      texCoords[o * 2] = 0.5 * texW;
      texCoords[o * 2 + 1] = 0.5;
      texCoords[inn * 2] = 0.5 * texW;
      texCoords[inn * 2 + 1] = texH - 0.5;
      final c = _dimmedInt(colors.ring, fades[i]);
      vColors[o] = c;
      vColors[inn] = c;
    }

    canvas.drawVertices(
      ui.Vertices.raw(
        VertexMode.triangleStrip,
        positions,
        textureCoordinates: texCoords,
        colors: vColors,
      ),
      BlendMode.modulate,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.arcDegrees != arcDegrees ||
      oldDelegate.shieldCenter != shieldCenter ||
      oldDelegate.colors.inner != colors.inner ||
      oldDelegate.colors.ring != colors.ring ||
      !identical(oldDelegate.fillImage, fillImage) ||
      !identical(oldDelegate.ringImage, ringImage) ||
      oldDelegate.ringThickness != ringThickness ||
      !identical(oldDelegate.clock, clock);
}

/// [tint] with its alpha scaled by [mult]. Under an additive blend the alpha
/// is what dims the colour, so the other channels are left alone — scaling
/// them too would dim it twice over.
Color _dimmed(Color tint, double mult) => tint.withValues(alpha: tint.a * mult);

/// Same as [_dimmed], packed the way `ui.Vertices` wants its colours.
int _dimmedInt(Color tint, double mult) => _dimmed(tint, mult).toARGB32();

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
