import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/save_archiver/save_archive_runner_dialog.dart';
import 'package:trios/save_archiver/save_archiver.dart';

/// The runner's promises: one job at a time, "stop" never interrupts the job in
/// flight, and it can't be closed while something is still running.
void main() {
  /// A job that finishes when its completer is completed, so a test can hold
  /// one open and look at the dialog mid-run.
  SaveArchiveJobRequest heldJob(
    String title,
    Completer<SaveArchiveJobResult> completer, {
    List<String>? started,
    void Function(SaveArchiveStep step)? reportSteps,
  }) => SaveArchiveJobRequest(
    title: title,
    subtitle: 'save_$title',
    run: (onStep) {
      started?.add(title);
      reportSteps?.call(SaveArchiveStep.compressing);
      onStep(SaveArchiveStep.compressing);
      return completer.future;
    },
  );

  SaveArchiveJobRequest instantJob(
    String title, {
    bool succeeded = true,
    bool needsAttention = false,
    String message = 'done',
    List<String>? started,
  }) => SaveArchiveJobRequest(
    title: title,
    subtitle: 'save_$title',
    run: (onStep) async {
      started?.add(title);
      return SaveArchiveJobResult(
        succeeded: succeeded,
        needsAttention: needsAttention,
        message: message,
      );
    },
  );

  Future<void> open(
    WidgetTester tester,
    List<SaveArchiveJobRequest> jobs, {
    VoidCallback? onFinished,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showSaveArchiveRunnerDialog(
              context: context,
              title: 'Archiving',
              jobs: jobs,
              onFinished: onFinished,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('runs one job at a time, in order', (tester) async {
    final first = Completer<SaveArchiveJobResult>();
    final second = Completer<SaveArchiveJobResult>();
    final started = <String>[];

    await open(tester, [
      heldJob('one', first, started: started),
      heldJob('two', second, started: started),
    ]);
    await tester.pump();

    expect(started, ['one'], reason: 'the second must wait its turn');

    first.complete(
      const SaveArchiveJobResult(succeeded: true, message: 'done'),
    );
    await tester.pump();
    await tester.pump();

    expect(started, ['one', 'two']);

    second.complete(
      const SaveArchiveJobResult(succeeded: true, message: 'done'),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('shows the step a running job is on', (tester) async {
    final held = Completer<SaveArchiveJobResult>();

    await open(tester, [heldJob('one', held)]);
    await tester.pump();

    expect(find.text('Compressing'), findsOneWidget);

    held.complete(
      const SaveArchiveJobResult(succeeded: true, message: 'all good'),
    );
    await tester.pumpAndSettle();

    expect(find.text('all good'), findsOneWidget);
  });

  testWidgets('stopping skips the rest but finishes the one in flight', (
    tester,
  ) async {
    final first = Completer<SaveArchiveJobResult>();
    final started = <String>[];

    await open(tester, [
      heldJob('one', first, started: started),
      instantJob('two', started: started),
      instantJob('three', started: started),
    ]);
    await tester.pump();

    await tester.tap(find.text('Stop after this one'));
    // Not pumpAndSettle: the progress bar animates while a job is in flight, so
    // nothing ever settles until the last one is done.
    await tester.pump();

    expect(started, ['one'], reason: 'nothing new may start after stopping');
    expect(find.text('Finishing current…'), findsOneWidget);

    first.complete(
      const SaveArchiveJobResult(succeeded: true, message: 'finished anyway'),
    );
    await tester.pumpAndSettle();

    expect(started, [
      'one',
    ], reason: 'the job in flight finished; the others never ran');
    expect(find.text('1 finished, 2 skipped.'), findsOneWidget);
    expect(find.text('Skipped'), findsNWidgets(2));
  });

  testWidgets('cannot be closed while a job is running', (tester) async {
    final held = Completer<SaveArchiveJobResult>();

    await open(tester, [heldJob('one', held)]);
    await tester.pump();

    expect(find.text('Close'), findsNothing);

    // Escape does nothing either.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump();
    expect(find.text('Archiving'), findsOneWidget);

    held.complete(const SaveArchiveJobResult(succeeded: true, message: 'done'));
    await tester.pumpAndSettle();

    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('a job that throws is reported, and the rest still run', (
    tester,
  ) async {
    final started = <String>[];

    await open(tester, [
      SaveArchiveJobRequest(
        title: 'one',
        subtitle: 'save_one',
        run: (onStep) async {
          started.add('one');
          throw Exception('7-Zip fell over');
        },
      ),
      instantJob('two', started: started),
    ]);
    await tester.pumpAndSettle();

    expect(started, ['one', 'two']);
    expect(find.textContaining('7-Zip fell over'), findsOneWidget);
    expect(find.text('1 finished, 1 failed.'), findsOneWidget);
  });

  testWidgets('a job that worked but needs a look is counted separately', (
    tester,
  ) async {
    await open(tester, [
      instantJob(
        'one',
        needsAttention: true,
        message: 'there are two copies now',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('1 need a look.'), findsOneWidget);
    expect(find.text('there are two copies now'), findsOneWidget);
  });

  testWidgets('tells the caller when everything has finished', (tester) async {
    var finished = false;

    await open(tester, [instantJob('one')], onFinished: () => finished = true);
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });
}
