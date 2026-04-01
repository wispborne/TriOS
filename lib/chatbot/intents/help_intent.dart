import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Lists all question categories the chatbot can answer.
class HelpIntent extends ChatIntent {
  static const _phrases = [
    'help',
    'what can you do',
    'what do you know',
    'what can i ask',
    'how to use chatbot',
    'what to ask',
    'what can you help with',
    'what questions',
    'what should i ask',
  ];

  static const _primaryKeywords = {
    'help': 0.55,
    'commands': 0.5,
  };

  static const _secondaryKeywords = {
    'can': 0.1,
    'ask': 0.1,
    'what': 0.1,
    'use': 0.1,
    'you': 0.1,
  };

  @override
  String get id => 'help';

  @override
  double match(String input, ConversationContext context) {
    return ModAwareIntent.scoreInput(
      input,
      _phrases,
      _primaryKeywords,
      _secondaryKeywords,
    );
  }

  @override
  ChatResponse respond(String input, ConversationContext context) {
    return const ChatResponse(text: _response);
  }

  static const _response =
      "Hey! I'm the TriOS assistant. I can help you with a bunch of things "
      "— just ask me naturally and I'll do my best to figure out what you need.\n"
      '\n'
      "Here are some of the things I know about:\n"
      '\n'
      '• Mods — finding mods, checking which are enabled, looking for '
      'updates, compatibility issues, browsing by author or category, '
      'context menu actions, color tags, and tips\n'
      '• Game info — your Starsector version, content counts (ships, '
      'weapons, hullmods), and portrait stats\n'
      '• Configuration — RAM and VRAM, game folder paths, '
      'your settings, and mod profiles\n'
      '• Log analysis — summarizing your log file or pulling out errors\n'
      '• Troubleshooting — common issues, fixes, and file permission problems\n'
      '• Other — TriOS version, whether the game is running, '
      'exporting data to CSV, and navigating to different pages\n'
      '\n'
      "You don't need to use exact commands — just describe what you're "
      "looking for and I'll take it from there!";
}
