import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:trios/models/mod_info.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/vram_estimator/image_reader/image_reader_async.dart';
import 'package:trios/vram_estimator/image_reader/png_chatgpt.dart';
import 'package:trios/vram_estimator/models/graphics_lib_config.dart';
import 'package:trios/vram_estimator/models/vram_checker_models.dart';
import 'package:trios/vram_estimator/selectors/vram_selector_id.dart';
import 'package:trios/vram_estimator/vram_check_scan_params.dart';
import 'package:trios/vram_estimator/vram_checker_logic.dart';
import 'package:trios/vram_estimator/vram_scan_one_mod.dart';

class _TrackingReader extends ReadImageHeaders {
  int active = 0;
  int peak = 0;
  int calls = 0;
  bool cancelled = false;
  bool cancelAfterFirst = false;
  bool failFirst = false;

  @override
  Future<ImageHeader?> readImageDeterminingBest(String path) async {
    calls++;
    final first = calls == 1;
    active++;
    if (active > peak) peak = active;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      if (first && cancelAfterFirst) cancelled = true;
      if (first && failFirst) throw const FormatException('Bad image');
      return ImageHeader(16, 16, 8, 4);
    } finally {
      active--;
    }
  }
}

Future<VramScanOutcome> _scan(_TrackingReader reader, int limit) async {
  final dir = await Directory.systemTemp.createTemp('scan_file_handles_');
  try {
    final graphics = await Directory('${dir.path}/graphics').create();
    for (var i = 0; i < 12; i++) {
      await File('${graphics.path}/$i.png').writeAsBytes([]);
    }
    return await scanOneMod(
      VramCheckScanParams(
        modInfo: VramCheckerMod(ModInfo(id: 'handles'), dir.path),
        enabledModIds: const [],
        selectorId: VramSelectorId.folderScan,
        selectorConfig: null,
        graphicsLibConfig: GraphicsLibConfig.disabled,
        showGfxLibDebugOutput: false,
        showPerformance: false,
        showSkippedFiles: true,
        showCountedFiles: false,
        maxFileHandles: limit,
      ),
      imageReaderPool: reader,
      isCancelledLocal: () => reader.cancelled,
    );
  } finally {
    await dir.delete(recursive: true);
  }
}

void main() {
  test('default scan budget leaves room for other app files', () {
    final checker = VramChecker(
      variantsToCheck: [],
      showGfxLibDebugOutput: false,
      showPerformance: false,
      showSkippedFiles: false,
      showCountedFiles: false,
      graphicsLibConfig: GraphicsLibConfig.disabled,
      isCancelled: () => false,
    );
    expect(checker.maxFileHandles, lessThanOrEqualTo(64));
  });

  test('queued image reads stop after cancellation', () async {
    final reader = _TrackingReader()..cancelAfterFirst = true;
    final outcome = await _scan(reader, 1);
    expect(reader.calls, 1);
    expect(outcome.cancelled, isTrue);
  });

  test('failed image reads release their permit', () async {
    final reader = _TrackingReader()..failFirst = true;
    final outcome = await _scan(reader, 2);
    expect(outcome.isSuccess, isTrue);
    expect(outcome.mod!.images.length, 11);
    expect(reader.calls, 12);
    expect(reader.peak, 2);
    expect(reader.active, 0);
    expect(outcome.logBuffer, isNot(contains('Waiting for file handles')));
  });

  test('invalid per-mod limits fail before opening any images', () async {
    final reader = _TrackingReader();
    final outcome = await _scan(reader, 0);
    expect(outcome.isFailure, isTrue);
    expect(reader.calls, 0);
    expect(outcome.errorMessage, contains('maxFileHandles'));
  });

  test('a one-handle scan budget reduces the real worker pool', () async {
    final root = await Directory.systemTemp.createTemp('scan_workers_');
    try {
      final variants = <ModVariant>[];
      final png = img.encodePng(img.Image(width: 16, height: 16));
      for (var i = 0; i < 4; i++) {
        final folder = Directory('${root.path}/mod$i');
        final graphics = await Directory('${folder.path}/graphics')
            .create(recursive: true);
        await File('${graphics.path}/sprite.png').writeAsBytes(png);
        variants.add(
          ModVariant(
            modInfo: ModInfo(id: 'mod$i', name: 'Mod $i'),
            versionCheckerInfo: null,
            modFolder: folder,
            hasNonBrickedModInfo: true,
            gameCoreFolder: root,
          ),
        );
      }
      for (final multithreaded in [false, true]) {
        final messages = <String>[];
        final checker = VramChecker(
          variantsToCheck: variants,
          showGfxLibDebugOutput: false,
          showPerformance: false,
          showSkippedFiles: false,
          showCountedFiles: false,
          graphicsLibConfig: GraphicsLibConfig.disabled,
          maxFileHandles: 1,
          multithreaded: multithreaded,
          isCancelled: () => false,
          infoOut: messages.add,
        );
        final mods = await checker.check();
        expect(mods.length, 4);
        expect(mods.every((mod) => mod.images.length == 1), isTrue);
        if (multithreaded) {
          expect(
            messages,
            contains('VRAM scan workers: 1, image reads per worker: 1'),
          );
        }
      }
    } finally {
      await root.delete(recursive: true);
    }
  });
}
