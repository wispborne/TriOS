import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'settings_aware_intent.dart';

/// Shows information about the active JRE and installed JREs.
class JreInfoIntent extends ChatIntent with SettingsAwareIntent {
  @override
  final Ref ref;

  JreInfoIntent(this.ref);

  static const _phrases = [
    'jre info',
    'java info',
    'java version',
    'jre version',
    'which java',
    'which jre',
    'current jre',
    'active jre',
    'what java',
    'what jre',
    'java runtime',
  ];

  static const _primaryKeywords = {
    'jre': 0.55,
    'java': 0.5,
  };

  static const _secondaryKeywords = {
    'version': 0.15,
    'info': 0.1,
    'current': 0.1,
    'active': 0.1,
    'which': 0.1,
    'runtime': 0.1,
  };

  @override
  String get id => 'jre_info';

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
    final jre = activeJre;
    final state = jreState;

    if (jre == null && state == null) {
      return const ChatResponse(
        text: 'No JRE information available. Make sure your game folder '
            'is configured in Settings.',
      );
    }

    final buf = StringBuffer('Java Runtime Environment\n');

    if (jre != null) {
      buf.writeln('  Active JRE:  ${jre.versionString}');
      buf.writeln(
        '  Type:        ${jre.isCustomJre ? "Custom (e.g. JRE 23)" : "Standard"}',
      );
      if (jre.ramAmountInMb != null) {
        buf.writeln('  RAM:         ${jre.ramAmountInMb} MB');
      }
    }

    if (state != null) {
      if (state.isUsingJre23) {
        buf.writeln('  JRE 23:      Active');
      }
      final installed = state.installedJres;
      if (installed.length > 1) {
        buf.writeln('  Installed JREs (${installed.length}):');
        for (final entry in installed) {
          buf.writeln('    - ${entry.versionString}');
        }
      }
      if (state.hasMultipleActiveJresWithDifferentRamAmounts) {
        buf.writeln(
          '\n  Warning: Multiple active JREs have different RAM amounts.',
        );
      }
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
