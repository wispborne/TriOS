// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: WorkerGenerator 6.1.5
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'image_reader_async.dart';

void _start$ReadImageHeaders(WorkerRequest command) {
  /// VM entry point for ReadImageHeaders
  run($ReadImageHeadersInitializer, command);
}

EntryPoint $getReadImageHeadersActivator(SquadronPlatformType platform) {
  if (platform.isVm) {
    return _start$ReadImageHeaders;
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
