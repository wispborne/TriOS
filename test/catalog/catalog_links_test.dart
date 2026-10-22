import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_links.dart';
import 'package:trios/catalog/models/forum_data_bundle.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/forum_mod_index.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_record_source.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/utils/catalog_search.dart';

Mod _mod(
  String id, {
  String? name,
  String? threadId,
  String? nexusId,
}) {
  return Mod(
    id: id,
    isEnabledInGame: true,
    modVariants: [
      ModVariant(
        modInfo: ModInfo(
          id: id,
          name: name,
          version: Version.parse('1.0.0', sanitizeInput: true),
        ),
        versionCheckerInfo: (threadId == null && nexusId == null)
            ? null
            : VersionCheckerInfo(modThreadId: threadId, modNexusId: nexusId),
        modFolder: Directory(''),
        hasNonBrickedModInfo: true,
        gameCoreFolder: Directory(''),
      ),
    ],
  );
}

/// A catalog entry. [partOfThread] marks its forum post as found only by the
/// AI, which is how the catalog marks a mod sharing its topic with others.
ModRepoEntry _entry(
  String name, {
  String? id,
  String? forumUrl,
  String? nexusUrl,
  bool partOfThread = false,
  List<CatalogSourcePost>? sourcePosts,
}) {
  final urls = <ModUrlType, String>{};
  if (forumUrl != null) urls[ModUrlType.Forum] = forumUrl;
  if (nexusUrl != null) urls[ModUrlType.NexusMods] = nexusUrl;
  final topicId = extractForumTopicId(forumUrl);
  return ModRepoEntry(
    id: id,
    name: name,
    urls: urls.isEmpty ? null : urls,
    sourcePosts:
        sourcePosts ??
        [
          if (topicId != null)
            CatalogSourcePost(
              kind: CatalogSourceKind.forum,
              id: '$topicId',
              foundBy: partOfThread ? CatalogFoundBy.llm : CatalogFoundBy.rules,
            ),
        ],
  );
}

CatalogSourcePost _post(
  CatalogSourceKind kind,
  String id,
  String? llmModName, {
  CatalogFoundBy foundBy = CatalogFoundBy.rulesAndLlm,
}) => CatalogSourcePost(
  kind: kind,
  id: id,
  llmModName: llmModName,
  foundBy: foundBy,
);

ForumLlmMod _threadMod(String name, {LlmModRole role = LlmModRole.main}) =>
    ForumLlmMod(
      name: name,
      role: role,
      extras: ForumLlmExtras(
        summary: ForumLlmSummary(sentence: 'AI wrote this about $name.'),
      ),
    );

Map<int, ForumModIndex> _thread(int topicId, String title, List<ForumLlmMod> mods) => {
  topicId: ForumModIndex(
    topicId: topicId,
    title: title,
    inModIndex: true,
    isArchivedModIndex: false,
    author: 'Someone',
    replies: 0,
    views: 0,
    topicUrl: 'https://example.com/topic',
    isWip: false,
    llm: ForumLlmData(mods: mods),
  ),
};

ModRecords _recordsLinking(
  String catalogName,
  String modId, {
  String? catalogId,
}) => ModRecords(
  records: {
    modId: ModRecord(
      recordKey: modId,
      modId: modId,
      sources: {
        'catalog': CatalogSource(catalogId: catalogId, name: catalogName),
      },
    ),
  },
);

