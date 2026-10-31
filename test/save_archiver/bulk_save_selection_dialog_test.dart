import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/save_archiver/bulk_save_selection_dialog.dart';
import 'package:trios/utils/extensions.dart';

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
  bool? capturedCheckbox;

  Future<void> open(
    WidgetTester tester, {
    required List<SaveSelectionItem> items,
    required Set<String> initiallySelected,
    String? checkboxLabel,
  }) async {
    captured = null;
    capturedCheckbox = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final selection = await showBulkSaveSelectionDialog(
                context: context,
                title: 'Archive saves',
                explanation: 'Pick some.',
                items: items,
                initiallySelected: initiallySelected,
                confirmLabel: (count) => 'Archive $count',
                confirmIcon: Icons.archive,
                checkboxLabel: checkboxLabel,
              );
              captured = selection?.ids;
              capturedCheckbox = selection?.checkboxTicked;
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
    expect(find.text('0 of 2'), findsOneWidget);
  });

  group('the checkbox', () {
    testWidgets('is not shown unless asked for', (tester) async {
      await open(
        tester,
        items: itemsNamed(['save_a']),
        initiallySelected: {'save_a'},
      );

      expect(find.byType(CheckboxListTile), findsNothing);
      await tester.tap(find.text('Archive 1'));
      await tester.pumpAndSettle();
      expect(capturedCheckbox, isFalse);
    });

    testWidgets('starts unticked', (tester) async {
      await open(
        tester,
        items: itemsNamed(['save_a']),
        initiallySelected: {'save_a'},
        checkboxLabel: 'Delete them',
      );

      await tester.tap(find.text('Archive 1'));
      await tester.pumpAndSettle();
      expect(capturedCheckbox, isFalse);
    });

    testWidgets('is returned when ticked', (tester) async {
      await open(
        tester,
        items: itemsNamed(['save_a']),
        initiallySelected: {'save_a'},
        checkboxLabel: 'Delete them',
      );

      await tester.tap(find.text('Delete them'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive 1'));
      await tester.pumpAndSettle();
      expect(captured, {'save_a'});
      expect(capturedCheckbox, isTrue);
    });
  });

  testWidgets('adds up the space needed for the ticked saves', (tester) async {
    await open(
      tester,
      items: const [
        SaveSelectionItem(
          id: 'save_a',
          title: 'save_a',
          subtitle: 'a save',
          sizeInBytes: 1000,
          restoredSizeInBytes: 3000000,
        ),
        SaveSelectionItem(
          id: 'save_b',
          title: 'save_b',
          subtitle: 'a save',
          sizeInBytes: 1000,
          restoredSizeInBytes: 5000000,
        ),
        SaveSelectionItem(
          id: 'save_c',
          title: 'save_c',
          subtitle: 'a save',
          sizeInBytes: 1000,
        ),
      ],
      initiallySelected: {'save_a', 'save_c'},
    );

    expect(find.text('Space needed'), findsOneWidget);
    expect(find.text(3000000.bytesAsReadable()), findsOneWidget);
    expect(
      find.text('${3000000.bytesAsReadable()} when restored'),
      findsOneWidget,
    );
  });
}
