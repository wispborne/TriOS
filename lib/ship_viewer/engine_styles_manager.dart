import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/ship_viewer/models/ship_engine_style_spec.dart';
import 'package:trios/ship_viewer/utils/sprite_utils.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/utils/logging.dart';

/// Merged `engine_styles.json` from the game core plus every enabled mod,
/// keyed by style id (e.g. `HIGH_TECH`). Deep-merged field by field, so a mod
/// that sets one field of a style keeps the rest of vanilla's values.
final engineStylesProvider = FutureProvider<Map<String, EngineStyleSpec>>((
  ref,
) async {
  final core = ref.watch(AppState.gameCoreFolder).value;
  final variants = ref
      .watch(AppState.mods)
      .map((mod) => mod.findFirstEnabledOrHighestVersion)
      .nonNulls;

  final jsonSources = <SourceJson>[];
  for (final source in orderedSources(variants)) {
    final folder = source.isVanilla ? core : source.variant!.modFolder;
    if (folder == null || folder.path.isEmpty) continue;

    final file = p
        .join(folder.path, 'data', 'config', 'engine_styles.json')
        .toFile();
    if (!await file.exists()) continue;
    try {
      jsonSources.add((
        source: source,
        json: (await file.readAsString()).parseJsonToMap(),
      ));
    } catch (e, st) {
      Fimber.w(
        'Failed to parse engine_styles.json in ${folder.path}: $e',
        ex: e,
        stacktrace: st,
      );
    }
  }

  final merged = mergeEngineStyles(jsonSources);

  final result = <String, EngineStyleSpec>{};
  for (final entry in merged.merged.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    try {
      result[entry.key] = EngineStyleSpec.fromJson(value);
    } catch (e) {
      // One malformed style shouldn't drop the rest.
      Fimber.w('Skipping engine style "${entry.key}": $e');
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
  final flame = await decodeImageFile(
    p.join(core.path, 'graphics', 'fx', 'engineflame32.png'),
  );
  final glow = await decodeImageFile(
    p.join(core.path, 'graphics', 'fx', 'engineglow32.png'),
  );
  if (flame == null || glow == null) return null;
  return EngineGlowSprites(flame: flame, glow: glow);
});
