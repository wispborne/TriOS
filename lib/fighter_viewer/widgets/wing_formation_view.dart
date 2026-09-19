import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:trios/fighter_viewer/models/wing.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/widgets/ship_blueprint_view.dart';

/// The fighters of a wing drawn in formation, sized the way the game sizes
/// them. The game uses the same drawing for the Codex list icon and the
/// picture on the fighter's page (`title/Object/do.java`); only [listIcon]
/// changes between the two.
///
/// How the game places and sizes the fighters in a box of size w × h:
/// - Positions come from a fixed table (`combat/new/A.java`,
///   `A.super(FighterWingSpec)`), not from the combat formation code. There is
///   one table per formation, and one row per wing size from 1 to 6. Each row
///   is a list of (x, y) positions as fractions of a spread. Wings of more than
///   6 draw only the first 6.
/// - Spread = min(w, h) × 0.75 × (1 + 0.5 × (1 − f)), capped at 125, and
///   multiplied by 0.667 for 2-fighter wings. f is 0.5 for list icons and
///   0.25 for the page picture.
/// - Zoom = min(w / 3 / sprite width, h / 3 / sprite height), capped at 1, then
///   × 0.75 (the fighter size factor) × 0.95. The zoom applies to the whole
///   drawing, so it shrinks the spread as well as the fighters.
/// - Each fighter is drawn at its natural size before the zoom, including
///   weapons that stick out past the hull sprite, like a Wanzer's arms.
class WingFormationView extends StatelessWidget {
  final Wing wing;

  /// The ship behind the wing.
  final Ship ship;

  /// True for the Codex list icon, false for the picture on the fighter page.
  final bool listIcon;

  /// Shows engine glow, as the list rows do on hover.
  final bool forceEngineGlow;

  const WingFormationView({
    super.key,
    required this.wing,
    required this.ship,
    this.listIcon = false,
    this.forceEngineGlow = false,
  });

  static const _box = [
    <double>[],
    [0.0, 0.0],
    [-0.35, 0.0, 0.35, 0.0],
    [0.0, 0.0, -0.45, 0.0, 0.45, 0.0],
    [-0.4, 0.4, -0.4, -0.4, 0.4, 0.4, 0.4, -0.4],
    [0.0, -0.3, -0.45, -0.3, 0.45, -0.3, -0.25, 0.33, 0.25, 0.33],
    [0.0, 0.25, -0.5, 0.25, 0.5, 0.25, 0.0, -0.25, -0.5, -0.25, 0.5, -0.25],
  ];

  static const _claw = [
    <double>[],
    [0.0, 0.0],
    [-0.35, 0.1, 0.35, 0.0],
    [0.0, -0.33, -0.33, 0.2, 0.33, 0.2],
    [-0.45, 0.5, -0.35, 0.0, 0.45, 0.0, 0.05, -0.4],
    [0.0, 0.05, -0.45, 0.3, 0.45, 0.3, -0.35, -0.33, 0.35, -0.33],
    [0.0, 0.15, -0.4, 0.25, 0.4, 0.25, 0.0, -0.4, -0.4, -0.25, 0.4, -0.25],
  ];

  static const _v = [
    <double>[],
    [0.0, 0.0],
    [-0.35, 0.0, 0.35, 0.1],
    [0.0, 0.33, -0.33, -0.2, 0.33, -0.2],
    [0.15, 0.45, -0.2, 0.05, 0.5, 0.05, -0.5, -0.4],
    [0.0, 0.45, -0.45, 0.3, 0.45, 0.3, -0.35, -0.33, 0.35, -0.33],
    [0.0, 0.4, -0.4, 0.25, 0.4, 0.25, 0.0, -0.15, -0.4, -0.25, 0.4, -0.25],
  ];

  /// Used for every other formation (DIAMOND, and modded values).
  static const _default = [
    <double>[],
    [0.0, 0.0],
    [-0.35, 0.0, 0.35, 0.0],
    [0.0, 0.33, -0.33, -0.2, 0.33, -0.2],
    [0.0, 0.4, -0.4, 0.0, 0.4, 0.0, 0.0, -0.4],
    [0.0, 0.45, -0.45, 0.3, 0.45, 0.3, -0.35, -0.33, 0.35, -0.33],
    [0.0, 0.4, -0.4, 0.25, 0.4, 0.25, 0.0, -0.4, -0.4, -0.25, 0.4, -0.25],
  ];

  @override
  Widget build(BuildContext context) {
    final spriteWidth = ship.width;
    final spriteHeight = ship.height;
    if (ship.spriteFile == null ||
        spriteWidth == null ||
        spriteHeight == null ||
        spriteWidth <= 0 ||
        spriteHeight <= 0) {
      return const SizedBox.shrink();
    }

    final table = switch (wing.formation?.toUpperCase()) {
      'BOX' => _box,
      'CLAW' => _claw,
      'V' => _v,
      _ => _default,
    };
    var count = wing.numCraft ?? 1;
    if (count >= table.length) count = table.length - 1;
    if (count <= 0) count = 1;
    final positions = table[count];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (!w.isFinite || !h.isFinite) return const SizedBox.shrink();

        final f = listIcon ? 0.5 : 0.25;
        var spread = math.min(
          math.min(w, h) * 0.75 * (1 + 0.5 * (1 - f)),
          125.0,
        );
        if (count == 2) spread *= 0.667;

        final zoom =
            math.min(math.min(w / 3 / spriteWidth, h / 3 / spriteHeight), 1.0) *
            0.75 *
            0.95;

        // Laid out at the game's unzoomed size, centered on the box's middle,
        // then scaled down by the zoom around that middle.
        return ClipRect(
          child: OverflowBox(
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: Transform.scale(
              scale: zoom,
              child: SizedBox(
                width: w / zoom,
                height: h / zoom,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < count; i++)
                      // A box three times the sprite size, so weapons past
                      // the hull have room. BoxFit.none draws the fighter at
                      // its natural size rather than shrinking it to fit.
                      Positioned(
                        left:
                            w / zoom / 2 +
                            positions[i * 2] * spread -
                            spriteWidth * 1.5,
                        // The game's y axis points up; Flutter's points down.
                        top:
                            h / zoom / 2 -
                            positions[i * 2 + 1] * spread -
                            spriteHeight * 1.5,
                        width: spriteWidth * 3,
                        height: spriteHeight * 3,
                        child: ShipBlueprintView.minimal(
                          ship: ship,
                          fit: BoxFit.none,
                          clipContent: false,
                          forceEngineGlow: forceEngineGlow,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
