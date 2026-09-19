import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/fair_work_queue.dart';

void main() {
  test('rotates waiting packs and never exceeds the shared limit', () async {
    final queue = FairWorkQueue(() => 2);
    final active = <String, Completer<void>>{};
    final started = <String>[];
    var count = 0;
    var maximum = 0;
    Future<void> work(String id) async {
      count++;
      if (count > maximum) maximum = count;
      started.add(id);
      await (active[id] = Completer<void>()).future;
      count--;
    }

    final futures = [
      for (var i = 0; i < 5; i++) queue.run('large', () => work('a$i')),
      queue.run('small', () => work('b')),
    ];
    expect(started, ['a0', 'a1']);
    active['a0']!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(started.last, 'a2');
    active['a1']!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(started.last, 'b');
    while (started.length < 6 || count > 0) {
      for (final c in active.values.toList()) {
        if (!c.isCompleted) c.complete();
      }
      await Future<void>.delayed(Duration.zero);
    }
    await Future.wait(futures);
    expect(maximum, 2);
  });

  test('a failed operation releases capacity', () async {
    final queue = FairWorkQueue(() => 1);
    final failure = queue.run('a', () async => throw StateError('failed'));
    final success = queue.run('b', () async => 42);
    await expectLater(failure, throwsStateError);
    expect(await success, 42);
  });
}
