import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'viewer_aware_intent.dart';

/// Shows portrait counts broken down by source mod.
class PortraitStatsIntent extends ChatIntent with ViewerAwareIntent {
  @override
  final Ref ref;

  PortraitStatsIntent(this.ref);

  static const _phrases = [
    'portrait count',
    'how many portraits',
    'portrait stats',
    'portrait info',
    'portraits available',
    'show portraits',
  ];

  static const _primaryKeywords = {
    'portraits': 0.55,
    'portrait': 0.55,
  };

  static const _secondaryKeywords = {
    'count': 0.15,
    'many': 0.1,
    'stats': 0.1,
    'info': 0.1,
    'available': 0.1,
    'how': 0.1,
  };

  @override
  String get id => 'portrait_stats';

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
    final portraitMap = portraits;
    if (portraitMap == null || portraitMap.isEmpty) {
      return const ChatResponse(
        text: ViewerAwareIntent.noViewerDataMessage,
      );
    }

    final totalPortraits = portraitMap.values
        .fold<int>(0, (sum, list) => sum + list.length);

    final buf = StringBuffer('Portraits: $totalPortraits total\n');

    // Sort sources by count descending.
    final sources = portraitMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    for (final entry in sources.take(15)) {
      final source = entry.key == null
          ? 'Vanilla'
          : (entry.key!.modInfo.nameOrId);
      buf.writeln('  $source: ${entry.value.length}');
    }

    if (sources.length > 15) {
      buf.writeln('  ...and ${sources.length - 15} more sources');
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
