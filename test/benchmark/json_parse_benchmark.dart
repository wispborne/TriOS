// Real-world benchmark for `parseJsonToMap()`.
//
// This file is deliberately NOT named `*_test.dart`, so `flutter test` skips
// it. Run it by naming it directly:
//
//   fvm flutter test test/benchmark/json_parse_benchmark.dart
//
// It walks a real Starsector install (game folder + every mod), reads every
// .json/.ship/.variant/.wpn/.skin/.faction/.system file, and parses them all.
//
// Options (all via --dart-define):
//   SS_PATH=<path>            game folder (default: the usual Windows path)
//   JSON_BENCH_MAX_FILES=N    only use the first N files found (0 = all)
//   JSON_BENCH_LOOPS=N        parse the whole corpus N times (default 1)
//   JSON_BENCH_TOP=N          how many slowest files to list (default 25)
//
// Example — quick run over 5000 files:
//   fvm flutter test test/benchmark/json_parse_benchmark.dart \
//     --dart-define=JSON_BENCH_MAX_FILES=5000

// The whole point of this file is to print a report.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:trios/starsector_json/starsector_json.dart';
import 'package:trios/utils/csv_parse_utils.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/logging.dart';

const String kGamePath = String.fromEnvironment(
  'SS_PATH',
  defaultValue: r'C:\Program Files (x86)\Fractal Softworks\Starsector',
);
const int kMaxFiles = int.fromEnvironment('JSON_BENCH_MAX_FILES');
const int kLoops = int.fromEnvironment('JSON_BENCH_LOOPS', defaultValue: 1);
const int kTopSlowest = int.fromEnvironment('JSON_BENCH_TOP', defaultValue: 25);

const _extensions = {
  '.json',
  '.ship',
  '.variant',
  '.wpn',
  '.skin',
  '.faction',
  '.system',
};

/// How much work a file needs, judged only from the outside so the report
/// stays honest no matter how `parseJsonToMap()` is written inside.
///
/// - [plainJson]: `jsonDecode` reads it as an object with no help.
/// - [needsRepair]: `jsonDecode` refuses it, but `parseJsonToMap()` copes.
///   This is the bucket worth optimising — it's where all the repair work is.
/// - [notAnObject]: valid JSON, but a list or a bare value, so there's no map
///   to return.
/// - [failed]: `parseJsonToMap()` throws.
enum ParsePath { plainJson, needsRepair, notAnObject, failed }

typedef CorpusFile = ({String path, String ext, String text});

