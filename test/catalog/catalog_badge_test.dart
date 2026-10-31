import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/catalog_mod_card.dart';

void main() {
  testWidgets('a badge in a Wrap is only as wide as its text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            child: Wrap(
              children: [CatalogBadge(label: '1.0.4', tooltip: 'Mod version')],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(CatalogBadge)).width, lessThan(100));
  });
}
