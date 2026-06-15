/// A single row from a Starsector `data/strings/descriptions.csv` file.
///
/// The same [id] may appear multiple times with different [type] values,
/// so the natural lookup key is `(id, type)`.
class DescriptionEntry {
  /// Type column values used in descriptions.csv.
  static const typeShip = 'SHIP';
  static const typeWeapon = 'WEAPON';
  static const typeHullMod = 'HULL_MOD';
  static const typeShipSystem = 'SHIP_SYSTEM';
  static const typeResource = 'RESOURCE';
  static const typePlanet = 'PLANET';
  static const typeCustom = 'CUSTOM';

  final String id;

  /// Entity type, e.g. [typeShip], [typeWeapon], [typeHullMod], etc.
  final String type;

  /// Primary description text.
  final String? text1;

  /// Secondary text (e.g. short category label like "Offensive").
  final String? text2;

  /// Detailed description, may contain `%s` substitution placeholders.
  final String? text3;

  /// Highlight / substitution values for [text3] (pipe-separated in the CSV).
  final String? text4;

  const DescriptionEntry({
    required this.id,
    required this.type,
    this.text1,
    this.text2,
    this.text3,
    this.text4,
  });
}
