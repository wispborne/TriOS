import 'chatbot_models.dart';

/// Base class for all chatbot intents.
///
/// To add a new intent:
/// 1. Create a class extending [ChatIntent]
/// 2. Implement [id], [match], and [respond]
/// 3. Register it in [ChatbotEngine]'s intent list
abstract class ChatIntent {
  /// Unique identifier for this intent (e.g., "greeting", "help").
  String get id;

  /// Returns a confidence score from 0.0 to 1.0 for how well [input] matches
  /// this intent. The [context] provides conversation history and memory for
  /// context-aware matching.
  ///
  /// Common strategies:
  /// - Keyword sets with weights
  /// - Regex patterns
  /// - Context bonuses (e.g., boost if following a related intent)
  double match(String input, ConversationContext context);

  /// Generates a response for the matched [input].
  ///
  /// Can return [ChatResponse.memoryUpdates] to persist state across turns
  /// (e.g., storing the user's name for later use).
  ChatResponse respond(String input, ConversationContext context);
}

class ChatbotEngine {
  final List<ChatIntent> _intents;

  /// The minimum confidence score an intent must achieve to be selected.
  /// Below this threshold, the fallback intent handles the input.
  static const double matchThreshold = 0.3;

  ChatbotEngine(this._intents);

  /// Processes [input] against all registered intents and returns the best
  /// matching response.
  ///
  /// 1. Normalizes input (lowercase, trim)
  /// 2. Scores every intent via [ChatIntent.match]
  /// 3. Picks the highest score (minimum [matchThreshold])
  /// 4. Tiebreaker: registration order (first wins)
  /// 5. Returns the winning intent's response
  ChatResponse process(String input, ConversationContext context) {
    final normalized = input.toLowerCase().trim();

    ChatIntent? bestIntent;
    double bestScore = -1;

    for (final intent in _intents) {
      final score = intent.match(normalized, context);
      if (score > bestScore) {
        bestScore = score;
        bestIntent = intent;
      }
    }

    if (bestIntent == null || bestScore < matchThreshold) {
      // Find fallback (lowest-priority intent that always matches).
      final fallback = _intents.where((i) => i.id == 'fallback').firstOrNull;
      if (fallback != null) {
        return fallback.respond(normalized, context);
      }
      return const ChatResponse(text: "...");
    }

    return bestIntent.respond(normalized, context);
  }

  /// The list of registered intents, for inspection/debugging.
  List<ChatIntent> get intents => List.unmodifiable(_intents);
}
