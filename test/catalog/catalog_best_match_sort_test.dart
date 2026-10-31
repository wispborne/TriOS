import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_page_controller.dart';
import 'package:trios/catalog/catalog_text_search.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/utils/catalog_search.dart';

CatalogMod catalogMod(String name, {int? views}) => CatalogMod(
  entry: ModRepoEntry(id: name.toLowerCase(), name: name),
  title: name,
  authors: '',
  views: views,
);

void main() {
  const popular = CatalogPageState(
    selectedSort: CatalogSortKey.mostViewed,
    sortAscending: false,
  );

  test('typing picks Best match, and Knights of Ludd is first', () {
    final state = withSearchQuery(popular, 'kol');
    expect(state.selectedSort, CatalogSortKey.bestMatch);

    final mods = [
      catalogMod('Kolobok Pack', views: 9000),
      catalogMod('Knights of Ludd', views: 10),
    ];
    final search = searchCatalogMods(mods, 'kol', searchAiText: true);
    final sorted = sortCatalogMods(
      search.mods,
      state.selectedSort,
      ascending: state.sortAscending,
      scores: search.scores,
    );
    expect(sorted.first.title, 'Knights of Ludd');
  });

  test('clearing the search puts back the sort and its direction', () {
    final ascendingPopular = popular.copyWith(sortAscending: true);
    final searching = withSearchQuery(ascendingPopular, 'kol');
    final typedMore = withSearchQuery(searching, 'kol ludd');
    expect(typedMore.selectedSort, CatalogSortKey.bestMatch);

    final cleared = withSearchQuery(typedMore, '');
    expect(cleared.selectedSort, CatalogSortKey.mostViewed);
    expect(cleared.sortAscending, isTrue);
    expect(cleared.sortBeforeSearch, isNull);
  });

  test('a sort picked by hand while searching survives more typing', () {
    final searching = withSearchQuery(popular, 'k');
    final picked = withSortChosen(searching, CatalogSortKey.name);
    expect(picked.sortChosenWhileSearching, isTrue);

    final typedMore = withSearchQuery(picked, 'kol');
    expect(typedMore.selectedSort, CatalogSortKey.name);

    final cleared = withSearchQuery(typedMore, '');
    expect(cleared.selectedSort, CatalogSortKey.name);
    expect(cleared.sortChosenWhileSearching, isFalse);
  });

  test('the next search picks Best match again after a hand-picked sort', () {
    final picked = withSortChosen(
      withSearchQuery(popular, 'k'),
      CatalogSortKey.name,
    );
    final cleared = withSearchQuery(picked, '');
    final searchingAgain = withSearchQuery(cleared, 'n');
    expect(searchingAgain.selectedSort, CatalogSortKey.bestMatch);
    expect(withSearchQuery(searchingAgain, '').selectedSort, CatalogSortKey.name);
  });

  test('a sort picked with no search text does not count as picked while searching', () {
    final picked = withSortChosen(popular, CatalogSortKey.date);
    expect(picked.sortChosenWhileSearching, isFalse);
    expect(withSearchQuery(picked, 'k').selectedSort, CatalogSortKey.bestMatch);
  });
}
