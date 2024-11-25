// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_reader_async.dart';

// **************************************************************************
// Generator: WorkerGenerator 6.1.1
// **************************************************************************

/// WorkerService class for ReadImageHeaders
class _$ReadImageHeadersWorkerService extends ReadImageHeaders
    implements WorkerService {
  _$ReadImageHeadersWorkerService() : super();

  @override
  late final Map<int, CommandHandler> operations =
      Map.unmodifiable(<int, CommandHandler>{
    _$readGenericId: ($) => readGeneric(_$X.$impl.$dsr0($.args[0])),
    _$readPngId: ($) => readPng(_$X.$impl.$dsr0($.args[0])),
  });

  static const int _$readGenericId = 1;
  static const int _$readPngId = 2;
}

/// Service initializer for ReadImageHeaders
WorkerService $ReadImageHeadersInitializer(WorkerRequest $$) =>
    _$ReadImageHeadersWorkerService();

/// Worker for ReadImageHeaders
base class ReadImageHeadersWorker extends Worker implements ReadImageHeaders {
  ReadImageHeadersWorker(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($ReadImageHeadersActivator(Squadron.platformType));

  ReadImageHeadersWorker.vm(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($ReadImageHeadersActivator(SquadronPlatformType.vm));

  ReadImageHeadersWorker.js(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($ReadImageHeadersActivator(SquadronPlatformType.js),
            threadHook: threadHook, exceptionManager: exceptionManager);

  ReadImageHeadersWorker.wasm(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($ReadImageHeadersActivator(SquadronPlatformType.wasm));

  @override
  Future<ImageHeader?> readGeneric(String path) =>
      send(_$ReadImageHeadersWorkerService._$readGenericId, args: [path])
          .then(_$X.$impl.$dsr2);

  @override
  Future<ImageHeader?> readPng(String path) =>
      send(_$ReadImageHeadersWorkerService._$readPngId, args: [path])
          .then(_$X.$impl.$dsr2);
}

/// Worker pool for ReadImageHeaders
base class ReadImageHeadersWorkerPool extends WorkerPool<ReadImageHeadersWorker>
    implements ReadImageHeaders {
  ReadImageHeadersWorkerPool(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => ReadImageHeadersWorker(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  ReadImageHeadersWorkerPool.vm(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => ReadImageHeadersWorker.vm(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  ReadImageHeadersWorkerPool.js(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => ReadImageHeadersWorker.js(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  ReadImageHeadersWorkerPool.wasm(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => ReadImageHeadersWorker.wasm(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  @override
  Future<ImageHeader?> readGeneric(String path) =>
      execute((w) => w.readGeneric(path));

  @override
  Future<ImageHeader?> readPng(String path) => execute((w) => w.readPng(path));
}

final class _$X {
  _$X._();

  static _$X? _impl;

  static _$X get $impl {
    if (_impl == null) {
      Squadron.onConverterChanged(() => _impl = _$X._());
      _impl = _$X._();
    }
    return _impl!;
  }

  late final $dsr0 = Squadron.converter.value<String>();
  late final $dsr1 = Squadron.converter.value<ImageHeader>();
  late final $dsr2 = Squadron.converter.nullable($dsr1);
}
