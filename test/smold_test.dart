// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:trios/models/mod_variant.dart';
import 'package:trios/models/version.dart';
import 'package:trios/utils/extensions.dart';

void main() {
  group('SmolId Algorithm Tests', () {
    // Test data
    final testCases = [
      ('MagicLib', Version.parse('1.4.6'), 'MagicL-1.4.6-775351590'),
      ('GraphicsLib', Version.parse('1.12.0'), 'Graphi-1.12.0-1433169229'),
      ('Some@Mod!Name', Version.parse('2.1.0-RC1'), 'SomeMo-2.1.0-RC1-1032567945'),
      ('', Version.parse('1.0.0'), '-1.0.0-1048947338'),
      (
        'VeryLongModNameThatExceedsLimit',
        Version.parse('10.20.30'),
        'VeryLo-10.20.30-1322163111',
      ),
    ];

    test('Original Algorithm - Correctness', () {
      for (final (id, version, expected) in testCases) {
        final result = _createSmolIdOriginal(id, version);
        expect(result, equals(expected),
            reason: 'Failed for id="$id", version="$version"');
      }
    });

    test('Optimized Algorithm - Correctness', () {
      for (final (id, version, expected) in testCases) {
        final result = _createSmolIdOptimized(id, version);
        expect(result, equals(expected),
            reason: 'Failed for id="$id", version="$version"');
      }
    });

    test('Performance Comparison - Original vs Optimized', () {
      const iterations = 10000000;
      final id = 'MagicLib';
      final version = Version.parse('1.4.6');

      final originalSw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        _createSmolIdOriginal(id, version);
      }
      originalSw.stop();

      final optimizedSw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        _createSmolIdOptimized(id, version);
      }
      optimizedSw.stop();

      print('Original Algorithm - $iterations iterations: ${originalSw.elapsed}');
      print('Optimized Algorithm - $iterations iterations: ${optimizedSw.elapsed}');

      final orig = originalSw.elapsedMicroseconds;
      final opt = optimizedSw.elapsedMicroseconds;
      expect(opt, lessThan(orig), reason: 'Optimized should be faster than original');

      final improvement = ((orig - opt) / orig) * 100;
      print('Optimized version was ${improvement.toStringAsFixed(2)}% faster than the original');
    });


    // test('Original Algorithm - Performance', () {
    //   const iterations = 100000;
    //   final id = 'MagicLib';
    //   final version = Version.parse('1.4.6');
    //
    //   final stopwatch = Stopwatch()..start();
    //
    //   for (var i = 0; i < iterations; i++) {
    //     _createSmolIdOriginal(id, version);
    //   }
    //
    //   stopwatch.stop();
    //   print(
    //     'Original Algorithm - $iterations iterations: ${stopwatch.elapsed}',
    //   );
    //
    //   // Sanity check - should complete within reasonable time
    //   expect(
    //     stopwatch.elapsedMilliseconds,
    //     lessThan(10000),
    //     reason: 'Original algorithm should complete within 10 seconds',
    //   );
    // });
    //
    // test('Optimized Algorithm - Performance', () {
    //   const iterations = 100000;
    //   final id = 'MagicLib';
    //   final version = Version.parse('1.4.6');
    //
    //   final stopwatch = Stopwatch()..start();
    //
    //   for (var i = 0; i < iterations; i++) {
    //     _createSmolIdOptimized(id, version);
    //   }
    //
    //   stopwatch.stop();
    //   print(
    //     'Optimized Algorithm - $iterations iterations: ${stopwatch.elapsed}',
    //   );
    //
    //   // Should be faster than original algorithm
    //   expect(
    //     stopwatch.elapsedMilliseconds,
    //     lessThan(5000),
    //     reason: 'Optimized algorithm should complete within 5 seconds',
    //   );
    // });
  });
}

// Original algorithm implementation
String _createSmolIdOriginal(String id, Version? version) {
  return '${id.replaceAll(smolIdAllowedChars, '').take(6)}-${version.toString().replaceAll(smolIdAllowedChars, '').take(9)}-${(id.hashCode + version.hashCode).abs()}';
}

String _createSmolIdOptimized(String id, Version? version) {
  final v = version.toString();
  final a = id.replaceAll(smolIdAllowedChars, '').take(6);
  final b = v.replaceAll(smolIdAllowedChars, '').take(9);
  final h = (id.hashCode + version.hashCode).abs();
  return '$a-$b-$h';
}