import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/engine_overhead.dart';

void main() {
  group('engineOverheadBytes', () {
    test('GraphicsLib disabled returns ~10% of cache', () {
      const cacheBytes = 588800000; // ~588.8 MB (5-mod run)
      final overhead = engineOverheadBytes(
        estimatedCacheBytes: cacheBytes,
        graphicsLibEnabled: false,
      );
      expect(overhead, (cacheBytes * 0.10).round());
      // Should be near 58.88 MB
      expect(overhead, closeTo(58880000, 1));
    });

    test('GraphicsLib enabled returns 257 MB + ~10% of cache', () {
      const cacheBytes = 1019700000; // ~1,019.7 MB (10-mod run)
      final overhead = engineOverheadBytes(
        estimatedCacheBytes: cacheBytes,
        graphicsLibEnabled: true,
      );
      final expected =
          graphicsLibFixedOverheadBytes + (cacheBytes * 0.10).round();
      expect(overhead, expected);
    });

    test('5-mod measurement: GraphicsLib OFF, ~588.8 MB cache', () {
      // Actual overhead was 61.5 MB
      const cacheBytes = 588800000;
      final overhead = engineOverheadBytes(
        estimatedCacheBytes: cacheBytes,
        graphicsLibEnabled: false,
      );
      const actualOverhead = 61500000;
      expect((overhead - actualOverhead).abs(), lessThan(30000000));
    });

    test('10-mod measurement: GraphicsLib ON, ~1,019.7 MB cache', () {
      // Actual overhead was 355.5 MB
      const cacheBytes = 1019700000;
      final overhead = engineOverheadBytes(
        estimatedCacheBytes: cacheBytes,
        graphicsLibEnabled: true,
      );
      const actualOverhead = 355500000;
      expect((overhead - actualOverhead).abs(), lessThan(30000000));
    });

    test('17-mod measurement: GraphicsLib ON, ~1,852.5 MB cache', () {
      // Actual overhead was 436.3 MB
      const cacheBytes = 1852500000;
      final overhead = engineOverheadBytes(
        estimatedCacheBytes: cacheBytes,
        graphicsLibEnabled: true,
      );
      const actualOverhead = 436300000;
      expect((overhead - actualOverhead).abs(), lessThan(30000000));
    });

    test('zero cache returns zero when GraphicsLib disabled', () {
      final overhead = engineOverheadBytes(
        estimatedCacheBytes: 0,
        graphicsLibEnabled: false,
      );
      expect(overhead, 0);
    });

    test('zero cache returns fixed overhead when GraphicsLib enabled', () {
      final overhead = engineOverheadBytes(
        estimatedCacheBytes: 0,
        graphicsLibEnabled: true,
      );
      expect(overhead, graphicsLibFixedOverheadBytes);
    });
  });
}
