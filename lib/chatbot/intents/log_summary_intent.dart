import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'log_aware_intent.dart';

/// Shows a summary of the parsed log file: game version, OS, Java,
/// mod count, error count, file path, and last-updated time.
class LogSummaryIntent extends ChatIntent with LogAwareIntent {
  @override
  final Ref ref;

  LogSummaryIntent(this.ref);

  static const _phrases = [
    'log summary',
    'log info',
    'log status',
    'log overview',
    'analyze log',
    'check log',
    'read log',
    'show log',
    "what's in my log",
    'whats in my log',
  ];

  static const _primaryKeywords = {
    'summary': 0.45,
    'overview': 0.45,
    'analyze': 0.4,
    'status': 0.35,
    'info': 0.3,
  };

  static const _secondaryKeywords = {
    'log': 0.15,
    'show': 0.1,
    'check': 0.1,
    'read': 0.1,
    'what': 0.1,
  };

  @override
  String get id => 'log_summary';

  @override
  double match(String input, ConversationContext context) {
    // Phrase match — high confidence.
    for (final phrase in _phrases) {
      if (input.contains(phrase)) return 0.85;
    }

    var score = 0.0;
    for (final entry in _primaryKeywords.entries) {
      if (input.contains(entry.key)) score += entry.value;
    }
    for (final entry in _secondaryKeywords.entries) {
      if (input.contains(entry.key)) score += entry.value;
    }

    return score.clamp(0.0, 0.95);
  }

  @override
  ChatResponse respond(String input, ConversationContext context) {
    final chips = logChips;
    if (chips == null) {
      return const ChatResponse(text: LogAwareIntent.noLogMessage);
    }

    final modCount = chips.modList.modList.length;
    final errorCount = chips.errorBlock.length;
    final updated = chips.lastUpdated != null
        ? DateFormat.yMMMd().add_jm().format(chips.lastUpdated!)
        : 'unknown';

    final buf = StringBuffer('Log Summary\n');
    buf.writeln('───────────');
    buf.writeln('Game version: ${chips.gameVersion ?? 'unknown'}');
    buf.writeln('OS: ${chips.os ?? 'unknown'}');
    buf.writeln('Java: ${chips.javaVersion ?? 'unknown'}');
    buf.writeln('Mods loaded: $modCount');
    buf.writeln('Errors found: $errorCount');
    if (chips.filepath != null) {
      buf.writeln('Log file: ${chips.filepath}');
    }
    buf.write('Last updated: $updated');

    return ChatResponse(text: buf.toString());
  }
}
