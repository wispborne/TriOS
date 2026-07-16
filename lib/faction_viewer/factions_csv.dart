import 'dart:convert';

import 'package:trios/utils/csv_parse_utils.dart';

/// Parses a `data/world/factions/factions.csv` and returns the merge keys of
/// the factions it registers.
///
/// A `.faction` file only becomes a faction in-game if some source lists its
/// path in `factions.csv` (the game merges that CSV across vanilla and all
/// mods). A mod that ships a `.faction` file *without* a matching CSV row is
/// only patching a faction registered elsewhere.
///
/// Returned keys are normalized to match [Faction.mergeKey] comparisons:
/// relative to `data/world/factions/`, no `.faction` extension, forward
/// slashes, lowercase. Rows pointing outside `data/world/factions/` keep
/// their full path (they can never match a scanned faction, which is
/// correct — TriOS doesn't scan outside that folder).
Set<String> parseFactionsCsvKeys(String csvContent) {
  const prefix = 'data/world/factions/';
  final keys = <String>{};

  for (final rawLine in const LineSplitter().convert(csvContent)) {
    final line = rawLine.removeCsvLineComments().trim();
    if (line.isEmpty) continue;

    // factions.csv is single-column, but be lenient about extra columns.
    var cell = line.split(',').first.trim();
    if (cell.startsWith('"') && cell.endsWith('"') && cell.length >= 2) {
      cell = cell.substring(1, cell.length - 1).trim();
    }
    if (cell.isEmpty) continue;

    var path = cell.replaceAll('\\', '/').toLowerCase();
    // Skip the header row.
    if (path == 'faction') continue;
    if (path.startsWith(prefix)) path = path.substring(prefix.length);
    if (path.endsWith('.faction')) {
      path = path.substring(0, path.length - '.faction'.length);
    }
    keys.add(path);
  }
  return keys;
}
