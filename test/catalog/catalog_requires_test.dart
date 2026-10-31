import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_requires.dart';
import 'package:trios/catalog/models/catalog_extras.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/models/forum_llm_data.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';

CatalogMod _mod(
  String id, {
  List<CatalogNeed>? needs,
  List<String>? aiNeeds,
  bool hasAiAnswer = false,
  String? title,
}) => CatalogMod(
  entry: ModRepoEntry(id: id, name: title ?? id),
  title: title ?? id,
  authors: '',
  llmMod: aiNeeds != null || hasAiAnswer
      ? ForumLlmMod(
          name: id,
          extras: ForumLlmExtras(needs: aiNeeds),
        )
      : null,
  extras: needs != null ? CatalogExtras(needs: needs) : null,
);

void main() {
  group('requiresChipKeys', () {
    test('a required mod with a catalog id uses the id', () {
      final mod = _mod(
        'a',
        needs: [CatalogNeed(name: 'LazyLib', id: 'lazylib')],
      );
      expect(requiresChipKeys(mod), ['lazylib']);
    });

    test('a required mod with no id uses its name, simplified', () {
      final mod = _mod('a', aiNeeds: ['Graphics Lib!']);
      expect(requiresChipKeys(mod), ['graphicslib']);
    });

    test('spelling variants share a key', () {
      expect(
        requiresChipKeys(_mod('a', aiNeeds: ['LazyLib'])),
        requiresChipKeys(_mod('b', aiNeeds: ['Lazy Lib'])),
      );
    });

    test('a mod with an answer and no required mods is Standalone', () {
      expect(requiresChipKeys(_mod('a', needs: [])), [kRequiresStandalone]);
      expect(requiresChipKeys(_mod('b', hasAiAnswer: true)), [
        kRequiresStandalone,
      ]);
    });

    test('a mod with no answer has no Requires value', () {
      expect(requiresChipKeys(_mod('a')), isEmpty);
    });

    test('the same mod listed twice gives one key', () {
      final mod = _mod('a', aiNeeds: ['LazyLib', 'Lazy Lib']);
      expect(requiresChipKeys(mod), ['lazylib']);
    });

    test('version text and decoration are dropped from names', () {
      final mod = _mod('a', aiNeeds: ['[0.98a] LazyLib v2.8']);
      expect(requiresChipKeys(mod), ['lazylib']);
    });

    test('a name with no English letters keeps a key', () {
      expect(requiresChipKeys(_mod('a', aiNeeds: ['星际'])), ['星际']);
    });

    test('a name that one catalog mod uses gets that mod\'s id', () {
      final ids = catalogIdsByNameKey([
        _mod('lazylib-id', title: 'LazyLib'),
        _mod('shared-1', title: 'Shared'),
        _mod('shared-2', title: 'Shared'),
      ]);
      expect(ids, {'lazylib': 'lazylib-id'});
      final mod = _mod('a', aiNeeds: ['Lazy Lib', 'Shared']);
      expect(requiresChipKeys(mod, idsByNameKey: ids), [
        'lazylib-id',
        'shared',
      ]);
    });
  });

  group('RequiresChipInfo', () {
    final mods = [
      _mod('lazylib', title: 'LazyLib'),
      _mod(
        'a',
        needs: [CatalogNeed(name: 'Lazy Library', id: 'lazylib')],
      ),
      _mod('b', aiNeeds: ['LazyLib']),
      _mod('c', aiNeeds: ['MagicLib']),
      _mod('d', aiNeeds: ['Magic Lib']),
      _mod('e', aiNeeds: ['MagicLib', 'Nexerelin']),
      _mod('f', needs: []),
    ];
    final info = RequiresChipInfo.from(mods);

    test('an id is labelled with the catalog name', () {
      expect(info.labelFor('lazylib'), 'LazyLib');
    });

    test('a name-only need joins the chip for its catalog id', () {
      expect(info.counts['lazylib'], 2);
      expect(info.keysFor(mods[2]), ['lazylib']);
    });

    test('a name key uses the most common spelling', () {
      expect(info.labelFor('magiclib'), 'MagicLib');
      expect(info.counts['magiclib'], 3);
    });

    test('Standalone comes first, then the most needed, then by label', () {
      final keys = info.counts.keys.toList()..sort(info.compare);
      expect(keys, [kRequiresStandalone, 'magiclib', 'lazylib', 'nexerelin']);
      expect(info.labelFor(kRequiresStandalone), 'Standalone');
    });
  });
}
