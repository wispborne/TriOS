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

  static const _response = "Here's what I can help with:\n"
      '\n'
      'Mods\n'
      '  "find mod <name>" — search for a mod\n'
      '  "enabled mods" — list active mods\n'
      '  "mod updates" — check for updates\n'
      '  "mod compatibility" — find issues\n'
      '  "mods by <author>" — filter by author\n'
      '  "mod categories" — browse by category\n'
      '  "mod tips" — show gameplay tips\n'
      '\n'
      'Game Info\n'
      '  "game version" — detected Starsector version\n'
      '  "how many ships/weapons/hullmods" — content counts\n'
      '  "portrait stats" — portrait breakdown\n'
      '\n'
      'Configuration\n'
      '  "current ram" — RAM allocation\n'
      '  "vram estimate" — VRAM usage\n'
      '  "jre info" — Java runtime details\n'
      '  "game folder" — folder paths\n'
      '  "my settings" — current settings\n'
      '  "list profiles" — mod profiles\n'
      '\n'
      'Log Analysis\n'
      '  "log summary" — overview of your log file\n'
      '  "log errors" — errors found in log\n'
      '\n'
      'Troubleshooting\n'
      '  "troubleshooting" — common issues & fixes\n'
      '  "permission issues" — file permission help\n'
      '\n'
      'Other\n'
      '  "trios version" — app version\n'
      '  "is game running" — game process status\n'
      '  "navigate to <page>" — find a page';
}
