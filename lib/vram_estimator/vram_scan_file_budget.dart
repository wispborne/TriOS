import 'dart:io';
import 'dart:math';

class VramScanFileLimitException implements Exception {
  static const message =
      'TriOS is too close to your system\'s open-file limit to scan safely. '
      'Try restarting TriOS. If that does not help, restart your computer.';

  final String? details;

  const VramScanFileLimitException([this.details]);

  @override
  String toString() => details == null ? message : '$message ($details)';
}

/// Limits image reads across all workers in one VRAM scan.
class VramScanFileBudget {
  static const defaultMaxFileHandles = 64;
  static const reservedFileHandles = 64;

  final int maxFileHandles;

  VramScanFileBudget({
    int requestedMax = defaultMaxFileHandles,
    int? softLimit,
    int openFileHandles = 0,
  }) : maxFileHandles = _calculate(requestedMax, softLimit, openFileHandles);

  static int _calculate(int requestedMax, int? softLimit, int openFileHandles) {
    if (requestedMax < 1) {
      throw RangeError.range(requestedMax, 1, null, 'requestedMax');
    }
    final cap = min(requestedMax, defaultMaxFileHandles);
    if (softLimit == null) return cap;
    final available = softLimit - openFileHandles - reservedFileHandles;
    if (available < 1) {
      throw VramScanFileLimitException(
        'Limit: $softLimit, open: $openFileHandles, '
        'reserved: $reservedFileHandles',
      );
    }
    return min(cap, available);
  }

  /// Null represents either an unlimited limit or unavailable diagnostics.
  static int? parseSoftLimit(String limits) {
    final match = RegExp(
      r'^Max open files\s+(\d+|unlimited)\s+',
      multiLine: true,
    ).firstMatch(limits);
    return int.tryParse(match?.group(1) ?? '');
  }

  static Future<VramScanFileBudget> forCurrentProcess({
    int requestedMax = defaultMaxFileHandles,
  }) async {
    int? softLimit;
    var openFileHandles = 0;
    if (Platform.isLinux) {
      try {
        softLimit = parseSoftLimit(
          await File('/proc/self/limits').readAsString(),
        );
        if (softLimit != null) {
          await for (final _ in Directory('/proc/self/fd').list()) {
            openFileHandles++;
          }
        }
      } on FileSystemException catch (e) {
        if (e.osError?.errorCode == 24) {
          throw const VramScanFileLimitException();
        }
        // /proc can be unavailable in restricted environments.
        softLimit = null;
      }
    }
    return VramScanFileBudget(
      requestedMax: requestedMax,
      softLimit: softLimit,
      openFileHandles: openFileHandles,
    );
  }

  int workerCount(int requestedWorkers) {
    if (requestedWorkers < 1) {
      throw RangeError.range(requestedWorkers, 1, null, 'requestedWorkers');
    }
    return min(requestedWorkers, maxFileHandles);
  }

  int handlesPerWorker(int requestedWorkers) =>
      maxFileHandles ~/ workerCount(requestedWorkers);
}
