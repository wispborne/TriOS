// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/logging.dart';

void main() {
  test('problem comparisons', () {
    final correctPairs = [
      ['1.9.0', '1.9.g'],
      ['1.9.g', '1.9.1'],
      ['0.5.1', '0.5.3rc1'],
      ['1.0', '1.00'],
      ['1.6.1-0.96a', '1.6.1c'],
      ['2.5 Gramada', '2.5.2'],
      ['1.1.0', '1.1.b'],
      ['1.12.SSS', '1.12.1'],
      ['0.14.5b', '0.15'],
    ];

    for (final pair in correctPairs) {
      final a = Version.parse(pair[0], sanitizeInput: false);
      final b = Version.parse(pair[1], sanitizeInput: false);
      final result = a.compareTo(b);
      expect(result, -1);
    }
  });

  test('sort versions', () {
    const iterations = 50;
    final versions = _expectedList
        .map((v) => Version.parse(v, sanitizeInput: true))
        .toList();

    for (int i = 0; i < iterations; i++) {
      final sorted = versions.toList()
        ..shuffle()
        ..sort((a, b) => a.compareTo(b));
      expect(sorted, versions);
    }
  });

  test('benchmark', () {
    // Disable slow console log output
    configureLogging(consoleOnly: true);

    final iterations = 1000;
    final versions = _expectedList
        .map((v) => Version.parse(v, sanitizeInput: true))
        .toList();

    final start = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < iterations; i++) {
      final sorted = versions.toList()
        ..shuffle()
        ..sort((a, b) => a.compareTo(b));
    }
    final end = DateTime.now().millisecondsSinceEpoch;
    final duration = end - start;
    print(
      'Sorting ${versions.length} items $iterations times took $duration ms',
    );
  });
}

final _expectedList = [
  "0.0.1",
  "0.0.3",
  "0.0.4a",
  "0.0.4b",
  "0.0.4e",
  "0.0.4f",
  "0.1",
  "0.1.0",
  "0.1.1",
  "0.1.4",
  "0.1.5",
  "0.1.98.1a",
  "0.1b",
  "0.2.0",
  "0.2.9k",
  "0.3.1",
  "0.3.5",
  "0.3.5h",
  "0.3.5i",
  "0.3.7b",
  "0.3a",
  "0.4.0",
  "0.4.1",
  "0.4.1c",
  "0.4.2",
  "0.4.2a",
  "0.4.2c",
  "0.4.3",
  "0.5.0-RC1",
  "0.5.0",
  "0.5.0a",
  "0.5.0d",
  "0.5.0f",
  "0.5.0g",
  "0.5.1",
  "0.5.1a",
  "0.5.3rc1",
  "0.5.3rc1-wisp",
  "0.6.0d",
  "0.6.1c",
  "0.6.2d",
  "0.6.4.1",
  "0.6.5",
  "0.6.5d",
  "0.6.7",
  "0.6.8",
  "0.6.10",
  "0.7.2",
  "0.7.4a",
  "0.7.4d",
  "0.7.5a",
  "0.7.5b",
  "0.7.5c",
  "0.7.5c-rewritten-001",
  "0.9.6-rc1-Wisp-005",
  "0.10.1",
  "0.11.1",
  "0.11.1x",
  "0.11.2",
  "0.11.2b",
  "0.11.2c",
  "0.13.0",
  "0.13.2",
  "0.13.2a",
  "0.14.1b",
  "0.14.2",
  "0.16.1",
  "0.17rc1",
  "0.96a",
  "0.99-RC5",
  "0.99F",
  "versions are for suckers",
  "1.0.0Beta6",
  "1.0.0rc2",
  "1.0",
  "1.00",
  "1.0.0",
  "1.0.0b",
  "1.0.1",
  "1.0.3",
  "1.0.4",
  "1.0.5",
  "1.0.7",
  "1.01",
  "1.1.0",
  "1.1.b",
  "1.1.1",
  "1.1.1h",
  "1.1.2",
  "1.1.3",
  "1.2.0",
  "1.2.1",
  "1.2.2",
  "1.2.3",
  "1.2.4",
  "1.2.5",
  "1.2.6",
  "1.2.7",
  "1.2.10",
  "1.2.12",
  "1.2b",
  "1.2e",
  "1.3",
  "1.3.0",
  "1.3.2",
  "1.3.3",
  "1.3c",
  "1.4",
  "1.4.3",
  "1.4.5",
  "1.4.6",
  "1.4b",
  "1.5",
  "1.5.3",
  "1.5.5",
  "1.5.6",
  "1.5.7",
  "1.6.0",
  "1.6.1",
  "1.6.1-0.96a",
  "1.6.1c",
  "1.6.2",
  "1.6.3",
  "1.6.3a",
  "1.6.5",
  "1.6b",
  "1.6c",
  "1.7.0",
  "1.7.1",
  "1.7.2",
  "1.7.3",
  "1.7.4",
  "1.7.5",
  "1.8.0",
  "1.8.1",
  "1.8.2",
  "1.8.3",
  "1.8.4",
  "1.8.5",
  "1.09",
  "1.9",
  "1.9.0",
  "1.9.gg",
  "1.9.ggg",
  "1.9.gggg",
  "1.9.ggggggg",
  "1.9.2",
  "1.9.3",
  "1.9.5",
  "1.10.2",
  "1.11",
  "1.12.0",
  "1.12.SSS",
  "1.12.1",
  "1.12.4",
  "1.13.0",
  "1.13.SSS",
  "1.13.2",
  "1.14.0",
  "1.14.1",
  "1.15.1",
  "1.17.1",
  "1.18.3ad",
  "1.18.3ae",
  "1.18.3aj",
  "1.41rc2",
  "002",
  "2.0.0",
  "2.0.c",
  "2.0.e",
  "2.0.3",
  "2.0.4",
  "2.0.8-Part1",
  "2.0.9",
  "2.1.0",
  "2.1.8",
  "2.2",
  "2.2.0",
  "2.2.1",
  "2.3.0",
  "2.3.1",
  "2.3.2",
  "2.4.0",
  "2.4.2",
  "2.4.6",
  "2.5 Gramada",
  "2.5.2",
  "2.6.2c",
  "2.6.2e",
  "2.6.4",
  "2.7.0rc3",
  "2.8",
  "2.8b",
  "2.64",
  "3.0",
  "3.0.5",
  "3.0.6.1",
  "3.0.9",
  "3.1.3",
  "3.2.c UNOFFICIAL",
  "3.2.1",
  "3.3.c-wisp001",
  "3.3.5",
  "3.3.6",
  "3.3.7",
  "4.0.0",
  "4.0.2",
  "4.1.0",
  "4.3.2",
  "4.4.0",
  "4.4.1",
  "5.1.0",
  "5.1.1",
  "5.2.0",
  "5.3.3",
  "5.4.0",
  "5.4.1",
  "6.2.1",
  "6.2.3",
  "8.4.5",
  "2021.4.10",
  "2023.5.05",
];
