import 'package:flutter_test/flutter_test.dart';
import 'package:trios/vram_estimator/vram_scan_file_budget.dart';

void main() {
  test('parses the soft open-file limit rather than the hard limit', () {
    expect(
      VramScanFileBudget.parseSoftLimit(
        'Limit                     Soft Limit           Hard Limit           Units\n'
        'Max open files            1024                 524288               files\n',
      ),
      1024,
    );
    expect(
      VramScanFileBudget.parseSoftLimit(
        'Max open files            unlimited            unlimited            files\n',
      ),
      isNull,
    );
    expect(VramScanFileBudget.parseSoftLimit('unavailable'), isNull);
  });

  test('caps oversized requests even when the OS limit is unavailable', () {
    expect(VramScanFileBudget(requestedMax: 8000).maxFileHandles, 64);
    expect(VramScanFileBudget(requestedMax: 8).maxFileHandles, 8);
  });

  test('leaves reserved capacity when the process is near its limit', () {
    final budget = VramScanFileBudget(softLimit: 128, openFileHandles: 48);
    expect(budget.maxFileHandles, 16);
  });

  test('refuses scanning when there is no room beyond the reserve', () {
    expect(
      () => VramScanFileBudget(softLimit: 128, openFileHandles: 64),
      throwsA(isA<VramScanFileLimitException>()),
    );
    expect(
      () => VramScanFileBudget(softLimit: 32, openFileHandles: 40),
      throwsA(isA<VramScanFileLimitException>()),
    );
  });

  test('rejects non-positive requested budgets', () {
    expect(() => VramScanFileBudget(requestedMax: 0), throwsRangeError);
    expect(() => VramScanFileBudget(requestedMax: -1), throwsRangeError);
  });

  test('all workers together stay within the scan budget', () {
    for (final capacity in [1, 2, 3, 5, 16, 63, 64]) {
      final budget = VramScanFileBudget(requestedMax: capacity);
      for (
        var requestedWorkers = 1;
        requestedWorkers <= 4;
        requestedWorkers++
      ) {
        final workers = budget.workerCount(requestedWorkers);
        final reads = budget.handlesPerWorker(requestedWorkers);
        expect(workers, inInclusiveRange(1, requestedWorkers));
        expect(reads, greaterThanOrEqualTo(1));
        expect(workers * reads, lessThanOrEqualTo(capacity));
      }
    }
  });
}
