import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/widgets/dialog_pager.dart';

void main() {
  Widget harness(List<String> items, {int startIndex = 0}) {
    return MaterialApp(
      home: Scaffold(
        body: DialogPager<String>(
          items: items,
          startIndex: startIndex,
          itemBuilder: (context, item, pagerControls) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text('item: $item'), const TextField(), pagerControls],
          ),
        ),
      ),
    );
  }

  IconButton chevronButton(WidgetTester tester, IconData icon) =>
      tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon));

  testWidgets('controls are hidden with fewer than two items', (tester) async {
    await tester.pumpWidget(harness(['only']));
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('Previous is disabled on the first item and Next on the last', (
    tester,
  ) async {
    await tester.pumpWidget(harness(['a', 'b', 'c']));

    expect(chevronButton(tester, Icons.chevron_left).onPressed, isNull);
    expect(chevronButton(tester, Icons.chevron_right).onPressed, isNotNull);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(find.text('item: b'), findsOneWidget);
    expect(chevronButton(tester, Icons.chevron_left).onPressed, isNotNull);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(find.text('item: c'), findsOneWidget);
    expect(chevronButton(tester, Icons.chevron_right).onPressed, isNull);
  });

  testWidgets('arrow keys page in both directions', (tester) async {
    await tester.pumpWidget(harness(['a', 'b', 'c']));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('item: b'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.text('item: c'), findsOneWidget);

    // At the end of the list the key does nothing.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('item: c'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(find.text('item: b'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(find.text('item: a'), findsOneWidget);
  });

  testWidgets('arrow keys are ignored while a text field has focus', (
    tester,
  ) async {
    await tester.pumpWidget(harness(['a', 'b']));
    await tester.pump();

    await tester.tap(find.byType(TextField));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('item: a'), findsOneWidget);
  });
}
