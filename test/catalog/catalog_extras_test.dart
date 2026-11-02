import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/utils/log_collapser.dart';

/// One record shaped like the scraper's `mod-catalog-extras.json`, based on
/// ED Shipyard's, with every field filled in.
Map<String, dynamic> _fullRecord() => {
  'displayName': 'ED Shipyard',
  'summary': 'Ships from the ED Shipyard.',
  'categories': ['Ships and weapons'],
  'rawCategories': ['Ship Pack'],
  'otherAuthorNames': {
    'Nick XR': ['nick', 'nick7884'],
  },
  'addedOn': '2022-07-24',
  'editedOn': '2026-09-13',
  'lastReleaseDate': '2026-09-15T00:00:00.000Z',
  'releases': [
    {
      'modId': 'ed-shipyard',
      'modName': 'ED Shipyard',
      'seenOn': '2026-09-15',
      'oldVersion': '2.7.2',
      'newVersion': '2.7.3',
      'gameVersion': '0.98a',
      'changelogNotes': 'Fixed a crash.',
      'updateCompatibilityText': 'Save compatible.',
      'canUpdate': 'yes',
    },
  ],
  'needs': [
    {'name': 'LazyLib', 'id': 'lazylib'},
  ],
  'optionalNeeds': [
    {'name': 'Some Mod'},
  ],
  'conflicts': [
    {
      'name': 'Particle Engine',
      'id': 'particle-engine',
      'quote': 'Particle Engine may rarely crash in very large battles.',
    },
  ],
  'isTool': false,
  'saveCompatible': true,
  'canAdd': 'yes',
  'canUpdate': 'yes',
  'canRemove': 'no',
  'saveCompatibilityText': 'Safe to add mid playthrough',
  'updateCompatibilityText': 'Save compatible.',
  'removalCompatibilityText': 'Do not remove.',
  'aiUse': <String, dynamic>{},
  'sameNameMods': [
    {
      'title': 'ED Shipyard',
      'url': 'https://fractalsoftworks.com/forum/index.php?topic=16479.0',
      'id': 'ed-shipyard-2',
      'authors': ['Ed'],
      'gameVersion': '0.9.1a',
      'modVersion': '2.1.2',
      'threadLastPostOn': '2019-05-01',
    },
  ],
  'gallery': [
    {
      'url': 'https://example.com/logo.png',
      'caption': 'Logo',
      'aiCaption': "A square logo with the letters 'ED'.",
      'aiKind': 'logo',
      'aiFit': 'good',
      'aiUnreadable': true,
      'small': true,
      'source': 'discord',
    },
  ],
  'discordPostHtml': '<p>Hello</p>',
};

ModRepoEntry _makeEntry({List<String>? categories}) => ModRepoEntry(
  id: 'ed-shipyard',
  name: 'ED Shipyard',
  categories: categories,
  sourcePosts: [
    CatalogSourcePost(
      kind: CatalogSourceKind.forum,
      id: '1',
      llmModName: 'ED Shipyard',
      foundBy: CatalogFoundBy.rulesAndLlm,
    ),
  ],
);

ForumModIndex _makeIndex(ForumLlmExtras extras) => ForumModIndex(
  topicId: 1,
  title: 'ED Shipyard',
  author: 'Ed',
  inModIndex: true,
  isArchivedModIndex: false,
  replies: 0,
  views: 0,
  topicUrl: 'https://example.com/topic=1',
  isWip: false,
  llm: ForumLlmData(
    mods: [
      ForumLlmMod(name: 'ED Shipyard', role: LlmModRole.main, extras: extras),
    ],
  ),
);

