import 'dart:io';

import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/game_data_merge.dart';

/// One mod's own copy of a data file behind an item — its `.wpn`, its `.ship`,
/// its `weapon_data.csv`, and so on.
///
/// Several mods can each ship a file for the same weapon or ship (Emergent
/// Threats rewrites vanilla's `autopulse.wpn`, say), and the game reads all of
/// them. The "open file" menus list every one instead of only the winner.
class ModDataFile {
  /// The mod's display name, or "Vanilla" for the game's own copy.
  final String modName;

  final File file;

  /// Whether this is the copy whose values take effect where they overlap.
  final bool isEffective;

  final bool isVanilla;

  const ModDataFile({
    required this.modName,
    required this.file,
    required this.isEffective,
    required this.isVanilla,
  });
}

/// Collects one file per source, skipping sources that don't have one.
///
/// [sourcesEffectiveFirst] must already be ordered with the winning source
/// first — `MergedSpec.rowContributors` already is, and
/// [sideFileSourcesInDisplayOrder] puts side-file contributors in that order.
/// [pathOf] returns that source's own copy of the file, or null when it has
/// none.
List<ModDataFile> collectModDataFiles(
  List<MergeSource> sourcesEffectiveFirst,
  String? Function(MergeSource source) pathOf,
) {
  final files = <ModDataFile>[];
  for (final source in sourcesEffectiveFirst) {
    final path = pathOf(source);
    if (path == null || path.isEmpty) continue;
    files.add(
      ModDataFile(
        modName: source.name,
        file: path.toFile(),
        isEffective: files.isEmpty,
        isVanilla: source.isVanilla,
      ),
    );
  }
  return files;
}
