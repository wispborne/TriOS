import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/widgets/filter_pill.dart';
import 'package:trios/widgets/smart_search/search_dsl_field.dart';
import 'package:trios/widgets/smart_search/smart_search_bar.dart';

void main() {
  Widget buildTestBar({
    String initialValue = '',
    ValueChanged<String>? onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SmartSearchBar(
          fields: [
            SearchFieldMeta(
              key: 'type',
              description: 'Type filter',
              valueSuggestions: () => ['weapon', 'ship'],
            ),
            SearchFieldMeta(
              key: 'size',
              description: 'Size filter',
              valueSuggestions: () => ['small', 'medium', 'large'],
            ),
            SearchFieldMeta(
              key: 'tracking',
              description: 'Tracking filter',
              valueSuggestions: () => ['poor', 'good', 'excellent'],
            ),
          ],
          recentHistory: const [],
          onChanged: onChanged ?? (_) {},
          initialValue: initialValue,
        ),
      ),
    );
  }

  int pillCount(WidgetTester tester) =>
      find.byType(FilterPill).evaluate().length;

  Future<void> focusTextField(WidgetTester tester) async {
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
  }

  group('6.1 Left/right arrow traversal', () {
    testWidgets('left arrow at offset 0 selects last pill without deleting',
        (tester) async {
      await tester.pumpWidget(buildTestBar(
        initialValue: 'type:weapon size:large',
      ));
      await tester.pumpAndSettle();
      expect(pillCount(tester), 2);

      await focusTextField(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(pillCount(tester), 2);
    });

    testWidgets('left arrow on first pill stays on first pill (no wrap)',
        (tester) async {
      String lastQuery = '';
      await tester.pumpWidget(buildTestBar(
        initialValue: 'type:weapon size:large tracking:excellent',
        onChanged: (q) => lastQuery = q,
      ));
      await tester.pumpAndSettle();

      await focusTextField(tester);

      // Navigate to first pill: left x3
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // Extra left should stay on first pill
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // Confirm we're on first pill by deleting it
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(pillCount(tester), 2);
      expect(lastQuery, 'size:large tracking:excellent');
    });

    testWidgets('right arrow from last pill returns to text field at offset 0',
        (tester) async {
      await tester.pumpWidget(buildTestBar(
        initialValue: 'type:weapon size:large',
      ));
      await tester.pumpAndSettle();

      await focusTextField(tester);

      // Select last pill
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // Right arrow back to text field
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(pillCount(tester), 2);
    });

    testWidgets('right arrow on non-last pill advances to next pill',
        (tester) async {
      String lastQuery = '';
      await tester.pumpWidget(buildTestBar(
        initialValue: 'type:weapon size:large',
        onChanged: (q) => lastQuery = q,
      ));
      await tester.pumpAndSettle();

      await focusTextField(tester);

      // Select last pill, then left to first
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // Right advances to second pill
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      // Confirm we're on second pill by deleting
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(pillCount(tester), 1);
      expect(lastQuery, 'type:weapon');
    });
  });

  group('6.2 Two-step backspace', () {
    testWidgets('first backspace selects pill, second deletes it',
        (tester) async {
      String lastQuery = '';
      await tester.pumpWidget(buildTestBar(
        initialValue: 'type:weapon size:large',
        onChanged: (q) => lastQuery = q,
      ));
      await tester.pumpAndSettle();

      await focusTextField(tester);

      // First backspace: select only
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(pillCount(tester), 2);

      // Second backspace: delete
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(pillCount(tester), 1);
      expect(lastQuery, 'type:weapon');
    });

    testWidgets('backspace moves selection to previous pill after deletion',
        (tester) async {
      String lastQuery = '';
      await tester.pumpWidget(buildTestBar(
        initialValue: 'type:weapon size:large tracking:excellent',
        onChanged: (q) => lastQuery = q,
      ));
      await tester.pumpAndSettle();

      await focusTextField(tester);

      // Select last pill
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      // Delete last pill — should select previous (size:large)
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(pillCount(tester), 2);
      expect(lastQuery, 'type:weapon size:large');

      // Delete again — should select previous (type:weapon)
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(pillCount(tester), 1);
      expect(lastQuery, 'type:weapon');

      // Delete last remaining pill — should clear
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(pillCount(tester), 0);
      expect(lastQuery, '');
    });
  });

  group('6.3 Delete key forward behavior', () {
    testWidgets('delete on selected pill advances to next pill',
        (tester) async {
      String lastQuery = '';
      await tester.pumpWidget(buildTestBar(
        initialValue: 'type:weapon size:large tracking:excellent',
        onChanged: (q) => lastQuery = q,
      ));
      await tester.pumpAndSettle();

      await focusTextField(tester);

      // Navigate to first pill
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // Delete first pill — should advance to next (size:large now at index 0)
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      expect(pillCount(tester), 2);
      expect(lastQuery, 'size:large tracking:excellent');

      // Delete again — should advance to next (tracking:excellent now at 0)
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      expect(pillCount(tester), 1);
      expect(lastQuery, 'tracking:excellent');
    });

    testWidgets('delete on last pill returns focus to text field',
        (tester) async {
      String lastQuery = '';
      await tester.pumpWidget(buildTestBar(
        initialValue: 'type:weapon size:large',
        onChanged: (q) => lastQuery = q,
      ));
      await tester.pumpAndSettle();

      await focusTextField(tester);

      // Select last pill
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // Delete last pill — should return to text field
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      expect(pillCount(tester), 1);
      expect(lastQuery, 'type:weapon');

      // Verify we're in text field mode: left arrow at offset 0 should select pill
      // (If we were still in pill mode, behavior would be different)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // Confirm by deleting — should delete first pill
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(pillCount(tester), 0);
    });
  });

  group('6.4 Home/End navigation', () {
    testWidgets('Home from text field selects first pill', (tester) async {
      String lastQuery = '';
      await tester.pumpWidget(buildTestBar(
        initialValue: 'type:weapon size:large tracking:excellent',
        onChanged: (q) => lastQuery = q,
      ));
      await tester.pumpAndSettle();

      await focusTextField(tester);

      // Home should select first pill
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();

      // Confirm by deleting first pill
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(pillCount(tester), 2);
      expect(lastQuery, 'size:large tracking:excellent');
    });

    testWidgets('Home from middle pill selects first pill', (tester) async {
      String lastQuery = '';
      await tester.pumpWidget(buildTestBar(
        initialValue: 'type:weapon size:large tracking:excellent',
        onChanged: (q) => lastQuery = q,
      ));
      await tester.pumpAndSettle();

      await focusTextField(tester);

      // Select last pill
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // Home should jump to first pill
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();

      // Confirm by deleting
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(pillCount(tester), 2);
      expect(lastQuery, 'size:large tracking:excellent');
    });

    testWidgets('End from pill selection returns to text field',
        (tester) async {
      await tester.pumpWidget(buildTestBar(
        initialValue: 'type:weapon size:large',
      ));
      await tester.pumpAndSettle();

      await focusTextField(tester);

      // Select last pill
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      // End should return to text field
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();

      // All pills intact
      expect(pillCount(tester), 2);
    });

    testWidgets('Home with no pills is ignored', (tester) async {
      await tester.pumpWidget(buildTestBar());
      await tester.pumpAndSettle();

      await focusTextField(tester);

      // Home with no pills should not crash
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();

      expect(pillCount(tester), 0);
    });
  });
}
