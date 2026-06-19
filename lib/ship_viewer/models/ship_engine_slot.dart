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

  /// Engine style id (e.g. `HIGH_TECH`), keyed into `engine_styles.json`.
  /// Null means inherit the hull's top-level `style`.
  final String? style;

  const ShipEngineSlot({
    required this.location,
    required this.angle,
    required this.length,
    required this.width,
    this.contrailSize,
    this.style,
  });

  /// Parses one raw `engineSlots` entry. Returns null if it lacks a usable
  /// location (the only field we strictly need to place a glow).
  static ShipEngineSlot? fromRaw(dynamic raw) {
    if (raw is! Map) return null;
    final loc = (raw['location'] as List?)
        ?.map((e) => (e as num).toDouble())
        .toList();
    if (loc == null || loc.length < 2) return null;
    return ShipEngineSlot(
      location: loc,
      angle: (raw['angle'] as num?)?.toDouble() ?? 180,
      length: (raw['length'] as num?)?.toDouble() ?? 0,
      width: (raw['width'] as num?)?.toDouble() ?? 0,
      contrailSize: (raw['contrailSize'] as num?)?.toDouble(),
      style: raw['style'] as String?,
    );
  }
}
