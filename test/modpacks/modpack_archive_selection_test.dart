import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/mod_manager/batch_installation/batch_installation.dart';
import 'package:trios/mod_manager/mod_install_source.dart';
import 'package:trios/models/mod_info.dart';
import 'package:trios/modpacks/installation/modpack_recovery.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';

void main() {
  final scan = ScannedArchive(
    modInfo: ModInfo(id: 'wanted'),
    fileCount: 3,
    allModInfos: [
      for (final id in ['wanted', 'optional', 'extra'])
        (
          modInfo: ModInfo(id: id),
          extractedFile: SourcedFile(
            File('$id/mod_info.json'),
            File('temp/$id/mod_info.json'),
            '$id/mod_info.json',
          ),
        ),
    ],
  );
  test(
    'only checked declared IDs are selected, including in multi-mod archives',
    () {
      expect(scan.selectDeclaredIds({'wanted'}).map((m) => m.modInfo.id), [
        'wanted',
      ]);
      expect(scan.selectDeclaredIds({}), isEmpty);
    },
  );
  test(
    'a missing or wrong-case ID fails instead of installing a different mod',
    () {
      expect(
        () => scan.selectDeclaredIds({'wanted', 'absent'}),
        throwsStateError,
      );
      expect(() => scan.selectDeclaredIds({'Wanted'}), throwsStateError);
    },
  );
  test('catalog clues precede exact and likely names', () {
    const item = ModpackItem(
      modId: 'id',
      name: 'Magic Ships',
      sourceType: ModpackItemSourceType.directDownload,
      url: 'https://example.org/a.zip',
      catalog: ModpackCatalogClues(name: 'Known entry'),
    );
    expect(modpackRecoveryRank(item, ModRepoEntry(name: 'Known entry')), 0);
    expect(modpackRecoveryRank(item, ModRepoEntry(name: 'Magic Ships')), 1);
    expect(
      modpackRecoveryRank(item, ModRepoEntry(name: 'Magic Ships Expansion')),
      2,
    );
    expect(modpackRecoveryRank(item, ModRepoEntry(name: 'Unrelated')), isNull);
  });
}
