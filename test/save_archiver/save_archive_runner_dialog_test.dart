import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/save_archiver/save_archive_runner_dialog.dart';
import 'package:trios/save_archiver/save_archiver.dart';

void main() {
  /// Keeps a job running until the test completes it.
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
    String? subtitle,
    int? originalSizeInBytes,
    int? archiveSizeInBytes,
  }) => SaveArchiveJobRequest(
    title: title,
    subtitle: subtitle ?? 'save_$title',
    run: (onStep) async {
      started?.add(title);
      return SaveArchiveJobResult(
        succeeded: succeeded,
        needsAttention: needsAttention,
        message: message,
        originalSizeInBytes: originalSizeInBytes,
        archiveSizeInBytes: archiveSizeInBytes,
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
              finishedTitle: 'Archived',
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
    expect(find.text('1 of 2'), findsOneWidget);

    first.complete(
      const SaveArchiveJobResult(succeeded: true, message: 'done'),
    );
    await tester.pump();
    await tester.pump();

    expect(started, ['one', 'two']);
    expect(find.text('2 of 2'), findsOneWidget);

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
    expect(
      find.text('Cancel'),
      findsNothing,
      reason: 'a single save has no later saves to skip',
    );
    expect(find.text('1 of 1'), findsNothing);

    held.complete(
      const SaveArchiveJobResult(succeeded: true, message: 'all good'),
    );
    await tester.pumpAndSettle();

    expect(find.text('all good'), findsOneWidget);
  });

  testWidgets('canceling skips the rest but finishes the one in flight', (
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

    await tester.tap(find.text('Cancel'));
    // The progress animation prevents pumpAndSettle while jobs are running.
    await tester.pump();

    expect(started, ['one'], reason: 'nothing new may start after canceling');
    expect(find.text('Canceling…'), findsOneWidget);

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

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump();
    expect(find.text('Archiving'), findsOneWidget);

    held.complete(const SaveArchiveJobResult(succeeded: true, message: 'done'));
    await tester.pumpAndSettle();

    expect(find.text('Close'), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Archiving'), findsNothing);
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

    expect(find.text('1 completed with warnings.'), findsOneWidget);
    expect(find.text('there are two copies now'), findsOneWidget);
  });

  testWidgets('shows space saved per save and in total', (tester) async {
    await open(tester, [
      instantJob(
        'one',
        message: '',
        originalSizeInBytes: 10000000,
        archiveSizeInBytes: 1000000,
      ),
      instantJob(
        'two',
        message: '',
        originalSizeInBytes: 10000000,
        archiveSizeInBytes: 1000000,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('9.54 MB compressed to 0.95 MB'), findsNWidgets(2));
    expect(find.text('Space saved 8.58 MB (90%)'), findsNWidgets(2));
    expect(find.text('Original size'), findsOneWidget);
    expect(find.text('19.07 MB'), findsOneWidget);
    expect(find.text('1.91 MB'), findsOneWidget);
    expect(find.text('17.17 MB (90%)'), findsOneWidget);
    expect(
      find.textContaining('finished'),
      findsNothing,
      reason: 'the checkmarks already show that everything worked',
    );
  });

  testWidgets('a single save has no total line', (tester) async {
    await open(tester, [
      instantJob(
        'one',
        message: '',
        originalSizeInBytes: 10000000,
        archiveSizeInBytes: 1000000,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Space saved 8.58 MB (90%)'), findsOneWidget);
    expect(find.text('Original size'), findsNothing);
  });

  testWidgets('shows folder names only for saves with the same name', (
    tester,
  ) async {
    await open(tester, [
      instantJob('Ludd', subtitle: 'save_Ludd_1'),
      instantJob('Ludd', subtitle: 'save_Ludd_2'),
      instantJob('Kanta', subtitle: 'save_Kanta_1'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('save_Ludd_1'), findsOneWidget);
    expect(find.text('save_Ludd_2'), findsOneWidget);
    expect(find.text('save_Kanta_1'), findsNothing);
  });

  testWidgets('tells the caller when everything has finished', (tester) async {
    var finished = false;

    await open(tester, [instantJob('one')], onFinished: () => finished = true);
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });
}
