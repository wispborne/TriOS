import 'package:flutter_test/flutter_test.dart';
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
    test('parses a full llm block', () {
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
      expect(mod.requires, ['LazyLib', 'MagicLib']);
      expect(mod.downloads, hasLength(2));

      final direct = mod.downloads.first;
      expect(direct.kind, LlmDownloadKind.direct);
      expect(direct.confidence, LlmDownloadConfidence.medium);
      expect(direct.resolvedDirectUrl, 'https://example.com/mod.zip?dl=1');
      expect(direct.sourceHost, 'Dropbox');
      expect(direct.fileName, 'mod.zip');
      expect(direct.requiresManualStep, false);
      expect(mod.downloads[1].kind, LlmDownloadKind.trios);

      final extras = mod.extras!;
      expect(extras.version, '1.2');
      expect(extras.summary!.sentence, 'A short summary.');
      expect(extras.summary!.paragraph, 'A longer summary paragraph.');
      expect(extras.changelog!.entries, hasLength(2));
      expect(extras.changelog!.entries!['1.2'], 'Fixed things.');
      expect(extras.changelog!.link, isNull);
      expect(extras.license, 'CC BY-NC-SA 4.0');
      expect(extras.supportLinks!.single.type, 'patreon');
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
      expect(mod.downloads.single.kind, LlmDownloadKind.unknown);
      expect(mod.downloads.single.confidence, LlmDownloadConfidence.unknown);
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
          ForumModIndexMapper.fromMap(entry).llm!.mods.single.extras!.changelog!;
      expect(changelog.entries, isNull);
      expect(changelog.link, 'https://example.com/changelog.txt');
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
