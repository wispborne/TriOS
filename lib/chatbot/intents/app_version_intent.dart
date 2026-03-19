import 'package:trios/trios/constants.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Shows the current TriOS app version.
class AppVersionIntent extends ChatIntent {
  static const _phrases = [
    'trios version',
    'app version',
    'what version of trios',
    'trios build',
    'current trios version',
    'which version of trios',
    'version of trios',
  ];

  static const _primaryKeywords = {
    'trios': 0.45,
    'app': 0.35,
  };

  static const _secondaryKeywords = {
    'version': 0.2,
    'build': 0.15,
    'current': 0.1,
  };

  @override
  String get id => 'app_version';

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
    return ChatResponse(
      text: '${Constants.appName} v${Constants.version}',
    );
  }
}
