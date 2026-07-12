import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:trios/ship_viewer/utils/sprite_utils.dart';
import 'package:trios/thirdparty/flutter_context_menu/components/menu_item.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/models/context_menu.dart';
import 'package:trios/thirdparty/flutter_context_menu/core/models/context_menu_entry.dart';
import 'package:trios/thirdparty/flutter_context_menu/widgets/context_menu_region.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/weapons_page_controller.dart';
import 'package:trios/widgets/moving_tooltip.dart';
import 'package:trios/widgets/snackbar.dart';

// Decoded-image cache for the layered weapon composite, keyed by file path.
final Map<String, Future<ui.Image?>> _weaponDecodedImageCache = {};

Future<ui.Image?> _loadWeaponImage(String path) {
  return _weaponDecodedImageCache.putIfAbsent(path, () => decodeImageFile(path));
}

/// One composited sprite layer, positioned in weapon-pixel space where the
/// origin is the weapon's mount center.
class _WeaponLayer {
  final ui.Image image;

  /// Where this layer's [pivot] lands, relative to the mount center.
  final Offset center;

  /// The point within the image (image pixel coords) mapped onto [center].
  final Offset pivot;

  /// Rotation about [center], in radians.
  final double rotation;

  final Paint paint;

  /// For glow layers: the additive tint (from `glowColor`, or white). The
  /// painter builds the per-frame additive paint from this scaled by the
  /// current fade opacity, so glow intensity can animate.
  final Color? glowTint;

  _WeaponLayer({
    required this.image,
    required this.center,
    required this.pivot,
    required this.rotation,
    required this.paint,
    this.glowTint,
  });

  /// Axis-aligned bounds of this layer in weapon space.
  Rect get bounds {
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    final corners = [
      Offset(-pivot.dx, -pivot.dy),
      Offset(w - pivot.dx, -pivot.dy),
      Offset(w - pivot.dx, h - pivot.dy),
      Offset(-pivot.dx, h - pivot.dy),
    ];
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final c in corners) {
      final x = c.dx * cos - c.dy * sin + center.dx;
      final y = c.dx * sin + c.dy * cos + center.dy;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

/// Renders a weapon as the game does at rest: a single mount's sprite layers
/// (under → barrel/main, ordered by [Weapon.renderBarrelBelow]) plus any loaded
/// missiles, with the glow sprite drawn additively on top.
class WeaponImageCell extends ConsumerStatefulWidget {
  final Weapon weapon;
  final BoxFit fit;
  final double size;

  /// Whether the grid row is hovered; reveals the glow for the whole row.
  final bool rowHovered;

  const WeaponImageCell({
    super.key,
    required this.weapon,
    this.fit = BoxFit.scaleDown,
    this.size = 40,
    this.rowHovered = false,
  });

  @override
  ConsumerState<WeaponImageCell> createState() => _WeaponImageCellState();
}

class _WeaponImageCellState extends ConsumerState<WeaponImageCell>
    with SingleTickerProviderStateMixin {
  List<_WeaponLayer> _layers = const [];

  // Glow layers, faded in/out by [_glowController] on hover (or pinned on when
  // "Always show weapon glow" is enabled).
  List<_WeaponLayer> _glowLayers = const [];
  Size _canvasSize = Size.zero;
  bool _loaded = false;
  bool _hovering = false;
  bool _alwaysShowGlow = false;

  late final AnimationController _glowController;

  static const double _deg2rad = math.pi / 180.0;

  /// Animate the glow toward fully shown when hovered (sprite or row) or
  /// always-on, else hidden.
  void _updateGlow() {
    _glowController.animateTo(
      (_alwaysShowGlow || _hovering || widget.rowHovered) ? 1.0 : 0.0,
    );
  }

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _build();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WeaponImageCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weapon.id != widget.weapon.id) {
      _loaded = false;
      _build();
    }
    if (oldWidget.rowHovered != widget.rowHovered) {
      _updateGlow();
    }
  }

