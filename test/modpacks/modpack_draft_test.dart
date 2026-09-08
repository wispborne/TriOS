import 'package:flutter_test/flutter_test.dart';
import 'package:trios/modpacks/models/modpack_definition.dart';
import 'package:trios/modpacks/models/modpack_draft.dart';
import 'package:trios/modpacks/modpack_format.dart';

ModpackDraftItem _item(String modId) => ModpackDraftItem(
  modId: modId,
  url: 'https://example.com/$modId.version',
  sourceType: ModpackItemSourceType.versionFile,
);

ModpackDraft _draft({
  String name = 'My pack',
  List<ModpackDraftItem>? items,
  String? homepageUrl,
  String? updateUrl,
}) => ModpackDraft(
  id: 'N3qGd6c8R2mVx1ZaYkW0_A',
  name: name,
  homepageUrl: homepageUrl,
  updateUrl: updateUrl,
  items: items ?? [_item('alpha_mod')],
);

Set<ModpackDraftProblem> _problems(ModpackDraft draft) =>
    draft.issues.map((issue) => issue.problem).toSet();

void main() {
  group('a finished draft', () {
    test('has no problems and can be saved', () {
      final draft = _draft();

      expect(draft.issues, isEmpty);
      expect(draft.isCommittable, isTrue);
    });

    test('becomes a definition at the version it is given', () {
      final definition = _draft().toDefinition(version: 4);

      expect(definition.id, 'N3qGd6c8R2mVx1ZaYkW0_A');
      expect(definition.version, 4);
      expect(definition.formatVersion, ModpackDefinition.currentFormatVersion);
      expect(definition.items.single.modId, 'alpha_mod');
    });

    test('trims text and drops blank optional fields', () {
      final definition = _draft(name: '  Spaced out  ')
          .copyWith(author: '   ', description: '  A note  ')
          .toDefinition(version: 1);

      expect(definition.name, 'Spaced out');
      expect(definition.author, isNull);
      expect(definition.description, 'A note');
    });

    test('gives standard labels their standard spelling', () {
      final definition = _draft(
        items: [_item('alpha_mod').copyWith(label: '  core ')],
      ).toDefinition(version: 1);

      expect(definition.items.single.label, ModpackItemLabels.core);
    });

    test('produces a definition the strict reader accepts', () {
      final definition = _draft(
        items: [
          _item('alpha_mod').copyWith(note: 'Read me.\nThen install.'),
          _item('beta_mod'),
        ],
      ).toDefinition(version: 2);

      // Encoding and reading it back is the same path a share link takes.
      expect(
        () => decodeModpackDefinition(
          Map<String, Object?>.from(canonicalModpackMap(definition)),
        ),
        returnsNormally,
      );
    });
  });

  group('an unfinished draft', () {
    test('is kept but cannot be saved', () {
      final draft = _draft(name: '   ', items: const []);

      expect(draft.isCommittable, isFalse);
      expect(
        _problems(draft),
        containsAll([
          ModpackDraftProblem.packNameMissing,
          ModpackDraftProblem.noItems,
        ]),
      );
      expect(() => draft.toDefinition(version: 1), throwsStateError);
    });

    test('reports which item needs work', () {
      final draft = _draft(
        items: [
          _item('alpha_mod'),
          const ModpackDraftItem(modId: 'beta_mod'),
        ],
      );

      final issues = draft.issues;
      expect(issues.map((issue) => issue.itemIndex), everyElement(1));
      expect(
        _problems(draft),
        containsAll([
          ModpackDraftProblem.itemUrlMissing,
          ModpackDraftProblem.itemSourceTypeMissing,
        ]),
      );
      expect(draft.incompleteItemIndices, [1]);
    });

    test('reports an unsafe item address', () {
      final draft = _draft(
        items: [_item('alpha_mod').copyWith(url: 'ftp://example.com/mod.zip')],
      );

      expect(_problems(draft), contains(ModpackDraftProblem.itemUrlInvalid));
    });

    test('reports the same mod twice', () {
      final draft = _draft(items: [_item('alpha_mod'), _item('alpha_mod')]);

      expect(_problems(draft), contains(ModpackDraftProblem.duplicateModId));
      expect(draft.issues.last.itemIndex, 1);
    });

    test('reports bad pack addresses', () {
      expect(
        _problems(_draft(homepageUrl: 'not a url')),
        contains(ModpackDraftProblem.homepageUrlInvalid),
      );
      expect(
        _problems(_draft(updateUrl: 'file:///C:/pack.trios-modpack')),
        contains(ModpackDraftProblem.updateUrlInvalid),
      );
    });

    test('reports a label or note that is too long', () {
      expect(
        _problems(
          _draft(
            items: [
              _item('alpha_mod')
                  .copyWith(label: 'x' * (ModpackLimits.maxLabelLength + 1)),
            ],
          ),
        ),
        contains(ModpackDraftProblem.itemLabelInvalid),
      );
      expect(
        _problems(
          _draft(
            items: [
              _item('alpha_mod')
                  .copyWith(note: 'x' * (ModpackLimits.maxNoteLength + 1)),
            ],
          ),
        ),
        contains(ModpackDraftProblem.itemNoteTooLong),
      );
    });

    test('counts as empty only when nothing has been typed', () {
      expect(const ModpackDraft(id: 'N3qGd6c8R2mVx1ZaYkW0_A').isEmpty, isTrue);
      expect(_draft(name: '  ', items: const []).isEmpty, isTrue);
      expect(_draft(name: 'Named').isEmpty, isFalse);
    });
  });

  group('starting from a saved pack', () {
    test('copies every field, including unknown ones', () {
      const definition = ModpackDefinition(
        id: 'N3qGd6c8R2mVx1ZaYkW0_A',
        name: 'Saved pack',
        version: 6,
        author: 'Wisp',
        gameVersion: '0.98a-RC8',
        updateUrl: 'https://example.com/pack.trios-modpack',
        items: [
          ModpackItem(
            modId: 'alpha_mod',
            url: 'https://example.com/alpha.version',
            sourceType: ModpackItemSourceType.versionFile,
            label: 'Core',
            note: 'First.',
          ),
        ],
        unknownFields: {'futureField': 'kept'},
      );

      final draft = ModpackDraft.fromDefinition(definition);

      expect(draft.id, definition.id);
      expect(draft.name, 'Saved pack');
      expect(draft.author, 'Wisp');
      expect(draft.updateUrl, definition.updateUrl);
      expect(draft.unknownFields['futureField'], 'kept');
      expect(draft.items.single.label, 'Core');
      expect(draft.isCommittable, isTrue);

      // Saving it again with the same version gives back the same pack.
      expect(
        modpackDefinitionsAreIdentical(
          draft.toDefinition(version: definition.version),
          definition,
        ),
        isTrue,
      );
    });
  });
}
