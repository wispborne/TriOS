import 'dart:math';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/ship_viewer/models/ship_engine_style_spec.dart';
import 'package:trios/ship_viewer/utils/sprite_utils.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/viewer_cache/graphics_index_manager.dart';
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

/// The engine flame sprites, decoded from the game core. These are the same
/// three the game uses when it draws engines in combat.
class EngineGlowSprites {
  /// `engineglow32.png` — the flame body for styles with `"type":"GLOW"`.
  final ui.Image flameGlow;

  /// `engineglow32s.png` — the flame body for styles with `"type":"SMOKE"`.
  final ui.Image flameSmoke;

  /// `engineflame32.png` — a teardrop shape laid faintly over the whole flame.
  /// Fighters don't get one.
  final ui.Image outline;

  /// `hit_glow.png` — the round bloom drawn at the engine nozzle.
  final ui.Image bloom;

  /// `smoke32.png` — one puff of a SMOKE-style contrail.
  final ui.Image smoke;

  /// `contrail64b.png` — the ribbon texture for QUAD_STRIP contrails (OMEGA).
  final ui.Image ribbon;

  /// `particlealpha32sq.png` — one GLOW-style contrail particle, read from
  /// inside `fs.common_obf.jar` (a generated look-alike if the jar is
  /// unreadable).
  final ui.Image particle;

  /// Sprites named by a style's `glowSprite` / `glowOutline`, keyed by the path
  /// as written in `engine_styles.json`. Paths that don't resolve are missing.
  final Map<String, ui.Image> custom;

  const EngineGlowSprites({
    required this.flameGlow,
    required this.flameSmoke,
    required this.outline,
    required this.bloom,
    required this.smoke,
    required this.ribbon,
    required this.particle,
    this.custom = const {},
  });
}

/// Reads the game's real contrail particle texture,
/// `graphics/particlealpha32sq.png`, out of `fs.common_obf.jar` — it isn't in
/// the game folder as a loose file. Null if the jar or the entry is missing.
Future<ui.Image?> _loadParticleTextureFromJar(String corePath) async {
  try {
    final jar = p.join(corePath, 'fs.common_obf.jar').toFile();
    if (!await jar.exists()) return null;
    final zip = ZipDecoder().decodeBytes(await jar.readAsBytes());
    final entry = zip.findFile('graphics/particlealpha32sq.png');
    if (entry == null) return null;
    final codec = await ui.instantiateImageCodec(entry.readBytes()!);
    return (await codec.getNextFrame()).image;
  } catch (e, st) {
    Fimber.w(
      'Could not read the contrail particle texture from fs.common_obf.jar: $e',
      ex: e,
      stacktrace: st,
    );
    return null;
  }
}

/// Stand-in for [_loadParticleTextureFromJar] when the jar can't be read: the
/// same falloff as the real texture, alpha = (1 - r)² from a bright centre.
Future<ui.Image> _makeParticleBlob() {
  const size = 32;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final center = ui.Offset(size / 2, size / 2);
  canvas.drawCircle(
    center,
    size / 2,
    ui.Paint()
      ..shader = ui.Gradient.radial(
        center,
        size / 2,
        [
          for (var i = 0; i <= 8; i++)
            ui.Color.fromARGB((255 * pow(1 - i / 8, 2)).round(), 255, 255, 255),
        ],
        [for (var i = 0; i <= 8; i++) i / 8],
      ),
  );
  return recorder.endRecording().toImage(size, size);
}

/// Decodes the engine flame sprites: the four the game always uses, plus any
/// sprite a style names itself. Null until the game core is known, or if one of
/// the four is missing.
final engineGlowSpritesProvider = FutureProvider<EngineGlowSprites?>((
  ref,
) async {
  final core = ref.watch(AppState.gameCoreFolder).value;
  if (core == null || core.path.isEmpty) return null;

  Future<ui.Image?> fx(String name) =>
      loadDecodedImage(p.join(core.path, 'graphics', 'fx', name));

  final flameGlow = await fx('engineglow32.png');
  final flameSmoke = await fx('engineglow32s.png');
  final outline = await fx('engineflame32.png');
  final bloom = await fx('hit_glow.png');
  final smoke = await fx('smoke32.png');
  final ribbon = await fx('contrail64b.png');
  if (flameGlow == null ||
      flameSmoke == null ||
      outline == null ||
      bloom == null ||
      smoke == null ||
      ribbon == null) {
    return null;
  }

  // A style can name its own flame or outline sprite, and that sprite can come
  // from a mod, so it goes through the same lookup as any other game file.
  final styles = await ref.watch(engineStylesProvider.future);
  final resolver = ref.watch(gameFileResolverProvider(false));
  final wanted = <String>{
    for (final style in styles.values) ...[
      ?style.glowSprite,
      ?style.glowOutline,
    ],
  };

  final custom = <String, ui.Image>{};
  for (final path in wanted) {
    final onDisk = resolver.resolve(path);
    if (onDisk == null) continue;
    final image = await loadDecodedImage(onDisk);
    if (image != null) custom[path] = image;
  }

  return EngineGlowSprites(
    flameGlow: flameGlow,
    flameSmoke: flameSmoke,
    outline: outline,
    bloom: bloom,
    smoke: smoke,
    ribbon: ribbon,
    particle:
        await _loadParticleTextureFromJar(core.path) ??
        await _makeParticleBlob(),
    custom: custom,
  );
});
