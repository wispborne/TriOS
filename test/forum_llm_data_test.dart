import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';

/// Minimal valid index entry; tests add an `llm` block on top of this.
Map<String, dynamic> baseIndexEntry() => {
  'topicId': 146,
  'title': 'Test Mod',
  'inModIndex': true,
  'isArchivedModIndex': false,
  'author': 'Author',
  'replies': 5,
  'views': 100,
  'topicUrl': 'https://fractalsoftworks.com/forum/index.php?topic=146.0',
  'isWip': false,
};

void main() {
  group('ForumLlmData parsing', () {
    test('parses a full llm block in the old format', () {
      final entry = baseIndexEntry()
        ..['llm'] = {
          'isMod': true, // Being removed by the scraper; must be ignored.
          'mods': [
            {
              'name': 'Test Mod',
              'role': 'main',
              'requires': ['LazyLib', 'MagicLib'],
              'downloads': [
                {
                  'url': 'https://example.com/mod.zip',
                  'label': 'Download version 1.2',
                  'kind': 'direct',
                  'resolvedDirectUrl': 'https://example.com/mod.zip?dl=1',
                  'sourceHost': 'Dropbox',
                  'fileName': 'mod.zip',
                  'confidence': 'medium',
                  'requiresManualStep': false,
                },
                {
                  'url': 'https://trilink.wispborne.com/open.html?mod=x',
                  'label': '',
                  'kind': 'trios',
                  'confidence': 'low',
                  'requiresManualStep': false,
                },
              ],
              'extras': {
                'version': '1.2',
                'summary': {
                  'sentence': 'A short summary.',
                  'paragraph': 'A longer summary paragraph.',
                },
                'changelog': {
                  'entries': {'1.2': 'Fixed things.', '1.1': 'Added things.'},
                },
                'license': 'CC BY-NC-SA 4.0',
                'supportLinks': [
                  {'url': 'https://patreon.com/someone', 'type': 'patreon'},
                ],
              },
            },
          ],
        };

      final index = ForumModIndexMapper.fromMap(entry);
      final llm = index.llm;
      expect(llm, isNotNull);
      expect(llm!.mods, hasLength(1));

      final mod = llm.mods.single;
      expect(mod.name, 'Test Mod');
      expect(mod.role, LlmModRole.main);
      expect(mod.parentMods, ['LazyLib', 'MagicLib']);
      expect(mod.downloads, hasLength(2));

      final direct = mod.downloads.first;
      expect(direct.type, LlmDownloadType.direct);
      expect(direct.confidence, LlmDownloadConfidence.medium);
      expect(direct.resolvedDirectUrl, 'https://example.com/mod.zip?dl=1');
      expect(direct.sourceHost, 'Dropbox');
      expect(direct.fileName, 'mod.zip');
      expect(direct.requiresManualStep, false);
      expect(mod.downloads[1].type, LlmDownloadType.trios);

      expect(mod.release!.version, '1.2');
      expect(mod.summary!.sentence, 'A short summary.');
      expect(mod.summary!.paragraph, 'A longer summary paragraph.');
      expect(mod.release!.changelog!.entries, hasLength(2));
      expect(mod.release!.changelog!.entries!['1.2'], 'Fixed things.');
      expect(mod.release!.changelog!.url, isNull);
      expect(mod.sourceCode!.license, 'CC BY-NC-SA 4.0');
      expect(mod.supportLinks!.single.type, 'patreon');
    });

    test('parses a full llm block in the new format', () {
      final entry = baseIndexEntry()
        ..['llm'] = {
          'mods': [
            {
              'name': 'Test Mod',
              'role': 'addon',
              'parentMod': 'Base Mod',
              'types': ['mod', 'tool'],
              'downloads': [
                {'url': 'https://example.com/mod.zip', 'type': 'direct'},
              ],
              'nicknames': ['TM'],
              'imageUrl': 'ext:https://example.com/logo.png',
              'release': {
                'version': '1.2',
                'changelog': {
                  'url': 'https://example.com/changelog.txt',
                  'entries': {'1.2': 'Fixed things.'},
                },
              },
              'saveCompat': {
                'adding': {'quote': 'Save compatible.', 'answer': 'yes'},
                'removing': {'quote': 'Needs a new game.', 'answer': 'no'},
                'updateNotes': [
                  {'version': '1.2', 'quote': 'Safe to update.', 'answer': 'yes'},
                ],
              },
              'requirements': {
                'required': ['LazyLib'],
                'optional': ['Nexerelin'],
              },
              'conflicts': [
                {'name': 'Other Mod', 'quote': 'Crashes.', 'type': 'technical'},
              ],
              'aiUse': {
                'usesAi': true,
                'uses': [
                  {'area': 'portraits', 'isOptional': true},
                ],
              },
              'sourceCode': {
                'url': 'https://github.com/someone/mod',
                'license': 'MIT',
              },
              'supportLinks': [
                {'url': 'https://ko-fi.com/someone', 'type': 'kofi'},
              ],
              'description': {
                'startsWith': 'This mod',
                'endsWith': 'the end.',
                'summary': {'sentence': 'A short summary.'},
              },
            },
          ],
        };

      final mod = ForumModIndexMapper.fromMap(entry).llm!.mods.single;
      expect(mod.role, LlmModRole.addon);
      expect(mod.parentMods, ['Base Mod']);
      expect(mod.isTool, isTrue);
      expect(mod.downloads.single.type, LlmDownloadType.direct);
      expect(mod.nicknames, ['TM']);
      expect(mod.imageUrl, 'https://example.com/logo.png');
      expect(mod.release!.version, '1.2');
      expect(mod.release!.changelog!.url, 'https://example.com/changelog.txt');
      expect(mod.release!.changelog!.entries!['1.2'], 'Fixed things.');
      expect(mod.saveCompat!.adding!.quote, 'Save compatible.');
      expect(mod.saveCompat!.adding!.answer, CatalogSaveAnswer.yes);
      expect(mod.saveCompat!.removing!.answer, CatalogSaveAnswer.no);
      expect(mod.saveCompat!.updateNotes!.single.answer, 'yes');
      expect(mod.requirements!.required, ['LazyLib']);
      expect(mod.requirements!.optional, ['Nexerelin']);
      expect(mod.conflicts!.single.name, 'Other Mod');
      expect(mod.aiUse!.uses!.single.isOptional, isTrue);
      expect(mod.sourceCode!.safeUrl, 'https://github.com/someone/mod');
      expect(mod.sourceCode!.license, 'MIT');
      expect(mod.supportLinks!.single.type, 'kofi');
      expect(mod.summary!.sentence, 'A short summary.');
    });

    test('old save, requirement and AI fields read in their new places', () {
      final entry = baseIndexEntry()
        ..['llm'] = {
          'mods': [
            {
              'name': 'Test Mod',
              'role': 'main',
              'isTool': false,
              'image': 'ext:https://example.com/logo.png',
              'extras': {
                'saveCompatibility': 'Save compatible.',
                'canAdd': 'yes',
                'removalCompatibility': 'Cannot be removed.',
                'canRemove': 'no',
                'updateNotes': [
                  {'quote': 'Start a new game.', 'answer': 'no'},
                ],
                'needs': ['LazyLib'],
                'optionalNeeds': ['Nexerelin'],
                'conflicts': [
                  {'name': 'Other Mod', 'quote': 'Crashes.', 'kind': 'technical'},
                ],
                'aiUse': {
                  'usesAi': true,
                  'uses': [
                    {'area': 'portraits', 'optional': true},
                  ],
                },
              },
            },
          ],
        };

      final mod = ForumModIndexMapper.fromMap(entry).llm!.mods.single;
      expect(mod.isTool, isFalse);
      expect(mod.imageUrl, 'https://example.com/logo.png');
      expect(mod.saveCompat!.adding!.quote, 'Save compatible.');
      expect(mod.saveCompat!.adding!.answer, CatalogSaveAnswer.yes);
      expect(mod.saveCompat!.removing!.quote, 'Cannot be removed.');
      expect(mod.saveCompat!.removing!.answer, CatalogSaveAnswer.no);
      expect(mod.saveCompat!.updateNotes!.single.quote, 'Start a new game.');
      expect(mod.requirements!.required, ['LazyLib']);
      expect(mod.requirements!.optional, ['Nexerelin']);
      expect(mod.conflicts!.single.quote, 'Crashes.');
      expect(mod.aiUse!.uses!.single.isOptional, isTrue);
    });

    test('an old mod with no tool answer has no tool answer', () {
      final entry = baseIndexEntry()
        ..['llm'] = {
          'mods': [
            {'name': 'Test Mod', 'role': 'main', 'extras': {}},
          ],
        };

      final mod = ForumModIndexMapper.fromMap(entry).llm!.mods.single;
      expect(mod.types, isNull);
      expect(mod.isTool, isNull);
    });

    test('entry without an llm block parses with llm == null', () {
      final index = ForumModIndexMapper.fromMap(baseIndexEntry());
      expect(index.llm, isNull);
    });

    test('unknown enum values decode to unknown', () {
      final entry = baseIndexEntry()
        ..['llm'] = {
          'mods': [
            {
              'name': 'Test Mod',
              'role': 'sidegrade',
              'downloads': [
                {
                  'url': 'https://example.com/mod.zip',
                  'label': 'Download',
                  'kind': 'torrent',
                  'confidence': 'certain',
                  'requiresManualStep': false,
                },
              ],
            },
          ],
        };

      final mod = ForumModIndexMapper.fromMap(entry).llm!.mods.single;
      expect(mod.role, LlmModRole.unknown);
      expect(mod.downloads.single.type, LlmDownloadType.unknown);
      expect(mod.downloads.single.confidence, LlmDownloadConfidence.unknown);
    });

    test('requires written as a comma-separated string parses as a list', () {
      final entry = baseIndexEntry()
        ..['llm'] = {
          'mods': [
            {
              'name': 'Test Mod',
              'role': 'main',
              'requires': 'GraphicsLib, MagicLib, LazyLib',
            },
          ],
        };

      final mod = ForumModIndexMapper.fromMap(entry).llm!.mods.single;
      expect(mod.parentMods, ['GraphicsLib', 'MagicLib', 'LazyLib']);
    });

    test('requires written as a single string parses as a one-item list', () {
      final entry = baseIndexEntry()
        ..['llm'] = {
          'mods': [
            {'name': 'Test Mod', 'role': 'main', 'requires': 'LAZYLIB'},
          ],
        };

      final mod = ForumModIndexMapper.fromMap(entry).llm!.mods.single;
      expect(mod.parentMods, ['LAZYLIB']);
    });

    test('summary with only a sentence parses', () {
      final entry = baseIndexEntry()
        ..['llm'] = {
          'mods': [
            {
              'name': 'Test Mod',
              'role': 'main',
              'extras': {
                'summary': {'sentence': 'A short summary.'},
              },
            },
          ],
        };

      final summary =
          ForumModIndexMapper.fromMap(entry).llm!.mods.single.summary!;
      expect(summary.sentence, 'A short summary.');
      expect(summary.paragraph, isNull);
    });

    test('malformed llm block decodes to null instead of throwing', () {
      final entry = baseIndexEntry()
        ..['llm'] = {
          'mods': [
            {'role': 'main'}, // Missing required 'name'.
          ],
        };

      final index = ForumModIndexMapper.fromMap(entry);
      expect(index.llm, isNull);
      // The rest of the entry still parsed.
      expect(index.topicId, 146);
    });

    test('llm block that is not a map decodes to null', () {
      final entry = baseIndexEntry()..['llm'] = 'garbage';
      expect(ForumModIndexMapper.fromMap(entry).llm, isNull);
    });

    test('sourceCode parses', () {
      final entry = baseIndexEntry()
        ..['llm'] = {
          'mods': [
            {
              'name': 'Test Mod',
              'role': 'main',
              'extras': {'sourceCode': 'https://github.com/someone/mod'},
            },
          ],
        };

      final sourceCode =
          ForumModIndexMapper.fromMap(entry).llm!.mods.single.sourceCode!;
      expect(sourceCode.url, 'https://github.com/someone/mod');
      expect(sourceCode.safeUrl, 'https://github.com/someone/mod');
    });

    test('changelog with only a link parses', () {
      final entry = baseIndexEntry()
        ..['llm'] = {
          'mods': [
            {
              'name': 'Test Mod',
              'role': 'main',
              'downloads': [],
              'extras': {
                'changelog': {'link': 'https://example.com/changelog.txt'},
              },
            },
          ],
        };

      final changelog =
          ForumModIndexMapper.fromMap(
            entry,
          ).llm!.mods.single.release!.changelog!;
      expect(changelog.entries, isNull);
      expect(changelog.url, 'https://example.com/changelog.txt');
    });
  });

  group('ForumLlmSourceCode.safeUrl', () {
    String? urlFor(String? sourceCode) =>
        ForumLlmSourceCode(url: sourceCode).safeUrl;

    test('is null when the mod has no source code link', () {
      expect(urlFor(null), isNull);
    });

    test('keeps http and https links, without surrounding spaces', () {
      expect(urlFor('  https://github.com/a/b  '), 'https://github.com/a/b');
      expect(urlFor('http://bitbucket.org/a/b'), 'http://bitbucket.org/a/b');
    });

    test('drops anything that is not a web link', () {
      expect(urlFor(''), isNull);
      expect(urlFor('github.com/a/b'), isNull);
      expect(urlFor('ask the author'), isNull);
      expect(urlFor('javascript:alert(1)'), isNull);
    });
  });

  group('ForumLlmData.mainMod', () {
    ForumLlmMod mod(String name, LlmModRole role) =>
        ForumLlmMod(name: name, role: role);

    test('returns null when there are no mods', () {
      expect(ForumLlmData().mainMod, isNull);
    });

    test('returns the only mod', () {
      final data = ForumLlmData(mods: [mod('A', LlmModRole.main)]);
      expect(data.mainMod!.name, 'A');
    });

    test('prefers the first main-role mod', () {
      final data = ForumLlmData(
        mods: [
          mod('Addon', LlmModRole.addon),
          mod('Main1', LlmModRole.main),
          mod('Main2', LlmModRole.main),
        ],
      );
      expect(data.mainMod!.name, 'Main1');
    });

    test('falls back to the first mod when no main exists', () {
      final data = ForumLlmData(
        mods: [mod('Addon', LlmModRole.addon), mod('Sep', LlmModRole.separate)],
      );
      expect(data.mainMod!.name, 'Addon');
    });
  });
}
