import 'package:trios/catalog/models/catalog_mod.dart';

/// How many mods each of the More by author and Similar mods lists shows.
const int relatedModsLimit = 5;

/// Other catalog mods by any of [mod]'s authors, newest first, at most
/// [relatedModsLimit].
///
/// Authors match when their names are the same ignoring case. Each side's
/// other known names count too, from the extras record and TriOS's own list.
/// See [newestFirst] for the order.
List<CatalogMod> moreByAuthor(CatalogMod mod, List<CatalogMod> allMods) {
  final authors = authorNamesOf(mod);
  if (authors.isEmpty) return const [];
  final matches = [
    for (final other in allMods)
      if (!_isSameMod(other, mod) && authorNamesOf(other).any(authors.contains))
        other,
  ]..sort(newestFirst);
  return matches.take(relatedModsLimit).toList();
}

/// Catalog mods by other authors that share at least one category with [mod],
/// at most [relatedModsLimit]. The ones sharing the most categories come
/// first, then the newest (see [newestFirst]).
///
/// A mod that shares an author goes in [moreByAuthor] instead, never here.
/// Uses [CatalogMod.categories]: the cleaned-up ones when the extras record
/// has them, the catalog's own otherwise.
List<CatalogMod> similarMods(CatalogMod mod, List<CatalogMod> allMods) {
  final categories = _lowercased(mod.categories);
  if (categories.isEmpty) return const [];
  final authors = authorNamesOf(mod);

  final shared = <CatalogMod, int>{};
  for (final other in allMods) {
    if (_isSameMod(other, mod)) continue;
    if (authorNamesOf(other).any(authors.contains)) continue;
    final count = _lowercased(other.categories).where(categories.contains);
    if (count.isNotEmpty) shared[other] = count.length;
  }

  final matches = shared.keys.toList()
    ..sort((a, b) {
      final byShared = shared[b]!.compareTo(shared[a]!);
      return byShared != 0 ? byShared : newestFirst(a, b);
    });
  return matches.take(relatedModsLimit).toList();
}

/// Every name [mod]'s authors go by, lowercased: the credited names, their
/// other names from the extras record, and TriOS's own list of other names.
Set<String> authorNamesOf(CatalogMod mod) => _lowercased([
  ...mod.entry.getAuthors(),
  ...?mod.extras?.otherAuthorNames.values.expand((names) => names),
  ...mod.otherAuthorNames,
]);

/// Sorts newer mods first. A mod's date is its last release when known, else
/// its last edit, else when it was added. Mods with no date go last.
int newestFirst(CatalogMod a, CatalogMod b) {
  final dayA = _newestDay(a);
  final dayB = _newestDay(b);
  if (dayA == dayB) return 0;
  if (dayA == null) return 1;
  if (dayB == null) return -1;
  return dayB.compareTo(dayA);
}

int? _newestDay(CatalogMod mod) => mod.lastReleaseDay ?? mod.editedDay;

bool _isSameMod(CatalogMod a, CatalogMod b) {
  if (identical(a, b)) return true;
  final id = a.entry.id;
  return id != null && id.isNotEmpty && id == b.entry.id;
}

Set<String> _lowercased(Iterable<String> values) => {
  for (final value in values)
    if (value.trim().toLowerCase() case final lower when lower.isNotEmpty)
      lower,
};
