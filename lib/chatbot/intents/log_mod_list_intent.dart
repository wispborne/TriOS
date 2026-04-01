import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'log_aware_intent.dart';

/// Lists mods detected in the parsed log file.
class LogModListIntent extends ChatIntent with LogAwareIntent {
  @override
  final Ref ref;

  LogModListIntent(this.ref);

  static const _phrases = [
    'mods in log',
    'mods in the log',
    'log mod list',
    'log mods',
    'mods from log',
    'mods loaded in log',
  ];

  static const _primaryKeywords = {
    'log': 0.45,
  };

  static const _secondaryKeywords = {
    'mods': 0.2,
    'mod': 0.15,
    'list': 0.1,
    'loaded': 0.1,
    'show': 0.1,
    'what': 0.1,
  };

  @override
  String get id => 'log_mod_list';

  @override
  double match(String input, ConversationContext context) {
    for (final phrase in _phrases) {
      if (input.contains(phrase)) return 0.85;
    }

    var score = 0.0;
    for (final entry in _primaryKeywords.entries) {
      if (input.contains(entry.key)) score += entry.value;
    }
    for (final entry in _secondaryKeywords.entries) {
      if (input.contains(entry.key)) score += entry.value;
    }

    return score.clamp(0.0, 0.95);
  }

  @override
  ChatResponse respond(String input, ConversationContext context) {
    final chips = logChips;
    if (chips == null) {
      return const ChatResponse(text: LogAwareIntent.noLogMessage);
    }

    final mods = chips.modList.modList;
    if (mods.isEmpty) {
      return const ChatResponse(
        text: 'No mods were detected in the log file.',
      );
    }

    final buf = StringBuffer('${mods.length} mod(s) found in the log');
    if (!chips.modList.isPerfectList) {
      buf.write(' (approximate — parsed from CSV loading lines)');
    }
    buf.writeln(':');

    for (final mod in mods) {
      final name = mod.modName ?? 'Unknown';
      final version = mod.modVersion != null ? ' v${mod.modVersion}' : '';
      final id = mod.modId != null ? ' (${mod.modId})' : '';
      buf.writeln('  $name$version$id');
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
