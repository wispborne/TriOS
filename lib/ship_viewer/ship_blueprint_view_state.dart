import 'package:dart_mappable/dart_mappable.dart';

part 'ship_blueprint_view_state.mapper.dart';

/// Which layers the interactive ship blueprint view shows, plus whether shields
/// animate. Saved to app settings and shared by every interactive blueprint
/// view in the app, so the choices stick across restarts no matter where the
/// view appears (ship details dialog, codex, and so on).
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
  });
}
