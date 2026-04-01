import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'log_aware_intent.dart';

/// Tells the user where their log file is located.
class LogLocationIntent extends ChatIntent with LogAwareIntent {
  @override
  final Ref ref;

  LogLocationIntent(this.ref);

  static const _phrases = [
    'log path',
    'log file',
    'log location',
    'where is log',
    'where is my log',
    'find log',
    'starsector.log',
    'open log',
  ];

  static const _primaryKeywords = {
    'path': 0.4,
    'location': 0.4,
    'where': 0.35,
    'find': 0.3,
  };

  static const _secondaryKeywords = {
    'log': 0.2,
    'file': 0.1,
    'starsector': 0.1,
  };

  @override
  String get id => 'log_location';

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

    return score.clamp(0.0, 0.95);
  }

  @override
  ChatResponse respond(String input, ConversationContext context) {
    final chips = logChips;
    if (chips?.filepath != null) {
      return ChatResponse(text: 'Your log file is at:\n${chips!.filepath}');
    }

    return const ChatResponse(
      text: LogAwareIntent.noLogMessage,
    );
  }
}
