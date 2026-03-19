import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Helps users find a specific page/tool in the TriOS sidebar.
class NavigateToPageIntent extends ChatIntent {
  static const _phrases = [
    'how to open',
    'where is the',
    'go to page',
    'open page',
    'navigate to',
    'how do i find',
    'how do i get to',
    'take me to',
    'show me the',
    'where can i find',
    'open the',
  ];

  static const _primaryKeywords = {
    'navigate': 0.45,
    'go to': 0.4,
    'page': 0.3,
    'open': 0.35,
  };

  static const _secondaryKeywords = {
    'where': 0.1,
    'how': 0.1,
    'find': 0.1,
    'sidebar': 0.15,
  };

  // Maps page keywords to descriptions.
  static const _pages = {
    'dashboard': 'Dashboard — the main overview page with RAM settings and mod summary.',
    'mod manager': 'Mod Manager — enable, disable, and manage your installed mods.',
    'mod profiles': 'Mod Profiles — save and switch between different mod configurations.',
    'vram estimator': 'VRAM Estimator — estimate GPU memory usage for your mods.',
    'vram': 'VRAM Estimator — estimate GPU memory usage for your mods.',
    'chipper': 'Chipper (Log Viewer) — analyze your Starsector log file.',
    'log viewer': 'Chipper (Log Viewer) — analyze your Starsector log file.',
    'log': 'Chipper (Log Viewer) — analyze your Starsector log file.',
    'jre manager': 'JRE Manager — manage Java runtime versions.',
    'jre': 'JRE Manager — manage Java runtime versions.',
    'java': 'JRE Manager — manage Java runtime versions.',
    'portraits': 'Portraits — browse and replace character portraits.',
    'weapons': 'Weapons — browse all weapons from vanilla and mods.',
    'ships': 'Ships — browse all ships/hulls from vanilla and mods.',
    'hullmods': 'Hullmods — browse all hull modifications.',
    'settings': 'Settings — configure TriOS preferences and paths.',
    'catalog': 'Catalog — browse and download mods from the online catalog.',
    'tips': 'Tips — view gameplay tips from your installed mods.',
  };

  @override
  String get id => 'navigate_to_page';

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
    // Try to match a page name in the input.
    for (final entry in _pages.entries) {
      if (input.contains(entry.key)) {
        return ChatResponse(
          text: 'You can find it in the sidebar:\n  ${entry.value}',
        );
      }
    }

    // No specific page matched — list all pages.
    final buf = StringBuffer('Available pages in the sidebar:\n');
    final seen = <String>{};
    for (final entry in _pages.entries) {
      final desc = entry.value;
      if (seen.add(desc)) {
        buf.writeln('  $desc');
      }
    }
    buf.writeln('\nAsk about a specific page for details.');
    return ChatResponse(text: buf.toString().trimRight());
  }
}