void main() {
  late final List<CorpusFile> corpus;
  late final int totalBytes;

  setUpAll(() {
    // Files the parser can't read log their whole contents. With tens of
    // thousands of files that buries the report and skews the timings, so
    // route logging through the console logger and turn it off.
    didLoggingInitializeSuccessfully = true;
    Logger.level = Level.off;

    final root = Directory(kGamePath);
    if (!root.existsSync()) {
      throw StateError(
        'Starsector not found at $kGamePath.\n'
        'Point at your install with --dart-define=SS_PATH=<path>.',
      );
    }

    final files = <CorpusFile>[];
    var bytes = 0;
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final path = entity.path;
      final dot = path.lastIndexOf('.');
      if (dot < 0) continue;
      final ext = path.substring(dot).toLowerCase();
      if (!_extensions.contains(ext)) continue;

      // Same fallback the app uses: UTF-8, then Latin-1 for the mod files
      // that aren't valid UTF-8.
      String text;
      try {
        final raw = entity.readAsBytesSync();
        try {
          text = utf8.decode(raw);
        } on FormatException {
          text = latin1.decode(raw, allowInvalid: true);
        }
      } catch (_) {
        continue;
      }
      files.add((path: path, ext: ext, text: text));
      bytes += text.length;
      if (kMaxFiles > 0 && files.length >= kMaxFiles) break;
    }

    corpus = files;
    totalBytes = bytes;
    expect(corpus, isNotEmpty, reason: 'No json-ish files found under $root');
  });

  test('parseJsonToMap over the whole Starsector install', () {
    _printCorpusSummary(corpus, totalBytes);

    // Sort every file into a bucket once, untimed, so the timing report can
    // say where the cost actually lands.
    final paths = corpus.map((f) => _classify(f.text)).toList();
    _printPathBreakdown(corpus, paths);

    // Warm up: one full pass that we throw away.
    for (final f in corpus) {
      _tryParse(f.text);
    }

    final perFileUs = List<int>.filled(corpus.length, 0);
    final wall = Stopwatch()..start();
    for (var loop = 0; loop < kLoops; loop++) {
      for (var i = 0; i < corpus.length; i++) {
        final sw = Stopwatch()..start();
        _tryParse(corpus[i].text);
        sw.stop();
        perFileUs[i] += sw.elapsedMicroseconds;
      }
    }
    wall.stop();

    _printTimings(
      title: 'parseJsonToMap() on raw file text',
      corpus: corpus,
      paths: paths,
      perFileUs: perFileUs,
      wall: wall,
      totalBytes: totalBytes,
    );
  }, timeout: const Timeout(Duration(hours: 2)));

  test('removeJsonComments() + parseJsonToMap(), as the viewers call it', () {
    final cleaned = corpus
        .map(
          (f) => (
            path: f.path,
            ext: f.ext,
            text: CsvJsonParsingUtils.removeJsonComments(f.text),
          ),
        )
        .toList();
    final cleanedBytes = cleaned.fold(0, (sum, f) => sum + f.text.length);
    final paths = cleaned.map((f) => _classify(f.text)).toList();
    _printPathBreakdown(cleaned, paths);

    for (final f in cleaned) {
      _tryParse(f.text);
    }

    final perFileUs = List<int>.filled(cleaned.length, 0);
    final wall = Stopwatch()..start();
    for (var loop = 0; loop < kLoops; loop++) {
      for (var i = 0; i < cleaned.length; i++) {
        final sw = Stopwatch()..start();
        _tryParse(cleaned[i].text);
        sw.stop();
        perFileUs[i] += sw.elapsedMicroseconds;
      }
    }
    wall.stop();

    _printTimings(
      title: 'parseJsonToMap() after removeJsonComments()',
      corpus: cleaned,
      paths: paths,
      perFileUs: perFileUs,
      wall: wall,
      totalBytes: cleanedBytes,
    );
  }, timeout: const Timeout(Duration(hours: 2)));

  test('parseStarsectorJson(), the port of the game\'s own parser', () {
    _printCorpusSummary(corpus, totalBytes);

    // Bucketed the same way as the other runs, by how much work the *current*
    // parser needs, so the two timing reports line up column for column.
    final paths = corpus.map((f) => _classify(f.text)).toList();

    for (final f in corpus) {
      _tryParseStarsector(f.text);
    }

    final perFileUs = List<int>.filled(corpus.length, 0);
    final wall = Stopwatch()..start();
    for (var loop = 0; loop < kLoops; loop++) {
      for (var i = 0; i < corpus.length; i++) {
        final sw = Stopwatch()..start();
        _tryParseStarsector(corpus[i].text);
        sw.stop();
        perFileUs[i] += sw.elapsedMicroseconds;
      }
    }
    wall.stop();

    _printTimings(
      title: 'parseStarsectorJson() on raw file text',
      corpus: corpus,
      paths: paths,
      perFileUs: perFileUs,
      wall: wall,
      totalBytes: totalBytes,
    );
  }, timeout: const Timeout(Duration(hours: 2)));

  // The port is stricter than parseJsonToMap() on purpose — it rejects what the
  // game rejects. This says how much that costs in practice, and whether the
  // files both of them read come out the same.
  test('parseStarsectorJson() vs parseJsonToMap(): do they agree?', () {
    const sameValue = DeepCollectionEquality();
    var bothOk = 0;
    var bothFailed = 0;
    var onlyOldOk = 0;
    var onlyNewOk = 0;
    var different = 0;
    final onlyOldExamples = <String>[];
    final onlyNewExamples = <String>[];
    final differentExamples = <String>[];
    final newErrors = <String, int>{};

    for (final f in corpus) {
      Map<String, dynamic>? old;
      try {
        old = f.text.parseJsonToMap();
      } catch (_) {
        old = null;
      }

      Map<String, dynamic>? fresh;
      String? error;
      try {
        fresh = parseStarsectorJson(f.text);
      } catch (e) {
        error = e is StarsectorJsonException ? e.message : e.toString();
      }

      if (old == null && fresh == null) {
        bothFailed++;
      } else if (fresh == null) {
        onlyOldOk++;
        final reason = _errorKind(error!);
        newErrors[reason] = (newErrors[reason] ?? 0) + 1;
        if (onlyOldExamples.length < kTopSlowest) {
          onlyOldExamples.add('${_shortPath(f.path)}  --  $error');
        }
      } else if (old == null) {
        onlyNewOk++;
        if (onlyNewExamples.length < kTopSlowest) {
          onlyNewExamples.add(_shortPath(f.path));
        }
      } else if (sameValue.equals(old, fresh)) {
        bothOk++;
      } else {
        different++;
        if (differentExamples.length < kTopSlowest) {
          differentExamples.add(_shortPath(f.path));
        }
      }
    }

    print('');
    print('--- parseStarsectorJson() vs parseJsonToMap() ---');
    print('  files: ${corpus.length}');
    print('    same result             ${bothOk.toString().padLeft(7)}');
    print('    both refuse the file    ${bothFailed.toString().padLeft(7)}');
    print('    only parseJsonToMap     ${onlyOldOk.toString().padLeft(7)}'
        '   (the port is stricter here)');
    print('    only parseStarsectorJson${onlyNewOk.toString().padLeft(7)}');
    print('    both read it, values differ${different.toString().padLeft(4)}');

    if (newErrors.isNotEmpty) {
      final kinds = newErrors.keys.toList()
        ..sort((a, b) => newErrors[b]!.compareTo(newErrors[a]!));
      print('');
      print('  why the port refused files parseJsonToMap read:');
      for (final kind in kinds) {
        print('    ${newErrors[kind].toString().padLeft(7)}  $kind');
      }
    }
    _printExamples('files only parseJsonToMap could read', onlyOldExamples);
    _printExamples('files only the port could read', onlyNewExamples);
    _printExamples('files that came out different', differentExamples);
    print('');
  }, timeout: const Timeout(Duration(hours: 2)));

  test('removeHashComments() vs removeJsonComments()', () {
    for (final f in corpus) {
      removeHashComments(f.text);
    }
    final wall = Stopwatch()..start();
    for (var loop = 0; loop < kLoops; loop++) {
      for (final f in corpus) {
        removeHashComments(f.text);
      }
    }
    wall.stop();
    final seconds = wall.elapsedMicroseconds / 1000000;
    final mb = (totalBytes * kLoops) / (1024 * 1024);
    print('');
    print('--- removeHashComments() alone ---');
    print('  wall:       ${_ms(wall.elapsedMicroseconds)}');
    print('  throughput: ${(mb / seconds).toStringAsFixed(1)} MB/sec');
    print('');
  }, timeout: const Timeout(Duration(hours: 2)));

  test('removeJsonComments() on its own', () {
    for (final f in corpus) {
      CsvJsonParsingUtils.removeJsonComments(f.text);
    }
    final wall = Stopwatch()..start();
    for (var loop = 0; loop < kLoops; loop++) {
      for (final f in corpus) {
        CsvJsonParsingUtils.removeJsonComments(f.text);
      }
    }
    wall.stop();
    final seconds = wall.elapsedMicroseconds / 1000000;
    final mb = (totalBytes * kLoops) / (1024 * 1024);
    print('');
    print('--- removeJsonComments() alone ---');
    print('  wall:       ${_ms(wall.elapsedMicroseconds)}');
    print('  throughput: ${(mb / seconds).toStringAsFixed(1)} MB/sec');
    print('');
  }, timeout: const Timeout(Duration(hours: 2)));
}

