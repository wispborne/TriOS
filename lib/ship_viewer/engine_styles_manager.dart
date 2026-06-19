import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/ship_viewer/models/ship_engine_style_spec.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

/// Merged `engine_styles.json` from the game core plus every enabled mod,
/// keyed by style id (e.g. `HIGH_TECH`). Later folders override earlier ones,
/// matching how Starsector merges config across mods.
final engineStylesProvider = FutureProvider<Map<String, EngineStyleSpec>>((
  ref,
) async {
  final result = <String, EngineStyleSpec>{};

  final folders = <Directory>[];
  final core = ref.watch(AppState.gameCoreFolder).value;
  if (core != null && core.path.isNotEmpty) folders.add(core);
  for (final mod in ref.watch(AppState.mods)) {
    final variant = mod.findFirstEnabledOrHighestVersion;
    if (variant != null) folders.add(variant.modFolder);
  }

  for (final folder in folders) {
    final file = p
        .join(folder.path, 'data', 'config', 'engine_styles.json')
        .toFile();
    if (!await file.exists()) continue;
    try {
      final map = (await file.readAsString()).parseJsonToMap();
      for (final entry in map.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        try {
          result[entry.key] = EngineStyleSpec.fromJson(value);
        } catch (e) {
          // One malformed style shouldn't drop the rest of the file's styles.
          Fimber.w('Skipping engine style "${entry.key}" in ${folder.path}: $e');
        }
      }
    } catch (e, st) {
      Fimber.w('Failed to parse engine_styles.json in ${folder.path}: $e',
          ex: e, stacktrace: st);
    }
  }

  return result;
});

/// The two default engine glow sprites, decoded from the game core.
class EngineGlowSprites {
  /// `engineflame32.png` — the teardrop flame (wide base on the left, tip
  /// on the right, so it points along +x in image space).
  final ui.Image flame;

  /// `engineglow32.png` — the round bloom drawn at the engine nozzle.
  final ui.Image glow;

  const EngineGlowSprites({required this.flame, required this.glow});
}

/// Decodes the default engine glow sprites from the game core's `graphics/fx`.
/// Null until the game core is known or if either sprite is missing.
final engineGlowSpritesProvider = FutureProvider<EngineGlowSprites?>((
  ref,
) async {
  final core = ref.watch(AppState.gameCoreFolder).value;
  if (core == null || core.path.isEmpty) return null;
  final flame = await _decodeImage(
    p.join(core.path, 'graphics', 'fx', 'engineflame32.png'),
  );
  final glow = await _decodeImage(
    p.join(core.path, 'graphics', 'fx', 'engineglow32.png'),
  );
  if (flame == null || glow == null) return null;
  return EngineGlowSprites(flame: flame, glow: glow);
});

Future<ui.Image?> _decodeImage(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    return (await codec.getNextFrame()).image;
  } catch (_) {
    return null;
  }
}
