import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_links.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_record_source.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';

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

CatalogMod _entry(
  String name, {
  String? forumUrl,
  String? nexusUrl,
  String? partOfThreadTitle,
}) {
  final urls = <ModUrlType, String>{};
  if (forumUrl != null) urls[ModUrlType.Forum] = forumUrl;
  if (nexusUrl != null) urls[ModUrlType.NexusMods] = nexusUrl;
  return CatalogMod(
    name: name,
    urls: urls.isEmpty ? null : urls,
    partOfThreadTitle: partOfThreadTitle,
  );
}

ModRecords _recordsLinking(String catalogName, String modId) => ModRecords(
  records: {
    modId: ModRecord(
      recordKey: modId,
      modId: modId,
      sources: {'catalog': CatalogSource(name: catalogName)},
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
      'an add-on sharing the parent thread id does not steal the parent match',
      () {
        const forumUrl =
            'https://fractalsoftworks.com/forum/index.php?topic=123.0';
        final parentEntry = _entry('Parent Mod', forumUrl: forumUrl);
        // Add-on carries the same thread URL but is marked part-of-thread.
        final addonEntry = _entry(
          'Addon',
          forumUrl: forumUrl,
          partOfThreadTitle: 'Parent Thread',
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
}
