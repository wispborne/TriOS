import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Shows recent mod enable/disable/delete actions from the audit log.
class ModAuditIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  ModAuditIntent(this.ref);

  static const _phrases = [
    'mod history',
    'mod audit',
    'audit log',
    'mod changes',
    'recent mod changes',
    'what mods did i change',
    'mod activity',
    'change history',
  ];

  static const _primaryKeywords = {
    'audit': 0.55,
    'history': 0.45,
    'changes': 0.4,
    'recent changes': 0.5,
    'activity': 0.4,
  };

  static const _secondaryKeywords = {
    'mod': 0.15,
    'mods': 0.15,
    'recent': 0.1,
    'log': 0.1,
  };

  @override
  String get id => 'mod_audit';

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
    final entries =
        ref.read(AppState.modAudit).valueOrNull;

    if (entries == null || entries.isEmpty) {
      return const ChatResponse(
        text: 'No mod change history recorded yet.',
      );
    }

    final recent = entries.reversed.take(15).toList();
    final buf = StringBuffer(
      'Recent Mod Changes (last ${recent.length})\n',
    );

    for (final entry in recent) {
      final time = entry.timestamp
          .toLocal()
          .toString()
          .split('.')
          .first;
      final action = entry.action.name.toUpperCase();
      // Try to resolve smolId to a mod name.
      final mod = mods
          .expand((m) => m.modVariants)
          .where((v) => v.smolId == entry.smolId)
          .firstOrNull;
      final name = mod?.modInfo.nameOrId ?? entry.smolId;
      buf.writeln('  [$action] $name  ($time)');
      if (entry.reason.isNotEmpty) {
        buf.writeln('    Reason: ${entry.reason}');
      }
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
