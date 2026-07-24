import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/ship_viewer/utils/sprite_utils.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/viewer_cache/graphics_index_manager.dart';

/// The two shield colors a hull style provides: the translucent inner fill and
/// the bright edge ring. These are the same colors the game uses when it draws
/// a ship's shield in combat.
class ShieldStyleColors {
  final Color inner;
  final Color ring;

  const ShieldStyleColors({required this.inner, required this.ring});

  /// The values the game falls back to for a MIDLINE hull — used when a ship's
  /// style isn't in the merged file.
  static const fallback = ShieldStyleColors(
    inner: Color.fromARGB(75, 125, 125, 255),
    ring: Color.fromARGB(255, 255, 255, 255),
  );
}

/// Reads an `[r, g, b, a]` (or `[r, g, b]`) color list out of a hull style.
/// Returns null if the value isn't a usable color list.
Color? _colorFromList(dynamic value) {
  if (value is! List || value.length < 3) return null;
  int channel(int i) => (value[i] as num).round().clamp(0, 255);
  final a = value.length >= 4 ? channel(3) : 255;
  return Color.fromARGB(a, channel(0), channel(1), channel(2));
}

/// Merged `hull_styles.json` shield colors from the game core plus every
/// enabled mod, keyed by style id (e.g. `HIGH_TECH`). Deep-merged field by
/// field, so a mod that changes one style keeps the rest of vanilla's values.
final hullStyleShieldColorsProvider =
    FutureProvider<Map<String, ShieldStyleColors>>((ref) async {
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
            .join(folder.path, 'data', 'config', 'hull_styles.json')
            .toFile();
        if (!await file.exists()) continue;
        try {
          jsonSources.add((
            source: source,
            json: (await file.readAsString()).parseJsonToMap(),
          ));
        } catch (e, st) {
          Fimber.w(
            'Failed to parse hull_styles.json in ${folder.path}: $e',
            ex: e,
            stacktrace: st,
          );
        }
      }

      final merged = mergeHullStyles(jsonSources);

      final result = <String, ShieldStyleColors>{};
      for (final entry in merged.merged.entries) {
        final value = entry.value;
        if (value is! Map) continue;
        final inner = _colorFromList(value['shieldInnerColor']);
        final ring = _colorFromList(value['shieldRingColor']);
        // A style with no shield colors (there are a few) just uses the
        // fallback wherever it's looked up.
        if (inner == null && ring == null) continue;
        result[entry.key] = ShieldStyleColors(
          inner: inner ?? ShieldStyleColors.fallback.inner,
          ring: ring ?? ShieldStyleColors.fallback.ring,
        );
      }
      return result;
    });

/// The shield textures, decoded from the game core. These are the same ones the
/// game uses when it draws shields in combat: a cloudy rim-glow for the inner
/// fill (picked by radius) and a soft-edged line for the edge ring.
class ShieldSprites {
  /// `graphics/fx/shields64.png` — the inner fill for small shields.
  final ui.Image fill64;

  /// `graphics/fx/shields128c.png` — the inner fill for medium shields.
  final ui.Image fill128;

  /// `graphics/fx/shields256.png` — the inner fill for large shields.
  final ui.Image fill256;

  /// `graphics/hud/line8x8.png` — a soft-edged line used across the ring's
  /// thickness so its edges fade out.
  final ui.Image ring;

  const ShieldSprites({
    required this.fill64,
    required this.fill128,
    required this.fill256,
    required this.ring,
  });

  /// The inner-fill texture the game would use for a shield of this radius.
  ui.Image fillForRadius(double radius) {
    if (radius >= 128) return fill256;
    if (radius >= 64) return fill128;
    return fill64;
  }
}

/// Decodes the four shield textures the game uses. Null if any is missing.
///
/// These go through the normal game file lookup rather than reading the game
/// folder directly, because a mod can ship its own copy of one of these files
/// and the game would use the mod's version. That's the only way to change the
/// shield pattern from files — there's no shield texture setting anywhere in
/// `hull_styles.json` or the `.ship` files. (A mod's Java code can also swap
/// the texture at runtime, but nothing on disk records that, so it can't be
/// shown here.)
final shieldSpritesProvider = FutureProvider<ShieldSprites?>((ref) async {
  // Every mod, enabled or not — same as the engine glow sprites.
  final resolver = ref.watch(gameFileResolverProvider(false));

  Future<ui.Image?> load(String gamePath) async {
    final onDisk = resolver.resolve(gamePath);
    if (onDisk == null) return null;
    return loadDecodedImage(onDisk);
  }

  final fill64 = await load('graphics/fx/shields64.png');
  final fill128 = await load('graphics/fx/shields128c.png');
  final fill256 = await load('graphics/fx/shields256.png');
  final ring = await load('graphics/hud/line8x8.png');
  if (fill64 == null || fill128 == null || fill256 == null || ring == null) {
    return null;
  }

  return ShieldSprites(
    fill64: fill64,
    fill128: fill128,
    fill256: fill256,
    ring: ring,
  );
});
