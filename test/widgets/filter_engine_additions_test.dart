import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/widgets/filter_engine/filter_engine.dart';

/// Stand-in item: chip values, plus the values it said no to.
class _Item {
  final String name;
  final List<String> values;
  final List<String> saidNo;

  _Item(this.name, {this.values = const [], this.saidNo = const []});
}

ChipFilterGroup<_Item> _group({bool withExplicitNo = true}) =>
    ChipFilterGroup<_Item>(
      id: 'attributes',
      name: 'Attributes',
      valueGetter: (_) => '',
      valuesGetter: (item) => item.values,
      explicitNoChecks: withExplicitNo
          ? {'safeToAdd': (item) => item.saidNo.contains('safeToAdd')}
          : const {},
    );

/// Keeps only even numbers while turned on.
class _EvenOnlyGroup extends CustomFilterGroup<int> {
  @override
  String get id => 'even';

  @override
  String get name => 'Even';

  bool on = false;

  @override
  bool get isActive => on;

  @override
  bool matches(int item) => !on || item.isEven;

  @override
  Map<String, Object?> serialize() => {'on': on};

  @override
  void restore(Map<String, Object?> selections) =>
      on = selections['on'] == true;

  @override
  void clear() => on = false;

  @override
  Widget buildBody(BuildContext context, VoidCallback onChanged) =>
      const SizedBox.shrink();
}

void main() {
  final saidYes = _Item('yes', values: ['safeToAdd']);
  final saidNo = _Item('no', saidNo: ['safeToAdd']);
  final saidNothing = _Item('unknown');

  group('Explicit-no chip values', () {
    test('excluding an explicit-no chip keeps only items that said no', () {
      final g = _group()..setSelections({'safeToAdd': false});
      expect(g.matches(saidYes), isFalse);
      expect(g.matches(saidNo), isTrue);
      expect(g.matches(saidNothing), isFalse);
    });

    test('including an explicit-no chip works as usual', () {
      final g = _group()..setSelections({'safeToAdd': true});
      expect(g.matches(saidYes), isTrue);
      expect(g.matches(saidNo), isFalse);
      expect(g.matches(saidNothing), isFalse);
    });

    test('other excluded chips still use the usual veto', () {
      final g = _group()..setSelections({'tool': false});
      final tool = _Item('tool', values: ['tool']);
      expect(g.matches(tool), isFalse);
      expect(g.matches(saidNothing), isTrue);
    });

    test('a group without the parameters is unchanged', () {
      final g = _group(withExplicitNo: false)
        ..setSelections({'safeToAdd': false});
      expect(g.matches(saidYes), isFalse);
      expect(g.matches(saidNo), isTrue);
      expect(g.matches(saidNothing), isTrue);
    });
  });

  group('CustomFilterGroup', () {
    test('the controller applies the page rule with the non-chip filters', () {
      final custom = _EvenOnlyGroup();
      final controller = FilterScopeController<int>(
        scope: const FilterScope('test'),
        groups: [custom],
        persistenceEnabled: false,
      );

      expect(controller.applyNonChipFilters([1, 2, 3, 4]), [1, 2, 3, 4]);
      expect(controller.activeCount, 0);

      custom.restore({'on': true});
      expect(controller.applyNonChipFilters([1, 2, 3, 4]), [2, 4]);
      expect(controller.activeCount, 1);
      expect(custom.serialize(), {'on': true});

      controller.clearAll();
      expect(custom.isActive, isFalse);
    });
  });

  group('applyWithCountItems', () {
    final small = ChipFilterGroup<int>(
      id: 'size',
      name: 'Size',
      valueGetter: (n) => n < 5 ? 'small' : 'big',
    );
    final even = _EvenOnlyGroup();
    final controller = FilterScopeController<int>(
      scope: const FilterScope('test'),
      groups: [small, even],
      persistenceEnabled: false,
    );
    final items = [for (var i = 0; i < 10; i++) i];

    setUp(() => controller.clearAll());

    test('matches the same items as the two-step apply', () {
      small.setSelections({'small': true});
      even.on = true;
      final result = controller.applyWithCountItems(items);
      final twoStep = controller.applyNonChipFilters(
        controller.applyChipFilters(items),
      );
      expect(result.matching, twoStep);
      expect(result.matching, [0, 2, 4]);
    });

    test("a chip group's count list leaves out only its own selections", () {
      small.setSelections({'small': true});
      even.on = true;
      final result = controller.applyWithCountItems(items);
      expect(result.countItemsByGroup['size'], [0, 2, 4, 6, 8]);
      expect(result.countItemsByGroup.keys, ['size']);
    });

    test('with nothing on, every item matches and counts', () {
      final result = controller.applyWithCountItems(items);
      expect(result.matching, items);
      expect(result.countItemsByGroup['size'], items);
    });
  });

  group('RangeFilterGroup valueLabel', () {
    test('is kept on the group for the widget to use', () {
      final g = RangeFilterGroup<int>(
        id: 'day',
        name: 'Day',
        valueGetter: (n) => n,
        suffix: 'd',
        valueLabel: (v) => 'day $v',
      );
      expect(g.valueLabel!(3), 'day 3');
    });
  });
}
