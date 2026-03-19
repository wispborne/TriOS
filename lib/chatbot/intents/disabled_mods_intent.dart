import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Lists only the currently disabled mods.
class DisabledModsIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  DisabledModsIntent(this.ref);

  static const _phrases = [
    'disabled mods',
    'inactive mods',
    'turned off mods',
    'mods i have off',
    'what mods are disabled',
    'what mods are off',
    'mods that are off',
  ];

  static const _primaryKeywords = {
    'disabled': 0.5,
    'inactive': 0.45,
    'off': 0.3,
  };

  static const _secondaryKeywords = {
    'mods': 0.15,
    'mod': 0.15,
    'show': 0.1,
    'list': 0.1,
    'which': 0.1,
  };

  @override
  String get id => 'disabled_mods';

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

    final disabled = mods.where((m) => !m.isEnabledInGame).toList()..sort();
    if (disabled.isEmpty) {
      return const ChatResponse(text: 'All installed mods are currently enabled.');
    }

    final buf = StringBuffer('Disabled Mods (${disabled.length})\n');
    for (final mod in disabled) {
      final variant = mod.findHighestVersion;
      final name = variant?.modInfo.nameOrId ?? mod.id;
      final version =
          variant?.modInfo.version != null ? ' v${variant!.modInfo.version}' : '';
      buf.writeln('  $name$version');
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
