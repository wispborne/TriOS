import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';

ModRepoEntry _makeEntry({DateTime? created}) => ModRepoEntry(
  id: 'ed-shipyard',
  name: 'ED Shipyard',
  dateTimeCreated: created,
  sourcePosts: [
    CatalogSourcePost(
      kind: CatalogSourceKind.forum,
      id: '1',
      llmModName: 'ED Shipyard',
      foundBy: CatalogFoundBy.rulesAndLlm,
    ),
  ],
);

ForumModIndex _makeIndex({bool? isTool, ForumLlmExtras? extras}) =>
    ForumModIndex(
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
          ForumLlmMod(
            name: 'ED Shipyard',
            role: LlmModRole.main,
            isTool: isTool,
            extras: extras,
          ),
        ],
      ),
    );

void main() {
  group('catalogDayNumber', () {
    test('counts whole days from 1970-01-01', () {
      expect(catalogDayNumber(DateTime.utc(1970)), 0);
      expect(catalogDayNumber(DateTime.utc(1970, 1, 2, 23, 59)), 1);
      expect(catalogDayNumber(null), isNull);
    });

    test('a bare date keeps its calendar day', () {
      final day = catalogDayNumber(DateTime.parse('2025-03-01'));
      expect(dateFromCatalogDayNumber(day!), DateTime.utc(2025, 3, 1));
    });
  });

  group('Date getters', () {
    test('Posted and Last edited fall back to the dates TriOS already has', () {
      final mod = gatherCatalogMod(
        mod: _makeEntry(created: DateTime.utc(2025, 1, 10)),
      );
      final posted = catalogDayNumber(DateTime.utc(2025, 1, 10));
      expect(mod.postedDay, posted);
      expect(mod.editedDay, posted, reason: 'never edited uses Posted');
      expect(mod.lastReleaseDay, isNull);
    });

    test('the extras record wins, and Last edited falls back to Posted', () {
      final mod = gatherCatalogMod(
        mod: _makeEntry(created: DateTime.utc(2020)),
        extras: CatalogExtras(addedOn: DateTime(2022, 7, 24)),
      );
      expect(mod.postedDay, catalogDayNumber(DateTime.utc(2022, 7, 24)));
      expect(mod.editedDay, mod.postedDay);
      expect(mod.lastReleaseDay, isNull, reason: 'Last release has no fallback');
    });

    test('a record with every date uses each one', () {
      final mod = gatherCatalogMod(
        mod: _makeEntry(),
        extras: CatalogExtras(
          addedOn: DateTime(2022, 7, 24),
          editedOn: DateTime(2026, 9, 13),
          lastReleaseDate: DateTime.utc(2026, 9, 15),
        ),
      );
      expect(mod.editedDay, catalogDayNumber(DateTime.utc(2026, 9, 13)));
      expect(mod.lastReleaseDay, catalogDayNumber(DateTime.utc(2026, 9, 15)));
    });
  });

  group('isTool and aiUse', () {
    test('fall back to the AI answer with no extras record', () {
      final mod = gatherCatalogMod(
        mod: _makeEntry(),
        forumIndex: _makeIndex(
          isTool: true,
          extras: ForumLlmExtras(aiUse: CatalogAiUse(usesAi: false)),
        ),
      );
      expect(mod.isTool, isTrue);
      expect(mod.usesAi, isFalse);
      expect(mod.attributeKeys, contains('tool'));
    });

    test('the extras record wins', () {
      final mod = gatherCatalogMod(
        mod: _makeEntry(),
        forumIndex: _makeIndex(
          isTool: true,
          extras: ForumLlmExtras(aiUse: CatalogAiUse(usesAi: false)),
        ),
        extras: CatalogExtras(isTool: false, aiUse: CatalogAiUse(usesAi: true)),
      );
      expect(mod.isTool, isFalse);
      expect(mod.usesAi, isTrue);
      expect(mod.attributeKeys, isNot(contains('tool')));
    });

    test('a record with no AI use falls back to the AI answer', () {
      final mod = gatherCatalogMod(
        mod: _makeEntry(),
        forumIndex: _makeIndex(
          extras: ForumLlmExtras(aiUse: CatalogAiUse(usesAi: true)),
        ),
        extras: CatalogExtras(),
      );
      expect(mod.usesAi, isTrue);
    });
  });

  group('Safe to add attribute key', () {
    test('is added only when the answer is yes', () {
      CatalogMod withAnswer(CatalogSaveAnswer answer) => gatherCatalogMod(
        mod: _makeEntry(),
        extras: CatalogExtras(canAdd: answer),
      );
      expect(withAnswer(CatalogSaveAnswer.yes).attributeKeys,
          contains('safeToAdd'));
      expect(withAnswer(CatalogSaveAnswer.no).attributeKeys,
          isNot(contains('safeToAdd')));
      expect(withAnswer(CatalogSaveAnswer.depends).attributeKeys,
          isNot(contains('safeToAdd')));
    });
  });
}
