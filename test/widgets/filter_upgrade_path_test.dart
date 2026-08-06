import 'package:flutter_test/flutter_test.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';

class _Ship {
  final String id;
  final bool isModule;

  _Ship(this.id, {this.isModule = false});
}

/// The Ship Viewer's general filters as 1.7.0 builds them. 1.6.x had a
/// "hideModules" field here instead of "showModuleShips", so anyone who saved
/// their ship filters before upgrading has a key that no longer exists.
///
/// "showModuleShips" is copied from the real thing, odd defaults and all: it
/// starts unticked, and unticked is what hides module ships, so its default is
/// the ticked (unfiltered) state.
CompositeFilterGroup<_Ship> _generalFilters() => CompositeFilterGroup<_Ship>(
  id: 'general',
  name: 'General',
  fields: [
    BoolField<_Ship>(
      id: 'showModuleShips',
      label: 'Show Ships That Are Modules',
      predicate: (_) => true,
      defaultValue: true,
      initialValue: false,
    ),
    BoolField<_Ship>(
      id: 'hasModules',
      label: 'Has Modules',
      predicate: (ship) => !ship.isModule,
    ),
  ],
);

bool _valueOf(CompositeFilterGroup<_Ship> group, String fieldId) =>
    (group.fieldById(fieldId) as BoolField<_Ship>).value;

void main() {
  group('ship filters saved by an older version', () {
    test('a field that no longer exists is ignored, not a crash', () {
      final group = _generalFilters();

      expect(
        () => group.restore({'hideModules': true, 'hasModules': true}),
        returnsNormally,
      );
    });

    test('the fields that do still exist are restored', () {
      final group = _generalFilters()
        ..restore({'hideModules': true, 'hasModules': true});

      expect(_valueOf(group, 'hasModules'), isTrue);
    });

    test('an old "Hide Modules" does not touch "Show Ships That Are Modules"',
        () {
      final group = _generalFilters()..restore({'hideModules': true});

      expect(
        _valueOf(group, 'showModuleShips'),
        isFalse,
        reason: 'the new field keeps its own starting value',
      );
    });

    test('a saved "Show Ships That Are Modules" is restored', () {
      final group = _generalFilters()..restore({'showModuleShips': true});

      expect(_valueOf(group, 'showModuleShips'), isTrue);
    });

    test('nothing saved at all is fine', () {
      final group = _generalFilters();

      expect(() => group.restore(const {}), returnsNormally);
      expect(_valueOf(group, 'hasModules'), isFalse);
    });

    test('a saved value of the wrong type falls back to the default', () {
      final group = _generalFilters()
        ..restore({'showModuleShips': 'yes please', 'hasModules': 3});

      expect(_valueOf(group, 'showModuleShips'), isTrue);
      expect(_valueOf(group, 'hasModules'), isFalse);
    });

    test('what gets written back out has only current fields', () {
      final group = _generalFilters()
        ..restore({'hideModules': true, 'hasModules': true});

      expect(group.serialize().keys, ['showModuleShips', 'hasModules']);
    });

    test('clearing the filters brings module ships back', () {
      final group = _generalFilters()..clear();

      expect(_valueOf(group, 'showModuleShips'), isTrue);
      expect(group.isActive, isFalse);
    });

    test('hiding module ships counts as a filter being on', () {
      final group = _generalFilters();

      expect(
        group.isActive,
        isTrue,
        reason: 'unticked is the filtered state, so the count must show it',
      );
    });
  });
}
