import 'package:flutter_test/flutter_test.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';

/// Small stand-in for a ship: a few weapon slots and one number.
class _Item {
  final String name;
  final List<String> slots;
  final num? points;

  _Item(this.name, {this.slots = const [], this.points});
}

ChipFilterGroup<_Item> _slotsGroup() => ChipFilterGroup<_Item>(
  id: 'slots',
  name: 'Weapon Slots',
  valueGetter: (_) => '',
  valuesGetter: (item) => item.slots,
);

RangeFilterGroup<_Item> _pointsGroup({bool allowGreater = true}) =>
    RangeFilterGroup<_Item>(
      id: 'points',
      name: 'Deployment Points',
      valueGetter: (item) => item.points,
      allowGreater: allowGreater,
    );

void main() {
  final ballisticAndMissile = _Item('a', slots: ['BALLISTIC', 'MISSILE']);
  final ballisticOnly = _Item('b', slots: ['BALLISTIC']);
  final missileOnly = _Item('c', slots: ['MISSILE']);
  final energyOnly = _Item('d', slots: ['ENERGY']);

  group('Chip group logic mode', () {
    test('"any" matches items with at least one included value', () {
      final g = _slotsGroup();
      g.setSelections({'BALLISTIC': true, 'MISSILE': true});

      expect(g.logicMode, ChipLogicMode.any);
      expect(g.matches(ballisticAndMissile), isTrue);
      expect(g.matches(ballisticOnly), isTrue);
      expect(g.matches(missileOnly), isTrue);
      expect(g.matches(energyOnly), isFalse);
    });

    test('"all" matches only items with every included value', () {
      final g = _slotsGroup();
      g.logicMode = ChipLogicMode.all;
      g.setSelections({'BALLISTIC': true, 'MISSILE': true});

      expect(g.matches(ballisticAndMissile), isTrue);
      expect(g.matches(ballisticOnly), isFalse);
      expect(g.matches(missileOnly), isFalse);
      expect(g.matches(energyOnly), isFalse);
    });

    test('excluded values still veto in "all" mode', () {
      final g = _slotsGroup();
      g.logicMode = ChipLogicMode.all;
      g.setSelections({'BALLISTIC': true, 'MISSILE': false});

      expect(g.matches(ballisticAndMissile), isFalse);
      expect(g.matches(ballisticOnly), isTrue);
    });

    test('saves and reloads the logic mode', () {
      final saved = _slotsGroup();
      saved.logicMode = ChipLogicMode.all;
      saved.setSelections({'BALLISTIC': true});

      final restored = _slotsGroup();
      restored.restore(saved.serialize());

      expect(restored.logicMode, ChipLogicMode.all);
      expect(restored.filterStates, {'BALLISTIC': true});
    });

    test('the default mode is not written out, and unknown modes fall back', () {
      final g = _slotsGroup();
      g.setSelections({'BALLISTIC': true});
      expect(g.serialize().containsKey(ChipFilterGroup.logicKey), isFalse);

      final restored = _slotsGroup();
      restored.restore({'BALLISTIC': true, ChipFilterGroup.logicKey: 'wat'});
      expect(restored.logicMode, ChipLogicMode.any);
      expect(restored.filterStates, {'BALLISTIC': true});
    });

    test('"all" ignores picks the data no longer has', () {
      // What you'd have after picking a slot from a mod, then turning it off:
      // the pick stays, but no chip for it is on screen any more.
      final g = _slotsGroup();
      g.logicMode = ChipLogicMode.all;
      g.setSelections({'BALLISTIC': true, 'FROM_A_MOD_THATS_OFF': true});
      g.updateKnownValues([ballisticAndMissile, ballisticOnly, energyOnly]);

      expect(g.matches(ballisticOnly), isTrue);
      expect(g.matches(energyOnly), isFalse);
    });

    test('clearing the group also resets the logic mode', () {
      final g = _slotsGroup();
      g.logicMode = ChipLogicMode.all;
      g.setSelections({'BALLISTIC': true});

      g.clear();

      expect(g.logicMode, ChipLogicMode.any);
      expect(g.filterStates, isEmpty);
    });
  });

  group('Range group', () {
    final items = [
      _Item('frigate', points: 5),
      _Item('destroyer', points: 10),
      _Item('cruiser', points: 20),
      _Item('capital', points: 60),
    ];

    test('reads its range from the data and starts off', () {
      final g = _pointsGroup()..updateRange(items);

      expect(g.min, 5);
      expect(g.max, 60);
      expect(g.isActive, isFalse);
      expect(items.every(g.matches), isTrue);
    });

    test('keeps only items inside the chosen range', () {
      final g = _pointsGroup()..updateRange(items);
      g.setRange(10, 20);

      expect(g.isActive, isTrue);
      expect(g.matches(items[0]), isFalse);
      expect(g.matches(items[1]), isTrue);
      expect(g.matches(items[2]), isTrue);
      expect(g.matches(items[3]), isFalse);
    });

    test('items with no value are dropped while the filter is on', () {
      final noValue = _Item('unknown');
      final g = _pointsGroup()..updateRange(items);

      expect(g.matches(noValue), isTrue);
      g.setRange(10, 20);
      expect(g.matches(noValue), isFalse);
    });

    test('the top handle means "and above"', () {
      final g = _pointsGroup()..updateRange(items);
      g.setRange(20, 60);

      // Something bigger than anything in the data still gets through.
      expect(g.matches(_Item('supercapital', points: 200)), isTrue);
    });

    test('without "and above", the top of the slider is a hard stop', () {
      final g = _pointsGroup(allowGreater: false)..updateRange(items);
      g.setRange(20, 60);

      expect(g.matches(_Item('supercapital', points: 200)), isFalse);
    });

    test('handles at either end stay there when new data arrives', () {
      final g = _pointsGroup()..updateRange(items);
      g.updateRange([...items, _Item('titan', points: 100)]);

      expect(g.max, 100);
      expect(g.curMax, 100);
      expect(g.isActive, isFalse);
    });

    test('a chosen range is kept, and clamped, when new data arrives', () {
      final g = _pointsGroup()..updateRange(items);
      g.setRange(10, 20);
      g.updateRange([_Item('frigate', points: 5), _Item('destroyer', points: 15)]);

      expect(g.curMin, 10);
      expect(g.curMax, 15);
    });

    test('saves and reloads the chosen range', () {
      final saved = _pointsGroup()..updateRange(items);
      saved.setRange(10, 20);

      final restored = _pointsGroup()..updateRange(items);
      restored.restore(saved.serialize());

      expect(restored.curMin, 10);
      expect(restored.curMax, 20);
      expect(restored.isActive, isTrue);
    });

    test('a range read from settings waits for the data to load', () {
      final restored = _pointsGroup();
      restored.restore({'min': 10, 'max': 20});
      expect(restored.isActive, isFalse, reason: 'no data yet');

      restored.updateRange(items);

      expect(restored.curMin, 10);
      expect(restored.curMax, 20);
      expect(restored.isActive, isTrue);
    });

    test('handles snap to numbers that exist in the data', () {
      final g = _pointsGroup()..updateRange(items);

      expect(g.snapTo(11), 10);
      expect(g.snapTo(18.4), 20);
      expect(g.snapTo(1000), 60);
    });

    test('every value in the data gets its own notch, evenly spaced', () {
      final g = _pointsGroup()..updateRange(items);

      // 5, 10, 20, 60 — four values, four notches, however lopsided they are.
      expect(g.stops, [5, 10, 20, 60]);
      expect(g.stopIndexFor(5), 0);
      expect(g.stopIndexFor(10), 1);
      expect(g.stopIndexFor(20), 2);
      expect(g.stopIndexFor(60), 3);
    });

    test('a position between notches picks the nearer one', () {
      final g = _pointsGroup()..updateRange(items);

      expect(g.stopIndexFor(6), 0);
      expect(g.stopIndexFor(9), 1);
      expect(g.stopIndexFor(14), 1);
      expect(g.stopIndexFor(17), 2);
      expect(g.stopIndexFor(-100), 0);
      expect(g.stopIndexFor(9999), 3);
    });

    test('one runaway value does not squash the rest of the track', () {
      // Hull points in vanilla: most ships are in the thousands, and one
      // entry is ten million.
      final g = _pointsGroup()
        ..updateRange([
          _Item('a', points: 1000),
          _Item('b', points: 5000),
          _Item('c', points: 20000),
          _Item('drone', points: 10000000),
        ]);

      // The giant is just the last notch; the real ships keep three quarters
      // of the track between them.
      expect(g.stops.length, 4);
      expect(g.stopIndexFor(20000), 2);
    });

    test('the range resets to the full span', () {
      final g = _pointsGroup()..updateRange(items);
      g.setRange(10, 20);

      g.clear();

      expect(g.curMin, 5);
      expect(g.curMax, 60);
      expect(g.isActive, isFalse);
    });
  });

  group('Filter scope controller', () {
    test('applies range groups, and "clear all" resets them', () {
      final points = _pointsGroup();
      final controller = FilterScopeController<_Item>(
        scope: const FilterScope('test'),
        groups: [points],
        persistenceEnabled: false,
      );
      final items = [
        _Item('a', points: 5),
        _Item('b', points: 20),
        _Item('c', points: 60),
      ];

      controller.updateRanges(items);
      points.setRange(10, 30);
      expect(controller.applyRangeFilters(items).map((i) => i.name), ['b']);
      expect(controller.activeCount, 1);

      controller.clearAll();
      expect(controller.applyRangeFilters(items).length, 3);
      expect(controller.activeCount, 0);
    });
  });
}
