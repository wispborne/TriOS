import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Lists only the currently enabled mods.
class EnabledModsIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  EnabledModsIntent(this.ref);

  static const _phrases = [
    'enabled mods',
    'active mods',
    'turned on mods',
    'mods i have on',
    'mods i have active',
    'mods do i have active',
    'what mods are enabled',
    'what mods are active',
    'mods that are on',
    'how many mods do i have active',
    'how many active mods',
    'how many enabled mods',
  ];

  static const _primaryKeywords = {
    'enabled': 0.5,
    'active': 0.45,
  };

  static const _secondaryKeywords = {
    'mods': 0.15,
    'mod': 0.15,
    'show': 0.1,
    'list': 0.1,
    'which': 0.1,
    'on': 0.1,
  };

  @override
  String get id => 'enabled_mods';

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

    final enabled = mods.where((m) => m.isEnabledInGame).toList()..sort();
    if (enabled.isEmpty) {
      return const ChatResponse(text: 'No mods are currently enabled.');
    }

    final buf = StringBuffer('Enabled Mods (${enabled.length})\n');
    for (final mod in enabled) {
      final variant = mod.findFirstEnabled;
      final name = variant?.modInfo.nameOrId ?? mod.id;
      final version =
          variant?.modInfo.version != null ? ' v${variant!.modInfo.version}' : '';
      buf.writeln('  $name$version');
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
