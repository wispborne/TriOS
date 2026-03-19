import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';
import 'settings_aware_intent.dart';

/// Shows the configured game, mods, and saves folder paths.
class GameFolderInfoIntent extends ChatIntent with SettingsAwareIntent {
  @override
  final Ref ref;

  GameFolderInfoIntent(this.ref);

  static const _phrases = [
    'game folder',
    'game directory',
    'game path',
    'where is starsector installed',
    'starsector folder',
    'installation path',
    'install location',
    'install directory',
    'mods folder',
    'saves folder',
    'where are my mods',
    'where are my saves',
  ];

  static const _primaryKeywords = {
    'folder': 0.45,
    'directory': 0.45,
    'path': 0.4,
    'installation': 0.4,
  };

  static const _secondaryKeywords = {
    'game': 0.15,
    'starsector': 0.15,
    'where': 0.1,
    'location': 0.1,
    'mods': 0.1,
    'saves': 0.1,
    'installed': 0.1,
  };

  @override
  String get id => 'game_folder_info';

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
    final game = gameFolder?.path;
    final mods = modsFolder?.path;
    final saves = savesFolder?.path;

    final buf = StringBuffer('Folder Paths\n');
    buf.writeln('  Game:  ${game ?? "Not configured"}');
    buf.writeln('  Mods:  ${mods ?? "Not configured"}');
    buf.writeln('  Saves: ${saves ?? "Not configured"}');

    if (game == null) {
      buf.writeln(
        '\nSet your game folder in Settings to get started.',
      );
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
