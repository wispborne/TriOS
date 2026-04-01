import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'viewer_aware_intent.dart';

/// Shows the total hullmod count and breakdown.
class HullmodCountIntent extends ChatIntent with ViewerAwareIntent {
  @override
  final Ref ref;

  HullmodCountIntent(this.ref);

  static const _phrases = [
    'how many hullmods',
    'hullmod count',
    'total hullmods',
    'number of hullmods',
  ];

  static const _primaryKeywords = {
    'hullmods': 0.5,
    'hullmod': 0.5,
  };

  static const _secondaryKeywords = {
    'count': 0.15,
    'many': 0.15,
    'total': 0.1,
    'number': 0.1,
    'how': 0.1,
  };

  @override
  String get id => 'hullmod_count';

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
    final hullmodList = hullmods;
    if (hullmodList == null || hullmodList.isEmpty) {
      return const ChatResponse(
        text: ViewerAwareIntent.noViewerDataMessage,
      );
    }

    final vanilla =
        hullmodList.where((h) => h.modVariant == null).length;
    final modded = hullmodList.length - vanilla;

    final buf = StringBuffer(
      'Hullmods: ${hullmodList.length} total\n',
    );
    buf.writeln('  Vanilla: $vanilla');
    buf.writeln('  From mods: $modded');

    return ChatResponse(text: buf.toString().trimRight());
  }
}
