import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_page_controller.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/utils/catalog_search.dart';

CatalogMod _mod(String id) => CatalogMod(
  entry: ModRepoEntry(id: id, name: id),
  title: id,
  authors: '',
);

List<String> _ids(List<CatalogMod> mods) => [for (final m in mods) m.title];

void main() {
  group('Saved sort', () {
    test('round trips through CatalogPageStatePersisted', () {
      final state = withSortChosen(
        const CatalogPageState(),
        CatalogSortKey.date,
      ).copyWith(sortAscending: true);
      final saved = CatalogPageStatePersistedMapper.fromMap(
        withSortSaved(state).toMap(),
      );
      expect(savedSort(saved), (key: CatalogSortKey.date, ascending: true));
    });

    test('an unknown name falls back to Popular, most first', () {
      const saved = CatalogPageStatePersisted(
        sortKey: 'noSuchSort',
        sortAscending: true,
      );
      const fallback = (key: CatalogSortKey.mostViewed, ascending: false);
      expect(savedSort(saved), fallback);
      expect(savedSort(null), fallback);
    });

    test('a saved Best match falls back to the default', () {
      const saved = CatalogPageStatePersisted(sortKey: 'bestMatch');
      expect(savedSort(saved).key, CatalogSortKey.mostViewed);
    });

    test('while Best match is showing, the sort before it is saved', () {
      final picked = withSortChosen(
        const CatalogPageState(),
        CatalogSortKey.name,
      );
      final searching = withSearchQuery(picked, 'lazy');
      expect(searching.selectedSort, CatalogSortKey.bestMatch);

      final saved = withSortSaved(searching);
      expect(saved.sortKey, 'name');
      expect(saved.sortAscending, isTrue);
    });

    test('a saved key with no direction uses its default direction', () {
      const saved = CatalogPageStatePersisted(sortKey: 'name');
      expect(savedSort(saved).ascending, isTrue);
    });
  });

  group('Random sort', () {
    final mods = [for (var i = 0; i < 40; i++) _mod('mod-$i')];

    List<String> random(List<CatalogMod> list, int seed) =>
        _ids(sortCatalogMods(list, CatalogSortKey.random, shuffleSeed: seed));

    test('the same seed gives the same order', () {
      expect(random(mods, 7), random(mods.reversed.toList(), 7));
    });

    test('filtering keeps the relative order', () {
      final all = random(mods, 7);
      final some = mods.where((m) => m.title.endsWith('3')).toList();
      expect(random(some, 7), all.where((id) => id.endsWith('3')).toList());
    });

    test('a new seed changes the order', () {
      expect(random(mods, 7), isNot(random(mods, 8)));
      expect(random(mods, 8).toSet(), random(mods, 7).toSet());
    });
  });
}
