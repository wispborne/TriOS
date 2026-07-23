import 'package:trios/utils/logging.dart';

/// Collapses repeated warnings into a single log line.
///
/// Identical messages are counted and printed once with `(xN)`. Distinct
/// messages are capped at [_lineCap]. Call [flush] when the run finishes.
class LogCollapser {
  final _counts = <String, int>{};

  /// How many distinct messages to print before summarising the rest.
  static const _lineCap = 30;

  /// The last few messages logged under each label, newest first. A merge that
  /// re-runs and finds the same problems says nothing the second time.
  ///
  /// It's a short list rather than a single entry because the same merge often
  /// runs under more than one setting (for example, all mods versus only
  /// enabled mods), so a couple of different messages take turns under one
  /// label.
  static final _recentByLabel = <String, List<String>>{};

  /// How many past messages to remember per label.
  static const _recentCap = 8;

  void add(String message) =>
      _counts.update(message, (n) => n + 1, ifAbsent: () => 1);

  /// Logs a warning summarizing everything gathered, or nothing if empty.
  ///
  /// Stays quiet if this exact summary was logged under [label] recently.
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

    final message = buffer.toString();
    final recent = _recentByLabel.putIfAbsent(label, () => <String>[]);
    if (recent.contains(message)) return;
    recent.insert(0, message);
    if (recent.length > _recentCap) recent.removeLast();

    Fimber.w(message);
  }

  /// Forgets what's already been logged, so the next [flush] speaks up again.
  /// For tests.
  static void resetRecent() => _recentByLabel.clear();
}
