import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/models/forum_data_bundle.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';

/// Shapes copied from the scraper's `mod-catalog.json` and
/// `mod-catalog-details.json`, trimmed to the fields TriOS reads.
void main() {
  group('mod-catalog.json', () {
    test('reads the id and source posts', () {
      final file = ModRepoFileMapper.fromMap({
        'items': [
          {
            'id': '3d-sector-2',
            'name': '3D Sector V0.3.5',
            'modVersion': '0.3.5',
            'gameVersionReq': '0.98a',
            'authorsList': ['TresDisco'],
            'urls': {
              'Discord': 'https://discord.com/channels/1/2/2',
              'Forum':
                  'https://fractalsoftworks.com/forum/index.php?topic=36154.0',
            },
            'sources': ['Discord', 'ModdingSubforum'],
            'categories': ['Total Conversion'],
            'images': {},
            'sourcePosts': [
              {
                'kind': 'forum',
                'id': '36154',
                'llmModName': '3D Sector',
                'foundBy': 'rulesAndLlm',
              },
              {
                'kind': 'discord',
                'id': '1559645440188874795',
                'llmModName': '3D Sector',
                'foundBy': 'rulesAndLlm',
              },
            ],
          },
        ],
        'collections': [
          {
            'id': 'some-collection',
            'name': 'Some Collection',
            'sourcePost': {'kind': 'forum', 'id': '34176'},
            'modIds': ['a', 'b'],
          },
        ],
        'totalCount': 1,
        'lastUpdated': '2026-10-20T23:02:00.000Z',
      });

      final entry = file.items.single;
      expect(entry.id, '3d-sector-2');
      expect(entry.forumPost?.id, '36154');
      expect(entry.forumPost?.llmModName, '3D Sector');
      expect(entry.discordPosts.single.id, '1559645440188874795');
      expect(entry.isPartOfThread, isFalse);
    });

    test('unknown kind and foundBy values do not fail the parse', () {
      final post = CatalogSourcePostMapper.fromMap({
        'kind': 'somewhereNew',
        'id': '1',
        'foundBy': 'somethingNew',
      });

      expect(post.kind, CatalogSourceKind.unknown);
      expect(post.foundBy, CatalogFoundBy.unknown);
    });

    test('a forum post found only by the AI marks the entry part of a thread', () {
      final entry = ModRepoEntryMapper.fromMap({
        'name': 'Useful.Tithes 1.0.a',
        'sourcePosts': [
          {
            'kind': 'forum',
            'id': '34161',
            'llmModName': 'Useful.Tithes',
            'foundBy': 'llm',
          },
        ],
      });

      expect(entry.isPartOfThread, isTrue);
    });
  });

  group('mod-catalog-details.json discordThreads', () {
    test('reads a thread answer', () {
      final thread = DiscordThreadAnswerMapper.fromMap({
        'threadId': '1203053249377079297',
        'url': 'https://discord.com/channels/1/1203053249377079297',
        'name': 'Example Mod 1.0.0',
        'mods': [
          {
            'name': 'Example Mod',
            'role': 'main',
            'downloads': [
              {
                'url': 'https://DownloadThisMod.com',
                'label': '',
                'kind': 'direct',
                'sourceHost': 'downloadthismod.com',
                'requiresManualStep': true,
              },
            ],
            'extras': {
              'version': '1.0.0',
              'summary': {'sentence': 'Adds a new mod to the game.'},
            },
          },
        ],
      });

      final mod = thread.mods.single;
      expect(mod.name, 'Example Mod');
      expect(mod.role, LlmModRole.main);
      expect(mod.downloads.single.kind, LlmDownloadKind.direct);
      expect(mod.extras?.summary?.sentence, 'Adds a new mod to the game.');
    });

    test('reads nicknames, the tool flag, canAdd and aiUse', () {
      final mod = ForumLlmModMapper.fromMap({
        'name': 'Example Mod',
        'role': 'main',
        'downloads': [],
        'nicknames': ['EM'],
        'isTool': true,
        'extras': {
          'canAdd': 'yes',
          'aiUse': {
            'quote': 'Some portraits were generated.',
            'usesAi': true,
            'uses': [
              {'area': 'portraits', 'how': 'generated', 'extent': 'some'},
              {'area': 'music', 'optional': true},
            ],
            'tools': ['Midjourney'],
          },
        },
      });

      expect(mod.nicknames, ['EM']);
      expect(mod.isTool, isTrue);
      expect(mod.extras?.canAdd, 'yes');
      final aiUse = mod.extras?.aiUse;
      expect(aiUse?.usesAi, isTrue);
      expect(aiUse?.uses?.first.area, 'portraits');
      expect(aiUse?.uses?.first.how, 'generated');
      expect(aiUse?.uses?.last.optional, isTrue);
      expect(aiUse?.tools, ['Midjourney']);
    });

    test('reads requirements and the save answers', () {
      // Nexerelin's answer, copied from the details file.
      final extras = ForumLlmExtrasMapper.fromMap({
        'needs': ['LazyLib', 'MagicLib'],
        'optionalNeeds': ['Version Checker'],
        'canAdd': 'depends',
        'saveCompatibility':
            'Can be added to existing save, although a few features may be missing.',
        'canRemove': 'no',
        'removalCompatibility': 'Cannot be removed from an existing save.',
        'updateNotes': [
          {
            'quote':
                'Updates will almost always be save-compatible for several versions.',
            'answer': 'depends',
          },
        ],
      });

      expect(extras.needs, ['LazyLib', 'MagicLib']);
      expect(extras.optionalNeeds, ['Version Checker']);
      expect(extras.canAdd, 'depends');
      expect(extras.canRemove, 'no');
      expect(
        extras.removalCompatibility,
        'Cannot be removed from an existing save.',
      );
      final note = extras.updateNotes!.single;
      expect(note.version, isNull);
      expect(note.answer, 'depends');
    });

    test('an empty aiUse means the post says nothing about AI', () {
      final extras = ForumLlmExtrasMapper.fromMap({
        'aiUse': <String, dynamic>{},
      });

      expect(extras.aiUse, isNotNull);
      expect(extras.aiUse?.usesAi, isNull);
    });
  });
}
