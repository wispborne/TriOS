import 'package:flutter_test/flutter_test.dart';
import 'package:trios/modpacks/library/modpack_card_data.dart';
import 'package:trios/modpacks/library/modpacks_page_controller.dart';
import 'package:trios/modpacks/modpack_install_progress.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/modpacks/models/modpack_library_entry.dart';

ModpackItem _item(String modId) => ModpackItem(
  modId: modId,
  url: 'https://example.com/$modId.version',
  sourceType: ModpackItemSourceType.versionFile,
);

ModpackDefinition _definition({
  String id = 'N3qGd6c8R2mVx1ZaYkW0_A',
  String name = 'Wisp\'s pack',
  int version = 3,
  String? author = 'Wisp',
  String? gameVersion = '0.98a-RC8',
  String? updateUrl,
  List<String> modIds = const ['alpha', 'beta', 'gamma'],
}) => ModpackDefinition(
  id: id,
  name: name,
  version: version,
  author: author,
  description: 'The mods I always install.',
  gameVersion: gameVersion,
  homepageUrl: 'https://example.com/pack',
  updateUrl: updateUrl,
  items: [for (final modId in modIds) _item(modId)],
);

ModpackCardData _card(
  String name, {
  String? author,
  int? packVersion,
  String? gameVersion,
  int installedCount = 0,
  bool installing = false,
}) => ModpackCardData(
  packId: name,
  name: name,
  author: author,
  packVersion: packVersion,
  gameVersion: gameVersion,
  installedCount: installedCount,
  installProgress: installing
      ? const ModpackInstallProgress(finishedCount: 1, totalCount: 2)
      : null,
);

List<String> _names(List<ModpackCardData> cards) =>
    cards.map((card) => card.name).toList();

