import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Provides a static guide to common Starsector/TriOS issues and fixes.
class CommonIssuesIntent extends ChatIntent {
  static const _phrases = [
    'common issues',
    'common problems',
    'troubleshooting',
    'help with issues',
    'game crashes',
    'game crash',
    'crash fix',
    'game not launching',
    'game wont start',
    "game won't start",
    'game not starting',
    'black screen',
    'stuck on loading',
    'freezing on load',
    'game freezes',
  ];

  static const _primaryKeywords = {
    'troubleshoot': 0.5,
    'troubleshooting': 0.55,
    'crash': 0.45,
    'crashes': 0.45,
    'crashing': 0.45,
    'issues': 0.4,
    'problems': 0.4,
    'fix': 0.35,
  };

  static const _secondaryKeywords = {
    'common': 0.1,
    'help': 0.1,
    'game': 0.1,
    'error': 0.1,
    'broken': 0.1,
  };

  @override
  String get id => 'common_issues';

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

  static const _response = 'Common Starsector Issues & Fixes\n'
      '\n'
      'OutOfMemoryError / Crash during loading\n'
      '  Increase RAM allocation on the Dashboard page.\n'
      '  Try "current ram" to see your setting, or "more ram" for a guide.\n'
      '\n'
      'Game won\'t start / Black screen\n'
      '  Check that your JRE is configured correctly ("jre info").\n'
      '  Try disabling recently-added mods.\n'
      '  On Windows, try running as Administrator.\n'
      '\n'
      'Missing mod dependencies\n'
      '  Ask "mod compatibility" to see which mods have issues.\n'
      '  Install missing dependencies from the Catalog page.\n'
      '\n'
      'Mod version mismatch\n'
      '  Ask "mod updates" to check for newer versions.\n'
      '  Check the mod\'s required game version vs yours ("game version").\n'
      '\n'
      'Permission errors\n'
      '  Ask "permission issues" for platform-specific help.\n'
      '\n'
      'For detailed error info, try "log summary" and "log errors"\n'
      'to analyze your Starsector log file.';
}
