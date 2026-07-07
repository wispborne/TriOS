import 'package:trios/codex/models/codex_entry.dart';

/// Searches [pool] the way the game's Codex does: case-insensitive substring
/// over `displayName` + `id`, with names that *start with* the query ranked
/// above plain substring matches, alphabetical (by sort name) within each rank.
///
/// [pool] is already scoped by the caller — the current category's listed
/// entries, or the whole listed index at the top level.
List<CodexEntry> codexSearch(String query, List<CodexEntry> pool) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final startsWith = <CodexEntry>[];
  final contains = <CodexEntry>[];

  for (final entry in pool) {
    final name = entry.displayName.toLowerCase();
    final id = entry.id.toLowerCase();
    if (name.startsWith(q) || id.startsWith(q)) {
      startsWith.add(entry);
    } else if (name.contains(q) || id.contains(q)) {
      contains.add(entry);
    }
  }

  int byName(CodexEntry a, CodexEntry b) =>
      a.sortName.toLowerCase().compareTo(b.sortName.toLowerCase());
  startsWith.sort(byName);
  contains.sort(byName);

  return [...startsWith, ...contains];
}
