import 'package:flutter_test/flutter_test.dart';
import 'package:trios/toolbar/nav_order_controller.dart';
import 'package:trios/toolbar/nav_order_entry.dart';
import 'package:trios/trios/navigation.dart';

void main() {
  group('NavOrderController.reconcile', () {
    test('null input returns the default order', () {
      final result = NavOrderController.reconcileForTesting(null);
      expect(result.length, defaultNavOrder.length);
      for (var i = 0; i < defaultNavOrder.length; i++) {
        final a = result[i];
        final b = defaultNavOrder[i];
        if (a is NavToolEntry && b is NavToolEntry) {
          expect(a.tool, b.tool);
        } else {
          expect(a.runtimeType, b.runtimeType);
        }
      }
    });

    test('empty input returns the default order', () {
      final result = NavOrderController.reconcileForTesting(const []);
      expect(result.length, defaultNavOrder.length);
    });

    test('missing tools are appended', () {
      // Only dashboard + divider — every other reorderable tool should be
      // appended.
      final partial = <NavOrderEntry>[
        const NavToolEntry(TriOSTools.dashboard),
        const NavDividerEntry(),
      ];
      final result = NavOrderController.reconcileForTesting(partial);
      final tools = result.whereType<NavToolEntry>().map((e) => e.tool).toSet();
      expect(tools, reorderableTools);
      // Divider is preserved.
      expect(result.whereType<NavDividerEntry>().length, 1);
    });

    test('duplicate tools are dropped (first occurrence kept)', () {
      final dupes = <NavOrderEntry>[
        const NavToolEntry(TriOSTools.ships),
        const NavToolEntry(TriOSTools.ships),
        const NavDividerEntry(),
        const NavToolEntry(TriOSTools.ships),
      ];
      final result = NavOrderController.reconcileForTesting(dupes);
      final shipsCount = result
          .whereType<NavToolEntry>()
          .where((e) => e.tool == TriOSTools.ships)
          .length;
      expect(shipsCount, 1);
    });

    test('duplicate dividers are dropped', () {
      final dupes = <NavOrderEntry>[
        const NavToolEntry(TriOSTools.dashboard),
        const NavDividerEntry(),
        const NavDividerEntry(),
        const NavToolEntry(TriOSTools.ships),
      ];
      final result = NavOrderController.reconcileForTesting(dupes);
      expect(result.whereType<NavDividerEntry>().length, 1);
    });

    test('non-reorderable tools (e.g. settings) are dropped', () {
      // TriOSTools.settings is explicitly NOT in `reorderableTools`.
      final withSettings = <NavOrderEntry>[
        const NavToolEntry(TriOSTools.settings),
        const NavToolEntry(TriOSTools.dashboard),
        const NavDividerEntry(),
      ];
      final result = NavOrderController.reconcileForTesting(withSettings);
      final hasSettings = result
          .whereType<NavToolEntry>()
          .any((e) => e.tool == TriOSTools.settings);
      expect(hasSettings, false);
    });

    test('synthesizes a divider when none is stored', () {
      final noDivider = <NavOrderEntry>[
        const NavToolEntry(TriOSTools.dashboard),
        const NavToolEntry(TriOSTools.modManager),
      ];
      final result = NavOrderController.reconcileForTesting(noDivider);
      expect(result.whereType<NavDividerEntry>().length, 1);
    });
  });
}
