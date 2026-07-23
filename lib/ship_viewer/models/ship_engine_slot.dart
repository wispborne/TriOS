import 'package:trios/ship_viewer/models/ship_engine_style_spec.dart';

/// One engine slot parsed from a `.ship` file's `engineSlots` array.
///
/// Coordinates follow the same ship-space convention as weapon slots:
/// [location] is `[x, y]` relative to the sprite center, with +x forward and
/// +y to the ship's left. [angle] is the direction the engine flame points,
/// in degrees (180 = straight aft, the common case).
class ShipEngineSlot {
  final List<double> location;
  final double angle;
  final double length;
  final double width;
  final double? contrailSize;

  /// Engine style name (e.g. `HIGH_TECH`), keyed into `engine_styles.json`.
  /// The game requires this key — a hull without it fails to load — so null
  /// only happens on data the game itself would reject; we fall back to the
  /// hull's top-level `style` rather than dropping the slot. The game treats
  /// an unknown name here as a [styleId], so mods can put their own style ids
  /// straight in `style` — a plain map lookup gets that for free.
  final String? style;

  /// Style id looked up in `engine_styles.json` when [style] is `CUSTOM`.
  final String? styleId;

  /// A whole style written inline in the `.ship` file, used with
  /// `"style": "CUSTOM"` when neither [style] nor [styleId] names one.
  /// Common in missiles, rare but legal in ships.
  final EngineStyleSpec? styleSpec;

  const ShipEngineSlot({
    required this.location,
    required this.angle,
    required this.length,
    required this.width,
    this.contrailSize,
    this.style,
    this.styleId,
    this.styleSpec,
  });

  /// Parses one raw `engineSlots` entry. Returns null if it lacks a usable
  /// location (the only field we strictly need to place a glow).
  static ShipEngineSlot? fromRaw(dynamic raw) {
    if (raw is! Map) return null;
    final loc = (raw['location'] as List?)
        ?.map((e) => (e as num).toDouble())
        .toList();
    if (loc == null || loc.length < 2) return null;
    final rawSpec = raw['styleSpec'];
    return ShipEngineSlot(
      location: loc,
      angle: (raw['angle'] as num?)?.toDouble() ?? 180,
      length: (raw['length'] as num?)?.toDouble() ?? 0,
      width: (raw['width'] as num?)?.toDouble() ?? 0,
      contrailSize: (raw['contrailSize'] as num?)?.toDouble(),
      style: raw['style'] as String?,
      styleId: raw['styleId'] as String?,
      styleSpec: rawSpec is Map ? EngineStyleSpec.fromJson(rawSpec) : null,
    );
  }
}
