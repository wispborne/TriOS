// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/libarchive/libarchive.dart';
import 'package:trios/main.dart';

void main() {
  // testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  //   // Build our app and trigger a frame.
  //   await tester.pumpWidget(const TriOSApp());
  //
  //   // Verify that our counter starts at 0.
  //   expect(find.text('0'), findsOneWidget);
  //   expect(find.text('1'), findsNothing);
  //
  //   // Tap the '+' icon and trigger a frame.
  //   await tester.tap(find.byIcon(Icons.add));
  //   await tester.pump();
  //
  //   // Verify that our counter has incremented.
  //   expect(find.text('0'), findsNothing);
  //   expect(find.text('1'), findsOneWidget);
  // });

  test("LibArchive read test", () {
    configureLogging();
    final libArchive = LibArchive();
    var archivePath = "F:/Downloads/Combat-Activators-v1.1.3.zip";
    final archiveEntries = libArchive.getEntriesInArchive(archivePath);

    print("Archive file: $archivePath");
    for (var element in archiveEntries) {
      print(element);
      print(element.file);
    }
  });

  test("LibArchive write test", () {
    configureLogging();
    final libArchive = LibArchive();
    var archivePath = "F:/Downloads/Combat-Activators-v1.1.3.zip";
    final archiveEntries =
        libArchive.extractEntriesInArchive(archivePath, "F:/Downloads/Combat-Activators-extractTest");

    print("Extracting archive file: $archivePath");
    for (var element in archiveEntries) {
      print(element);
    }
  });
}
