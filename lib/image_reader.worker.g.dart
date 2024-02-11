// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_reader.dart';

// **************************************************************************
// Generator: WorkerGenerator 2.4.2
// **************************************************************************

/// WorkerService class for ReadImageHeaders
class _$ReadImageHeadersWorkerService extends ReadImageHeaders
    implements WorkerService {
  _$ReadImageHeadersWorkerService() : super();

  @override
  Map<int, CommandHandler> get operations => _operations;

  late final Map<int, CommandHandler> _operations =
      Map.unmodifiable(<int, CommandHandler>{
    _$readGenericId: ($) => readGeneric($.args[0]),
    _$readPngId: ($) => readPng($.args[0]),
  });

  static const int _$readGenericId = 1;
  static const int _$readPngId = 2;
}

/// Service initializer for ReadImageHeaders
WorkerService $ReadImageHeadersInitializer(WorkerRequest startRequest) =>
    _$ReadImageHeadersWorkerService();

/// Operations map for ReadImageHeaders
@Deprecated(
    'squadron_builder now supports "plain old Dart objects" as services. '
    'Services do not need to derive from WorkerService nor do they need to mix in '
    'with \$ReadImageHeadersOperations anymore.')
mixin $ReadImageHeadersOperations on WorkerService {
  @override
  // not needed anymore, generated for compatibility with previous versions of squadron_builder
  Map<int, CommandHandler> get operations => WorkerService.noOperations;
}

/// Worker for ReadImageHeaders
class ReadImageHeadersWorker extends Worker implements ReadImageHeaders {
  ReadImageHeadersWorker({PlatformWorkerHook? platformWorkerHook})
      : super($ReadImageHeadersActivator,
            platformWorkerHook: platformWorkerHook);

  @override
  Future<ImageHeader?> readGeneric(String path) =>
      send(_$ReadImageHeadersWorkerService._$readGenericId, args: [path]);

  @override
  Future<ImageHeader?> readPng(String path) =>
      send(_$ReadImageHeadersWorkerService._$readPngId, args: [path]);
}

/// Worker pool for ReadImageHeaders
class ReadImageHeadersWorkerPool extends WorkerPool<ReadImageHeadersWorker>
    implements ReadImageHeaders {
  ReadImageHeadersWorkerPool(
      {ConcurrencySettings? concurrencySettings,
      PlatformWorkerHook? platformWorkerHook})
      : super(
            () =>
                ReadImageHeadersWorker(platformWorkerHook: platformWorkerHook),
            concurrencySettings: concurrencySettings);

  @override
  Future<ImageHeader?> readGeneric(String path) =>
      execute((w) => w.readGeneric(path));

  @override
  Future<ImageHeader?> readPng(String path) => execute((w) => w.readPng(path));
}
