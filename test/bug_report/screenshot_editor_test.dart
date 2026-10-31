import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/bug_report/screenshot_editor.dart';

Future<Uint8List> _whitePng(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = Colors.white,
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<Color> _pixelAt(Uint8List png, int x, int y) async {
  final image = await decodeImageFromList(png);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final i = (y * image.width + x) * 4;
  final bytes = data!.buffer.asUint8List();
  return Color.fromARGB(bytes[i + 3], bytes[i], bytes[i + 1], bytes[i + 2]);
}

void main() {
  testWidgets('hidden areas are painted black in the sent image', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final screenshot = await BugReportScreenshot.fromBytes(
        await _whitePng(20, 20),
      );
      expect(screenshot.width, 20);
      expect(screenshot.height, 20);

      final result = await flattenScreenshot(screenshot, [
        const HideBox(Rect.fromLTRB(0, 0, 10, 10)),
      ]);

      expect(await _pixelAt(result, 5, 5), const Color(0xFF000000));
      expect(await _pixelAt(result, 15, 15), const Color(0xFFFFFFFF));
    });
  });

  testWidgets('no marks sends the original image', (tester) async {
    await tester.runAsync(() async {
      final bytes = await _whitePng(4, 4);
      final screenshot = await BugReportScreenshot.fromBytes(bytes);
      expect(await flattenScreenshot(screenshot, []), same(bytes));
    });
  });
}
