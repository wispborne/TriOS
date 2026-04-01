import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'viewer_aware_intent.dart';

/// Shows the total weapon count and breakdown.
class WeaponCountIntent extends ChatIntent with ViewerAwareIntent {
  @override
  final Ref ref;

  WeaponCountIntent(this.ref);

  static const _phrases = [
    'how many weapons',
    'weapon count',
    'total weapons',
    'number of weapons',
  ];

  static const _primaryKeywords = {
    'weapons': 0.5,
    'weapon': 0.5,
  };

  static const _secondaryKeywords = {
    'count': 0.15,
    'many': 0.15,
    'total': 0.1,
    'number': 0.1,
    'how': 0.1,
  };

  @override
  String get id => 'weapon_count';

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
    final weaponList = weapons;
    if (weaponList == null || weaponList.isEmpty) {
      return const ChatResponse(
        text: ViewerAwareIntent.noViewerDataMessage,
      );
    }

    final vanilla =
        weaponList.where((w) => w.modVariant == null).length;
    final modded = weaponList.length - vanilla;

    final buf = StringBuffer('Weapons: ${weaponList.length} total\n');
    buf.writeln('  Vanilla: $vanilla');
    buf.writeln('  From mods: $modded');

    return ChatResponse(text: buf.toString().trimRight());
  }
}
