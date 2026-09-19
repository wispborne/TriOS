import 'dart:async';
import 'dart:collection';

/// Round-robin queues: a large batch cannot fill every waiting slot ahead of
/// another batch. Cancellation is checked again when a slot becomes available.
class FairWorkQueue {
  final int Function() limit;
  final _owners = Queue<String>();
  final _pending = <String, Queue<Future<void> Function()>>{};
  int _active = 0;

  FairWorkQueue(this.limit);

  Future<T> run<T>(String owner, Future<T> Function() work) {
    final result = Completer<T>();
    final queue = _pending.putIfAbsent(owner, () {
      _owners.add(owner);
      return Queue();
    });
    queue.add(() async {
      try {
        result.complete(await work());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    _drain();
    return result.future;
  }

  void _drain() {
    while (_active < limit().clamp(1, 6) && _owners.isNotEmpty) {
      final owner = _owners.removeFirst();
      final queue = _pending[owner]!;
      final work = queue.removeFirst();
      if (queue.isEmpty) {
        _pending.remove(owner);
      } else {
        _owners.addLast(owner);
      }
      _active++;
      unawaited(
        work().whenComplete(() {
          _active--;
          _drain();
        }),
      );
    }
  }
}
