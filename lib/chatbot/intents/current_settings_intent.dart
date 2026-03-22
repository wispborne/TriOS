import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'settings_aware_intent.dart';

/// Shows a summary of the user's current TriOS settings.
class CurrentSettingsIntent extends ChatIntent with SettingsAwareIntent {
  @override
  final Ref ref;

  CurrentSettingsIntent(this.ref);

  static const _phrases = [
    'my settings',
    'current settings',
    'show settings',
    'trios settings',
    'app settings',
    'what are my settings',
  ];

  static const _primaryKeywords = {
    'settings': 0.55,
    'configuration': 0.5,
    'config': 0.5,
    'preferences': 0.45,
  };

  static const _secondaryKeywords = {
    'current': 0.1,
    'show': 0.1,
    'my': 0.1,
  };

  @override
  String get id => 'current_settings';

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
    final buf = StringBuffer('TriOS Settings\n');
    buf.writeln(
      '  Game folder:     ${gameFolder?.path ?? "Not set"}',
    );
    buf.writeln(
      '  Mods folder:     ${modsFolder?.path ?? "Default"}',
    );
    buf.writeln(
      '  Direct launch:   ${s.enableDirectLaunch ? "Enabled" : "Disabled"}',
    );
    buf.writeln('  Default page:    ${s.defaultTool.name}');
    buf.writeln(
      '  Theme:           ${s.themeKey ?? "Default"}',
    );
    buf.writeln(
      '  Game version:    ${s.lastStarsectorVersion ?? "Unknown"}',
    );
    buf.writeln(
      '  Colorful grid:   ${s.modsGridColorful ? "On" : "Off"}',
    );

    return ChatResponse(text: buf.toString().trimRight());
  }
}