void main() {
  group('matchCatalogToInstalled', () {
    test('a saved record link beats an exact-name match (Ashpad/Aashpad)', () {
      // The real install has a different name; a second mod happens to be named
      // exactly like the catalog entry. The saved link must win.
      final aashpad = _mod('aashpad', name: 'Aashpad');
      final other = _mod('other', name: 'Ashpad');
      final entry = _entry('Ashpad');

      final links = matchCatalogToInstalled(
        entries: [entry],
        installedMods: [aashpad, other],
        records: _recordsLinking('Ashpad', 'aashpad'),
      );

      expect(links, hasLength(1));
      expect(links.single.mod.id, 'aashpad');
      expect(links.single.signal, CatalogLinkSignal.persistedRecord);
    });

    test('without the saved link, Ashpad does not match Aashpad', () {
      final aashpad = _mod('aashpad', name: 'Aashpad');
      final links = matchCatalogToInstalled(
        entries: [_entry('Ashpad')],
        installedMods: [aashpad],
        records: null,
      );
      expect(links, isEmpty);
    });

    test('exact name match links when names agree', () {
      final links = matchCatalogToInstalled(
        entries: [_entry('Nexerelin')],
        installedMods: [_mod('nexerelin', name: 'Nexerelin')],
        records: null,
      );
      expect(links.single.mod.id, 'nexerelin');
      expect(links.single.signal, CatalogLinkSignal.exactName);
    });

    test('fuzzy fallback matches "BoxUtil" to installed "Box Util"', () {
      final links = matchCatalogToInstalled(
        entries: [_entry('BoxUtil')],
        installedMods: [_mod('boxutil', name: 'Box Util')],
        records: null,
      );
      expect(links.single.mod.id, 'boxutil');
      expect(links.single.signal, CatalogLinkSignal.fuzzyName);
    });

    test('forum thread id links the parent entry', () {
      final links = matchCatalogToInstalled(
        entries: [
          _entry(
            'Parent Mod',
            forumUrl: 'https://fractalsoftworks.com/forum/index.php?topic=123.0',
          ),
        ],
        installedMods: [_mod('parent', name: 'Different Name', threadId: '123')],
        records: null,
      );
      expect(links.single.mod.id, 'parent');
      expect(links.single.signal, CatalogLinkSignal.threadId);
    });

    test(
      'version text does not let a child mod match the parent catalog entry',
      () {
        const forumUrl =
            'https://fractalsoftworks.com/forum/index.php?topic=13236.0';
        final brightonEntry = _entry('Brighton Federation 0.0.4a');
        final hmiEntry = _entry(
          'Hazard Mining Incorporated',
          forumUrl: forumUrl,
        );

        final links = CatalogLinks(
          matchCatalogToInstalled(
            entries: [brightonEntry, hmiEntry],
            installedMods: [
              _mod(
                'HMI_brighton',
                name: 'Brighton Federation',
                threadId: '13236',
              ),
            ],
            records: _recordsLinking(
              'Hazard Mining Incorporated',
              'HMI_brighton',
            ),
          ),
        );

        expect(
          links.linkForName('Brighton Federation 0.0.4a')?.mod.id,
          'HMI_brighton',
        );
        expect(links.linkForName('Hazard Mining Incorporated'), isNull);
      },
    );

    test('a child listed after its parent keeps the shared-thread match', () {
      const forumUrl =
          'https://fractalsoftworks.com/forum/index.php?topic=13236.0';
      final hmiEntry = _entry('Hazard Mining Incorporated', forumUrl: forumUrl);
      final supervillainsEntry = _entry(
        'HMI Supervillains 0.0.5c',
        forumUrl: forumUrl,
        partOfThread: true,
      );

      final links = CatalogLinks(
        matchCatalogToInstalled(
          entries: [hmiEntry, supervillainsEntry],
          installedMods: [
            _mod('HMI_SV', name: 'HMI Supervillains', threadId: '13236'),
          ],
          records: _recordsLinking('Hazard Mining Incorporated', 'HMI_SV'),
        ),
      );

      expect(links.linkForName('HMI Supervillains 0.0.5c')?.mod.id, 'HMI_SV');
      expect(links.linkForName('Hazard Mining Incorporated'), isNull);
    });

    test(
      'an add-on sharing the parent thread id does not steal the parent match',
      () {
        const forumUrl =
            'https://fractalsoftworks.com/forum/index.php?topic=123.0';
        final parentEntry = _entry('Parent Mod', forumUrl: forumUrl);
        // Add-on carries the same thread URL but is marked part-of-thread.
        final addonEntry = _entry(
          'Addon',
          forumUrl: forumUrl,
          partOfThread: true,
        );

        final links = matchCatalogToInstalled(
          entries: [parentEntry, addonEntry],
          installedMods: [
            _mod('parent', name: 'Parent Mod', threadId: '123'),
          ],
          records: null,
        );

        final byEntry = CatalogLinks(links);
        expect(byEntry.linkForName('Parent Mod')?.mod.id, 'parent');
        // The add-on must not link to the parent's installed mod.
        expect(byEntry.linkForName('Addon'), isNull);
      },
    );
  });

  group('CatalogLinks lookups', () {
    test('resolves from both directions', () {
      final links = matchCatalogToInstalled(
        entries: [_entry('Nexerelin')],
        installedMods: [_mod('nexerelin', name: 'Nexerelin')],
        records: null,
      );
      final catalogLinks = CatalogLinks(links);

      expect(catalogLinks.linkForModId('nexerelin')?.entry.name, 'Nexerelin');
      expect(
        catalogLinks.modForEntry(_entry('nexerelin'))?.id, // case-insensitive
        'nexerelin',
      );
    });
  });

  group('ModRecord.syntheticKey', () {
    // A frozen copy of the original algorithm. syntheticKey's output is saved on
    // disk as record keys, so it must stay byte-identical for existing names.
    String legacy(String name) {
      final normalized = name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '-');
      return 'catalog:$normalized';
    }

    const names = [
      'Ashpad',
      'Box Util',
      'Nexerelin',
      '! mod',
      '  -x  ',
      'A - B',
      'Mod!!!',
      'Some   Mod   Name',
      'MixedCASE Thing',
      'ünïcode name',
    ];

    for (final name in names) {
      test('matches the frozen scheme for "$name"', () {
        expect(ModRecord.syntheticKey(name), legacy(name));
      });
    }

    test('lowercases and trims like catalogEntryKey', () {
      expect(catalogEntryKey('  Ashpad  '), 'ashpad');
    });
  });

  group('catalog ids', () {
    test('a saved catalog id links the entry after its name changes', () {
      final links = matchCatalogToInstalled(
        entries: [_entry('Ashpad 2.0', id: 'ashpad')],
        installedMods: [_mod('aashpad', name: 'Aashpad')],
        records: _recordsLinking('Ashpad', 'aashpad', catalogId: 'ashpad'),
      );

      expect(links.single.mod.id, 'aashpad');
      expect(links.single.signal, CatalogLinkSignal.persistedRecord);
    });

    test('two entries with the same name each keep their own link', () {
      final first = _entry('Bushi', id: 'bushi');
      final second = _entry('Bushi', id: 'bushi-2');
      final links = CatalogLinks(
        matchCatalogToInstalled(
          entries: [first, second],
          installedMods: [_mod('hiigaran', name: 'Hiigaran Descendants')],
          records: _recordsLinking('Bushi', 'hiigaran', catalogId: 'bushi-2'),
        ),
      );

      expect(links.modForEntry(second)?.id, 'hiigaran');
      expect(links.modForEntry(first), isNull);
    });
  });

  group('llmModForEntry', () {
    test('picks the forum mod the catalog names on a shared topic', () {
      final forum = _thread(34161, "Hartley's Miscellaneous Mods", [
        _threadMod('Useful.Tithes'),
        _threadMod('Big Pilum Energy'),
        _threadMod('Lost.Sector'),
      ]);
      final entry = _entry(
        'Big Pilum Energy 1.0.d',
        sourcePosts: [
          _post(
            CatalogSourceKind.forum,
            '34161',
            'Big Pilum Energy',
            foundBy: CatalogFoundBy.llm,
          ),
        ],
      );

      final gathered = gatherCatalogMod(mod: entry, forumIndex: forum[34161]);
      expect(gathered.llmMod?.name, 'Big Pilum Energy');
      expect(gathered.partOfThreadTitle, "Hartley's Miscellaneous Mods");
    });

    test('falls back to the Discord answer when the forum has none', () {
      final entry = _entry(
        'Discord Mod',
        sourcePosts: [_post(CatalogSourceKind.discord, '42', 'Discord Mod')],
      );
      final thread = DiscordThreadAnswer(
        threadId: '42',
        url: 'https://discord.com/channels/1/42',
        name: 'Discord Mod 1.0',
        mods: [_threadMod('Discord Mod')],
      );

      final gathered = gatherCatalogMod(
        mod: entry,
        discordThreads: discordThreadsFor(entry, {'42': thread}),
      );
      expect(gathered.llmMod?.name, 'Discord Mod');
      expect(gathered.aiSentence, 'AI wrote this about Discord Mod.');
      expect(gathered.partOfThreadTitle, isNull);
    });

    test('a rules-only entry gets no AI answer, even with a main mod', () {
      final forum = _thread(9035, 'Red thread', [_threadMod('Red')]);
      final entry = _entry(
        'Red',
        sourcePosts: [
          _post(
            CatalogSourceKind.forum,
            '9035',
            null,
            foundBy: CatalogFoundBy.rules,
          ),
        ],
      );

      expect(llmModForEntry(entry, forumIndex: forum[9035]), isNull);
    });
  });
}
