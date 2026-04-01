import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Lists all installed mods with their name, version, and enabled status.
class ModListIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  ModListIntent(this.ref);

  static const _phrases = [
    'my mods',
    'all mods',
    'list all mods',
    'show all mods',
    'what are my mods',
  ];

  static const _primaryKeywords = {
    'list': 0.35,
    'all': 0.3,
    'installed': 0.35,
  };

  static const _secondaryKeywords = {
    'mods': 0.15,
    'mod': 0.15,
    'show': 0.1,
    'my': 0.1,
    'what': 0.1,
  };

  @override
  String get id => 'mod_list';

  @override
  double match(String input, ConversationContext context) {
    return ModAwareIntent.scoreInput(
      input,
      _phrases,
      _primaryKeywords,
      _secondaryKeywords,
      contextBonus: context.lastMatchedIntentId == 'mod_count' ? 0.15 : 0.0,
    );
  }

  @override
  ChatResponse respond(String input, ConversationContext context) {
    final guard = guardModData();
    if (guard != null) return guard;

    final allMods = mods..sort();
    if (allMods.isEmpty) {
      return const ChatResponse(text: 'No mods are installed.');
    }

    const maxDisplay = 30;
    final buf = StringBuffer('Installed Mods (${allMods.length})\n');

    for (final mod in allMods.take(maxDisplay)) {
      final variant = mod.findFirstEnabledOrHighestVersion;
      final name = variant?.modInfo.nameOrId ?? mod.id;
      final version =
          variant?.modInfo.version != null ? ' v${variant!.modInfo.version}' : '';
      final status = mod.isEnabledInGame ? '[ON] ' : '[OFF]';
      buf.writeln('  $status $name$version');
    }

    if (allMods.length > maxDisplay) {
      buf.writeln('  ...and ${allMods.length - maxDisplay} more');
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