void main() {
  group('building card data', () {
    test('a saved pack is described by its saved definition', () {
      final definition = _definition();
      final data = ModpacksData(
        packs: {definition.id: ModpackLibraryEntry(definition: definition)},
      );

      final cards = buildModpackCardData(
        data,
        installedModIds: {'alpha', 'gamma', 'unrelated'},
      );

      expect(cards.length, 1);
      final card = cards.single;
      expect(card.packId, definition.id);
      expect(card.name, 'Wisp\'s pack');
      expect(card.author, 'Wisp');
      expect(card.packVersion, 3);
      expect(card.gameVersion, '0.98a-RC8');
      expect(card.description, 'The mods I always install.');
      expect(card.homepageUrl, 'https://example.com/pack');
      expect(card.installedCount, 2);
      expect(card.totalCount, 3);
      expect(card.missingCount, 1);
      expect(card.isDraftOnly, isFalse);
      expect(card.hasUnsavedChanges, isFalse);
      expect(card.isFullyInstalled, isFalse);
      expect(card.labels, isEmpty);
    });

    test('a never-saved draft shows as a Draft with no version', () {
      const draft = ModpackDraft(
        id: 'draft_pack_id_00000000',
        name: '  Half done  ',
        author: '',
        items: [
          ModpackDraftItem(
            modId: 'alpha',
            url: 'https://example.com/alpha.version',
            sourceType: ModpackItemSourceType.versionFile,
          ),
          ModpackDraftItem(modId: 'beta'),
        ],
      );
      const data = ModpacksData(drafts: {'draft_pack_id_00000000': draft});

      final card = buildModpackCardData(
        data,
        installedModIds: {'alpha'},
      ).single;

      expect(card.name, 'Half done');
      expect(card.author, isNull);
      expect(card.packVersion, isNull);
      expect(card.isDraftOnly, isTrue);
      expect(card.hasUnsavedChanges, isTrue);
      expect(card.needsSources, isTrue);
      expect(card.installedCount, 1);
      expect(card.totalCount, 2);
      expect(card.labels, [ModpackCardLabel.draft]);
    });

    test('a saved pack with a draft shows Unsaved changes, not Draft', () {
      final definition = _definition();
      final data = ModpacksData(
        packs: {definition.id: ModpackLibraryEntry(definition: definition)},
        drafts: {
          definition.id: ModpackDraft.fromDefinition(definition)
              .copyWith(name: 'Renamed in the editor'),
        },
      );

      final card = buildModpackCardData(data, installedModIds: {}).single;

      // Library actions work on the saved pack, so the card shows its name.
      expect(card.name, 'Wisp\'s pack');
      expect(card.isDraftOnly, isFalse);
      expect(card.hasUnsavedChanges, isTrue);
      expect(card.labels, [ModpackCardLabel.unsavedChanges]);
    });

    test('a failed install and a newer online version add labels', () {
      final definition = _definition();
      final data = ModpacksData(
        packs: {
          definition.id: ModpackLibraryEntry(
            definition: definition,
            itemFailures: {
              'beta': ModpackItemFailure(
                modId: 'beta',
                sourceFingerprint: 'versionFile|https://example.com/beta',
                message: 'Download failed',
                failedAt: DateTime(2026, 1, 1),
              ),
            },
            updateCheck: ModpackUpdateCheck(
              onlineDefinition: definition.copyWith(version: 5),
            ),
          ),
        },
      );

      final card = buildModpackCardData(data, installedModIds: {}).single;

      expect(card.hasFailures, isTrue);
      expect(card.onlineVersionAvailable, 5);
      expect(card.labels, [
        ModpackCardLabel.updateAvailable,
        ModpackCardLabel.failed,
      ]);
    });

    test('an older online version is not an update', () {
      final definition = _definition(version: 3);
      final data = ModpacksData(
        packs: {
          definition.id: ModpackLibraryEntry(
            definition: definition,
            updateCheck: ModpackUpdateCheck(
              onlineDefinition: definition.copyWith(version: 2),
            ),
          ),
        },
      );

      final card = buildModpackCardData(data, installedModIds: {}).single;

      expect(card.updateAvailable, isFalse);
    });

    test('a running installation is shown on its card', () {
      final definition = _definition();
      final data = ModpacksData(
        packs: {definition.id: ModpackLibraryEntry(definition: definition)},
      );

      final card = buildModpackCardData(
        data,
        installedModIds: {},
        installations: {
          definition.id: const ModpackInstallProgress(
            finishedCount: 1,
            totalCount: 3,
          ),
        },
      ).single;

      expect(card.isInstalling, isTrue);
      expect(card.installProgress!.fraction, closeTo(1 / 3, 0.001));
      expect(card.labels, [ModpackCardLabel.installing]);
    });

    test('every saved pack and every draft-only pack gets a card', () {
      final saved = _definition(id: 'saved_pack_id_00000000');
      final data = ModpacksData(
        packs: {saved.id: ModpackLibraryEntry(definition: saved)},
        drafts: {
          saved.id: ModpackDraft.fromDefinition(saved),
          'draft_pack_id_00000000': const ModpackDraft(
            id: 'draft_pack_id_00000000',
            name: 'New pack',
          ),
        },
      );

      final cards = buildModpackCardData(data, installedModIds: {});

      expect(cards.map((card) => card.packId).toSet(), {
        saved.id,
        'draft_pack_id_00000000',
      });
    });
  });

  group('sorting cards', () {
    test('name ascending ignores case', () {
      final sorted = ModpacksPageController.sortCards(
        [_card('beta'), _card('Alpha'), _card('gamma')],
        ModpackSortField.name,
        true,
      );

      expect(_names(sorted), ['Alpha', 'beta', 'gamma']);
    });

    test('descending reverses the field order', () {
      final sorted = ModpacksPageController.sortCards(
        [
          _card('one', installedCount: 1),
          _card('three', installedCount: 3),
          _card('two', installedCount: 2),
        ],
        ModpackSortField.installedCount,
        false,
      );

      expect(_names(sorted), ['three', 'two', 'one']);
    });

    test('packs with no value for the field go last either way', () {
      final cards = [
        _card('no author'),
        _card('by zed', author: 'Zed'),
        _card('by amy', author: 'Amy'),
      ];

      expect(
        _names(
          ModpacksPageController.sortCards(
            cards,
            ModpackSortField.author,
            true,
          ),
        ),
        ['by amy', 'by zed', 'no author'],
      );
      expect(
        _names(
          ModpacksPageController.sortCards(
            cards,
            ModpackSortField.author,
            false,
          ),
        ),
        ['by zed', 'by amy', 'no author'],
      );
    });

    test('ties are broken by name', () {
      final sorted = ModpacksPageController.sortCards(
        [_card('zeta', packVersion: 1), _card('alpha', packVersion: 1)],
        ModpackSortField.packVersion,
        true,
      );

      expect(_names(sorted), ['alpha', 'zeta']);
    });

    test('a pack being installed comes first whatever the sort', () {
      final sorted = ModpacksPageController.sortCards(
        [_card('alpha'), _card('zeta', installing: true), _card('beta')],
        ModpackSortField.name,
        true,
      );

      expect(_names(sorted), ['zeta', 'alpha', 'beta']);
    });
  });
}