void main() {
  setUp(LogCollapser.resetRecent);

  group('parseCatalogExtrasFile', () {
    test('reads every field', () {
      final file = parseCatalogExtrasFile({
        'schemaVersion': 1,
        'generatedAt': '2026-10-29T03:01:44.127205Z',
        'mods': {'ed-shipyard': _fullRecord()},
      });

      expect(file.schemaVersion, 1);
      expect(file.isKnownSchema, isTrue);
      expect(file.generatedAt, DateTime.utc(2026, 10, 29, 3, 1, 44, 127, 205));

      final record = file.mods['ed-shipyard']!;
      expect(record.displayName, 'ED Shipyard');
      expect(record.summary, 'Ships from the ED Shipyard.');
      expect(record.categories, ['Ships and weapons']);
      expect(record.rawCategories, ['Ship Pack']);
      expect(record.otherAuthorNames, {
        'Nick XR': ['nick', 'nick7884'],
      });
      expect(record.addedOn, DateTime(2022, 7, 24));
      expect(record.editedOn, DateTime(2026, 9, 13));
      expect(record.lastReleaseDate, DateTime.utc(2026, 9, 15));

      final release = record.releases.single;
      expect(release.seenOn, DateTime(2026, 9, 15));
      expect(release.oldVersion, '2.7.2');
      expect(release.newVersion, '2.7.3');
      expect(release.gameVersion, '0.98a');
      expect(release.changelogNotes, 'Fixed a crash.');
      expect(release.updateCompatibilityText, 'Save compatible.');
      expect(release.canUpdate, CatalogSaveAnswer.yes);

      expect(record.needs.single.name, 'LazyLib');
      expect(record.needs.single.id, 'lazylib');
      expect(record.optionalNeeds.single.id, isNull);
      expect(record.conflicts.single.name, 'Particle Engine');
      expect(record.conflicts.single.id, 'particle-engine');
      expect(record.conflicts.single.quote, contains('rarely crash'));
      expect(record.isTool, isFalse);
      expect(record.saveCompatible, isTrue);
      expect(record.canAdd, CatalogSaveAnswer.yes);
      expect(record.canUpdate, CatalogSaveAnswer.yes);
      expect(record.canRemove, CatalogSaveAnswer.no);
      expect(record.saveCompatibilityText, 'Safe to add mid playthrough');
      expect(record.updateCompatibilityText, 'Save compatible.');
      expect(record.removalCompatibilityText, 'Do not remove.');
      expect(record.aiUse, isNotNull);
      expect(record.aiUse?.usesAi, isNull);

      final sameName = record.sameNameMods.single;
      expect(sameName.title, 'ED Shipyard');
      expect(sameName.url, contains('topic=16479'));
      expect(sameName.id, 'ed-shipyard-2');
      expect(sameName.authors, ['Ed']);
      expect(sameName.gameVersion, '0.9.1a');
      expect(sameName.modVersion, '2.1.2');
      expect(sameName.threadLastPostOn, DateTime(2019, 5, 1));

      final picture = record.gallery.single;
      expect(picture.url, 'https://example.com/logo.png');
      expect(picture.caption, 'Logo');
      expect(picture.aiCaption, contains('square logo'));
      expect(picture.aiKind, CatalogPictureKind.logo);
      expect(picture.aiFit, CatalogPictureFit.good);
      expect(picture.aiUnreadable, isTrue);
      expect(picture.small, isTrue);
      expect(picture.source, CatalogPictureSource.discord);

      expect(record.discordPostHtml, '<p>Hello</p>');
    });

    test('a record with only some fields fills the rest with empty values', () {
      final file = parseCatalogExtrasFile({
        'schemaVersion': 1,
        'mods': {
          'a': {'addedOn': '2025-03-01', 'somethingNew': 42},
        },
      });

      final record = file.mods['a']!;
      expect(record.addedOn, DateTime(2025, 3, 1));
      expect(record.categories, isEmpty);
      expect(record.releases, isEmpty);
      expect(record.otherAuthorNames, isEmpty);
      expect(record.canAdd, isNull);
      expect(record.aiUse, isNull);
    });

    test('a bad record is dropped and the rest still load', () {
      final file = parseCatalogExtrasFile({
        'schemaVersion': 1,
        'mods': {
          'good': _fullRecord(),
          'bad': {'categories': 'not a list'},
          'also-good': {'displayName': 'Fine'},
        },
      });

      expect(file.mods.keys, unorderedEquals(['good', 'also-good']));
    });

    test('an unknown enum value reads as unknown', () {
      final file = parseCatalogExtrasFile({
        'schemaVersion': 1,
        'mods': {
          'a': {
            'canAdd': 'sometimes',
            'gallery': [
              {
                'url': 'https://example.com/a.png',
                'aiKind': 'meme',
                'aiFit': 'great',
                'source': 'reddit',
              },
            ],
          },
        },
      });

      final record = file.mods['a']!;
      expect(record.canAdd, CatalogSaveAnswer.unknown);
      final picture = record.gallery.single;
      expect(picture.aiKind, CatalogPictureKind.unknown);
      expect(picture.aiFit, CatalogPictureFit.unknown);
      expect(picture.source, CatalogPictureSource.unknown);
    });

    test('a newer schema version gives no records', () {
      final file = parseCatalogExtrasFile({
        'schemaVersion': 2,
        'mods': {'ed-shipyard': _fullRecord()},
      });

      expect(file.isKnownSchema, isFalse);
      expect(file.mods, isEmpty);
    });
  });

  group('CatalogMod extras and fallbacks', () {
    final llmExtras = ForumLlmExtras(
      needs: ['LazyLib'],
      optionalNeeds: ['Nexerelin'],
      conflicts: [ForumLlmConflict(name: 'BoxUtil', quote: 'BoxUtil breaks.')],
      canAdd: 'no',
    );

    test('with no record, the getters fall back', () {
      final mod = gatherCatalogMod(
        mod: _makeEntry(categories: ['Ship Pack', 'Discord Only']),
        forumIndex: _makeIndex(llmExtras),
      );

      expect(mod.extras, isNull);
      expect(mod.categories, ['Ship Pack', 'Discord Only']);
      expect(mod.requiredMods.single.name, 'LazyLib');
      expect(mod.requiredMods.single.id, isNull);
      expect(mod.optionalMods.single.name, 'Nexerelin');
      expect(mod.conflictingMods.single.name, 'BoxUtil');
      expect(mod.conflictingMods.single.quote, 'BoxUtil breaks.');
      expect(mod.canAddToSaveAnswer, CatalogSaveAnswer.no);
      expect(mod.canAddToSave, isFalse);
    });

    test('with a record, the record wins', () {
      final record = CatalogExtrasMapper.fromMap(_fullRecord());
      final mod = gatherCatalogMod(
        mod: _makeEntry(categories: ['Ship Pack']),
        forumIndex: _makeIndex(llmExtras),
        extras: record,
      );

      expect(mod.extras, same(record));
      expect(mod.categories, ['Ships and weapons']);
      expect(mod.requiredMods.single.id, 'lazylib');
      expect(mod.optionalMods.single.name, 'Some Mod');
      expect(mod.conflictingMods.single.id, 'particle-engine');
      expect(mod.canAddToSaveAnswer, CatalogSaveAnswer.yes);
      expect(mod.canAddToSave, isTrue);
    });

    test('a record with no categories or canAdd still wins', () {
      final mod = gatherCatalogMod(
        mod: _makeEntry(categories: ['Discord Only']),
        forumIndex: _makeIndex(llmExtras),
        extras: CatalogExtras(),
      );

      expect(mod.categories, isEmpty);
      expect(mod.requiredMods, isEmpty);
      expect(mod.canAddToSaveAnswer, isNull);
    });

    test('with no record and no AI answer, the getters are empty', () {
      final mod = gatherCatalogMod(mod: _makeEntry());

      expect(mod.categories, isEmpty);
      expect(mod.requiredMods, isEmpty);
      expect(mod.optionalMods, isEmpty);
      expect(mod.conflictingMods, isEmpty);
      expect(mod.canAddToSaveAnswer, isNull);
    });
  });

  group('summary', () {
    test("the extras record's summary is the mod's short summary", () {
      final mod = gatherCatalogMod(
        mod: ModRepoEntry(name: 'Mod', summary: 'The catalog summary.'),
        extras: CatalogExtras(summary: "Starmodder's summary."),
      );

      expect(mod.summaryText, "Starmodder's summary.");
    });

    test("the catalog's summary is used when the record has none", () {
      final mod = gatherCatalogMod(
        mod: ModRepoEntry(name: 'Mod', summary: 'The catalog summary.'),
        extras: CatalogExtras(),
      );

      expect(mod.summaryText, 'The catalog summary.');
    });
  });

  group('CatalogNeed', () {
    test('reads via, for a mod needed by another requirement', () {
      final need = CatalogNeedMapper.fromMap({
        'name': 'LazyLib',
        'id': 'lazylib',
        'via': 'MagicLib',
      });

      expect(need.name, 'LazyLib');
      expect(need.id, 'lazylib');
      expect(need.via, 'MagicLib');
    });

    test('reads a need without via as null', () {
      final need = CatalogNeedMapper.fromMap({
        'name': 'MagicLib',
        'id': 'magiclib',
      });

      expect(need.via, isNull);
    });
  });
}
