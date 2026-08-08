import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/ship_viewer/utils/sprite_utils.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/utils/game_json_values.dart';
import 'package:trios/utils/log_collapser.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/ordered_sources_provider.dart';
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
  int? channel(int i) => doubleFromGameJson(value[i])?.round().clamp(0, 255);
  final r = channel(0), g = channel(1), b = channel(2);
  final a = value.length >= 4 ? channel(3) : 255;
  if (r == null || g == null || b == null || a == null) return null;
  return Color.fromARGB(a, r, g, b);
}

/// Merged `hull_styles.json` shield colors from the game core plus every
/// enabled mod, keyed by style id (e.g. `HIGH_TECH`). Deep-merged field by
/// field, so a mod that changes one style keeps the rest of vanilla's values.
final hullStyleShieldColorsProvider =
    FutureProvider<Map<String, ShieldStyleColors>>((ref) async {
      final core = ref.watch(AppState.gameCoreFolder).value;
      // Every mod, enabled or not. Watched through orderedSourcesProvider so
      // enabling a mod doesn't re-read this file out of every mod folder again.
      final sources = ref.watch(orderedSourcesProvider(false));

      final jsonSources = <SourceJson>[];
      for (final source in sources) {
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

/// Every shield texture override from every mod, as file paths, before the
/// images are loaded.
///
/// Only the fill texture is here. The game takes a ring texture too
/// (`ShieldAPI.setRadius`), but never draws it — it always draws the ring with
/// `graphics/hud/line8x8.png`, the same as TriOS does. So a ring texture in a
/// mod's file would be a value nothing anywhere uses.
class ShieldTextureOverridePaths {
  /// Hullmod id → the fill texture ships with that built-in hullmod use.
  final Map<String, String> byHullmod;

  /// Hull id → the fill texture that hull uses, whatever its hullmods say.
  final Map<String, String> byHull;

  const ShieldTextureOverridePaths({
    required this.byHullmod,
    required this.byHull,
  });

  static const empty = ShieldTextureOverridePaths(byHullmod: {}, byHull: {});

  bool get isEmpty => byHullmod.isEmpty && byHull.isEmpty;

  /// The fill texture for one hull: its own entry if it has one, otherwise the
  /// first of its built-in hullmods that has an entry. Null when neither
  /// matches, which means the ship draws the vanilla shield.
  ///
  /// A hull entry wins because it is the more specific thing the mod said. Mods
  /// use it for the exceptions to their own hullmod rule.
  String? forShip(String hullId, List<String>? builtInMods) {
    final hullEntry = byHull[hullId];
    if (hullEntry != null) return hullEntry;
    for (final hullmod in builtInMods ?? const <String>[]) {
      final entry = byHullmod[hullmod];
      if (entry != null) return entry;
    }
    return null;
  }
}

/// Reads the `shields` section out of a merged `trios.json`.
///
/// Anything shaped wrong is skipped rather than thrown, so one bad entry in one
/// mod can't stop the rest from loading.
ShieldTextureOverridePaths parseShieldTextureOverrides(
  Map<String, dynamic> merged,
) {
  final shields = merged['shields'];
  if (shields is! Map) return ShieldTextureOverridePaths.empty;
  return ShieldTextureOverridePaths(
    byHullmod: _shieldOverrideMap(shields['byHullmod']),
    byHull: _shieldOverrideMap(shields['byHull']),
  );
}

Map<String, String> _shieldOverrideMap(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, String>{};
  for (final entry in value.entries) {
    final id = entry.key;
    final fields = entry.value;
    if (id is! String || fields is! Map) continue;
    final inner = fields['textureInner'];
    // An entry that names no fill texture says nothing.
    if (inner is! String || inner.isEmpty) continue;
    result[id] = inner;
  }
  return result;
}

/// Shield texture overrides with their images already decoded, ready to draw.
class ShieldTextureImages {
  final ShieldTextureOverridePaths paths;

  /// Decoded fill images, keyed by the path written in the mod's file.
  final Map<String, ui.Image> fillsByPath;

  const ShieldTextureImages({required this.paths, required this.fillsByPath});

  static const empty = ShieldTextureImages(
    paths: ShieldTextureOverridePaths.empty,
    fillsByPath: {},
  );

  /// The fill image to draw for one hull, or null to draw the vanilla one.
  ui.Image? fillFor(String hullId, List<String>? builtInMods) {
    final path = paths.forShip(hullId, builtInMods);
    if (path == null) return null;
    return fillsByPath[path];
  }
}

/// TriOS's own shield texture list, shipped with the app. Read as if it were a
/// mod's file, and applied before any mod's, so a mod always wins.
const _builtInShieldTexturesAsset = 'assets/common/shield_textures.json';

/// The source name shown for TriOS's built-in list when merging.
const _builtInShieldTexturesSource = MergeSource(
  key: 'trios_built_in_shield_textures',
  name: 'TriOS',
);

/// Shield textures mods assign from Java code.
///
/// Comes from two places: TriOS's own list of mods it already knows about, and
/// a `data/config/trios.json` a mod can ship for itself. The mod's file wins,
/// so a mod can correct or add to what TriOS ships. Writing an empty
/// `textureInner` clears an entry, putting that ship back to the vanilla shield.
///
/// The game never reads `trios.json`. It exists because `ShieldAPI.setRadius`
/// swaps shield textures at runtime and nothing else on disk records it.
final shieldTextureOverridesProvider = FutureProvider<ShieldTextureImages>((
  ref,
) async {
  final core = ref.watch(AppState.gameCoreFolder).value;
  // Every mod, enabled or not — same as the other shield visuals.
  final sources = ref.watch(orderedSourcesProvider(false));
  final resolver = ref.watch(gameFileResolverProvider(false));

  final jsonSources = <SourceJson>[];

  // TriOS's list goes first so every mod's file is applied over it.
  try {
    jsonSources.add((
      source: _builtInShieldTexturesSource,
      json: (await rootBundle.loadString(
        _builtInShieldTexturesAsset,
      )).parseJsonToMap(),
    ));
  } catch (e, st) {
    Fimber.w(
      'Failed to read TriOS\'s built-in shield texture list: $e',
      ex: e,
      stacktrace: st,
    );
  }

  for (final source in sources) {
    final folder = source.isVanilla ? core : source.variant!.modFolder;
    if (folder == null || folder.path.isEmpty) continue;

    final file = p.join(folder.path, 'data', 'config', 'trios.json').toFile();
    if (!await file.exists()) continue;
    try {
      jsonSources.add((
        source: source,
        json: (await file.readAsString()).parseJsonToMap(),
      ));
    } catch (e, st) {
      Fimber.w(
        'Failed to parse trios.json in ${folder.path}: $e',
        ex: e,
        stacktrace: st,
      );
    }
  }
  if (jsonSources.isEmpty) return ShieldTextureImages.empty;

  final paths = parseShieldTextureOverrides(
    mergeTriosModConfig(jsonSources).merged,
  );
  if (paths.isEmpty) return ShieldTextureImages.empty;

  final issues = LogCollapser();
  final wantedPaths = {...paths.byHullmod.values, ...paths.byHull.values};

  final fillsByPath = <String, ui.Image>{};
  for (final path in wantedPaths) {
    final onDisk = resolver.resolve(path);
    if (onDisk == null) {
      issues.add('No file found for shield texture "$path".');
      continue;
    }
    final image = await loadDecodedImage(onDisk);
    if (image == null) {
      issues.add('Could not read shield texture "$path".');
      continue;
    }
    fillsByPath[path] = image;
  }
  issues.flush('Loading mod shield textures');

  return ShieldTextureImages(paths: paths, fillsByPath: fillsByPath);
});
