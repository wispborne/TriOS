import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_text_search.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';

/// A small hand-made catalog mod.
CatalogMod catalogMod(
  String name, {
  String? id,
  List<String> authors = const [],
  List<String> categories = const [],
  List<ModSource> sources = const [],
  String? summary,
  String? description,
  String? aiSentence,
  String? sourceCodeUrl,
  bool isWip = false,
  bool? usesAi,
}) {
  return CatalogMod(
    entry: ModRepoEntry(
      id: id ?? name.toLowerCase(),
      name: name,
      authorsList: authors,
      categories: categories,
      sources: sources,
    ),
    title: name,
    authors: authors.join(', '),
    summaryText: summary,
    descriptionText: description,
    aiSentence: aiSentence,
    sourceCodeUrl: sourceCodeUrl,
    isWip: isWip,
    llmMod: ForumLlmMod(
      name: name,
      extras: ForumLlmExtras(aiUse: CatalogAiUse(usesAi: usesAi)),
    ),
  );
}

List<String> search(
  List<CatalogMod> mods,
  String text, {
  bool searchAiText = true,
}) => searchCatalogMods(
  mods,
  text,
  searchAiText: searchAiText,
).mods.map((m) => m.title).toList();

void main() {
  group('normalizeSearchText', () {
    test('takes off accents and apostrophes', () {
      expect(normalizeSearchText("Amazigh's Café"), 'amazighs cafe');
    });

    test('keeps dots between digits only', () {
      expect(
        normalizeSearchText('[0.98a] Ship/Weapon Pack.'),
        '0.98a ship weapon pack',
      );
    });

    test('keeps letters of other alphabets', () {
      expect(normalizeSearchText('Звезда Ωmega'), 'звезда ωmega');
    });
  });

  group('editDistance', () {
    test('counts added, removed and swapped letters', () {
      expect(editDistance('nexerlin', 'nexerelin'), 1);
      expect(editDistance('kitten', 'sitting'), 3);
    });

    test('two letters trading places is one change', () {
      expect(editDistance('lazylbi', 'lazylib'), 1);
    });

    test('stops at the limit', () {
      expect(editDistance('kitten', 'sitting', limit: 1), 2);
    });
  });

  group('shorthand', () {
    test('"indevo" finds Industrial Evolution', () {
      final mods = [
        catalogMod('Industrial Evolution'),
        catalogMod('Ship Pack'),
      ];
      expect(search(mods, 'indevo'), ['Industrial Evolution']);
    });

    test('"kol" finds Knights of Ludd', () {
      final mods = [catalogMod('Knights of Ludd'), catalogMod('Ship Pack')];
      expect(search(mods, 'kol'), ['Knights of Ludd']);
    });

    test('"swp" puts Ship/Weapon Pack first', () {
      final mods = [catalogMod('SWPlus'), catalogMod('Ship/Weapon Pack')];
      expect(search(mods, 'swp').first, 'Ship/Weapon Pack');
    });

    test('"faction" does not find Fleet Action History or Action', () {
      final mods = [
        catalogMod('Fleet Action History'),
        catalogMod('Action'),
        catalogMod('Faction Pack'),
      ];
      expect(search(mods, 'faction'), ['Faction Pack']);
    });
  });

  group('close spellings', () {
    test('"nexerlin" finds Nexerelin', () {
      expect(search([catalogMod('Nexerelin')], 'nexerlin'), ['Nexerelin']);
    });

    test('"lazt" does not find LazyLib', () {
      expect(search([catalogMod('LazyLib')], 'lazt'), isEmpty);
    });
  });

  group('reading the search', () {
    test('"graphics lib" finds GraphicsLib through the split at the capital', () {
      final mods = [catalogMod('GraphicsLib'), catalogMod('Graphics Overhaul')];
      expect(search(mods, 'graphics lib'), ['GraphicsLib']);
    });

    test('"pirate -junk" leaves out mods matching junk', () {
      final mods = [catalogMod('Pirate Pack'), catalogMod('Pirate Junk Yard')];
      expect(search(mods, 'pirate -junk'), ['Pirate Pack']);
    });

    test('"-portrait" starts from every mod', () {
      final mods = [catalogMod('Portrait Pack'), catalogMod('Ship Pack')];
      expect(search(mods, '-portrait'), ['Ship Pack']);
    });

    test('"portrait, faction" lists mods matching either', () {
      final mods = [
        catalogMod('Portrait Pack'),
        catalogMod('Faction Mod'),
        catalogMod('Ship Pack'),
      ];
      expect(
        search(mods, 'portrait, faction'),
        unorderedEquals(['Portrait Pack', 'Faction Mod']),
      );
    });

    test('a quoted phrase needs the words next to each other', () {
      final mods = [
        catalogMod('Unknown Contact'),
        catalogMod('Contact Unknown'),
      ];
      expect(search(mods, '"unknown contact"'), ['Unknown Contact']);
    });

    test('an unclosed quote is closed at the end of its group', () {
      final mods = [
        catalogMod('Unknown Contact'),
        catalogMod('Contact Unknown'),
      ];
      expect(search(mods, '"unknown contact'), ['Unknown Contact']);
    });

    test('a lone minus or quote is ignored', () {
      final query = CatalogSearchQuery('- " +', searchAiText: true);
      expect(query.isEmpty, isTrue);
    });
  });

  group('fields', () {
    test('"author:wisp" lists only Wisp\'s mods', () {
      final mods = [
        catalogMod('Wisp Mod', authors: ['Wisp']),
        catalogMod('Other Mod', authors: ['Histidine']),
      ];
      expect(search(mods, 'author:wisp'), ['Wisp Mod']);
    });

    test('author: also looks in other author names', () {
      final mods = [
        catalogMod('DR Mod', authors: ['DR']),
        catalogMod('Other Mod', authors: ['Histidine']),
      ];
      expect(search(mods, 'author:revenant'), ['DR Mod']);
    });

    test('"from:discord"', () {
      final mods = [
        catalogMod('Discord Mod', sources: [ModSource.Discord]),
        catalogMod('Forum Mod', sources: [ModSource.ModdingSubforum]),
      ];
      expect(search(mods, 'from:discord'), ['Discord Mod']);
      expect(search(mods, 'from:forum'), ['Forum Mod']);
    });

    test('"category:weapons"', () {
      final mods = [
        catalogMod('Gun Mod', categories: ['Weapons']),
        catalogMod('Ship Mod', categories: ['Ships']),
      ];
      expect(search(mods, 'category:weapons'), ['Gun Mod']);
    });

    test('"foo:bar" is read as the words foo and bar', () {
      final mods = [catalogMod('Foo Bar'), catalogMod('Ship Pack')];
      expect(search(mods, 'foo:bar'), ['Foo Bar']);
    });
  });

  group('has: and is:', () {
    test('"-is:wip" leaves out works in progress', () {
      final mods = [
        catalogMod('Done Mod'),
        catalogMod('Unfinished Mod', isWip: true),
      ];
      expect(search(mods, '-is:wip'), ['Done Mod']);
    });

    test('"has:source"', () {
      final mods = [
        catalogMod('Open Mod', sourceCodeUrl: 'https://github.com/x/y'),
        catalogMod('Closed Mod'),
      ];
      expect(search(mods, 'has:source'), ['Open Mod']);
    });

    test('"is:noai" leaves out mods whose author says nothing', () {
      final mods = [
        catalogMod('No AI Mod', usesAi: false),
        catalogMod('AI Mod', usesAi: true),
        catalogMod('Silent Mod'),
      ];
      expect(search(mods, 'is:noai'), ['No AI Mod']);
      expect(search(mods, 'has:ai'), ['AI Mod']);
      expect(
        search(mods, '-has:ai'),
        unorderedEquals(['No AI Mod', 'Silent Mod']),
      );
    });

    test('questions do not change the order', () {
      final mods = [
        catalogMod('Nexerelin', sourceCodeUrl: 'https://github.com/x/y'),
        catalogMod(
          'Other Mod',
          description: 'Works with Nexerelin.',
          sourceCodeUrl: 'https://github.com/x/z',
        ),
        catalogMod('Third Mod', description: 'Needs Nexerelin.'),
      ];
      final plain = searchCatalogMods(mods, 'nexerelin', searchAiText: true);
      final withFlag = searchCatalogMods(
        mods,
        'nexerelin has:source',
        searchAiText: true,
      );
      expect(withFlag.mods.map((m) => m.title), ['Nexerelin', 'Other Mod']);
      for (final mod in withFlag.mods) {
        expect(withFlag.scores[mod], plain.scores[mod]);
      }
    });
  });

  group('ranking and facts', () {
    test('a description-only match ranks below a name match', () {
      final mods = [
        catalogMod('Other Mod', description: 'Requires Nexerelin to run.'),
        catalogMod('Nexerelin'),
      ];
      expect(search(mods, 'nexerelin'), ['Nexerelin', 'Other Mod']);
    });

    test('a link is searched', () {
      final mod = CatalogMod(
        entry: ModRepoEntry(
          name: 'Linked Mod',
          urls: {ModUrlType.NexusMods: 'https://www.nexusmods.com/starsector/mods/123'},
        ),
        title: 'Linked Mod',
        authors: '',
      );
      expect(search([mod], 'nexusmods'), ['Linked Mod']);
      expect(search([mod], 'url:nexusmods'), ['Linked Mod']);
    });

    test('the AI sentence is not searched when AI text is off', () {
      final mods = [catalogMod('Zoo Mod', aiSentence: 'Adds zebras.')];
      expect(search(mods, 'zebras', searchAiText: true), ['Zoo Mod']);
      expect(search(mods, 'zebras', searchAiText: false), isEmpty);
      expect(search(mods, 'summary:zebras', searchAiText: false), isEmpty);
    });

    test('two mods with the same name keep their own facts', () {
      final mods = [
        catalogMod('Twin', id: 'twin-1', authors: ['Alpha']),
        catalogMod('Twin', id: 'twin-2', authors: ['Beta']),
      ];
      expect(search(mods, 'twin'), hasLength(2));
      final found = searchCatalogMods(mods, 'alpha', searchAiText: true);
      expect(found.mods.single.entry.id, 'twin-1');
    });

    test('ties go by name, then catalog id', () {
      final mods = [
        catalogMod('Pack B', id: 'b'),
        catalogMod('Pack A', id: 'z'),
        catalogMod('Pack A', id: 'a'),
      ];
      final found = searchCatalogMods(mods, '-junk', searchAiText: true);
      expect(found.mods.map((m) => m.entry.id), ['a', 'z', 'b']);
    });

    test('an empty search lists every mod in the order given', () {
      final mods = [catalogMod('B'), catalogMod('A')];
      expect(search(mods, '  '), ['B', 'A']);
    });
  });
}
