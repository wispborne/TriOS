import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Lists all utility/library mods.
class UtilityModsIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  UtilityModsIntent(this.ref);

  static const _phrases = [
    'utility mods',
    'library mods',
    'lib mods',
    'helper mods',
    'support mods',
  ];

  static const _primaryKeywords = {
    'utility': 0.5,
    'library': 0.5,
    'libraries': 0.45,
    'lib': 0.4,
  };

  static const _secondaryKeywords = {
    'mods': 0.15,
    'mod': 0.15,
    'show': 0.1,
    'list': 0.1,
  };

  @override
  String get id => 'utility_mods';

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

    final utilityMods = mods.where((mod) {
      final variant = mod.findFirstEnabledOrHighestVersion;
      return variant?.modInfo.isUtility == true;
    }).toList()
      ..sort();

    if (utilityMods.isEmpty) {
      return const ChatResponse(text: 'No utility/library mods are installed.');
    }

    final buf = StringBuffer(
      'Utility/Library Mods (${utilityMods.length})\n',
    );
    for (final mod in utilityMods) {
      final variant = mod.findFirstEnabledOrHighestVersion;
      final name = variant?.modInfo.nameOrId ?? mod.id;
      final version =
          variant?.modInfo.version != null ? ' v${variant!.modInfo.version}' : '';
      final status = mod.isEnabledInGame ? '[ON] ' : '[OFF]';
      buf.writeln('  $status $name$version');
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