  /// Renders the composite at native pixel resolution to PNG bytes,
  /// optionally including the glow layers.
  Future<Uint8List?> _renderCompositePng({required bool withGlow}) async {
    if (_layers.isEmpty || _canvasSize.isEmpty) return null;
    final w = _canvasSize.width.round();
    final h = _canvasSize.height.round();
    if (w <= 0 || h <= 0) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final l in _layers) {
      _drawWeaponLayer(canvas, l, l.paint);
    }
    if (withGlow) {
      for (final l in _glowLayers) {
        _drawWeaponLayer(
          canvas,
          l,
          _glowLayerPaint(l.glowTint ?? const Color(0xFFFFFFFF), 1.0),
        );
      }
    }

    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(w, h);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }

  Future<void> _copySpriteToClipboard({required bool withGlow}) async {
    final bytes = await _renderCompositePng(withGlow: withGlow);
    if (!mounted) return;
    if (bytes == null) return;

    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      showSnackBar(
        context: context,
        type: SnackBarType.warn,
        content: const Text(
          'Copying images is not supported on this platform.',
        ),
      );
      return;
    }

    final item = DataWriterItem()..add(Formats.png(bytes));
    await clipboard.write([item]);
    if (!mounted) return;
    showSnackBar(
      context: context,
      type: SnackBarType.info,
      content: Text(
        withGlow
            ? 'Copied sprite (with glow) to clipboard.'
            : 'Copied sprite to clipboard.',
      ),
    );
  }

  /// The composite painted at 1:1 (native pixel) scale, statically.
  Widget _composite1to1({required bool withGlow}) {
    return SizedBox(
      width: _canvasSize.width,
      height: _canvasSize.height,
      child: CustomPaint(
        painter: _WeaponSpritePainter(
          layers: _layers,
          glowLayers: withGlow ? _glowLayers : const [],
          glowOpacity: const AlwaysStoppedAnimation(1.0),
        ),
      ),
    );
  }

  /// Hover tooltip: the 1:1 composite, shown both without and with glow.
  Widget _buildTooltipPreview(BuildContext context) {
    final theme = Theme.of(context);
    final hasGlow = _glowLayers.isNotEmpty;

    Widget tile(bool withGlow) => Container(
      color: kDarkTooltipBackground,
      padding: const EdgeInsets.all(8),
      child: _composite1to1(withGlow: withGlow),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.weapon.name ?? widget.weapon.id,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasGlow) ...[
              tile(false),
              const SizedBox(width: 8),
              tile(true),
            ] else
              tile(false),
          ],
        ),
      ],
    );
  }

  Future<void> _build() async {
    final weapon = widget.weapon;
    final layers = <_WeaponLayer>[];
    final glowLayers = <_WeaponLayer>[];

    // Full-frame layers (under, gun/main in at-rest draw order), centered.
    for (final path in weapon.spriteLayers) {
      final img = await _loadWeaponImage(path);
      if (img == null) continue;
      layers.add(
        _WeaponLayer(
          image: img,
          center: Offset.zero,
          pivot: Offset(img.width / 2, img.height / 2),
          rotation: 0,
          paint: Paint()..filterQuality = FilterQuality.high,
        ),
      );
    }

    // Loaded missiles: one per tube, at its fire offset, oriented up.
    final offsets = weapon.mountOffsets;
    if (weapon.renderLoadedMissiles &&
        weapon.loadedMissileSprite != null &&
        offsets != null &&
        offsets.length >= 2) {
      final missileImg = await _loadWeaponImage(weapon.loadedMissileSprite!);
      if (missileImg != null) {
        final c = weapon.loadedMissileCenter;
        final pivot = (c != null && c.length >= 2)
            ? Offset(c[0], c[1])
            : Offset(missileImg.width / 2, missileImg.height / 2);
        final angles = weapon.mountAngleOffsets;
        final tubes = offsets.length ~/ 2;
        for (var i = 0; i < tubes; i++) {
          final x = offsets[i * 2]; // forward (along barrel)
          final y = offsets[i * 2 + 1]; // lateral
          final angle = (angles != null && angles.length > i) ? angles[i] : 0.0;
          layers.add(
            _WeaponLayer(
              image: missileImg,
              // weapon-forward = up = -y on screen; lateral = +x on screen.
              center: Offset(y, -x),
              pivot: pivot,
              rotation: angle * _deg2rad,
              paint: Paint()..filterQuality = FilterQuality.high,
            ),
          );
        }
      }
    }

    // Glow sprite on top, drawn additively and tinted by glowColor. Painted
    // only on hover, faded in/out by [_glowController].
    final glowPath = weapon.glowSprite;
    if (glowPath != null) {
      final glowImg = await _loadWeaponImage(glowPath);
      if (glowImg != null) {
        final gc = weapon.glowColor;
        final tint = (gc != null && gc.length >= 3)
            ? Color.fromARGB(
                gc.length >= 4 ? gc[3].round().clamp(0, 255) : 255,
                gc[0].round().clamp(0, 255),
                gc[1].round().clamp(0, 255),
                gc[2].round().clamp(0, 255),
              )
            : const Color(0xFFFFFFFF);
        glowLayers.add(
          _WeaponLayer(
            image: glowImg,
            center: Offset.zero,
            pivot: Offset(glowImg.width / 2, glowImg.height / 2),
            rotation: 0,
            paint: Paint(),
            glowTint: tint,
          ),
        );
      }
    }

    final all = [...layers, ...glowLayers];
    if (all.isEmpty) {
      if (mounted) setState(() => _loaded = true);
      return;
    }

    // Union bounding box over all layers (incl. glow) so the canvas size — and
    // thus the rendered scale — stays stable whether or not glow is shown.
    var bbox = all.first.bounds;
    for (final l in all.skip(1)) {
      bbox = bbox.expandToInclude(l.bounds);
    }
    _WeaponLayer shift(_WeaponLayer l) => _WeaponLayer(
      image: l.image,
      center: l.center - bbox.topLeft,
      pivot: l.pivot,
      rotation: l.rotation,
      paint: l.paint,
      glowTint: l.glowTint,
    );

    if (mounted) {
      setState(() {
        _layers = layers.map(shift).toList();
        _glowLayers = glowLayers.map(shift).toList();
        _canvasSize = bbox.size;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return SizedBox(width: widget.size, height: widget.size);
    }
    if ((_layers.isEmpty && _glowLayers.isEmpty) || _canvasSize.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: Icon(Icons.image_not_supported)),
      );
    }

    final tooltipPath =
        widget.weapon.mainSprite ?? widget.weapon.allSpriteFiles.firstOrNull;

    // Pin the glow on (or release back to hover behavior) when the setting flips.
    final alwaysShowGlow = ref.watch(
      weaponsPageControllerProvider.select((s) => s.alwaysShowGlow),
    );
    if (alwaysShowGlow != _alwaysShowGlow) {
      _alwaysShowGlow = alwaysShowGlow;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateGlow();
      });
    }

    Widget composite = FittedBox(
      fit: widget.fit,
      child: SizedBox(
        width: _canvasSize.width,
        height: _canvasSize.height,
        child: CustomPaint(
          painter: _WeaponSpritePainter(
            layers: _layers,
            glowLayers: _glowLayers,
            glowOpacity: _glowController,
          ),
        ),
      ),
    );

    // Right-click: open the sprite's folder, copy the composite to clipboard.
    // (No tap handler — taps fall through to the row's default handler.)
    composite = ContextMenuRegion(
      contextMenu: ContextMenu(
        entries: <ContextMenuEntry>[
          if (tooltipPath != null)
            MenuItem(
              label: 'Open sprite folder',
              icon: Icons.folder_open,
              onSelected: () => tooltipPath.toFile().showInExplorer(),
            ),
          MenuItem(
            label: _glowLayers.isEmpty
                ? 'Copy sprite to clipboard'
                : 'Copy sprite (no glow)',
            icon: Icons.copy,
            onSelected: () => _copySpriteToClipboard(withGlow: false),
          ),
          if (_glowLayers.isNotEmpty)
            MenuItem(
              label: 'Copy sprite (with glow)',
              icon: Icons.auto_awesome,
              onSelected: () => _copySpriteToClipboard(withGlow: true),
            ),
        ],
        padding: const EdgeInsets.all(8.0),
      ),
      child: composite,
    );

    // Glow fades in on hover and out on exit (unless pinned on by the setting).
    if (_glowLayers.isNotEmpty) {
      composite = MouseRegion(
        onEnter: (_) {
          _hovering = true;
          _updateGlow();
        },
        onExit: (_) {
          _hovering = false;
          _updateGlow();
        },
        child: composite,
      );
    }

    if (_layers.isNotEmpty) {
      composite = MovingTooltipWidget.framed(
        backgroundColor: kDarkTooltipBackground,
        tooltipWidgetBuilder: (context) => _buildTooltipPreview(context),
        child: composite,
      );
    }

    return SizedBox(width: widget.size, height: widget.size, child: composite);
  }
}

