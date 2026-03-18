enum MessageSender { user, bot }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

class ConversationContext {
  final List<ChatMessage> history;
  final String? lastMatchedIntentId;
  final int turnCount;
  final Map<String, dynamic> memory;

  const ConversationContext({
    this.history = const [],
    this.lastMatchedIntentId,
    this.turnCount = 0,
    this.memory = const {},
  });

  ConversationContext copyWith({
    List<ChatMessage>? history,
    String? lastMatchedIntentId,
    int? turnCount,
    Map<String, dynamic>? memory,
  }) {
    return ConversationContext(
      history: history ?? this.history,
      lastMatchedIntentId: lastMatchedIntentId ?? this.lastMatchedIntentId,
      turnCount: turnCount ?? this.turnCount,
      memory: memory ?? this.memory,
    );
  }
}

class ChatResponse {
  final String text;
  final Map<String, dynamic>? memoryUpdates;

  const ChatResponse({
    required this.text,
    this.memoryUpdates,
  });
}
