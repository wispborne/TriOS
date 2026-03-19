import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';
import 'package:trios/trios/constants.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Checks whether a TriOS update is available.
class AppUpdateIntent extends ChatIntent {
  final Ref ref;

  AppUpdateIntent(this.ref);

  static const _phrases = [
    'is there a trios update',
    'trios update',
    'update trios',
    'is trios up to date',
    'trios latest version',
    'new trios version',
    'check for updates',
    'app update',
  ];

  static const _primaryKeywords = {
    'update trios': 0.55,
    'trios update': 0.55,
  };

  static const _secondaryKeywords = {
    'update': 0.15,
    'latest': 0.15,
    'new': 0.1,
    'trios': 0.15,
    'app': 0.1,
    'check': 0.1,
  };

  @override
  String get id => 'app_update';

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
    final updateState =
        ref.read(AppState.selfUpdate).valueOrNull;

    if (updateState == null) {
      return ChatResponse(
        text: 'You are running ${Constants.appName} v${Constants.version}.\n'
            'No update information available at this time.',
      );
    }

    // If there's active download progress, an update is in progress.
    return ChatResponse(
      text: 'You are running ${Constants.appName} v${Constants.version}.\n'
          'An update is being downloaded. Check the Settings page for details.',
    );
  }
}
