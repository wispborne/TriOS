import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/widgets/labeled_text_field.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 400, child: child)),
);

void main() {
  testWidgets('shows its label and current text', (tester) async {
    final controller = TextEditingController(text: 'Wisp');

    await tester.pumpWidget(
      _wrap(LabeledTextField(controller: controller, label: 'Author')),
    );

    expect(find.text('Author'), findsOneWidget);
    expect(find.text('Wisp'), findsOneWidget);
  });

  testWidgets('shows error text the caller passes in', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LabeledTextField(
          controller: TextEditingController(),
          label: 'Update address',
          errorText: 'Must be an HTTP or HTTPS address.',
        ),
      ),
    );

    expect(find.text('Must be an HTTP or HTTPS address.'), findsOneWidget);
  });

  testWidgets('stops typing past the length limit and hides the counter', (
    tester,
  ) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      _wrap(
        LabeledTextField(controller: controller, label: 'Status', maxLength: 5),
      ),
    );

    await tester.enterText(find.byType(TextField), '1234567890');
    await tester.pump();

    expect(controller.text, '12345');
    expect(find.text('5/5'), findsNothing);
  });

  testWidgets('reports changes', (tester) async {
    String? typed;

    await tester.pumpWidget(
      _wrap(
        LabeledTextField(
          controller: TextEditingController(),
          label: 'Name',
          onChanged: (value) => typed = value,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'My pack');
    expect(typed, 'My pack');
  });

  testWidgets('grows for multiline text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LabeledTextField(
          controller: TextEditingController(text: 'one\ntwo\nthree'),
          label: 'Note',
          minLines: 2,
          maxLines: 5,
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 2);
    expect(field.maxLines, 5);
  });
}
