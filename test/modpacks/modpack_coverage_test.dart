import 'package:flutter_test/flutter_test.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';
import 'package:trios/modpacks/modpack_coverage.dart';

ModpackItem _item(String modId) => ModpackItem(
  modId: modId,
  url: 'https://example.com/$modId.version',
  sourceType: ModpackItemSourceType.versionFile,
);

ModpackDefinition _definition(
  List<String> modIds, {
  String id = 'N3qGd6c8R2mVx1ZaYkW0_A',
  int version = 1,
}) => ModpackDefinition(
  id: id,
  name: 'Test pack',
  version: version,
  items: modIds.map(_item).toList(),
);

void main() {
  group('installed counts', () {
    test('count any installed variant of a mod ID', () {
      final coverage = calculateModpackCoverage(
        definition: _definition(['alpha', 'beta', 'gamma']),
        installedModIds: {'alpha', 'gamma', 'unrelated_mod'},
      );

      expect(coverage.totalCount, 3);
      expect(coverage.installedCount, 2);
      expect(coverage.missingModIds, ['beta']);
      expect(coverage.isFullyInstalled, isFalse);
    });

    test('report a fully installed pack', () {
      final coverage = calculateModpackCoverage(
        definition: _definition(['alpha', 'beta']),
        installedModIds: {'alpha', 'beta'},
      );

      expect(coverage.isFullyInstalled, isTrue);
      expect(coverage.missingCount, 0);
    });

    test('are case-sensitive, like mod IDs', () {
      final coverage = calculateModpackCoverage(
        definition: _definition(['MagicLib']),
        installedModIds: {'magiclib'},
      );

      expect(coverage.installedCount, 0);
      expect(coverage.missingModIds, ['MagicLib']);
    });

    test('keep pack order in the missing list', () {
      final coverage = calculateModpackCoverage(
        definition: _definition(['zeta', 'alpha', 'mu']),
        installedModIds: {},
      );

      expect(coverage.missingModIds, ['zeta', 'alpha', 'mu']);
    });
  });

  group('drafts', () {
    test('provide the item list for a pack that was never saved', () {
      final draft = ModpackDraft(
        id: 'N3qGd6c8R2mVx1ZaYkW0_A',
        name: 'Draft only',
        items: const [
          ModpackDraftItem(
            modId: 'alpha',
            url: 'https://example.com/alpha.version',
            sourceType: ModpackItemSourceType.versionFile,
          ),
          ModpackDraftItem(modId: 'beta'),
        ],
      );

      final coverage = calculateModpackCoverage(
        draft: draft,
        installedModIds: {'alpha'},
      );

      expect(coverage.totalCount, 2);
      expect(coverage.installedCount, 1);
      expect(coverage.itemsNeedingSources, ['beta']);
      expect(coverage.hasSourceProblems, isTrue);
    });

    test('report unfinished items on a saved pack without recounting them', () {
      final definition = _definition(['alpha']);
      final draft = ModpackDraft.fromDefinition(definition).copyWith(
        items: [
          ModpackDraftItem.fromItem(definition.items.single),
          const ModpackDraftItem(modId: 'newly_added'),
        ],
      );

      final coverage = calculateModpackCoverage(
        definition: definition,
        draft: draft,
        installedModIds: {'alpha'},
      );

      // The saved pack still has one item; the half-typed one is a problem,
      // not an item.
      expect(coverage.totalCount, 1);
      expect(coverage.itemsNeedingSources, ['newly_added']);
    });

    test('report no source problems when every item is finished', () {
      final definition = _definition(['alpha']);
      final coverage = calculateModpackCoverage(
        definition: definition,
        draft: ModpackDraft.fromDefinition(definition),
        installedModIds: {},
      );

      expect(coverage.hasSourceProblems, isFalse);
    });
  });

  group('failures and updates', () {
    test('list items whose last install attempt failed', () {
      final coverage = calculateModpackCoverage(
        definition: _definition(['alpha', 'beta']),
        installedModIds: {'alpha'},
        itemFailures: {
          'beta': ModpackItemFailure(
            modId: 'beta',
            sourceFingerprint: 'versionFile|https://example.com/beta.version',
            message: 'Download failed',
            failedAt: DateTime(2026, 9, 3),
          ),
        },
      );

      expect(coverage.failedModIds, ['beta']);
      expect(coverage.hasFailures, isTrue);
    });

    test('report an available update from the entry', () {
      final entry = ModpackLibraryEntry(
        definition: _definition(['alpha'], version: 2),
        updateCheck: ModpackUpdateCheck(
          onlineDefinition: _definition(['alpha', 'beta'], version: 5),
          succeededAt: DateTime(2026, 9, 3),
        ),
      );

      final coverage = calculateEntryCoverage(
        entry: entry,
        installedModIds: {'alpha'},
      );

      expect(coverage.updateAvailable, isTrue);
      expect(coverage.onlineVersionAvailable, 5);
      // The update's extra item is not counted until the update is accepted.
      expect(coverage.totalCount, 1);
    });

    test('report no update when nothing newer was found', () {
      final coverage = calculateEntryCoverage(
        entry: ModpackLibraryEntry(definition: _definition(['alpha'])),
        installedModIds: {},
      );

      expect(coverage.updateAvailable, isFalse);
    });
  });

  test('an empty pack is not fully installed', () {
    final coverage = calculateModpackCoverage(
      definition: _definition([]),
      installedModIds: {'alpha'},
    );

    expect(coverage.totalCount, 0);
    expect(coverage.isFullyInstalled, isFalse);
  });
}
