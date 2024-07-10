import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:stringr/stringr.dart';
import 'package:text_search/text_search.dart';

import '../models/mod.dart';
import '../models/mod_info.dart';
import '../models/mod_variant.dart';
import '../trios/constants.dart';

String createSearchIndex(ModVariant modVariant) =>
    "${modVariant.modInfo.name} ${modVariant.modInfo.author} ${modVariant.modInfo.id}}";

/// Creates a list of tags to be used for searching. All tags are lowercased.
List<TextSearchItemTerm> createSearchTags(ModInfo modInfo) {
  final alphaName = modInfo.name?.slugify();
  final tags = [
    modInfo.name?.let((it) => (term: it, penalty: 0.0)),
    modInfo.id.let((it) => (term: it, penalty: 0.0)),
    alphaName?.let((it) => (term: it, penalty: 10.0)),
    ...?alphaName?.split("-").map((it) => (term: it, penalty: 10.0)),
    // Create acronym.
    ((alphaName?.split("-").length ?? 0) > 0)
        ? alphaName!
            .split("-")
            .where((element) => element.isNotEmpty)
            .map((e) => e.substring(0, 1))
            .join()
            .let((it) => (term: it, penalty: 0.0))
        : null,
    modInfo.author?.let((it) => (term: it, penalty: 0.0)),
    ...?modInfo.author?.let((it) =>
        getModAuthorAliases(it).map((alias) => (term: alias, penalty: 0.0))),
    modInfo.gameVersion?.let((it) => (term: it, penalty: 0.0)),
    modInfo.originalGameVersion?.let((it) => (term: it, penalty: 0.0)),
  ]
      .filter((it) => it?.term != null && it!.term.isNotEmpty)
      .distinctBy((it) => it)
      .map((it) => TextSearchItemTerm(it!.term, it.penalty))
      .toList(growable: false);
  // Fimber.v(tags.join("\n"));
  return tags;
}

List<String> getModAuthorAliases(String author,
    {List<List<String>> listOfLists = Constants.modAuthorAliases}) {
  String normalizedAuthor = author.trim().toLowerCase();

  for (var aliases in listOfLists) {
    if (aliases
        .any((alias) => alias.trim().toLowerCase() == normalizedAuthor)) {
      return aliases
          .where((alias) => alias.trim().toLowerCase() != normalizedAuthor)
          .toList();
    }
  }
  return [];
}

final _modSearchTagsCache = <SmolId, List<TextSearchItemTerm>>{};

List<TextSearchItemTerm> getModVariantSearchTags(ModVariant modVariant) {
  return _modSearchTagsCache.putIfAbsent(
      modVariant.smolId, () => createSearchTags(modVariant.modInfo));
}

/// Searches just the enabled/highest version of each mod.
List<Mod>? searchMods(List<Mod> mods, String? query) {
  return searchModVariants(
          mods
              .map((mod) => mod.findFirstEnabledOrHighestVersion)
              .whereNotNull()
              .toList(),
          query)
      .map((modVariant) => mods.firstWhereOrNull(
          (mod) => mod.findFirstEnabledOrHighestVersion == modVariant))
      .whereNotNull()
      .toList();
}

List<ModVariant> searchModVariants(
    List<ModVariant> modVariants, String? query) {
  final modSearch = modVariants.isEmpty
      ? null
      : TextSearch(modVariants
          .map((mod) => TextSearchItem(mod, getModVariantSearchTags(mod)))
          .toList());
  return (query == null || query.isEmpty || modVariants.isEmpty)
      ? modVariants
      : query
          .split(",")
          .map((it) => it.trim())
          .filter((it) => it.isNotNullOrEmpty())
          .map((queryPart) =>
              (query: queryPart, result: modSearch!.search(queryPart)))
          .filter((e) => e.result.any((element) => element.score > 0))
          .toList()
          .let((results) {
          final positiveQueryResult = results
              .filter((queryObj) => !queryObj.query.startsWith("-"))
              .map((e) => e.result)
              .flattened
              .sortedBy<num>((e) => e.score)
              .map((e) => e.object);

          final negativeQueryResult = results
              .filter((queryObj) => queryObj.query.startsWith("-"))
              .map((e) => e.result)
              .flattened
              .map((e) => e.object);

          if (positiveQueryResult.isEmpty && negativeQueryResult.isNotEmpty) {
            return modVariants
                .filter((mod) => !negativeQueryResult.contains(mod));
          } else if (positiveQueryResult.isNotEmpty) {
            return positiveQueryResult
                .filter((mod) => !negativeQueryResult.contains(mod));
          } else {
            return <ModVariant>[];
          }
        }).toList();
}
