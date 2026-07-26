import 'dart:ui';

import 'package:dart_mappable/dart_mappable.dart';

part 'ship_blueprint_view_state.mapper.dart';

/// What to show behind the ship in the interactive blueprint view: nothing, a
/// flat color, or one of the game's own space pictures. "Transparent" shows
/// nothing, letting whatever is behind the view show through.
///
/// The picture file names are written out here rather than found by scanning,
/// so a future game version could add ones we don't list, or drop ones we do.
/// A name the game doesn't have simply isn't offered.
@MappableEnum(defaultValue: ShipBlueprintBackground.background2)
enum ShipBlueprintBackground {
  transparent,
  black,
  darkGrey,
  lightGrey,
  white,
  darkBlue,
  darkRed,
  background1,
  background2,
  background3,
  background4,
  background5,
  background6,
  galatia,
  hyperspace,
  hyperspaceCool;

  /// The flat color to paint, or null for "Transparent" and the pictures.
  Color? get color => switch (this) {
    ShipBlueprintBackground.black => const Color(0xFF000000),
    ShipBlueprintBackground.darkGrey => const Color(0xFF2B2B2B),
    ShipBlueprintBackground.lightGrey => const Color(0xFFB0B0B0),
    ShipBlueprintBackground.white => const Color(0xFFFFFFFF),
    ShipBlueprintBackground.darkBlue => const Color(0xFF0D2B45),
    ShipBlueprintBackground.darkRed => const Color(0xFF3A1214),
    _ => null,
  };

  /// Where the picture lives, written the way the game's own data files write
  /// it, or null for "Transparent" and the flat colors. Looked up the way the
  /// game looks it up, so a mod that replaces the file wins.
  String? get imagePath => switch (this) {
    ShipBlueprintBackground.background1 =>
      'graphics/backgrounds/background1.jpg',
    ShipBlueprintBackground.background2 =>
      'graphics/backgrounds/background2.jpg',
    ShipBlueprintBackground.background3 =>
      'graphics/backgrounds/background3.jpg',
    ShipBlueprintBackground.background4 =>
      'graphics/backgrounds/background4.jpg',
    ShipBlueprintBackground.background5 =>
      'graphics/backgrounds/background5.jpg',
    ShipBlueprintBackground.background6 =>
      'graphics/backgrounds/background6.jpg',
    ShipBlueprintBackground.galatia =>
      'graphics/backgrounds/background_galatia.jpg',
    ShipBlueprintBackground.hyperspace =>
      'graphics/backgrounds/hyperspace1.jpg',
    ShipBlueprintBackground.hyperspaceCool =>
      'graphics/backgrounds/hyperspace_bg_cool.jpg',
    _ => null,
  };

  String get label => switch (this) {
    ShipBlueprintBackground.transparent => 'Transparent',
    ShipBlueprintBackground.black => 'Black',
    ShipBlueprintBackground.darkGrey => 'Dark grey',
    ShipBlueprintBackground.lightGrey => 'Light grey',
    ShipBlueprintBackground.white => 'White',
    ShipBlueprintBackground.darkBlue => 'Dark blue',
    ShipBlueprintBackground.darkRed => 'Dark red',
    ShipBlueprintBackground.background1 => 'Space 1',
    ShipBlueprintBackground.background2 => 'Space 2',
    ShipBlueprintBackground.background3 => 'Space 3',
    ShipBlueprintBackground.background4 => 'Space 4',
    ShipBlueprintBackground.background5 => 'Space 5',
    ShipBlueprintBackground.background6 => 'Space 6',
    ShipBlueprintBackground.galatia => 'Galatia',
    ShipBlueprintBackground.hyperspace => 'Hyperspace',
    ShipBlueprintBackground.hyperspaceCool => 'Hyperspace (cool)',
  };
}

/// Which layers the interactive ship blueprint view shows, plus its animation
/// and background choices. Saved to app settings and shared by every
/// interactive blueprint view in the app, so the choices stick across restarts
/// no matter where the view appears (ship details dialog, codex, and so on).
///
/// Thumbnails (the non-interactive `ShipBlueprintView.minimal`) don't use this
/// — they're controlled by their own constructor values.
///
/// The defaults match the view's constructor defaults, so a first run looks the
/// same as before this was saved.
@MappableClass()
class ShipBlueprintViewState with ShipBlueprintViewStateMappable {
  final bool showModules;
  final bool showBounds;
  final bool showMounts;
  final bool showArcs;
  final bool showWeapons;
  final bool showDecorativeWeapons;
  final bool showEngineGlow;
  final bool showShield;
  final bool animateShields;
  final bool animateEngines;
  final ShipBlueprintBackground background;

  const ShipBlueprintViewState({
    this.showModules = true,
    this.showBounds = false,
    this.showMounts = true,
    this.showArcs = true,
    this.showWeapons = true,
    this.showDecorativeWeapons = true,
    this.showEngineGlow = true,
    this.showShield = true,
    this.animateShields = true,
    this.animateEngines = true,
    this.background = ShipBlueprintBackground.background2,
  });
}
