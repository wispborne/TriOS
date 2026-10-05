import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/save_archiver/bulk_save_selection_dialog.dart';

/// The dialog's one promise: the ticks somebody is looking at are exactly what
/// gets acted on. Nothing else, and nothing extra.
void main() {
  List<SaveSelectionItem> itemsNamed(List<String> ids) => [
    for (final id in ids)
      SaveSelectionItem(
        id: id,
        title: id,
        subtitle: 'a save',
        sizeInBytes: 1000,
      ),
  ];

  Set<String>? captured;

  Future<void> open(
    WidgetTester tester, {
    required List<SaveSelectionItem> items,
    required Set<String> initiallySelected,
    SaveSelectionCountFilter? countFilter,
  }) async {
    captured = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              captured = await showBulkSaveSelectionDialog(
                context: context,
                title: 'Archive saves',
                explanation: 'Pick some.',
                items: items,
                initiallySelected: initiallySelected,
                confirmLabel: (count) => 'Archive $count',
                confirmIcon: Icons.archive,
                countFilter: countFilter,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('returns exactly what is ticked when it opens', (tester) async {
    await open(
      tester,
      items: itemsNamed(['save_a', 'save_b', 'save_c']),
      initiallySelected: {'save_b', 'save_c'},
    );

    expect(find.text('Archive 2'), findsOneWidget);
    await tester.tap(find.text('Archive 2'));
    await tester.pumpAndSettle();

    expect(captured, {'save_b', 'save_c'});
  });

  testWidgets('cancelling returns nothing at all', (tester) async {
    await open(
      tester,
      items: itemsNamed(['save_a', 'save_b']),
      initiallySelected: {'save_a', 'save_b'},
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(captured, isNull);
  });

  testWidgets('unticking a row takes it out of the result', (tester) async {
    await open(
      tester,
      items: itemsNamed(['save_a', 'save_b']),
      initiallySelected: {'save_a', 'save_b'},
    );

    await tester.tap(find.text('save_a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive 1'));
    await tester.pumpAndSettle();

    expect(captured, {'save_b'});
  });

  testWidgets('ticking a row adds it', (tester) async {
    await open(
      tester,
      items: itemsNamed(['save_a', 'save_b']),
      initiallySelected: const {},
    );

    await tester.tap(find.text('save_b'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive 1'));
    await tester.pumpAndSettle();

    expect(captured, {'save_b'});
  });

  testWidgets('confirming is not possible with nothing ticked', (tester) async {
    await open(
      tester,
      items: itemsNamed(['save_a']),
      initiallySelected: const {},
    );

    await tester.tap(find.text('Archive 0'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Still open, nothing returned.
    expect(find.text('Archive saves'), findsOneWidget);
    expect(captured, isNull);
  });

  testWidgets('a row that cannot be ticked stays out of the result', (
    tester,
  ) async {
    await open(
      tester,
      items: [
        ...itemsNamed(['save_a']),
        const SaveSelectionItem(
          id: 'save_blocked',
          title: 'save_blocked',
          subtitle: 'a save',
          sizeInBytes: 1000,
          selectable: false,
          blockedReason: 'Already in the saves folder',
        ),
      ],
      initiallySelected: {'save_a', 'save_blocked'},
    );

    // It was asked for, but it is not selectable, so it was never ticked.
    expect(find.text('Archive 1'), findsOneWidget);
    expect(find.text('Already in the saves folder'), findsOneWidget);

    await tester.tap(find.text('save_blocked'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive 1'));
    await tester.pumpAndSettle();

    expect(captured, {'save_a'});
  });

  testWidgets('select all never picks up an unselectable row', (tester) async {
    await open(
      tester,
      items: [
        ...itemsNamed(['save_a']),
        const SaveSelectionItem(
          id: 'save_blocked',
          title: 'save_blocked',
          subtitle: 'a save',
          sizeInBytes: 1000,
          selectable: false,
        ),
      ],
      initiallySelected: const {},
    );

    await tester.tap(find.text('Select all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive 1'));
    await tester.pumpAndSettle();

    expect(captured, {'save_a'});
  });

  testWidgets('select none clears everything', (tester) async {
    await open(
      tester,
      items: itemsNamed(['save_a', 'save_b']),
      initiallySelected: {'save_a', 'save_b'},
    );

    await tester.tap(find.text('Select none'));
    await tester.pumpAndSettle();

    expect(find.text('Archive 0'), findsOneWidget);
    expect(find.text('0 of 2 selected'), findsOneWidget);
  });

  group('the "keep the newest" number', () {
    SaveSelectionCountFilter filterOver(
      List<String> ids, {
      required int initialValue,
      void Function(int)? onValueChanged,
    }) => SaveSelectionCountFilter(
      prefixLabel: 'Keep the newest',
      suffixLabel: 'saves',
      initialValue: initialValue,
      maxValue: ids.length,
      // Newest first, keep the first [value] of them.
      selectionFor: (value) => ids.skip(value).toSet(),
      onValueChanged: onValueChanged,
    );

    testWidgets('starts at the number it was given', (tester) async {
      final ids = ['save_a', 'save_b', 'save_c'];
      await open(
        tester,
        items: itemsNamed(ids),
        initiallySelected: {'save_b', 'save_c'},
        countFilter: filterOver(ids, initialValue: 1),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('Archive 2'), findsOneWidget);
    });

    testWidgets('turning it up keeps more and archives fewer', (tester) async {
      final ids = ['save_a', 'save_b', 'save_c'];
      await open(
        tester,
        items: itemsNamed(ids),
        initiallySelected: {'save_b', 'save_c'},
        countFilter: filterOver(ids, initialValue: 1),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.text('Archive 1'));
      await tester.pumpAndSettle();
      expect(captured, {'save_c'});
    });

    testWidgets('turning it down to zero picks everything', (tester) async {
      final ids = ['save_a', 'save_b', 'save_c'];
      await open(
        tester,
        items: itemsNamed(ids),
        initiallySelected: {'save_b', 'save_c'},
        countFilter: filterOver(ids, initialValue: 1),
      );

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      expect(find.text('Archive 3'), findsOneWidget);
    });

    testWidgets('changing the number throws away hand-made ticks', (
      tester,
    ) async {
      final ids = ['save_a', 'save_b', 'save_c'];
      await open(
        tester,
        items: itemsNamed(ids),
        initiallySelected: {'save_c'},
        countFilter: filterOver(ids, initialValue: 2),
      );

      await tester.tap(find.text('save_a'));
      await tester.pumpAndSettle();
      expect(find.text('Archive 2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      // Back to what "keep the newest 1" means, not what was ticked by hand.
      await tester.tap(find.text('Archive 2'));
      await tester.pumpAndSettle();
      expect(captured, {'save_b', 'save_c'});
    });

    testWidgets('it is reported so it can be remembered', (tester) async {
      final ids = ['save_a', 'save_b'];
      final reported = <int>[];

      await open(
        tester,
        items: itemsNamed(ids),
        initiallySelected: {'save_b'},
        countFilter: filterOver(
          ids,
          initialValue: 1,
          onValueChanged: reported.add,
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      expect(reported, [2, 1]);
    });

    testWidgets('it cannot go below zero or above the number of saves', (
      tester,
    ) async {
      final ids = ['save_a', 'save_b'];
      await open(
        tester,
        items: itemsNamed(ids),
        initiallySelected: const {},
        countFilter: filterOver(ids, initialValue: 0),
      );

      expect(
        tester.widget<IconButton>(_iconButtonWith(Icons.remove)).onPressed,
        isNull,
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(
        tester.widget<IconButton>(_iconButtonWith(Icons.add)).onPressed,
        isNull,
      );
    });
  });
}

Finder _iconButtonWith(IconData icon) =>
    find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton));
