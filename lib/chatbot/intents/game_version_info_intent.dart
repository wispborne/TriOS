import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_logic.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Shows the detected game version and mod compatibility summary.
class GameVersionInfoIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  GameVersionInfoIntent(this.ref);

  static const _phrases = [
    'game version',
    'starsector version',
    'what version',
    'version compatibility',
    'game compatibility',
    'what version of starsector',
  ];

  static const _primaryKeywords = {
    'version': 0.45,
    'compatible': 0.4,
  };

  static const _secondaryKeywords = {
    'game': 0.15,
    'starsector': 0.15,
    'what': 0.1,
    'check': 0.1,
  };

  @override
  String get id => 'game_version_info';

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
    final guard = guardModData();
    if (guard != null) return guard;

    final gameVersion = starsectorVersion ?? 'unknown';
    final compatibility = modCompatibility;

    var compatibleCount = 0;
    var warningCount = 0;
    var incompatibleCount = 0;

    // Only check enabled mods
    for (final mod in mods.where((m) => m.isEnabledInGame)) {
      final variant = mod.findFirstEnabled;
      if (variant == null) continue;

      final check = compatibility[variant.smolId];
      if (check == null) continue;

      switch (check.gameCompatibility) {
        case GameCompatibility.perfectMatch:
          compatibleCount++;
        case GameCompatibility.warning:
          warningCount++;
        case GameCompatibility.incompatible:
          incompatibleCount++;
      }
    }

    final buf = StringBuffer('Game Version: $gameVersion\n');
    buf.writeln('  Compatible mods: $compatibleCount');
    if (warningCount > 0) {
      buf.writeln('  Mods with warnings: $warningCount');
    }
    if (incompatibleCount > 0) {
      buf.writeln('  Incompatible mods: $incompatibleCount');
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
