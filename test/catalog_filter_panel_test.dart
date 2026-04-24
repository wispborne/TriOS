import 'package:flutter_test/flutter_test.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';

/// Minimal `ScrapedMod` stand-in: the catalog filter groups only need the
/// attribute-key list and a version string, so we avoid pulling in the real
/// class (which has heavy transitive deps).
class _TestMod {
  final String name;
  final List<String> attributes;
  final String? gameVersionReq;
  final List<String> categories;

  _TestMod({
    required this.name,
    this.attributes = const [],
    this.gameVersionReq,
    this.categories = const [],
  });
}

void main() {
  group('Attributes ChipFilterGroup (Catalog)', () {
    ChipFilterGroup<_TestMod> makeAttributes() {
      return ChipFilterGroup<_TestMod>(
        id: 'attributes',
        name: 'Attributes',
        valueGetter: (_) => '',
        valuesGetter: (m) => m.attributes,
      );
    }

    final modWithDownload = _TestMod(
      name: 'A',
      attributes: ['download'],
    );
    final modWithDiscord = _TestMod(
      name: 'B',
      attributes: ['discord'],
    );
    final modInstalled = _TestMod(
      name: 'C',
      attributes: ['installed', 'update'],
    );
    final modArchived = _TestMod(
      name: 'D',
      attributes: ['archived'],
    );

    test('include-only: "download" includes only download mods', () {
      final g = makeAttributes();
      g.setSelections({'download': true});
      expect(g.matches(modWithDownload), isTrue);
      expect(g.matches(modWithDiscord), isFalse);
      expect(g.matches(modInstalled), isFalse);
    });

    test('exclude-only: "discord" excludes discord mods and keeps the rest',
        () {
      final g = makeAttributes();
      g.setSelections({'discord': false});
      expect(g.matches(modWithDownload), isTrue);
      expect(g.matches(modWithDiscord), isFalse);
      expect(g.matches(modInstalled), isTrue);
    });

    test('combined include + exclude', () {
      final g = makeAttributes();
      g.setSelections({'installed': true, 'archived': false});
      expect(g.matches(modInstalled), isTrue);
      expect(g.matches(modArchived), isFalse);
      expect(g.matches(modWithDownload), isFalse);
    });

    test('empty selection passes all mods through', () {
      final g = makeAttributes();
      expect(g.matches(modWithDownload), isTrue);
      expect(g.matches(modWithDiscord), isTrue);
      expect(g.isActive, isFalse);
      expect(g.activeCount, 0);
    });

    test('clear() resets selections', () {
      final g = makeAttributes();
      g.setSelections({'download': true, 'discord': false});
      expect(g.isActive, isTrue);
      g.clear();
      expect(g.isActive, isFalse);
      expect(g.filterStates, isEmpty);
    });
  });

  group('Version CompositeFilterGroup (Catalog)', () {
    final mod097 = _TestMod(name: 'X', gameVersionReq: '0.97a-RC11');
    final mod098 = _TestMod(name: 'Y', gameVersionReq: '0.98a');
    final modNoVersion = _TestMod(name: 'Z', gameVersionReq: null);

    /// Mirrors the bucketing shape the controller uses: bucket label → raw
    /// versions.
    final versionGroupOptions = <String, Set<String>>{
      '0.98': {'0.98a'},
      '0.97': {'0.97a-RC11', '0.97a'},
    };

    CompositeFilterGroup<_TestMod> makeVersion() {
      return CompositeFilterGroup<_TestMod>(
        id: 'version',
        name: 'Game Version',
        fields: [
          StringChoiceField<_TestMod>(
            id: 'versionBucket',
            label: 'Game Version',
            options: versionGroupOptions.keys.toList(),
            allLabel: 'All Versions',
            predicate: (mod, selected) {
              if (selected == null) return true;
              final bucket = versionGroupOptions[selected];
              if (bucket == null) return false;
              return mod.gameVersionReq != null &&
                  bucket.contains(mod.gameVersionReq);
            },
          ),
        ],
      );
    }

    test('default (null selection) matches every mod — "All Versions"', () {
      final g = makeVersion();
      expect(g.isActive, isFalse);
      expect(g.matches(mod097), isTrue);
      expect(g.matches(mod098), isTrue);
      expect(g.matches(modNoVersion), isTrue);
    });

    test('selecting "0.97" restricts to raw versions in that bucket', () {
      final g = makeVersion();
      final field = g.fieldById('versionBucket') as StringChoiceField<_TestMod>;
      field.setSelected('0.97');
      expect(g.isActive, isTrue);
      expect(g.matches(mod097), isTrue);
      expect(g.matches(mod098), isFalse);
      expect(g.matches(modNoVersion), isFalse);
    });

    test('serialize/restore roundtrips the selection', () {
      final g = makeVersion();
      final field = g.fieldById('versionBucket') as StringChoiceField<_TestMod>;
      field.setSelected('0.97');
      final serialized = g.serialize();
      expect(serialized['versionBucket'], '0.97');

      final g2 = makeVersion();
      g2.restore(serialized);
      final restored = g2.fieldById('versionBucket') as StringChoiceField<_TestMod>;
      expect(restored.selected, '0.97');
    });

    test('restore ignores unknown selections', () {
      final g = makeVersion();
      g.restore({'versionBucket': 'does-not-exist'});
      final field = g.fieldById('versionBucket') as StringChoiceField<_TestMod>;
      expect(field.selected, isNull);
    });

    test('clear() resets to default', () {
      final g = makeVersion();
      final field = g.fieldById('versionBucket') as StringChoiceField<_TestMod>;
      field.setSelected('0.97');
      expect(g.isActive, isTrue);
      g.clear();
      expect(g.isActive, isFalse);
      expect(field.selected, isNull);
    });
  });

  group('FilterScopeController.clearAll (Catalog shape)', () {
    test('clears every group in the catalog-style scope', () {
      final attributes = ChipFilterGroup<_TestMod>(
        id: 'attributes',
        name: 'Attributes',
        valueGetter: (_) => '',
        valuesGetter: (m) => m.attributes,
      );
      final category = ChipFilterGroup<_TestMod>(
        id: 'category',
        name: 'Category',
        valueGetter: (_) => '',
        valuesGetter: (m) => m.categories,
      );
      final version = CompositeFilterGroup<_TestMod>(
        id: 'version',
        name: 'Game Version',
        fields: [
          StringChoiceField<_TestMod>(
            id: 'versionBucket',
            label: 'Game Version',
            options: ['0.97', '0.98'],
            allLabel: 'All Versions',
            predicate: (_, __) => true,
          ),
        ],
      );
      final controller = FilterScopeController<_TestMod>(
        scope: const FilterScope('catalog'),
        groups: [attributes, category, version],
        persistenceEnabled: false,
      );

      attributes.setSelections({'installed': true});
      category.setSelections({'Faction': true});
      (version.fieldById('versionBucket') as StringChoiceField<_TestMod>)
          .setSelected('0.97');

      expect(controller.activeCount, greaterThan(0));

      controller.clearAll();

      expect(controller.activeCount, 0);
      expect(attributes.isActive, isFalse);
      expect(category.isActive, isFalse);
      expect(version.isActive, isFalse);
    });
  });
}
