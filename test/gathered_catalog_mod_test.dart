import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_details.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/catalog_mod.dart';

ModRepoEntry _makeMod({
  String name = 'TestMod',
  String? summary,
  String? description,
  String? partOfThreadTitle,
  Map<ModUrlType, String>? urls,
  List<ModSource>? sources,
}) =>
    ModRepoEntry(
      name: name,
      summary: summary,
      description: description,
      partOfThreadTitle: partOfThreadTitle,
      urls: urls,
      sources: sources,
    );

ForumModIndex _makeIndex({
  int topicId = 1,
  String title = 'Thread Title',
  String author = 'Author',
  bool isWip = false,
  bool isArchivedModIndex = false,
  ForumLlmData? llm,
  int views = 100,
  int replies = 10,
}) =>
    ForumModIndex(
      topicId: topicId,
      title: title,
      author: author,
      inModIndex: true,
      isArchivedModIndex: isArchivedModIndex,
      replies: replies,
      views: views,
      topicUrl: 'https://example.com/topic=$topicId',
      isWip: isWip,
      llm: llm,
    );

ForumLlmMod _makeLlmMod({
  required String name,
  LlmModRole role = LlmModRole.unknown,
  ForumLlmExtras? extras,
  String? image,
}) =>
    ForumLlmMod(
      name: name,
      role: role,
      extras: extras,
      image: image,
    );

