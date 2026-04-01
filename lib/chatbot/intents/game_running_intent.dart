import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'settings_aware_intent.dart';

/// Checks whether Starsector is currently running.
class GameRunningIntent extends ChatIntent with SettingsAwareIntent {
  @override
  final Ref ref;

  GameRunningIntent(this.ref);

  static const _phrases = [
    'is game running',
    'is starsector running',
    'game running',
    'is the game on',
    'game status',
    'is the game running',
    'game process',
  ];

  static const _primaryKeywords = {
    'running': 0.55,
    'process': 0.45,
  };

  static const _secondaryKeywords = {
    'game': 0.15,
    'starsector': 0.15,
    'status': 0.1,
    'is': 0.1,
  };

  @override
  String get id => 'game_running';

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
    if (isGameRunning) {
      return const ChatResponse(
        text: 'Starsector is currently running.\n'
            'Note: Mod changes won\'t take effect until you restart the game.',
      );
    }
    return const ChatResponse(
      text: 'Starsector does not appear to be running.',
    );
  }
}
