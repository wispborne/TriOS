import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_records/mod_record.dart';
import 'package:trios/mod_records/mod_record_source.dart';
import 'package:trios/models/mod.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_info_json.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/models/version_checker_info.dart';
import 'package:trios/modpacks/editor/modpack_editor_logic.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';

ModVariant variant(
  String id, {
  String? url,
  List<Dependency> dependencies = const [],
}) => ModVariant(
  modInfo: ModInfo(
    id: id,
    name: id,
    version: Version.parse('1.0'),
    dependencies: dependencies,
  ),
  versionCheckerInfo: VersionCheckerInfo(masterVersionFile: url),
  modFolder: Directory('mods/$id'),
  hasNonBrickedModInfo: true,
  gameCoreFolder: Directory('core'),
);

void main() {
  test(
    'an explicitly saved fixed source wins over Version Checker overrides',
    () {
      final record = ModRecord(
        recordKey: 'alpha',
        modpackSource: const CatalogSource(
          directDownloadUrl: 'https://example.com/chosen.zip',
        ),
        userOverrides: const {
          'versionChecker': VersionCheckerSource(
            masterVersionFileUrl: 'https://example.com/override.version',
          ),
        },
      );
      final item = discoverModpackItem(
        variant('alpha', url: 'https://example.com/mod.version'),
        record,
      );
      expect(item.url, 'https://example.com/chosen.zip');
      expect(item.sourceType, ModpackItemSourceType.directDownload);
      expect(
        ModRecordMapper.fromMap(record.toMap()).modpackSource,
        record.modpackSource,
      );
    },
  );
  test('source discovery follows overrides, local VC, catalog, then download history', () {
    final mod = variant('alpha', url: 'https://example.com/local.version');
    final record = ModRecord(
      recordKey: 'alpha',
      userOverrides: const {
        'versionChecker': VersionCheckerSource(
          masterVersionFileUrl: 'https://example.com/override.version',
        ),
        'catalog': CatalogSource(
          directDownloadUrl: 'https://example.com/override.zip',
        ),
        'downloadHistory': DownloadHistorySource(
          lastDownloadedFrom: 'https://example.com/history-override.zip',
        ),
      },
      sources: const {
        'catalog': CatalogSource(
          name: 'Alpha',
          directDownloadUrl: 'https://example.com/catalog.zip',
          forumThreadId: '123',
        ),
        'downloadHistory': DownloadHistorySource(
          lastDownloadedFrom: 'https://example.com/history.zip',
        ),
      },
    );
    expect(
      discoverModpackItem(mod, record).url,
      'https://example.com/override.version',
    );
    final noVc = record.copyWith(
      userOverrides: Map<String, ModRecordSource>.of(record.userOverrides)
        ..remove('versionChecker'),
    );
    expect(
      discoverModpackItem(mod, noVc).url,
      'https://example.com/override.zip',
    );
    final historyOnly = noVc.copyWith(
      userOverrides: Map<String, ModRecordSource>.of(noVc.userOverrides)
        ..remove('catalog'),
    );
    expect(
      discoverModpackItem(mod, historyOnly).url,
      'https://example.com/history-override.zip',
    );
    final noOverrides = record.copyWith(userOverrides: {});
    expect(
      discoverModpackItem(mod, noOverrides).url,
      'https://example.com/local.version',
    );
    expect(
      discoverModpackItem(variant('alpha'), noOverrides).url,
      'https://example.com/catalog.zip',
    );
    expect(
      discoverModpackItem(
        variant('alpha'),
        noOverrides.copyWith(
          sources: {'downloadHistory': record.sources['downloadHistory']!},
        ),
      ).url,
      'https://example.com/history.zip',
    );
    expect(discoverModpackItem(mod, record).catalog?.forumTopicId, '123');
  });
  test('unsafe or absent sources leave editable incomplete drafts', () {
    final item = discoverModpackItem(
      variant('alpha', url: 'file:///mod.zip'),
      null,
    );
    expect(item.modId, 'alpha');
    expect(item.sourceType, isNull);
    expect(item.isComplete, false);
  });
  test('dependency traversal includes transitive requirements and terminates cycles', () {
    final a = variant('a', dependencies: [Dependency(id: 'b')]);
    final b = variant(
      'b',
      dependencies: [
        Dependency(id: 'a'),
        Dependency(id: 'c'),
      ],
    );
    final c = variant('c', dependencies: [Dependency(id: 'absent')]);
    final result = findModpackDependencies(
      [const ModpackDraftItem(modId: 'a')],
      [
        for (final v in [a, b, c])
          Mod(id: v.modInfo.id, isEnabledInGame: false, modVariants: [v]),
      ],
    );
    expect(result.available.map((v) => v.modInfo.id), ['b', 'c']);
    expect(result.warnings.any((w) => w.contains('absent')), true);
  });
  test('bulk reorder retains relative order and uses full list positions when filtered', () {
    expect(moveModpackItems(['a', 'b', 'c', 'd', 'e'], {1, 3}, 0), [
      'b',
      'd',
      'a',
      'c',
      'e',
    ]);
    expect(moveModpackItems(['a', 'b', 'c', 'd', 'e'], {0, 2}, 5), [
      'b',
      'd',
      'e',
      'a',
      'c',
    ]);
    expect(moveModpackItems(['a', 'b', 'c'], {1}, 1), ['a', 'b', 'c']);
  });
  test('labels reject controls, preserve custom case, and normalize standard values', () {
    expect(modpackLabelError('   '), isNotNull);
    expect(modpackLabelError('a\tb'), isNotNull);
    expect(modpackLabelError('a\nb'), isNotNull);
    expect(modpackLabelError('a' * 41), isNotNull);
    expect(modpackLabelError(' My Label '), isNull);
    expect(ModpackItemLabels.normalize(' cOrE '), 'Core');
    expect(ModpackItemLabels.normalize(' My Label '), 'My Label');
  });
}
