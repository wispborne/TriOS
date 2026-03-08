import 'dart:async';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:trios/utils/logging.dart';

final appWorkerProvider = Provider<AppWorker>((ref) {
  final worker = AppWorker();
  ref.onDispose(worker.dispose);
  return worker;
});

// ---------------------------------------------------------------------------
// Message protocol
// ---------------------------------------------------------------------------

class _TaskRequest {
  final int taskId;
  final Function function;
  final Object? argument;

  _TaskRequest(this.taskId, this.function, this.argument);
}

class _TaskResponse {
  final int taskId;
  final Object? result;

  _TaskResponse(this.taskId, this.result);
}

class _TaskError {
  final int taskId;
  final String error;
  final String stackTrace;

  _TaskError(this.taskId, this.error, this.stackTrace);
}

class _ShutdownMessage {}

// ---------------------------------------------------------------------------
// Worker entry point (top-level function, runs in the worker isolate)
// ---------------------------------------------------------------------------

void _workerEntryPoint(SendPort mainSendPort) {
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  // All Fimber calls in this isolate now forward through the port.
  configureWorkerLogging(mainSendPort);

  workerReceivePort.listen((dynamic message) async {
    if (message is _TaskRequest) {
      try {
        final result = await message.function(message.argument);
        mainSendPort.send(_TaskResponse(message.taskId, result));
      } catch (e, st) {
        mainSendPort.send(
          _TaskError(message.taskId, e.toString(), st.toString()),
        );
      }
      return;
    }

    if (message is _ShutdownMessage) {
      workerReceivePort.close();
      return;
    }
  });
}

// ---------------------------------------------------------------------------
// AppWorker
// ---------------------------------------------------------------------------

class AppWorker {
  Isolate? _isolate;
  SendPort? _workerSendPort;
  final _pendingTasks = <int, Completer<Object?>>{};
  int _nextTaskId = 0;
  Completer<void>? _initCompleter;

  /// Runs [function] with [argument] in the long-lived worker isolate.
  ///
  /// [function] must be a top-level or static function (same constraint as
  /// `compute()`). The isolate is spawned lazily on first call and reused for
  /// all subsequent calls. Tasks execute sequentially.
  Future<R> run<R, A>(FutureOr<R> Function(A) function, A argument) async {
    await _ensureInitialized();

    final taskId = _nextTaskId++;
    final completer = Completer<Object?>();
    _pendingTasks[taskId] = completer;

    _workerSendPort!.send(_TaskRequest(taskId, function, argument));

    final result = await completer.future;
    return result as R;
  }

  Future<void> _ensureInitialized() async {
    if (_workerSendPort != null) return;
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }

    _initCompleter = Completer<void>();

    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_workerEntryPoint, receivePort.sendPort);
    receivePort.listen(_handleWorkerMessage);

    await _initCompleter!.future;
  }

  void _handleWorkerMessage(dynamic message) {
    if (message is SendPort) {
      _workerSendPort = message;
      _initCompleter?.complete();
      return;
    }

    if (message is _TaskResponse) {
      _pendingTasks.remove(message.taskId)?.complete(message.result);
      return;
    }

    if (message is _TaskError) {
      _pendingTasks.remove(message.taskId)?.completeError(
        RemoteWorkerException(message.error, message.stackTrace),
      );
      return;
    }

    if (message is WorkerLogMessage) {
      _dispatchLogMessage(message);
      return;
    }
  }

  void _dispatchLogMessage(WorkerLogMessage log) {
    final stackTrace =
        log.stackTrace != null ? StackTrace.fromString(log.stackTrace!) : null;
    final level = log.levelValue;

    if (level <= Level.trace.value) {
      Fimber.v(() => log.message, ex: log.error, stacktrace: stackTrace);
    } else if (level <= Level.debug.value) {
      Fimber.d(log.message, ex: log.error, stacktrace: stackTrace);
    } else if (level <= Level.info.value) {
      Fimber.i(log.message, ex: log.error, stacktrace: stackTrace);
    } else if (level <= Level.warning.value) {
      Fimber.w(log.message, ex: log.error, stacktrace: stackTrace);
    } else {
      Fimber.e(log.message, ex: log.error, stacktrace: stackTrace);
    }
  }

  void dispose() {
    _workerSendPort?.send(_ShutdownMessage());
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _workerSendPort = null;

    for (final completer in _pendingTasks.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('AppWorker disposed while task was pending'),
        );
      }
    }
    _pendingTasks.clear();
  }
}

/// Exception thrown on the main isolate when a worker task fails.
class RemoteWorkerException implements Exception {
  final String message;
  final String remoteStackTrace;

  RemoteWorkerException(this.message, this.remoteStackTrace);

  @override
  String toString() =>
      'RemoteWorkerException: $message\nRemote stack trace:\n$remoteStackTrace';
}
