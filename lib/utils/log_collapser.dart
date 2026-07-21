import 'package:trios/utils/logging.dart';

/// Collapses repeated warnings into a single log line.
///
/// Identical messages are counted and printed once with `(xN)`. Distinct
/// messages are capped at [_lineCap]. Call [flush] when the run finishes.
class LogCollapser {
  final _counts = <String, int>{};

  /// How many distinct messages to print before summarising the rest.
  static const _lineCap = 30;

  void add(String message) =>
      _counts.update(message, (n) => n + 1, ifAbsent: () => 1);

  /// Logs a warning summarizing everything gathered, or nothing if empty.
  ///
  /// [label] prefixes the count (e.g. "Merging weapons: 12 issues.").
  void flush(String label, {String noun = 'issue'}) {
    if (_counts.isEmpty) return;

    final total = _counts.values.fold(0, (sum, n) => sum + n);
    final entries = _counts.entries.toList();
    final buffer = StringBuffer(
      '$label: $total ${total == 1 ? noun : '${noun}s'}.',
    );
    for (final entry in entries.take(_lineCap)) {
      final prefix = entry.value > 1 ? '(x${entry.value}) ' : '';
      buffer.write('\n  • $prefix${entry.key}');
    }
    if (entries.length > _lineCap) {
      buffer.write('\n  …and ${entries.length - _lineCap} more.');
    }
    Fimber.w(buffer.toString());
  }
}
