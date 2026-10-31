import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/details_dialog/related_mods.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';

CatalogMod _mod(
  String id, {
  List<String> authors = const [],
  List<String> categories = const [],
  CatalogExtras? extras,
  DateTime? postDate,
}) => CatalogMod(
  entry: ModRepoEntry(
    id: id,
    name: id,
    authorsList: authors,
    categories: categories,
  ),
  title: id,
  authors: authors.join(', '),
  postDate: postDate,
  extras: extras,
);

List<String> _ids(List<CatalogMod> mods) => [for (final m in mods) m.entry.id!];

void main() {
  group('moreByAuthor', () {
    test('lists other mods by the same author, not the mod itself', () {
      final mod = _mod('a', authors: ['Alex']);
      final all = [
        mod,
        _mod('b', authors: ['Alex']),
        _mod('c', authors: ['Sam']),
      ];

      expect(_ids(moreByAuthor(mod, all)), ['b']);
    });

    test('compares author names ignoring case', () {
      final mod = _mod('a', authors: ['Alex']);
      final all = [
        mod,
        _mod('b', authors: ['aLEX']),
      ];

      expect(_ids(moreByAuthor(mod, all)), ['b']);
    });

    test("matches on the extras record's other author names", () {
      final mod = _mod(
        'a',
        authors: ['Alex'],
        extras: CatalogExtras(
          otherAuthorNames: {
            'Alex': ['Alexander'],
          },
        ),
      );
      final all = [
        mod,
        _mod('b', authors: ['Alexander']),
      ];

      expect(_ids(moreByAuthor(mod, all)), ['b']);
    });

    test('shows at most five', () {
      final mod = _mod('a', authors: ['Alex']);
      final all = [
        mod,
        for (var i = 0; i < 8; i++) _mod('m$i', authors: ['Alex']),
      ];

      expect(moreByAuthor(mod, all), hasLength(relatedModsLimit));
    });

    test('puts the newest first: last release, then last edit, then added', () {
      final mod = _mod('a', authors: ['Alex']);
      final released = _mod(
        'released',
        authors: ['Alex'],
        extras: CatalogExtras(lastReleaseDate: DateTime(2026, 5, 1)),
      );
      final edited = _mod(
        'edited',
        authors: ['Alex'],
        extras: CatalogExtras(editedOn: DateTime(2026, 3, 1)),
      );
      final added = _mod(
        'added',
        authors: ['Alex'],
        postDate: DateTime(2026, 4, 1),
      );
      final undated = _mod('undated', authors: ['Alex']);

      expect(_ids(moreByAuthor(mod, [mod, undated, edited, added, released])), [
        'released',
        'added',
        'edited',
        'undated',
      ]);
    });
  });

  group('similarMods', () {
    test('a mod sharing an author goes to More by, not Similar', () {
      final mod = _mod('a', authors: ['Alex'], categories: ['Ships']);
      final sameAuthor = _mod('b', authors: ['Alex'], categories: ['Ships']);
      final otherAuthor = _mod('c', authors: ['Sam'], categories: ['Ships']);
      final all = [mod, sameAuthor, otherAuthor];

      expect(_ids(similarMods(mod, all)), ['c']);
      expect(_ids(moreByAuthor(mod, all)), ['b']);
    });

    test('needs at least one shared category', () {
      final mod = _mod('a', authors: ['Alex'], categories: ['Ships']);
      final all = [
        mod,
        _mod('b', authors: ['Sam'], categories: ['Portraits']),
      ];

      expect(similarMods(mod, all), isEmpty);
    });

    test('puts the most shared categories first, then the newest', () {
      final mod = _mod(
        'a',
        authors: ['Alex'],
        categories: ['Ships', 'Weapons', 'Factions'],
      );
      final oneOld = _mod(
        'oneOld',
        authors: ['Sam'],
        categories: ['Ships'],
        postDate: DateTime(2020),
      );
      final oneNew = _mod(
        'oneNew',
        authors: ['Sam'],
        categories: ['Ships'],
        postDate: DateTime(2026),
      );
      final two = _mod(
        'two',
        authors: ['Sam'],
        categories: ['Ships', 'Weapons'],
        postDate: DateTime(2019),
      );

      expect(_ids(similarMods(mod, [mod, oneOld, oneNew, two])), [
        'two',
        'oneNew',
        'oneOld',
      ]);
    });

    test('uses the cleaned categories when the extras record has them', () {
      final mod = _mod(
        'a',
        authors: ['Alex'],
        categories: ['Raw ships'],
        extras: CatalogExtras(categories: ['Ships and weapons']),
      );
      final cleanedMatch = _mod(
        'cleaned',
        authors: ['Sam'],
        extras: CatalogExtras(categories: ['Ships and weapons']),
      );
      final rawMatch = _mod('raw', authors: ['Sam'], categories: ['Raw ships']);

      expect(_ids(similarMods(mod, [mod, cleanedMatch, rawMatch])), [
        'cleaned',
      ]);
    });

    test('uses the raw catalog categories without an extras record', () {
      final mod = _mod('a', authors: ['Alex'], categories: ['Ships']);
      final all = [
        mod,
        _mod('b', authors: ['Sam'], categories: ['ships']),
      ];

      expect(_ids(similarMods(mod, all)), ['b']);
    });

    test('shows at most five', () {
      final mod = _mod('a', authors: ['Alex'], categories: ['Ships']);
      final all = [
        mod,
        for (var i = 0; i < 8; i++)
          _mod('m$i', authors: ['Sam'], categories: ['Ships']),
      ];

      expect(similarMods(mod, all), hasLength(relatedModsLimit));
    });
  });
}
