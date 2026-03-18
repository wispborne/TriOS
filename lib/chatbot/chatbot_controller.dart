import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chatbot_engine.dart';
import 'chatbot_models.dart';
import 'intents/fallback_intent.dart';

final chatbotControllerProvider =
    AutoDisposeNotifierProvider<ChatbotController, ConversationContext>(
      () => ChatbotController(),
    );

class ChatbotController extends AutoDisposeNotifier<ConversationContext> {
  static ConversationContext _persisted = const ConversationContext();

  late final ChatbotEngine _engine;

  @override
  ConversationContext build() {
    _engine = ChatbotEngine([
      // Register intents here. Order matters for tiebreaking.
      // Higher-priority intents should come first.
      FallbackIntent(),
    ]);

    return _persisted;
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    final updatedHistory = [...state.history, userMessage];
    final contextForEngine = state.copyWith(history: updatedHistory);

    final response = _engine.process(text, contextForEngine);

    final botMessage = ChatMessage(
      text: response.text,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );

    final newMemory = {
      ...state.memory,
      if (response.memoryUpdates != null) ...response.memoryUpdates!,
    };

    state = state.copyWith(
      history: [...updatedHistory, botMessage],
      lastMatchedIntentId: _lastMatchedId(text, contextForEngine),
      turnCount: state.turnCount + 1,
      memory: newMemory,
    );
    _persisted = state;
  }

  String? _lastMatchedId(String input, ConversationContext context) {
    final normalized = input.toLowerCase().trim();
    String? bestId;
    double bestScore = -1;

    for (final intent in _engine.intents) {
      final score = intent.match(normalized, context);
      if (score > bestScore) {
        bestScore = score;
        bestId = intent.id;
      }
    }

    return bestScore >= ChatbotEngine.matchThreshold ? bestId : 'fallback';
  }

  void clear() {
    state = const ConversationContext();
    _persisted = state;
  }
}
