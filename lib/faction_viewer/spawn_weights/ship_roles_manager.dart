import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:trios/faction_viewer/faction_merge.dart';
import 'package:trios/faction_viewer/models/faction.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

/// Name used for game-core data, matching `faction_manager.dart` so
/// attributions from both sources can be compared by name.
const String kVanillaSourceName = 'Vanilla';

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
/// enabled mod, in the game's load order.
final mergedShipRolesProvider = FutureProvider<MergedShipRoles>((ref) async {
  final gameCore = ref.watch(AppState.gameCoreFolder).value;
  if (gameCore == null) return MergedShipRoles.empty;

  final variants = ref
      .watch(AppState.mods)
      .map((mod) => mod.findFirstEnabledOrHighestVersion)
      .nonNulls
      .sortedByGameLoadOrder();

  final sources = <(String, Directory)>[
    (kVanillaSourceName, gameCore),
    for (final variant in variants)
      (variant.modInfo.nameOrId, variant.modFolder),
  ];

  var merged = <String, dynamic>{};
  var attributions = <String, List<SourceContribution>>{};
  var itemAttributions = <String, Map<String, String>>{};
  final sourceFiles = <String, File>{};

  for (final (sourceName, folder) in sources) {
    final file = File(p.join(folder.path, _shipRolesRelativePath));
    if (!await file.exists()) continue;

    try {
      final content = await file.readAsStringUtf8OrLatin1();
      final json = await content.removeJsonComments().parseJsonToMapAsync();

      final result = mergeFactionJson(
        base: merged,
        overlay: json,
        sourceName: sourceName,
        existingAttributions: attributions,
        existingItemAttributions: itemAttributions,
      );
      merged = result.merged;
      attributions = result.attributions;
      itemAttributions = result.itemAttributions;
      sourceFiles[sourceName] = file;
    } catch (e, st) {
      Fimber.w(
        '[$sourceName] Error parsing ${file.path}: $e',
        ex: e,
        stacktrace: st,
      );
    }
  }

  return MergedShipRoles(
    roles: _buildRoles(merged, itemAttributions),
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