void _drawWeaponLayer(Canvas canvas, _WeaponLayer l, Paint paint) {
  canvas.save();
  canvas.translate(l.center.dx, l.center.dy);
  if (l.rotation != 0) canvas.rotate(l.rotation);
  canvas.drawImage(l.image, Offset(-l.pivot.dx, -l.pivot.dy), paint);
  canvas.restore();
}

/// Additive glow paint, scaled by [op] (0–1) so the glow can fade in/out.
Paint _glowLayerPaint(Color tint, double op) => Paint()
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

class _WeaponSpritePainter extends CustomPainter {
  final List<_WeaponLayer> layers;
  final List<_WeaponLayer> glowLayers;

  /// Current glow fade, 0 (hidden) to 1 (full). Drives repaint while animating.
  final Animation<double> glowOpacity;

  _WeaponSpritePainter({
    required this.layers,
    required this.glowLayers,
    required this.glowOpacity,
  }) : super(repaint: glowOpacity);

  @override
  void paint(Canvas canvas, Size size) {
    for (final l in layers) {
      _drawWeaponLayer(canvas, l, l.paint);
    }

    final op = glowOpacity.value;
    if (op <= 0) return;
    for (final l in glowLayers) {
      _drawWeaponLayer(
        canvas,
        l,
        _glowLayerPaint(l.glowTint ?? const Color(0xFFFFFFFF), op),
      );
    }
  }

  @override
  bool shouldRepaint(_WeaponSpritePainter oldDelegate) =>
      !identical(oldDelegate.layers, layers) ||
      !identical(oldDelegate.glowLayers, glowLayers);
}

