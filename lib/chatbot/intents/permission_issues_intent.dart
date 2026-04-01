import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/trios/app_state.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Helps diagnose file permission issues and provides platform-specific advice.
class PermissionIssuesIntent extends ChatIntent {
  final Ref ref;

  PermissionIssuesIntent(this.ref);

  static const _phrases = [
    'permission denied',
    'permission error',
    'access denied',
    'cannot write',
    "can't write",
    'read only',
    'permission problem',
    'permission issue',
    'file permission',
    'folder permission',
    'write permission',
  ];

  static const _primaryKeywords = {
    'permission': 0.55,
    'permissions': 0.55,
    'access denied': 0.5,
  };

  static const _secondaryKeywords = {
    'denied': 0.15,
    'error': 0.1,
    'write': 0.1,
    'read only': 0.1,
    'file': 0.1,
    'folder': 0.1,
  };

  @override
  String get id => 'permission_issues';

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
    final canWrite =
        ref.read(AppState.canWriteToModsFolder).valueOrNull;
    final canWriteStarsector =
        ref.read(AppState.canWriteToStarsectorFolder).valueOrNull;

    final buf = StringBuffer('File Permission Check\n');

    if (canWrite != null || canWriteStarsector != null) {
      buf.writeln(
        '  Mods folder writable: ${canWrite == true ? "Yes" : canWrite == false ? "NO" : "Unknown"}',
      );
      buf.writeln(
        '  Game folder writable: ${canWriteStarsector == true ? "Yes" : canWriteStarsector == false ? "NO" : "Unknown"}',
      );
      buf.writeln();
    }

    if (Platform.isWindows) {
      buf.writeln('Windows fixes:');
      buf.writeln(
        '  1. Right-click TriOS → "Run as administrator"',
      );
      buf.writeln(
        '  2. Move Starsector out of Program Files to avoid UAC issues.',
      );
      buf.writeln(
        '  3. Check that your antivirus isn\'t blocking file access.',
      );
    } else if (Platform.isMacOS) {
      buf.writeln('macOS fixes:');
      buf.writeln(
        '  1. In System Settings → Privacy & Security, grant TriOS '
        'Full Disk Access.',
      );
      buf.writeln(
        '  2. Run: chmod -R u+rw "<game folder path>"',
      );
    } else {
      buf.writeln('Linux fixes:');
      buf.writeln(
        '  1. Run: chmod -R u+rw "<game folder path>"',
      );
      buf.writeln(
        '  2. Check folder ownership: chown -R \$USER "<game folder path>"',
      );
    }

    return ChatResponse(text: buf.toString().trimRight());
  }
}
