import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'settings_aware_intent.dart';

/// Shows information about RAM allocation and managed vmparams files.
class RamInfoIntent extends ChatIntent with SettingsAwareIntent {
  @override
  final Ref ref;

  RamInfoIntent(this.ref);

  static const _phrases = [
    'ram info',
    'memory info',
    'how much ram',
    'current ram',
    'ram allocation',
    'xmx',
    'xms',
    'vmparams',
    'heap size',
  ];

  static const _primaryKeywords = {
    'ram': 0.55,
    'memory': 0.45,
    'vmparams': 0.5,
  };

  static const _secondaryKeywords = {
    'info': 0.1,
    'current': 0.1,
    'allocation': 0.15,
    'heap': 0.15,
    'size': 0.1,
    'how': 0.05,
    'much': 0.05,
  };

  @override
  String get id => 'ram_info';

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
    final state = vmparamsState;

    if (state == null) {
      return const ChatResponse(
        text: 'No RAM information available. Make sure your game folder '
            'is configured in Settings.',
      );
    }

    final buf = StringBuffer('RAM Allocation\n');

    if (state.currentRamAmountInMb != null) {
      buf.writeln('  Current RAM: ${state.currentRamAmountInMb} MB');
    }

    final selected = state.selectedVmparamsFiles;
    if (selected.isNotEmpty) {
      buf.writeln('  Managed vmparams files (${selected.length}):');
      final gameDir = gameFolder;
      for (final file in selected) {
        final ram = state.fileRamAmounts[file];
        final displayPath = gameDir != null
            ? p.relative(file.path, from: gameDir.path)
            : file.path;
        buf.writeln(
          '    - $displayPath${ram != null ? " ($ram MB)" : ""}',
        );
      }
    }

    if (state.hasMultipleFilesWithDifferentRam) {
      buf.writeln(
        '\n  Warning: Multiple vmparams files have different RAM amounts.',
      );
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
