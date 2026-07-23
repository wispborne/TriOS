import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/hullmod_viewer/hullmods_manager.dart';
import 'package:trios/hullmod_viewer/models/hullmod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/ship_viewer/models/ship.dart';
import 'package:trios/ship_viewer/ship_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/weapon_viewer/models/weapon.dart';
import 'package:trios/weapon_viewer/weapons_manager.dart';

/// Mixin for intents that need access to ship, weapon, hullmod, or portrait data.
mixin ViewerAwareIntent {
  Ref get ref;

  /// Every mod, enabled or not, so questions about an installed mod still get
  /// an answer while it's switched off.
  List<Ship>? get ships => ref.read(shipListNotifierProvider(false)).valueOrNull;

  List<Weapon>? get weapons =>
      ref.read(weaponListNotifierProvider(false)).valueOrNull;

  List<Hullmod>? get hullmods =>
      ref.read(hullmodListNotifierProvider).valueOrNull;

  Map<ModVariant?, List<Portrait>>? get portraits =>
      ref.read(AppState.portraits).valueOrNull;

  static const noViewerDataMessage =
      "Viewer data hasn't loaded yet. Make sure your game folder is "
      "configured in Settings and try opening the relevant viewer page first.";
}