/// Runs the real parser and swallows failures, so one bad file doesn't end
/// the run. Returns whether it produced a map.
bool _tryParse(String text) {
  try {
    text.parseJsonToMap();
    return true;
  } catch (_) {
    return false;
  }
}

/// Same as [_tryParse], for the port of the game's parser.
bool _tryParseStarsector(String text) {
  try {
    parseStarsectorJson(text);
    return true;
  } catch (_) {
    return false;
  }
}

/// Strips the position off a syntax error so the same complaint about different
/// files groups into one line in the report.
String _errorKind(String message) {
  final at = message.indexOf(' at ');
  return at < 0 ? message : message.substring(0, at);
}

void _printExamples(String title, List<String> examples) {
  if (examples.isEmpty) return;
  print('');
  print('  $title:');
  for (final example in examples) {
    print('    $example');
  }
}

/// Works out how much work a file needs, using only `jsonDecode` and the
/// public `parseJsonToMap()`. Nothing here reaches into how the repair is
/// done, so this keeps working if the repair is rewritten.
ParsePath _classify(String text) {
  try {
    final decoded = jsonDecode(text);
    return decoded is Map<String, dynamic>
        ? ParsePath.plainJson
        : ParsePath.notAnObject;
  } on FormatException {
    // Not JSON as written — see whether parseJsonToMap can repair it.
  }
  try {
    text.parseJsonToMap();
    return ParsePath.needsRepair;
  } catch (_) {
    return ParsePath.failed;
  }
}

