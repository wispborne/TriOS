import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/widgets/filter_pill.dart';
import 'package:trios/widgets/smart_search/search_dsl_field.dart';
import 'package:trios/widgets/smart_search/smart_search_bar.dart';

void main() {
  Widget buildTestBar({
    required bool useFieldPills,
    ValueChanged<String>? onChanged,
    WidgetBuilder? helpBuilder,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SmartSearchBar(
          fields: [
            SearchFieldMeta(
              key: 'author',
              description: 'Author filter',
              valueSuggestions: () => ['Wisp', 'Histidine'],
            ),
            SearchFieldMeta(
              key: 'category',
              description: 'Category filter',
              valueSuggestions: () => ['Weapons', 'Total Conversion'],
            ),
          ],
          recentHistory: const [],
          onChanged: onChanged ?? (_) {},
          useFieldPills: useFieldPills,
          helpBuilder: helpBuilder,
        ),
      ),
    );
  }

  int pillCount(WidgetTester tester) =>
      find.byType(FilterPill).evaluate().length;

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  group('pills off', () {
    testWidgets('"kol, author:wisp" reaches onChanged unchanged', (
      tester,
    ) async {
      var lastQuery = '';
      await tester.pumpWidget(
        buildTestBar(useFieldPills: false, onChanged: (q) => lastQuery = q),
      );

      await tester.enterText(find.byType(TextField), 'kol, author:wisp');
      await tester.pump();
      expect(lastQuery, 'kol, author:wisp');

      await tester.enterText(find.byType(TextField), 'kol, author:wisp ');
      await tester.pump();
      expect(lastQuery, 'kol, author:wisp ');
      expect(pillCount(tester), 0);
    });

    testWidgets('"kol, auth" suggests author: and choosing it completes the piece', (
      tester,
    ) async {
      var lastQuery = '';
      await tester.pumpWidget(
        buildTestBar(useFieldPills: false, onChanged: (q) => lastQuery = q),
      );

      await tester.enterText(find.byType(TextField), 'kol, auth');
      await tester.pump();
      expect(find.text('author'), findsOneWidget);

      await tester.tap(find.text('author'));
      await tester.pumpAndSettle();
      expect(fieldText(tester), 'kol, author:');
      expect(lastQuery, 'kol, author:');
    });

    testWidgets('choosing a value puts it in place without a pill', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestBar(useFieldPills: false));

      await tester.enterText(find.byType(TextField), 'kol,category:tot');
      await tester.pump();
      await tester.tap(find.text('Total Conversion'));
      await tester.pumpAndSettle();

      expect(fieldText(tester), 'kol,category:"Total Conversion"');
      expect(pillCount(tester), 0);
    });

    testWidgets('the info button shows the custom help', (tester) async {
      await tester.pumpWidget(
        buildTestBar(
          useFieldPills: false,
          helpBuilder: (_) => const Text('Custom help text'),
        ),
      );

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.text('Custom help text'), findsOneWidget);
      expect(find.text('Search Field Reference'), findsNothing);
    });
  });

  group('pills on (the default)', () {
    testWidgets('fields still become pills', (tester) async {
      var lastQuery = '';
      await tester.pumpWidget(
        buildTestBar(useFieldPills: true, onChanged: (q) => lastQuery = q),
      );

      await tester.enterText(find.byType(TextField), 'kol author:wisp ');
      await tester.pump();
      expect(pillCount(tester), 1);
      expect(lastQuery, 'author:wisp kol');
    });

    testWidgets('the info button shows the field reference', (tester) async {
      await tester.pumpWidget(buildTestBar(useFieldPills: true));

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();
      expect(find.text('Search Field Reference'), findsOneWidget);
    });
  });
}
