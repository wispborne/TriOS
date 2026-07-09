import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trios/widgets/moving_tooltip.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  Future<TestGesture> hoverOver(WidgetTester tester, Finder finder) async {
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(finder));
    await tester.pump();
    return gesture;
  }

  testWidgets('tooltipWidgetBuilder waits for the default show delay', (
    tester,
  ) async {
    var buildCount = 0;
    await tester.pumpWidget(
      wrap(
        MovingTooltipWidget(
          tooltipWidgetBuilder: (_) {
            buildCount++;
            return const Text('tooltip content');
          },
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );

    await hoverOver(tester, find.byType(SizedBox));
    expect(buildCount, 0);
    expect(find.text('tooltip content'), findsNothing);

    await tester.pump(MovingTooltipWidget.defaultBuilderShowDelay);
    await tester.pump();
    expect(buildCount, 1);
    expect(find.text('tooltip content'), findsOneWidget);
  });

  testWidgets('exiting before the delay never builds the tooltip', (
    tester,
  ) async {
    var buildCount = 0;
    await tester.pumpWidget(
      wrap(
        MovingTooltipWidget(
          tooltipWidgetBuilder: (_) {
            buildCount++;
            return const Text('tooltip content');
          },
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );

    final gesture = await hoverOver(tester, find.byType(SizedBox));
    await gesture.moveTo(Offset.zero); // Leave before the delay elapses.
    await tester.pump(MovingTooltipWidget.defaultBuilderShowDelay * 2);
    expect(buildCount, 0);
    expect(find.text('tooltip content'), findsNothing);
  });

  testWidgets('eager tooltipWidget still shows without delay', (tester) async {
    await tester.pumpWidget(
      wrap(
        const MovingTooltipWidget(
          tooltipWidget: Text('tooltip content'),
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    );

    await hoverOver(tester, find.byType(SizedBox));
    expect(find.text('tooltip content'), findsOneWidget);
  });

  testWidgets('showDelay: Duration.zero opts a builder out of the delay', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MovingTooltipWidget(
          showDelay: Duration.zero,
          tooltipWidgetBuilder: (_) => const Text('tooltip content'),
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );

    await hoverOver(tester, find.byType(SizedBox));
    expect(find.text('tooltip content'), findsOneWidget);
  });
}