void main() {
  group('gatherCatalogMod', () {
    test('add-on card gets its own AI entry', () {
      final mainExtras = ForumLlmExtras(
        summary: ForumLlmSummary(
          sentence: 'Main sentence.',
          paragraph: 'Main paragraph.',
        ),
      );
      final addonExtras = ForumLlmExtras(
        summary: ForumLlmSummary(
          sentence: 'Addon sentence.',
          paragraph: 'Addon paragraph.',
        ),
      );
      final llm = ForumLlmData(mods: [
        _makeLlmMod(
          name: 'Nexerelin',
          role: LlmModRole.main,
          extras: mainExtras,
        ),
        _makeLlmMod(
          name: 'Nexerelin Extras',
          role: LlmModRole.addon,
          extras: addonExtras,
        ),
      ]);
      final index = _makeIndex(llm: llm);
      final mod = _makeMod(
        name: 'Nexerelin Extras',
        partOfThreadTitle: 'Nexerelin Thread',
      );

      final gathered = gatherCatalogMod(mod: mod, forumIndex: index);

      expect(gathered.aiSentence, 'Addon sentence.');
      expect(gathered.aiParagraph, 'Addon paragraph.');
      expect(gathered.llmMod?.name, 'Nexerelin Extras');
    });

    test('add-on with no name match falls back to main mod', () {
      final mainExtras = ForumLlmExtras(
        summary: ForumLlmSummary(
          sentence: 'Main sentence.',
          paragraph: 'Main paragraph.',
        ),
      );
      final llm = ForumLlmData(mods: [
        _makeLlmMod(
          name: 'Nexerelin',
          role: LlmModRole.main,
          extras: mainExtras,
        ),
      ]);
      final index = _makeIndex(llm: llm);
      final mod = _makeMod(
        name: 'Unknown Addon',
        partOfThreadTitle: 'Nexerelin Thread',
      );

      final gathered = gatherCatalogMod(mod: mod, forumIndex: index);

      expect(gathered.aiSentence, 'Main sentence.');
      expect(gathered.llmMod?.name, 'Nexerelin');
    });

    test('normal entry gets main mod', () {
      final extras = ForumLlmExtras(
        summary: ForumLlmSummary(
          sentence: 'A sentence.',
          paragraph: 'A paragraph.',
        ),
      );
      final llm = ForumLlmData(mods: [
        _makeLlmMod(
          name: 'TestMod',
          role: LlmModRole.main,
          extras: extras,
        ),
        _makeLlmMod(name: 'SomeAddon', role: LlmModRole.addon),
      ]);
      final index = _makeIndex(llm: llm);
      final mod = _makeMod(name: 'TestMod');

      final gathered = gatherCatalogMod(mod: mod, forumIndex: index);

      expect(gathered.llmMod?.name, 'TestMod');
      expect(gathered.aiSentence, 'A sentence.');
    });

    test('all five texts survive', () {
      final extras = ForumLlmExtras(
        summary: ForumLlmSummary(
          sentence: 'AI sentence.',
          paragraph: 'AI paragraph.',
        ),
      );
      final llm = ForumLlmData(mods: [
        _makeLlmMod(
          name: 'TestMod',
          role: LlmModRole.main,
          extras: extras,
        ),
      ]);
      final index = _makeIndex(llm: llm);
      final mod = _makeMod(
        name: 'TestMod',
        summary: 'Author summary',
        description: 'Author description',
      );

      final gathered = gatherCatalogMod(mod: mod, forumIndex: index);

      expect(gathered.summaryText, 'Author summary');
      expect(gathered.descriptionText, 'Author description');
      expect(gathered.modInfoText, isNull);
      expect(gathered.aiSentence, 'AI sentence.');
      expect(gathered.aiParagraph, 'AI paragraph.');
    });

    test('WIP and Archived flags come through', () {
      final index = _makeIndex(isWip: true, isArchivedModIndex: true);
      final mod = _makeMod();

      final gathered = gatherCatalogMod(mod: mod, forumIndex: index);

      expect(gathered.isWip, isTrue);
      expect(gathered.isArchived, isTrue);
    });

    test('without forum index, flags default to false', () {
      final mod = _makeMod();

      final gathered = gatherCatalogMod(mod: mod);

      expect(gathered.isWip, isFalse);
      expect(gathered.isArchived, isFalse);
    });

    test('attribute keys include download, source, and flags', () {
      final index = _makeIndex(isWip: true);
      final mod = _makeMod(
        urls: {ModUrlType.DirectDownload: 'https://example.com/dl'},
        sources: [ModSource.Discord, ModSource.Index],
      );

      final gathered = gatherCatalogMod(mod: mod, forumIndex: index);

      expect(gathered.attributeKeys, contains('download'));
      expect(gathered.attributeKeys, contains('discord'));
      expect(gathered.attributeKeys, contains('index'));
      expect(gathered.attributeKeys, contains('wip'));
      expect(gathered.attributeKeys, isNot(contains('archived')));
    });
  });

  group('gatherCatalogMod source code and license', () {
    CatalogMod gatherWith({String? sourceCode, String? license}) {
      final llm = ForumLlmData(mods: [
        _makeLlmMod(
          name: 'TestMod',
          role: LlmModRole.main,
          extras: ForumLlmExtras(sourceCode: sourceCode, license: license),
        ),
      ]);
      return gatherCatalogMod(
        mod: _makeMod(name: 'TestMod'),
        forumIndex: _makeIndex(llm: llm),
      );
    }

    test('a source code link and a license come through', () {
      final gathered = gatherWith(
        sourceCode: 'https://github.com/someone/mod',
        license: 'MIT',
      );

      expect(gathered.sourceCodeUrl, 'https://github.com/someone/mod');
      expect(gathered.licenseText, 'MIT');
    });

    test('both are null when the mod has neither', () {
      final gathered = gatherWith();

      expect(gathered.sourceCodeUrl, isNull);
      expect(gathered.licenseText, isNull);
    });

    test('a source code link that is not a web link is dropped', () {
      expect(gatherWith(sourceCode: 'ask me').sourceCodeUrl, isNull);
    });

    test('&nbsp; in the license becomes a space', () {
      final gathered = gatherWith(license: 'Free&nbsp;to&nbsp;use.');

      expect(gathered.licenseText, 'Free to use.');
    });

    test('a license that is only a link is offered as a link', () {
      final gathered = gatherWith(
        license: 'https://creativecommons.org/licenses/by-nc/4.0/',
      );

      expect(
        gathered.licenseUrl,
        'https://creativecommons.org/licenses/by-nc/4.0/',
      );
    });

    test('a license with words around a link is not a link', () {
      final gathered = gatherWith(
        license: 'See https://example.com/license for the rules.',
      );

      expect(gathered.licenseUrl, isNull);
    });

    test('the source code attribute only shows up when there is a link', () {
      expect(
        gatherWith(sourceCode: 'https://github.com/a/b').attributeKeys,
        contains('sourceCode'),
      );
      expect(
        gatherWith(license: 'MIT').attributeKeys,
        isNot(contains('sourceCode')),
      );
    });
  });

  group('sourceCodeHostName', () {
    test('names the sites mods actually use', () {
      expect(sourceCodeHostName('https://github.com/a/b'), 'GitHub');
      expect(sourceCodeHostName('https://www.github.com/a/b'), 'GitHub');
      expect(sourceCodeHostName('https://bitbucket.org/a/b'), 'Bitbucket');
      expect(sourceCodeHostName('https://gitlab.com/a/b'), 'GitLab');
    });

    test('falls back to the site address for anywhere else', () {
      expect(
        sourceCodeHostName('https://www.assembla.com/spaces/x'),
        'assembla.com',
      );
    });
  });

  group('gatherCatalogMod with forumDetails', () {
    test('details fields win over index fields', () {
      final index = _makeIndex(
        author: 'IndexAuthor',
      );
      final details = ForumModDetails(
        topicId: 1,
        title: 'Detail Title',
        author: 'DetailAuthor',
        authorTitle: 'Modding Legend',
        authorPostCount: 500,
        authorAvatarPath: '/avatars/detail.png',
        postDate: DateTime(2024, 6, 1),
        lastEditDate: DateTime(2024, 7, 1),
        category: 'Mods',
        contentHtml: '<p>hello</p>',
        isPlaceholderDetail: false,
      );
      final mod = _makeMod(name: 'TestMod');

      final gathered = gatherCatalogMod(
        mod: mod,
        forumIndex: index,
        forumDetails: details,
      );

      expect(gathered.authorTitle, 'Modding Legend');
      expect(gathered.authorPostCount, 500);
      // Forum avatar paths are relative to the forum root; gathering turns
      // them into a full URL so they can be loaded as a web image.
      expect(
        gathered.authorAvatarPath,
        'https://fractalsoftworks.com/avatars/detail.png',
      );
      expect(gathered.postDate, DateTime(2024, 6, 1));
      expect(gathered.lastEditDate, DateTime(2024, 7, 1));
      expect(gathered.category, 'Mods');
    });

    test('index fills in when details fields are null', () {
      final index = _makeIndex(
        author: 'IndexAuthor',
      );
      final details = ForumModDetails(
        topicId: 1,
        title: 'Detail Title',
        author: 'DetailAuthor',
        contentHtml: '<p>hello</p>',
        isPlaceholderDetail: false,
      );
      final mod = _makeMod(name: 'TestMod');

      final gathered = gatherCatalogMod(
        mod: mod,
        forumIndex: index,
        forumDetails: details,
      );

      expect(gathered.authorTitle, isNull);
      expect(gathered.authorPostCount, isNull);
      expect(gathered.views, 100);
      expect(gathered.replies, 10);
    });
  });
}
