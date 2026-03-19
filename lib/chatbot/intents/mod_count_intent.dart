import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Shows a quick count of total, enabled, and disabled mods.
class ModCountIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  ModCountIntent(this.ref);

  static const _phrases = [
    'how many mods',
    'mod count',
    'number of mods',
    'total mods',
    'count mods',
    'how many mods do i have',
    'how many mods are',
  ];

  static const _primaryKeywords = {
    'count': 0.5,
    'many': 0.45,
    'number': 0.4,
    'total': 0.4,
  };

  static const _secondaryKeywords = {
    'mods': 0.15,
    'mod': 0.15,
    'how': 0.1,
  };

  @override
  String get id => 'mod_count';

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

    final allMods = mods;
    final enabledCount = allMods.where((m) => m.isEnabledInGame).length;
    final disabledCount = allMods.length - enabledCount;

    final buf = StringBuffer('Mod Count\n');
    buf.writeln('  Total: ${allMods.length}');
    buf.writeln('  Enabled: $enabledCount');
    buf.writeln('  Disabled: $disabledCount');

    return ChatResponse(text: buf.toString().trimRight());
  }
}
