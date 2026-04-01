import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'viewer_aware_intent.dart';

/// Shows combined ship, weapon, hullmod, and portrait counts.
class ViewerStatsIntent extends ChatIntent with ViewerAwareIntent {
  @override
  final Ref ref;

  ViewerStatsIntent(this.ref);

  static const _phrases = [
    'game data stats',
    'data overview',
    'ships weapons hullmods',
    'game content stats',
    'content overview',
    'how much content',
    'content count',
    'game content',
  ];

  static const _primaryKeywords = {
    'stats': 0.45,
    'overview': 0.4,
    'content': 0.4,
    'data': 0.35,
  };

  static const _secondaryKeywords = {
    'ships': 0.1,
    'weapons': 0.1,
    'hullmods': 0.1,
    'game': 0.1,
    'all': 0.1,
  };

  @override
  String get id => 'viewer_stats';

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
    final shipList = ships;
    final weaponList = weapons;
    final hullmodList = hullmods;
    final portraitMap = portraits;

    final buf = StringBuffer('Game Content Overview\n');

    if (shipList != null && shipList.isNotEmpty) {
      buf.writeln('  Ships:    ${shipList.length}');
    } else {
      buf.writeln('  Ships:    Not loaded');
    }

    if (weaponList != null && weaponList.isNotEmpty) {
      buf.writeln('  Weapons:  ${weaponList.length}');
    } else {
      buf.writeln('  Weapons:  Not loaded');
    }

    if (hullmodList != null && hullmodList.isNotEmpty) {
      buf.writeln('  Hullmods: ${hullmodList.length}');
    } else {
      buf.writeln('  Hullmods: Not loaded');
    }

    if (portraitMap != null && portraitMap.isNotEmpty) {
      final totalPortraits = portraitMap.values
          .fold<int>(0, (sum, list) => sum + list.length);
      buf.writeln('  Portraits: $totalPortraits');
    } else {
      buf.writeln('  Portraits: Not loaded');
    }

    buf.writeln(
      '\nOpen a viewer page to load its data if not yet loaded.',
    );

    return ChatResponse(text: buf.toString().trimRight());
  }
}
