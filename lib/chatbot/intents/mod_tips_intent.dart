import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Shows random gameplay tips from installed mods.
class ModTipsIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  ModTipsIntent(this.ref);

  static const _phrases = [
    'mod tips',
    'show tips',
    'any tips',
    'gameplay tips',
    'starsector tips',
    'tips for mods',
    'mod advice',
    'random tip',
    'give me a tip',
  ];

  static const _primaryKeywords = {
    'tips': 0.55,
    'tip': 0.5,
    'advice': 0.45,
    'suggestions': 0.4,
  };

  static const _secondaryKeywords = {
    'mod': 0.1,
    'mods': 0.1,
    'show': 0.1,
    'any': 0.1,
    'random': 0.1,
  };

  @override
  String get id => 'mod_tips';

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
    final tips = ref.read(AppState.tipsProvider).valueOrNull;

    if (tips == null || tips.isEmpty) {
      return const ChatResponse(
        text: 'No tips available. Tips come from your installed mods\' '
            'mod_info.json files.',
      );
    }

    // Pick up to 5 random tips.
    final rng = Random();
    final shuffled = List.of(tips)..shuffle(rng);
    final selected = shuffled.take(5).toList();

    final buf = StringBuffer('Tips from Your Mods\n');
    for (final modTip in selected) {
      final tipText = modTip.tipObj.tip ?? '(no text)';
      final source = modTip.variants.firstOrNull?.modInfo.nameOrId ?? 'Unknown';
      buf.writeln('  "$tipText"');
      buf.writeln('    — $source');
    }

    if (tips.length > 5) {
      buf.writeln(
        '\n${tips.length - 5} more tips available. Ask again for different ones!',
      );
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
