import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'settings_aware_intent.dart';

/// Shows the current RAM allocation for Starsector.
class CurrentRamInfoIntent extends ChatIntent with SettingsAwareIntent {
  @override
  final Ref ref;

  CurrentRamInfoIntent(this.ref);

  static const _phrases = [
    'current ram',
    'how much ram assigned',
    'ram amount',
    'current memory',
    'assigned ram',
    'ram setting',
    'how much ram am i using',
    'current heap',
    'how much ram',
    'what ram',
    'what is my ram',
  ];

  static const _primaryKeywords = {
    'assigned': 0.45,
    'current': 0.35,
    'amount': 0.35,
  };

  static const _secondaryKeywords = {
    'ram': 0.2,
    'memory': 0.15,
    'heap': 0.15,
    'mb': 0.1,
    'gb': 0.1,
    'how much': 0.1,
  };

  @override
  String get id => 'current_ram_info';

  @override
  double match(String input, ConversationContext context) {
    var score = ModAwareIntent.scoreInput(
      input,
      _phrases,
      _primaryKeywords,
      _secondaryKeywords,
    );

    // Context bonus if user just asked about RAM allocation or RAM vs VRAM.
    if ((context.lastMatchedIntentId == 'ram_allocation' ||
            context.lastMatchedIntentId == 'ram_vs_vram') &&
        score > 0.0) {
      score = (score + 0.15).clamp(0.0, 0.95);
    }

    return score;
  }

  @override
  ChatResponse respond(String input, ConversationContext context) {
    final ram = currentRam;

    if (ram == null) {
      return const ChatResponse(
        text: 'Could not determine current RAM allocation. '
            'Make sure your game folder is configured in Settings.',
      );
    }

    final ramMb = int.tryParse(ram);
    final ramGb =
        ramMb != null ? ' (${(ramMb / 1024).toStringAsFixed(1)} GB)' : '';

    return ChatResponse(
      text: 'Current RAM allocation: $ram MB$ramGb\n'
          '\n'
          'To change this, go to the Dashboard page and adjust the\n'
          'RAM slider, or ask "more ram" for recommendations.',
    );
  }
}
