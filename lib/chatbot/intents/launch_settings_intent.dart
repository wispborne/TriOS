import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'settings_aware_intent.dart';

/// Shows game launch configuration.
class LaunchSettingsIntent extends ChatIntent with SettingsAwareIntent {
  @override
  final Ref ref;

  LaunchSettingsIntent(this.ref);

  static const _phrases = [
    'launch settings',
    'launch options',
    'how to launch',
    'launch configuration',
    'game launcher',
    'direct launch',
    'how to start game',
    'start the game',
  ];

  static const _primaryKeywords = {
    'launch': 0.55,
    'launcher': 0.5,
  };

  static const _secondaryKeywords = {
    'settings': 0.15,
    'options': 0.1,
    'direct': 0.1,
    'start': 0.1,
    'configuration': 0.1,
  };

  @override
  String get id => 'launch_settings';

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
    final s = settings;
    final buf = StringBuffer('Launch Configuration\n');
    buf.writeln(
      '  Direct launch:   ${s.enableDirectLaunch ? "Enabled (TriOS acts as launcher)" : "Disabled (opens game exe)"}',
    );
    if (s.useCustomGameExePath && s.customGameExePath != null) {
      buf.writeln(
        '  Custom exe path: ${s.customGameExePath}',
      );
    }

    if (!s.enableDirectLaunch) {
      buf.writeln(
        '\nTip: Enable Direct Launch in Settings for better mod '
        'compatibility.',
      );
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
