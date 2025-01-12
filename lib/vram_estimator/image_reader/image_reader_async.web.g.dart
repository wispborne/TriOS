// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: WorkerGenerator 6.1.5
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'image_reader_async.dart';

void main() {
  /// Web entry point for ReadImageHeaders
  run($ReadImageHeadersInitializer);
}

EntryPoint $getReadImageHeadersActivator(SquadronPlatformType platform) {
  if (platform.isJs) {
    return Squadron.uri(
        'lib/vram_estimator/image_reader/image_reader_async.web.g.dart.js');
  } else if (platform.isWasm) {
    return Squadron.uri(
        'lib/vram_estimator/image_reader/image_reader_async.web.g.dart.wasm');
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
