import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/hullmodViewer/hullmods_manager.dart';
import 'package:trios/hullmodViewer/models/hullmod.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/portraits/portrait_model.dart';
import 'package:trios/shipViewer/models/shipGpt.dart';
import 'package:trios/shipViewer/ship_manager.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/weaponViewer/models/weapon.dart';
import 'package:trios/weaponViewer/weapons_manager.dart';

/// Mixin for intents that need access to ship, weapon, hullmod, or portrait data.
mixin ViewerAwareIntent {
  Ref get ref;

  List<Ship>? get ships => ref.read(shipListNotifierProvider).valueOrNull;

  List<Weapon>? get weapons =>
      ref.read(weaponListNotifierProvider).valueOrNull;

  List<Hullmod>? get hullmods =>
      ref.read(hullmodListNotifierProvider).valueOrNull;

  Map<ModVariant?, List<Portrait>>? get portraits =>
      ref.read(AppState.portraits).valueOrNull;

  static const noViewerDataMessage =
      "Viewer data hasn't loaded yet. Make sure your game folder is "
      "configured in Settings and try opening the relevant viewer page first.";
}
