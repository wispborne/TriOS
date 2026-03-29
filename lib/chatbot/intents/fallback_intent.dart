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
    "I'm not sure what you mean. Try \"help\" to see what I can answer.",
    "I didn't catch that. You can ask about mods, RAM, VRAM, logs, or troubleshooting.",
    "Hmm, I don't have an answer for that. Try asking about mod updates, compatibility, or settings.",
    "Not sure about that one. Type \"help\" for a list of topics I know about.",
    "I couldn't match that to anything I know. Try rephrasing, or ask \"help\" for ideas.",
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
