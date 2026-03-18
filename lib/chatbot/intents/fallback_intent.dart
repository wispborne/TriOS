import 'dart:math';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';

/// Catch-all intent that handles any unrecognized input.
///
/// Always returns a low match score (0.1), so any real intent will
/// take priority. Serves as both the guaranteed floor and a template
/// for writing new intents.
class FallbackIntent extends ChatIntent {
  static final _random = Random();

  static const _responses = [
    "I'm not sure what you mean. Try something else?",
  ];

  @override
  String get id => 'fallback';

  @override
  double match(String input, ConversationContext context) => 0.1;

  @override
  ChatResponse respond(String input, ConversationContext context) {
    final text = _responses[_random.nextInt(_responses.length)];
    return ChatResponse(text: text);
  }
}
