import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Directs users to the Catalog page to find and download mods.
class FindModsIntent extends ChatIntent {
  static const _phrases = [
    'where to find mods',
    'where to get mods',
    'where to download mods',
    'where can i find mods',
    'where can i get mods',
    'where can i download mods',
    'how to get mods',
    'how to download mods',
    'how to install new mods',
    'where do i get mods',
    'where do i find mods',
    'browse mods',
    'mod catalog',
    'mod browser',
    'open catalog',
    'show catalog',
    'go to catalog',
    'find new mods',
    'get new mods',
    'download mods',
    'install mods',
  ];

  static const _primaryKeywords = {
    'catalog': 0.55,
    'download': 0.45,
    'browse': 0.45,
    'get mods': 0.5,
    'get more mods': 0.5,
    'install new': 0.45,
    'mod browser': 0.5,
  };

  static const _secondaryKeywords = {
    'where': 0.15,
    'how': 0.1,
    'mods': 0.1,
    'new': 0.1,
    'more': 0.1,
  };

  @override
  String get id => 'find_mods';

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

  static const _response = 'Finding New Mods\n'
      '\n'
      'TriOS has a built-in Catalog page! Click "Catalog" in the sidebar\n'
      'to browse, search, and install mods directly.\n'
      '\n'
      'The Catalog lets you:\n'
      '  Browse all available mods\n'
      '  Filter by category and game version\n'
      '  Download and install with one click\n'
      '\n'
      'You can also find mods at:\n'
      '  Starsector Forums — fractalsoftworks.com/forum\n'
      '  Unofficial Starsector Discord — has mod channels';
}
