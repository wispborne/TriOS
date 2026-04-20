// Heavy benchmark for the Starsector json-ish parsing pipeline
// (`removeJsonComments()` -> `fixJson()` -> `jsonDecode`).
//
// Loop count is configurable at compile time:
//   flutter test test/fix_json_benchmark_test.dart --dart-define=JSON_BENCH_LOOPS=10    # smoke
//   flutter test test/fix_json_benchmark_test.dart --dart-define=JSON_BENCH_LOOPS=200   # default
//   flutter test test/fix_json_benchmark_test.dart --dart-define=JSON_BENCH_LOOPS=2000  # heavy
//
// Fixtures live in test/fixtures/json_ish/ and are copied from real Starsector
// mods. Mix of .ship/.skin/.variant/.wpn with clean JSON and semicolon-quirked
// files so the benchmark exercises both the fast path and the full rewrite.
//
// Reports a per-file breakdown (sorted slowest-first) and aggregate stats
// (files/sec, MB/sec) via `print` so results show up under `flutter test`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';

const int kDefaultLoops = 1000;
const int kWarmupLoops = 5;
const int kBenchLoops = int.fromEnvironment(
  'JSON_BENCH_LOOPS',
  defaultValue: kDefaultLoops,
);

void main() {
  late final Directory fixturesDir;
  late final Map<String, String> fixtures;
  late final int totalBytes;

  setUpAll(() {
    fixturesDir = Directory('test/fixtures/json_ish');
    expect(
      fixturesDir.existsSync(),
      isTrue,
      reason: 'Fixtures directory not found at ${fixturesDir.path}',
    );

    fixtures = {};
    var bytes = 0;
    for (final entity in fixturesDir.listSync()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final raw = entity.readAsStringSync();
      fixtures[name] = raw;
      bytes += raw.length;
    }
    totalBytes = bytes;

    expect(fixtures, isNotEmpty, reason: 'No fixture files loaded');
  });

  group('json-ish parse benchmark', () {
    test('produces valid maps for every fixture', () {
      final failures = <String, Object>{};
      fixtures.forEach((name, raw) {
        try {
          final map = raw.removeJsonComments().parseJsonToMap();
          expect(
            map,
            isNotEmpty,
            reason: '$name decoded to an empty map',
          );
        } catch (e) {
          failures[name] = e;
        }
      });
      expect(
        failures,
        isEmpty,
        reason: 'Fixtures failed to parse:\n'
            '${failures.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}',
      );
    });

    test(
      'parse pipeline (removeJsonComments + fixJson + jsonDecode)',
      () {
        final loops = kBenchLoops;
        final fileCount = fixtures.length;

        print('');
        print('==============================================================');
        print(' json-ish parse benchmark');
        print('   fixtures:  $fileCount  (${_fmtBytes(totalBytes)})');
        print('   warmup:    $kWarmupLoops iters');
        print('   loops:     $loops iters  (override with'
            ' --dart-define=JSON_BENCH_LOOPS=N)');
        print('==============================================================');

        // Warmup — discard timings so JIT + regex caches settle.
        for (var i = 0; i < kWarmupLoops; i++) {
          for (final raw in fixtures.values) {
            raw.removeJsonComments().parseJsonToMap();
          }
        }

        final perFile = <_FileStats>[];
        final overall = Stopwatch()..start();
        for (final entry in fixtures.entries) {
          final raw = entry.value;
          var minUs = 1 << 62;
          var maxUs = 0;
          final sw = Stopwatch()..start();
          for (var i = 0; i < loops; i++) {
            final iterSw = Stopwatch()..start();
            raw.removeJsonComments().parseJsonToMap();
            iterSw.stop();
            final us = iterSw.elapsedMicroseconds;
            if (us < minUs) minUs = us;
            if (us > maxUs) maxUs = us;
          }
          sw.stop();
          perFile.add(_FileStats(
            name: entry.key,
            bytes: raw.length,
            totalUs: sw.elapsedMicroseconds,
            minUs: minUs,
            maxUs: maxUs,
            loops: loops,
          ));
        }
        overall.stop();

        perFile.sort((a, b) => b.avgUs.compareTo(a.avgUs));

        print('');
        print(_row(
          'file',
          'bytes',
          'total ms',
          'avg us',
          'min us',
          'max us',
        ));
        print(_row('----', '-----', '--------', '------', '------', '------'));
        for (final s in perFile) {
          print(_row(
            s.name,
            s.bytes.toString(),
            s.totalMs.toStringAsFixed(1),
            s.avgUs.toStringAsFixed(1),
            s.minUs.toString(),
            s.maxUs.toString(),
          ));
        }

        final totalParses = loops * fileCount;
        final wallMs = overall.elapsedMicroseconds / 1000.0;
        final wallSec = wallMs / 1000.0;
        final parsesPerSec = wallSec > 0 ? totalParses / wallSec : 0;
        final mbProcessed = (totalBytes * loops) / (1024 * 1024);
        final mbPerSec = wallSec > 0 ? mbProcessed / wallSec : 0;

        print('');
        print('--- aggregate ---');
        print('   total parses:   $totalParses');
        print('   wall time:      ${wallMs.toStringAsFixed(1)} ms');
        print('   throughput:     ${parsesPerSec.toStringAsFixed(1)} parses/sec');
        print('   data scanned:   ${mbProcessed.toStringAsFixed(2)} MB'
            ' (${mbPerSec.toStringAsFixed(2)} MB/sec)');
        print('');
      },
      timeout: const Timeout(Duration(minutes: 30)),
    );
  });
}

class _FileStats {
  _FileStats({
    required this.name,
    required this.bytes,
    required this.totalUs,
    required this.minUs,
    required this.maxUs,
    required this.loops,
  });

  final String name;
  final int bytes;
  final int totalUs;
  final int minUs;
  final int maxUs;
  final int loops;

  double get avgUs => totalUs / loops;
  double get totalMs => totalUs / 1000.0;
}

String _fmtBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

String _row(
  String a,
  String b,
  String c,
  String d,
  String e,
  String f,
) {
  String pad(String s, int w, {bool right = false}) =>
      right ? s.padLeft(w) : s.padRight(w);
  return '  ${pad(a, 46)}  ${pad(b, 8, right: true)}'
      '  ${pad(c, 10, right: true)}  ${pad(d, 10, right: true)}'
      '  ${pad(e, 8, right: true)}  ${pad(f, 8, right: true)}';
}
