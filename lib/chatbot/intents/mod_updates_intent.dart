import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/mod_manager_extensions.dart';

import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Lists mods that have updates available via version checker.
class ModUpdatesIntent extends ChatIntent with ModAwareIntent {
  @override
  final Ref ref;

  ModUpdatesIntent(this.ref);

  static const _phrases = [
    'mod updates',
    'available updates',
    'outdated mods',
    'mods need updating',
    'any updates',
    'check for updates',
    'which mods have updates',
    'are my mods up to date',
  ];

  static const _primaryKeywords = {
    'updates': 0.5,
    'update': 0.45,
    'outdated': 0.5,
    'newer': 0.4,
  };

  static const _secondaryKeywords = {
    'mods': 0.1,
    'mod': 0.1,
    'check': 0.1,
    'available': 0.15,
    'any': 0.1,
  };

  @override
  String get id => 'mod_updates';

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
    final guard = guardModData();
    if (guard != null) return guard;

    final vcState = versionCheckResults;
    if (vcState == null) {
      return const ChatResponse(
        text: 'Version check data is not available yet. '
            'Try again in a moment.',
      );
    }

    final updatesAvailable = <String>[];

    for (final mod in mods) {
      final check = mod.updateCheck(vcState);
      if (check == null || !check.hasUpdate) continue;

      final localVersion = check.variant.modInfo.version;
      final remoteVersion =
          check.remoteVersionCheck?.remoteVersion?.modVersion;
      final name = check.variant.modInfo.nameOrId;

      if (remoteVersion != null) {
        updatesAvailable.add(
          '  $name: v$localVersion -> v$remoteVersion',
        );
      } else {
        updatesAvailable.add('  $name: update available');
      }
    }

    if (updatesAvailable.isEmpty) {
      return const ChatResponse(text: 'All mods are up to date!');
    }

    final buf = StringBuffer(
      'Mod Updates Available (${updatesAvailable.length})\n',
    );
    buf.writeAll(updatesAvailable, '\n');

    return ChatResponse(text: buf.toString().trimRight());
  }
}
