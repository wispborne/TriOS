import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/game_data_merge.dart';
import 'package:trios/utils/logging.dart';
import 'package:trios/utils/ordered_sources_provider.dart';

const String _shipRolesRelativePath = 'data/world/factions/'
    'default_ship_roles.json';

/// Keys inside a role that aren't ship weights.
const _nonWeightKeys = {'fallback', 'fallback2', 'includeDefault'};

/// One role's shared default list, after merging every mod's copy of
/// `default_ship_roles.json`.
class DefaultShipRole {
  final String name;

  /// Loadout id → weight, as written in the files (before any faction filters).
  final Map<String, double> weights;

  /// Loadout id → the mod that set that weight last (last writer wins).
  final Map<String, String> sources;

  /// The role the game picks from instead when this one ends up empty.
  final String? fallbackRole;
  final String? fallbackRole2;

  const DefaultShipRole({
    required this.name,
    required this.weights,
    required this.sources,
    this.fallbackRole,
    this.fallbackRole2,
  });
}

/// The merged `default_ship_roles.json` across the game and every enabled mod.
class MergedShipRoles {
  final Map<String, DefaultShipRole> roles;

  /// Source name → the `default_ship_roles.json` file it came from, so the UI
  /// can open the file that set a weight.
  final Map<String, File> sourceFiles;

  const MergedShipRoles({required this.roles, required this.sourceFiles});

  static const empty = MergedShipRoles(roles: {}, sourceFiles: {});
}

/// Reads and merges `default_ship_roles.json` from the game core and every
/// installed mod, in the game's load order. With [onlyEnabledMods] on, mods
/// that aren't enabled are left out.
final mergedShipRolesProvider =
    FutureProvider.family<MergedShipRoles, bool>((ref, onlyEnabledMods) async {
  final gameCore = ref.watch(AppState.gameCoreFolder).value;
  if (gameCore == null) return MergedShipRoles.empty;

  // In merge order, so a mod that isn't enabled sorts behind the game core and
  // can't rewrite vanilla's roles. Watched through orderedSourcesProvider, which
  // holds still unless the sources actually changed — a toggle does move one, so
  // that re-reads this file out of every mod folder, one small JSON each.
  final sources = ref.watch(orderedSourcesProvider(onlyEnabledMods));

  final jsonSources = <SourceJson>[];
  final sourceFiles = <String, File>{};

  for (final source in sources) {
    final folder = source.variant?.modFolder ?? gameCore;
    final file = File(p.join(folder.path, _shipRolesRelativePath));
    if (!await file.exists()) continue;

    try {
      final content = await file.readAsStringUtf8OrLatin1();
      final json = await content.parseJsonToMapAsync();
      jsonSources.add((source: source, json: json));
      sourceFiles[source.name] = file;
    } catch (e, st) {
      Fimber.w(
        '[${source.name}] Error parsing ${file.path}: $e',
        ex: e,
        stacktrace: st,
      );
    }
  }

  final merged = mergeShipRoles(jsonSources);

  return MergedShipRoles(
    roles: _buildRoles(merged.merged, merged.itemAttributions),
    sourceFiles: sourceFiles,
  );
});

Map<String, DefaultShipRole> _buildRoles(
  Map<String, dynamic> merged,
  Map<String, Map<String, String>> itemAttributions,
) {
  final roles = <String, DefaultShipRole>{};

  for (final entry in merged.entries) {
    final body = entry.value;
    if (body is! Map<String, dynamic>) continue;

    final roleName = entry.key;
    final attrs = itemAttributions[roleName] ?? const {};
    final weights = <String, double>{};
    final sources = <String, String>{};

    for (final weightEntry in body.entries) {
      if (_nonWeightKeys.contains(weightEntry.key)) continue;
      final weight = toDoubleOrNull(weightEntry.value);
      if (weight == null) continue;
      weights[weightEntry.key] = weight;
      final source = attrs[weightEntry.key];
      if (source != null) sources[weightEntry.key] = source;
    }

    roles[roleName] = DefaultShipRole(
      name: roleName,
      weights: weights,
      sources: sources,
      fallbackRole: _firstKeyOf(body['fallback']),
      fallbackRole2: _firstKeyOf(body['fallback2']),
    );
  }

  return roles;
}

/// `"fallback":{"combatMedium":0.5}` — we only need the role name.
String? _firstKeyOf(dynamic value) {
  if (value is Map && value.isNotEmpty) return value.keys.first.toString();
  return null;
}

/// Weights in these files are numbers, but a stray quoted number or a Java
/// suffix (`1f`, parsed to the string "1f") shouldn't silently drop an entry.
double? toDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return value.toDoubleOrNullAllowingJavaSuffix();
  return null;
}
