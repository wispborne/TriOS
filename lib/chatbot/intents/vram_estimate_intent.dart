import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Shows total estimated VRAM usage for enabled and all mods.
class VramEstimateIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  VramEstimateIntent(this.ref);

  static const _phrases = [
    'vram estimate',
    'vram usage',
    'estimate vram',
    'total vram',
    'vram total',
    'how much vram am i using',
    'vram check',
    'check vram usage',
    'estimated vram',
  ];

  static const _primaryKeywords = {
    'estimate': 0.5,
    'usage': 0.45,
    'estimated': 0.45,
    'total': 0.4,
  };

  static const _secondaryKeywords = {
    'vram': 0.2,
    'video memory': 0.15,
    'check': 0.1,
    'gpu': 0.1,
  };

  @override
  String get id => 'vram_estimate';

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
    final vramState =
        ref.read(AppState.vramEstimatorProvider).valueOrNull;

    if (vramState == null || vramState.modVramInfo.isEmpty) {
      return const ChatResponse(
        text: 'No VRAM data available yet.\n'
            'Open the VRAM Estimator page in the sidebar to run a scan.',
      );
    }

    final allMods = vramState.modVramInfo.values.toList();
    final enabledMods = allMods.where((m) => m.isEnabled).toList();

    int totalBytes(List<dynamic> mods) {
      var total = 0;
      for (final mod in mods) {
        for (final bytes in mod.imagesNotIncludingGraphicsLib()) {
          total += bytes as int;
        }
      }
      return total;
    }

    final enabledBytes = totalBytes(enabledMods);
    final allBytes = totalBytes(allMods);

    String formatMb(int bytes) =>
        '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';

    final buf = StringBuffer('VRAM Usage Estimate\n');
    buf.writeln(
      '  Enabled mods (${enabledMods.length}): ~${formatMb(enabledBytes)}',
    );
    buf.writeln(
      '  All mods (${allMods.length}):     ~${formatMb(allBytes)}',
    );

    if (vramState.lastUpdated != null) {
      buf.writeln(
        '  Last scanned: ${vramState.lastUpdated!.toLocal().toString().split('.').first}',
      );
    }

    buf.writeln(
      '\nNote: This is an estimate based on texture sizes.\n'
      'Ask "high vram mods" to see the biggest consumers.',
    );

    return ChatResponse(text: buf.toString().trimRight());
  }
}