void _printCorpusSummary(List<CorpusFile> corpus, int totalBytes) {
  final byExt = <String, ({int count, int bytes})>{};
  for (final f in corpus) {
    final prev = byExt[f.ext] ?? (count: 0, bytes: 0);
    byExt[f.ext] = (count: prev.count + 1, bytes: prev.bytes + f.text.length);
  }
  final exts = byExt.keys.toList()
    ..sort((a, b) => byExt[b]!.bytes.compareTo(byExt[a]!.bytes));

  print('');
  print('==================================================================');
  print(' corpus: $kGamePath');
  print('   files: ${corpus.length}   size: ${_mb(totalBytes)}'
      '   loops: $kLoops');
  for (final ext in exts) {
    print('     ${ext.padRight(10)} ${byExt[ext]!.count.toString().padLeft(7)}'
        ' files  ${_mb(byExt[ext]!.bytes).padLeft(10)}');
  }
  print('==================================================================');
}

void _printPathBreakdown(List<CorpusFile> corpus, List<ParsePath> paths) {
  final counts = <ParsePath, int>{};
  final bytes = <ParsePath, int>{};
  for (var i = 0; i < corpus.length; i++) {
    counts[paths[i]] = (counts[paths[i]] ?? 0) + 1;
    bytes[paths[i]] = (bytes[paths[i]] ?? 0) + corpus[i].text.length;
  }
  print('');
  print('  how much work each file needs:');
  for (final path in ParsePath.values) {
    final count = counts[path] ?? 0;
    final share = corpus.isEmpty ? 0.0 : 100 * count / corpus.length;
    print('    ${path.name.padRight(12)} ${count.toString().padLeft(7)} files'
        ' (${share.toStringAsFixed(1).padLeft(5)}%)'
        '  ${_mb(bytes[path] ?? 0).padLeft(10)}');
  }
}

void _printTimings({
  required String title,
  required List<CorpusFile> corpus,
  required List<ParsePath> paths,
  required List<int> perFileUs,
  required Stopwatch wall,
  required int totalBytes,
}) {
  final byPathUs = <ParsePath, int>{};
  for (var i = 0; i < corpus.length; i++) {
    byPathUs[paths[i]] = (byPathUs[paths[i]] ?? 0) + perFileUs[i];
  }
  final measuredUs = perFileUs.fold(0, (a, b) => a + b);

  print('');
  print('--- $title ---');
  print('  wall time:  ${_ms(wall.elapsedMicroseconds)}'
      '  (sum of per-file: ${_ms(measuredUs)})');
  final seconds = wall.elapsedMicroseconds / 1000000;
  final mb = (totalBytes * kLoops) / (1024 * 1024);
  final parses = corpus.length * kLoops;
  print('  throughput: ${(mb / seconds).toStringAsFixed(1)} MB/sec,'
      ' ${(parses / seconds).round()} files/sec');

  print('  time spent, split by how much work the file needed:');
  for (final path in ParsePath.values) {
    final us = byPathUs[path] ?? 0;
    final share = measuredUs == 0 ? 0.0 : 100 * us / measuredUs;
    print('    ${path.name.padRight(12)} ${_ms(us).padLeft(12)}'
        ' (${share.toStringAsFixed(1).padLeft(5)}%)');
  }

  final order = List.generate(corpus.length, (i) => i)
    ..sort((a, b) => perFileUs[b].compareTo(perFileUs[a]));
  print('  slowest $kTopSlowest files:');
  for (final i in order.take(kTopSlowest)) {
    final avgUs = perFileUs[i] / kLoops;
    print('    ${avgUs.toStringAsFixed(0).padLeft(9)} us'
        '  ${paths[i].name.padRight(10)}'
        '  ${_kb(corpus[i].text.length).padLeft(9)}'
        '  ${_shortPath(corpus[i].path)}');
  }
  print('');
}

String _shortPath(String path) {
  final parts = path.replaceAll('\\', '/').split('/');
  return parts.length <= 4 ? path : parts.sublist(parts.length - 4).join('/');
}

String _ms(int microseconds) =>
    '${(microseconds / 1000).toStringAsFixed(1)} ms';

String _kb(int bytes) => '${(bytes / 1024).toStringAsFixed(1)} KB';

String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
