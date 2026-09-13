import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vram_scan_file_budget.dart';

/// Kept in memory so a failed scan remains visible without entering the cache.
final vramScanErrorProvider = NotifierProvider<VramScanErrorNotifier, String?>(
  VramScanErrorNotifier.new,
);

class VramScanErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void clear() => state = null;

  void report(Object error) {
    state = error is VramScanFileLimitException
        ? VramScanFileLimitException.message
        : 'The VRAM scan could not finish. See the TriOS log for details.';
  }
}
