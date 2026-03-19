import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/chipper/models/error_lines.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'log_aware_intent.dart';

/// Lists errors found in the parsed log file, up to a cap.
class LogErrorsIntent extends ChatIntent with LogAwareIntent {
  @override
  final Ref ref;

  LogErrorsIntent(this.ref);

  static const _maxErrors = 10;

  static const _phrases = [
    'log errors',
    'show errors',
    'list errors',
    'what errors',
    'any errors',
    'what went wrong',
    'what crashed',
    'show crashes',
    'any crashes',
    'any exceptions',
  ];

  static const _primaryKeywords = {
    'errors': 0.5,
    'error': 0.5,
    'crashes': 0.45,
    'crash': 0.45,
    'exceptions': 0.45,
    'exception': 0.45,
    'problems': 0.4,
    'wrong': 0.35,
  };

  static const _secondaryKeywords = {
    'log': 0.1,
    'show': 0.1,
    'list': 0.1,
    'what': 0.1,
    'any': 0.1,
  };

  @override
  String get id => 'log_errors';

  @override
  double match(String input, ConversationContext context) {
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

    // Context bonus: user just saw a summary and is likely drilling in.
    if (context.lastMatchedIntentId == 'log_summary' && score > 0.0) {
      score += 0.15;
    }

    return score.clamp(0.0, 0.95);
  }

  @override
  ChatResponse respond(String input, ConversationContext context) {
    final chips = logChips;
    if (chips == null) {
      return const ChatResponse(text: LogAwareIntent.noLogMessage);
    }

    final errors = chips.errorBlock;
    if (errors.isEmpty) {
      return const ChatResponse(text: 'No errors found in the log. Looks good!');
    }

    final buf = StringBuffer('Found ${errors.length} error line(s) in the log.\n');

    final display = errors.take(_maxErrors);
    for (final line in display) {
      final text = _errorText(line);
      buf.writeln('  Line ${line.lineNumber}: $text');
    }

    if (errors.length > _maxErrors) {
      buf.write(
        '\n...and ${errors.length - _maxErrors} more. '
        'Open the Log Viewer (Chipper) for the full list.',
      );
    }

    return ChatResponse(text: buf.toString());
  }

  String _errorText(LogLine line) {
    if (line is GeneralErrorLogLine) {
      return line.error ?? line.fullError;
    }
    if (line is StacktraceLogLine) {
      final method = line.method ?? '';
      final loc = line.classAndLine ?? '';
      return 'at ${line.namespace ?? ''}.$method($loc)';
    }
    return line.fullError;
  }
}
