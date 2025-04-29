import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:stringr/stringr.dart';
import 'package:text_search/text_search.dart';
import 'package:trios/catalog/models/scraped_mod.dart';

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
        ...?modInfo.author?.let(
          (it) => getModAuthorAliases(
            it,
          ).map((alias) => (term: alias, penalty: 0.0)),
        ),
        modInfo.gameVersion?.let((it) => (term: it, penalty: 0.0)),
        modInfo.originalGameVersion?.let((it) => (term: it, penalty: 0.0)),
      ]
      .filter((it) => it?.term != null && it!.term.isNotEmpty)
      .distinctBy((it) => it)
      .map((it) => TextSearchItemTerm(it!.term, it.penalty))
      .toList(growable: false);
  // Fimber.v(() =>tags.join("\n"));
  return tags;
}

List<String> getModAuthorAliases(
  String author, {
  List<List<String>> listOfLists = Constants.modAuthorAliases,
}) {
  String normalizedAuthor = author.trim().toLowerCase();

  for (var aliases in listOfLists) {
    if (aliases.any(
      (alias) => alias.trim().toLowerCase() == normalizedAuthor,
    )) {
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
    modVariant.smolId,
    () => createSearchTags(modVariant.modInfo),
  );
}

/// Searches just the enabled/highest version of each mod.
List<Mod>? searchMods(List<Mod> mods, String? query) {
  if (query == null || query.isEmpty) {
    return mods;
  }

  return searchModVariants(
        mods
            .map((mod) => mod.findFirstEnabledOrHighestVersion)
            .nonNulls
            .toList(),
        query,
      )
      .map(
        (modVariant) => mods.firstWhereOrNull(
          (mod) => mod.findFirstEnabledOrHighestVersion == modVariant,
        ),
      )
      .nonNulls
      .toList();
}

List<ModVariant> searchModVariants(
  List<ModVariant> modVariants,
  String? query,
) {
  final modSearch =
      modVariants.isEmpty
          ? null
          : TextSearch(
            modVariants
                .map((mod) => TextSearchItem(mod, getModVariantSearchTags(mod)))
                .toList(),
          );

  final threshold = 1.0;

  final result =
      (query == null || query.isEmpty || modVariants.isEmpty)
          ? modVariants
          : query
              .split(",")
              .map((it) => it.trim())
              .filter((it) => it.isNotNullOrEmpty())
              .map(
                (queryPart) => (
                  query: queryPart,
                  result: modSearch!.search(queryPart),
                ),
              )
              .toList()
              .let((results) {
                final positiveQueryResult = results
                    .filter((queryObj) => !queryObj.query.startsWith("-"))
                    .map((e) => e.result)
                    .flattened
                    .filter((e) => e.score < threshold)
                    .sortedBy<num>((e) => e.score)
                    .map((e) => e.object);

                final negativeQueryResult = results
                    .filter((queryObj) => queryObj.query.startsWith("-"))
                    .map((e) => e.result)
                    .flattened
                    .filter((e) => e.score < threshold)
                    .map((e) => e.object);

                if (positiveQueryResult.isEmpty &&
                    negativeQueryResult.isNotEmpty) {
                  return modVariants.filter(
                    (mod) => !negativeQueryResult.contains(mod),
                  );
                } else if (positiveQueryResult.isNotEmpty) {
                  return positiveQueryResult.filter(
                    (mod) => !negativeQueryResult.contains(mod),
                  );
                } else {
                  return <ModVariant>[];
                }
              })
              .toList();
  return result;
}

// Scraped Mod search

final Map<String, List<TextSearchItemTerm>> _scrapedModSearchTagsCache = {};

List<TextSearchItemTerm> getScrapedModSearchTags(ScrapedMod mod) {
  return _scrapedModSearchTagsCache.putIfAbsent(
    mod.name,
    () => createScrapedModSearchTags(mod),
  );
}

List<ScrapedMod> searchScrapedMods(List<ScrapedMod> mods, String? query) {
  if (query == null || query.isEmpty) {
    return mods;
  }

  List<TextSearchItem<ScrapedMod>> items =
      mods
          .map((mod) => TextSearchItem(mod, getScrapedModSearchTags(mod)))
          .toList();
  List<String> queryParts =
      query.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  Set<ScrapedMod> positiveResults = {};
  Set<ScrapedMod> negativeResults = {};

  for (var queryPart in queryParts) {
    bool isNegative = queryPart.startsWith('-');
    String actualQuery = isNegative ? queryPart.substring(1) : queryPart;

    List<TextSearchItem<ScrapedMod>> matchingItems =
        items.where((item) {
          return item.terms.any(
            (term) => term.term.contains(actualQuery.toLowerCase()),
          );
        }).toList();

    if (isNegative) {
      negativeResults.addAll(matchingItems.map((item) => item.object));
    } else {
      positiveResults.addAll(matchingItems.map((item) => item.object));
    }
  }

  if (positiveResults.isEmpty && negativeResults.isNotEmpty) {
    return mods.where((mod) => !negativeResults.contains(mod)).toList();
  } else if (positiveResults.isNotEmpty) {
    return positiveResults
        .where((mod) => !negativeResults.contains(mod))
        .toList();
  } else {
    return [];
  }
}

List<TextSearchItemTerm> createScrapedModSearchTags(ScrapedMod mod) {
  List<TextSearchItemTerm> tags = [];

  void addTag(String? term, double penalty) {
    if (term != null && term.isNotEmpty) {
      tags.add(TextSearchItemTerm(term.toLowerCase(), penalty));
    }
  }

  addTag(mod.name, 0.0);
  String? alphaName = mod.name.slugify();
  addTag(alphaName, 10.0);
  List<String> parts = alphaName.split('-');
  for (var part in parts) {
    addTag(part, 10.0);
  }
  if (parts.isNotEmpty) {
    String acronym = parts.where((e) => e.isNotEmpty).map((e) => e[0]).join();
    addTag(acronym, 0.0);
  }

  for (var author in mod.authorsList ?? []) {
    addTag(author, 0.0);
    List<String> aliases = getModAuthorAliases(author);
    for (var alias in aliases) {
      addTag(alias, 0.0);
    }
  }

  mod.categories?.forEach((it) => addTag(it, 0.0));
  mod.sources?.forEach((it) => addTag(it.toString(), 0.0));
  mod.urls?.forEach((key, value) => addTag(value, 0.0));

  addTag(mod.gameVersionReq, 0.0);
  addTag(mod.modVersion, 0.0);

  var uniqueTags = LinkedHashSet<TextSearchItemTerm>.from(tags);
  return uniqueTags.toList();
}
