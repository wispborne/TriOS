import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Shows the top mods by VRAM usage.
class HighVramModsIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  HighVramModsIntent(this.ref);

  static const _phrases = [
    'high vram mods',
    'biggest vram mods',
    'most vram',
    'vram heavy mods',
    'which mods use most vram',
    'vram hogs',
    'top vram mods',
    'largest vram',
  ];

  static const _primaryKeywords = {
    'biggest': 0.5,
    'heavy': 0.45,
    'hogs': 0.45,
    'most': 0.4,
    'top': 0.4,
    'highest': 0.45,
    'largest': 0.45,
  };

  static const _secondaryKeywords = {
    'vram': 0.2,
    'mods': 0.1,
    'which': 0.1,
    'gpu': 0.1,
  };

  @override
  String get id => 'high_vram_mods';

  @override
  double match(String input, ConversationContext context) {
    var score = ModAwareIntent.scoreInput(
      input,
      _phrases,
      _primaryKeywords,
      _secondaryKeywords,
    );

    // Context bonus: user just asked about VRAM estimate.
    if (context.lastMatchedIntentId == 'vram_estimate' && score > 0.0) {
      score = (score + 0.15).clamp(0.0, 0.95);
    }

    return score;
  }

  @override
  ChatResponse respond(String input, ConversationContext context) {
    final vramState =
        ref.read(AppState.vramEstimatorProvider).valueOrNull;

    if (vramState == null || vramState.modVramInfo.isEmpty) {
      return const ChatResponse(
        text: 'No VRAM data available yet.\n'
            'Open the VRAM Estimator page in the sidebar to run a scan.',
      );
    }

    // Build list with total bytes per mod, sorted descending.
    final modEntries = vramState.modVramInfo.values.toList();
    final withBytes = modEntries.map((mod) {
      final bytes = mod.imagesNotIncludingGraphicsLib().fold<int>(
        0,
        (sum, b) => sum + b,
      );
      return (mod: mod, bytes: bytes);
    }).toList()
      ..sort((a, b) => b.bytes.compareTo(a.bytes));

    final top = withBytes.take(10).toList();

    final buf = StringBuffer(
      'Top ${top.length} Mods by VRAM Usage\n',
    );
    for (final entry in top) {
      final name = entry.mod.info.name ?? entry.mod.info.modId;
      final mb = (entry.bytes / (1024 * 1024)).toStringAsFixed(0);
      final status = entry.mod.isEnabled ? 'ON' : 'OFF';
      buf.writeln('  [$status] $name — ~$mb MB');
    }

    if (withBytes.length > 10) {
      buf.writeln('  ...and ${withBytes.length - 10} more mods');
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
